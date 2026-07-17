use futures_util::{
    future::{select, Either},
    pin_mut, StreamExt,
};
use serde::{Deserialize, Serialize};
use std::{
    cmp::Ordering,
    collections::BTreeMap,
    sync::atomic::{AtomicUsize, Ordering as AtomicOrdering},
    time::Duration,
};
use worker::{
    event, AbortController, Delay, Env, Fetch, Headers, Method, Request, Response, Result,
};

/// Production DefiLlama endpoint used when no override is configured.
const DEFAULT_UPSTREAM_URL: &str = "https://yields.llama.fi/pools";

/// Exact DefiLlama pool IDs supported by the CRE workflow.
const DEFAULT_ALLOWED_POOLS: &str = concat!(
    "aa70268e-4b52-42bf-a116-608b370f9501,",
    "7da72d09-56ca-4ec5-a45f-59114353e487,",
    "d9fa8e14-0447-4207-9ae8-7810199dfa1f,",
    "d9c395b9-00d0-4426-a6b3-572a6dd68e54,",
    "7e0661bf-8cf3-45e6-9424-31916d4c7b84,",
    "0c8567f8-ba5b-41ad-80de-00a71895eb19,",
    "c4b05318-88af-4536-a834-f5fc8940d2d3,",
    "0758c3b8-4ffb-4176-b0a9-f446e367db46,",
    "b828f0cb-853d-4b32-aebb-2e20d7fd70a8",
);

/// Maximum response size returned to CRE, leaving margin below its 100 KB HTTP limit.
const MAX_RESPONSE_BYTES: usize = 90 * 1024;

/// Maximum DefiLlama success response size accepted by `Content-Length` precheck.
const MAX_UPSTREAM_BYTES: usize = 12 * 1024 * 1024;

/// Wall-clock budget for the complete upstream fetch and body read.
///
/// The byte cap limits total response size, but it does not stop an upstream
/// from slowly streaming bytes forever.
const UPSTREAM_READ_TIMEOUT_SECS: u64 = 30;

/// Maximum number of upstream fetch+read operations allowed in flight at once
/// per isolate.
///
/// Bounds aggregate buffered memory to roughly
/// `MAX_CONCURRENT_UPSTREAM_FETCHES * MAX_UPSTREAM_BYTES`, so concurrent
/// requests cannot multiply the per-request byte cap unboundedly.
const MAX_CONCURRENT_UPSTREAM_FETCHES: usize = 4;

/// Maximum number of compact pool entries returned to CRE.
const MAX_RELAY_POOLS: usize = 32;

/// Maximum accepted byte length for an upstream DefiLlama pool ID.
const MAX_POOL_ID_BYTES: usize = 128;

/// DefiLlama metadata is untrusted input. Bounding response fields before JSON
/// serialization prevents a compromised upstream from inflating the CRE-facing
/// response or forcing large encoder allocations.
///
/// These limits intentionally cover only the compact metadata returned to CRE,
/// not the larger upstream response. Overlong metadata is treated as malformed
/// and the containing pool is dropped.
///
/// Maximum accepted byte length for an upstream chain name returned to CRE.
const MAX_CHAIN_BYTES: usize = 32;

/// Maximum accepted byte length for an upstream project name returned to CRE.
const MAX_PROJECT_BYTES: usize = 64;

/// Maximum accepted byte length for an upstream symbol returned to CRE.
const MAX_SYMBOL_BYTES: usize = 64;

/// Maximum accepted byte length for a request Authorization header.
///
/// The bearer token is short and fixed by deployment policy. Rejecting oversized
/// headers before comparison prevents unauthenticated clients from making auth
/// cost scale with attacker-controlled input size.
///
/// This cap is a comparison-cost guard, not a pre-allocation guard:
/// `Headers::get` returns an owned string after the Worker runtime has already
/// accepted and materialized the request headers. Pre-allocation protection
/// depends on Cloudflare's platform request-header limits.
const MAX_AUTH_HEADER_BYTES: usize = 1024;

/// Checks whether a configured bearer token is usable as an auth secret.
///
/// Empty or whitespace-only values are treated as unconfigured: without this
/// check, `constant_time_eq` would accept an empty client-supplied token
/// against an empty configured secret, silently bypassing authentication.
/// Only the configured value is checked here — the client-supplied token is
/// still compared byte-exact, untrimmed, in `authorize_header`.
fn is_valid_configured_token(token: &str) -> bool {
    !token.trim().is_empty()
}

/// Pool shape read from DefiLlama's `/pools` response.
#[derive(Debug, Deserialize)]
struct Pool {
    pool: String,
    chain: String,
    project: String,
    symbol: String,
    #[serde(rename = "apyBase")]
    apy_base: Option<f64>,
}

/// Compact pool shape returned to the CRE workflow.
#[derive(Debug, Serialize, PartialEq)]
struct RelayPool {
    pool: String,
    chain: String,
    project: String,
    symbol: String,
    #[serde(rename = "apyBase")]
    apy_base: f64,
}

/// Top-level DefiLlama response shape.
#[derive(Debug, Deserialize)]
struct DefiLlamaResponse {
    data: Vec<Pool>,
}

/// Top-level relay response shape.
#[derive(Debug, Serialize)]
struct RelayResponse {
    data: Vec<RelayPool>,
}

/// Canonicalized pool IDs used to filter DefiLlama pools.
#[derive(Debug)]
struct Allowlists {
    pools: Vec<String>,
}

/// Count of upstream fetch+read operations currently in flight for this isolate.
static IN_FLIGHT_UPSTREAM_FETCHES: AtomicUsize = AtomicUsize::new(0);

/// RAII guard reserving one upstream-fetch slot for the lifetime of `handle_pools`.
///
/// Releases its slot on drop, covering every return path (success, upstream
/// error, parse error, timeout) without manual bookkeeping at each site.
///
/// Ordering is `Relaxed` throughout: this counter only needs to stay
/// internally correct, it does not need to establish a happens-before
/// relationship with any other memory, since nothing else is read or written
/// under its cap.
struct UpstreamFetchSlot;

impl UpstreamFetchSlot {
    fn try_acquire() -> Option<Self> {
        let mut current = IN_FLIGHT_UPSTREAM_FETCHES.load(AtomicOrdering::Relaxed);
        loop {
            if current >= MAX_CONCURRENT_UPSTREAM_FETCHES {
                return None;
            }
            match IN_FLIGHT_UPSTREAM_FETCHES.compare_exchange_weak(
                current,
                current + 1,
                AtomicOrdering::Relaxed,
                AtomicOrdering::Relaxed,
            ) {
                Ok(_) => return Some(Self),
                Err(observed) => current = observed,
            }
        }
    }
}

impl Drop for UpstreamFetchSlot {
    fn drop(&mut self) {
        let previous = IN_FLIGHT_UPSTREAM_FETCHES.fetch_sub(1, AtomicOrdering::Relaxed);
        debug_assert!(previous > 0);
    }
}

/// Cloudflare Worker entrypoint.
///
/// The relay exposes a single data endpoint and rejects every other route.
#[event(fetch)]
pub async fn main(req: Request, env: Env, _ctx: worker::Context) -> Result<Response> {
    match (req.method(), req.path().as_str()) {
        (Method::Get, "/v1/defillama/pools") => handle_pools(req, env).await,
        _ => response_with_status("not found", 404),
    }
}

/// Handles the DefiLlama relay endpoint.
///
/// The request must include the configured bearer token. On success, the worker
/// fetches DefiLlama's full pool response, filters it to approved pools, and
/// returns a compact JSON payload that fits within CRE's HTTP response quota.
///
/// Concurrent upstream fetches are capped at `MAX_CONCURRENT_UPSTREAM_FETCHES`
/// per isolate, so many simultaneous authenticated requests cannot multiply
/// buffered memory unboundedly.
async fn handle_pools(req: Request, env: Env) -> Result<Response> {
    let token = env.secret("RELAY_BEARER_TOKEN")?.to_string();
    if !is_valid_configured_token(&token) {
        return response_with_status("server misconfigured", 500);
    }
    if !is_authorized(&req, &token) {
        return response_with_status("unauthorized", 401);
    }

    let Some(_upstream_slot) = UpstreamFetchSlot::try_acquire() else {
        return response_with_status("too many concurrent requests", 429);
    };

    let upstream_url = upstream_url(optional_var(&env, "DEFILLAMA_UPSTREAM_URL")?.as_deref());
    let allowlists = allowlists_from_env(&env)?;

    let mut upstream_req = Request::new(&upstream_url, Method::Get)?;
    upstream_req
        .headers_mut()?
        .set("Accept", "application/json")?;

    let abort = AbortController::default();
    let signal = abort.signal();
    let fetch = async move {
        let mut upstream_resp = Fetch::Request(upstream_req)
            .send_with_signal(&signal)
            .await?;

        if upstream_resp.status_code() != 200 {
            return Err(upstream_error());
        }
        if upstream_success_too_large(upstream_content_length(&upstream_resp)?) {
            return Err(upstream_too_large_error());
        }

        read_upstream_json(&mut upstream_resp).await
    };
    let timeout = Delay::from(Duration::from_secs(UPSTREAM_READ_TIMEOUT_SECS));
    pin_mut!(fetch);
    pin_mut!(timeout);

    // Abort the Fetch signal before returning on timeout so a slow response
    // body is cancelled rather than only dropping the Rust future.
    let upstream = match select(fetch, timeout).await {
        Either::Left((Ok(upstream), _)) => upstream,
        Either::Left((Err(_), _)) => return response_with_status("upstream error", 502),
        Either::Right(((), _)) => {
            abort.abort();
            return response_with_status("upstream timeout", 504);
        }
    };
    let payload = filter_payload(upstream, &allowlists);

    let encoded = encode_payload(&payload)?;
    if relay_response_too_large(&encoded) {
        return response_with_status("filtered response too large", 502);
    }

    json_response(encoded)
}

/// Checks the Worker request `Authorization` header against the expected token.
fn is_authorized(req: &Request, expected_token: &str) -> bool {
    authorize_header(
        req.headers().get("Authorization").ok().flatten().as_deref(),
        expected_token,
    )
}

/// Checks whether an optional authorization header is the expected bearer token.
///
/// Accepted input is exactly `Bearer <token>`. The full header is capped before
/// parsing so unauthenticated requests cannot force comparison work proportional
/// to an attacker-chosen header length. After the prefix check, only the token
/// bytes are compared against the configured secret.
fn authorize_header(header: Option<&str>, expected_token: &str) -> bool {
    const BEARER_PREFIX: &str = "Bearer ";

    let Some(value) = header else {
        return false;
    };
    if value.len() > MAX_AUTH_HEADER_BYTES {
        return false;
    }

    let Some(token) = value.strip_prefix(BEARER_PREFIX) else {
        return false;
    };
    constant_time_eq(token, expected_token)
}

/// Compares bounded strings without byte-value short-circuiting.
///
/// The loop count is derived from the trusted expected value. This keeps runtime
/// independent of the provided token length after `authorize_header` has applied
/// the header cap, while still folding length mismatches into the result.
fn constant_time_eq(left: &str, right: &str) -> bool {
    let left = left.as_bytes();
    let right = right.as_bytes();
    let mut diff = left.len() ^ right.len();

    for index in 0..right.len() {
        let left_byte = left.get(index).copied().unwrap_or(0);
        let right_byte = right[index];
        diff |= usize::from(left_byte ^ right_byte);
    }

    diff == 0
}

/// Builds allowlists from Worker environment variables, falling back to defaults.
fn allowlists_from_env(env: &Env) -> Result<Allowlists> {
    Ok(build_allowlists(
        optional_var(env, "ALLOWED_POOLS")?.as_deref(),
    ))
}

/// Reads an optional Worker variable.
///
/// Missing variables are treated as `None` so defaults can be applied by the
/// caller.
fn optional_var(env: &Env, name: &str) -> Result<Option<String>> {
    match env.var(name) {
        Ok(value) => Ok(Some(value.to_string())),
        Err(_) => Ok(None),
    }
}

/// Parses a comma-separated allowlist into canonical values.
fn parse_csv(input: &str) -> Vec<String> {
    input
        .split(',')
        .map(canonical)
        .filter(|value| !value.is_empty())
        .collect()
}

/// Filters DefiLlama pools to exact allowed pool IDs and numeric base APY.
///
/// Pools with `null` base APY are dropped because the CRE workflow needs
/// protocol-native yield values to compare candidate pools.
///
/// Returned string fields are trimmed and bounded before they enter the relay
/// payload. Overlong metadata is rejected instead of truncated so CRE never
/// receives ambiguous chain/project/symbol values. The returned pool ID uses the
/// canonical, validated allowlist key rather than the raw upstream string, which
/// prevents padded IDs from amplifying the serialized response size.
///
/// Selection is intentionally independent of upstream ordering: the relay keeps
/// the best candidate per pool ID, sorts all candidates, then applies the
/// CRE-facing response count cap.
fn filter_payload(upstream: DefiLlamaResponse, allowlists: &Allowlists) -> RelayResponse {
    let max_pools = allowlists.pools.len().min(MAX_RELAY_POOLS);
    let mut by_pool = BTreeMap::new();

    for pool in upstream.data {
        let Some(key) = canonical_pool_id(&pool.pool) else {
            continue;
        };
        if !allowlists.pools.iter().any(|value| value == &key) {
            continue;
        }

        let Some(apy_base) = pool.apy_base else {
            continue;
        };
        if !apy_base.is_finite() {
            continue;
        }

        let Some(chain) = bounded_field(&pool.chain, MAX_CHAIN_BYTES) else {
            continue;
        };
        let Some(project) = bounded_field(&pool.project, MAX_PROJECT_BYTES) else {
            continue;
        };
        let Some(symbol) = bounded_field(&pool.symbol, MAX_SYMBOL_BYTES) else {
            continue;
        };

        let relay_pool = RelayPool {
            pool: key.clone(),
            chain,
            project,
            symbol,
            apy_base,
        };

        match by_pool.get_mut(&key) {
            Some(existing) => {
                if relay_pool_sorts_before(&relay_pool, existing) {
                    *existing = relay_pool;
                }
            }
            None => {
                by_pool.insert(key, relay_pool);
            }
        }
    }

    let mut data: Vec<_> = by_pool.into_values().collect();
    sort_relay_pools(&mut data);
    data.truncate(max_pools);

    RelayResponse { data }
}

/// Sorts relay pools deterministically for stable CRE-facing responses.
fn sort_relay_pools(pools: &mut [RelayPool]) {
    pools.sort_by(compare_relay_pools);
}

fn relay_pool_sorts_before(left: &RelayPool, right: &RelayPool) -> bool {
    compare_relay_pools(left, right) == Ordering::Less
}

fn compare_relay_pools(left: &RelayPool, right: &RelayPool) -> Ordering {
    right
        .apy_base
        .total_cmp(&left.apy_base)
        .then_with(|| left.chain.cmp(&right.chain))
        .then_with(|| left.project.cmp(&right.project))
        .then_with(|| left.symbol.cmp(&right.symbol))
        .then_with(|| left.pool.cmp(&right.pool))
}

/// Builds canonical allowlists from optional configured values.
fn build_allowlists(pools: Option<&str>) -> Allowlists {
    Allowlists {
        pools: parse_csv(pools.unwrap_or(DEFAULT_ALLOWED_POOLS)),
    }
}

/// Encodes the compact relay payload as JSON bytes.
fn encode_payload(payload: &RelayResponse) -> Result<Vec<u8>> {
    serde_json::to_vec(payload).map_err(|err| worker::Error::RustError(err.to_string()))
}

/// Reads and parses upstream JSON while enforcing the relay's hard byte cap.
///
/// `Content-Length` is only a cheap early reject. The authoritative protection
/// is this chunked read, which stops as soon as the actual body exceeds
/// `MAX_UPSTREAM_BYTES`, including chunked or incorrectly reported responses.
async fn read_upstream_json(resp: &mut Response) -> Result<DefiLlamaResponse> {
    let body = read_upstream_body(resp, MAX_UPSTREAM_BYTES).await?;
    parse_upstream_json(&body)
}

/// Reads a Worker response body without allowing it to grow past `limit` bytes.
///
/// Upstream responses must be stream-readable. Falling back to a one-shot
/// `bytes()` read would allocate the whole body before this function can enforce
/// `limit`, so non-streamable bodies are treated as upstream failures.
async fn read_upstream_body(resp: &mut Response, limit: usize) -> Result<Vec<u8>> {
    let mut body = Vec::new();
    let mut stream = resp
        .stream()
        .map_err(|_| upstream_stream_unavailable_error())?;

    while let Some(chunk) = stream.next().await {
        let chunk = chunk?;
        if upstream_body_too_large(body.len().saturating_add(chunk.len()), limit) {
            return Err(upstream_too_large_error());
        }
        body.extend_from_slice(&chunk);
    }

    Ok(body)
}

/// Parses the bounded upstream body into the subset of DefiLlama data we use.
///
/// Parser details are intentionally hidden from the caller. Malformed upstream
/// JSON is an upstream failure, not a client-facing diagnostic surface.
fn parse_upstream_json(body: &[u8]) -> Result<DefiLlamaResponse> {
    serde_json::from_slice(body).map_err(|_| upstream_parse_error())
}

/// Checks whether the actual upstream body bytes exceed the hard read limit.
fn upstream_body_too_large(body_len: usize, limit: usize) -> bool {
    body_len > limit
}

fn upstream_too_large_error() -> worker::Error {
    worker::Error::RustError("upstream response too large".to_string())
}

fn upstream_error() -> worker::Error {
    worker::Error::RustError("upstream error".to_string())
}

fn upstream_stream_unavailable_error() -> worker::Error {
    worker::Error::RustError("upstream response is not streamable".to_string())
}

fn upstream_parse_error() -> worker::Error {
    worker::Error::RustError("upstream parse error".to_string())
}

/// Returns the configured upstream URL or the production DefiLlama default.
fn upstream_url(value: Option<&str>) -> String {
    value.unwrap_or(DEFAULT_UPSTREAM_URL).to_string()
}

/// Checks whether a successful upstream response declares a body too large to parse.
///
/// This is only a cheap header precheck. A declared size equal to the hard read
/// limit is allowed so the header path matches `read_upstream_body`, which
/// rejects only actual bodies that exceed the limit.
fn upstream_success_too_large(content_length: Option<usize>) -> bool {
    match content_length {
        Some(length) => length > MAX_UPSTREAM_BYTES,
        None => false,
    }
}

/// Checks whether a response body exceeds the relay's CRE-facing size limit.
fn relay_response_too_large(body: &[u8]) -> bool {
    body.len() > MAX_RESPONSE_BYTES
}

/// Builds a JSON Worker response from encoded bytes.
fn json_response(body: Vec<u8>) -> Result<Response> {
    let headers = Headers::new();
    headers.set("Content-Type", "application/json")?;
    Ok(Response::from_bytes(body)?.with_headers(headers))
}

/// Converts a DefiLlama string value into the relay's comparison form.
fn canonical(value: &str) -> String {
    value.trim().to_ascii_lowercase()
}

/// Converts an untrusted upstream pool ID into comparison form after bounding size.
fn canonical_pool_id(value: &str) -> Option<String> {
    let value = value.trim();
    if value.len() > MAX_POOL_ID_BYTES {
        return None;
    }
    Some(value.to_ascii_lowercase())
}

/// Trims and bounds an untrusted upstream string before returning it to CRE.
///
/// Empty or overlong fields indicate malformed upstream metadata for this relay
/// and are dropped with their containing pool entry.
fn bounded_field(value: &str, max_bytes: usize) -> Option<String> {
    let value = value.trim();
    if value.is_empty() || value.len() > max_bytes {
        return None;
    }
    Some(value.to_string())
}

/// Builds a plain text Worker response with the provided status code.
fn response_with_status(message: &str, status: u16) -> Result<Response> {
    Ok(Response::ok(message)?.with_status(status))
}

/// Reads and parses a response `Content-Length` header when present.
fn upstream_content_length(resp: &Response) -> Result<Option<usize>> {
    match resp.headers().get("Content-Length") {
        Ok(Some(value)) => Ok(parse_content_length(&value)),
        Ok(None) | Err(_) => Ok(None),
    }
}

/// Parses a `Content-Length` header value.
fn parse_content_length(value: &str) -> Option<usize> {
    value.trim().parse::<usize>().ok()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn test_allowlists() -> Allowlists {
        Allowlists {
            pools: parse_csv(
                "aa70268e-4b52-42bf-a116-608b370f9501,\
                 d9c395b9-00d0-4426-a6b3-572a6dd68e54",
            ),
        }
    }

    fn pool(pool: &str, chain: &str, project: &str, symbol: &str, apy_base: Option<f64>) -> Pool {
        Pool {
            pool: pool.to_string(),
            chain: chain.to_string(),
            project: project.to_string(),
            symbol: symbol.to_string(),
            apy_base,
        }
    }

    #[test]
    fn parse_csv_trims_and_canonicalizes_values() {
        assert_eq!(
            parse_csv(" Ethereum, ARBITRUM ,, "),
            vec!["ethereum", "arbitrum"]
        );
    }

    #[test]
    fn filter_payload_returns_only_allowed_pools() {
        let upstream = DefiLlamaResponse {
            data: vec![
                pool(
                    "aa70268e-4b52-42bf-a116-608b370f9501",
                    "Ethereum",
                    "aave-v3",
                    "USDC",
                    Some(4.5),
                ),
                pool(
                    "d9c395b9-00d0-4426-a6b3-572a6dd68e54",
                    "Arbitrum",
                    "compound-v3",
                    "USDC",
                    Some(6.25),
                ),
                pool("not-allowed", "Ethereum", "aave-v3", "USDC", Some(9.0)),
            ],
        };

        let filtered = filter_payload(upstream, &test_allowlists());

        assert_eq!(
            filtered.data,
            vec![
                RelayPool {
                    pool: "d9c395b9-00d0-4426-a6b3-572a6dd68e54".to_string(),
                    chain: "Arbitrum".to_string(),
                    project: "compound-v3".to_string(),
                    symbol: "USDC".to_string(),
                    apy_base: 6.25,
                },
                RelayPool {
                    pool: "aa70268e-4b52-42bf-a116-608b370f9501".to_string(),
                    chain: "Ethereum".to_string(),
                    project: "aave-v3".to_string(),
                    symbol: "USDC".to_string(),
                    apy_base: 4.5,
                },
            ]
        );
    }

    #[test]
    fn filter_payload_sorts_pools_deterministically() {
        let upstream = DefiLlamaResponse {
            data: vec![
                pool(
                    "aa70268e-4b52-42bf-a116-608b370f9501",
                    "Ethereum",
                    "aave-v3",
                    "USDC",
                    Some(6.25),
                ),
                pool(
                    "d9c395b9-00d0-4426-a6b3-572a6dd68e54",
                    "Arbitrum",
                    "compound-v3",
                    "USDC",
                    Some(6.25),
                ),
            ],
        };

        let filtered = filter_payload(upstream, &test_allowlists());

        assert_eq!(
            filtered.data,
            vec![
                RelayPool {
                    pool: "d9c395b9-00d0-4426-a6b3-572a6dd68e54".to_string(),
                    chain: "Arbitrum".to_string(),
                    project: "compound-v3".to_string(),
                    symbol: "USDC".to_string(),
                    apy_base: 6.25,
                },
                RelayPool {
                    pool: "aa70268e-4b52-42bf-a116-608b370f9501".to_string(),
                    chain: "Ethereum".to_string(),
                    project: "aave-v3".to_string(),
                    symbol: "USDC".to_string(),
                    apy_base: 6.25,
                },
            ]
        );
    }

    #[test]
    fn filter_payload_deduplicates_pool_ids_deterministically() {
        let upstream = DefiLlamaResponse {
            data: vec![
                pool(
                    "aa70268e-4b52-42bf-a116-608b370f9501",
                    "Ethereum",
                    "aave-v3",
                    "USDC",
                    Some(4.5),
                ),
                pool(
                    "AA70268E-4B52-42BF-A116-608B370F9501",
                    "Ethereum",
                    "aave-v3",
                    "USDC",
                    Some(7.0),
                ),
                pool(
                    "d9c395b9-00d0-4426-a6b3-572a6dd68e54",
                    "Arbitrum",
                    "compound-v3",
                    "USDC",
                    Some(6.25),
                ),
            ],
        };

        let filtered = filter_payload(upstream, &test_allowlists());

        assert_eq!(
            filtered.data,
            vec![
                RelayPool {
                    pool: "aa70268e-4b52-42bf-a116-608b370f9501".to_string(),
                    chain: "Ethereum".to_string(),
                    project: "aave-v3".to_string(),
                    symbol: "USDC".to_string(),
                    apy_base: 7.0,
                },
                RelayPool {
                    pool: "d9c395b9-00d0-4426-a6b3-572a6dd68e54".to_string(),
                    chain: "Arbitrum".to_string(),
                    project: "compound-v3".to_string(),
                    symbol: "USDC".to_string(),
                    apy_base: 6.25,
                },
            ]
        );
    }

    #[test]
    fn filter_payload_is_case_insensitive() {
        let upstream = DefiLlamaResponse {
            data: vec![pool(
                "AA70268E-4B52-42BF-A116-608B370F9501",
                "ethereum",
                "AAVE-V3",
                "usdc",
                Some(4.5),
            )],
        };

        let filtered = filter_payload(upstream, &test_allowlists());

        assert_eq!(filtered.data.len(), 1);
    }

    #[test]
    fn filter_payload_returns_canonical_pool_id_for_padded_upstream_id() {
        let upstream = DefiLlamaResponse {
            data: vec![pool(
                "   AA70268E-4B52-42BF-A116-608B370F9501   ",
                "Ethereum",
                "aave-v3",
                "USDC",
                Some(4.5),
            )],
        };

        let filtered = filter_payload(upstream, &test_allowlists());

        assert_eq!(
            filtered.data,
            vec![RelayPool {
                pool: "aa70268e-4b52-42bf-a116-608b370f9501".to_string(),
                chain: "Ethereum".to_string(),
                project: "aave-v3".to_string(),
                symbol: "USDC".to_string(),
                apy_base: 4.5,
            }]
        );
    }

    #[test]
    fn filter_payload_drops_overlong_output_fields() {
        let upstream = DefiLlamaResponse {
            data: vec![
                pool(
                    "aa70268e-4b52-42bf-a116-608b370f9501",
                    &"a".repeat(MAX_CHAIN_BYTES + 1),
                    "aave-v3",
                    "USDC",
                    Some(4.5),
                ),
                pool(
                    "d9c395b9-00d0-4426-a6b3-572a6dd68e54",
                    "Arbitrum",
                    "compound-v3",
                    &"U".repeat(MAX_SYMBOL_BYTES + 1),
                    Some(6.25),
                ),
            ],
        };

        let filtered = filter_payload(upstream, &test_allowlists());

        assert!(filtered.data.is_empty());
    }

    #[test]
    fn filter_payload_trims_output_fields() {
        let upstream = DefiLlamaResponse {
            data: vec![pool(
                "aa70268e-4b52-42bf-a116-608b370f9501",
                " Ethereum ",
                " aave-v3 ",
                " USDC ",
                Some(4.5),
            )],
        };

        let filtered = filter_payload(upstream, &test_allowlists());

        assert_eq!(
            filtered.data,
            vec![RelayPool {
                pool: "aa70268e-4b52-42bf-a116-608b370f9501".to_string(),
                chain: "Ethereum".to_string(),
                project: "aave-v3".to_string(),
                symbol: "USDC".to_string(),
                apy_base: 4.5,
            }]
        );
    }

    #[test]
    fn filter_payload_drops_null_base_apy_pools() {
        let upstream = DefiLlamaResponse {
            data: vec![pool(
                "aa70268e-4b52-42bf-a116-608b370f9501",
                "Ethereum",
                "aave-v3",
                "USDC",
                None,
            )],
        };

        let filtered = filter_payload(upstream, &test_allowlists());

        assert!(filtered.data.is_empty());
    }

    #[test]
    fn constant_time_eq_requires_same_bytes() {
        assert!(constant_time_eq("Bearer secret", "Bearer secret"));
        assert!(!constant_time_eq("Bearer secret", "Bearer other"));
        assert!(!constant_time_eq("Bearer secret", "Bearer secretx"));
    }

    #[test]
    fn authorize_header_requires_expected_bearer_token() {
        assert!(authorize_header(Some("Bearer secret"), "secret"));
        assert!(!authorize_header(None, "secret"));
        assert!(!authorize_header(Some("secret"), "secret"));
        assert!(!authorize_header(Some("bearer secret"), "secret"));
        assert!(!authorize_header(Some("Bearersecret"), "secret"));
        assert!(!authorize_header(Some("Bearer other"), "secret"));
        assert!(!authorize_header(Some("Bearer secre"), "secret"));
        assert!(!authorize_header(Some("Bearer secrett"), "secret"));
    }

    #[test]
    fn is_valid_configured_token_rejects_empty_and_whitespace_only_values() {
        assert!(!is_valid_configured_token(""));
        assert!(!is_valid_configured_token("   "));
        assert!(!is_valid_configured_token("\n\t"));
        assert!(is_valid_configured_token("real-secret"));
    }

    #[test]
    fn authorize_header_rejects_oversized_headers_before_comparison() {
        let oversized = format!("Bearer {}", "a".repeat(MAX_AUTH_HEADER_BYTES));

        assert!(oversized.len() > MAX_AUTH_HEADER_BYTES);
        assert!(!authorize_header(Some(&oversized), "secret"));
    }

    #[test]
    fn constant_time_eq_handles_length_mismatches_without_requiring_equal_lengths() {
        assert!(constant_time_eq("Bearer secret", "Bearer secret"));
        assert!(!constant_time_eq("Bearer secre", "Bearer secret"));
        assert!(!constant_time_eq("Bearer secrett", "Bearer secret"));
        assert!(!constant_time_eq("", "Bearer secret"));
    }

    #[test]
    fn filter_payload_returns_empty_data_when_no_pools_match() {
        let upstream = DefiLlamaResponse {
            data: vec![pool("not-allowed", "Base", "aave-v3", "USDC", Some(4.5))],
        };

        let filtered = filter_payload(upstream, &test_allowlists());

        assert!(filtered.data.is_empty());
    }

    #[test]
    fn filter_payload_drops_non_finite_base_apy_pools() {
        let upstream = DefiLlamaResponse {
            data: vec![
                pool(
                    "aa70268e-4b52-42bf-a116-608b370f9501",
                    "Ethereum",
                    "aave-v3",
                    "USDC",
                    Some(f64::INFINITY),
                ),
                pool(
                    "d9c395b9-00d0-4426-a6b3-572a6dd68e54",
                    "Arbitrum",
                    "compound-v3",
                    "USDC",
                    Some(f64::NAN),
                ),
            ],
        };

        let filtered = filter_payload(upstream, &test_allowlists());

        assert!(filtered.data.is_empty());
    }

    #[test]
    fn filter_payload_drops_overlong_pool_ids() {
        let upstream = DefiLlamaResponse {
            data: vec![
                pool(
                    &"a".repeat(MAX_POOL_ID_BYTES + 1),
                    "Ethereum",
                    "aave-v3",
                    "USDC",
                    Some(99.0),
                ),
                pool(
                    "aa70268e-4b52-42bf-a116-608b370f9501",
                    "Ethereum",
                    "aave-v3",
                    "USDC",
                    Some(4.5),
                ),
            ],
        };

        let filtered = filter_payload(upstream, &test_allowlists());

        assert_eq!(
            filtered.data,
            vec![RelayPool {
                pool: "aa70268e-4b52-42bf-a116-608b370f9501".to_string(),
                chain: "Ethereum".to_string(),
                project: "aave-v3".to_string(),
                symbol: "USDC".to_string(),
                apy_base: 4.5,
            }]
        );
    }

    #[test]
    fn filter_payload_caps_relay_pool_count() {
        let allowed_pools: Vec<_> = (0..MAX_RELAY_POOLS + 1)
            .map(|index| format!("pool-{index}"))
            .collect();
        let upstream = DefiLlamaResponse {
            data: allowed_pools
                .iter()
                .map(|pool_id| pool(pool_id, "Ethereum", "aave-v3", "USDC", Some(4.5)))
                .collect(),
        };
        let allowlists = Allowlists {
            pools: allowed_pools,
        };

        let filtered = filter_payload(upstream, &allowlists);

        assert_eq!(filtered.data.len(), MAX_RELAY_POOLS);
    }

    #[test]
    fn filter_payload_applies_pool_count_cap_after_sorting_all_candidates() {
        let allowed_pools: Vec<_> = (0..MAX_RELAY_POOLS + 1)
            .map(|index| format!("pool-{index}"))
            .collect();
        let upstream = DefiLlamaResponse {
            data: allowed_pools
                .iter()
                .enumerate()
                .map(|(index, pool_id)| {
                    let apy_base = if index == MAX_RELAY_POOLS { 10.0 } else { 1.0 };
                    pool(pool_id, "Ethereum", "aave-v3", "USDC", Some(apy_base))
                })
                .collect(),
        };
        let allowlists = Allowlists {
            pools: allowed_pools,
        };

        let filtered = filter_payload(upstream, &allowlists);

        assert_eq!(filtered.data.len(), MAX_RELAY_POOLS);
        assert!(filtered
            .data
            .iter()
            .any(|pool| pool.pool == format!("pool-{MAX_RELAY_POOLS}")));
    }

    #[test]
    fn relay_response_stays_under_size_limit_for_small_payload() {
        let response = RelayResponse {
            data: vec![RelayPool {
                pool: "aa70268e-4b52-42bf-a116-608b370f9501".to_string(),
                chain: "Ethereum".to_string(),
                project: "aave-v3".to_string(),
                symbol: "USDC".to_string(),
                apy_base: 4.5,
            }],
        };

        let encoded = encode_payload(&response).expect("response encodes");

        assert!(!relay_response_too_large(&encoded));
    }

    #[test]
    fn default_allowed_pools_include_optimism_native_usdc_markets() {
        let pools = parse_csv(DEFAULT_ALLOWED_POOLS);
        assert!(pools.contains(&"0758c3b8-4ffb-4176-b0a9-f446e367db46".to_string()));
        assert!(pools.contains(&"b828f0cb-853d-4b32-aebb-2e20d7fd70a8".to_string()));
    }

    #[test]
    fn build_allowlists_uses_defaults_and_overrides() {
        let defaults = build_allowlists(None);
        assert!(defaults
            .pools
            .contains(&"aa70268e-4b52-42bf-a116-608b370f9501".to_string()));

        let custom = build_allowlists(Some(" pool-a, POOL-B "));
        assert_eq!(custom.pools, vec!["pool-a", "pool-b"]);
    }

    #[test]
    fn canonical_pool_id_rejects_overlong_values() {
        assert_eq!(canonical_pool_id(&"a".repeat(MAX_POOL_ID_BYTES + 1)), None);
    }

    #[test]
    fn upstream_url_uses_default_or_override() {
        assert_eq!(upstream_url(None), DEFAULT_UPSTREAM_URL);
        assert_eq!(
            upstream_url(Some("https://example.test/pools")),
            "https://example.test/pools"
        );
    }

    #[test]
    fn upstream_success_size_limit_uses_upstream_limit() {
        assert!(!upstream_success_too_large(None));
        assert!(!upstream_success_too_large(Some(MAX_UPSTREAM_BYTES - 1)));
        assert!(!upstream_success_too_large(Some(MAX_UPSTREAM_BYTES)));
        assert!(upstream_success_too_large(Some(MAX_UPSTREAM_BYTES + 1)));
    }

    #[test]
    fn upstream_body_size_limit_uses_actual_body_length() {
        assert!(!upstream_body_too_large(
            MAX_UPSTREAM_BYTES,
            MAX_UPSTREAM_BYTES
        ));
        assert!(upstream_body_too_large(
            MAX_UPSTREAM_BYTES + 1,
            MAX_UPSTREAM_BYTES
        ));
    }

    #[test]
    fn parse_upstream_json_reads_defillama_response_shape() {
        let parsed = parse_upstream_json(
            br#"{"data":[{"pool":"pool-a","chain":"Ethereum","project":"aave-v3","symbol":"USDC","apyBase":4.5}]}"#,
        )
        .expect("valid upstream JSON parses");

        assert_eq!(parsed.data.len(), 1);
        assert_eq!(parsed.data[0].pool, "pool-a");
        assert_eq!(parsed.data[0].apy_base, Some(4.5));
    }

    #[test]
    fn parse_upstream_json_returns_generic_error_for_invalid_json() {
        let err = parse_upstream_json(br#"{"data":["#).expect_err("invalid JSON fails");

        match err {
            worker::Error::RustError(message) => assert_eq!(message, "upstream parse error"),
            other => panic!("expected generic RustError, got {other:?}"),
        }
    }

    #[test]
    fn parse_content_length_treats_invalid_values_as_unknown() {
        assert_eq!(parse_content_length("not-a-number"), None);
        assert_eq!(parse_content_length("9999999999999999999999999999"), None);
        assert_eq!(parse_content_length(" 42 "), Some(42));
    }

    #[test]
    fn upstream_fetch_slot_bounds_concurrent_acquisitions() {
        let mut held: Vec<_> = (0..MAX_CONCURRENT_UPSTREAM_FETCHES)
            .map(|_| UpstreamFetchSlot::try_acquire().expect("slot available under cap"))
            .collect();

        assert!(
            UpstreamFetchSlot::try_acquire().is_none(),
            "acquisition past the cap must fail"
        );

        held.pop(); // drop exactly one held slot
        assert!(
            UpstreamFetchSlot::try_acquire().is_some(),
            "dropping a slot must free exactly one acquisition"
        );
    }

    #[test]
    fn relay_response_exceeds_size_limit_for_large_payload() {
        let response = RelayResponse {
            data: (0..2_000)
                .map(|index| RelayPool {
                    pool: format!("pool-{index}"),
                    chain: "Ethereum".to_string(),
                    project: "aave-v3".to_string(),
                    symbol: format!("USDC-{index}"),
                    apy_base: 4.5,
                })
                .collect(),
        };

        let encoded = encode_payload(&response).expect("response encodes");

        assert!(relay_response_too_large(&encoded));
    }
}

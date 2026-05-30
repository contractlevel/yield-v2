use serde::{Deserialize, Serialize};
use std::{cmp::Ordering, collections::BTreeMap};
use worker::{event, Env, Fetch, Headers, Method, Request, Response, Result};

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
const MAX_UPSTREAM_BYTES: usize = 25 * 1024 * 1024;

/// Maximum number of compact pool entries returned to CRE.
const MAX_RELAY_POOLS: usize = 32;

/// Maximum accepted byte length for an upstream DefiLlama pool ID.
const MAX_POOL_ID_BYTES: usize = 128;

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
async fn handle_pools(req: Request, env: Env) -> Result<Response> {
    let token = env.secret("RELAY_BEARER_TOKEN")?.to_string();
    if !is_authorized(&req, &token) {
        return response_with_status("unauthorized", 401);
    }

    let upstream_url = upstream_url(optional_var(&env, "DEFILLAMA_UPSTREAM_URL")?.as_deref());
    let allowlists = allowlists_from_env(&env)?;

    let mut upstream_req = Request::new(&upstream_url, Method::Get)?;
    upstream_req
        .headers_mut()?
        .set("Accept", "application/json")?;

    let mut upstream_resp = Fetch::Request(upstream_req).send().await?;
    if upstream_resp.status_code() != 200 {
        return response_with_status("upstream error", 502);
    }
    if upstream_success_too_large(upstream_content_length(&upstream_resp)?) {
        return response_with_status("upstream response too large", 502);
    }

    let upstream: DefiLlamaResponse = upstream_resp.json().await?;
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
fn authorize_header(header: Option<&str>, expected_token: &str) -> bool {
    let Some(value) = header else {
        return false;
    };
    constant_time_eq(value, &format!("Bearer {expected_token}"))
}

/// Compares strings without short-circuiting on mismatched lengths or bytes.
fn constant_time_eq(left: &str, right: &str) -> bool {
    let left = left.as_bytes();
    let right = right.as_bytes();
    let max_len = left.len().max(right.len());
    let mut diff = left.len() ^ right.len();

    for index in 0..max_len {
        let left_byte = left.get(index).copied().unwrap_or(0);
        let right_byte = right.get(index).copied().unwrap_or(0);
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

        let relay_pool = RelayPool {
            pool: pool.pool,
            chain: pool.chain,
            project: pool.project,
            symbol: pool.symbol,
            apy_base,
        };

        if let Some(existing) = by_pool.get_mut(&key) {
            if relay_pool_sorts_before(&relay_pool, existing) {
                *existing = relay_pool;
            }
            continue;
        }

        if by_pool.len() < max_pools {
            by_pool.insert(key, relay_pool);
        }
    }

    let mut data: Vec<_> = by_pool.into_values().collect();
    sort_relay_pools(&mut data);

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

/// Returns the configured upstream URL or the production DefiLlama default.
fn upstream_url(value: Option<&str>) -> String {
    value.unwrap_or(DEFAULT_UPSTREAM_URL).to_string()
}

/// Checks whether a successful upstream response declares a body too large to parse.
fn upstream_success_too_large(content_length: Option<usize>) -> bool {
    match content_length {
        Some(length) => length >= MAX_UPSTREAM_BYTES,
        None => true,
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
                    pool: "AA70268E-4B52-42BF-A116-608B370F9501".to_string(),
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
        assert!(!authorize_header(Some("Bearer other"), "secret"));
        assert!(!authorize_header(Some("Bearer secre"), "secret"));
        assert!(!authorize_header(Some("Bearer secrett"), "secret"));
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
        assert!(upstream_success_too_large(None));
        assert!(!upstream_success_too_large(Some(MAX_UPSTREAM_BYTES - 1)));
        assert!(upstream_success_too_large(Some(MAX_UPSTREAM_BYTES)));
        assert!(upstream_success_too_large(Some(MAX_UPSTREAM_BYTES + 1)));
    }

    #[test]
    fn parse_content_length_treats_invalid_values_as_unknown() {
        assert_eq!(parse_content_length("not-a-number"), None);
        assert_eq!(parse_content_length("9999999999999999999999999999"), None);
        assert_eq!(parse_content_length(" 42 "), Some(42));
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

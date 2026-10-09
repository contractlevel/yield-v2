mod config;
mod sources;

use config::{PoolConfig, RateSource, POOLS};

use futures_util::{
    future::{select, try_join_all, Either},
    pin_mut, StreamExt,
};
use serde::Serialize;
use std::time::Duration;
use worker::{
    event, AbortController, AbortSignal, Delay, Env, Fetch, Headers, Method, Request, RequestInit,
    RequestRedirect, Response, Result,
};

/// Wall-clock budget for all upstream requests in one refresh.
///
/// Fetch has no timeout of its own and scheduled events may run for 15 minutes,
/// so without this a hung refresh could overwrite KV during the rebalance.
const UPSTREAM_READ_TIMEOUT_SECS: u64 = 30;

/// Maximum body size for each Aave or Compound response.
const MAX_PROVIDER_BYTES: usize = 64 * 1024;

/// KV namespace binding declared in wrangler.toml.
const SNAPSHOT_KV_BINDING: &str = "POOL_SNAPSHOTS";
/// Single compact snapshot replaced only after a successful refresh.
const SNAPSHOT_KEY: &str = "pools";

/// Inclusive base APY bounds matching the Go workflow's pool selection policy.
const MIN_POOL_APY: f64 = 0.0;
const MAX_POOL_APY: f64 = 1000.0;

/// Constructs a relay error without including upstream payloads or secrets.
fn error(message: &str) -> worker::Error {
    worker::Error::RustError(message.to_owned())
}

/// Accepts finite base APYs in percentage units within the CRE policy bounds.
///
/// Zero and 1000% are accepted; negative, excessive, NaN, and infinite rates fail.
fn validate_apy(apy: f64) -> Result<f64> {
    if !apy.is_finite() || !(MIN_POOL_APY..=MAX_POOL_APY).contains(&apy) {
        return Err(error("invalid base APY"));
    }
    Ok(apy)
}

/// Compact pool shape returned to the CRE workflow.
#[derive(Debug, Serialize)]
struct RelayPool {
    pool: String,
    chain: String,
    project: String,
    symbol: String,
    #[serde(rename = "apyBase")]
    apy_base: f64,
}

/// Snapshot stored in KV and returned to the CRE workflow.
#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct Snapshot {
    refreshed_at: u64,
    data: Vec<RelayPool>,
}

fn encode_snapshot(snapshot: &Snapshot) -> Result<String> {
    if snapshot.data.is_empty() {
        return Err(error("empty snapshot"));
    }
    Ok(serde_json::to_string(snapshot)?)
}

/// Only scheduled refreshes fetch the upstream dataset. Failed refreshes leave KV unchanged.
#[event(scheduled)]
pub async fn scheduled(_event: worker::ScheduledEvent, env: Env, _ctx: worker::ScheduleContext) {
    if let Err(error) = refresh_snapshot(&env).await {
        worker::console_error!("DefiLlama snapshot refresh failed: {}", error);
    }
}

async fn refresh_snapshot(env: &Env) -> Result<()> {
    // Use the fetch start time; successful publication must not disguise a slow fetch's age.
    let refreshed_at = worker::Date::now().as_millis() / 1000;
    let data = fetch_pools(env).await?;
    let encoded = encode_snapshot(&Snapshot { refreshed_at, data })?;
    env.kv(SNAPSHOT_KV_BINDING)?
        .put(SNAPSHOT_KEY, encoded)?
        .execute()
        .await?;
    Ok(())
}

/// Cloudflare Worker entrypoint.
///
/// The relay exposes a single data endpoint and rejects every other route.
#[event(fetch)]
pub async fn main(req: Request, env: Env, _ctx: worker::Context) -> Result<Response> {
    match (req.method(), req.path().as_str()) {
        (Method::Get, "/v1/defillama/pools") => handle_pools(req, env).await,
        _ => Response::error("not found", 404),
    }
}

/// Authenticated reads only serve the saved snapshot; they never fetch upstream.
///
/// Freshness is enforced by the CRE workflow against DON time, not here.
async fn handle_pools(req: Request, env: Env) -> Result<Response> {
    let token = env.secret("RELAY_BEARER_TOKEN")?.to_string();
    // An empty secret would otherwise authorize "Bearer " with an empty token.
    if token.trim().is_empty() {
        return Response::error("server misconfigured", 500);
    }
    if !is_authorized(&req, &token) {
        return Response::error("unauthorized", 401);
    }
    let Some(encoded) = env
        .kv(SNAPSHOT_KV_BINDING)?
        .get(SNAPSHOT_KEY)
        .text()
        .await?
    else {
        return Response::error("snapshot unavailable", 503);
    };
    json_response(encoded.into_bytes())
}

/// Fetches every catalogue pool concurrently within one shared 30-second budget.
///
/// Every pool must return a valid rate. Any failed request, invalid rate, or
/// timeout fails the entire refresh, aborts outstanding requests, and leaves the
/// previous KV snapshot in place; callers never receive a partial snapshot.
async fn fetch_pools(env: &Env) -> Result<Vec<RelayPool>> {
    let abort = AbortController::default();
    let signal = abort.signal();
    let fetch = try_join_all(POOLS.iter().map(|pool| fetch_pool(env, pool, &signal)));
    let timeout = Delay::from(Duration::from_secs(UPSTREAM_READ_TIMEOUT_SECS));
    pin_mut!(fetch);
    pin_mut!(timeout);

    match select(fetch, timeout).await {
        Either::Left((Ok(data), _)) => Ok(data),
        Either::Left((Err(error), _)) => {
            abort.abort();
            Err(error)
        }
        Either::Right(((), _)) => {
            abort.abort();
            Err(error("upstream timeout"))
        }
    }
}

/// Fetches and validates one configured strategy, then attaches trusted metadata.
///
/// Aave needs one API request. Compound first reads utilization and then passes
/// that exact ABI word to its supply-rate call, using the configured RPC secret.
async fn fetch_pool(env: &Env, pool: &PoolConfig, signal: &AbortSignal) -> Result<RelayPool> {
    let apy = match pool.source {
        RateSource::AaveV3 { market } => {
            let request = sources::aave_v3_request(pool, market);
            let body = post_json(sources::AAVE_V3_URL, request, signal).await?;
            sources::parse_aave_v3_apy(&body, pool, market)?
        }
        RateSource::AaveV4 { spoke, reserve_id } => {
            let request = sources::aave_v4_request(pool, spoke, reserve_id);
            let body = post_json(sources::AAVE_V4_URL, request, signal).await?;
            sources::parse_aave_v4_apy(&body, pool, spoke, reserve_id)?
        }
        RateSource::CompoundV3 { rpc_secret, comet } => {
            let url = env
                .secret(rpc_secret)
                .map_err(|_| error("missing Compound RPC secret"))?
                .to_string();
            let request = sources::eth_call_request(comet, sources::GET_UTILIZATION);
            let utilization = post_json(&url, request, signal).await?;
            let call = sources::supply_rate_call(&utilization)?;
            let body = post_json(&url, sources::eth_call_request(comet, &call), signal).await?;
            sources::parse_compound_apy(&body)?
        }
    };
    Ok(pool.relay_pool(apy))
}

/// POSTs provider JSON under the shared abort signal and parses the bounded response.
///
/// Redirects are rejected. Transport errors are replaced with generic errors
/// so credential-bearing RPC URLs cannot appear in scheduled-refresh logs.
async fn post_json(
    url: &str,
    body: serde_json::Value,
    signal: &AbortSignal,
) -> Result<serde_json::Value> {
    let headers = Headers::new();
    headers.set("Accept", "application/json")?;
    headers.set("Content-Type", "application/json")?;
    let mut init = RequestInit::new();
    init.with_method(Method::Post)
        .with_headers(headers)
        .with_redirect(RequestRedirect::Manual)
        .with_body(Some(body.to_string().into()));
    let request = Request::new_with_init(url, &init).map_err(|_| error("upstream error"))?;
    let mut response = Fetch::Request(request)
        .send_with_signal(signal)
        .await
        .map_err(|_| error("upstream error"))?;
    if response.status_code() != 200 {
        return Err(error("upstream error"));
    }
    let body = read_bounded(&mut response).await?;
    serde_json::from_slice(&body).map_err(|_| error("upstream parse error"))
}

/// Streams a provider response body, failing once it exceeds MAX_PROVIDER_BYTES.
///
/// Streaming enforces the limit before the whole body is buffered. Bodies that
/// cannot be streamed fail rather than falling back to an unbounded read.
async fn read_bounded(response: &mut Response) -> Result<Vec<u8>> {
    let mut stream = response.stream().map_err(|_| error("upstream error"))?;
    let mut body = Vec::new();
    while let Some(chunk) = stream.next().await {
        append_bounded(&mut body, &chunk.map_err(|_| error("upstream error"))?)?;
    }
    Ok(body)
}

/// Appends a chunk only if the body stays within MAX_PROVIDER_BYTES.
///
/// Capacity is checked before appending, so a rejected chunk leaves `body` unchanged.
fn append_bounded(body: &mut Vec<u8>, chunk: &[u8]) -> Result<()> {
    if chunk.len() > MAX_PROVIDER_BYTES - body.len() {
        return Err(error("upstream response too large"));
    }
    body.extend_from_slice(chunk);
    Ok(())
}

/// Checks the Worker request `Authorization` header against the expected token.
fn is_authorized(req: &Request, expected_token: &str) -> bool {
    authorize_header(
        req.headers().get("Authorization").ok().flatten().as_deref(),
        expected_token,
    )
}

/// Checks whether an optional authorization header is exactly `Bearer <expected_token>`.
fn authorize_header(header: Option<&str>, expected_token: &str) -> bool {
    header
        .and_then(|value| value.strip_prefix("Bearer "))
        .is_some_and(|token| constant_time_eq(token, expected_token))
}

/// Compares strings without byte-value short-circuiting.
///
/// The loop runs over the trusted `right` value, so runtime does not depend on
/// the client-supplied `left` value; length mismatches are folded into the result.
fn constant_time_eq(left: &str, right: &str) -> bool {
    let left = left.as_bytes();
    let right = right.as_bytes();
    let mut diff = left.len() ^ right.len();

    for (index, &right_byte) in right.iter().enumerate() {
        let left_byte = left.get(index).copied().unwrap_or(0);
        diff |= usize::from(left_byte ^ right_byte);
    }

    diff == 0
}

/// Builds a JSON Worker response from encoded bytes.
fn json_response(body: Vec<u8>) -> Result<Response> {
    let headers = Headers::new();
    headers.set("Content-Type", "application/json")?;
    Ok(Response::from_bytes(body)?.with_headers(headers))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn constant_time_eq_requires_same_bytes_and_length() {
        assert!(constant_time_eq("secret", "secret"));
        assert!(!constant_time_eq("secrex", "secret"));
        assert!(!constant_time_eq("secre", "secret"));
        assert!(!constant_time_eq("secrett", "secret"));
        assert!(!constant_time_eq("", "secret"));
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
    fn append_bounded_accepts_chunks_up_to_the_exact_limit() {
        let mut body = Vec::new();
        append_bounded(&mut body, &vec![1; MAX_PROVIDER_BYTES - 1]).unwrap();
        append_bounded(&mut body, &[2]).unwrap();
        append_bounded(&mut body, &[]).unwrap();
        assert_eq!(body.len(), MAX_PROVIDER_BYTES);
        assert_eq!(body.last(), Some(&2));
    }

    #[test]
    fn append_bounded_rejects_crossing_chunks_and_leaves_body_unchanged() {
        let mut body = Vec::new();
        append_bounded(&mut body, &vec![1; MAX_PROVIDER_BYTES - 1]).unwrap();
        let error = append_bounded(&mut body, &[2, 3]).unwrap_err();
        assert_eq!(error.to_string(), "upstream response too large");
        assert_eq!(body, vec![1; MAX_PROVIDER_BYTES - 1]);

        let mut full = vec![1; MAX_PROVIDER_BYTES];
        assert!(append_bounded(&mut full, &[2]).is_err());
        assert_eq!(full.len(), MAX_PROVIDER_BYTES);
        assert!(append_bounded(&mut Vec::new(), &vec![1; MAX_PROVIDER_BYTES + 1]).is_err());
    }

    #[test]
    fn snapshot_encodes_cre_shape_and_rejects_empty_data() {
        let snapshot = Snapshot {
            refreshed_at: 1000,
            data: vec![RelayPool {
                pool: "pool-a".to_owned(),
                chain: "Polygon".to_owned(),
                project: "aave-v3".to_owned(),
                symbol: "USDC".to_owned(),
                apy_base: 4.5,
            }],
        };
        let encoded = encode_snapshot(&snapshot).expect("valid snapshot");
        let decoded: serde_json::Value = serde_json::from_str(&encoded).unwrap();
        assert_eq!(
            decoded,
            serde_json::json!({
                "refreshedAt": 1000,
                "data": [{
                    "pool": "pool-a",
                    "chain": "Polygon",
                    "project": "aave-v3",
                    "symbol": "USDC",
                    "apyBase": 4.5
                }]
            })
        );
        assert!(encode_snapshot(&Snapshot {
            refreshed_at: 1000,
            data: vec![]
        })
        .is_err());
    }
}

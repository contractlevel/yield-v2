//! Request construction and response validation for protocol-native base yields.
//!
//! All functions are synchronous and perform no network or secret access.
//! Aave decimal strings and Compound ABI words are converted to percentage APY;
//! callers remain responsible for HTTP status, timeout, and publication.

use crate::{config::PoolConfig, error, validate_apy};
use serde_json::{json, Value};
use worker::Result;

/// Official Aave V3 GraphQL endpoint for exact market/token reserve queries.
pub(crate) const AAVE_V3_URL: &str = "https://api.v3.aave.com/graphql";
/// Official Aave V4 GraphQL endpoint for exact chain/Spoke/reserve queries.
pub(crate) const AAVE_V4_URL: &str = "https://api.v4.aave.com/graphql";
/// Four-byte selector for Comet getUtilization(), which takes no arguments.
pub(crate) const GET_UTILIZATION: &str = "0x7eb71131";
/// Four-byte selector for Comet getSupplyRate(uint256), which returns uint64.
const GET_SUPPLY_RATE: &str = "0xd955759d";

/// Builds an Aave V3 reserve query for the configured market and asset.
///
/// Requests the base supply APY fraction and the identifiers that
/// parse_aave_v3_apy verifies. Incentive rates are not requested.
pub(crate) fn aave_v3_request(config: &PoolConfig, market: &str) -> Value {
    json!({
        "query": "query($request: ReserveRequest!) { reserve(request: $request) { market { address } underlyingToken { address chainId } supplyInfo { apy { value } } } }",
        "variables": { "request": {
            "market": market, "chainId": config.chain_id,
            "underlyingToken": config.asset
        } }
    })
}

/// Builds an Aave V4 reserve query for the configured Spoke and reserve ID.
///
/// Requests the base supply APY percentage and the identifiers that
/// parse_aave_v4_apy verifies. Reward rates are not requested.
pub(crate) fn aave_v4_request(config: &PoolConfig, spoke: &str, reserve_id: &str) -> Value {
    json!({
        "query": "query($request: ReserveRequest!) { reserve(request: $request) { onChainId chain { chainId } spoke { address } asset { underlying { address } } summary { supplyApy { normalized } } } }",
        "variables": { "request": { "query": { "reserveInput": {
            "chainId": config.chain_id, "spoke": spoke,
            "onChainId": reserve_id
        } } } }
    })
}

/// Extracts the configured V3 reserve's base supply APY in percentage units.
///
/// supplyInfo.apy.value is a fraction, so it is multiplied by 100.
pub(crate) fn parse_aave_v3_apy(body: &Value, config: &PoolConfig, market: &str) -> Result<f64> {
    let reserve = aave_reserve(body)?;
    require_reserve(
        reserve,
        &[
            ("/market/address", market),
            ("/underlyingToken/address", config.asset),
        ],
        "/underlyingToken/chainId",
        config.chain_id,
    )?;
    validate_apy(decimal(reserve, "/supplyInfo/apy/value")? * 100.0)
}

/// Extracts the configured V4 reserve's base supply APY in percentage units.
///
/// summary.supplyApy.normalized is already a percentage.
pub(crate) fn parse_aave_v4_apy(
    body: &Value,
    config: &PoolConfig,
    spoke: &str,
    reserve_id: &str,
) -> Result<f64> {
    let reserve = aave_reserve(body)?;
    require_reserve(
        reserve,
        &[
            ("/spoke/address", spoke),
            ("/asset/underlying/address", config.asset),
            ("/onChainId", reserve_id),
        ],
        "/chain/chainId",
        config.chain_id,
    )?;
    validate_apy(decimal(reserve, "/summary/supplyApy/normalized")?)
}

/// Rejects GraphQL errors and returns the reserve object.
///
/// GraphQL can return HTTP 200 with partial data alongside errors, so any
/// nonempty or malformed errors field fails. Error messages exclude payloads.
fn aave_reserve(body: &Value) -> Result<&Value> {
    if body
        .get("errors")
        .is_some_and(|errors| errors.as_array().is_none_or(|errors| !errors.is_empty()))
    {
        return Err(error("Aave GraphQL error"));
    }
    body.pointer("/data/reserve")
        .filter(|reserve| reserve.is_object())
        .ok_or_else(|| error("Aave reserve unavailable"))
}

/// Requires the returned reserve to be the one requested.
///
/// String identifiers compare ignoring ASCII case; absent, non-string, or padded
/// values fail. The chain ID must be an unsigned JSON integer.
fn require_reserve(
    reserve: &Value,
    ids: &[(&str, &str)],
    chain_path: &str,
    chain_id: u64,
) -> Result<()> {
    let ids_match = ids.iter().all(|(path, expected)| {
        reserve
            .pointer(path)
            .and_then(Value::as_str)
            .is_some_and(|actual| actual.eq_ignore_ascii_case(expected))
    });
    if !ids_match || reserve.pointer(chain_path).and_then(Value::as_u64) != Some(chain_id) {
        return Err(error("Aave reserve mismatch"));
    }
    Ok(())
}

/// Parses an Aave decimal string at a JSON pointer without changing its units.
///
/// Numeric JSON values and missing/null fields fail. Final finiteness and range
/// checks belong to validate_apy after the provider's percentage conversion.
fn decimal(value: &Value, path: &str) -> Result<f64> {
    value
        .pointer(path)
        .and_then(Value::as_str)
        .ok_or_else(|| error("missing Aave rate"))?
        .parse()
        .map_err(|_| error("invalid Aave rate"))
}

/// Builds a read-only eth_call to the configured Comet at the latest block.
///
/// data must already contain its function selector and any ABI arguments.
/// The URL and credentials are not included.
pub(crate) fn eth_call_request(comet: &str, data: &str) -> Value {
    json!({
        "jsonrpc": "2.0", "id": 1, "method": "eth_call",
        "params": [{ "to": comet, "data": data }, "latest"]
    })
}

/// Validates a JSON-RPC eth_call response and borrows its 32-byte ABI result word.
///
/// Requires jsonrpc "2.0", integer id 1, no error field, and "0x" followed by
/// exactly 64 hex digits. This checks encoding, not the value's meaning.
fn rpc_word(body: &Value) -> Result<&str> {
    if body.get("error").is_some()
        || body.get("jsonrpc").and_then(Value::as_str) != Some("2.0")
        || body.get("id").and_then(Value::as_u64) != Some(1)
    {
        return Err(error("Compound RPC error"));
    }
    body.get("result")
        .and_then(Value::as_str)
        .and_then(|result| result.strip_prefix("0x"))
        .filter(|word| word.len() == 64 && word.bytes().all(|byte| byte.is_ascii_hexdigit()))
        .ok_or_else(|| error("invalid Compound ABI result"))
}

/// Encodes getSupplyRate(uint256) calldata from the validated utilization response.
///
/// getUtilization returns uint256, so its 32-byte word is passed through unchanged.
pub(crate) fn supply_rate_call(utilization: &Value) -> Result<String> {
    Ok(format!("{GET_SUPPLY_RATE}{}", rpc_word(utilization)?))
}

/// Decodes Comet's uint64, 1e18-scaled per-second supply rate as compounded APY.
///
/// Nonzero bits above the low 64 do not fit uint64 and are rejected.
pub(crate) fn parse_compound_apy(body: &Value) -> Result<f64> {
    let rate = u64::from_str_radix(rpc_word(body)?, 16)
        .map_err(|_| error("invalid Compound supply rate"))?;
    compound_apy(rate)
}

/// Projects a constant 1e18-scaled per-second rate into compounded percentage APY.
///
/// Uses a 365-day year (31,536,000 seconds):
/// 100 * ((1 + rate / 1e18)^31,536,000 - 1).
/// ln_1p and exp_m1 avoid cancellation when per-second rates are tiny.
/// This is effective annual yield, not simple annualized APR or reward yield.
/// Zero is accepted; non-finite results and APYs above the CRE bound fail.
fn compound_apy(rate: u64) -> Result<f64> {
    validate_apy(100.0 * (31_536_000.0 * (rate as f64 / 1e18).ln_1p()).exp_m1())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::POOLS;

    // Identifiers of the Ethereum Aave V3 (POOLS[0]) and V4 Core (POOLS[2]) strategies.
    const V3_MARKET: &str = "0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2";
    const V4_SPOKE: &str = "0x94e7A5dCbE816e498b89aB752661904E2F56c485";
    const V4_RESERVE_ID: &str = "7";

    // Fixed parsers let one table test cover both Aave versions.
    type Parse = fn(&Value) -> Result<f64>;
    const PARSE_V3: Parse = |body| parse_aave_v3_apy(body, &POOLS[0], V3_MARKET);
    const PARSE_V4: Parse = |body| parse_aave_v4_apy(body, &POOLS[2], V4_SPOKE, V4_RESERVE_ID);

    // Fixed provider fixtures keep the expected response shapes independent
    // of the request builders and pool configuration under test.
    fn v3_response() -> Value {
        json!({ "data": { "reserve": {
            "market": { "address": "0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2" },
            "underlyingToken": {
                "address": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
                "chainId": 1
            },
            "supplyInfo": { "apy": { "value": "0.035" } }
        } } })
    }

    fn v4_response() -> Value {
        json!({ "data": { "reserve": {
            "onChainId": "7",
            "chain": { "chainId": 1 },
            "spoke": { "address": "0x94e7A5dCbE816e498b89aB752661904E2F56c485" },
            "asset": { "underlying": {
                "address": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
            } },
            "summary": { "supplyApy": { "normalized": "3.5" } }
        } } })
    }

    fn rpc_response(result: Value) -> Value {
        json!({ "jsonrpc": "2.0", "id": 1, "result": result })
    }

    const V3_RATE: &str = "/data/reserve/supplyInfo/apy/value";
    const V4_RATE: &str = "/data/reserve/summary/supplyApy/normalized";

    fn assert_error<T: std::fmt::Debug>(result: Result<T>, expected: &str) {
        assert_eq!(
            result.expect_err("response must fail").to_string(),
            expected
        );
    }

    #[test]
    fn aave_requests_use_exact_reserve_variables_and_base_rate_fields() {
        let v3 = aave_v3_request(&POOLS[0], V3_MARKET);
        assert_eq!(
            v3["variables"],
            json!({ "request": {
            "market": "0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2",
            "chainId": 1,
            "underlyingToken": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
        } })
        );
        assert!(v3["query"]
            .as_str()
            .unwrap()
            .contains("supplyInfo { apy { value } }"));
        let v4 = aave_v4_request(&POOLS[2], V4_SPOKE, V4_RESERVE_ID);
        assert_eq!(
            v4["variables"],
            json!({ "request": { "query": {
            "reserveInput": {
                "chainId": 1,
                "spoke": "0x94e7A5dCbE816e498b89aB752661904E2F56c485",
                "onChainId": "7"
            }
        } } })
        );
        assert!(v4["query"]
            .as_str()
            .unwrap()
            .contains("summary { supplyApy { normalized } }"));
    }

    #[test]
    fn aave_rates_are_percentages_and_ignore_rewards() {
        let mut v3 = v3_response();
        v3["data"]["reserve"]["incentives"] = json!([{ "apy": "99" }]);
        assert!((PARSE_V3(&v3).unwrap() - 3.5).abs() < 1e-12);
        let mut v4 = v4_response();
        v4["data"]["reserve"]["summary"]["rewards"] = json!([{ "apy": "99" }]);
        assert_eq!(PARSE_V4(&v4).unwrap(), 3.5);
    }

    #[test]
    fn aave_rejects_graphql_errors_but_accepts_an_empty_list() {
        for (mut body, parse) in [(v3_response(), PARSE_V3), (v4_response(), PARSE_V4)] {
            body["errors"] = json!([]);
            assert!(parse(&body).is_ok());
            for errors in [
                json!([{ "message": "sensitive upstream detail" }]),
                Value::Null,
            ] {
                body["errors"] = errors;
                assert_error(parse(&body), "Aave GraphQL error");
            }
        }
    }

    #[test]
    fn aave_requires_a_reserve_object() {
        for body in [
            json!({}),
            json!({ "data": { "reserve": null } }),
            json!({ "data": { "reserve": [] } }),
        ] {
            assert_error(PARSE_V3(&body), "Aave reserve unavailable");
        }
    }

    #[test]
    fn aave_accepts_addresses_in_any_case() {
        let mut body = v3_response();
        body["data"]["reserve"]["market"]["address"] =
            json!("0x87870bca3f3fd6335c3f4ce8392d69350b4fa4e2");
        assert!(PARSE_V3(&body).is_ok());
    }

    #[test]
    fn aave_rejects_a_different_reserve() {
        for (mut body, parse, path, wrong) in [
            (
                v3_response(),
                PARSE_V3,
                "/data/reserve/market/address",
                json!("0xwrong"),
            ),
            (
                v3_response(),
                PARSE_V3,
                "/data/reserve/underlyingToken/address",
                json!("0xwrong"),
            ),
            (
                v3_response(),
                PARSE_V3,
                "/data/reserve/underlyingToken/chainId",
                json!(8453),
            ),
            (
                v4_response(),
                PARSE_V4,
                "/data/reserve/spoke/address",
                json!("0xwrong"),
            ),
            (
                v4_response(),
                PARSE_V4,
                "/data/reserve/asset/underlying/address",
                json!(null),
            ),
            (
                v4_response(),
                PARSE_V4,
                "/data/reserve/onChainId",
                json!("2"),
            ),
            (
                v4_response(),
                PARSE_V4,
                "/data/reserve/chain/chainId",
                json!("1"),
            ),
        ] {
            *body.pointer_mut(path).unwrap() = wrong;
            assert_error(parse(&body), "Aave reserve mismatch");
        }
    }

    #[test]
    fn aave_rates_must_be_decimal_strings() {
        for (fixture, parse, path) in [
            (v3_response(), PARSE_V3, V3_RATE),
            (v4_response(), PARSE_V4, V4_RATE),
        ] {
            for (invalid, expected) in [
                (Value::Null, "missing Aave rate"),
                (json!(3.5), "missing Aave rate"),
                (json!("abc"), "invalid Aave rate"),
            ] {
                let mut body = fixture.clone();
                *body.pointer_mut(path).unwrap() = invalid;
                assert_error(parse(&body), expected);
            }
        }
    }

    #[test]
    fn aave_rates_enforce_inclusive_apy_bounds() {
        for (fixture, parse, path, maximum, above) in [
            (v3_response(), PARSE_V3, V3_RATE, "10", "10.0001"),
            (v4_response(), PARSE_V4, V4_RATE, "1000", "1000.01"),
        ] {
            for (rate, expected) in [("0", 0.0), (maximum, 1000.0)] {
                let mut body = fixture.clone();
                *body.pointer_mut(path).unwrap() = json!(rate);
                assert_eq!(parse(&body).unwrap(), expected);
            }
            for rate in ["-0.01", above, "NaN"] {
                let mut body = fixture.clone();
                *body.pointer_mut(path).unwrap() = json!(rate);
                assert_error(parse(&body), "invalid base APY");
            }
        }
    }

    #[test]
    fn compound_requests_are_read_only_calls_to_the_configured_comet() {
        let comet = "0xc3d688B66703497DAA19211EEdff47f25384cdc3";
        assert_eq!(
            eth_call_request(comet, GET_UTILIZATION),
            json!({
                "jsonrpc": "2.0", "id": 1, "method": "eth_call",
                "params": [{ "to": comet, "data": "0x7eb71131" }, "latest"]
            })
        );
        let word = format!("{:064x}", 500_000_000_000_000_000_u64);
        let call = supply_rate_call(&rpc_response(json!(format!("0x{word}")))).unwrap();
        assert_eq!(call, format!("0xd955759d{word}"));
        assert_eq!(eth_call_request(comet, &call)["params"][0]["data"], call);
    }

    #[test]
    fn utilization_word_passes_through_unchanged() {
        let word = "f".repeat(64);
        let call = supply_rate_call(&rpc_response(json!(format!("0x{word}")))).unwrap();
        assert_eq!(call, format!("0xd955759d{word}"));
    }

    #[test]
    fn compound_rejects_rpc_errors_and_mismatched_envelopes() {
        let valid = rpc_response(json!(format!("0x{:064x}", 1)));
        for (field, invalid) in [
            ("jsonrpc", json!("1.0")),
            ("jsonrpc", json!(2)),
            ("id", json!("1")),
            ("id", json!(1.0)),
            ("id", json!(2)),
            ("error", json!({ "message": "sensitive RPC detail" })),
        ] {
            let mut body = valid.clone();
            body[field] = invalid;
            assert_error(supply_rate_call(&body), "Compound RPC error");
        }
        for field in ["jsonrpc", "id"] {
            let mut body = valid.clone();
            body.as_object_mut().unwrap().remove(field);
            assert_error(parse_compound_apy(&body), "Compound RPC error");
        }
        assert_error(
            parse_compound_apy(&json!({ "jsonrpc": "1.0", "id": 999, "result": "0x0" })),
            "Compound RPC error",
        );
    }

    #[test]
    fn compound_requires_one_complete_hex_abi_word() {
        for invalid in [
            json!("0x0"),
            json!(format!("0x{}", "0".repeat(63))),
            json!(format!("0x{}", "0".repeat(65))),
            json!(format!("0X{}", "0".repeat(64))),
            json!("0".repeat(64)),
            json!(format!("0x{}", "g".repeat(64))),
            json!(1),
            Value::Null,
        ] {
            assert_error(
                supply_rate_call(&rpc_response(invalid)),
                "invalid Compound ABI result",
            );
        }
    }

    #[test]
    fn parse_compound_apy_decodes_uint64_rates_only() {
        let rate = |value: u128| rpc_response(json!(format!("0x{value:064x}")));
        assert_eq!(parse_compound_apy(&rate(0)).unwrap(), 0.0);
        let apy = parse_compound_apy(&rate(1_000_000_000)).unwrap();
        assert!((apy - 3.2038528297639104).abs() < 1e-12);
        assert_error(
            parse_compound_apy(&rate(u64::MAX as u128 + 1)),
            "invalid Compound supply rate",
        );
        assert_error(
            parse_compound_apy(&rate(u64::MAX.into())),
            "invalid base APY",
        );
    }

    #[test]
    fn compound_compounds_small_rates_without_losing_precision() {
        assert_eq!(compound_apy(0).unwrap(), 0.0);
        assert!((compound_apy(1).unwrap() - 3.153600000049726e-9).abs() < 1e-20);
        let apy = compound_apy(1_000_000_000).unwrap();
        assert!((apy - 3.2038528297639104).abs() < 1e-12);
        assert!(apy > 3.1536); // Simple annualized APR for the same rate.
        let rates = [1, 10, 1_000, 1_000_000, 1_000_000_000];
        assert!(rates
            .windows(2)
            .all(|pair| { compound_apy(pair[0]).unwrap() < compound_apy(pair[1]).unwrap() }));
    }

    #[test]
    fn compound_enforces_the_apy_limit_and_rejects_exponential_overflow() {
        assert!(compound_apy(76_036_763_190).unwrap() <= 1000.0);
        assert_error(compound_apy(76_036_763_191), "invalid base APY");
        assert_error(compound_apy(1_000_000_000_000_000_000), "invalid base APY");
        assert_error(compound_apy(u64::MAX), "invalid base APY");
    }
}

//! Fixed native-USDC strategies and CRE-compatible response metadata.
//!
//! This module performs no I/O and contains no RPC credentials. Every strategy
//! is refreshed; adding or removing one requires an explicit code change.

use crate::RelayPool;

/// Protocol-specific identifiers needed to fetch a strategy's base supply rate.
///
/// Chain ID and underlying USDC address are shared fields on PoolConfig.
#[derive(Debug, Clone, Copy)]
pub(crate) enum RateSource {
    /// Aave V3 Pool address used as the GraphQL market identifier.
    AaveV3 { market: &'static str },
    /// Aave V4 Spoke address and its onchain reserve ID, encoded as a decimal string.
    AaveV4 {
        spoke: &'static str,
        reserve_id: &'static str,
    },
    /// Worker secret name for the RPC URL and the native-USDC Comet address.
    ///
    /// The secret's value is resolved by the fetcher, never stored in this table.
    CompoundV3 {
        rpc_secret: &'static str,
        comet: &'static str,
    },
}

/// One supported strategy, combining its stable CRE identity and upstream target.
#[derive(Debug)]
pub(crate) struct PoolConfig {
    /// Legacy DefiLlama UUID retained as the deployed workflow's stable pool ID.
    pub pool: &'static str,
    /// Exact CRE-facing chain label; Optimism must remain "OP Mainnet".
    pub chain: &'static str,
    /// EIP-155 chain ID for upstream queries, not a Chainlink chain selector.
    pub chain_id: u64,
    /// Native USDC address; bridged USDC variants are deliberately excluded.
    pub asset: &'static str,
    /// Exact protocol market from which this strategy's rate must be read.
    pub source: RateSource,
}

impl PoolConfig {
    /// Combines a fetched base APY with the fixed metadata expected by CRE.
    ///
    /// apy_base is a percentage: 3.5 means 3.5%, not 350%. The caller must
    /// validate the rate before publication; this method only builds the value.
    /// Project is derived from the source to prevent inconsistent configuration.
    /// Every supported strategy uses USDC, so symbol is fixed.
    pub fn relay_pool(&self, apy_base: f64) -> RelayPool {
        RelayPool {
            pool: self.pool.to_owned(),
            chain: self.chain.to_owned(),
            project: match self.source {
                RateSource::AaveV3 { .. } => "aave-v3",
                RateSource::AaveV4 { .. } => "aave-v4",
                RateSource::CompoundV3 { .. } => "compound-v3",
            }
            .to_owned(),
            symbol: "USDC".to_owned(),
            apy_base,
        }
    }
}

/// The 12 mainnet strategies already allowlisted by the deployed CRE workflow.
///
/// USDC, Spoke, and Comet addresses match evm/script/HelperConfig.s.sol. Aave V3
/// Pool addresses and V4 reserve IDs were resolved through the official Aave
/// APIs. Ethereum and Avalanche V4 entries target their configured Core Spokes.
/// UUIDs remain unchanged even though DefiLlama is no longer the rate source.
pub(crate) const POOLS: &[PoolConfig] = &[
    PoolConfig {
        pool: "aa70268e-4b52-42bf-a116-608b370f9501",
        chain: "Ethereum",
        chain_id: 1,
        asset: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
        source: RateSource::AaveV3 {
            market: "0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2",
        },
    },
    PoolConfig {
        pool: "7da72d09-56ca-4ec5-a45f-59114353e487",
        chain: "Ethereum",
        chain_id: 1,
        asset: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
        source: RateSource::CompoundV3 {
            rpc_secret: "ETHEREUM_RPC_URL",
            comet: "0xc3d688B66703497DAA19211EEdff47f25384cdc3",
        },
    },
    PoolConfig {
        pool: "4ac1a968-68ab-4da8-87e3-8f1e15e3dae2",
        chain: "Ethereum",
        chain_id: 1,
        asset: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
        source: RateSource::AaveV4 {
            spoke: "0x94e7A5dCbE816e498b89aB752661904E2F56c485",
            reserve_id: "7",
        },
    },
    PoolConfig {
        pool: "d9fa8e14-0447-4207-9ae8-7810199dfa1f",
        chain: "Arbitrum",
        chain_id: 42161,
        asset: "0xaf88d065e77c8cC2239327C5EDb3A432268e5831",
        source: RateSource::AaveV3 {
            market: "0x794a61358D6845594F94dc1DB02A252b5b4814aD",
        },
    },
    PoolConfig {
        pool: "d9c395b9-00d0-4426-a6b3-572a6dd68e54",
        chain: "Arbitrum",
        chain_id: 42161,
        asset: "0xaf88d065e77c8cC2239327C5EDb3A432268e5831",
        source: RateSource::CompoundV3 {
            rpc_secret: "ARBITRUM_RPC_URL",
            comet: "0x9c4ec768c28520B50860ea7a15bd7213a9fF58bf",
        },
    },
    PoolConfig {
        pool: "7e0661bf-8cf3-45e6-9424-31916d4c7b84",
        chain: "Base",
        chain_id: 8453,
        asset: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
        source: RateSource::AaveV3 {
            market: "0xA238Dd80C259a72e81d7e4664a9801593F98d1c5",
        },
    },
    PoolConfig {
        pool: "0c8567f8-ba5b-41ad-80de-00a71895eb19",
        chain: "Base",
        chain_id: 8453,
        asset: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
        source: RateSource::CompoundV3 {
            rpc_secret: "BASE_RPC_URL",
            comet: "0xb125E6687d4313864e53df431d5425969c15Eb2F",
        },
    },
    PoolConfig {
        pool: "c4b05318-88af-4536-a834-f5fc8940d2d3",
        chain: "Avalanche",
        chain_id: 43114,
        asset: "0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E",
        source: RateSource::AaveV3 {
            market: "0x794a61358D6845594F94dc1DB02A252b5b4814aD",
        },
    },
    PoolConfig {
        pool: "22323e90-bde5-54a1-8686-53b4205b61b7",
        chain: "Avalanche",
        chain_id: 43114,
        asset: "0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E",
        source: RateSource::AaveV4 {
            spoke: "0x435272CefF93a1E657E8ABfdf0A13e95900A3a56",
            reserve_id: "2",
        },
    },
    PoolConfig {
        pool: "0758c3b8-4ffb-4176-b0a9-f446e367db46",
        chain: "OP Mainnet",
        chain_id: 10,
        asset: "0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85",
        source: RateSource::AaveV3 {
            market: "0x794a61358D6845594F94dc1DB02A252b5b4814aD",
        },
    },
    PoolConfig {
        pool: "b828f0cb-853d-4b32-aebb-2e20d7fd70a8",
        chain: "OP Mainnet",
        chain_id: 10,
        asset: "0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85",
        source: RateSource::CompoundV3 {
            rpc_secret: "OPTIMISM_RPC_URL",
            comet: "0x2e44e174f7D53F0212823acC11C01A11d58c5bCB",
        },
    },
    PoolConfig {
        pool: "1b8b4cdb-0728-42a8-bf13-2c8fea7427ee",
        chain: "Polygon",
        chain_id: 137,
        asset: "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359",
        source: RateSource::AaveV3 {
            market: "0x794a61358D6845594F94dc1DB02A252b5b4814aD",
        },
    },
];

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::Value;
    use std::collections::BTreeSet;

    fn strings(values: &Value) -> BTreeSet<&str> {
        values
            .as_array()
            .unwrap()
            .iter()
            .map(|value| value.as_str().unwrap())
            .collect()
    }

    #[test]
    fn catalogue_matches_production_cre_configuration() {
        let workflow: Value =
            serde_json::from_str(include_str!("../../../cre/workflow/config.production.json"))
                .unwrap();
        let ids: BTreeSet<_> = POOLS.iter().map(|pool| pool.pool).collect();
        assert_eq!(ids.len(), POOLS.len()); // No duplicate pool IDs.
        assert_eq!(ids, strings(&workflow["defiLlama"]["poolIds"]));

        let chains: BTreeSet<_> = workflow["evms"]
            .as_array()
            .unwrap()
            .iter()
            .map(|chain| chain["defiLlamaChainName"].as_str().unwrap())
            .collect();
        let projects = strings(&workflow["defiLlama"]["projects"]);
        let symbols = strings(&workflow["defiLlama"]["symbols"]);
        for config in POOLS {
            let pool = config.relay_pool(3.5);
            assert!(chains.contains(pool.chain.as_str()));
            assert!(projects.contains(pool.project.as_str()));
            assert!(symbols.contains(pool.symbol.as_str()));
            // The project name is hashed into the onchain protocol ID.
            let expected = match config.source {
                RateSource::AaveV3 { .. } => "aave-v3",
                RateSource::AaveV4 { .. } => "aave-v4",
                RateSource::CompoundV3 { .. } => "compound-v3",
            };
            assert_eq!(pool.project, expected);
        }
    }

    #[test]
    fn targets_match_native_usdc_contract_configuration() {
        let helper = include_str!("../../../evm/script/HelperConfig.s.sol");
        let mut checked = 0;
        for (chain, chain_id, function, rpc_secret) in [
            ("Ethereum", 1, "getEthereumConfig", "ETHEREUM_RPC_URL"),
            ("Arbitrum", 42161, "getArbitrumConfig", "ARBITRUM_RPC_URL"),
            ("Base", 8453, "getBaseConfig", "BASE_RPC_URL"),
            ("Avalanche", 43114, "getAvalancheConfig", ""),
            ("OP Mainnet", 10, "getOptimismConfig", "OPTIMISM_RPC_URL"),
            ("Polygon", 137, "getPolygonConfig", ""),
        ] {
            let declaration = format!("function {function}()");
            let block = helper
                .split(&declaration)
                .nth(1)
                .unwrap()
                .split("function ")
                .next()
                .unwrap();
            for config in POOLS.iter().filter(|pool| pool.chain == chain) {
                checked += 1;
                assert_eq!(config.chain_id, chain_id);
                assert!(block.contains(&format!("usdc: {}", config.asset)));
                match config.source {
                    // HelperConfig stores the PoolAddressesProvider, not the Pool.
                    RateSource::AaveV3 { .. } => {}
                    RateSource::AaveV4 { spoke, .. } => {
                        assert!(block.contains(&format!("aaveV4Spoke: {spoke}")));
                    }
                    RateSource::CompoundV3 {
                        rpc_secret: actual,
                        comet,
                    } => {
                        assert_eq!(actual, rpc_secret);
                        assert!(block.contains(&format!("compoundV3Comet: {comet}")));
                    }
                }
            }
        }
        assert_eq!(checked, POOLS.len()); // Every pool's chain is listed above.
    }
}

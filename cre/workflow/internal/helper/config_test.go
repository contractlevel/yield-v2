package helper

import (
	"encoding/json"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestBlockNumberMustBeExplicit(t *testing.T) {
	for _, test := range []struct {
		name, input string
		valid       bool
		block       int64
	}{
		{"missing", `{}`, false, 0},
		{"null", `{"blockNumber":null}`, false, 0},
		{"finalized", `{"blockNumber":-3}`, true, -3},
		{"latest", `{"blockNumber":-2}`, true, -2},
		{"explicit zero", `{"blockNumber":0}`, true, 0},
		{"explicit height", `{"blockNumber":12345}`, true, 12345},
	} {
		t.Run(test.name, func(t *testing.T) {
			config := &Config{
				AssetDecimals: testAssetDecimals(), EpochSchedule: "0 0 0 * * *",
				RebalanceSchedule: "0 0 12 * * *", DefiLlama: validDefiLlamaConfig(),
				Evms: []EvmConfig{validEvmConfig()},
			}
			require.NoError(t, json.Unmarshal([]byte(test.input), config))
			err := ValidateConfig(config)
			if test.valid {
				require.NoError(t, err)
				require.Equal(t, test.block, *config.BlockNumber)
			} else {
				require.ErrorContains(t, err, "blockNumber must be specified")
			}
		})
	}
}

const (
	validVaultAddress          = "0x0000000000000000000000000000000000000001"
	validWorkflowRouterAddress = "0x0000000000000000000000000000000000000002"
)

func validEvmConfig(overrides ...func(*EvmConfig)) EvmConfig {
	cfg := EvmConfig{
		IsParent:              true,
		ChainName:             "chain-a",
		ChainSelector:         1,
		VaultAddress:          validVaultAddress,
		WorkflowRouterAddress: validWorkflowRouterAddress,
		GasLimit:              500_000,
	}

	for _, override := range overrides {
		override(&cfg)
	}

	return cfg
}

func validDefiLlamaConfig() DefiLlama {
	return DefiLlama{
		PoolIDs:  []string{"aa70268e-4b52-42bf-a116-608b370f9501", "d9c395b9-00d0-4426-a6b3-572a6dd68e54"},
		Projects: []string{"aave-v3", "compound-v3"},
		Symbols:  []string{"USDC"},
	}
}

func Test_ValidateConfig_supportedDefiLlamaProjects(t *testing.T) {
	for _, project := range []string{"aave-v3", "aave-v4", "compound-v3"} {
		t.Run(project, func(t *testing.T) {
			cfg := &Config{
				BlockNumber: new(int64), AssetDecimals: testAssetDecimals(),
				EpochSchedule: "0 0 0 * * *", RebalanceSchedule: "0 0 12 * * *",
				DefiLlama: validDefiLlamaConfig(), Evms: []EvmConfig{validEvmConfig()},
			}
			cfg.DefiLlama.Projects = []string{project}
			require.NoError(t, ValidateConfig(cfg))
		})
	}
}

func Test_ValidateConfig_rejectsNoncanonicalDefiLlamaProjects(t *testing.T) {
	for _, project := range []string{
		"AAVE-V3", "AAVE-V4", "COMPOUND-V3", "Aave-v3",
		" aave-v3", "aave-v4 ", "\tcompound-v3\n", "unsupported",
	} {
		t.Run(project, func(t *testing.T) {
			cfg := &Config{
				BlockNumber: new(int64), AssetDecimals: testAssetDecimals(),
				EpochSchedule: "0 0 0 * * *", RebalanceSchedule: "0 0 12 * * *",
				DefiLlama: validDefiLlamaConfig(), Evms: []EvmConfig{validEvmConfig()},
			}
			cfg.DefiLlama.Projects = []string{"aave-v3", project}
			// Canonical duplicates are rejected by the existing uniqueness check.
			require.Error(t, ValidateConfig(cfg))
			cfg.DefiLlama.Projects = []string{project}
			require.ErrorContains(t, ValidateConfig(cfg), "unsupported defiLlama project")
		})
	}
}

func Test_FindEvmConfigByChainSelector_found(t *testing.T) {
	evms := []EvmConfig{
		{ChainName: "chain-a", ChainSelector: 1},
		{ChainName: "chain-b", ChainSelector: 2},
	}

	cfg, err := FindEvmConfigByChainSelector(evms, 2)
	require.NoError(t, err, "expected no error when selector exists")
	require.NotNil(t, cfg, "expected non-nil config when selector exists")
	require.Equal(t, "chain-b", cfg.ChainName, "unexpected ChainName")
}

func Test_FindEvmConfigByChainSelector_notFound(t *testing.T) {
	evms := []EvmConfig{
		{ChainName: "chain-a", ChainSelector: 1},
	}

	cfg, err := FindEvmConfigByChainSelector(evms, 999)
	require.Error(t, err, "expected error when selector does not exist")
	require.Nil(t, cfg, "expected nil config when selector does not exist")
	require.ErrorContains(t, err, "no evm config found for chainSelector 999")
}

func Test_ValidateConfig_valid(t *testing.T) {
	cfg := &Config{
		BlockNumber:       new(int64),
		AssetDecimals:     testAssetDecimals(),
		EpochSchedule:     "0 0 0 * * *",
		RebalanceSchedule: "0 0 12 * * *",
		DefiLlama:         validDefiLlamaConfig(),
		Evms: []EvmConfig{
			validEvmConfig(),
			validEvmConfig(func(e *EvmConfig) {
				e.IsParent = false
				e.ChainName = "chain-b"
				e.ChainSelector = 2
				e.VaultAddress = "0x0000000000000000000000000000000000000003"
				e.WorkflowRouterAddress = "0x0000000000000000000000000000000000000004"
			}),
		},
	}

	err := ValidateConfig(cfg)
	require.NoError(t, err, "expected valid config to pass")
}

func Test_ValidateConfig_noEvms(t *testing.T) {
	err := ValidateConfig(&Config{BlockNumber: new(int64)})
	require.Error(t, err, "expected error when no EVM configs are provided")
	require.ErrorContains(t, err, "no EVM configs provided")
}

func Test_ValidateConfig_zeroChainSelector(t *testing.T) {
	cfg := &Config{
		BlockNumber:       new(int64),
		AssetDecimals:     testAssetDecimals(),
		EpochSchedule:     "0 0 0 * * *",
		RebalanceSchedule: "0 0 12 * * *",
		DefiLlama:         validDefiLlamaConfig(),
		Evms: []EvmConfig{
			validEvmConfig(func(e *EvmConfig) {
				e.ChainSelector = 0
			}),
		},
	}

	err := ValidateConfig(cfg)
	require.Error(t, err, "expected error when chain selector is zero")
	require.ErrorContains(t, err, "evms[0]: chainSelector must be non-zero")
}

func Test_ValidateConfig_duplicateChainSelector(t *testing.T) {
	cfg := &Config{
		BlockNumber:       new(int64),
		AssetDecimals:     testAssetDecimals(),
		EpochSchedule:     "0 0 0 * * *",
		RebalanceSchedule: "0 0 12 * * *",
		DefiLlama:         validDefiLlamaConfig(),
		Evms: []EvmConfig{
			validEvmConfig(),
			validEvmConfig(func(e *EvmConfig) {
				e.IsParent = false
				e.ChainName = "chain-b"
			}),
		},
	}

	err := ValidateConfig(cfg)
	require.Error(t, err, "expected error when chain selector is duplicated")
	require.ErrorContains(t, err, "evms[1]: duplicate chainSelector 1")
}

func Test_ValidateConfig_emptyVaultAddress(t *testing.T) {
	cfg := &Config{
		BlockNumber:       new(int64),
		AssetDecimals:     testAssetDecimals(),
		EpochSchedule:     "0 0 0 * * *",
		RebalanceSchedule: "0 0 12 * * *",
		DefiLlama:         validDefiLlamaConfig(),
		Evms: []EvmConfig{
			validEvmConfig(func(e *EvmConfig) {
				e.VaultAddress = ""
			}),
		},
	}

	err := ValidateConfig(cfg)
	require.Error(t, err, "expected error when vault address is empty")
	require.ErrorContains(t, err, `invalid vaultAddress ""`)
}

func Test_ValidateConfig_invalidVaultAddress(t *testing.T) {
	cfg := &Config{
		BlockNumber:       new(int64),
		AssetDecimals:     testAssetDecimals(),
		EpochSchedule:     "0 0 0 * * *",
		RebalanceSchedule: "0 0 12 * * *",
		DefiLlama:         validDefiLlamaConfig(),
		Evms: []EvmConfig{
			validEvmConfig(func(e *EvmConfig) {
				e.VaultAddress = "not-an-address"
			}),
		},
	}

	err := ValidateConfig(cfg)
	require.Error(t, err, "expected error when vault address is invalid")
	require.ErrorContains(t, err, `invalid vaultAddress "not-an-address"`)
}

func Test_ValidateConfig_zeroVaultAddress(t *testing.T) {
	cfg := &Config{
		BlockNumber:       new(int64),
		AssetDecimals:     testAssetDecimals(),
		EpochSchedule:     "0 0 0 * * *",
		RebalanceSchedule: "0 0 12 * * *",
		DefiLlama:         validDefiLlamaConfig(),
		Evms: []EvmConfig{
			validEvmConfig(func(e *EvmConfig) {
				e.VaultAddress = "0x0000000000000000000000000000000000000000"
			}),
		},
	}

	err := ValidateConfig(cfg)
	require.Error(t, err, "expected error when vault address is zero")
	require.ErrorContains(t, err, `invalid vaultAddress "0x0000000000000000000000000000000000000000"`)
}

func Test_ValidateConfig_emptyWorkflowRouterAddress(t *testing.T) {
	cfg := &Config{
		BlockNumber:       new(int64),
		AssetDecimals:     testAssetDecimals(),
		EpochSchedule:     "0 0 0 * * *",
		RebalanceSchedule: "0 0 12 * * *",
		DefiLlama:         validDefiLlamaConfig(),
		Evms: []EvmConfig{
			validEvmConfig(func(e *EvmConfig) {
				e.WorkflowRouterAddress = ""
			}),
		},
	}

	err := ValidateConfig(cfg)
	require.Error(t, err, "expected error when workflow router address is empty")
	require.ErrorContains(t, err, `invalid workflowRouterAddress ""`)
}

func Test_ValidateConfig_invalidWorkflowRouterAddress(t *testing.T) {
	cfg := &Config{
		BlockNumber:       new(int64),
		AssetDecimals:     testAssetDecimals(),
		EpochSchedule:     "0 0 0 * * *",
		RebalanceSchedule: "0 0 12 * * *",
		DefiLlama:         validDefiLlamaConfig(),
		Evms: []EvmConfig{
			validEvmConfig(func(e *EvmConfig) {
				e.WorkflowRouterAddress = "not-an-address"
			}),
		},
	}

	err := ValidateConfig(cfg)
	require.Error(t, err, "expected error when workflow router address is invalid")
	require.ErrorContains(t, err, `invalid workflowRouterAddress "not-an-address"`)
}

func Test_ValidateConfig_zeroWorkflowRouterAddress(t *testing.T) {
	cfg := &Config{
		BlockNumber:       new(int64),
		AssetDecimals:     testAssetDecimals(),
		EpochSchedule:     "0 0 0 * * *",
		RebalanceSchedule: "0 0 12 * * *",
		DefiLlama:         validDefiLlamaConfig(),
		Evms: []EvmConfig{
			validEvmConfig(func(e *EvmConfig) {
				e.WorkflowRouterAddress = "0x0000000000000000000000000000000000000000"
			}),
		},
	}

	err := ValidateConfig(cfg)
	require.Error(t, err, "expected error when workflow router address is zero")
	require.ErrorContains(t, err, `invalid workflowRouterAddress "0x0000000000000000000000000000000000000000"`)
}

func Test_ValidateConfig_zeroGasLimit(t *testing.T) {
	cfg := &Config{
		BlockNumber:       new(int64),
		AssetDecimals:     testAssetDecimals(),
		EpochSchedule:     "0 0 0 * * *",
		RebalanceSchedule: "0 0 12 * * *",
		DefiLlama:         validDefiLlamaConfig(),
		Evms: []EvmConfig{
			validEvmConfig(func(e *EvmConfig) {
				e.GasLimit = 0
			}),
		},
	}

	err := ValidateConfig(cfg)
	require.Error(t, err, "expected error when gas limit is zero")
	require.ErrorContains(t, err, "evms[0] (chain 1): gasLimit must be non-zero")
}

func Test_ValidateConfig_noParent(t *testing.T) {
	cfg := &Config{
		BlockNumber:       new(int64),
		AssetDecimals:     testAssetDecimals(),
		EpochSchedule:     "0 0 0 * * *",
		RebalanceSchedule: "0 0 12 * * *",
		DefiLlama:         validDefiLlamaConfig(),
		Evms: []EvmConfig{
			validEvmConfig(func(e *EvmConfig) {
				e.IsParent = false
			}),
		},
	}

	err := ValidateConfig(cfg)
	require.Error(t, err, "expected error when no parent chain is configured")
	require.ErrorContains(t, err, "expected exactly one parent chain (IsParent=true), got 0")
}

func Test_ValidateConfig_multipleParents(t *testing.T) {
	cfg := &Config{
		BlockNumber:       new(int64),
		AssetDecimals:     testAssetDecimals(),
		EpochSchedule:     "0 0 0 * * *",
		RebalanceSchedule: "0 0 12 * * *",
		DefiLlama:         validDefiLlamaConfig(),
		Evms: []EvmConfig{
			validEvmConfig(),
			validEvmConfig(func(e *EvmConfig) {
				e.ChainName = "chain-b"
				e.ChainSelector = 2
				e.VaultAddress = "0x0000000000000000000000000000000000000003"
				e.WorkflowRouterAddress = "0x0000000000000000000000000000000000000004"
			}),
		},
	}

	err := ValidateConfig(cfg)
	require.Error(t, err, "expected error when multiple parent chains are configured")
	require.ErrorContains(t, err, "expected exactly one parent chain (IsParent=true), got 2")
}

func Test_ValidateConfig_emptyDefiLlamaPoolIDs(t *testing.T) {
	cfg := &Config{
		BlockNumber:       new(int64),
		AssetDecimals:     testAssetDecimals(),
		EpochSchedule:     "0 0 0 * * *",
		RebalanceSchedule: "0 0 12 * * *",
		DefiLlama:         DefiLlama{Projects: []string{"aave-v3"}, Symbols: []string{"USDC"}},
		Evms:              []EvmConfig{validEvmConfig()},
	}

	err := ValidateConfig(cfg)
	require.Error(t, err, "expected error when DeFiLlama pool IDs are empty")
	require.ErrorContains(t, err, "defiLlama.poolIds must contain at least one value")
}

func Test_ValidateConfig_emptyDefiLlamaPoolIDValue(t *testing.T) {
	cfg := &Config{
		BlockNumber:       new(int64),
		AssetDecimals:     testAssetDecimals(),
		EpochSchedule:     "0 0 0 * * *",
		RebalanceSchedule: "0 0 12 * * *",
		DefiLlama:         DefiLlama{PoolIDs: []string{""}, Projects: []string{"aave-v3"}, Symbols: []string{"USDC"}},
		Evms:              []EvmConfig{validEvmConfig()},
	}

	err := ValidateConfig(cfg)
	require.Error(t, err, "expected error when DeFiLlama pool ID is empty")
	require.ErrorContains(t, err, "defiLlama.poolIds[0]: value must be non-empty")
}

func Test_ValidateConfig_duplicateDefiLlamaPoolIDDifferentCase(t *testing.T) {
	cfg := &Config{
		BlockNumber:       new(int64),
		AssetDecimals:     testAssetDecimals(),
		EpochSchedule:     "0 0 0 * * *",
		RebalanceSchedule: "0 0 12 * * *",
		DefiLlama:         DefiLlama{PoolIDs: []string{"pool-a", "POOL-A"}, Projects: []string{"aave-v3"}, Symbols: []string{"USDC"}},
		Evms:              []EvmConfig{validEvmConfig()},
	}

	err := ValidateConfig(cfg)
	require.Error(t, err, "expected error when DeFiLlama pool ID differs only by case")
	require.ErrorContains(t, err, `defiLlama.poolIds[1]: duplicate value "POOL-A"`)
}

func Test_ValidateConfig_emptyDefiLlamaProjects(t *testing.T) {
	cfg := &Config{
		BlockNumber:       new(int64),
		AssetDecimals:     testAssetDecimals(),
		EpochSchedule:     "0 0 0 * * *",
		RebalanceSchedule: "0 0 12 * * *",
		DefiLlama:         DefiLlama{PoolIDs: []string{"pool-a"}, Symbols: []string{"USDC"}},
		Evms:              []EvmConfig{validEvmConfig()},
	}

	err := ValidateConfig(cfg)
	require.Error(t, err, "expected error when DeFiLlama projects are empty")
	require.ErrorContains(t, err, "defiLlama.projects must contain at least one value")
}

func Test_ValidateConfig_emptyDefiLlamaProjectValue(t *testing.T) {
	cfg := &Config{
		BlockNumber:       new(int64),
		AssetDecimals:     testAssetDecimals(),
		EpochSchedule:     "0 0 0 * * *",
		RebalanceSchedule: "0 0 12 * * *",
		DefiLlama:         DefiLlama{PoolIDs: []string{"pool-a"}, Projects: []string{""}, Symbols: []string{"USDC"}},
		Evms:              []EvmConfig{validEvmConfig()},
	}

	err := ValidateConfig(cfg)
	require.Error(t, err, "expected error when DeFiLlama project is empty")
	require.ErrorContains(t, err, "defiLlama.projects[0]: value must be non-empty")
}

func Test_ValidateConfig_whitespaceDefiLlamaProjectValue(t *testing.T) {
	cfg := &Config{
		BlockNumber:       new(int64),
		AssetDecimals:     testAssetDecimals(),
		EpochSchedule:     "0 0 0 * * *",
		RebalanceSchedule: "0 0 12 * * *",
		DefiLlama:         DefiLlama{PoolIDs: []string{"pool-a"}, Projects: []string{" "}, Symbols: []string{"USDC"}},
		Evms:              []EvmConfig{validEvmConfig()},
	}

	err := ValidateConfig(cfg)
	require.Error(t, err, "expected error when DeFiLlama project is whitespace")
	require.ErrorContains(t, err, "defiLlama.projects[0]: value must be non-empty")
}

func Test_ValidateConfig_duplicateDefiLlamaProject(t *testing.T) {
	cfg := &Config{
		BlockNumber:       new(int64),
		AssetDecimals:     testAssetDecimals(),
		EpochSchedule:     "0 0 0 * * *",
		RebalanceSchedule: "0 0 12 * * *",
		DefiLlama:         DefiLlama{PoolIDs: []string{"pool-a"}, Projects: []string{"aave-v3", "aave-v3"}, Symbols: []string{"USDC"}},
		Evms:              []EvmConfig{validEvmConfig()},
	}

	err := ValidateConfig(cfg)
	require.Error(t, err, "expected error when DeFiLlama project is duplicated")
	require.ErrorContains(t, err, `defiLlama.projects[1]: duplicate value "aave-v3"`)
}

func Test_ValidateConfig_duplicateDefiLlamaProjectDifferentCase(t *testing.T) {
	cfg := &Config{
		BlockNumber:       new(int64),
		AssetDecimals:     testAssetDecimals(),
		EpochSchedule:     "0 0 0 * * *",
		RebalanceSchedule: "0 0 12 * * *",
		DefiLlama:         DefiLlama{PoolIDs: []string{"pool-a"}, Projects: []string{"aave-v3", "AAVE-V3"}, Symbols: []string{"USDC"}},
		Evms:              []EvmConfig{validEvmConfig()},
	}

	err := ValidateConfig(cfg)
	require.Error(t, err, "expected error when DeFiLlama project differs only by case")
	require.ErrorContains(t, err, `defiLlama.projects[1]: duplicate value "AAVE-V3"`)
}

func Test_ValidateConfig_emptyDefiLlamaSymbols(t *testing.T) {
	cfg := &Config{
		BlockNumber:       new(int64),
		AssetDecimals:     testAssetDecimals(),
		EpochSchedule:     "0 0 0 * * *",
		RebalanceSchedule: "0 0 12 * * *",
		DefiLlama:         DefiLlama{PoolIDs: []string{"pool-a"}, Projects: []string{"aave-v3"}},
		Evms:              []EvmConfig{validEvmConfig()},
	}

	err := ValidateConfig(cfg)
	require.Error(t, err, "expected error when DeFiLlama symbols are empty")
	require.ErrorContains(t, err, "defiLlama.symbols must contain at least one value")
}

func Test_ValidateConfig_emptyDefiLlamaSymbolValue(t *testing.T) {
	cfg := &Config{
		BlockNumber:       new(int64),
		AssetDecimals:     testAssetDecimals(),
		EpochSchedule:     "0 0 0 * * *",
		RebalanceSchedule: "0 0 12 * * *",
		DefiLlama:         DefiLlama{PoolIDs: []string{"pool-a"}, Projects: []string{"aave-v3"}, Symbols: []string{""}},
		Evms:              []EvmConfig{validEvmConfig()},
	}

	err := ValidateConfig(cfg)
	require.Error(t, err, "expected error when DeFiLlama symbol is empty")
	require.ErrorContains(t, err, "defiLlama.symbols[0]: value must be non-empty")
}

func Test_ValidateConfig_whitespaceDefiLlamaSymbolValue(t *testing.T) {
	cfg := &Config{
		BlockNumber:       new(int64),
		AssetDecimals:     testAssetDecimals(),
		EpochSchedule:     "0 0 0 * * *",
		RebalanceSchedule: "0 0 12 * * *",
		DefiLlama:         DefiLlama{PoolIDs: []string{"pool-a"}, Projects: []string{"aave-v3"}, Symbols: []string{" "}},
		Evms:              []EvmConfig{validEvmConfig()},
	}

	err := ValidateConfig(cfg)
	require.Error(t, err, "expected error when DeFiLlama symbol is whitespace")
	require.ErrorContains(t, err, "defiLlama.symbols[0]: value must be non-empty")
}

func Test_ValidateConfig_duplicateDefiLlamaSymbol(t *testing.T) {
	cfg := &Config{
		BlockNumber:       new(int64),
		AssetDecimals:     testAssetDecimals(),
		EpochSchedule:     "0 0 0 * * *",
		RebalanceSchedule: "0 0 12 * * *",
		DefiLlama:         DefiLlama{PoolIDs: []string{"pool-a"}, Projects: []string{"aave-v3"}, Symbols: []string{"USDC", "USDC"}},
		Evms:              []EvmConfig{validEvmConfig()},
	}

	err := ValidateConfig(cfg)
	require.Error(t, err, "expected error when DeFiLlama symbol is duplicated")
	require.ErrorContains(t, err, `defiLlama.symbols[1]: duplicate value "USDC"`)
}

func Test_ValidateConfig_duplicateDefiLlamaSymbolDifferentCase(t *testing.T) {
	cfg := &Config{
		BlockNumber:       new(int64),
		AssetDecimals:     testAssetDecimals(),
		EpochSchedule:     "0 0 0 * * *",
		RebalanceSchedule: "0 0 12 * * *",
		DefiLlama:         DefiLlama{PoolIDs: []string{"pool-a"}, Projects: []string{"aave-v3"}, Symbols: []string{"USDC", "usdc"}},
		Evms:              []EvmConfig{validEvmConfig()},
	}

	err := ValidateConfig(cfg)
	require.Error(t, err, "expected error when DeFiLlama symbol differs only by case")
	require.ErrorContains(t, err, `defiLlama.symbols[1]: duplicate value "usdc"`)
}

func Test_ValidateConfig_duplicateDefiLlamaChainName(t *testing.T) {
	cfg := &Config{
		BlockNumber:       new(int64),
		AssetDecimals:     testAssetDecimals(),
		EpochSchedule:     "0 0 0 * * *",
		RebalanceSchedule: "0 0 12 * * *",
		DefiLlama:         validDefiLlamaConfig(),
		Evms: []EvmConfig{
			validEvmConfig(func(e *EvmConfig) {
				e.DefiLlamaChainName = "Arbitrum"
			}),
			validEvmConfig(func(e *EvmConfig) {
				e.IsParent = false
				e.ChainName = "chain-b"
				e.ChainSelector = 2
				e.VaultAddress = "0x0000000000000000000000000000000000000003"
				e.WorkflowRouterAddress = "0x0000000000000000000000000000000000000004"
				e.DefiLlamaChainName = "Arbitrum"
			}),
		},
	}

	err := ValidateConfig(cfg)
	require.Error(t, err, "expected error when DeFiLlama chain name is duplicated")
	require.ErrorContains(t, err, `evms[1] (chain 2): duplicate defiLlamaChainName "Arbitrum"`)
}

func Test_ValidateConfig_duplicateDefiLlamaChainNameDifferentCase(t *testing.T) {
	cfg := &Config{
		BlockNumber:       new(int64),
		AssetDecimals:     testAssetDecimals(),
		EpochSchedule:     "0 0 0 * * *",
		RebalanceSchedule: "0 0 12 * * *",
		DefiLlama:         validDefiLlamaConfig(),
		Evms: []EvmConfig{
			validEvmConfig(func(e *EvmConfig) {
				e.DefiLlamaChainName = "Arbitrum"
			}),
			validEvmConfig(func(e *EvmConfig) {
				e.IsParent = false
				e.ChainName = "chain-b"
				e.ChainSelector = 2
				e.VaultAddress = "0x0000000000000000000000000000000000000003"
				e.WorkflowRouterAddress = "0x0000000000000000000000000000000000000004"
				e.DefiLlamaChainName = "arbitrum"
			}),
		},
	}

	err := ValidateConfig(cfg)
	require.Error(t, err, "expected error when DeFiLlama chain name differs only by case")
	require.ErrorContains(t, err, `evms[1] (chain 2): duplicate defiLlamaChainName "arbitrum"`)
}

func Test_FindParent_found(t *testing.T) {
	evms := []EvmConfig{
		{ChainName: "chain-a", ChainSelector: 1},
		{IsParent: true, ChainName: "chain-b", ChainSelector: 2},
	}

	cfg, err := FindParent(evms)
	require.NoError(t, err, "expected no error when parent exists")
	require.Equal(t, "chain-b", cfg.ChainName, "unexpected parent ChainName")
	require.Equal(t, uint64(2), cfg.ChainSelector, "unexpected parent ChainSelector")
}

func Test_FindParent_notFound(t *testing.T) {
	cfg, err := FindParent([]EvmConfig{{ChainName: "chain-a", ChainSelector: 1}})
	require.Error(t, err, "expected error when parent does not exist")
	require.Equal(t, EvmConfig{}, cfg, "expected zero-value config when parent does not exist")
	require.ErrorContains(t, err, "no parent chain configured")
}

func testAssetDecimals() *uint8 {
	value := uint8(6)
	return &value
}

func TestOperationalConfigLimits(t *testing.T) {
	for _, test := range []struct {
		name   string
		change func(*Config)
		reason string
	}{
		{"gas quota", func(c *Config) { c.Evms[0].GasLimit = 5_000_001 }, "gasLimit exceeds"},
		{"missing decimals", func(c *Config) { c.AssetDecimals = nil }, "assetDecimals"},
		{"excess decimals", func(c *Config) { *c.AssetDecimals = 78 }, "assetDecimals"},
		{"missing epoch schedule", func(c *Config) { c.EpochSchedule = " " }, "must be specified"},
		{"missing rebalance schedule", func(c *Config) { c.RebalanceSchedule = "" }, "must be specified"},
		{"zero decimals", func(c *Config) { *c.AssetDecimals = 0 }, ""},
		{"maximum decimals", func(c *Config) { *c.AssetDecimals = 77 }, ""},
		{"maximum gas", func(c *Config) { c.Evms[0].GasLimit = 5_000_000 }, ""},
	} {
		t.Run(test.name, func(t *testing.T) {
			config := &Config{BlockNumber: new(int64), AssetDecimals: testAssetDecimals(), EpochSchedule: "0 0 0 * * *", RebalanceSchedule: "0 0 12 * * *", Evms: []EvmConfig{validEvmConfig()}, DefiLlama: validDefiLlamaConfig()}
			test.change(config)
			err := ValidateConfig(config)
			if test.reason == "" {
				require.NoError(t, err)
			} else {
				require.ErrorContains(t, err, test.reason)
			}
		})
	}
}

func TestChainTriggerQuota(t *testing.T) {
	config := &Config{BlockNumber: new(int64), AssetDecimals: testAssetDecimals(), EpochSchedule: "0 0 0 * * *", RebalanceSchedule: "0 0 12 * * *", DefiLlama: validDefiLlamaConfig()}
	for i := 1; i <= 9; i++ {
		chain := validEvmConfig()
		chain.IsParent, chain.ChainSelector = i == 1, uint64(i)
		config.Evms = append(config.Evms, chain)
		err := ValidateConfig(config)
		if i <= 8 {
			require.NoError(t, err)
		} else {
			require.ErrorContains(t, err, "9 chains require 11 triggers")
		}
	}
}

package helper

import (
	"fmt"
	"strings"

	"github.com/ethereum/go-ethereum/common"
)

// Config is loaded from config.json
type Config struct {
	RebalanceSchedule string      `json:"rebalanceSchedule"`
	EpochSchedule     string      `json:"epochSchedule"`
	AssetDecimals     *uint8      `json:"assetDecimals"`
	BlockNumber       *int64      `json:"blockNumber"` // Required: -3 finalized; -2 pending for local forks.
	DefiLlama         DefiLlama   `json:"defiLlama"`
	Evms              []EvmConfig `json:"evms"`
}

type DefiLlama struct {
	PoolIDs  []string `json:"poolIds"`
	Projects []string `json:"projects"`
	Symbols  []string `json:"symbols"`
}

// EvmConfig:
//   - IsParent == true: where the Parent Vault is
//     and where we read the activeStrategy from.
//   - activeStrategy.ChainSelector tells us which chain the active strategy
//     adapter lives on.
type EvmConfig struct {
	IsParent              bool   `json:"isParent"`
	ChainName             string `json:"chainName"`
	DefiLlamaChainName    string `json:"defiLlamaChainName,omitempty"`
	ChainSelector         uint64 `json:"chainSelector"`
	VaultAddress          string `json:"vaultAddress"`
	WorkflowRouterAddress string `json:"workflowRouterAddress"`
	GasLimit              uint64 `json:"gasLimit"`
}

func FindEvmConfigByChainSelector(evms []EvmConfig, target uint64) (*EvmConfig, error) {
	for i := range evms {
		if evms[i].ChainSelector == target {
			return &evms[i], nil
		}
	}
	return nil, fmt.Errorf("no evm config found for chainSelector %d", target)
}

func ValidateConfig(cfg *Config) error {
	if cfg == nil || len(cfg.Evms) == 0 {
		return fmt.Errorf("no EVM configs provided")
	}
	if err := validateDefiLlamaConfig(cfg.DefiLlama); err != nil {
		return err
	}

	seenSelectors := make(map[uint64]struct{}, len(cfg.Evms))
	seenDefiLlamaChains := make(map[string]struct{}, len(cfg.Evms))
	parentCount := 0

	for i, e := range cfg.Evms {
		if e.ChainSelector == 0 {
			return fmt.Errorf("evms[%d]: chainSelector must be non-zero", i)
		}
		if _, dup := seenSelectors[e.ChainSelector]; dup {
			return fmt.Errorf("evms[%d]: duplicate chainSelector %d", i, e.ChainSelector)
		}
		seenSelectors[e.ChainSelector] = struct{}{}

		if !isRequiredAddress(e.VaultAddress) {
			return fmt.Errorf("evms[%d] (chain %d): invalid vaultAddress %q", i, e.ChainSelector, e.VaultAddress)
		}
		if !isRequiredAddress(e.WorkflowRouterAddress) {
			return fmt.Errorf("evms[%d] (chain %d): invalid workflowRouterAddress %q", i, e.ChainSelector, e.WorkflowRouterAddress)
		}
		if e.GasLimit == 0 {
			return fmt.Errorf("evms[%d] (chain %d): gasLimit must be non-zero", i, e.ChainSelector)
		}
		if e.GasLimit > 5_000_000 {
			return fmt.Errorf("evms[%d]: gasLimit exceeds CRE's 5,000,000 quota", i)
		}
		if e.DefiLlamaChainName != "" {
			canonicalName := canonicalDefiLlamaValue(e.DefiLlamaChainName)
			if _, dup := seenDefiLlamaChains[canonicalName]; dup {
				return fmt.Errorf("evms[%d] (chain %d): duplicate defiLlamaChainName %q", i, e.ChainSelector, e.DefiLlamaChainName)
			}
			seenDefiLlamaChains[canonicalName] = struct{}{}
		}

		if e.IsParent {
			parentCount++
		}
	}

	if parentCount != 1 {
		return fmt.Errorf("expected exactly one parent chain (IsParent=true), got %d", parentCount)
	}
	if TriggerCount(len(cfg.Evms)) > 10 {
		return fmt.Errorf("%d chains require %d triggers; CRE permits 10", len(cfg.Evms), TriggerCount(len(cfg.Evms)))
	}
	if cfg.AssetDecimals == nil || *cfg.AssetDecimals > 77 {
		return fmt.Errorf("assetDecimals must be specified and between 0 and 77")
	}
	if cfg.BlockNumber == nil {
		return fmt.Errorf("blockNumber must be specified")
	}
	if strings.TrimSpace(cfg.EpochSchedule) == "" || strings.TrimSpace(cfg.RebalanceSchedule) == "" {
		return fmt.Errorf("epochSchedule and rebalanceSchedule must be specified")
	}
	return nil
}

// Each vault has one combined log subscription, plus the two cron triggers.
func TriggerCount(chains int) int { return chains + 2 }

func isRequiredAddress(value string) bool {
	if value == "" || !common.IsHexAddress(value) {
		return false
	}
	return common.HexToAddress(value) != (common.Address{})
}

func validateDefiLlamaConfig(cfg DefiLlama) error {
	if err := validateUniqueNonEmptyStrings("defiLlama.poolIds", cfg.PoolIDs); err != nil {
		return err
	}
	if err := validateUniqueNonEmptyStrings("defiLlama.projects", cfg.Projects); err != nil {
		return err
	}
	for _, project := range cfg.Projects {
		switch project {
		case "aave-v3", "aave-v4", "compound-v3":
			// Exact names match the registered protocol IDs.
		default:
			return fmt.Errorf("unsupported defiLlama project %q: expected aave-v3, aave-v4, or compound-v3", project)
		}
	}
	if err := validateUniqueNonEmptyStrings("defiLlama.symbols", cfg.Symbols); err != nil {
		return err
	}
	return nil
}

func validateUniqueNonEmptyStrings(field string, values []string) error {
	if len(values) == 0 {
		return fmt.Errorf("%s must contain at least one value", field)
	}

	seen := make(map[string]struct{}, len(values))
	for i, value := range values {
		canonicalValue := canonicalDefiLlamaValue(value)
		if canonicalValue == "" {
			return fmt.Errorf("%s[%d]: value must be non-empty", field, i)
		}
		if _, dup := seen[canonicalValue]; dup {
			return fmt.Errorf("%s[%d]: duplicate value %q", field, i, value)
		}
		seen[canonicalValue] = struct{}{}
	}

	return nil
}

func canonicalDefiLlamaValue(value string) string {
	return strings.ToLower(strings.TrimSpace(value))
}

// FindParent returns the single parent EvmConfig. Safe to call only after
// ValidateConfig has succeeded.
func FindParent(evms []EvmConfig) (EvmConfig, error) {
	for _, e := range evms {
		if e.IsParent {
			return e, nil
		}
	}
	return EvmConfig{}, fmt.Errorf("no parent chain configured")
}

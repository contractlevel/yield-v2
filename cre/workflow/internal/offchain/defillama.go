package offchain

import (
	"bytes"
	"compress/gzip"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"

	"github.com/ethereum/go-ethereum/crypto"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

var (
	defiLlamaURL        = "https://yields.llama.fi/pools"
	defiLlamaHTTPClient = http.DefaultClient
)

// Config contains the workflow's DefiLlama selection policy.
type Config struct {
	Chains   []ChainConfig
	Projects []string
	Symbols  []string
}

type ChainConfig struct {
	ChainSelector      uint64
	DefiLlamaChainName string
}

// Pool is a liquidity pool returned by the DefiLlama API.
type Pool struct {
	Chain   string  `json:"chain"`
	Project string  `json:"project"`
	Symbol  string  `json:"symbol"`
	Apy     float64 `json:"apy"`
}

// fetchParams holds the inputs for the node-mode fetch function.
type fetchParams struct {
	Config           Config
	ActiveProtocolId [32]byte
	ActiveChainName  string
}

// fetchResult holds the output of the node-mode fetch function.
// Uses value semantics (not pointers) for CRE consensus serialisation.
type fetchResult struct {
	BestPool    Pool `json:"bestPool"`
	HasBest     bool `json:"hasBest"`
	CurrentPool Pool `json:"currentPool"`
	HasCurrent  bool `json:"hasCurrent"`
}

// FetchAndSelectPools queries DefiLlama and returns the best approved pool and the
// currently active pool. activeChainSelector is the CCIP selector of the active
// strategy's chain; it is used to match against the DefiLlama "chain" field.
// Either return value may be nil: bestPool is nil when no approved pool exists; currentPool
// is nil when the active strategy's chain/project is not in the approved set.
func FetchAndSelectPools(runtime cre.Runtime, cfg Config, activeProtocolId [32]byte, activeChainSelector uint64) (*Pool, *Pool, error) {
	selectorToName := chainSelectorToName(cfg)
	activeChainName := selectorToName[activeChainSelector] // empty string if unknown

	params := fetchParams{
		Config:           cfg,
		ActiveProtocolId: activeProtocolId,
		ActiveChainName:  activeChainName,
	}

	raw, err := cre.RunInNodeMode(params, runtime, fetchAndParse, cre.ConsensusIdenticalAggregation[fetchResult]()).Await()
	if err != nil {
		return nil, nil, fmt.Errorf("fetch pools: %w", err)
	}

	var best, current *Pool
	if raw.HasBest {
		pool := raw.BestPool
		best = &pool
	}
	if raw.HasCurrent {
		pool := raw.CurrentPool
		current = &pool
	}
	return best, current, nil
}

// fetchAndParse is the node-mode function executed on each DON node.
func fetchAndParse(params fetchParams, _ cre.NodeRuntime) (fetchResult, error) {
	req, err := http.NewRequest(http.MethodGet, defiLlamaURL, nil)
	if err != nil {
		return fetchResult{}, fmt.Errorf("build request: %w", err)
	}
	req.Header.Set("Accept-Encoding", "gzip")

	resp, err := defiLlamaHTTPClient.Do(req)
	if err != nil {
		return fetchResult{}, fmt.Errorf("do request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fetchResult{}, fmt.Errorf("unexpected status %d", resp.StatusCode)
	}

	var reader io.Reader = resp.Body
	if strings.Contains(strings.ToLower(resp.Header.Get("Content-Encoding")), "gzip") {
		gz, gzErr := gzip.NewReader(resp.Body)
		if gzErr != nil {
			return fetchResult{}, fmt.Errorf("gzip reader: %w", gzErr)
		}
		defer gz.Close()
		reader = gz
	}

	body, err := io.ReadAll(reader)
	if err != nil {
		return fetchResult{}, fmt.Errorf("read body: %w", err)
	}

	return parsePools(bytes.NewReader(body), params.Config, params.ActiveProtocolId, params.ActiveChainName)
}

// parsePools streams the DefiLlama JSON response, filtering and selecting pools.
func parsePools(r io.Reader, cfg Config, activeProtocolId [32]byte, activeChainName string) (fetchResult, error) {
	decoder := json.NewDecoder(r)

	// Navigate to the "data" array.
	foundData := false
	for {
		t, err := decoder.Token()
		if err == io.EOF {
			break
		}
		if err != nil {
			return fetchResult{}, fmt.Errorf("token scan: %w", err)
		}
		if key, ok := t.(string); ok && strings.EqualFold(key, "data") {
			foundData = true
			break
		}
	}
	if !foundData {
		return fetchResult{}, fmt.Errorf("'data' key not found in response")
	}

	t, err := decoder.Token()
	if err != nil {
		return fetchResult{}, fmt.Errorf("read array start: %w", err)
	}
	if delim, ok := t.(json.Delim); !ok || delim != '[' {
		return fetchResult{}, fmt.Errorf("expected '[' after 'data' key")
	}

	var result fetchResult
	var maxApy float64
	allowedChain := allowedChains(cfg)
	allowedProject := allowedValues(cfg.Projects)
	allowedSymbol := allowedValues(cfg.Symbols)

	for decoder.More() {
		var p Pool
		if err := decoder.Decode(&p); err != nil {
			return fetchResult{}, fmt.Errorf("decode pool: %w", err)
		}

		if !allowedSymbol[p.Symbol] || !allowedProject[p.Project] || !allowedChain[p.Chain] {
			continue
		}

		if p.Apy > maxApy {
			maxApy = p.Apy
			result.BestPool = p
			result.HasBest = true
		}

		if p.Chain == activeChainName && PoolToProtocolId(p.Project) == activeProtocolId {
			result.CurrentPool = p
			result.HasCurrent = true
		}
	}

	return result, nil
}

// PoolToProtocolId computes keccak256(project) as a [32]byte protocol ID.
func PoolToProtocolId(project string) [32]byte {
	hash := crypto.Keccak256([]byte(project))
	var id [32]byte
	copy(id[:], hash)
	return id
}

// PoolToChainSelector converts a DefiLlama chain name to a CCIP chain selector.
func PoolToChainSelector(cfg Config, chain string) (uint64, error) {
	for sel, name := range chainSelectorToName(cfg) {
		if name == chain {
			return sel, nil
		}
	}
	return 0, fmt.Errorf("no chain selector for DefiLlama chain %q", chain)
}

func chainSelectorToName(cfg Config) map[uint64]string {
	result := make(map[uint64]string, len(cfg.Chains))
	for _, chain := range cfg.Chains {
		if chain.DefiLlamaChainName == "" {
			continue
		}
		result[chain.ChainSelector] = chain.DefiLlamaChainName
	}
	return result
}

func allowedChains(cfg Config) map[string]bool {
	result := make(map[string]bool, len(cfg.Chains))
	for _, chain := range cfg.Chains {
		if chain.DefiLlamaChainName == "" {
			continue
		}
		result[chain.DefiLlamaChainName] = true
	}
	return result
}

func allowedValues(values []string) map[string]bool {
	result := make(map[string]bool, len(values))
	for _, value := range values {
		result[value] = true
	}
	return result
}

package offchain

import (
	"bytes"
	"compress/gzip"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/ethereum/go-ethereum/crypto"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

var (
	defiLlamaURL        = "https://yields.llama.fi/pools"
	defiLlamaHTTPClient = &http.Client{Timeout: defiLlamaRequestTimeout}
)

const (
	defiLlamaRequestTimeout     = 10 * time.Second
	defiLlamaMaxCompressedBytes = 10 << 20
	defiLlamaMaxDecodedBytes    = 10 << 20
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
	ctx, cancel := context.WithTimeout(context.Background(), defiLlamaRequestTimeout)
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, defiLlamaURL, nil)
	if err != nil {
		return fetchResult{}, fmt.Errorf("build request: %w", err)
	}
	req.Header.Set("Accept-Encoding", "gzip")

	resp, err := defiLlamaHTTPClient.Do(req)
	if err != nil {
		return fetchResult{}, fmt.Errorf("do request: %w", err)
	}
	defer resp.Body.Close()

	if err := validateDefiLlamaResponseURL(resp); err != nil {
		return fetchResult{}, err
	}

	if resp.StatusCode != http.StatusOK {
		return fetchResult{}, fmt.Errorf("unexpected status %d", resp.StatusCode)
	}

	rawBody, err := readLimited(resp.Body, defiLlamaMaxCompressedBytes, "compressed response body")
	if err != nil {
		return fetchResult{}, err
	}

	var reader io.Reader = bytes.NewReader(rawBody)
	if strings.Contains(strings.ToLower(resp.Header.Get("Content-Encoding")), "gzip") {
		gz, gzErr := gzip.NewReader(bytes.NewReader(rawBody))
		if gzErr != nil {
			return fetchResult{}, fmt.Errorf("gzip reader: %w", gzErr)
		}
		defer gz.Close()
		reader = gz
	}

	body, err := readLimited(reader, defiLlamaMaxDecodedBytes, "decoded response body")
	if err != nil {
		return fetchResult{}, err
	}

	return parsePools(bytes.NewReader(body), params.Config, params.ActiveProtocolId, params.ActiveChainName)
}

func validateDefiLlamaResponseURL(resp *http.Response) error {
	expected, err := url.Parse(defiLlamaURL)
	if err != nil {
		return fmt.Errorf("parse expected URL: %w", err)
	}
	if resp.Request == nil || resp.Request.URL == nil {
		return fmt.Errorf("missing final response URL")
	}
	if !strings.EqualFold(resp.Request.URL.Scheme, expected.Scheme) || !strings.EqualFold(resp.Request.URL.Host, expected.Host) {
		return fmt.Errorf("unexpected final response URL %q", resp.Request.URL.String())
	}
	return nil
}

func readLimited(r io.Reader, limit int64, label string) ([]byte, error) {
	limited := io.LimitReader(r, limit+1)
	body, err := io.ReadAll(limited)
	if err != nil {
		return nil, fmt.Errorf("read %s: %w", label, err)
	}
	if int64(len(body)) > limit {
		return nil, fmt.Errorf("%s exceeds %d bytes", label, limit)
	}
	return body, nil
}

// parsePools streams the DefiLlama JSON response, filtering and selecting pools.
func parsePools(r io.Reader, cfg Config, activeProtocolId [32]byte, activeChainName string) (fetchResult, error) {
	decoder := json.NewDecoder(r)

	t, err := decoder.Token()
	if err != nil {
		return fetchResult{}, fmt.Errorf("read object start: %w", err)
	}
	if delim, ok := t.(json.Delim); !ok || delim != '{' {
		return fetchResult{}, fmt.Errorf("expected top-level object")
	}

	foundData := false
	for decoder.More() {
		t, err := decoder.Token()
		if err != nil {
			return fetchResult{}, fmt.Errorf("read top-level key: %w", err)
		}
		key := t.(string)

		if !strings.EqualFold(key, "data") {
			if err := skipJSONValue(decoder); err != nil {
				return fetchResult{}, fmt.Errorf("skip top-level key %q: %w", key, err)
			}
			continue
		}

		foundData = true
		break
	}

	if !foundData {
		return fetchResult{}, fmt.Errorf("'data' key not found in response")
	}

	t, err = decoder.Token()
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

		chainName, chainOK := allowedChain[canonicalDefiLlamaValue(p.Chain)]
		projectName, projectOK := allowedProject[canonicalDefiLlamaValue(p.Project)]
		symbolName, symbolOK := allowedSymbol[canonicalDefiLlamaValue(p.Symbol)]
		if !symbolOK || !projectOK || !chainOK {
			continue
		}

		pool := p
		pool.Chain = chainName
		pool.Project = projectName
		pool.Symbol = symbolName

		if pool.Apy > maxApy {
			maxApy = pool.Apy
			result.BestPool = pool
			result.HasBest = true
		}

		if pool.Chain == activeChainName && PoolToProtocolId(pool.Project) == activeProtocolId {
			result.CurrentPool = pool
			result.HasCurrent = true
		}
	}

	return result, nil
}

func skipJSONValue(decoder *json.Decoder) error {
	t, err := decoder.Token()
	if err != nil {
		return err
	}

	delim, ok := t.(json.Delim)
	if !ok {
		return nil
	}

	switch delim {
	case '{':
		for decoder.More() {
			if _, err := decoder.Token(); err != nil {
				return err
			}
			if err := skipJSONValue(decoder); err != nil {
				return err
			}
		}
		_, err := decoder.Token()
		return err
	case '[':
		for decoder.More() {
			if err := skipJSONValue(decoder); err != nil {
				return err
			}
		}
		_, err := decoder.Token()
		return err
	default:
		return nil
	}
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
		if canonicalDefiLlamaValue(name) == canonicalDefiLlamaValue(chain) {
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

func allowedChains(cfg Config) map[string]string {
	result := make(map[string]string, len(cfg.Chains))
	for _, chain := range cfg.Chains {
		if chain.DefiLlamaChainName == "" {
			continue
		}
		result[canonicalDefiLlamaValue(chain.DefiLlamaChainName)] = chain.DefiLlamaChainName
	}
	return result
}

func allowedValues(values []string) map[string]string {
	result := make(map[string]string, len(values))
	for _, value := range values {
		result[canonicalDefiLlamaValue(value)] = value
	}
	return result
}

func canonicalDefiLlamaValue(value string) string {
	return strings.ToLower(strings.TrimSpace(value))
}

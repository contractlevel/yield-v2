package offchain

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"math"
	"sort"
	"strings"
	"time"

	"github.com/ethereum/go-ethereum/crypto"
	"github.com/smartcontractkit/chainlink-protos/cre/go/sdk"
	crehttp "github.com/smartcontractkit/cre-sdk-go/capabilities/networking/http"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"google.golang.org/protobuf/types/known/durationpb"
)

var (
	defiLlamaHTTPClient = &crehttp.Client{}
)

const (
	defiLlamaRelayBearerTokenSecret = "DEFILLAMA_RELAY_BEARER_TOKEN"
	defiLlamaRequestTimeout         = 10 * time.Second
	defiLlamaMaxResponseBytes       = 100 << 10
	maxJSONNestingDepth             = 256
	minPoolAPY                      = 0.0
	maxPoolAPY                      = 1000.0
)

// Config contains the workflow's DefiLlama relay endpoint and selection policy.
type Config struct {
	RelayURL string
	PoolIDs  []string
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
	Pool    string  `json:"pool"`
	Chain   string  `json:"chain"`
	Project string  `json:"project"`
	Symbol  string  `json:"symbol"`
	Apy     float64 `json:"apyBase"`
}

// fetchParams holds the inputs for the node-mode fetch function.
type fetchParams struct {
	Config           Config
	ActiveProtocolId [32]byte
	ActiveChainName  string
	BearerToken      string
}

// fetchResult holds the output of the node-mode fetch function.
// Uses value semantics (not pointers) for CRE consensus serialisation.
type fetchResult struct {
	BestPool    Pool `json:"bestPool"`
	HasBest     bool `json:"hasBest"`
	CurrentPool Pool `json:"currentPool"`
	HasCurrent  bool `json:"hasCurrent"`
}

type defiLlamaRequester interface {
	SendRequest(*crehttp.Request) cre.Promise[*crehttp.Response]
}

// FetchAndSelectPools queries DefiLlama and returns the best approved pool and the
// currently active pool. activeChainSelector is the CCIP selector of the active
// strategy's chain; it is used to match against the DefiLlama "chain" field.
// Either return value may be nil: bestPool is nil when no approved pool exists; currentPool
// is nil when the active strategy's chain/project is not in the approved set.
func FetchAndSelectPools(runtime cre.Runtime, cfg Config, activeProtocolId [32]byte, activeChainSelector uint64) (*Pool, *Pool, error) {
	selectorToName := chainSelectorToName(cfg)
	activeChainName := selectorToName[activeChainSelector] // empty string if unknown
	secret, err := runtime.GetSecret(&sdk.SecretRequest{Id: defiLlamaRelayBearerTokenSecret}).Await()
	if err != nil {
		return nil, nil, fmt.Errorf("get relay bearer token: %w", err)
	}
	if secret == nil || strings.TrimSpace(secret.Value) == "" {
		return nil, nil, fmt.Errorf("get relay bearer token: empty secret")
	}

	params := fetchParams{
		Config:           cfg,
		ActiveProtocolId: activeProtocolId,
		ActiveChainName:  activeChainName,
		BearerToken:      secret.Value,
	}

	raw, err := crehttp.SendRequest(params, runtime, defiLlamaHTTPClient, fetchAndParse, cre.ConsensusIdenticalAggregation[fetchResult]()).Await()
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

// fetchAndParse is the HTTP capability callback executed on each DON node.
func fetchAndParse(params fetchParams, _ *slog.Logger, sendRequester *crehttp.SendRequester) (fetchResult, error) {
	return fetchAndParseWithRequester(params, sendRequester)
}

func fetchAndParseWithRequester(params fetchParams, requester defiLlamaRequester) (fetchResult, error) {
	req := &crehttp.Request{
		Url:    params.Config.RelayURL,
		Method: "GET",
		Headers: map[string]string{
			"Accept":        "application/json",
			"Authorization": "Bearer " + params.BearerToken,
		},
		Timeout: durationpb.New(defiLlamaRequestTimeout),
	}

	resp, err := requester.SendRequest(req).Await()
	if err != nil {
		return fetchResult{}, fmt.Errorf("do request: %w", err)
	}
	if resp == nil {
		return fetchResult{}, fmt.Errorf("do request: nil response")
	}

	if resp.StatusCode != 200 {
		return fetchResult{}, fmt.Errorf("unexpected status %d", resp.StatusCode)
	}

	body, err := readLimited(bytes.NewReader(resp.Body), defiLlamaMaxResponseBytes, "relay response body")
	if err != nil {
		return fetchResult{}, err
	}

	return parsePools(bytes.NewReader(body), params.Config, params.ActiveProtocolId, params.ActiveChainName)
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

	var candidates []Pool
	allowedPool := allowedValues(cfg.PoolIDs)
	allowedChain := allowedChains(cfg)
	allowedProject := allowedValues(cfg.Projects)
	allowedSymbol := allowedValues(cfg.Symbols)

	for decoder.More() {
		var p Pool
		if err := decoder.Decode(&p); err != nil {
			return fetchResult{}, fmt.Errorf("decode pool: %w", err)
		}

		poolID, poolOK := allowedPool[canonicalDefiLlamaValue(p.Pool)]
		chainName, chainOK := allowedChain[canonicalDefiLlamaValue(p.Chain)]
		projectName, projectOK := allowedProject[canonicalDefiLlamaValue(p.Project)]
		symbolName, symbolOK := allowedSymbol[canonicalDefiLlamaValue(p.Symbol)]
		if !poolOK || !symbolOK || !projectOK || !chainOK {
			continue
		}
		if !ValidPoolAPY(p.Apy) {
			continue
		}

		pool := p
		pool.Pool = poolID
		pool.Chain = chainName
		pool.Project = projectName
		pool.Symbol = symbolName

		candidates = append(candidates, pool)
	}

	sortPools(candidates)

	var result fetchResult
	if len(candidates) > 0 {
		result.BestPool = candidates[0]
		result.HasBest = true
	}
	for _, pool := range candidates {
		if pool.Chain == activeChainName && PoolToProtocolId(pool.Project) == activeProtocolId {
			result.CurrentPool = pool
			result.HasCurrent = true
			break
		}
	}

	return result, nil
}

func ValidPoolAPY(apy float64) bool {
	return !math.IsNaN(apy) && !math.IsInf(apy, 0) && apy >= minPoolAPY && apy <= maxPoolAPY
}

func sortPools(pools []Pool) {
	sort.SliceStable(pools, func(i, j int) bool {
		left := pools[i]
		right := pools[j]
		if left.Apy != right.Apy {
			return left.Apy > right.Apy
		}
		if left.Chain != right.Chain {
			return left.Chain < right.Chain
		}
		if left.Project != right.Project {
			return left.Project < right.Project
		}
		if left.Symbol != right.Symbol {
			return left.Symbol < right.Symbol
		}
		return left.Pool < right.Pool
	})
}

func skipJSONValue(decoder *json.Decoder) error {
	return skipJSONValueDepth(decoder, 0)
}

func skipJSONValueDepth(decoder *json.Decoder, depth int) error {
	if depth > maxJSONNestingDepth {
		return fmt.Errorf("maximum JSON nesting depth exceeded")
	}

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
			if err := skipJSONValueDepth(decoder, depth+1); err != nil {
				return err
			}
		}
		_, err := decoder.Token()
		return err
	case '[':
		for decoder.More() {
			if err := skipJSONValueDepth(decoder, depth+1); err != nil {
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

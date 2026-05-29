package offchain

import (
	"encoding/json"
	"errors"
	"io"
	"strings"
	"testing"

	crehttp "github.com/smartcontractkit/cre-sdk-go/capabilities/networking/http"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/stretchr/testify/require"
)

const testRelayURL = "https://yield-v2-defillama-relay.contractlevel.workers.dev/v1/defillama/pools"

type fakeDefiLlamaRequester struct {
	send func(*crehttp.Request) (*crehttp.Response, error)
}

func (f fakeDefiLlamaRequester) SendRequest(req *crehttp.Request) cre.Promise[*crehttp.Response] {
	resp, err := f.send(req)
	return cre.PromiseFromResult(resp, err)
}

func testConfig() Config {
	return Config{
		RelayURL: testRelayURL,
		Chains: []ChainConfig{
			{ChainSelector: 1, DefiLlamaChainName: "Ethereum"},
			{ChainSelector: 2, DefiLlamaChainName: "Arbitrum"},
			{ChainSelector: 3, DefiLlamaChainName: ""},
		},
		Projects: []string{"aave-v3", "compound-v3"},
		Symbols:  []string{"USDC"},
	}
}

func testRelayJSON() string {
	return `{
		"data": [
			{"pool":"eth-aave","chain":"Ethereum","project":"aave-v3","symbol":"USDC","apyBase":4.5},
			{"pool":"arb-comp","chain":"Arbitrum","project":"compound-v3","symbol":"USDC","apyBase":6.25},
			{"pool":"base-comp","chain":"Base","project":"compound-v3","symbol":"USDC","apyBase":10.0},
			{"pool":"unsupported-project","chain":"Ethereum","project":"unsupported","symbol":"USDC","apyBase":99.0},
			{"pool":"unsupported-symbol","chain":"Ethereum","project":"aave-v3","symbol":"DAI","apyBase":99.0}
		]
	}`
}

func testRuntimeWithRelayToken(t *testing.T, token string) cre.Runtime {
	t.Helper()
	return testutils.NewRuntime(t, testutils.Secrets{
		"": {defiLlamaRelayBearerTokenSecret: token},
	})
}

func Test_ParsePools_selectsBestAndCurrent(t *testing.T) {
	result, err := parsePools(strings.NewReader(testRelayJSON()), testConfig(), PoolToProtocolId("aave-v3"), "Ethereum")
	require.NoError(t, err, "expected valid response to parse")
	require.True(t, result.HasBest, "expected best pool")
	require.Equal(t, Pool{Pool: "arb-comp", Chain: "Arbitrum", Project: "compound-v3", Symbol: "USDC", Apy: 6.25}, result.BestPool)
	require.True(t, result.HasCurrent, "expected current pool")
	require.Equal(t, Pool{Pool: "eth-aave", Chain: "Ethereum", Project: "aave-v3", Symbol: "USDC", Apy: 4.5}, result.CurrentPool)
}

func Test_ParsePools_noApprovedPools(t *testing.T) {
	body := `{"data":[{"pool":"base-aave","chain":"Base","project":"aave-v3","symbol":"USDC","apyBase":8.0}]}`

	result, err := parsePools(strings.NewReader(body), testConfig(), PoolToProtocolId("aave-v3"), "Ethereum")
	require.NoError(t, err, "expected valid response to parse")
	require.False(t, result.HasBest, "expected no best pool")
	require.False(t, result.HasCurrent, "expected no current pool")
}

func Test_ParsePools_currentRequiresActiveChainAndProtocol(t *testing.T) {
	result, err := parsePools(strings.NewReader(testRelayJSON()), testConfig(), PoolToProtocolId("compound-v3"), "Ethereum")
	require.NoError(t, err, "expected valid response to parse")
	require.True(t, result.HasBest, "expected best pool")
	require.False(t, result.HasCurrent, "expected no current pool when protocol does not match active chain")
}

func Test_ParsePools_matchesCaseInsensitiveAndReturnsConfiguredValues(t *testing.T) {
	body := `{"data":[
		{"pool":"eth-aave","chain":"ethereum","project":"AAVE-V3","symbol":"usdc","apyBase":4.5},
		{"pool":"arb-comp","chain":"ARBITRUM","project":"COMPOUND-V3","symbol":"usdc","apyBase":6.25}
	]}`

	result, err := parsePools(strings.NewReader(body), testConfig(), PoolToProtocolId("aave-v3"), "Ethereum")
	require.NoError(t, err, "expected valid response to parse")
	require.True(t, result.HasBest, "expected best pool")
	require.Equal(t, Pool{Pool: "arb-comp", Chain: "Arbitrum", Project: "compound-v3", Symbol: "USDC", Apy: 6.25}, result.BestPool)
	require.True(t, result.HasCurrent, "expected current pool")
	require.Equal(t, Pool{Pool: "eth-aave", Chain: "Ethereum", Project: "aave-v3", Symbol: "USDC", Apy: 4.5}, result.CurrentPool)
}

func Test_ParsePools_errors(t *testing.T) {
	tests := []struct {
		name    string
		body    string
		wantErr string
	}{
		{name: "invalid json token", body: `{"x": tru`, wantErr: `skip top-level key "x"`},
		{name: "missing data", body: `{"pools":[]}`, wantErr: "'data' key not found in response"},
		{name: "data is not array", body: `{"data":{}}`, wantErr: "expected '[' after 'data' key"},
		{name: "invalid pool", body: `{"data":[{"apyBase":"not-a-number"}]}`, wantErr: "decode pool"},
		{name: "missing array start", body: `{"data":`, wantErr: "read array start"},
		{name: "top-level value is not object", body: `[]`, wantErr: "expected top-level object"},
		{name: "empty response", body: ``, wantErr: "read object start"},
		{name: "malformed top-level key", body: `{"ignored": true,`, wantErr: "read top-level key"},
		{name: "nested data key ignored", body: `{"meta":{"data":[{"chain":"Ethereum","project":"aave-v3","symbol":"USDC","apyBase":4.5}]}}`, wantErr: "'data' key not found in response"},
		{name: "malformed skipped object key", body: `{"meta":{"nested": true,},"data":[]}`, wantErr: `skip top-level key "meta"`},
		{name: "malformed skipped object value", body: `{"meta":{"nested":},"data":[]}`, wantErr: `skip top-level key "meta"`},
		{name: "malformed skipped array value", body: `{"meta":[true,],"data":[]}`, wantErr: `skip top-level key "meta"`},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := parsePools(strings.NewReader(tt.body), testConfig(), PoolToProtocolId("aave-v3"), "Ethereum")
			require.Error(t, err, "expected parse error")
			require.Equal(t, fetchResult{}, result, "expected zero result on error")
			require.ErrorContains(t, err, tt.wantErr)
		})
	}
}

func Test_FetchAndParse_sendsRelayAuthHeader(t *testing.T) {
	requester := fakeDefiLlamaRequester{send: func(req *crehttp.Request) (*crehttp.Response, error) {
		require.Equal(t, testRelayURL, req.Url, "unexpected URL")
		require.Equal(t, "GET", req.Method, "unexpected method")
		require.Equal(t, "application/json", req.Headers["Accept"], "unexpected accept header")
		require.Equal(t, "Bearer test-token", req.Headers["Authorization"], "unexpected auth header")
		require.NotNil(t, req.Timeout, "expected timeout")

		return &crehttp.Response{
			StatusCode: 200,
			Body:       []byte(testRelayJSON()),
		}, nil
	}}

	result, err := fetchAndParseWithRequester(fetchParams{
		Config:           testConfig(),
		ActiveProtocolId: PoolToProtocolId("aave-v3"),
		ActiveChainName:  "Ethereum",
		BearerToken:      "test-token",
	}, requester)
	require.NoError(t, err, "expected fetch and parse to succeed")
	require.True(t, result.HasBest, "expected best pool")
	require.True(t, result.HasCurrent, "expected current pool")
}

func Test_FetchAndParse_errors(t *testing.T) {
	tests := []struct {
		name    string
		send    func(*crehttp.Request) (*crehttp.Response, error)
		wantErr string
	}{
		{
			name: "request error",
			send: func(*crehttp.Request) (*crehttp.Response, error) {
				return nil, errors.New("network failed")
			},
			wantErr: "do request: network failed",
		},
		{
			name: "unexpected status",
			send: func(*crehttp.Request) (*crehttp.Response, error) {
				return &crehttp.Response{StatusCode: 502}, nil
			},
			wantErr: "unexpected status 502",
		},
		{
			name: "body too large",
			send: func(*crehttp.Request) (*crehttp.Response, error) {
				return &crehttp.Response{
					StatusCode: 200,
					Body:       mustRead(t, io.LimitReader(zeroReader{}, defiLlamaMaxResponseBytes+1)),
				}, nil
			},
			wantErr: "relay response body exceeds 102400 bytes",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			requester := fakeDefiLlamaRequester{send: tt.send}
			result, err := fetchAndParseWithRequester(fetchParams{Config: testConfig(), BearerToken: "test-token"}, requester)
			require.Error(t, err, "expected fetch error")
			require.Equal(t, fetchResult{}, result, "expected zero result on error")
			require.ErrorContains(t, err, tt.wantErr)
		})
	}
}

func Test_FetchAndSelectPools(t *testing.T) {
	original := defiLlamaHTTPClient
	defiLlamaHTTPClient = &crehttp.Client{}
	t.Cleanup(func() { defiLlamaHTTPClient = original })

	requester := fakeDefiLlamaRequester{send: func(req *crehttp.Request) (*crehttp.Response, error) {
		require.Equal(t, "Bearer test-token", req.Headers["Authorization"], "unexpected auth header")
		return &crehttp.Response{StatusCode: 200, Body: []byte(testRelayJSON())}, nil
	}}
	result, err := fetchAndParseWithRequester(fetchParams{
		Config:           testConfig(),
		ActiveProtocolId: PoolToProtocolId("aave-v3"),
		ActiveChainName:  "Ethereum",
		BearerToken:      "test-token",
	}, requester)
	require.NoError(t, err, "expected fetch and parse to succeed")
	require.True(t, result.HasBest, "expected best pool")

	runtime := testRuntimeWithRelayToken(t, "test-token")
	best, current, err := FetchAndSelectPools(runtime, testConfig(), PoolToProtocolId("aave-v3"), 1)
	require.Error(t, err, "test runtime has no HTTP capability mock installed")
	require.Nil(t, best, "expected nil best pool on capability error")
	require.Nil(t, current, "expected nil current pool on capability error")
}

func Test_FetchAndSelectPools_secretErrors(t *testing.T) {
	tests := []struct {
		name    string
		secrets testutils.Secrets
		wantErr string
	}{
		{name: "missing secret", secrets: testutils.Secrets{}, wantErr: "get relay bearer token"},
		{name: "empty secret", secrets: testutils.Secrets{"": {defiLlamaRelayBearerTokenSecret: ""}}, wantErr: "empty secret"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			runtime := testutils.NewRuntime(t, tt.secrets)
			best, current, err := FetchAndSelectPools(runtime, testConfig(), PoolToProtocolId("aave-v3"), 1)
			require.Error(t, err, "expected secret error")
			require.Nil(t, best, "expected nil best pool")
			require.Nil(t, current, "expected nil current pool")
			require.ErrorContains(t, err, tt.wantErr)
		})
	}
}

func Test_SkipJSONValue_closingDelimiter(t *testing.T) {
	decoder := json.NewDecoder(strings.NewReader(`[]`))

	token, err := decoder.Token()
	require.NoError(t, err, "expected array start")
	require.Equal(t, json.Delim('['), token, "unexpected first token")

	require.NoError(t, skipJSONValue(decoder), "expected closing delimiter to be skipped")
}

func Test_PoolToProtocolId(t *testing.T) {
	id := PoolToProtocolId("aave-v3")
	require.Equal(t, id, PoolToProtocolId("aave-v3"), "expected deterministic protocol ID")
	require.NotEqual(t, id, PoolToProtocolId("compound-v3"), "expected different projects to hash differently")
}

func Test_PoolToChainSelector(t *testing.T) {
	selector, err := PoolToChainSelector(testConfig(), "Arbitrum")
	require.NoError(t, err, "expected configured chain to map")
	require.Equal(t, uint64(2), selector, "unexpected selector")

	selector, err = PoolToChainSelector(testConfig(), "arbitrum")
	require.NoError(t, err, "expected configured chain to map case-insensitively")
	require.Equal(t, uint64(2), selector, "unexpected selector")

	selector, err = PoolToChainSelector(testConfig(), "Base")
	require.Error(t, err, "expected unconfigured chain to fail")
	require.Zero(t, selector, "expected zero selector")
	require.ErrorContains(t, err, `no chain selector for DefiLlama chain "Base"`)
}

func Test_ConfigHelpers(t *testing.T) {
	cfg := testConfig()

	require.Equal(t, map[uint64]string{1: "Ethereum", 2: "Arbitrum"}, chainSelectorToName(cfg))
	require.Equal(t, map[string]string{"ethereum": "Ethereum", "arbitrum": "Arbitrum"}, allowedChains(cfg))
	require.Equal(t, map[string]string{"usdc": "USDC"}, allowedValues([]string{"USDC"}))
}

func mustRead(t *testing.T, r io.Reader) []byte {
	t.Helper()
	body, err := io.ReadAll(r)
	require.NoError(t, err, "expected read")
	return body
}

type zeroReader struct{}

func (zeroReader) Read(p []byte) (int, error) {
	for i := range p {
		p[i] = 0
	}
	return len(p), nil
}

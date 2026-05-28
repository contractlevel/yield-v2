package offchain

import (
	"bytes"
	"compress/gzip"
	"errors"
	"io"
	"net/http"
	"net/url"
	"strings"
	"testing"

	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/stretchr/testify/require"
)

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(req *http.Request) (*http.Response, error) {
	return f(req)
}

func testConfig() Config {
	return Config{
		Chains: []ChainConfig{
			{ChainSelector: 1, DefiLlamaChainName: "Ethereum"},
			{ChainSelector: 2, DefiLlamaChainName: "Arbitrum"},
			{ChainSelector: 3, DefiLlamaChainName: ""},
		},
		Projects: []string{"aave-v3", "compound-v3"},
		Symbols:  []string{"USDC"},
	}
}

func testPoolsJSON() string {
	return `{
		"ignored": true,
		"data": [
			{"chain":"Ethereum","project":"aave-v3","symbol":"USDC","apy":4.5},
			{"chain":"Arbitrum","project":"compound-v3","symbol":"USDC","apy":6.25},
			{"chain":"Base","project":"compound-v3","symbol":"USDC","apy":10.0},
			{"chain":"Ethereum","project":"unsupported","symbol":"USDC","apy":99.0},
			{"chain":"Ethereum","project":"aave-v3","symbol":"DAI","apy":99.0}
		]
	}`
}

func withDefiLlamaHTTPClient(t *testing.T, client *http.Client) {
	t.Helper()

	original := defiLlamaHTTPClient
	defiLlamaHTTPClient = client
	t.Cleanup(func() {
		defiLlamaHTTPClient = original
	})
}

func withDefiLlamaURL(t *testing.T, url string) {
	t.Helper()

	original := defiLlamaURL
	defiLlamaURL = url
	t.Cleanup(func() {
		defiLlamaURL = original
	})
}

func Test_ParsePools_selectsBestAndCurrent(t *testing.T) {
	result, err := parsePools(strings.NewReader(testPoolsJSON()), testConfig(), PoolToProtocolId("aave-v3"), "Ethereum")
	require.NoError(t, err, "expected valid response to parse")
	require.True(t, result.HasBest, "expected best pool")
	require.Equal(t, Pool{Chain: "Arbitrum", Project: "compound-v3", Symbol: "USDC", Apy: 6.25}, result.BestPool)
	require.True(t, result.HasCurrent, "expected current pool")
	require.Equal(t, Pool{Chain: "Ethereum", Project: "aave-v3", Symbol: "USDC", Apy: 4.5}, result.CurrentPool)
}

func Test_ParsePools_noApprovedPools(t *testing.T) {
	body := `{"data":[{"chain":"Base","project":"aave-v3","symbol":"USDC","apy":8.0}]}`

	result, err := parsePools(strings.NewReader(body), testConfig(), PoolToProtocolId("aave-v3"), "Ethereum")
	require.NoError(t, err, "expected valid response to parse")
	require.False(t, result.HasBest, "expected no best pool")
	require.False(t, result.HasCurrent, "expected no current pool")
}

func Test_ParsePools_currentRequiresActiveChainAndProtocol(t *testing.T) {
	result, err := parsePools(strings.NewReader(testPoolsJSON()), testConfig(), PoolToProtocolId("compound-v3"), "Ethereum")
	require.NoError(t, err, "expected valid response to parse")
	require.True(t, result.HasBest, "expected best pool")
	require.False(t, result.HasCurrent, "expected no current pool when protocol does not match active chain")
}

func Test_ParsePools_errors(t *testing.T) {
	tests := []struct {
		name    string
		body    string
		wantErr string
	}{
		{
			name:    "invalid json token",
			body:    `{"x": tru`,
			wantErr: "token scan",
		},
		{
			name:    "missing data",
			body:    `{"pools":[]}`,
			wantErr: "'data' key not found in response",
		},
		{
			name:    "data is not array",
			body:    `{"data":{}}`,
			wantErr: "expected '[' after 'data' key",
		},
		{
			name:    "invalid pool",
			body:    `{"data":[{"apy":"not-a-number"}]}`,
			wantErr: "decode pool",
		},
		{
			name:    "missing array start",
			body:    `{"data":`,
			wantErr: "read array start",
		},
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

func Test_FetchAndParse_successPlainAndGzip(t *testing.T) {
	tests := []struct {
		name        string
		gzipBody    bool
		contentType string
	}{
		{name: "plain"},
		{name: "gzip", gzipBody: true, contentType: "gzip"},
		{name: "gzip mixed case", gzipBody: true, contentType: "GZip"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			body := []byte(testPoolsJSON())
			if tt.gzipBody {
				body = gzipBytes(t, body)
			}

			withDefiLlamaHTTPClient(t, &http.Client{Transport: roundTripFunc(func(req *http.Request) (*http.Response, error) {
				require.Equal(t, http.MethodGet, req.Method, "unexpected method")
				require.Equal(t, defiLlamaURL, req.URL.String(), "unexpected URL")
				require.Equal(t, "gzip", req.Header.Get("Accept-Encoding"), "unexpected encoding header")
				_, hasDeadline := req.Context().Deadline()
				require.True(t, hasDeadline, "expected request context deadline")

				return &http.Response{
					StatusCode: http.StatusOK,
					Header:     http.Header{"Content-Encoding": []string{tt.contentType}},
					Body:       io.NopCloser(bytes.NewReader(body)),
					Request:    req,
				}, nil
			})})

			result, err := fetchAndParse(fetchParams{
				Config:           testConfig(),
				ActiveProtocolId: PoolToProtocolId("aave-v3"),
				ActiveChainName:  "Ethereum",
			}, nil)
			require.NoError(t, err, "expected fetch and parse to succeed")
			require.True(t, result.HasBest, "expected best pool")
			require.True(t, result.HasCurrent, "expected current pool")
		})
	}
}

func Test_FetchAndParse_errors(t *testing.T) {
	tests := []struct {
		name      string
		roundTrip func(*http.Request) (*http.Response, error)
		wantErr   string
	}{
		{
			name: "build request error",
			roundTrip: func(*http.Request) (*http.Response, error) {
				t.Fatal("round trip must not be called when request cannot be built")
				return nil, nil
			},
			wantErr: "build request",
		},
		{
			name: "request error",
			roundTrip: func(*http.Request) (*http.Response, error) {
				return nil, errors.New("network failed")
			},
			wantErr: `do request: Get "https://yields.llama.fi/pools": network failed`,
		},
		{
			name: "unexpected status",
			roundTrip: func(req *http.Request) (*http.Response, error) {
				return &http.Response{StatusCode: http.StatusBadGateway, Body: io.NopCloser(strings.NewReader("")), Request: req}, nil
			},
			wantErr: "unexpected status 502",
		},
		{
			name: "invalid gzip body",
			roundTrip: func(req *http.Request) (*http.Response, error) {
				return &http.Response{
					StatusCode: http.StatusOK,
					Header:     http.Header{"Content-Encoding": []string{"gzip"}},
					Body:       io.NopCloser(strings.NewReader("not gzip")),
					Request:    req,
				}, nil
			},
			wantErr: "gzip reader",
		},
		{
			name: "read body error",
			roundTrip: func(req *http.Request) (*http.Response, error) {
				return &http.Response{StatusCode: http.StatusOK, Body: io.NopCloser(errReader{}), Request: req}, nil
			},
			wantErr: "read compressed response body: read failed",
		},
		{
			name: "redirected final URL",
			roundTrip: func(req *http.Request) (*http.Response, error) {
				finalReq := req.Clone(req.Context())
				finalReq.URL.Scheme = "http"
				finalReq.URL.Host = "169.254.169.254"
				return &http.Response{StatusCode: http.StatusOK, Body: io.NopCloser(strings.NewReader(testPoolsJSON())), Request: finalReq}, nil
			},
			wantErr: `unexpected final response URL "http://169.254.169.254/pools"`,
		},
		{
			name: "missing final URL",
			roundTrip: func(*http.Request) (*http.Response, error) {
				return &http.Response{StatusCode: http.StatusOK, Body: io.NopCloser(strings.NewReader(testPoolsJSON()))}, nil
			},
			wantErr: "missing final response URL",
		},
		{
			name: "compressed body too large",
			roundTrip: func(req *http.Request) (*http.Response, error) {
				return &http.Response{
					StatusCode: http.StatusOK,
					Body:       io.NopCloser(io.LimitReader(zeroReader{}, defiLlamaMaxCompressedBytes+1)),
					Request:    req,
				}, nil
			},
			wantErr: "compressed response body exceeds 10485760 bytes",
		},
		{
			name: "decoded gzip body too large",
			roundTrip: func(req *http.Request) (*http.Response, error) {
				return &http.Response{
					StatusCode: http.StatusOK,
					Header:     http.Header{"Content-Encoding": []string{"gzip"}},
					Body:       io.NopCloser(bytes.NewReader(gzipBytes(t, bytes.Repeat([]byte("x"), defiLlamaMaxDecodedBytes+1)))),
					Request:    req,
				}, nil
			},
			wantErr: "decoded response body exceeds 10485760 bytes",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if tt.name == "build request error" {
				withDefiLlamaURL(t, "://bad-url")
			}
			withDefiLlamaHTTPClient(t, &http.Client{Transport: roundTripFunc(tt.roundTrip)})

			result, err := fetchAndParse(fetchParams{Config: testConfig()}, nil)
			require.Error(t, err, "expected fetch error")
			require.Equal(t, fetchResult{}, result, "expected zero result on error")
			require.ErrorContains(t, err, tt.wantErr)
		})
	}
}

func Test_FetchAndSelectPools(t *testing.T) {
	withDefiLlamaHTTPClient(t, &http.Client{Transport: roundTripFunc(func(req *http.Request) (*http.Response, error) {
		return &http.Response{
			StatusCode: http.StatusOK,
			Body:       io.NopCloser(strings.NewReader(testPoolsJSON())),
			Request:    req,
		}, nil
	})})

	runtime := testutils.NewRuntime(t, testutils.Secrets{})
	best, current, err := FetchAndSelectPools(runtime, testConfig(), PoolToProtocolId("aave-v3"), 1)
	require.NoError(t, err, "expected fetch to succeed")
	require.Equal(t, &Pool{Chain: "Arbitrum", Project: "compound-v3", Symbol: "USDC", Apy: 6.25}, best)
	require.Equal(t, &Pool{Chain: "Ethereum", Project: "aave-v3", Symbol: "USDC", Apy: 4.5}, current)
}

func Test_FetchAndSelectPools_noPools(t *testing.T) {
	withDefiLlamaHTTPClient(t, &http.Client{Transport: roundTripFunc(func(req *http.Request) (*http.Response, error) {
		return &http.Response{
			StatusCode: http.StatusOK,
			Body:       io.NopCloser(strings.NewReader(`{"data":[]}`)),
			Request:    req,
		}, nil
	})})

	runtime := testutils.NewRuntime(t, testutils.Secrets{})
	best, current, err := FetchAndSelectPools(runtime, testConfig(), PoolToProtocolId("aave-v3"), 1)
	require.NoError(t, err, "expected fetch to succeed")
	require.Nil(t, best, "expected nil best pool")
	require.Nil(t, current, "expected nil current pool")
}

func Test_FetchAndSelectPools_error(t *testing.T) {
	withDefiLlamaHTTPClient(t, &http.Client{Transport: roundTripFunc(func(*http.Request) (*http.Response, error) {
		return nil, errors.New("network failed")
	})})

	runtime := testutils.NewRuntime(t, testutils.Secrets{})
	best, current, err := FetchAndSelectPools(runtime, testConfig(), PoolToProtocolId("aave-v3"), 1)
	require.Error(t, err, "expected fetch error")
	require.Nil(t, best, "expected nil best pool")
	require.Nil(t, current, "expected nil current pool")
	require.ErrorContains(t, err, `fetch pools: do request: Get "https://yields.llama.fi/pools": network failed`)
}

func Test_ValidateDefiLlamaResponseURL_parseExpectedURLError(t *testing.T) {
	withDefiLlamaURL(t, "://bad-url")

	err := validateDefiLlamaResponseURL(&http.Response{
		Request: &http.Request{URL: mustParseURL(t, "https://yields.llama.fi/pools")},
	})
	require.Error(t, err, "expected parse error")
	require.ErrorContains(t, err, "parse expected URL")
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

	selector, err = PoolToChainSelector(testConfig(), "Base")
	require.Error(t, err, "expected unconfigured chain to fail")
	require.Zero(t, selector, "expected zero selector")
	require.ErrorContains(t, err, `no chain selector for DefiLlama chain "Base"`)
}

func Test_ConfigHelpers(t *testing.T) {
	cfg := testConfig()

	require.Equal(t, map[uint64]string{1: "Ethereum", 2: "Arbitrum"}, chainSelectorToName(cfg))
	require.Equal(t, map[string]bool{"Ethereum": true, "Arbitrum": true}, allowedChains(cfg))
	require.Equal(t, map[string]bool{"USDC": true}, allowedValues([]string{"USDC"}))
}

func gzipBytes(t *testing.T, body []byte) []byte {
	t.Helper()

	var buf bytes.Buffer
	gz := gzip.NewWriter(&buf)
	_, err := gz.Write(body)
	require.NoError(t, err, "expected gzip write")
	require.NoError(t, gz.Close(), "expected gzip close")
	return buf.Bytes()
}

func mustParseURL(t *testing.T, raw string) *url.URL {
	t.Helper()

	u, err := url.Parse(raw)
	require.NoError(t, err, "expected test URL to parse")
	return u
}

type errReader struct{}

func (errReader) Read([]byte) (int, error) {
	return 0, errors.New("read failed")
}

type zeroReader struct{}

func (zeroReader) Read(p []byte) (int, error) {
	for i := range p {
		p[i] = 0
	}
	return len(p), nil
}

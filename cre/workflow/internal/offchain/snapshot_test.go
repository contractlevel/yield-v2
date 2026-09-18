package offchain

import (
	"strings"
	"testing"

	crehttp "github.com/smartcontractkit/cre-sdk-go/capabilities/networking/http"
)

func TestValidateSnapshotFreshness(t *testing.T) {
	for _, tt := range []struct {
		name, body, wantError string
		now                   int64
	}{
		{"fresh", `{"refreshedAt":1000}`, "", 1000},
		{"boundary", `{"refreshedAt":1000}`, "", 1900},
		{"stale", `{"refreshedAt":1000}`, "older than 15 minutes", 1901},
		{"future", `{"refreshedAt":1001}`, "in the future", 1000},
		{"missing", `{}`, "invalid snapshot", 1000},
		{"null", `{"refreshedAt":null}`, "invalid snapshot", 1000},
		{"negative", `{"refreshedAt":-1}`, "invalid snapshot", 1000},
		{"negative clock", `{"refreshedAt":0}`, "invalid snapshot", -1},
		{"malformed", `{`, "decode snapshot", 1000},
		{"wrong type", `{"refreshedAt":"1000"}`, "decode snapshot", 1000},
		{"fraction", `{"refreshedAt":1000.5}`, "decode snapshot", 1000},
		{"overflow", `{"refreshedAt":9223372036854775808}`, "decode snapshot", 1000},
	} {
		t.Run(tt.name, func(t *testing.T) {
			err := validateSnapshotFreshness([]byte(tt.body), tt.now)
			if tt.wantError == "" {
				if err != nil {
					t.Fatal(err)
				}
			} else if err == nil || !strings.Contains(err.Error(), tt.wantError) {
				t.Fatalf("got %v, want %q", err, tt.wantError)
			}
		})
	}
}

func TestFetchRejectsStaleSnapshotBeforePoolSelection(t *testing.T) {
	requester := fakeDefiLlamaRequester{send: func(*crehttp.Request) (*crehttp.Response, error) {
		return &crehttp.Response{StatusCode: 200, Body: []byte(testRelayJSON())}, nil
	}}
	result, err := fetchAndParseWithRequester(fetchParams{Config: testConfig(), ObservedAt: 901}, requester)
	if err == nil || !strings.Contains(err.Error(), "older than 15 minutes") {
		t.Fatalf("got %v, want stale snapshot error", err)
	}
	if result.HasBest || result.HasCurrent {
		t.Fatal("stale snapshot selected a pool")
	}
}

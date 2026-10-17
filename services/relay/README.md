# Yieldcoin Relay

Cloudflare Worker that publishes a snapshot of USDC base supply APYs for the Yieldcoin v2 CRE rebalance workflow.

## Purpose

The workflow previously read rates from the DefiLlama API, which is now behind a paywall. The relay reads each strategy's rate directly from its protocol instead:

- **Aave V3** and **Aave V4**: official Aave GraphQL APIs (`api.v3.aave.com`, `api.v4.aave.com`).
- **Compound V3**: `getUtilization()` then `getSupplyRate(utilization)` via `eth_call` on our RPC providers.

The relay serves one stored snapshot, refreshed well before the rebalance, rather than fetching on request. This makes it very likely that DON nodes observe the same rates; KV is eventually consistent, so it is not guaranteed. CRE then requires identical consensus on each node's parsed selection result.

For compatibility with the deployed workflow, the Worker name, the `/v1/defillama/pools` route, and the DefiLlama pool UUIDs are unchanged.

## How It Works

**Scheduled refresh** (`17:50`, `17:55`, `17:58` UTC, before the daily `18:00` rebalance):

1. Fetch the rate for every strategy in `src/config.rs::POOLS` concurrently.
2. Validate each response:
   - Aave: no GraphQL errors, and the returned market or Spoke, asset, chain, and reserve ID match the request.
   - Compound: JSON-RPC `2.0`, integer `id` `1`, no `error`, and an exact 32-byte ABI word. The utilization word is passed through unchanged; the supply rate must fit `uint64`.
   - Every provider body is streamed and capped at 64 KiB.
   - Every APY must be finite and within 0–1000% inclusive.
3. Convert each rate to a percentage APY:
   - Aave V3: `supplyInfo.apy.value` is a fraction, multiplied by 100.
   - Aave V4: `summary.supplyApy.normalized` is already a percentage.
   - Compound V3: the 1e18-scaled per-second rate is compounded per second over a 365-day year, `100 × ((1 + rate / 1e18)^31,536,000 − 1)`. This is effective annual yield, not simple APR.
4. Write `{refreshedAt, data}` to the KV key `pools`.

**All-or-nothing:** every strategy must return a valid rate. If any request fails, any rate is invalid, or the 30-second budget expires, outstanding requests are aborted, nothing is written, and the previous snapshot stays in KV. The error is logged and the next scheduled run retries.

The 30-second budget matters because `fetch` has no timeout of its own and scheduled events may run for 15 minutes; without it, a hung refresh could overwrite KV during the rebalance. Refreshes are scheduled before the rebalance to allow time for KV propagation, which can briefly expose different versions to different readers.

**Read** (`GET /v1/defillama/pools` with `Authorization: Bearer <token>`) returns the stored snapshot and never fetches upstream:

| Status | Meaning                                            |
| ------ | -------------------------------------------------- |
| `200`  | Stored snapshot, including a stale one (see below) |
| `401`  | Missing or wrong bearer token                      |
| `404`  | Any other route or method                          |
| `500`  | `RELAY_BEARER_TOKEN` is missing or empty           |
| `503`  | No snapshot has been stored yet                    |

Two deliberate behaviours:

- **Freshness is enforced by CRE, not the relay.** A stale stored snapshot is returned with HTTP `200`. The workflow rejects snapshots older than 15 minutes or dated in the future, using DON time.
- **Pools are in catalogue order.** The relay does not sort; the workflow sorts by APY itself.

## Response

```json
{
  "refreshedAt": 1770000000,
  "data": [
    {
      "pool": "aa70268e-4b52-42bf-a116-608b370f9501",
      "chain": "Ethereum",
      "project": "aave-v3",
      "symbol": "USDC",
      "apyBase": 4.25
    }
  ]
}
```

`refreshedAt` is the Unix time in seconds when the refresh started. `apyBase` is a percentage (`4.25` means 4.25%) and excludes rewards and incentives.

## Strategies

The relay refreshes all 12 strategies in `POOLS`. Adding or removing one is a code change; unit tests check the catalogue against `cre/workflow/config.production.json` and `evm/script/HelperConfig.s.sol`.

Each pool ID must map to the exact canonical native USDC market our adapters enter. Do not add a pool only because its chain, project, and symbol look correct; verify the underlying token and market first.

| Chain     | CRE Chain Label | Protocol    | Pool ID                                | Native USDC                                  | Notes                                                                                        |
| --------- | --------------- | ----------- | -------------------------------------- | -------------------------------------------- | -------------------------------------------------------------------------------------------- |
| Ethereum  | Ethereum        | Aave V3     | `aa70268e-4b52-42bf-a116-608b370f9501` | `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48` | Plain market                                                                                 |
| Ethereum  | Ethereum        | Compound V3 | `7da72d09-56ca-4ec5-a45f-59114353e487` | `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48` | Plain USDC Comet                                                                             |
| Ethereum  | Ethereum        | Aave V4     | `4ac1a968-68ab-4da8-87e3-8f1e15e3dae2` | `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48` | Reserve `7` on our Spoke, whose Hub is `Core` (`0xCca852Bc40e560adC3b1Cc58CA5b55638ce826c9`) |
| Arbitrum  | Arbitrum        | Aave V3     | `d9fa8e14-0447-4207-9ae8-7810199dfa1f` | `0xaf88d065e77c8cC2239327C5EDb3A432268e5831` | Native USDC, not bridged USDC.e                                                              |
| Arbitrum  | Arbitrum        | Compound V3 | `d9c395b9-00d0-4426-a6b3-572a6dd68e54` | `0xaf88d065e77c8cC2239327C5EDb3A432268e5831` | Native USDC, not bridged USDC.e                                                              |
| Base      | Base            | Aave V3     | `7e0661bf-8cf3-45e6-9424-31916d4c7b84` | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` | Plain market                                                                                 |
| Base      | Base            | Compound V3 | `0c8567f8-ba5b-41ad-80de-00a71895eb19` | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` | Plain USDC Comet                                                                             |
| Avalanche | Avalanche       | Aave V3     | `c4b05318-88af-4536-a834-f5fc8940d2d3` | `0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E` | Plain market                                                                                 |
| Avalanche | Avalanche       | Aave V4     | `22323e90-bde5-54a1-8686-53b4205b61b7` | `0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E` | Reserve `2` on our Spoke, whose Hub is `0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e`          |
| Optimism  | OP Mainnet      | Aave V3     | `0758c3b8-4ffb-4176-b0a9-f446e367db46` | `0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85` | The chain label must remain `OP Mainnet`                                                     |
| Optimism  | OP Mainnet      | Compound V3 | `b828f0cb-853d-4b32-aebb-2e20d7fd70a8` | `0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85` | The chain label must remain `OP Mainnet`                                                     |
| Polygon   | Polygon         | Aave V3     | `1b8b4cdb-0728-42a8-bf13-2c8fea7427ee` | `0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359` | Native USDC; the bridged USDC pool `37b04faa-95bb-4ccb-9c4e-c70fa167342b` is excluded        |

## Configuration

`wrangler.toml` holds the Worker name, the `sh build.sh` command for the sandboxed offline build, compatibility date, KV binding (`POOL_SNAPSHOTS`), cron schedule, and logging settings. The KV namespace ID is public.

Secrets are set with `npm exec --no -- wrangler secret put <NAME>`:

| Secret                                                                     | Purpose                                                    |
| -------------------------------------------------------------------------- | ---------------------------------------------------------- |
| `RELAY_BEARER_TOKEN`                                                       | Access control for the public Worker URL                   |
| `ETHEREUM_RPC_URL`, `ARBITRUM_RPC_URL`, `BASE_RPC_URL`, `OPTIMISM_RPC_URL` | Compound V3 `eth_call`s; URLs are never included in errors |

Bearer token rules:

- Use a fresh high-entropy production token. The token used during local testing or initial setup must be rotated before production use.
- Store it in Cloudflare only as the Worker secret `RELAY_BEARER_TOKEN`, and in CRE only as the workflow secret `DEFILLAMA_RELAY_BEARER_TOKEN`.
- Do not put the production token in `.env`, `wrangler.toml`, workflow config JSON, README examples, shell history, or committed docs.
- A local `.env` or `.dev.vars` may hold a development-only token and must remain ignored by git.

## Dependencies

Runtime dependencies are intentionally limited to:

- `worker`
- `futures-util`
- `serde`
- `serde_json`

Do not add runtime dependencies without an explicit review. In particular, do not add `reqwest`, `tokio`, `axum`, `anyhow`, `thiserror`, config frameworks, logging frameworks, or test helper crates. `deny.toml` enforces the most important bans.

Deployment tooling is project-local and pinned: `wrangler` `4.147.0` through `package-lock.json` with npm integrity hashes. Use frozen installs and avoid moving versions. Do not use `wrangler@latest` or `npx wrangler`.

On 2026-10-07, npm verified registry signatures for all 91 candidate packages
and available attestations for 75. The audit reported GHSA-wq5f-xc86-pv6w in
Sharp 0.35.4, propagated to Miniflare and Wrangler. Sharp is local development
tooling, not part of the deployed Rust Worker. This relay has no Images binding
or image transformations; the advisory's SVG-decoding path is not used.
The documented code-execution conditions concern glibc Linux, while this build
setup uses macOS. Reassess this finding if the platform or image usage changes;
the dependency remains affected and audits will continue to report it.

## Tooling Setup

Node.js is pinned to `24.21.0` in `.nvmrc` and `package.json`. npm rejects
incompatible Node versions by default through `engine-strict=true` in `.npmrc`.
Dependency lifecycle scripts are disabled by default through `ignore-scripts=true`;
explicit `npm run` commands can still execute scripts.

Review any tool installation or script before running it. Before installing
Node from an archive, verify the official release's signed checksum manifest
and the archive checksum. On macOS, an alternative is the official installer:
verify it with `pkgutil --check-signature` and require a trusted Node.js
Foundation signature. Do not pipe downloaded installation scripts into a shell.

The existing build uses worker-build `0.8.3`. Its published source was reviewed;
the installed executable has not been independently reproduced from source.
Review and approve installation before running the command below on a new machine.

```bash
# Only if worker-build is missing, after installation approval:
# cargo install worker-build --version 0.8.3 --locked
nvm use # activate the version in .nvmrc
npm ci --ignore-scripts # pinned Node tooling from the lockfile
npm exec --no -- wrangler --version # expect 4.147.0
npm exec --no -- wrangler login
```

`npm exec --no --` refuses to install a missing package, so use it for every Wrangler command.

### Build network isolation

Before building, export `WORKER_BUILD_BIN`, `ESBUILD_BIN`, and `WASM_BINDGEN_BIN`
in your local shell. Each must point to a verified executable using an absolute
path. Keep personal paths outside Git; `.dev.vars` is for Worker runtime
configuration, not build-tool paths.

`build.sh` rejects unset, relative, missing, or non-executable paths. It then uses
macOS `sandbox-exec` with `build.sb` to deny network access to the build and its
child processes. Cargo also uses `--offline --locked`, and `--no-opt` skips
wasm-opt. Wrangler deployment runs outside this sandbox. Missing dependencies
or attempted downloads cause the build to fail.

The reviewed helper files were esbuild `0.28.0` and wasm-bindgen `0.2.122` for
macOS ARM64. Their contents matched official archives with matching published
integrity hashes. This does not verify signatures or guarantee vulnerability-free
tools. Review replacements before use. Other platforms require an equivalent
network-isolation mechanism before building.

## Local Development

Local development requires macOS and the three exported build-tool paths
described in [Build network isolation](#build-network-isolation), because
`wrangler dev` runs the configured build command.

Configure a development-only `RELAY_BEARER_TOKEN` in the ignored `.dev.vars` file, and the same token in your shell for curl. Start the local Worker with scheduled-event testing enabled:

```bash
npm exec --no -- wrangler dev --test-scheduled
```

In another terminal, run a scheduled refresh, then read the snapshot. The refresh calls the real Aave APIs and your RPC providers, so it needs the four RPC URLs in `.dev.vars`. Local KV is separate from the deployed namespace.

```bash
curl -i 'http://127.0.0.1:8787/__scheduled'
curl -H "Authorization: Bearer $RELAY_BEARER_TOKEN" http://127.0.0.1:8787/v1/defillama/pools
```

## Checks

```bash
cargo fmt --check
cargo test
cargo llvm-cov --summary-only
cargo audit
cargo deny check
```

Unit tests make no network calls. They cover request construction, response validation, APY conversion and bounds, the provider body cap, authorization, snapshot encoding, and catalogue consistency. Run `cargo llvm-cov` for current coverage figures.

Run `npm run test:runtime` to build the Worker and test routing, authorization,
scheduled refreshes, and cache preservation in Miniflare. This requires the
pinned npm dependencies and the build-tool paths described in
[Build network isolation](#build-network-isolation). Tests use fake providers
and temporary local KV; they do not read `.env` or contact live providers.
The timeout case takes about 35 seconds. Runtime tests are separate from Rust
coverage figures.

## Deploy

This replaces the relay already serving the deployed workflow, under the same Worker name and URL.

Deployment runs the configured sandboxed build first. It requires macOS and
the three exported build-tool paths described in
[Build network isolation](#build-network-isolation).

1. Set the four RPC URLs as Worker secrets. Keep the existing production `RELAY_BEARER_TOKEN` unless you are rotating it. For rotation, update both the Worker secret and CRE's `DEFILLAMA_RELAY_BEARER_TOKEN` outside the `17:50`–`18:00` UTC window, before the next workflow run. The two updates are separate operations; requests fail authentication while their values differ. Verify an authenticated read after both updates.
2. Deploy outside the `17:50`–`18:00` UTC window:

   ```bash
   npm run deploy
   ```

3. The existing KV snapshot is kept until the next successful refresh. Wait for the next scheduled refresh, then verify:

   ```bash
   curl -i \
     -H "Authorization: Bearer $RELAY_BEARER_TOKEN" \
     https://yield-v2-defillama-relay.contractlevel.workers.dev/v1/defillama/pools
   ```

   - `200` with all 12 pools, a `refreshedAt` from that refresh, and plausible APYs.
   - `401` without the token.
   - No `DefiLlama snapshot refresh failed` entries in the Worker logs, and CPU usage within limits.

4. Confirm the following `18:00` rebalance run accepted the snapshot.

## Monitoring

Worker logs are enabled without sampling. In the Cloudflare dashboard, open this Worker's logs and look for `DefiLlama snapshot refresh failed`. A failed refresh keeps the previous snapshot, which the workflow rejects once it is older than 15 minutes. The Rust SDK reports scheduled events as successful even after a logged refresh error, so event success counts do not prove that data refreshed. Logs are stored; no automatic alerts are configured.

## CRE Integration

The Go workflow calls the fixed `defiLlamaRelayURL` in `cre/workflow/internal/offchain/defillama.go`; there is no relay URL field in the workflow JSON config. It sends `Authorization: Bearer <token>` using the CRE secret `DEFILLAMA_RELAY_BEARER_TOKEN`, rejects stale or future snapshots, filters by its configured pool IDs, chains, projects, and symbols, and selects the best pool itself.

Three refreshes a day make at most three KV writes. Nine DON nodes reading at the daily rebalance make about nine KV reads.

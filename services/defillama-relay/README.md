# DefiLlama Relay

Cloudflare Worker that filters live DefiLlama pool data into the compact shape consumed by the Yield v2 CRE workflow.

<!-- @review redeploy cloudflare worker! -->

## Purpose

CRE's production HTTP response quota is `100 KB`. DefiLlama's full `/pools` response is larger than that, so the workflow calls this relay instead. The relay fetches the live DefiLlama response, filters to approved pools, and returns only:

```json
{
  "data": [
    {
      "pool": "d9c395b9-00d0-4426-a6b3-572a6dd68e54",
      "chain": "Arbitrum",
      "project": "compound-v3",
      "symbol": "USDC",
      "apyBase": 6.25
    }
  ]
}
```

## Dependencies

Runtime dependencies are intentionally limited to:

- `worker`
- `serde`
- `serde_json`

Do not add runtime dependencies without an explicit review. In particular, do not add `reqwest`, `tokio`, `axum`, `anyhow`, `thiserror`, config frameworks, logging frameworks, or test helper crates.

Deployment tooling is project-local and pinned:

- `wrangler` `4.84.1`
- `package-lock.json` with npm integrity hashes

Use frozen installs and avoid moving versions:

```bash
npm ci --ignore-scripts
```

Do not use `wrangler@latest` or `npx wrangler`.

## Configuration

`wrangler.toml` contains the non-secret Worker config and is safe to commit while it only contains the Worker name, build command, compatibility date, and public relay vars.

Current vars:

```toml
ALLOWED_POOLS = "aa70268e-4b52-42bf-a116-608b370f9501,..."
DEFILLAMA_UPSTREAM_URL = "https://yields.llama.fi/pools"
```

Allowed DefiLlama pool IDs should map to the exact canonical native USDC markets our adapters can enter. Do not add a pool ID only because its `chain`, `project`, and `symbol` look correct; first verify the underlying token and market metadata.

| Chain     | DefiLlama Chain | Protocol    | Pool ID                                | Canonical USDC                               | Notes                                                                                                                                                                                                                                    |
| --------- | --------------- | ----------- | -------------------------------------- | -------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Ethereum  | Ethereum        | Aave v3     | `aa70268e-4b52-42bf-a116-608b370f9501` | `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48` | Plain market, `poolMeta: null`                                                                                                                                                                                                           |
| Ethereum  | Ethereum        | Compound v3 | `7da72d09-56ca-4ec5-a45f-59114353e487` | `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48` | Plain USDC Comet                                                                                                                                                                                                                         |
| Ethereum  | Ethereum        | Aave v4     | `4ac1a968-68ab-4da8-87e3-8f1e15e3dae2` | `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48` | `poolMeta: "Core"`. Aave v4 lists 3 Ethereum USDC markets (`Core`/`Prime`/`Plus`) with different IDs and APYs; confirmed via `getReserve` that our deployed Spoke's Hub is the `Core` Hub (`0xCca852Bc40e560adC3b1Cc58CA5b55638ce826c9`) |
| Arbitrum  | Arbitrum        | Aave v3     | `d9fa8e14-0447-4207-9ae8-7810199dfa1f` | `0xaf88d065e77c8cC2239327C5EDb3A432268e5831` | Native USDC, not old bridged USDC.e                                                                                                                                                                                                      |
| Arbitrum  | Arbitrum        | Compound v3 | `d9c395b9-00d0-4426-a6b3-572a6dd68e54` | `0xaf88d065e77c8cC2239327C5EDb3A432268e5831` | Native USDC, not old bridged USDC.e                                                                                                                                                                                                      |
| Base      | Base            | Aave v3     | `7e0661bf-8cf3-45e6-9424-31916d4c7b84` | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` | Plain market                                                                                                                                                                                                                             |
| Base      | Base            | Compound v3 | `0c8567f8-ba5b-41ad-80de-00a71895eb19` | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` | Plain USDC Comet                                                                                                                                                                                                                         |
| Avalanche | Avalanche       | Aave v3     | `c4b05318-88af-4536-a834-f5fc8940d2d3` | `0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E` | Plain market                                                                                                                                                                                                                             |
| Avalanche | Avalanche       | Aave v4     | `22323e90-bde5-54a1-8686-53b4205b61b7` | `0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E` | `poolMeta: "Core"`, only Avalanche aave-v4 USDC market listed today; confirmed via `getReserve` that our deployed Spoke's Hub is `0xd07369fAE4A5BB13c9Ce446B052c7867B1AbDf6e`                                                            |
| Optimism  | OP Mainnet      | Aave v3     | `0758c3b8-4ffb-4176-b0a9-f446e367db46` | `0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85` | DefiLlama labels Optimism as `OP Mainnet`                                                                                                                                                                                                |
| Optimism  | OP Mainnet      | Compound v3 | `b828f0cb-853d-4b32-aebb-2e20d7fd70a8` | `0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85` | DefiLlama labels Optimism as `OP Mainnet`                                                                                                                                                                                                |

Set the bearer token as a Worker secret:

```bash
npm exec wrangler -- secret put RELAY_BEARER_TOKEN
```

`RELAY_BEARER_TOKEN` is the access control for this public Worker URL. The token used during local testing or initial setup must be rotated before production use.

Production rules:

- Use a fresh high-entropy production token.
- Store it in Cloudflare only as the Worker secret `RELAY_BEARER_TOKEN`.
- Store the same value in CRE only as the workflow secret `DEFILLAMA_RELAY_BEARER_TOKEN`.
- Do not put the production token in `.env`.
- Do not put the production token in `wrangler.toml`, workflow config JSON, README examples, shell history, or committed docs.
- A local `.env` may hold a development-only token and must remain ignored by git.

## Tooling Setup

Install Rust Worker build tooling if needed:

```bash
cargo install worker-build
```

Install pinned Node tooling from the lockfile:

```bash
npm ci --ignore-scripts
```

Verify Wrangler is the pinned local version:

```bash
npm exec wrangler -- --version
```

Expected:

```text
4.84.1
```

Log in to Cloudflare:

```bash
npm exec wrangler -- login
```

## Local Development

```bash
npm run dev
```

Call the relay:

```bash
curl \
  -H "Authorization: Bearer $RELAY_BEARER_TOKEN" \
  http://127.0.0.1:8787/v1/defillama/pools
```

## Checks

```bash
cargo fmt --check
cargo test
cargo audit
cargo deny check
cargo vet
```

Live DefiLlama tests should be opt-in only:

```bash
RUN_LIVE_DEFILLAMA_TESTS=1 cargo test
```

## Deploy

Generate a fresh production bearer token, then set it as a Cloudflare Worker secret. Do not reuse the local development token.

```bash
npm exec wrangler -- secret put RELAY_BEARER_TOKEN
```

Deploy:

```bash
npm run deploy
```

After deployment, call the Worker URL with the bearer token:

```bash
curl \
  -H "Authorization: Bearer $RELAY_BEARER_TOKEN" \
  https://<worker-url>/v1/defillama/pools
```

Expected response:

```json
{
  "data": [
    {
      "pool": "d9c395b9-00d0-4426-a6b3-572a6dd68e54",
      "chain": "Arbitrum",
      "project": "compound-v3",
      "symbol": "USDC",
      "apyBase": 6.25
    }
  ]
}
```

Also verify an unauthenticated request returns `401`.

## CRE Integration

The CRE workflow should call the deployed Worker URL instead of `https://yields.llama.fi/pools`.

Use CRE secrets/config for:

- `defiLlama.relayUrl` in the workflow config
- `DEFILLAMA_RELAY_BEARER_TOKEN` in CRE secrets

The deployed Worker URL is public. The bearer token is secret. The production token must be uploaded to CRE secrets, not placed in `.env` or committed config.

The workflow should include:

```text
Authorization: Bearer <token>
```

The relay returns all matching pools. The CRE workflow remains responsible for selecting the best pool.

### CRE request concurrency

A CRE HTTP consensus request is executed independently by each DON node. The relay therefore permits up
to eight upstream fetches per Worker isolate. With the current nine-node DON, at most one request receives
`429`, which remains below CRE's four-node consensus failure threshold. The limit also bounds worst-case
upstream response buffering to `8 * 12 MiB = 96 MiB` per isolate.

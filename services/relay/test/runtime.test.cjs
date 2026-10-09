const assert = require("node:assert/strict");
const { readFileSync } = require("node:fs");
const { createRequire } = require("node:module");
const { resolve } = require("node:path");
const test = require("node:test");

// Reuse Wrangler's locked Miniflare dependency.
const requireWrangler = createRequire(require.resolve("wrangler/package.json"));
const { Miniflare, Response } = requireWrangler("miniflare");
const root = resolve(__dirname, "..");
const endpoint = "http://relay.test/v1/defillama/pools";
const token = "runtime-test-only";
const utilizationWord = "1".padStart(64, "0");
const rate = 1_000_000_000;
const rpcOrigins = ["ethereum", "arbitrum", "base", "optimism"]
  .map(chain => `https://${chain}.rpc.test`);
const expectedIds = JSON.parse(readFileSync(
  resolve(root, "../../cre/workflow/config.production.json"), "utf8"
)).defiLlama.poolIds;

function createRuntime(bearer = token) {
  let mode = "success";
  const calls = [];
  const env = {
    RELAY_BEARER_TOKEN: { type: "text", value: bearer },
    POOL_SNAPSHOTS: { type: "kv", id: "runtime-test-kv" },
  };
  for (const origin of rpcOrigins) {
    const chain = new URL(origin).hostname.split(".")[0].toUpperCase();
    env[`${chain}_RPC_URL`] = { type: "text", value: origin };
  }

  // Intercept every provider request; unexpected destinations fail the test.
  async function provider(request) {
    const url = new URL(request.url);
    assert.ok([
      "https://api.v3.aave.com", "https://api.v4.aave.com", ...rpcOrigins,
    ].includes(url.origin), "unexpected outbound provider");
    assert.equal(request.method, "POST");
    const body = await request.json();
    calls.push({ origin: url.origin, pathname: url.pathname, body });

    if (url.origin === "https://api.v3.aave.com") {
      if (mode === "http") return new Response("failure", { status: 500 });
      if (mode === "redirect" && url.pathname !== "/redirect-target") return new Response("", {
        status: 307, headers: { Location: "https://api.v3.aave.com/redirect-target" },
      });
      if (mode === "malformed") return new Response("{");
      if (mode === "timeout") {
        await new Promise(resolve => setTimeout(resolve, 35_000));
      }
      const v = body.variables.request;
      const result = { data: { reserve: {
        market: { address: v.market },
        underlyingToken: { address: v.underlyingToken, chainId: v.chainId },
        supplyInfo: { apy: { value: mode === "oversized" ? "0.05" : "0.04" } },
      } } };
      // Valid data that would change the snapshot if the body cap were missing.
      if (mode === "oversized") result.padding = "x".repeat(65_537);
      return Response.json(result);
    }

    if (url.origin === "https://api.v4.aave.com") {
      const v = body.variables.request.query.reserveInput;
      const assets = {
        1: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
        43114: "0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E",
      };
      return Response.json({ data: { reserve: {
        onChainId: v.onChainId,
        chain: { chainId: v.chainId },
        spoke: { address: v.spoke },
        asset: { underlying: { address: assets[v.chainId] } },
        summary: { supplyApy: { normalized: "5" } },
      } } });
    }

    assert.equal(body.method, "eth_call");
    assert.equal(body.params[1], "latest");
    const utilization = body.params[0].data === "0x7eb71131";
    if (!utilization) {
      assert.equal(body.params[0].data, "0xd955759d" + utilizationWord);
    }
    const word = utilization ? utilizationWord : rate.toString(16).padStart(64, "0");
    return Response.json({
      jsonrpc: "2.0", id: 1,
      result: mode === "truncated" ? "0x0" : "0x" + word,
    });
  }

  const mf = new Miniflare({
    host: "127.0.0.1", port: 0,
    telemetry: { enabled: false },
    workers: [{ config: {
      name: "relay-runtime-test",
      compatibilityDate: "2026-04-28",
      manifest: {
        mainModule: "worker/shim.mjs",
        modules: {
          "worker/shim.mjs": {
            type: "esm",
            contents: readFileSync(resolve(root, "build/worker/shim.mjs"), "utf8"),
          },
          "index.js": {
            type: "esm",
            contents: readFileSync(resolve(root, "build/index.js"), "utf8"),
          },
          "index_bg.wasm": {
            type: "wasm",
            contents: new Uint8Array(readFileSync(resolve(root, "build/index_bg.wasm"))),
          },
        },
      },
      env,
    },
    dev: { outboundService: { type: "fetcher", handler: provider } } }],
  });

  return {
    mf, calls,
    setMode(value) { mode = value; },
    read() {
      return mf.dispatchFetch(endpoint, {
        headers: { Authorization: "Bearer " + token },
      });
    },
    async refresh() {
      const worker = await mf.getWorker();
      const result = await worker.scheduled({ cron: "50 23 * * *" });
      await result.waitUntil;
    },
  };
}

test("routing, refresh and cache preservation", { timeout: 60_000 }, async t => {
  const runtime = createRuntime();
  const { mf, calls } = runtime;
  t.after(() => mf.dispose());

  await t.test("authorization and routing do not fetch upstream", async () => {
    assert.equal((await mf.dispatchFetch(endpoint)).status, 401);
    assert.equal((await mf.dispatchFetch(endpoint, {
      headers: { Authorization: "Bearer wrong" },
    })).status, 401);
    assert.equal((await mf.dispatchFetch("http://relay.test/other")).status, 404);
    assert.equal((await mf.dispatchFetch(endpoint, { method: "POST" })).status, 404);
    assert.equal((await runtime.read()).status, 503);
    assert.equal(calls.length, 0);
  });

  let snapshot, saved;
  await t.test("successful refresh publishes all 12 base APYs", async () => {
    await runtime.refresh();
    const response = await runtime.read();
    assert.equal(response.status, 200);
    assert.match(response.headers.get("Content-Type"), /application\/json/);
    saved = await response.text();
    snapshot = JSON.parse(saved);
    assert.deepEqual(snapshot.data.map(pool => pool.pool).sort(), [...expectedIds].sort());
    assert.equal(calls.length, 16);
    assert.ok(Math.abs(Date.now() / 1000 - snapshot.refreshedAt) < 10);
    const expected = {
      "aave-v3": 4, "aave-v4": 5,
      "compound-v3": 100 * Math.expm1(31_536_000 * Math.log1p(rate / 1e18)),
    };
    for (const pool of snapshot.data) {
      assert.equal(pool.symbol, "USDC");
      assert.ok(Math.abs(pool.apyBase - expected[pool.project]) < 1e-8);
    }
    await runtime.read();
    assert.equal(calls.length, 16, "cached reads must not call providers");
  });

  for (const failure of ["http", "redirect", "oversized", "malformed", "truncated", "timeout"]) {
    await t.test(`${failure} refresh preserves the previous cache`, async () => {
      runtime.setMode(failure);
      await runtime.refresh();
      if (failure === "redirect") {
        assert.ok(
          calls.every(call => call.pathname !== "/redirect-target"),
          "the relay must not follow provider redirects"
        );
      }
      const response = await runtime.read();
      assert.equal(response.status, 200);
      assert.equal(await response.text(), saved);
    });
  }

  await t.test("stale snapshots remain available for CRE to reject", async () => {
    const kv = await mf.getKVNamespace("POOL_SNAPSHOTS");
    await kv.put("pools", JSON.stringify({ ...snapshot, refreshedAt: 1 }));
    const response = await runtime.read();
    assert.equal(response.status, 200);
    assert.equal((await response.json()).refreshedAt, 1);
  });
});

test("an empty bearer token fails closed", { timeout: 15_000 }, async t => {
  const { mf, calls, read } = createRuntime(" ");
  t.after(() => mf.dispose());
  assert.equal((await read()).status, 500);
  assert.equal(calls.length, 0);
});

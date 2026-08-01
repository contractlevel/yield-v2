# Services

All commands below run from the DefiLlama relay project root, `services/defillama-relay/`.

```
cargo fmt --check
cargo test
```

```
cargo deny check
cargo audit
```

### Coverage

Install:

```
cargo install cargo-llvm-cov --locked
```

```
cargo llvm-cov --html
open target/llvm-cov/html/index.html
```

### Simulation

From one terminal:

```
npm run dev
```

From another terminal:

```
source .env

curl \
    -H "Authorization: Bearer $RELAY_BEARER_TOKEN" \
    http://127.0.0.1:8787/v1/defillama/pools
```

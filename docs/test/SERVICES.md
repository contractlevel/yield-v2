# Services

All commands below run from the yield relay project root, `services/relay/`.

For Node, dependency, and build-tool requirements, follow the relay's
[Tooling Setup](../../services/relay/README.md#tooling-setup) and
[Build network isolation](../../services/relay/README.md#build-network-isolation)
instructions before running builds or runtime tests.

```
cargo fmt --check
cargo test
```

```
cargo deny check
cargo audit
```

### Runtime tests

```sh
npm run test:runtime
```

These tests build the Worker and exercise its deployment entrypoint in Miniflare,
using fake providers and temporary local KV. They do not read `.env` or call live
providers. The timeout case takes about 35 seconds.

### Coverage

Use an approved installation of `cargo-llvm-cov`. Review its version and obtain
installation approval before adding or updating the tool.

```
cargo llvm-cov --html
open target/llvm-cov/html/index.html
```

These figures cover the Rust tests; Miniflare runtime tests are not included.

### Simulation

Follow the relay's [Local Development](../../services/relay/README.md#local-development)
instructions to configure development secrets, enable scheduled-event testing,
trigger a refresh, and read the cached snapshot.

Unlike runtime tests, this simulation calls live providers. Its local KV is
separate from production KV.

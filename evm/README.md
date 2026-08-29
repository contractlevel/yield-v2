# Yieldcoin v2 EVM

Yieldcoin v2 is a multichain, epoch-based yield vault. Users deposit into a `ParentVault` and
receive `YieldcoinShare` tokens after epoch settlement. Capital is deployed through protocol
adapters on the parent chain or through CCIP-connected `ChildVault` deployments. Chainlink CRE
coordinates epoch settlement and rebalancing through `WorkflowRouter` contracts.

The contracts are under active development and have no live production deployments.

## Quick start

Install [Foundry](https://book.getfoundry.sh/getting-started/installation), then initialize the
repository dependencies from the repository root:

```bash
git submodule update --init --recursive
cd evm
```

Build and run the test suite:

```bash
forge build --build-info
forge test
```

Generate and inspect the coverage report:

```bash
forge coverage --report lcov
genhtml lcov.info -o coverage
open coverage/index.html
```

See [EVM Testing](../docs/test/EVM.md) for invariant fuzzing, static analysis, Halmos, and Certora
commands. Some integration and fork tests require RPC environment variables configured in
[`foundry.toml`](./foundry.toml).

## Architecture

The main production components are:

- `ParentVault` — the user-facing vault and canonical share-accounting contract.
- `ChildVault` — deploys capital into strategies on a remote chain.
- `YieldcoinShare` — the upgradeable and pausable ERC-20 share token.
- `WorkflowRouter` — validates and forwards allowlisted CRE workflow reports to a vault.
- `AdapterRegistry` — maps protocol identifiers to vault-bound strategy adapters.
- Protocol adapters — integrate Aave V3, Aave V4, and Compound V3.

Production contracts are under [`src/`](./src), deployment and configuration scripts under
[`script/`](./script), and Foundry tests under [`test/`](./test).

For the complete component diagram and lifecycle, see
[Architecture](../docs/protocol/ARCHITECTURE.md). The canonical epoch, rebalance, CCIP, and recovery
flows are documented in [Execution Paths](../docs/protocol/PATHS.md).

## Security and audit context

Auditors and security reviewers should read these documents in order:

1. [Architecture](../docs/protocol/ARCHITECTURE.md) — components, relationships, and lifecycle.
2. [Execution Paths](../docs/protocol/PATHS.md) — canonical success, failure, and recovery flows.
3. [Threat Model](../docs/security/THREAT_MODEL.md) — assets, trust boundaries, and threat surfaces.
4. [Access-Control Matrix](../docs/security/ACCESS_CONTROL_MATRIX.md) — roles and privileged entry
   points.
5. [Invariants](../docs/security/INVARIANTS.md) — safety properties and verification status.
6. [Known Issues](../docs/security/KNOWN_ISSUES.md) — accepted risks and revisit conditions.
7. [Design Decisions](../docs/protocol/DECISIONS.md) — rationale and intentional tradeoffs.

The broader documentation index is at [`docs/README.md`](../docs/README.md). Deployment,
configuration, operations, incident-response, and upgrade procedures are under
[`docs/operator/`](../docs/operator/).

Report suspected vulnerabilities according to the [security policy](../docs/SECURITY.md).

## Recovery

Recovery depends on where an operation executes. Synchronous `ParentVault` strategy interactions
and parent-originated CCIP sends revert atomically on failure and do not store recovery state.
Failures after an asynchronous operation reaches a `ChildVault` store typed recovery state where
possible. `ParentVault` stores `REBALANCE_DEPOSIT` recovery only when an inbound cross-chain
rebalance has already delivered assets to `ParentVault` and depositing them into the new local
strategy fails.

See [Recovery](../docs/concepts/RECOVERY.md) for the recovery model and
[Execution Paths](../docs/protocol/PATHS.md) for each flow.

## WorkflowRouter-called selectors

`WorkflowRouter` can forward the following vault entry points. Their selectors are listed
explicitly because each configured selector must route to exactly one intended operation.

| Function signature | Selector |
| --- | --- |
| `initiateRebalance(uint256,(bytes32,uint64))` | `0x3ba1b347` |
| `completeRebalance(uint256)` | `0x58b275bc` |
| `closeEpoch(uint256,uint256)` | `0xf5591e6e` |
| `completeEpochDeposit(uint256,uint256)` | `0x9f2ba740` |
| `executeRebalance(uint256,(bytes32,uint64))` | `0x1aa137ec` |
| `executeEpochWithdraw(uint256,uint256)` | `0x1c12f962` |

Reproduce any value with `cast sig '<function-signature>'`. Workflow configuration and selector
allowlisting are described in [Workflow](../docs/protocol/WORKFLOW.md).

## Proxy storage namespaces

The upgradeable contracts use ERC-7201 namespaced storage:

| Namespace | Storage location |
| --- | --- |
| `yieldcoin.storage.BaseVault` | `0x99afdd01627a14a05f9b616b4e511b7ffe10b226156d7b6f476c4380e58f9d00` |
| `yieldcoin.storage.ParentVault` | `0x4d89b729d7d5f9a6740a79abcbedc524fd1c9bd2e1f192f6caeffd6a1cf4ea00` |
| `yieldcoin.storage.ChildVault` | `0x78e4dbdeeaf798c2dd37013d97b7b9a2111b1f613652054109dec720ccf6f400` |
| `yieldcoin.storage.YieldcoinShare` | `0x41e0a3d2fe098fdb6914a7f5b701ff6b1c613a556bd3607f71a6be16b1a71800` |

Reproduce the locations with:

```bash
cast index-erc7201 yieldcoin.storage.BaseVault
cast index-erc7201 yieldcoin.storage.ParentVault
cast index-erc7201 yieldcoin.storage.ChildVault
cast index-erc7201 yieldcoin.storage.YieldcoinShare
```

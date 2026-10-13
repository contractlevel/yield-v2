# Audit History

The implementation in `cre/` has not been audited.

## September 2026 — Zealynx

| Item | Reference |
| --- | --- |
| Report | [Yieldcoin v2 Smart Contract Audit — 15 September 2026](../../audits/2026-09-zealynx-yieldcoin-v2.pdf) |
| Auditor | Zealynx — Carlos Vendrell (Bloqarl) |
| Scope | Solidity sources under `evm/src/`. CRE, off-chain services, deployment scripts, tests, and third-party dependencies were out of scope. |
| Initial audit commit | [`a08ecdf`](https://github.com/contractlevel/yield-v2/commit/a08ecdfdb5aa603366ac9a342791cc532052ee52) |
| Final audit remediation commit | [`4864ee0`](https://github.com/contractlevel/yield-v2/commit/4864ee051275fd03e8344c0386a1876caf45b3cf) |

The report includes a mitigation review: 11 findings (1 Critical, 1 High, 6 Medium,
and 3 Low), with 8 fixed, 2 mitigated with documented residuals, and 1 accepted as
a known issue. See the report for individual findings and [Known Issues](./KNOWN_ISSUES.md)
for accepted limitations.

## Unaudited Allowlist Delta

The deposit allowlist was added after the final audit remediation commit and is
not covered by the Zealynx audit:

- [`2c78cfc`](https://github.com/contractlevel/yield-v2/commit/2c78cfc731db9da0d640c47aa76c8374f5c99263) adds the allowlist module, storage, operator role, and ParentVault integration.
- [`b63a093`](https://github.com/contractlevel/yield-v2/commit/b63a09321a8e80328cfa8b35391b05b6e3969247) adds the interface and formats the module.
- [`de5f6e6`](https://github.com/contractlevel/yield-v2/commit/de5f6e6c8a4037c05af63fecc5ddc4000b7a0e5b) removes allowlist checks from withdrawals, leaving enforcement on deposits.
- [`1206dd2`](https://github.com/contractlevel/yield-v2/commit/1206dd2ae9329780cebe112eb0c54e4fdf60e634) adds tests, formal verification, and documentation.

Formal verification is recorded in [Allowlist invariants and coverage](./INVARIANTS.md#allowlist),
with the [Certora module specification](../../evm/certora/spec/modules/Allowlist.spec),
[configuration](../../evm/certora/conf/modules/Allowlist.conf), and
[ParentVault rules](../../evm/certora/spec/vaults/ParentVault.rules.spec).
The module and touched ParentVault rules passed.

# YieldcoinShare

[`YieldcoinShare`](../../evm/src/token/YieldcoinShare.sol) is the compliance-ready share token for Yieldcoin v2. It is a [Chainlink ACE `ComplianceTokenERC3643`](https://github.com/smartcontractkit/chainlink-ace/blob/main/packages/tokens/erc-3643/src/ComplianceTokenERC3643.sol), and its policy checks are part of the token's security model.

[`ParentVault`](../../evm/src/vaults/ParentVault.sol) is the only protocol component intended to mint and burn shares for normal user accounting. Deposits do not mint shares immediately; users claim shares after an epoch closes. Withdraw intents escrow shares in `ParentVault`, and those shares are burned when the user claims the settled underlying asset. See: [`USER_GUIDE`](../USER_GUIDE.md).

User-facing token actions are ACE-gated. The deployment wires KYC policy checks for transfer and approval flows. Depending on the selector, the caller and relevant counterparty addresses must be KYC-approved. For example, transfers check the caller and recipient, while `transferFrom` checks the caller, source, and recipient. `decreaseAllowance` checks only the caller so a user can reduce approval exposure even if a spender later loses KYC status.

Administrative token functions also use ACE policy checks. The [deploy script](../../evm/script/deploy/DeployParent.s.sol) configures [`RoleBasedAccessControlPolicy`](https://github.com/smartcontractkit/chainlink-ace/blob/main/packages/policy-management/src/policies/RoleBasedAccessControlPolicy.sol) permissions for roles such as `MINTER_ROLE`, `BURNER_ROLE`, `CONFIG_OPERATOR_ROLE`, `POLICY_ENGINE_MANAGER_ROLE`, `PAUSER_ROLE`, `UNPAUSER_ROLE`, and `COMPLIANCE_OPERATOR_ROLE`.

Compliance operations include freeze, unfreeze, address freeze, and forced transfer behavior inherited through the compliance token stack and gated through ACE RBAC. These powers are intentionally privileged and are part of the protocol's compliance trust boundary.

`getCCIPAdmin()` returns the stored CCIP admin configured by `setCCIPAdmin`. This is separate from the token's `owner()`. The token's `owner()` is used for UUPS upgrade authorization, and `renounceOwnership()` is disabled to avoid permanently removing upgrade capability.

For role authority, see [`ACCESS_CONTROL_MATRIX`](../security/ACCESS_CONTROL_MATRIX.md#yieldcoinshare). For accepted role-trust risks, see [`KNOWN_ISSUES`](../security/KNOWN_ISSUES.md#ki-001--centralized-trust-in-privileged-operatoradmin-roles).

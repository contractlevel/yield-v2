# Compliance

// @review - expand onchain compliance procedures for this protocol.

## KYC and Identity Provider

Yieldcoin v2 integrates onchain ACE policy checks with an offchain KYC or compliance process.

The commercial operator can use a third-party KYC provider, such as Sumsub or another approved identity provider. Alternatively, the commercial operator can run its own offchain compliance infrastructure and facilitate the required onchain writes itself.

In either model, the offchain process performs the real-world user verification. After a user completes KYC, an authorized provider or operator-controlled writer records the user's onchain identity and credential status:

- `IdentityRegistry.registerIdentity(ccid, account, context)` maps the user's address to a `bytes32` CCID.
- `CredentialRegistry.registerCredential(ccid, credentialTypeId, expiresAt, credentialData, context)` records that the CCID has the required credential, such as `common.kyc`.

The protocol's ACE policies then check that onchain confirmation when a user calls protected `ParentVault` functions or uses policy-gated Yieldcoin share actions.

The KYC or compliance process should not publish user PII onchain. The identity provider or operator-controlled compliance service computes the user's CCID offchain at its own discretion, then writes the address-to-CCID mapping and the KYC credential for that CCID onchain. Yieldcoin's current KYC flow does not use `credentialData`; if it is used later for extra metadata such as jurisdiction, it should contain only non-sensitive data, a hash, or a reference rather than raw personal data.

## Notes

`YieldcoinShare.mint` does not KYC-check the recipient directly because `ParentVault` is the only expected caller of share minting, and the user-facing `ParentVault` claim path is already ACE-gated.

# Testnets

## Wallet funding

Test wallet should be funded with:

- native
- link
- usdc (on Parent)

https://sepolia.arbiscan.io/address/0x7664c538c80870824738a8adccd92aca244d7e69

https://sepolia.basescan.org/address/0x7664C538C80870824738A8ADCcd92AcA244D7e69

https://sepolia.etherscan.io/address/0x7664C538C80870824738A8ADCcd92AcA244D7e69

https://sepolia-optimism.etherscan.io/address/0x7664C538C80870824738A8ADCcd92AcA244D7e69

https://testnet.snowtrace.io/address/0x7664C538C80870824738A8ADCcd92AcA244D7e69

---

Mock protocols should be deployed on each chain for each supported pool.

aaveV3:

- eth
- arb
- base
- op
- avax

compoundV3:

- arb
- base
- op
- eth

aaveV4:

- eth
- avax

### Deploy Mock Protocols:

```
forge script script/deploy/DeployTestnetProtocols.s.sol:DeployTestnetProtocols \
    --rpc-url optimism_sepolia \
    --account testnet-deployer \
    --sender 0x7664C538C80870824738A8ADCcd92AcA244D7e69 \
    --broadcast \
    --verify \
    --verifier etherscan \
    --retries 15 \
    --delay 10 \
    --slow \
    -vvvv
```

```
forge script script/deploy/DeployTestnetProtocols.s.sol:DeployTestnetProtocols \
    --rpc-url avalanche_fuji \
    --account testnet-deployer \
    --sender 0x7664C538C80870824738A8ADCcd92AcA244D7e69 \
    --broadcast \
    --verify \
    --verifier etherscan \
    --verifier-url "https://api.routescan.io/v2/network/testnet/evm/43113/etherscan/api" \
    --retries 15 \
    --delay 10 \
    --slow \
    -vvvv
```

### Deploy Parent infra:

```
forge script script/deploy/DeployParent.s.sol:DeployParent \
    --rpc-url arbitrum_sepolia \
    --account testnet-deployer \
    --sender 0x7664C538C80870824738A8ADCcd92AcA244D7e69 \
    --broadcast \
    --verify \
    --verifier etherscan \
    --retries 15 \
    --delay 10 \
    --slow \
    -vvvv
```

### Deploy Child infra:

```
forge script script/deploy/DeployChild.s.sol:DeployChild \
    --rpc-url arbitrum_sepolia \
    --account testnet-deployer \
    --sender 0x7664C538C80870824738A8ADCcd92AcA244D7e69 \
    --broadcast \
    --verify \
    --verifier etherscan \
    --retries 15 \
    --delay 10 \
    --slow \
    -vvvv
```

## Parent Deployments

| Contract | Address |
| --- | --- |
| `BaseVaultCcipLib` | `0x13cdee9be66127fa1c3922dd12f16b87d6d3da71` |
| `ParentVaultUserEpochLib` | `0xf95d1b804a837eab54041abff4d642366dc20ea1` |
| `ParentVaultRebalanceLib` | `0x34db5430fadca96a80be89d732ae1422c577aff1` |
| `ParentVaultEpochLib` | `0x9688f8ace6d139e8ed33a146ec8714c751121054` |
| `ParentVaultConfigLib` | `0x5641d1005678526605b17b4fe6d7e20a30420224` |
| `ParentVaultCcipLib` | `0x0be4982561e7d1c9936cff25e43e6c805466d98b` |
| `BaseVaultStrategyLib` | `0x4ab7794139fb422813b97e1e4a33a7947666a323` |
| `BaseVaultConfigLib` | `0x07d45439566c417491760b0698683ae42739d108` |
| `PolicyEngine` implementation | `0x8383a982dc0b844ca9200fbedeebbe50ae4bb157` |
| `PolicyEngine` proxy | `0x079a90b7761ff10f455bc2188392b2ae765f8dad` |
| `IdentityRegistry` implementation | `0x412749be129b2b6ba778f732adb6b69617bd7a13` |
| `IdentityRegistry` proxy | `0x971e7d69e039cc013145ceaa6aacc9dbe55deba6` |
| `CredentialRegistry` implementation | `0xe6d10460bf3fc0eeca03d73d393dafc867ad0836` |
| `CredentialRegistry` proxy | `0xb2ac18061d6996202227b211a0c7915b010413c2` |
| `AdapterRegistry` | `0x809a7bf022841e3bcda0d3cf64b780aabf898c64` |
| `YieldcoinShare` implementation | `0x171dbab26fdd04ba215e0d6338d1270f6d20d838` |
| `YieldcoinShare` proxy | `0x811356c12f222c246fca7ac73f740d8accf03e0a` |
| `ParentVault` implementation | `0x58fbfdf85c4463c8d956a4fc0252a75c320b42fb` |
| `ParentVault` proxy | `0x584099c5200b8a63536230017f718797026e5915` |
| `AaveV3Adapter` | `0xc8802711eb8c9defbcb1ee626bcb54b981297d19` |
| `CompoundV3Adapter` | `0x175b945fc2520c20f5e2cfee323f79bf29205913` |
| `WorkflowRouter` | `0x2f0aac54238f1523fe23e54ab273e9ff5320b51c` |
| `TerminalAllowPolicy` implementation | `0xc0e11e92188743e37fed15f0c998ed1b9533fe01` |
| `TerminalAllowPolicy` proxy | `0x96b4c7e3419f07bc2baa0b5a4151d220984028a9` |
| `YieldcoinShareFrozenAccountPolicy` implementation | `0x512efe701404a637ccaca933028d0afe647cc0c4` |
| `YieldcoinShareFrozenAccountPolicy` proxy | `0xcd6f007979bfb9f1ea9a9df432a298d0469861d3` |
| `CredentialRegistryIdentityValidatorPolicy` implementation | `0x66738d30269f1e88a762f421995feebe8e617d52` |
| `CredentialRegistryIdentityValidatorPolicy` proxy | `0x07c4e5242206de2da117635c31b84884522f46fb` |
| `SenderExtractor` | `0x921fe4ed6a98f800199b11569673a5230b522f9c` |
| `OnlyAuthorizedSenderPolicy` implementation | `0x4577bdfb0fd75664586f03db266413a7609b7baa` |
| `OnlyAuthorizedSenderPolicy` proxy | `0x5f8191e9fe6b4164930cdf92f6fe824ae35602e0` |
| `CredentialRegistryAccountListValidatorPolicy` implementation | `0xcc6535ccb21f9ed8a0e593dddcd1a6fac1d6474b` |
| `CredentialRegistryAccountListValidatorPolicy` proxy | `0x63f8cfc8a7202e2dc1f46b23d2043c7889796b3a` |
| `YieldcoinShareKycExtractor` | `0x13aa0a08d5d867c60017c3b2f78f6c38d1e509e4` |
| `RoleBasedAccessControlPolicy` implementation | `0x0f9469f3831406c34e8a563c095392f79a7b8439` |
| `RoleBasedAccessControlPolicy` proxy | `0x8dd0fbab082d591edb0666390066b5161842bb0c` |

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

_Note: rpc-url needs to be changed to specific chain. verifier-url should be added if using routescan for avalanche explorer._

```
forge script script/deploy/DeployChild.s.sol:DeployChild \
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
forge script script/deploy/DeployChild.s.sol:DeployChild \
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

### Set Crosschain Vaults

Run once on each testnet after all five vault proxies have been deployed. Change `--rpc-url` to
`arbitrum_sepolia`, `ethereum_sepolia`, `base_sepolia`, `optimism_sepolia`, and `avalanche_fuji` respectively.

```bash
forge script script/interactions/SetCrosschainVaults.s.sol:SetCrosschainVaults \
    --rpc-url avalanche_fuji \
    --account testnet-deployer \
    --sender 0x7664C538C80870824738A8ADCcd92AcA244D7e69 \
    --broadcast \
    -vvvv
```

Grant the burner `CONFIG_OPERATOR_ROLE` on the active chain's vault proxy if required:

```bash
forge script script/interactions/GrantConfigOperator.s.sol:GrantConfigOperator \
    --rpc-url optimism_sepolia \
    --account testnet-deployer \
    --sender 0x7664C538C80870824738A8ADCcd92AcA244D7e69 \
    --broadcast \
    -vvvv
```

Fund each vault proxy with 5 LINK. Run once on each testnet, changing `--rpc-url` for each chain:

```bash
forge script script/interactions/FundVaultLink.s.sol:FundVaultLink \
    --rpc-url avalanche_fuji \
    --account testnet-deployer \
    --sender 0x7664C538C80870824738A8ADCcd92AcA244D7e69 \
    --broadcast \
    -vvvv
```

## Parent Deployments (Arbitrum Sepolia)

| Contract                                                      | Address                                      |
| ------------------------------------------------------------- | -------------------------------------------- |
| `BaseVaultCcipLib`                                            | [`0x13cdee9be66127fa1c3922dd12f16b87d6d3da71`](https://sepolia.arbiscan.io/address/0x13cdee9be66127fa1c3922dd12f16b87d6d3da71) |
| `ParentVaultUserEpochLib`                                     | [`0xf95d1b804a837eab54041abff4d642366dc20ea1`](https://sepolia.arbiscan.io/address/0xf95d1b804a837eab54041abff4d642366dc20ea1) |
| `ParentVaultRebalanceLib`                                     | [`0x34db5430fadca96a80be89d732ae1422c577aff1`](https://sepolia.arbiscan.io/address/0x34db5430fadca96a80be89d732ae1422c577aff1) |
| `ParentVaultEpochLib`                                         | [`0x9688f8ace6d139e8ed33a146ec8714c751121054`](https://sepolia.arbiscan.io/address/0x9688f8ace6d139e8ed33a146ec8714c751121054) |
| `ParentVaultConfigLib`                                        | [`0x5641d1005678526605b17b4fe6d7e20a30420224`](https://sepolia.arbiscan.io/address/0x5641d1005678526605b17b4fe6d7e20a30420224) |
| `ParentVaultCcipLib`                                          | [`0x0be4982561e7d1c9936cff25e43e6c805466d98b`](https://sepolia.arbiscan.io/address/0x0be4982561e7d1c9936cff25e43e6c805466d98b) |
| `BaseVaultStrategyLib`                                        | [`0x4ab7794139fb422813b97e1e4a33a7947666a323`](https://sepolia.arbiscan.io/address/0x4ab7794139fb422813b97e1e4a33a7947666a323) |
| `BaseVaultConfigLib`                                          | [`0x07d45439566c417491760b0698683ae42739d108`](https://sepolia.arbiscan.io/address/0x07d45439566c417491760b0698683ae42739d108) |
| `PolicyEngine` implementation                                 | [`0x8383a982dc0b844ca9200fbedeebbe50ae4bb157`](https://sepolia.arbiscan.io/address/0x8383a982dc0b844ca9200fbedeebbe50ae4bb157) |
| `PolicyEngine` proxy                                          | [`0x079a90b7761ff10f455bc2188392b2ae765f8dad`](https://sepolia.arbiscan.io/address/0x079a90b7761ff10f455bc2188392b2ae765f8dad) |
| `IdentityRegistry` implementation                             | [`0x412749be129b2b6ba778f732adb6b69617bd7a13`](https://sepolia.arbiscan.io/address/0x412749be129b2b6ba778f732adb6b69617bd7a13) |
| `IdentityRegistry` proxy                                      | [`0x971e7d69e039cc013145ceaa6aacc9dbe55deba6`](https://sepolia.arbiscan.io/address/0x971e7d69e039cc013145ceaa6aacc9dbe55deba6) |
| `CredentialRegistry` implementation                           | [`0xe6d10460bf3fc0eeca03d73d393dafc867ad0836`](https://sepolia.arbiscan.io/address/0xe6d10460bf3fc0eeca03d73d393dafc867ad0836) |
| `CredentialRegistry` proxy                                    | [`0xb2ac18061d6996202227b211a0c7915b010413c2`](https://sepolia.arbiscan.io/address/0xb2ac18061d6996202227b211a0c7915b010413c2) |
| `AdapterRegistry`                                             | [`0x809a7bf022841e3bcda0d3cf64b780aabf898c64`](https://sepolia.arbiscan.io/address/0x809a7bf022841e3bcda0d3cf64b780aabf898c64) |
| `YieldcoinShare` implementation                               | [`0x171dbab26fdd04ba215e0d6338d1270f6d20d838`](https://sepolia.arbiscan.io/address/0x171dbab26fdd04ba215e0d6338d1270f6d20d838) |
| `YieldcoinShare` proxy                                        | [`0x811356c12f222c246fca7ac73f740d8accf03e0a`](https://sepolia.arbiscan.io/address/0x811356c12f222c246fca7ac73f740d8accf03e0a) |
| `ParentVault` implementation                                  | [`0x58fbfdf85c4463c8d956a4fc0252a75c320b42fb`](https://sepolia.arbiscan.io/address/0x58fbfdf85c4463c8d956a4fc0252a75c320b42fb) |
| `ParentVault` proxy                                           | [`0x584099c5200b8a63536230017f718797026e5915`](https://sepolia.arbiscan.io/address/0x584099c5200b8a63536230017f718797026e5915) |
| `AaveV3Adapter`                                               | [`0xc8802711eb8c9defbcb1ee626bcb54b981297d19`](https://sepolia.arbiscan.io/address/0xc8802711eb8c9defbcb1ee626bcb54b981297d19) |
| `CompoundV3Adapter`                                           | [`0x175b945fc2520c20f5e2cfee323f79bf29205913`](https://sepolia.arbiscan.io/address/0x175b945fc2520c20f5e2cfee323f79bf29205913) |
| `WorkflowRouter`                                              | [`0x2f0aac54238f1523fe23e54ab273e9ff5320b51c`](https://sepolia.arbiscan.io/address/0x2f0aac54238f1523fe23e54ab273e9ff5320b51c) |
| `TerminalAllowPolicy` implementation                          | [`0xc0e11e92188743e37fed15f0c998ed1b9533fe01`](https://sepolia.arbiscan.io/address/0xc0e11e92188743e37fed15f0c998ed1b9533fe01) |
| `TerminalAllowPolicy` proxy                                   | [`0x96b4c7e3419f07bc2baa0b5a4151d220984028a9`](https://sepolia.arbiscan.io/address/0x96b4c7e3419f07bc2baa0b5a4151d220984028a9) |
| `YieldcoinShareFrozenAccountPolicy` implementation            | [`0x512efe701404a637ccaca933028d0afe647cc0c4`](https://sepolia.arbiscan.io/address/0x512efe701404a637ccaca933028d0afe647cc0c4) |
| `YieldcoinShareFrozenAccountPolicy` proxy                     | [`0xcd6f007979bfb9f1ea9a9df432a298d0469861d3`](https://sepolia.arbiscan.io/address/0xcd6f007979bfb9f1ea9a9df432a298d0469861d3) |
| `CredentialRegistryIdentityValidatorPolicy` implementation    | [`0x66738d30269f1e88a762f421995feebe8e617d52`](https://sepolia.arbiscan.io/address/0x66738d30269f1e88a762f421995feebe8e617d52) |
| `CredentialRegistryIdentityValidatorPolicy` proxy             | [`0x07c4e5242206de2da117635c31b84884522f46fb`](https://sepolia.arbiscan.io/address/0x07c4e5242206de2da117635c31b84884522f46fb) |
| `SenderExtractor`                                             | [`0x921fe4ed6a98f800199b11569673a5230b522f9c`](https://sepolia.arbiscan.io/address/0x921fe4ed6a98f800199b11569673a5230b522f9c) |
| `OnlyAuthorizedSenderPolicy` implementation                   | [`0x4577bdfb0fd75664586f03db266413a7609b7baa`](https://sepolia.arbiscan.io/address/0x4577bdfb0fd75664586f03db266413a7609b7baa) |
| `OnlyAuthorizedSenderPolicy` proxy                            | [`0x5f8191e9fe6b4164930cdf92f6fe824ae35602e0`](https://sepolia.arbiscan.io/address/0x5f8191e9fe6b4164930cdf92f6fe824ae35602e0) |
| `CredentialRegistryAccountListValidatorPolicy` implementation | [`0xcc6535ccb21f9ed8a0e593dddcd1a6fac1d6474b`](https://sepolia.arbiscan.io/address/0xcc6535ccb21f9ed8a0e593dddcd1a6fac1d6474b) |
| `CredentialRegistryAccountListValidatorPolicy` proxy          | [`0x63f8cfc8a7202e2dc1f46b23d2043c7889796b3a`](https://sepolia.arbiscan.io/address/0x63f8cfc8a7202e2dc1f46b23d2043c7889796b3a) |
| `YieldcoinShareKycExtractor`                                  | [`0x13aa0a08d5d867c60017c3b2f78f6c38d1e509e4`](https://sepolia.arbiscan.io/address/0x13aa0a08d5d867c60017c3b2f78f6c38d1e509e4) |
| `RoleBasedAccessControlPolicy` implementation                 | [`0x0f9469f3831406c34e8a563c095392f79a7b8439`](https://sepolia.arbiscan.io/address/0x0f9469f3831406c34e8a563c095392f79a7b8439) |
| `RoleBasedAccessControlPolicy` proxy                          | [`0x8dd0fbab082d591edb0666390066b5161842bb0c`](https://sepolia.arbiscan.io/address/0x8dd0fbab082d591edb0666390066b5161842bb0c) |

## Child Deployments

### Ethereum Sepolia

| Contract                    | Address                                      |
| --------------------------- | -------------------------------------------- |
| `BaseVaultStrategyLib`      | [`0x4ab7794139fb422813b97e1e4a33a7947666a323`](https://sepolia.etherscan.io/address/0x4ab7794139fb422813b97e1e4a33a7947666a323) |
| `AdapterRegistry`           | [`0x971e7d69e039cc013145ceaa6aacc9dbe55deba6`](https://sepolia.etherscan.io/address/0x971e7d69e039cc013145ceaa6aacc9dbe55deba6) |
| `ChildVault` implementation | [`0xb2ac18061d6996202227b211a0c7915b010413c2`](https://sepolia.etherscan.io/address/0xb2ac18061d6996202227b211a0c7915b010413c2) |
| `ChildVault` proxy          | [`0x809a7bf022841e3bcda0d3cf64b780aabf898c64`](https://sepolia.etherscan.io/address/0x809a7bf022841e3bcda0d3cf64b780aabf898c64) |
| `AaveV3Adapter`             | [`0xf02c4a15eeffc6fbbde26a2dddb52b57861e2e38`](https://sepolia.etherscan.io/address/0xf02c4a15eeffc6fbbde26a2dddb52b57861e2e38) |
| `AaveV4Adapter`             | [`0x811356c12f222c246fca7ac73f740d8accf03e0a`](https://sepolia.etherscan.io/address/0x811356c12f222c246fca7ac73f740d8accf03e0a) |
| `CompoundV3Adapter`         | [`0x584099c5200b8a63536230017f718797026e5915`](https://sepolia.etherscan.io/address/0x584099c5200b8a63536230017f718797026e5915) |
| `WorkflowRouter`            | [`0xe7a5a96775f75baaaf49e5dc009e3264779e2f9c`](https://sepolia.etherscan.io/address/0xe7a5a96775f75baaaf49e5dc009e3264779e2f9c) |

### Base Sepolia

| Contract                    | Address                                      |
| --------------------------- | -------------------------------------------- |
| `BaseVaultStrategyLib`      | [`0x4ab7794139fb422813b97e1e4a33a7947666a323`](https://sepolia.basescan.org/address/0x4ab7794139fb422813b97e1e4a33a7947666a323) |
| `AdapterRegistry`           | [`0x4f162bc4acc9e5847fcbef84cebaf45087430c36`](https://sepolia.basescan.org/address/0x4f162bc4acc9e5847fcbef84cebaf45087430c36) |
| `ChildVault` implementation | [`0x781d5338eb60ed6c0129f28ce56872cc239ac3c2`](https://sepolia.basescan.org/address/0x781d5338eb60ed6c0129f28ce56872cc239ac3c2) |
| `ChildVault` proxy          | [`0x221736594f42a10ce61a0f66dc4e6b04786ff8a3`](https://sepolia.basescan.org/address/0x221736594f42a10ce61a0f66dc4e6b04786ff8a3) |
| `AaveV3Adapter`             | [`0xdc0239d860dc5b3356e9ab260b56cf69e9cfb92a`](https://sepolia.basescan.org/address/0xdc0239d860dc5b3356e9ab260b56cf69e9cfb92a) |
| `CompoundV3Adapter`         | [`0x5d1079dae90f23bbe64faf3adc08554669d9f938`](https://sepolia.basescan.org/address/0x5d1079dae90f23bbe64faf3adc08554669d9f938) |
| `WorkflowRouter`            | [`0x971e7d69e039cc013145ceaa6aacc9dbe55deba6`](https://sepolia.basescan.org/address/0x971e7d69e039cc013145ceaa6aacc9dbe55deba6) |

### Optimism Sepolia

| Contract                    | Address                                      |
| --------------------------- | -------------------------------------------- |
| `BaseVaultStrategyLib`      | [`0x4ab7794139fb422813b97e1e4a33a7947666a323`](https://sepolia-optimism.etherscan.io/address/0x4ab7794139fb422813b97e1e4a33a7947666a323) |
| `AdapterRegistry`           | [`0x4f162bc4acc9e5847fcbef84cebaf45087430c36`](https://sepolia-optimism.etherscan.io/address/0x4f162bc4acc9e5847fcbef84cebaf45087430c36) |
| `ChildVault` implementation | [`0x781d5338eb60ed6c0129f28ce56872cc239ac3c2`](https://sepolia-optimism.etherscan.io/address/0x781d5338eb60ed6c0129f28ce56872cc239ac3c2) |
| `ChildVault` proxy          | [`0x221736594f42a10ce61a0f66dc4e6b04786ff8a3`](https://sepolia-optimism.etherscan.io/address/0x221736594f42a10ce61a0f66dc4e6b04786ff8a3) |
| `AaveV3Adapter`             | [`0xdc0239d860dc5b3356e9ab260b56cf69e9cfb92a`](https://sepolia-optimism.etherscan.io/address/0xdc0239d860dc5b3356e9ab260b56cf69e9cfb92a) |
| `CompoundV3Adapter`         | [`0x5d1079dae90f23bbe64faf3adc08554669d9f938`](https://sepolia-optimism.etherscan.io/address/0x5d1079dae90f23bbe64faf3adc08554669d9f938) |
| `WorkflowRouter`            | [`0x971e7d69e039cc013145ceaa6aacc9dbe55deba6`](https://sepolia-optimism.etherscan.io/address/0x971e7d69e039cc013145ceaa6aacc9dbe55deba6) |

### Avalanche Fuji

| Contract                    | Address                                      |
| --------------------------- | -------------------------------------------- |
| `BaseVaultStrategyLib`      | [`0x4ab7794139fb422813b97e1e4a33a7947666a323`](https://testnet.snowtrace.io/address/0x4ab7794139fb422813b97e1e4a33a7947666a323) |
| `AdapterRegistry`           | [`0xd9e76077c65fe2ca25ced7432bf206c19507c553`](https://testnet.snowtrace.io/address/0xd9e76077c65fe2ca25ced7432bf206c19507c553) |
| `ChildVault` implementation | [`0x26254c3c69b63e490c7dd88662549b12f8884e08`](https://testnet.snowtrace.io/address/0x26254c3c69b63e490c7dd88662549b12f8884e08) |
| `ChildVault` proxy          | [`0x781d5338eb60ed6c0129f28ce56872cc239ac3c2`](https://testnet.snowtrace.io/address/0x781d5338eb60ed6c0129f28ce56872cc239ac3c2) |
| `AaveV3Adapter`             | [`0x221736594f42a10ce61a0f66dc4e6b04786ff8a3`](https://testnet.snowtrace.io/address/0x221736594f42a10ce61a0f66dc4e6b04786ff8a3) |
| `AaveV4Adapter`             | [`0x09addfa88e49bdf33021971e38b0bfae8715af7a`](https://testnet.snowtrace.io/address/0x09addfa88e49bdf33021971e38b0bfae8715af7a) |
| `WorkflowRouter`            | [`0x412749be129b2b6ba778f732adb6b69617bd7a13`](https://testnet.snowtrace.io/address/0x412749be129b2b6ba778f732adb6b69617bd7a13) |

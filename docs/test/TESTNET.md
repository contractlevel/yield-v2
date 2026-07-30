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

Run from `evm/` after all five vault proxies have been deployed and the deployer has
`CONFIG_OPERATOR_ROLE` on each vault proxy. The script configures every vault with the other four vaults
defined in `script/HelperConfig.s.sol`.

```bash
for rpc in arbitrum_sepolia ethereum_sepolia base_sepolia optimism_sepolia avalanche_fuji; do
    forge script script/interactions/SetCrosschainVaults.s.sol:SetCrosschainVaults \
        --rpc-url "$rpc" \
        --account testnet-deployer \
        --sender 0x7664C538C80870824738A8ADCcd92AcA244D7e69 \
        --broadcast \
        -vvvv || break
done
```

### Configure Workflow Routers

Run from `evm/` after deploying the CRE workflow and granting the deployer
`CONFIG_OPERATOR_ROLE` on each WorkflowRouter. The script configures the deployed workflow metadata and
allowlists the appropriate parent or child vault selectors. It validates the configured vault and verifies
the resulting router configuration before completing.

```bash
for rpc in arbitrum_sepolia ethereum_sepolia base_sepolia optimism_sepolia avalanche_fuji; do
    forge script script/interactions/ConfigureWorkflowRouter.s.sol:ConfigureWorkflowRouter \
        --rpc-url "$rpc" \
        --account testnet-deployer \
        --sender 0x7664C538C80870824738A8ADCcd92AcA244D7e69 \
        --broadcast \
        -vvvv || break
done
```

The workflow values are defined once in `script/HelperConfig.s.sol` and shared by all five testnet configs:

- workflow name: `67d6954c97`
- workflow ID: `0x00af2b6d4c060c94ddf6f13d9236199fc8cd4d5b35b46c164b36912e45655891`
- workflow owner: `0x7664C538C80870824738A8ADCcd92AcA244D7e69`

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
| `BaseVaultCcipLib`                                            | [`0x81b55294f3d3af167e9f1e622149648f42859be6`](https://sepolia.arbiscan.io/address/0x81b55294f3d3af167e9f1e622149648f42859be6#code) |
| `ParentVaultUserEpochLib`                                     | [`0xf00e3fe45530aa4308b8172ecdd23114d96b2326`](https://sepolia.arbiscan.io/address/0xf00e3fe45530aa4308b8172ecdd23114d96b2326#code) |
| `ParentVaultRebalanceLib`                                     | [`0x3292407edbcd027d587ae2818d6f1c9ef630c41a`](https://sepolia.arbiscan.io/address/0x3292407edbcd027d587ae2818d6f1c9ef630c41a#code) |
| `ParentVaultEpochLib`                                         | [`0xb3b24e9fc31062817fb29c7133462990e531588a`](https://sepolia.arbiscan.io/address/0xb3b24e9fc31062817fb29c7133462990e531588a#code) |
| `ParentVaultConfigLib`                                        | [`0x363afb12607a53e3f8d2fc663946d229d83a93f5`](https://sepolia.arbiscan.io/address/0x363afb12607a53e3f8d2fc663946d229d83a93f5#code) |
| `ParentVaultCcipLib`                                          | [`0xc64e578152bae99174f597d16eed660ab6e250a8`](https://sepolia.arbiscan.io/address/0xc64e578152bae99174f597d16eed660ab6e250a8#code) |
| `BaseVaultStrategyLib`                                        | [`0xa7205e3bb7ecf1537f7ef2641bd9108fecd28bc5`](https://sepolia.arbiscan.io/address/0xa7205e3bb7ecf1537f7ef2641bd9108fecd28bc5#code) |
| `BaseVaultConfigLib`                                          | [`0x287eacd24f969910914f87eb6b936dde5d0626ac`](https://sepolia.arbiscan.io/address/0x287eacd24f969910914f87eb6b936dde5d0626ac#code) |
| `PolicyEngine` implementation                                 | [`0x0dbbb22e5a633f0cdd3e512b9427d11f7fe9ca92`](https://sepolia.arbiscan.io/address/0x0dbbb22e5a633f0cdd3e512b9427d11f7fe9ca92#code) |
| `PolicyEngine` proxy                                          | [`0x40585f81080282e0eee11f9d459f6e0005cfb9bb`](https://sepolia.arbiscan.io/address/0x40585f81080282e0eee11f9d459f6e0005cfb9bb#code) |
| `IdentityRegistry` implementation                             | [`0x6395c9f680cda7ca391509a04f8c35895ad89bf8`](https://sepolia.arbiscan.io/address/0x6395c9f680cda7ca391509a04f8c35895ad89bf8#code) |
| `IdentityRegistry` proxy                                      | [`0x49a62fa0c40e1c511736abbf2e23cb11e8deb7cb`](https://sepolia.arbiscan.io/address/0x49a62fa0c40e1c511736abbf2e23cb11e8deb7cb#code) |
| `CredentialRegistry` implementation                           | [`0x31b0d818cb4c356b5a2145a08cc5c0f70d261962`](https://sepolia.arbiscan.io/address/0x31b0d818cb4c356b5a2145a08cc5c0f70d261962#code) |
| `CredentialRegistry` proxy                                    | [`0x5b4162118af51df69ab875e66d927ccc6e893296`](https://sepolia.arbiscan.io/address/0x5b4162118af51df69ab875e66d927ccc6e893296#code) |
| `AdapterRegistry`                                             | [`0x10cf67db20d37930a7874843f227faca6daaf8ec`](https://sepolia.arbiscan.io/address/0x10cf67db20d37930a7874843f227faca6daaf8ec#code) |
| `YieldcoinShare` implementation                               | [`0x2aa278dbdb32135554cb61409ae1f0720d73812c`](https://sepolia.arbiscan.io/address/0x2aa278dbdb32135554cb61409ae1f0720d73812c#code) |
| `YieldcoinShare` proxy                                        | [`0x37672a053a258202ad2f1d0afadabf7e0db93399`](https://sepolia.arbiscan.io/address/0x37672a053a258202ad2f1d0afadabf7e0db93399#code) |
| `ParentVault` implementation                                  | [`0x80a1c5d6859d51dce3373e8e117c059177141056`](https://sepolia.arbiscan.io/address/0x80a1c5d6859d51dce3373e8e117c059177141056#code) |
| `ParentVault` proxy                                           | [`0x0c4ed72777e832e2dae6d59875e956abd9ad91d9`](https://sepolia.arbiscan.io/address/0x0c4ed72777e832e2dae6d59875e956abd9ad91d9#code) |
| `AaveV3Adapter`                                               | [`0x3aa20269fe42a89debcfb1370d6b7df74e64d414`](https://sepolia.arbiscan.io/address/0x3aa20269fe42a89debcfb1370d6b7df74e64d414#code) |
| `CompoundV3Adapter`                                           | [`0xcce8adc9df419707a5b538c6d80106b4927b2311`](https://sepolia.arbiscan.io/address/0xcce8adc9df419707a5b538c6d80106b4927b2311#code) |
| `WorkflowRouter`                                              | [`0x7fd005f9552f600e8231ba821a9e7da42a94fe83`](https://sepolia.arbiscan.io/address/0x7fd005f9552f600e8231ba821a9e7da42a94fe83#code) |
| `TerminalAllowPolicy` implementation                          | [`0x7f2427eefe90c3c368fd552dc05ed45fdef745ae`](https://sepolia.arbiscan.io/address/0x7f2427eefe90c3c368fd552dc05ed45fdef745ae#code) |
| `TerminalAllowPolicy` proxy                                   | [`0xaf56279900dea0a93608deb206d9e6ec466245f2`](https://sepolia.arbiscan.io/address/0xaf56279900dea0a93608deb206d9e6ec466245f2#code) |
| `YieldcoinShareFrozenAccountPolicy` implementation            | [`0xdcca262c9d046580271276156deadd372e5178fe`](https://sepolia.arbiscan.io/address/0xdcca262c9d046580271276156deadd372e5178fe#code) |
| `YieldcoinShareFrozenAccountPolicy` proxy                     | [`0xe4592d35615da8cd1414aec213318e5ee6653d94`](https://sepolia.arbiscan.io/address/0xe4592d35615da8cd1414aec213318e5ee6653d94#code) |
| `CredentialRegistryIdentityValidatorPolicy` implementation    | [`0x477d5809309e01aee380acb397fe8707e52c569e`](https://sepolia.arbiscan.io/address/0x477d5809309e01aee380acb397fe8707e52c569e#code) |
| `CredentialRegistryIdentityValidatorPolicy` proxy             | [`0x56e7925638645685016b71f7e6d832b3f7d01c0f`](https://sepolia.arbiscan.io/address/0x56e7925638645685016b71f7e6d832b3f7d01c0f#code) |
| `SenderExtractor`                                             | [`0x98d299159950030b7dfcb34b457f3ebda84cc733`](https://sepolia.arbiscan.io/address/0x98d299159950030b7dfcb34b457f3ebda84cc733#code) |
| `OnlyAuthorizedSenderPolicy` implementation                   | [`0x4ab6e929e45f846a4b3431e9633c8a3422f586c3`](https://sepolia.arbiscan.io/address/0x4ab6e929e45f846a4b3431e9633c8a3422f586c3#code) |
| `OnlyAuthorizedSenderPolicy` proxy                            | [`0x604c05048c37239d4b0dbade9c95c6114bf4c50c`](https://sepolia.arbiscan.io/address/0x604c05048c37239d4b0dbade9c95c6114bf4c50c#code) |
| `CredentialRegistryAccountListValidatorPolicy` implementation | [`0x6d8b6f78ce622bd4418ca1bca961830a43c145ba`](https://sepolia.arbiscan.io/address/0x6d8b6f78ce622bd4418ca1bca961830a43c145ba#code) |
| `CredentialRegistryAccountListValidatorPolicy` proxy          | [`0x004af5cefbf481798f6dd54e26c51dcb0687c903`](https://sepolia.arbiscan.io/address/0x004af5cefbf481798f6dd54e26c51dcb0687c903#code) |
| `YieldcoinShareKycExtractor`                                  | [`0x3fbc8e2386248a217c4c364323c1c0b21d63bc43`](https://sepolia.arbiscan.io/address/0x3fbc8e2386248a217c4c364323c1c0b21d63bc43#code) |
| `RoleBasedAccessControlPolicy` implementation                 | [`0x69ed779fd52b41a753ae90b9e828b8c448aa774a`](https://sepolia.arbiscan.io/address/0x69ed779fd52b41a753ae90b9e828b8c448aa774a#code) |
| `RoleBasedAccessControlPolicy` proxy                          | [`0x4123be5ee9fe84a8546d2703b5e478dcee0e1adc`](https://sepolia.arbiscan.io/address/0x4123be5ee9fe84a8546d2703b5e478dcee0e1adc#code) |

## Child Deployments

### Ethereum Sepolia

| Contract                    | Address                                      |
| --------------------------- | -------------------------------------------- |
| `BaseVaultStrategyLib`      | [`0x4ab7794139fb422813b97e1e4a33a7947666a323`](https://sepolia.etherscan.io/address/0x4ab7794139fb422813b97e1e4a33a7947666a323#code) |
| `AdapterRegistry`           | [`0x971e7d69e039cc013145ceaa6aacc9dbe55deba6`](https://sepolia.etherscan.io/address/0x971e7d69e039cc013145ceaa6aacc9dbe55deba6#code) |
| `ChildVault` implementation | [`0xb2ac18061d6996202227b211a0c7915b010413c2`](https://sepolia.etherscan.io/address/0xb2ac18061d6996202227b211a0c7915b010413c2#code) |
| `ChildVault` proxy          | [`0x809a7bf022841e3bcda0d3cf64b780aabf898c64`](https://sepolia.etherscan.io/address/0x809a7bf022841e3bcda0d3cf64b780aabf898c64#code) |
| `AaveV3Adapter`             | [`0xf02c4a15eeffc6fbbde26a2dddb52b57861e2e38`](https://sepolia.etherscan.io/address/0xf02c4a15eeffc6fbbde26a2dddb52b57861e2e38#code) |
| `AaveV4Adapter`             | [`0x811356c12f222c246fca7ac73f740d8accf03e0a`](https://sepolia.etherscan.io/address/0x811356c12f222c246fca7ac73f740d8accf03e0a#code) |
| `CompoundV3Adapter`         | [`0x584099c5200b8a63536230017f718797026e5915`](https://sepolia.etherscan.io/address/0x584099c5200b8a63536230017f718797026e5915#code) |
| `WorkflowRouter`            | [`0xe7a5a96775f75baaaf49e5dc009e3264779e2f9c`](https://sepolia.etherscan.io/address/0xe7a5a96775f75baaaf49e5dc009e3264779e2f9c#code) |

### Base Sepolia

| Contract                    | Address                                      |
| --------------------------- | -------------------------------------------- |
| `BaseVaultStrategyLib`      | [`0x4ab7794139fb422813b97e1e4a33a7947666a323`](https://sepolia.basescan.org/address/0x4ab7794139fb422813b97e1e4a33a7947666a323#code) |
| `AdapterRegistry`           | [`0x4f162bc4acc9e5847fcbef84cebaf45087430c36`](https://sepolia.basescan.org/address/0x4f162bc4acc9e5847fcbef84cebaf45087430c36#code) |
| `ChildVault` implementation | [`0x781d5338eb60ed6c0129f28ce56872cc239ac3c2`](https://sepolia.basescan.org/address/0x781d5338eb60ed6c0129f28ce56872cc239ac3c2#code) |
| `ChildVault` proxy          | [`0x221736594f42a10ce61a0f66dc4e6b04786ff8a3`](https://sepolia.basescan.org/address/0x221736594f42a10ce61a0f66dc4e6b04786ff8a3#code) |
| `AaveV3Adapter`             | [`0xdc0239d860dc5b3356e9ab260b56cf69e9cfb92a`](https://sepolia.basescan.org/address/0xdc0239d860dc5b3356e9ab260b56cf69e9cfb92a#code) |
| `CompoundV3Adapter`         | [`0x5d1079dae90f23bbe64faf3adc08554669d9f938`](https://sepolia.basescan.org/address/0x5d1079dae90f23bbe64faf3adc08554669d9f938#code) |
| `WorkflowRouter`            | [`0x971e7d69e039cc013145ceaa6aacc9dbe55deba6`](https://sepolia.basescan.org/address/0x971e7d69e039cc013145ceaa6aacc9dbe55deba6#code) |

### Optimism Sepolia

| Contract                    | Address                                      |
| --------------------------- | -------------------------------------------- |
| `BaseVaultStrategyLib`      | [`0x4ab7794139fb422813b97e1e4a33a7947666a323`](https://sepolia-optimism.etherscan.io/address/0x4ab7794139fb422813b97e1e4a33a7947666a323#code) |
| `AdapterRegistry`           | [`0x4f162bc4acc9e5847fcbef84cebaf45087430c36`](https://sepolia-optimism.etherscan.io/address/0x4f162bc4acc9e5847fcbef84cebaf45087430c36#code) |
| `ChildVault` implementation | [`0x781d5338eb60ed6c0129f28ce56872cc239ac3c2`](https://sepolia-optimism.etherscan.io/address/0x781d5338eb60ed6c0129f28ce56872cc239ac3c2#code) |
| `ChildVault` proxy          | [`0x221736594f42a10ce61a0f66dc4e6b04786ff8a3`](https://sepolia-optimism.etherscan.io/address/0x221736594f42a10ce61a0f66dc4e6b04786ff8a3#code) |
| `AaveV3Adapter`             | [`0xdc0239d860dc5b3356e9ab260b56cf69e9cfb92a`](https://sepolia-optimism.etherscan.io/address/0xdc0239d860dc5b3356e9ab260b56cf69e9cfb92a#code) |
| `CompoundV3Adapter`         | [`0x5d1079dae90f23bbe64faf3adc08554669d9f938`](https://sepolia-optimism.etherscan.io/address/0x5d1079dae90f23bbe64faf3adc08554669d9f938#code) |
| `WorkflowRouter`            | [`0x971e7d69e039cc013145ceaa6aacc9dbe55deba6`](https://sepolia-optimism.etherscan.io/address/0x971e7d69e039cc013145ceaa6aacc9dbe55deba6#code) |

### Avalanche Fuji

| Contract                    | Address                                      |
| --------------------------- | -------------------------------------------- |
| `BaseVaultStrategyLib`      | [`0x4ab7794139fb422813b97e1e4a33a7947666a323`](https://testnet.snowtrace.io/address/0x4ab7794139fb422813b97e1e4a33a7947666a323#code) |
| `AdapterRegistry`           | [`0xd9e76077c65fe2ca25ced7432bf206c19507c553`](https://testnet.snowtrace.io/address/0xd9e76077c65fe2ca25ced7432bf206c19507c553#code) |
| `ChildVault` implementation | [`0x26254c3c69b63e490c7dd88662549b12f8884e08`](https://testnet.snowtrace.io/address/0x26254c3c69b63e490c7dd88662549b12f8884e08#code) |
| `ChildVault` proxy          | [`0x781d5338eb60ed6c0129f28ce56872cc239ac3c2`](https://testnet.snowtrace.io/address/0x781d5338eb60ed6c0129f28ce56872cc239ac3c2#code) |
| `AaveV3Adapter`             | [`0x221736594f42a10ce61a0f66dc4e6b04786ff8a3`](https://testnet.snowtrace.io/address/0x221736594f42a10ce61a0f66dc4e6b04786ff8a3#code) |
| `AaveV4Adapter`             | [`0x09addfa88e49bdf33021971e38b0bfae8715af7a`](https://testnet.snowtrace.io/address/0x09addfa88e49bdf33021971e38b0bfae8715af7a#code) |
| `WorkflowRouter`            | [`0x412749be129b2b6ba778f732adb6b69617bd7a13`](https://testnet.snowtrace.io/address/0x412749be129b2b6ba778f732adb6b69617bd7a13#code) |

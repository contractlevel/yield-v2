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
- polygon

compoundV3:

- arb
- base
- op
- eth

aaveV4:

- eth
- avax

### Deploy Mock Protocols:

#### Polygon Amoy

| Contract | Address |
| --- | --- |
| `TestnetAaveV3Pool` | [0x90eD505030703c504FB162DE0A892705b4812D0f](https://amoy.polygonscan.com/address/0x90eD505030703c504FB162DE0A892705b4812D0f#code) |
| `TestnetAToken` | [0x67798aC5b8B3C2Aefc939825d2eaA958f4eCe367](https://amoy.polygonscan.com/address/0x67798aC5b8B3C2Aefc939825d2eaA958f4eCe367#code) |
| `TestnetAaveV3PoolAddressesProvider` | [0x90e10d38F75ce1A871A1fDeA9bab39e8ddA4531f](https://amoy.polygonscan.com/address/0x90e10d38F75ce1A871A1fDeA9bab39e8ddA4531f#code) |

All three contracts are verified. The pool uses native Amoy USDC (`0x41E94Eb019C0762f9Bfcf9Fb1E58725BfB0e7582`) and is owned by `0x7664C538C80870824738A8ADCcd92AcA244D7e69`. Deployment cost: 0.046433952091416843 POL.

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
- workflow ID: `0x008ed53617a116cbfa73849a3eb22ab73099b7c30e14a54c6a34116c19a1e4da`
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

## Parent Deployments (Base Sepolia)

| Contract | Address |
| --- | --- |
| `BaseVaultCcipLib` | [`0x9451451c7d6616c2e47b44a257b76769e4afad1f`](https://sepolia.basescan.org/address/0x9451451c7d6616c2e47b44a257b76769e4afad1f#code) |
| `ParentVaultUserEpochLib` | [`0xc46c2fe15b06e2d0e24a07edce3d490100966ed8`](https://sepolia.basescan.org/address/0xc46c2fe15b06e2d0e24a07edce3d490100966ed8#code) |
| `ParentVaultRebalanceLib` | [`0xc044640d1ee350ccfe8d20ee05dadf58274284f9`](https://sepolia.basescan.org/address/0xc044640d1ee350ccfe8d20ee05dadf58274284f9#code) |
| `ParentVaultEpochLib` | [`0x583a6e90cb2be26004c4912219e21cdb00975aed`](https://sepolia.basescan.org/address/0x583a6e90cb2be26004c4912219e21cdb00975aed#code) |
| `ParentVaultConfigLib` | [`0x40a144820e23fee92ca7eef7095bed9a15d0dacc`](https://sepolia.basescan.org/address/0x40a144820e23fee92ca7eef7095bed9a15d0dacc#code) |
| `ParentVaultCcipLib` | [`0x10ac9823a72eec19fb90d99721c4fece3edad1c0`](https://sepolia.basescan.org/address/0x10ac9823a72eec19fb90d99721c4fece3edad1c0#code) |
| `BaseVaultStrategyLib` | [`0x1cbd0bf1001c9a7357f04f4ba51ba21df2608d89`](https://sepolia.basescan.org/address/0x1cbd0bf1001c9a7357f04f4ba51ba21df2608d89#code) |
| `BaseVaultConfigLib` | [`0xaf21f72bcd48714a985378a908d2daf871802a22`](https://sepolia.basescan.org/address/0xaf21f72bcd48714a985378a908d2daf871802a22#code) |
| `AdapterRegistry` | [`0x0527dd5103eb59974cb882446780fe190caf4777`](https://sepolia.basescan.org/address/0x0527dd5103eb59974cb882446780fe190caf4777#code) |
| `YieldcoinShare implementation` | [`0xee4d89b06fe9082fe9a737de2a5a061e07bef781`](https://sepolia.basescan.org/address/0xee4d89b06fe9082fe9a737de2a5a061e07bef781#code) |
| `YieldcoinShare proxy` | [`0x3bb4f976c6881ef8cda6d2a94f774381dd80c742`](https://sepolia.basescan.org/address/0x3bb4f976c6881ef8cda6d2a94f774381dd80c742#code) |
| `YieldcoinShareSeedLock` | [`0xd4f567e1cb628a1a0af1b1481d45bd0eae64f243`](https://sepolia.basescan.org/address/0xd4f567e1cb628a1a0af1b1481d45bd0eae64f243#code) |
| `ParentVault implementation` | [`0xbdf3367fbcefd2f4b6ff9a2fd6b31e587c569139`](https://sepolia.basescan.org/address/0xbdf3367fbcefd2f4b6ff9a2fd6b31e587c569139#code) |
| `ParentVault proxy` | [`0xa5e7a54867abc3c1c871aed5d11320fcc56ad8b7`](https://sepolia.basescan.org/address/0xa5e7a54867abc3c1c871aed5d11320fcc56ad8b7#code) |
| `AaveV3Adapter` | [`0xd2c6088555ad7eadfa602138f75afbabebc433b9`](https://sepolia.basescan.org/address/0xd2c6088555ad7eadfa602138f75afbabebc433b9#code) |
| `CompoundV3Adapter` | [`0x109171d2833d302ad6300488f2f2fd21671c3d85`](https://sepolia.basescan.org/address/0x109171d2833d302ad6300488f2f2fd21671c3d85#code) |
| `WorkflowRouter` | [`0x5f8191e9fe6b4164930cdf92f6fe824ae35602e0`](https://sepolia.basescan.org/address/0x5f8191e9fe6b4164930cdf92f6fe824ae35602e0#code) |

## Child Deployments

### Polygon Amoy

| Contract | Address |
| --- | --- |
| `AdapterRegistry` | [0x26254c3c69b63e490c7dd88662549b12f8884e08](https://amoy.polygonscan.com/address/0x26254c3c69b63e490c7dd88662549b12f8884e08#code) |
| `ChildVault` implementation | [0x221736594f42a10ce61a0f66dc4e6b04786ff8a3](https://amoy.polygonscan.com/address/0x221736594f42a10ce61a0f66dc4e6b04786ff8a3#code) |
| `ChildVault` proxy | [0xdc0239d860dc5b3356e9ab260b56cf69e9cfb92a](https://amoy.polygonscan.com/address/0xdc0239d860dc5b3356e9ab260b56cf69e9cfb92a#code) |
| `AaveV3Adapter` | [0x09addfa88e49bdf33021971e38b0bfae8715af7a](https://amoy.polygonscan.com/address/0x09addfa88e49bdf33021971e38b0bfae8715af7a#code) |
| `WorkflowRouter` | [0x079a90b7761ff10f455bc2188392b2ae765f8dad](https://amoy.polygonscan.com/address/0x079a90b7761ff10f455bc2188392b2ae765f8dad#code) |

The deployment stopped at a redundant config-role grant. Epoch, rebalance, LINK, and rewards roles were completed with separate transactions using a 200,000 gas limit:

- Epoch: `0x7d6e0284da17c86d7adceff34c2fab433c47b3f901fc31369cb7d11d56c6d9cd`.
- Rebalance: `0xf7ad3961ae8fb1eea68e9c2a9f46ce929d3468775d56727e2a3b21e6d9454222`.
- LINK: `0x90a418ddcc1ce57b076eb40019a70b4aeea8935e06e96950d5e64e81a79a430f`.
- Rewards: `0x531e6dc831cca4e4daf834b503fe3792739da74ac72b886b63a2cb755eb9dde2`.

### Arbitrum Sepolia

| Contract | Address |
| --- | --- |
| `AdapterRegistry` | [`0xa659d0e7baf83532ae903ddcb0eb5f8c561e0d04`](https://sepolia.arbiscan.io/address/0xa659d0e7baf83532ae903ddcb0eb5f8c561e0d04#code) |
| `ChildVault implementation` | [`0x05392c3d1ac7bdbfd02d06e24b070062ddac2df0`](https://sepolia.arbiscan.io/address/0x05392c3d1ac7bdbfd02d06e24b070062ddac2df0#code) |
| `ChildVault proxy` | [`0xe995ddfe2df6fce2e3caf4028e94e771ebe0e34b`](https://sepolia.arbiscan.io/address/0xe995ddfe2df6fce2e3caf4028e94e771ebe0e34b#code) |
| `AaveV3Adapter` | [`0x65dfde686a0686788c5c600bed1f6564060bd303`](https://sepolia.arbiscan.io/address/0x65dfde686a0686788c5c600bed1f6564060bd303#code) |
| `CompoundV3Adapter` | [`0xa4b43e11ef0222de7587895af77effe35c006ab2`](https://sepolia.arbiscan.io/address/0xa4b43e11ef0222de7587895af77effe35c006ab2#code) |
| `WorkflowRouter` | [`0x117d5fec39c7209a618d71b52b834eb44c5aff7f`](https://sepolia.arbiscan.io/address/0x117d5fec39c7209a618d71b52b834eb44c5aff7f#code) |

### Ethereum Sepolia

| Contract | Address |
| --- | --- |
| `AdapterRegistry` | [`0xbdf3367fbcefd2f4b6ff9a2fd6b31e587c569139`](https://sepolia.etherscan.io/address/0xbdf3367fbcefd2f4b6ff9a2fd6b31e587c569139#code) |
| `ChildVault implementation` | [`0xc8bf8893f4322d511a982d0748eb362f6eb3e0eb`](https://sepolia.etherscan.io/address/0xc8bf8893f4322d511a982d0748eb362f6eb3e0eb#code) |
| `ChildVault proxy` | [`0xd2c6088555ad7eadfa602138f75afbabebc433b9`](https://sepolia.etherscan.io/address/0xd2c6088555ad7eadfa602138f75afbabebc433b9#code) |
| `AaveV3Adapter` | [`0x5e1493ec552e758c2491a4e2fc22800bd9bc5d0d`](https://sepolia.etherscan.io/address/0x5e1493ec552e758c2491a4e2fc22800bd9bc5d0d#code) |
| `AaveV4Adapter` | [`0x5736580f680cbccee38a2221922c5cabe480bcbc`](https://sepolia.etherscan.io/address/0x5736580f680cbccee38a2221922c5cabe480bcbc#code) |
| `CompoundV3Adapter` | [`0xf39f629acf22650ea6d472fa7b6546e486177f19`](https://sepolia.etherscan.io/address/0xf39f629acf22650ea6d472fa7b6546e486177f19#code) |
| `WorkflowRouter` | [`0x5f8191e9fe6b4164930cdf92f6fe824ae35602e0`](https://sepolia.etherscan.io/address/0x5f8191e9fe6b4164930cdf92f6fe824ae35602e0#code) |


### Optimism Sepolia

| Contract | Address |
| --- | --- |
| `AdapterRegistry` | [`0x96b4c7e3419f07bc2baa0b5a4151d220984028a9`](https://sepolia-optimism.etherscan.io/address/0x96b4c7e3419f07bc2baa0b5a4151d220984028a9#code) |
| `ChildVault implementation` | [`0xcd6f007979bfb9f1ea9a9df432a298d0469861d3`](https://sepolia-optimism.etherscan.io/address/0xcd6f007979bfb9f1ea9a9df432a298d0469861d3#code) |
| `ChildVault proxy` | [`0x66738d30269f1e88a762f421995feebe8e617d52`](https://sepolia-optimism.etherscan.io/address/0x66738d30269f1e88a762f421995feebe8e617d52#code) |
| `AaveV3Adapter` | [`0x07c4e5242206de2da117635c31b84884522f46fb`](https://sepolia-optimism.etherscan.io/address/0x07c4e5242206de2da117635c31b84884522f46fb#code) |
| `CompoundV3Adapter` | [`0x7049a76a036137c9d63a3a8c32aa9ce0cfa4192d`](https://sepolia-optimism.etherscan.io/address/0x7049a76a036137c9d63a3a8c32aa9ce0cfa4192d#code) |
| `WorkflowRouter` | [`0xee4d89b06fe9082fe9a737de2a5a061e07bef781`](https://sepolia-optimism.etherscan.io/address/0xee4d89b06fe9082fe9a737de2a5a061e07bef781#code) |

### Avalanche Fuji

| Contract | Address |
| --- | --- |
| `AdapterRegistry` | [`0xc0e11e92188743e37fed15f0c998ed1b9533fe01`](https://testnet.snowtrace.io/address/0xc0e11e92188743e37fed15f0c998ed1b9533fe01#code) |
| `ChildVault implementation` | [`0x512efe701404a637ccaca933028d0afe647cc0c4`](https://testnet.snowtrace.io/address/0x512efe701404a637ccaca933028d0afe647cc0c4#code) |
| `ChildVault proxy` | [`0xcd6f007979bfb9f1ea9a9df432a298d0469861d3`](https://testnet.snowtrace.io/address/0xcd6f007979bfb9f1ea9a9df432a298d0469861d3#code) |
| `AaveV3Adapter` | [`0x66738d30269f1e88a762f421995feebe8e617d52`](https://testnet.snowtrace.io/address/0x66738d30269f1e88a762f421995feebe8e617d52#code) |
| `AaveV4Adapter` | [`0x921fe4ed6a98f800199b11569673a5230b522f9c`](https://testnet.snowtrace.io/address/0x921fe4ed6a98f800199b11569673a5230b522f9c#code) |
| `WorkflowRouter` | [`0xdad87492a140283dc2c8b4a5a217a832bb31fbfe`](https://testnet.snowtrace.io/address/0xdad87492a140283dc2c8b4a5a217a832bb31fbfe#code) |

---

## Testnet Transactions

### 1st Epoch

[closeEpoch triggered by CRE](https://sepolia.arbiscan.io/tx/0xbd9b7866971569bc146f9fc83a74417a83c72add1561ad9860d325ebcf8d97ef)

[claimShares in first epoch](https://sepolia.arbiscan.io/tx/0x347e5212e2f6d7b7aea16ebe814b3a1c76358760fa85237dd3242576eb445eae)

### 1st Rebalance

[first rebalance (crosschain: parent to child)](https://sepolia.arbiscan.io/tx/0x9aa14b92e1d3cb7aa57167b8a3c68f770e516f43978cd50cb08deff5ad0e64e1)

[ccip tx for first rebalance](https://ccip.chain.link/msg/0x390dd2a29c4041fccbbd174cd5ae8ec5d31c1f519d6689267199416600179f4b)

[RebalanceDepositSuccess](https://sepolia.basescan.org/tx/0x0e5adc745484f778328a4476c3c3bf8dd63939d08f5fda5aabf76d7fb58c42b3#eventlog)

[RebalanceCompleted](https://sepolia.arbiscan.io/tx/0x2994730ddfc737704f2e0ab3c2e65d5a414bb718a3246623e18451ca151f3a24)

### 2nd Epoch

[closeEpoch (NET_DEPOSIT)](https://sepolia.arbiscan.io/tx/0x3f6d26488f2e595ee529204f3d60224631a9c52dfc43c23803abe303b1821d28)

[ccip net deposit from parent to strategy](https://ccip.chain.link/msg/0xad1f3ac53d999e1d325df19a7e99503ab6e0652422a9e3b046cacddb2c11bca0)

[DepositToStrategySuccess](https://sepolia.basescan.org/tx/0x6cf5aaea473e1a80879344a218813f7ca8be7e42d7d252716ee46bae285af79b)

### 3rd Epoch

[EpochExecuting (NET_WITHDRAW) (log triggers CRE to write to strategy)](https://sepolia.arbiscan.io/tx/0xd77a8a7d18e6f321efd7068090f385692549865df6c6ff12b041bb8efc48fefc)

[WithdrawFromStrategySuccess, RebalanceWithdrawSuccess, CCIPBridged (from strategy to parent)](https://sepolia.basescan.org/tx/0x35025414a798fa1fff584d1614ee9ee4e8bb6aedc08910e4975cdec73743edf6)

[EpochClaimable (ccipReceive on Parent)](https://sepolia.arbiscan.io/tx/0xdf259b960b246f4c2d8e498d6154d6213b49dda850429ba696b514ec2cf35d55#eventlog)

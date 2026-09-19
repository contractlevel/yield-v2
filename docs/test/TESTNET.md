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
for rpc in arbitrum_sepolia ethereum_sepolia base_sepolia optimism_sepolia avalanche_fuji polygon_amoy; do
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
        --slow \
        -vvvv || break
done
```

The workflow values are defined once in `script/HelperConfig.s.sol` and shared by all six testnet configs:

- workflow name: `67d6954c97`
- workflow ID: `0x000c6b4abbc8ab218cdf41a64ca706a2e8606dc00ee803461cd2b8bbd8db9358`
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

| Contract                        | Address                                                                                                                              |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `AdapterRegistry`               | [`0x0753147da68bc9e52213a4c42b6750282c5bee65`](https://sepolia.basescan.org/address/0x0753147da68bc9e52213a4c42b6750282c5bee65#code) |
| `YieldcoinShare implementation` | [`0x071ee35b8d68780c235a58656ca20c8d52df040d`](https://sepolia.basescan.org/address/0x071ee35b8d68780c235a58656ca20c8d52df040d#code) |
| `YieldcoinShare proxy`          | [`0xdd6f3cfe1197decb8c3fcc033682e5da1f8520ea`](https://sepolia.basescan.org/address/0xdd6f3cfe1197decb8c3fcc033682e5da1f8520ea#code) |
| `YieldcoinShareSeedLock`        | [`0x314f103d113141979d476ae4838a5050e4bf1492`](https://sepolia.basescan.org/address/0x314f103d113141979d476ae4838a5050e4bf1492#code) |
| `ParentVault implementation`    | [`0xf9cae899f9b9da22eafeafa30e4c5a9057e7000c`](https://sepolia.basescan.org/address/0xf9cae899f9b9da22eafeafa30e4c5a9057e7000c#code) |
| `ParentVault proxy`             | [`0x6fbb019a1d9f49bd2e667de994cc3588edb4b09d`](https://sepolia.basescan.org/address/0x6fbb019a1d9f49bd2e667de994cc3588edb4b09d#code) |
| `AaveV3Adapter`                 | [`0xc19801df37e45f63fd46c4253cf55a75a43e40cf`](https://sepolia.basescan.org/address/0xc19801df37e45f63fd46c4253cf55a75a43e40cf#code) |
| `CompoundV3Adapter`             | [`0xc5d7cba8fdee824a4e424316fe2fe10762d0d960`](https://sepolia.basescan.org/address/0xc5d7cba8fdee824a4e424316fe2fe10762d0d960#code) |
| `WorkflowRouter`                | [`0x7ceeb23617a99038dadeb30566290b7442ead006`](https://sepolia.basescan.org/address/0x7ceeb23617a99038dadeb30566290b7442ead006#code) |

## Child Deployments

### Polygon Amoy

| Contract                    | Address                                                                                                                            |
| --------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| `AdapterRegistry`           | [0x26254c3c69b63e490c7dd88662549b12f8884e08](https://amoy.polygonscan.com/address/0x26254c3c69b63e490c7dd88662549b12f8884e08#code) |
| `ChildVault` implementation | [0x221736594f42a10ce61a0f66dc4e6b04786ff8a3](https://amoy.polygonscan.com/address/0x221736594f42a10ce61a0f66dc4e6b04786ff8a3#code) |
| `ChildVault` proxy          | [0xdc0239d860dc5b3356e9ab260b56cf69e9cfb92a](https://amoy.polygonscan.com/address/0xdc0239d860dc5b3356e9ab260b56cf69e9cfb92a#code) |
| `AaveV3Adapter`             | [0xe7a5a96775f75baaaf49e5dc009e3264779e2f9c](https://amoy.polygonscan.com/address/0xe7a5a96775f75baaaf49e5dc009e3264779e2f9c#code) |
| `WorkflowRouter`            | [0x079a90b7761ff10f455bc2188392b2ae765f8dad](https://amoy.polygonscan.com/address/0x079a90b7761ff10f455bc2188392b2ae765f8dad#code) |

The deployment stopped at a redundant config-role grant. Epoch, rebalance, LINK, and rewards roles were completed with separate transactions using a 200,000 gas limit:

- Epoch: `0x7d6e0284da17c86d7adceff34c2fab433c47b3f901fc31369cb7d11d56c6d9cd`.
- Rebalance: `0xf7ad3961ae8fb1eea68e9c2a9f46ce929d3468775d56727e2a3b21e6d9454222`.
- LINK: `0x90a418ddcc1ce57b076eb40019a70b4aeea8935e06e96950d5e64e81a79a430f`.
- Rewards: `0x531e6dc831cca4e4daf834b503fe3792739da74ac72b886b63a2cb755eb9dde2`.

### Arbitrum Sepolia

| Contract                    | Address                                                                                                                             |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `AdapterRegistry`           | [`0xa659d0e7baf83532ae903ddcb0eb5f8c561e0d04`](https://sepolia.arbiscan.io/address/0xa659d0e7baf83532ae903ddcb0eb5f8c561e0d04#code) |
| `ChildVault implementation` | [`0x05392c3d1ac7bdbfd02d06e24b070062ddac2df0`](https://sepolia.arbiscan.io/address/0x05392c3d1ac7bdbfd02d06e24b070062ddac2df0#code) |
| `ChildVault proxy`          | [`0xe995ddfe2df6fce2e3caf4028e94e771ebe0e34b`](https://sepolia.arbiscan.io/address/0xe995ddfe2df6fce2e3caf4028e94e771ebe0e34b#code) |
| `AaveV3Adapter`             | [`0xed5b8fd4393a09827c07db7e84837aa529674bb4`](https://sepolia.arbiscan.io/address/0xed5b8fd4393a09827c07db7e84837aa529674bb4#code) |
| `CompoundV3Adapter`         | [`0x04b35d2f45e63d1d9f1bdcfba2b47bd06100f92c`](https://sepolia.arbiscan.io/address/0x04b35d2f45e63d1d9f1bdcfba2b47bd06100f92c#code) |
| `WorkflowRouter`            | [`0x117d5fec39c7209a618d71b52b834eb44c5aff7f`](https://sepolia.arbiscan.io/address/0x117d5fec39c7209a618d71b52b834eb44c5aff7f#code) |

### Ethereum Sepolia

| Contract                    | Address                                                                                                                              |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `AdapterRegistry`           | [`0xbdf3367fbcefd2f4b6ff9a2fd6b31e587c569139`](https://sepolia.etherscan.io/address/0xbdf3367fbcefd2f4b6ff9a2fd6b31e587c569139#code) |
| `ChildVault implementation` | [`0xc8bf8893f4322d511a982d0748eb362f6eb3e0eb`](https://sepolia.etherscan.io/address/0xc8bf8893f4322d511a982d0748eb362f6eb3e0eb#code) |
| `ChildVault proxy`          | [`0xd2c6088555ad7eadfa602138f75afbabebc433b9`](https://sepolia.etherscan.io/address/0xd2c6088555ad7eadfa602138f75afbabebc433b9#code) |
| `AaveV3Adapter`             | [`0x0d6f1cb4340d6205b64b9c6dbb6e24aef5b01e7a`](https://sepolia.etherscan.io/address/0x0d6f1cb4340d6205b64b9c6dbb6e24aef5b01e7a#code) |
| `AaveV4Adapter`             | [`0xcc6535ccb21f9ed8a0e593dddcd1a6fac1d6474b`](https://sepolia.etherscan.io/address/0xcc6535ccb21f9ed8a0e593dddcd1a6fac1d6474b#code) |
| `CompoundV3Adapter`         | [`0x63f8cfc8a7202e2dc1f46b23d2043c7889796b3a`](https://sepolia.etherscan.io/address/0x63f8cfc8a7202e2dc1f46b23d2043c7889796b3a#code) |
| `WorkflowRouter`            | [`0x5f8191e9fe6b4164930cdf92f6fe824ae35602e0`](https://sepolia.etherscan.io/address/0x5f8191e9fe6b4164930cdf92f6fe824ae35602e0#code) |

### Optimism Sepolia

| Contract                    | Address                                                                                                                                       |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `AdapterRegistry`           | [`0x96b4c7e3419f07bc2baa0b5a4151d220984028a9`](https://sepolia-optimism.etherscan.io/address/0x96b4c7e3419f07bc2baa0b5a4151d220984028a9#code) |
| `ChildVault implementation` | [`0xcd6f007979bfb9f1ea9a9df432a298d0469861d3`](https://sepolia-optimism.etherscan.io/address/0xcd6f007979bfb9f1ea9a9df432a298d0469861d3#code) |
| `ChildVault proxy`          | [`0x66738d30269f1e88a762f421995feebe8e617d52`](https://sepolia-optimism.etherscan.io/address/0x66738d30269f1e88a762f421995feebe8e617d52#code) |
| `AaveV3Adapter`             | [`0x1d458510bf28a1f001ed82461043eb574998d963`](https://sepolia-optimism.etherscan.io/address/0x1d458510bf28a1f001ed82461043eb574998d963#code) |
| `CompoundV3Adapter`         | [`0xedff1dfddca2aff40191c6ce11e54720570557d0`](https://sepolia-optimism.etherscan.io/address/0xedff1dfddca2aff40191c6ce11e54720570557d0#code) |
| `WorkflowRouter`            | [`0xee4d89b06fe9082fe9a737de2a5a061e07bef781`](https://sepolia-optimism.etherscan.io/address/0xee4d89b06fe9082fe9a737de2a5a061e07bef781#code) |

### Avalanche Fuji

| Contract                    | Address                                                                                                                              |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `AdapterRegistry`           | [`0xc0e11e92188743e37fed15f0c998ed1b9533fe01`](https://testnet.snowtrace.io/address/0xc0e11e92188743e37fed15f0c998ed1b9533fe01#code) |
| `ChildVault implementation` | [`0x512efe701404a637ccaca933028d0afe647cc0c4`](https://testnet.snowtrace.io/address/0x512efe701404a637ccaca933028d0afe647cc0c4#code) |
| `ChildVault proxy`          | [`0xcd6f007979bfb9f1ea9a9df432a298d0469861d3`](https://testnet.snowtrace.io/address/0xcd6f007979bfb9f1ea9a9df432a298d0469861d3#code) |
| `AaveV3Adapter`             | [`0x5f8191e9fe6b4164930cdf92f6fe824ae35602e0`](https://testnet.snowtrace.io/address/0x5f8191e9fe6b4164930cdf92f6fe824ae35602e0#code) |
| `AaveV4Adapter`             | [`0xd08c326be60fec778c69a0c14916b101ec40c4fa`](https://testnet.snowtrace.io/address/0xd08c326be60fec778c69a0c14916b101ec40c4fa#code) |
| `WorkflowRouter`            | [`0xdad87492a140283dc2c8b4a5a217a832bb31fbfe`](https://testnet.snowtrace.io/address/0xdad87492a140283dc2c8b4a5a217a832bb31fbfe#code) |

### Mock Protocols:

#### Arbitrum Sepolia

| Contract                             | Address                                                                                                                           |
| ------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------- |
| `TestnetAaveV3Pool`                  | [0x3742cc0150de6259557C3bda80997e035AFd47de](https://sepolia.arbiscan.io/address/0x3742cc0150de6259557C3bda80997e035AFd47de#code) |
| `TestnetAToken`                      | [0xD8c3e67e77e998AbcA7DC3EE7002BF1cc4728768](https://sepolia.arbiscan.io/address/0xD8c3e67e77e998AbcA7DC3EE7002BF1cc4728768#code) |
| `TestnetAaveV3PoolAddressesProvider` | [0x9A142D0c5113e51D5e454bE70437B8270ee2234F](https://sepolia.arbiscan.io/address/0x9A142D0c5113e51D5e454bE70437B8270ee2234F#code) |
| `TestnetComet`                       | [0x696957686787c4be72aa1bECb2d068150A6C7c21](https://sepolia.arbiscan.io/address/0x696957686787c4be72aa1bECb2d068150A6C7c21#code) |
| `TestnetCometRewards`                | [0xea4E6af732148c9E030b5bBb161cE236D9A9801D](https://sepolia.arbiscan.io/address/0xea4E6af732148c9E030b5bBb161cE236D9A9801D#code) |

The mocks use Arbitrum Sepolia native USDC (`0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d`)
and are owned by `0x7664C538C80870824738A8ADCcd92AcA244D7e69`.

#### Ethereum Sepolia

| Contract                             | Address                                                                                                                            |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| `TestnetAaveV3Pool`                  | [0x12bA5f2cc0f0f21A1B700A4C3eB6EA3862A33161](https://sepolia.etherscan.io/address/0x12bA5f2cc0f0f21A1B700A4C3eB6EA3862A33161#code) |
| `TestnetAToken`                      | [0x7e56c2f14a067646b2bc19bf6ef929174964239a](https://sepolia.etherscan.io/address/0x7e56c2f14a067646b2bc19bf6ef929174964239a#code) |
| `TestnetAaveV3PoolAddressesProvider` | [0x68A4c443995389849866cA350c0A623A4a17a416](https://sepolia.etherscan.io/address/0x68A4c443995389849866cA350c0A623A4a17a416#code) |
| `TestnetAaveV4Spoke`                 | [0x9267881460a43dA80512Ef5EE8c4CA61B1148CdB](https://sepolia.etherscan.io/address/0x9267881460a43dA80512Ef5EE8c4CA61B1148CdB#code) |
| `TestnetAaveV4Hub`                   | [0x3e059f52385e56afbacb09cdff424da51b05c9ff](https://sepolia.etherscan.io/address/0x3e059f52385e56afbacb09cdff424da51b05c9ff#code) |
| `TestnetComet`                       | [0x1b813d91D92dA0bF94c6cA4829E87DE325ABdD0c](https://sepolia.etherscan.io/address/0x1b813d91D92dA0bF94c6cA4829E87DE325ABdD0c#code) |
| `TestnetCometRewards`                | [0x165Aa383598cb93B1e2a0E8A429b4AC46Dadf3d5](https://sepolia.etherscan.io/address/0x165Aa383598cb93B1e2a0E8A429b4AC46Dadf3d5#code) |

#### Base Sepolia

| Contract                             | Address                                                                                                                            |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| `TestnetAaveV3Pool`                  | [0x165Aa383598cb93B1e2a0E8A429b4AC46Dadf3d5](https://sepolia.basescan.org/address/0x165Aa383598cb93B1e2a0E8A429b4AC46Dadf3d5#code) |
| `TestnetAToken`                      | [0x39b80d2f0f54c12b10646852a4baf9f970e89871](https://sepolia.basescan.org/address/0x39b80d2f0f54c12b10646852a4baf9f970e89871#code) |
| `TestnetAaveV3PoolAddressesProvider` | [0x0d6f1cb4340d6205B64b9c6DBB6E24AeF5b01e7a](https://sepolia.basescan.org/address/0x0d6f1cb4340d6205B64b9c6DBB6E24AeF5b01e7a#code) |
| `TestnetComet`                       | [0xcc6535CCb21f9ed8a0E593dDDCd1a6faC1D6474B](https://sepolia.basescan.org/address/0xcc6535CCb21f9ed8a0E593dDDCd1a6faC1D6474B#code) |
| `TestnetCometRewards`                | [0x63f8cfC8A7202e2Dc1f46B23D2043C7889796b3a](https://sepolia.basescan.org/address/0x63f8cfC8A7202e2Dc1f46B23D2043C7889796b3a#code) |

#### Optimism Sepolia

| Contract                             | Address                                                                                                                                     |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `TestnetAaveV3Pool`                  | [0xac9D87b3e309A201f287B2202D4b80e6750618C4](https://sepolia-optimism.etherscan.io/address/0xac9D87b3e309A201f287B2202D4b80e6750618C4#code) |
| `TestnetAToken`                      | [0xffb1eb87ca441d6a4f57e08eb70b0a2e165223d2](https://sepolia-optimism.etherscan.io/address/0xffb1eb87ca441d6a4f57e08eb70b0a2e165223d2#code) |
| `TestnetAaveV3PoolAddressesProvider` | [0x4577bdfB0fD75664586f03db266413A7609B7Baa](https://sepolia-optimism.etherscan.io/address/0x4577bdfB0fD75664586f03db266413A7609B7Baa#code) |
| `TestnetComet`                       | [0x5f8191e9FE6b4164930Cdf92F6fe824aE35602e0](https://sepolia-optimism.etherscan.io/address/0x5f8191e9FE6b4164930Cdf92F6fe824aE35602e0#code) |
| `TestnetCometRewards`                | [0xd08C326be60FEC778c69a0c14916B101EC40c4fA](https://sepolia-optimism.etherscan.io/address/0xd08C326be60FEC778c69a0c14916B101EC40c4fA#code) |

#### Avalanche Fuji

| Contract                             | Address                                                                                                                            |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| `TestnetAaveV3Pool`                  | [0xb606505AeEb4DFc2478A2AF5864E122105C44661](https://testnet.snowtrace.io/address/0xb606505AeEb4DFc2478A2AF5864E122105C44661#code) |
| `TestnetAToken`                      | [0x7a4e3123e953343dc22f8524c86f7c623398eb97](https://testnet.snowtrace.io/address/0x7a4e3123e953343dc22f8524c86f7c623398eb97#code) |
| `TestnetAaveV3PoolAddressesProvider` | [0xac9D87b3e309A201f287B2202D4b80e6750618C4](https://testnet.snowtrace.io/address/0xac9D87b3e309A201f287B2202D4b80e6750618C4#code) |
| `TestnetAaveV4Spoke`                 | [0x4577bdfB0fD75664586f03db266413A7609B7Baa](https://testnet.snowtrace.io/address/0x4577bdfB0fD75664586f03db266413A7609B7Baa#code) |
| `TestnetAaveV4Hub`                   | [0x2f7f81549dbf2042bb6d48ced03a31a334de90b4](https://testnet.snowtrace.io/address/0x2f7f81549dbf2042bb6d48ced03a31a334de90b4#code) |

#### Polygon Amoy

| Contract                             | Address                                                                                                                            |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| `TestnetAaveV3Pool`                  | [0x175b945FC2520c20f5E2cFee323f79BF29205913](https://amoy.polygonscan.com/address/0x175b945FC2520c20f5E2cFee323f79BF29205913#code) |
| `TestnetAToken`                      | [0x14449fdd4a9e50bcc450f928d6449472a72009f6](https://amoy.polygonscan.com/address/0x14449fdd4a9e50bcc450f928d6449472a72009f6#code) |
| `TestnetAaveV3PoolAddressesProvider` | [0xfee8D520E51c8e8cB157ACe638bE5Bc5899cD660](https://amoy.polygonscan.com/address/0xfee8D520E51c8e8cB157ACe638bE5Bc5899cD660#code) |

The pool uses native Amoy USDC (`0x41E94Eb019C0762f9Bfcf9Fb1E58725BfB0e7582`) and is owned by `0x7664C538C80870824738A8ADCcd92AcA244D7e69`.

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

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

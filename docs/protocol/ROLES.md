# Roles

## Actors

| Actor | Address |
| --- | --- |
| Administration multisig | `0x377a77807085675Bc8350a47eEE2F1DF457abFd7` |
| Operator | `0xD22f590FE47d4F9882C68c919bE295bC42013b50` |
| Emergency pauser 1 | `0x418feeaC792ABc3FB7f7A5a6a74c68C7C39e7C37` |
| Emergency pauser 2 | `0xfdC521A45b9036bd4b18DcE54De58C840C67fb0e` |
| Allowlist operator | `0xB0E03148B64D6695B429FFC72Ad0209A132bF196` |
| Independent timelock canceller | `0x56F48C7Edfca223D050E9AEfC6975C4c7d308416` |
| CRE workflow owner multisig | `0x9b418eDbFf04DaF89Db55D9E18Af2a0E23984636` |

## Timelocks

| Chain | Address |
| --- | --- |
| Base | `0xA5E772329CfE6fd6c463c5D2b77815C0213E8dd2` |
| Arbitrum | `0x4f412CA0158FD3DC78Aa92935258d6A444FDfD47` |
| Avalanche | `0x06411fd2Bb6f0b9AeA49054B3b01bEE5a234dCFb` |
| Ethereum | `0x2f866642a738951Fdf2578cDc66db3400C802b0e` |
| Optimism | `0x4f412CA0158FD3DC78Aa92935258d6A444FDfD47` |
| Polygon | `0x06411fd2Bb6f0b9AeA49054B3b01bEE5a234dCFb` |

Each timelock has a minimum delay of three days and administers the protocol contracts on its chain.

| Timelock role | Holder |
| --- | --- |
| `DEFAULT_ADMIN_ROLE` | Timelock itself |
| `PROPOSER_ROLE` | Administration multisig |
| `EXECUTOR_ROLE` | Administration multisig |
| `CANCELLER_ROLE` | Administration multisig and independent timelock canceller |

## Vaults

These roles apply to the ParentVault on Base and every ChildVault.

| Role | Holder |
| --- | --- |
| `DEFAULT_ADMIN_ROLE` | Local timelock |
| `UPGRADER_ROLE` | Local timelock |
| `PAUSER_ROLE` | Operator and both emergency pausers |
| `UNPAUSER_ROLE` | Operator |
| `CONFIG_OPERATOR_ROLE` | Operator |
| `REBALANCE_OPERATOR_ROLE` | Local WorkflowRouter |
| `EPOCH_OPERATOR_ROLE` | Local WorkflowRouter |
| `LINK_OPERATOR_ROLE` | Operator |
| `REWARDS_OPERATOR_ROLE` | Operator |

The ParentVault also has these roles:

| Role | Holder |
| --- | --- |
| `CANCEL_DEPOSIT_OPERATOR_ROLE` | Operator |
| `ALLOWLIST_OPERATOR_ROLE` | Operator and allowlist operator |

## Workflow routers

| Role | Holder |
| --- | --- |
| `DEFAULT_ADMIN_ROLE` | Local timelock |
| `PAUSER_ROLE` | Operator and both emergency pausers |
| `UNPAUSER_ROLE` | Operator |
| `CONFIG_OPERATOR_ROLE` | Operator |
| `KEYSTONE_FORWARDER_ROLE` | Chainlink Keystone Forwarder for the local chain |

### Keystone Forwarders

| Chain | Address |
| --- | --- |
| Base | `0xF8344CFd5c43616a4366C34E3EEE75af79a74482` |
| Arbitrum | `0xF8344CFd5c43616a4366C34E3EEE75af79a74482` |
| Avalanche | `0x76c9cf548b4179F8901cda1f8623568b58215E62` |
| Ethereum | `0x0b93082D9b3C7C97fAcd250082899BAcf3af3885` |
| Optimism | `0xF8344CFd5c43616a4366C34E3EEE75af79a74482` |
| Polygon | `0x76c9cf548b4179F8901cda1f8623568b58215E62` |

## Adapter registries

| Role | Holder |
| --- | --- |
| `DEFAULT_ADMIN_ROLE` | Local timelock |
| `CONFIG_OPERATOR_ROLE` | Operator |

## Yieldcoin share

These roles apply to the Yieldcoin share token on Base.

| Role | Holder |
| --- | --- |
| `DEFAULT_ADMIN_ROLE` | Base timelock |
| `UPGRADER_ROLE` | Base timelock |
| `PAUSER_ROLE` | Operator |
| `UNPAUSER_ROLE` | Operator |
| `CONFIG_OPERATOR_ROLE` | Operator |
| `MINTER_ROLE` | ParentVault |
| `BURNER_ROLE` | ParentVault |

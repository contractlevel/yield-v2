// @review doc - write upgrade playbook

epoch and rebalance nonce in parent initialize should NOT be set to 1 again if upgrading

https://www.zealynx.io/research/smart-contracts/proxy-upgradeability-security-checklist

nonReentrant initializer

For UUPS proxies, verify new implementation includes correct proxiableUUID() and upgrade functions

storage layout validation in upgrade process

---

vaults.UPGRADER_ROLE and yieldcoinShare.owner should be granted to OZ timelock contract

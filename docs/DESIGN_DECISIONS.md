1. all events have 3 params, and each is indexed for certora fv

2. recovery modes are permissionless

3. parent vault (and some base vault) logic split into libs to reduce bytesize

4. completeRebalance, recoverFailedRebalanceDeposit omit whenNotPaused because we want to allow the completion of rebalances already in progress

5. completeRebalance does not depend on inbound ccip message because it can be completed by CRE

6. closeEpoch does not sanity check operator supplied tvl against actual tvl. closeEpoch is called by CRE workflow(router) and this is consistent with the tvl provided from other chains

7. closeEpoch DoS when local aave or compound reverts. CRE workflow can retry.

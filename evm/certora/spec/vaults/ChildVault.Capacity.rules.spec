import "ChildVaultCommon.rules.spec";

using MockCCIPSendCapacityRouter as ccipRouter;
using MockChildVaultCapacityCaller as capacityCaller;

methods {
    function ccipRouter.getFee() external returns (uint256) envfree;
    function ccipRouter.getFeeReverts() external returns (bool) envfree;
    function ccipRouter.ccipSendReverts() external returns (bool) envfree;
    function ccipRouter.capacityError() external returns (bool) envfree;
    function ccipRouter.getLastMessageDataHash() external returns (bytes32) envfree;
    function capacityCaller.expectedCapacityError() external returns (bytes) envfree;
    function capacityCaller.captureRouterSend(uint64, Client.EVM2AnyMessage) external returns (bool, bytes);
    function capacityCaller.captureVaultSend(uint256, uint64, Types.CcipTx, uint256, bytes32)
        external returns (bool, bytes);
    function capacityCaller.captureEpochWithdraw(uint256, uint256) external returns (bool, bytes);
    function capacityCaller.captureRebalance(uint256, Types.Strategy) external returns (bool, bytes);
    function capacityCaller.captureRecovery() external returns (bool, bytes);
}

/// @notice The router fixture emits the exact native capacity error.
/// @dev Checks the selector and all three ABI arguments independently of the vault.
rule CCIP_005_routerSend_EmitsExactCapacityError() {
    env e;
    uint64 destinationChainSelector;
    Client.EVM2AnyMessage message;
    require e.msg.value == 0, "capture call is nonpayable";
    require message.receiver.length == 0;
    require message.data.length == 0;
    require message.extraArgs.length == 0;
    require message.tokenAmounts.length == 0;

    bytes expectedReason = capacityCaller.expectedCapacityError();
    storage before = lastStorage;
    bool reverted;
    bytes actualReason;
    (reverted, actualReason) = capacityCaller.captureRouterSend(e, destinationChainSelector, message);

    assert reverted;
    assert actualReason.length == 100, "capacity error contains a selector and three ABI arguments";
    assert hashBytes(actualReason) == hashBytes(expectedReason), "router emits the exact expected error";
    assert before[ccipRouter] == lastStorage[ccipRouter];
}

/// @notice The real ChildVault catch bubbles the exact router error and rolls back the send.
rule CCIP_005_ccipSend_BubblesExactCapacityError() {
    env e;
    uint256 bridgeAmount;
    uint64 destinationChainSelector;
    Types.CcipTx ccipTxType;
    uint256 nonce;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getCcipSendRecoveryNonce() == 0 && getCcipSendRecoveryProtocolId() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require bridgeAmount != 0, "bridge amount should not be zero";
    require destinationChainSelector != 0, "destination chain selector should not be zero";
    require destinationChainSelector != getThisChainSelector(), "destination should not be this chain";
    require getCrosschainVault(destinationChainSelector) != 0, "destination vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";

    /// @dev failure condition being verified
    require ccipRouter.capacityError(), "router emits the token capacity error";
    require ccipRouter.ccipSendReverts(), "router send should revert";

    /// @dev set ghost starting values
    require ghost_CCIPBridged_EventCount == 0;
    require ghost_CcipSendRecoveryStored_EventCount == 0;
    require ghost_ccipSendRecovery_amount_StoreCount == 0;
    require ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 0;
    require ghost_ccipSendRecovery_nonce_StoreCount == 0;
    require ghost_ccipSendRecovery_protocolId_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;

    /// @dev Exclude approval and token-transfer failures regardless of call order.
    require link.balanceOf(currentContract) >= 1, "vault LINK balance covers the mock fee";
    require link.balanceOf(ccipRouter) < max_uint256, "router LINK balance does not overflow";
    require asset.balanceOf(ccipRouter) <= max_uint256 - bridgeAmount,
        "router asset balance does not overflow";

    require asset.balanceOf(currentContract) >= bridgeAmount, "vault assets cover the send";

    storage before = lastStorage;

    bytes expectedReason = capacityCaller.expectedCapacityError();
    bool reverted;
    bytes actualReason;
    (reverted, actualReason) = capacityCaller.captureVaultSend(
        e, bridgeAmount, destinationChainSelector, ccipTxType, nonce, protocolId
    );

    assert reverted;
    assert actualReason.length == 100, "capacity error contains a selector and three ABI arguments";
    assert hashBytes(actualReason) == hashBytes(expectedReason), "vault preserves the exact capacity error";
    assert before[currentContract] == lastStorage[currentContract];
    assert before[adapter] == lastStorage[adapter];
    assert before[asset] == lastStorage[asset];
    assert before[link] == lastStorage[link];
    assert before[ccipRouter] == lastStorage[ccipRouter];
    assert ghost_CCIPBridged_EventCount == 0;
    assert ghost_CcipSendRecoveryStored_EventCount == 0;
    assert ghost_ccipSendRecovery_amount_StoreCount == 0;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 0;
    assert ghost_ccipSendRecovery_nonce_StoreCount == 0;
    assert ghost_ccipSendRecovery_protocolId_StoreCount == 0;
    assert ghost_recoveryMode_StoreCount == 0;
}


/// @notice A capacity error reverts the entire operation with the exact router payload.
/// @dev Verifies vault, adapter, token, router, nonce, recovery, and event rollback.
rule CCIP_005_NONCE_005_NONCE_006_REC_002_REC_009_executeEpochWithdraw_RevertWhen_RouterCcipSendCapacityExceeded() {
    env e;
    uint256 epochNonce;
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require ghost_lastHandledEpochNonce_StoreCount == 0,
        "handled epoch nonce store count starts at zero";
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), capacityCaller);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getCcipSendRecoveryNonce() == 0 && getCcipSendRecoveryProtocolId() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require amount != 0, "amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() > 0, "adapter withdraw should return a nonzero amount";
    require getCrosschainVault(getParentChainSelector()) != 0, "parent vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require currentContract.i_parentChainSelector != 0 && currentContract.i_parentChainSelector != currentContract.i_thisChainSelector,
        "destination selector should be valid";

    /// @dev failure condition being verified
    require ccipRouter.capacityError(), "router emits the token capacity error";
    require ccipRouter.ccipSendReverts(), "router send should revert";

    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();
    address router = getRouter();
    uint256 amountOut = amount > adapterTVLBefore ? adapterTVLBefore : amount;

    /// @dev mock token arithmetic conditions
    require amountOut <= adapterAssetBalanceBefore, "adapter asset balance should cover the withdrawn amount";
    require vaultAssetBalanceBefore <= max_uint256 - amountOut, "vault asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_WithdrawFromStrategySuccess_EventCount == 0;
    require ghost_WithdrawFromStrategyFailure_EventCount == 0;
    require ghost_EpochWithdrawRecoveryStored_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;
    require ghost_CcipSendRecoveryStored_EventCount == 0;
    require ghost_ccipSendRecovery_amount_StoreCount == 0;
    require ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 0;
    require ghost_ccipSendRecovery_nonce_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;

    /// @dev Exclude approval and token-transfer failures regardless of call order.
    require link.balanceOf(currentContract) >= 1, "vault LINK balance covers the mock fee";
    require link.balanceOf(ccipRouter) < max_uint256, "router LINK balance does not overflow";
    require asset.balanceOf(ccipRouter) <= max_uint256 - amountOut,
        "router asset balance does not overflow";

    bytes expectedReason = capacityCaller.expectedCapacityError();
    bool reverted;
    bytes actualReason;

    storage before = lastStorage;

    (reverted, actualReason) = capacityCaller.captureEpochWithdraw(e, epochNonce, amount);

    assert reverted;
    assert actualReason.length == 100, "capacity error contains a selector and three ABI arguments";
    assert hashBytes(actualReason) == hashBytes(expectedReason), "operation preserves the exact capacity error";
    assert before[currentContract] == lastStorage[currentContract];
    assert before[adapter] == lastStorage[adapter];
    assert before[asset] == lastStorage[asset];
    assert before[link] == lastStorage[link];
    assert before[ccipRouter] == lastStorage[ccipRouter];
    assert ghost_lastHandledEpochNonce_StoreCount == 0;
    assert ghost_WithdrawFromStrategySuccess_EventCount == 0;
    assert ghost_WithdrawFromStrategyFailure_EventCount == 0;
    assert ghost_EpochWithdrawRecoveryStored_EventCount == 0;
    assert ghost_CCIPBridged_EventCount == 0;
    assert ghost_CcipSendRecoveryStored_EventCount == 0;
    assert ghost_ccipSendRecovery_amount_StoreCount == 0;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 0;
    assert ghost_ccipSendRecovery_nonce_StoreCount == 0;
    assert ghost_recoveryMode_StoreCount == 0;
}

/// @notice A capacity error reverts the entire operation with the exact router payload.
/// @dev Verifies vault, adapter, token, router, nonce, recovery, and event rollback.
rule CCIP_005_REC_001_REC_002_REC_004_REC_009_executeRecovery_REBALANCE_WITHDRAW_Remote_RevertWhen_RouterCcipSendCapacityExceeded() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_WITHDRAW, "rebalance withdraw recovery should be pending";
    require getCcipSendRecoveryNonce() == 0 && getCcipSendRecoveryProtocolId() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    Types.RebalanceWithdrawRecovery recovery = getRebalanceWithdrawRecovery();
    require recovery.strategy.chainSelector != 0, "target chain selector should not be zero";
    require recovery.strategy.chainSelector != getThisChainSelector(), "target strategy should be remote";
    require getCrosschainVault(recovery.strategy.chainSelector) != 0, "target vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";

    /// @dev failure condition being verified
    require ccipRouter.capacityError(), "router emits the token capacity error";
    require ccipRouter.ccipSendReverts(), "router send should revert";

    uint256 amountRebalanced = adapter.getTVL();
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    address router = getRouter();

    /// @dev mock token arithmetic conditions
    require amountRebalanced != 0, "adapter withdraw should return a nonzero amount";
    require amountRebalanced <= adapterBalanceBefore, "adapter asset balance should cover the withdrawal";
    require vaultBalanceBefore <= max_uint256 - amountRebalanced, "vault asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_RebalanceWithdrawRecoveryCleared_EventCount == 0;
    require ghost_RebalanceWithdrawSuccess_EventCount == 0;
    require ghost_ActiveProtocolAdapterCleared_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;
    require ghost_CcipSendRecoveryStored_EventCount == 0;
    require ghost_ccipSendRecovery_amount_StoreCount == 0;
    require ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 0;
    require ghost_ccipSendRecovery_nonce_StoreCount == 0;
    require ghost_ccipSendRecovery_protocolId_StoreCount == 0;
    require ghost_rebalanceWithdrawRecovery_rebalanceNonce_StoreCount == 0;
    require ghost_rebalanceWithdrawRecovery_protocolId_StoreCount == 0;
    require ghost_rebalanceWithdrawRecovery_chainSelector_StoreCount == 0;
    require ghost_activeProtocolAdapter_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;

    /// @dev Exclude approval and token-transfer failures regardless of call order.
    require link.balanceOf(currentContract) >= 1, "vault LINK balance covers the mock fee";
    require link.balanceOf(ccipRouter) < max_uint256, "router LINK balance does not overflow";
    require asset.balanceOf(ccipRouter) <= max_uint256 - amountRebalanced,
        "router asset balance does not overflow";

    bytes expectedReason = capacityCaller.expectedCapacityError();
    bool reverted;
    bytes actualReason;

    storage before = lastStorage;

    (reverted, actualReason) = capacityCaller.captureRecovery(e);

    assert reverted;
    assert actualReason.length == 100, "capacity error contains a selector and three ABI arguments";
    assert hashBytes(actualReason) == hashBytes(expectedReason), "operation preserves the exact capacity error";
    assert before[currentContract] == lastStorage[currentContract];
    assert before[adapter] == lastStorage[adapter];
    assert before[asset] == lastStorage[asset];
    assert before[link] == lastStorage[link];
    assert before[ccipRouter] == lastStorage[ccipRouter];
    assert ghost_RebalanceWithdrawRecoveryCleared_EventCount == 0;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 0;
    assert ghost_ActiveProtocolAdapterCleared_EventCount == 0;
    assert ghost_CCIPBridged_EventCount == 0;
    assert ghost_CcipSendRecoveryStored_EventCount == 0;
    assert ghost_ccipSendRecovery_amount_StoreCount == 0;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 0;
    assert ghost_ccipSendRecovery_nonce_StoreCount == 0;
    assert ghost_ccipSendRecovery_protocolId_StoreCount == 0;
    assert ghost_rebalanceWithdrawRecovery_rebalanceNonce_StoreCount == 0;
    assert ghost_rebalanceWithdrawRecovery_protocolId_StoreCount == 0;
    assert ghost_rebalanceWithdrawRecovery_chainSelector_StoreCount == 0;
    assert ghost_activeProtocolAdapter_StoreCount == 0;
    assert ghost_recoveryMode_StoreCount == 0;
}

/// @notice A capacity error reverts the entire operation with the exact router payload.
/// @dev Verifies vault, adapter, token, router, nonce, recovery, and event rollback.
rule CCIP_005_NONCE_005_NONCE_006_REC_002_REC_009_executeRebalance_Remote_RevertWhen_RouterCcipSendCapacityExceeded() {
    env e;
    uint256 rebalanceNonce;
    require rebalanceNonce > getLastHandledRebalanceNonce(), "rebalance nonce should be new";
    require ghost_lastHandledRebalanceNonce_StoreCount == 0,
        "handled rebalance nonce store count starts at zero";
    Types.Strategy newStrategy;

    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), capacityCaller);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getCcipSendRecoveryNonce() == 0 && getCcipSendRecoveryProtocolId() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require newStrategy.chainSelector != 0, "target chain selector should not be zero";
    require newStrategy.chainSelector != getThisChainSelector(), "target strategy should be remote";
    require getCrosschainVault(newStrategy.chainSelector) != 0, "target vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";

    /// @dev failure condition being verified
    require ccipRouter.capacityError(), "router emits the token capacity error";
    require ccipRouter.ccipSendReverts(), "router send should revert";

    uint256 amountRebalanced = adapter.getTVL();
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    address router = getRouter();
    require amountRebalanced > 0, "adapter withdraw should return a nonzero amount";
    require amountRebalanced <= adapterBalanceBefore, "adapter balance should cover the withdrawal";
    require vaultBalanceBefore <= max_uint256 - amountRebalanced, "vault balance should not overflow";

    require ghost_RebalanceWithdrawSuccess_EventCount == 0;
    require ghost_ActiveProtocolAdapterCleared_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;
    require ghost_CcipSendRecoveryStored_EventCount == 0;
    require ghost_activeProtocolAdapter_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;
    require ghost_ccipSendRecovery_amount_StoreCount == 0;
    require ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 0;
    require ghost_ccipSendRecovery_nonce_StoreCount == 0;
    require ghost_ccipSendRecovery_protocolId_StoreCount == 0;

    /// @dev Exclude approval and token-transfer failures regardless of call order.
    require link.balanceOf(currentContract) >= 1, "vault LINK balance covers the mock fee";
    require link.balanceOf(ccipRouter) < max_uint256, "router LINK balance does not overflow";
    require asset.balanceOf(ccipRouter) <= max_uint256 - amountRebalanced,
        "router asset balance does not overflow";

    bytes expectedReason = capacityCaller.expectedCapacityError();
    bool reverted;
    bytes actualReason;

    storage before = lastStorage;

    (reverted, actualReason) = capacityCaller.captureRebalance(e, rebalanceNonce, newStrategy);

    assert reverted;
    assert actualReason.length == 100, "capacity error contains a selector and three ABI arguments";
    assert hashBytes(actualReason) == hashBytes(expectedReason), "operation preserves the exact capacity error";
    assert before[currentContract] == lastStorage[currentContract];
    assert before[adapter] == lastStorage[adapter];
    assert before[asset] == lastStorage[asset];
    assert before[link] == lastStorage[link];
    assert before[ccipRouter] == lastStorage[ccipRouter];
    assert ghost_lastHandledRebalanceNonce_StoreCount == 0;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 0;
    assert ghost_ActiveProtocolAdapterCleared_EventCount == 0;
    assert ghost_CCIPBridged_EventCount == 0;
    assert ghost_CcipSendRecoveryStored_EventCount == 0;
    assert ghost_activeProtocolAdapter_StoreCount == 0;
    assert ghost_recoveryMode_StoreCount == 0;
    assert ghost_ccipSendRecovery_amount_StoreCount == 0;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 0;
    assert ghost_ccipSendRecovery_nonce_StoreCount == 0;
    assert ghost_ccipSendRecovery_protocolId_StoreCount == 0;
}

/// @notice A capacity error reverts the entire operation with the exact router payload.
/// @dev Verifies vault, adapter, token, router, nonce, recovery, and event rollback.
rule CCIP_005_REC_001_REC_002_REC_004_REC_009_executeRecovery_EPOCH_WITHDRAW_RevertWhen_RouterCcipSendCapacityExceeded() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.EPOCH_WITHDRAW, "epoch withdraw recovery should be pending";
    require getCcipSendRecoveryNonce() == 0 && getCcipSendRecoveryProtocolId() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() > 0, "adapter withdraw should return a nonzero amount";
    require getCrosschainVault(getParentChainSelector()) != 0, "parent vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require currentContract.i_parentChainSelector != 0 && currentContract.i_parentChainSelector != currentContract.i_thisChainSelector,
        "destination selector should be valid";

    /// @dev failure condition being verified
    require ccipRouter.capacityError(), "router emits the token capacity error";
    require ccipRouter.ccipSendReverts(), "router send should revert";

    Types.EpochRecovery recovery = getEpochWithdrawRecovery();
    uint256 adapterTVLBefore = adapter.getTVL();
    uint256 amountOut = recovery.amount > adapterTVLBefore ? adapterTVLBefore : recovery.amount;
    address router = getRouter();
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);

    /// @dev mock token arithmetic conditions
    require recovery.amount != 0, "recovery amount should not be zero";
    require amountOut != 0, "withdraw amount out should not be zero";
    require amountOut <= adapterAssetBalanceBefore, "adapter asset balance should cover the withdrawn amount";
    require vaultAssetBalanceBefore <= max_uint256 - amountOut, "vault asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_EpochWithdrawRecoveryCleared_EventCount == 0;
    require ghost_WithdrawFromStrategySuccess_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;
    require ghost_CcipSendRecoveryStored_EventCount == 0;
    require ghost_epochWithdrawRecovery_epochNonce_StoreCount == 0;
    require ghost_epochWithdrawRecovery_amount_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;
    require ghost_ccipSendRecovery_amount_StoreCount == 0;
    require ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 0;
    require ghost_ccipSendRecovery_nonce_StoreCount == 0;
    require ghost_ccipSendRecovery_protocolId_StoreCount == 0;

    /// @dev Exclude approval and token-transfer failures regardless of call order.
    require link.balanceOf(currentContract) >= 1, "vault LINK balance covers the mock fee";
    require link.balanceOf(ccipRouter) < max_uint256, "router LINK balance does not overflow";
    require asset.balanceOf(ccipRouter) <= max_uint256 - amountOut,
        "router asset balance does not overflow";

    bytes expectedReason = capacityCaller.expectedCapacityError();
    bool reverted;
    bytes actualReason;

    storage before = lastStorage;

    (reverted, actualReason) = capacityCaller.captureRecovery(e);

    assert reverted;
    assert actualReason.length == 100, "capacity error contains a selector and three ABI arguments";
    assert hashBytes(actualReason) == hashBytes(expectedReason), "operation preserves the exact capacity error";
    assert before[currentContract] == lastStorage[currentContract];
    assert before[adapter] == lastStorage[adapter];
    assert before[asset] == lastStorage[asset];
    assert before[link] == lastStorage[link];
    assert before[ccipRouter] == lastStorage[ccipRouter];
    assert ghost_EpochWithdrawRecoveryCleared_EventCount == 0;
    assert ghost_WithdrawFromStrategySuccess_EventCount == 0;
    assert ghost_CCIPBridged_EventCount == 0;
    assert ghost_CcipSendRecoveryStored_EventCount == 0;
    assert ghost_epochWithdrawRecovery_epochNonce_StoreCount == 0;
    assert ghost_epochWithdrawRecovery_amount_StoreCount == 0;
    assert ghost_recoveryMode_StoreCount == 0;
    assert ghost_ccipSendRecovery_amount_StoreCount == 0;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 0;
    assert ghost_ccipSendRecovery_nonce_StoreCount == 0;
    assert ghost_ccipSendRecovery_protocolId_StoreCount == 0;
}

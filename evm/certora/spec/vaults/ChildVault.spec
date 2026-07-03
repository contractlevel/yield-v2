using MockAdapterRegistry as adapterRegistry;
using MockProtocolAdapter as adapter;
using MockProtocolAdapter as targetAdapter;
using MockInvalidProtocolAdapter as invalidAdapter;
using MockUSDC as asset;
using MockLINK as link;
using MockCCIPRouter as ccipRouter;

/// Verification of ChildVault-specific behavior
/// @author @contractlevel
/// @notice ChildVault interacts with strategy protocols on its own chain, and Parent and other Child Vaults via CCIP.
/// @notice Shared BaseVault behavior is verified separately in BaseVault.spec.

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    /*//////////////////////////////////////////////////////////////
                         CHILDVAULT ENTRY POINTS
    //////////////////////////////////////////////////////////////*/
    function initialize(BaseVault.InitParams) external;
    function ccipReceive(Client.Any2EVMMessage) external;
    function ccipSend(uint256, uint64, Types.CcipTx, bytes) external;
    function tryCcipSend(uint256, uint64, Types.CcipTx, bytes) external;
    function tryDepositToAdapter(address, uint256) external;
    function executeEpochWithdraw(uint256, uint256) external;
    function executeRebalance(uint256, Types.Strategy) external;
    function recoverFailedEpochDeposit() external;
    function recoverFailedEpochWithdraw() external;
    function recoverFailedRebalanceWithdraw() external;
    function recoverFailedRebalanceDeposit() external;
    function recoverFailedCcipSend() external;

    /*//////////////////////////////////////////////////////////////
                             GETTERS
    //////////////////////////////////////////////////////////////*/
    function getParentChainSelector() external returns (uint64) envfree;
    function getEpochDepositRecovery() external returns (Types.EpochRecovery) envfree;
    function getEpochWithdrawRecovery() external returns (Types.EpochRecovery) envfree;
    function getRebalanceWithdrawRecovery() external returns (Types.RebalanceWithdrawRecovery) envfree;
    function getCcipSendRecovery() external returns (Types.CcipSendRecovery) envfree;
    function getCcipSendRecoveryTxType() external returns (Types.CcipTx) envfree;
    function getCcipSendRecoveryAmount() external returns (uint256) envfree;
    function getCcipSendRecoveryDestinationChainSelector() external returns (uint64) envfree;
    function getCcipSendRecoveryCreatedAt() external returns (uint256) envfree;
    function getCcipSendRecoveryTxData() external returns (bytes) envfree;
    function getCcipSendRecoveryTxDataStorageSlot() external returns (bytes32) envfree;
    function getRebalanceDepositRecovery() external returns (Types.RebalanceDepositRecovery) envfree;
    function getRecoveryMode() external returns (Types.RecoveryMode) envfree;
    function getActiveProtocolAdapter() external returns (address) envfree;
    function getThisChainSelector() external returns (uint64) envfree;
    function getCrosschainVault(uint64) external returns (address) envfree;
    function getCcipGasLimit(uint64) external returns (uint256) envfree;
    function getTVL() external returns (uint256) envfree;
    function getRouter() external returns (address) envfree;
    function getAsset() external returns (address) envfree;
    function getLink() external returns (address) envfree;

    /*//////////////////////////////////////////////////////////////
                       LINKED CONTRACT GETTERS
    //////////////////////////////////////////////////////////////*/
    function asset.balanceOf(address) external returns (uint256) envfree;
    function link.balanceOf(address) external returns (uint256) envfree;
    function adapter.getTVL() external returns (uint256) envfree;
    function adapter.getVault() external returns (address) envfree;
    function targetAdapter.getTVL() external returns (uint256) envfree;
    function targetAdapter.getVault() external returns (address) envfree;
    function invalidAdapter.getVault() external returns (address) envfree;
    function adapter.depositReverts() external returns (bool) envfree;
    function adapter.withdrawReverts() external returns (bool) envfree;
    function targetAdapter.depositReverts() external returns (bool) envfree;
    function ccipRouter.getFee() external returns (uint256) envfree;
    function ccipRouter.getFeeReverts() external returns (bool) envfree;
    function ccipRouter.ccipSendReverts() external returns (bool) envfree;
    // function adapterRegistry.getAdapter(bytes32) external returns (address) envfree;

    /*//////////////////////////////////////////////////////////////
                           ACCESS CONTROL
    //////////////////////////////////////////////////////////////*/
    function hasRole(bytes32, address) external returns (bool) envfree;
    function EPOCH_OPERATOR_ROLE() external returns (bytes32) envfree;
    function REBALANCE_OPERATOR_ROLE() external returns (bytes32) envfree;

    /*//////////////////////////////////////////////////////////////
                         HARNESS HELPERS
    //////////////////////////////////////////////////////////////*/
    function reentrancyGuardEntered() external returns (bool) envfree;
    function bytes32ToAddress(bytes32) external returns (address) envfree;
    function bytes32ToUint256(bytes32) external returns (uint256) envfree;
    function bytes32ToUint64(bytes32) external returns (uint64) envfree;
    function bytes32ToUint8(bytes32) external returns (uint8) envfree;
    function uint8ToCcipTxType(uint8) external returns (Types.CcipTx) envfree;
    function isInitialized() external returns (bool) envfree;
    function encodeAddress(address) external returns (bytes) envfree;
    function encodeEpochNonce(uint256) external returns (bytes) envfree;
    function encodeRebalanceData(uint256, bytes32) external returns (bytes) envfree;
    function encodeCcipTxData(Types.CcipTx, bytes) external returns (bytes) envfree;
    function encodeRawCcipTxData(uint256, bytes) external returns (bytes) envfree;
    function decodeCcipTxType(bytes) external returns (Types.CcipTx) envfree;
    function decodeCcipTxPayload(bytes) external returns (bytes) envfree;

    /*//////////////////////////////////////////////////////////////
                         DISPATCHER SUMMARIES
    //////////////////////////////////////////////////////////////*/
    function _.transfer(address, uint256) external => DISPATCHER(true);
    function _.transferFrom(address, address, uint256) external => DISPATCHER(true);
    function _.balanceOf(address) external => DISPATCHER(true);
    function _.approve(address, uint256) external => DISPATCHER(true);
    function _.forceApprove(address, uint256) external => DISPATCHER(true);
    function _.deposit(uint256) external => DISPATCHER(true);
    function _.withdraw(uint256) external => DISPATCHER(true);
    function _.getTVL() external => DISPATCHER(true);
    function _.getVault() external => DISPATCHER(true);
    function _.getAsset() external => DISPATCHER(true);
    function _.getAdapter(bytes32) external => DISPATCHER(true);
    function _.getFee(uint64, Client.EVM2AnyMessage) external => DISPATCHER(true);
    function _.ccipSend(uint64, Client.EVM2AnyMessage) external => DISPATCHER(true);
}

/*//////////////////////////////////////////////////////////////
                         DEFINITIONS
//////////////////////////////////////////////////////////////*/
definition EpochDepositRecoveryStoredEvent() returns bytes32 =
// keccak256("EpochDepositRecoveryStored(uint256,uint256)")
    to_bytes32(0x6985100e96bcd0c1720ec939d9dc621afeaf8d0ff9ef1e037aed1aa435c78309);

definition EpochDepositRecoveryClearedEvent() returns bytes32 =
// keccak256("EpochDepositRecoveryCleared(uint256)")
    to_bytes32(0xfdbd409908832cd88b4e365485ac43234524771b7f3d76035e67238020fa2214);

definition EpochWithdrawRecoveryStoredEvent() returns bytes32 =
// keccak256("EpochWithdrawRecoveryStored(uint256,uint256)")
    to_bytes32(0xe98ad4f22d3e907748f0c3ff471dd84e546dbdd41337b79a48a46464eecc16ac);

definition EpochWithdrawRecoveryClearedEvent() returns bytes32 =
// keccak256("EpochWithdrawRecoveryCleared(uint256)")
    to_bytes32(0x9e32833d5a2e5d61de7066162eeb050b31893b65e85c4762099b26293a53b60b);

definition RebalanceWithdrawRecoveryStoredEvent() returns bytes32 =
// keccak256("RebalanceWithdrawRecoveryStored(uint256,bytes32,uint64)")
    to_bytes32(0xb88a5725563918075a03a03c81c4b622aac1b91801d1f978f96528c1036b5a4c);

definition RebalanceWithdrawRecoveryClearedEvent() returns bytes32 =
// keccak256("RebalanceWithdrawRecoveryCleared(uint256)")
    to_bytes32(0xf9ef918deae43921948a02965bca7aa79c4ebfdaf63843745c8e048b2f2a6d0f);

definition CcipSendRecoveryStoredEvent() returns bytes32 =
// keccak256("CcipSendRecoveryStored(uint8,uint64,uint256)")
    to_bytes32(0xaf3d02631aab34fcdae0c6a4eb28c12d169508dc9f59daef14147c56c0ef1615);

definition CcipSendRecoveryClearedEvent() returns bytes32 =
// keccak256("CcipSendRecoveryCleared(uint8,uint64,uint256)")
    to_bytes32(0xce718a4b1be47c1b43b083b936720c3b2c16bad5577d1da8a3888791ac294991);

definition CCIPBridgedEvent() returns bytes32 =
// keccak256("CCIPBridged(bytes32,uint256,uint8)")
    to_bytes32(0x39e716d942b34d57d78c584f648ec8e13b9621c6e5b1a57d18ef47a98b11b39d);

definition DepositToStrategySuccessEvent() returns bytes32 =
// keccak256("DepositToStrategySuccess(uint256,uint256)")
    to_bytes32(0x822db7c313fcf6d7b9ea5da5e0e6f3d27317446731e4016faa07a1127bb0a1c4);

definition DepositToStrategyFailureEvent() returns bytes32 =
// keccak256("DepositToStrategyFailure(uint256,uint256)")
    to_bytes32(0xe793c4fcefcfc6be38155702c97e12901a8434f945b26921d530968edb0ef0e9);

definition WithdrawFromStrategySuccessEvent() returns bytes32 =
// keccak256("WithdrawFromStrategySuccess(uint256,uint256)")
    to_bytes32(0xb38981e8f1428114c35ad63ef9ab14a90a34bc12cac0782d420baab4522a659f);

definition ActiveProtocolAdapterSetEvent() returns bytes32 =
// keccak256("ActiveProtocolAdapterSet(bytes32,address)")
    to_bytes32(0xf3628f0443ba881ea4c9543ca1d28250e78f2e019fffe8a8e722378625dcf598);

definition ActiveProtocolAdapterClearedEvent() returns bytes32 =
// keccak256("ActiveProtocolAdapterCleared(address)")
    to_bytes32(0x965689b74a63affbd22afb2528d6f7c11a4d1d2850b0f0cc8f647992386bf04f);

definition RebalanceDepositSuccessEvent() returns bytes32 =
// keccak256("RebalanceDepositSuccess(uint256,uint256)")
    to_bytes32(0x2db49c393972e05db516ff3191339f00472c21c0c8a0dba6cdc7fdcc60cc0f7f);

definition RebalanceDepositFailureEvent() returns bytes32 =
// keccak256("RebalanceDepositFailure(uint256,uint256)")
    to_bytes32(0xaf33555f3c66bb0a023d6b759e182afe00eb0b37fa2bbb17ad7d1f7618eb0e7c);

definition RebalanceDepositRecoveryStoredEvent() returns bytes32 =
// keccak256("RebalanceDepositRecoveryStored(uint256,uint256)")
    to_bytes32(0x4bbae92bb9743ae03720831d3ae066b9d8f88479d38633dac2ca5e8109b83894);

definition RebalanceDepositRecoveryClearedEvent() returns bytes32 =
// keccak256("RebalanceDepositRecoveryCleared(uint256)")
    to_bytes32(0xfd0affe04f47c983df51f211349e202dc404654e6851f1ad16dc04aa5c683e6f);

definition WithdrawFromStrategyFailureEvent() returns bytes32 =
// keccak256("WithdrawFromStrategyFailure(uint256,uint256)")
    to_bytes32(0x37f4f811d10c7b3a19d28781f245b42c5320a1736a27b2b43b34f9360c760e38);

definition RebalanceWithdrawSuccessEvent() returns bytes32 =
// keccak256("RebalanceWithdrawSuccess(uint256,uint256)")
    to_bytes32(0xbda9c2bb85185244245a5c12fdd1e1107c46dc54a6d54d015bccf78aec5a8668);

definition RebalanceWithdrawFailureEvent() returns bytes32 =
// keccak256("RebalanceWithdrawFailure(uint256)")
    to_bytes32(0x419b356601ce305e332b89009cbc4ec088b901dadd6b8a6e19ee038183ff64e6);

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
/// ─── s_rebalanceWithdrawRecovery.rebalanceNonce ─────────────
ghost mathint ghost_rebalanceWithdrawRecovery_rebalanceNonce_StoreCount { init_state axiom ghost_rebalanceWithdrawRecovery_rebalanceNonce_StoreCount == 0; }
ghost uint256  ghost_rebalanceWithdrawRecovery_rebalanceNonce_StoredValue { init_state axiom ghost_rebalanceWithdrawRecovery_rebalanceNonce_StoredValue == 0; }

/// ─── s_rebalanceWithdrawRecovery.strategy.protocolId ────────
ghost mathint ghost_rebalanceWithdrawRecovery_protocolId_StoreCount { init_state axiom ghost_rebalanceWithdrawRecovery_protocolId_StoreCount == 0; }
ghost bytes32  ghost_rebalanceWithdrawRecovery_protocolId_StoredValue { init_state axiom ghost_rebalanceWithdrawRecovery_protocolId_StoredValue == to_bytes32(0); }

/// ─── s_rebalanceWithdrawRecovery.strategy.chainSelector ─────
ghost mathint ghost_rebalanceWithdrawRecovery_chainSelector_StoreCount { init_state axiom ghost_rebalanceWithdrawRecovery_chainSelector_StoreCount == 0; }
ghost uint64   ghost_rebalanceWithdrawRecovery_chainSelector_StoredValue { init_state axiom ghost_rebalanceWithdrawRecovery_chainSelector_StoredValue == 0; }

/// ─── s_rebalanceWithdrawRecovery.createdAt ──────────────────
ghost mathint ghost_rebalanceWithdrawRecovery_createdAt_StoreCount { init_state axiom ghost_rebalanceWithdrawRecovery_createdAt_StoreCount == 0; }
ghost uint256  ghost_rebalanceWithdrawRecovery_createdAt_StoredValue { init_state axiom ghost_rebalanceWithdrawRecovery_createdAt_StoredValue == 0; }

/// ─── s_epochDepositRecovery.epochNonce ──────────────────────
ghost mathint ghost_epochDepositRecovery_epochNonce_StoreCount { init_state axiom ghost_epochDepositRecovery_epochNonce_StoreCount == 0; }
ghost uint256  ghost_epochDepositRecovery_epochNonce_StoredValue { init_state axiom ghost_epochDepositRecovery_epochNonce_StoredValue == 0; }

/// ─── s_epochDepositRecovery.amount ──────────────────────────
ghost mathint ghost_epochDepositRecovery_amount_StoreCount { init_state axiom ghost_epochDepositRecovery_amount_StoreCount == 0; }
ghost uint256  ghost_epochDepositRecovery_amount_StoredValue { init_state axiom ghost_epochDepositRecovery_amount_StoredValue == 0; }

/// ─── s_epochDepositRecovery.createdAt ───────────────────────
ghost mathint ghost_epochDepositRecovery_createdAt_StoreCount { init_state axiom ghost_epochDepositRecovery_createdAt_StoreCount == 0; }
ghost uint256  ghost_epochDepositRecovery_createdAt_StoredValue { init_state axiom ghost_epochDepositRecovery_createdAt_StoredValue == 0; }

/// ─── s_epochWithdrawRecovery.epochNonce ─────────────────────
ghost mathint ghost_epochWithdrawRecovery_epochNonce_StoreCount { init_state axiom ghost_epochWithdrawRecovery_epochNonce_StoreCount == 0; }
ghost uint256  ghost_epochWithdrawRecovery_epochNonce_StoredValue { init_state axiom ghost_epochWithdrawRecovery_epochNonce_StoredValue == 0; }

/// ─── s_epochWithdrawRecovery.amount ─────────────────────────
ghost mathint ghost_epochWithdrawRecovery_amount_StoreCount { init_state axiom ghost_epochWithdrawRecovery_amount_StoreCount == 0; }
ghost uint256  ghost_epochWithdrawRecovery_amount_StoredValue { init_state axiom ghost_epochWithdrawRecovery_amount_StoredValue == 0; }

/// ─── s_epochWithdrawRecovery.createdAt ──────────────────────
ghost mathint ghost_epochWithdrawRecovery_createdAt_StoreCount { init_state axiom ghost_epochWithdrawRecovery_createdAt_StoreCount == 0; }
ghost uint256  ghost_epochWithdrawRecovery_createdAt_StoredValue { init_state axiom ghost_epochWithdrawRecovery_createdAt_StoredValue == 0; }

/// ─── s_ccipSendRecovery.ccipTxType ──────────────────────────
// ghost mathint ghost_ccipSendRecovery_ccipTxType_StoreCount { init_state axiom ghost_ccipSendRecovery_ccipTxType_StoreCount == 0; }
// ghost Types.CcipTx ghost_ccipSendRecovery_ccipTxType_StoredValue { init_state axiom ghost_ccipSendRecovery_ccipTxType_StoredValue == Types.CcipTx.EPOCH_NET_DEPOSIT; }

/// ─── s_ccipSendRecovery.amount ──────────────────────────────
ghost mathint ghost_ccipSendRecovery_amount_StoreCount { init_state axiom ghost_ccipSendRecovery_amount_StoreCount == 0; }
ghost uint256  ghost_ccipSendRecovery_amount_StoredValue { init_state axiom ghost_ccipSendRecovery_amount_StoredValue == 0; }

/// ─── s_ccipSendRecovery.destinationChainSelector ────────────
ghost mathint ghost_ccipSendRecovery_destinationChainSelector_StoreCount { init_state axiom ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 0; }
ghost uint64   ghost_ccipSendRecovery_destinationChainSelector_StoredValue { init_state axiom ghost_ccipSendRecovery_destinationChainSelector_StoredValue == 0; }

// /// ─── s_ccipSendRecovery.txData ──────────────────────────────
// ghost mathint ghost_ccipSendRecovery_txData_StoreCount { init_state axiom ghost_ccipSendRecovery_txData_StoreCount == 0; }
// ghost bytes    ghost_ccipSendRecovery_txData_StoredValue { init_state axiom ghost_ccipSendRecovery_txData_StoredValue == to_bytes(0); }

/// ─── s_ccipSendRecovery.createdAt ───────────────────────────
ghost mathint ghost_ccipSendRecovery_createdAt_StoreCount { init_state axiom ghost_ccipSendRecovery_createdAt_StoreCount == 0; }
ghost uint256  ghost_ccipSendRecovery_createdAt_StoredValue { init_state axiom ghost_ccipSendRecovery_createdAt_StoredValue == 0; }

/// ─── s_recoveryMode ──────────────────────────────────────────
ghost mathint            ghost_recoveryMode_StoreCount { init_state axiom ghost_recoveryMode_StoreCount == 0; }
ghost Types.RecoveryMode ghost_recoveryMode_StoredValue { init_state axiom ghost_recoveryMode_StoredValue == Types.RecoveryMode.NONE; }

/// ─── s_activeProtocolAdapter ─────────────────────────────────
ghost mathint ghost_activeProtocolAdapter_StoreCount { init_state axiom ghost_activeProtocolAdapter_StoreCount == 0; }
ghost address  ghost_activeProtocolAdapter_StoredValue { init_state axiom ghost_activeProtocolAdapter_StoredValue == 0; }

/// ─── s_rebalanceDepositRecovery.rebalanceNonce ───────────────
ghost mathint ghost_rebalanceDepositRecovery_nonce_StoreCount { init_state axiom ghost_rebalanceDepositRecovery_nonce_StoreCount == 0; }
ghost uint256  ghost_rebalanceDepositRecovery_nonce_StoredValue { init_state axiom ghost_rebalanceDepositRecovery_nonce_StoredValue == 0; }

/// ─── s_rebalanceDepositRecovery.amount ───────────────────────
ghost mathint ghost_rebalanceDepositRecovery_amount_StoreCount { init_state axiom ghost_rebalanceDepositRecovery_amount_StoreCount == 0; }
ghost uint256  ghost_rebalanceDepositRecovery_amount_StoredValue { init_state axiom ghost_rebalanceDepositRecovery_amount_StoredValue == 0; }

/// ─── s_rebalanceDepositRecovery.createdAt ────────────────────
ghost mathint ghost_rebalanceDepositRecovery_createdAt_StoreCount { init_state axiom ghost_rebalanceDepositRecovery_createdAt_StoreCount == 0; }
ghost uint256  ghost_rebalanceDepositRecovery_createdAt_StoredValue { init_state axiom ghost_rebalanceDepositRecovery_createdAt_StoredValue == 0; }

/// ─── Event: EpochDepositRecoveryStored ──────────────────────
ghost mathint ghost_EpochDepositRecoveryStored_EventCount { init_state axiom ghost_EpochDepositRecoveryStored_EventCount == 0; }
ghost uint256 ghost_EpochDepositRecoveryStored_Param_epochNonce { init_state axiom ghost_EpochDepositRecoveryStored_Param_epochNonce == 0; }
ghost uint256 ghost_EpochDepositRecoveryStored_Param_amount { init_state axiom ghost_EpochDepositRecoveryStored_Param_amount == 0; }

/// ─── Event: EpochDepositRecoveryCleared ─────────────────────
ghost mathint ghost_EpochDepositRecoveryCleared_EventCount { init_state axiom ghost_EpochDepositRecoveryCleared_EventCount == 0; }
ghost uint256 ghost_EpochDepositRecoveryCleared_Param_epochNonce { init_state axiom ghost_EpochDepositRecoveryCleared_Param_epochNonce == 0; }

/// ─── Event: EpochWithdrawRecoveryStored ─────────────────────
ghost mathint ghost_EpochWithdrawRecoveryStored_EventCount { init_state axiom ghost_EpochWithdrawRecoveryStored_EventCount == 0; }
ghost uint256 ghost_EpochWithdrawRecoveryStored_Param_epochNonce { init_state axiom ghost_EpochWithdrawRecoveryStored_Param_epochNonce == 0; }
ghost uint256 ghost_EpochWithdrawRecoveryStored_Param_amount { init_state axiom ghost_EpochWithdrawRecoveryStored_Param_amount == 0; }

/// ─── Event: EpochWithdrawRecoveryCleared ────────────────────
ghost mathint ghost_EpochWithdrawRecoveryCleared_EventCount { init_state axiom ghost_EpochWithdrawRecoveryCleared_EventCount == 0; }
ghost uint256 ghost_EpochWithdrawRecoveryCleared_Param_epochNonce { init_state axiom ghost_EpochWithdrawRecoveryCleared_Param_epochNonce == 0; }

/// ─── Event: RebalanceWithdrawRecoveryStored ─────────────────
ghost mathint ghost_RebalanceWithdrawRecoveryStored_EventCount { init_state axiom ghost_RebalanceWithdrawRecoveryStored_EventCount == 0; }
ghost uint256 ghost_RebalanceWithdrawRecoveryStored_Param_rebalanceNonce { init_state axiom ghost_RebalanceWithdrawRecoveryStored_Param_rebalanceNonce == 0; }
ghost bytes32 ghost_RebalanceWithdrawRecoveryStored_Param_protocolId { init_state axiom ghost_RebalanceWithdrawRecoveryStored_Param_protocolId == to_bytes32(0); }
ghost uint64 ghost_RebalanceWithdrawRecoveryStored_Param_chainSelector { init_state axiom ghost_RebalanceWithdrawRecoveryStored_Param_chainSelector == 0; }

/// ─── Event: RebalanceWithdrawRecoveryCleared ────────────────
ghost mathint ghost_RebalanceWithdrawRecoveryCleared_EventCount { init_state axiom ghost_RebalanceWithdrawRecoveryCleared_EventCount == 0; }
ghost uint256 ghost_RebalanceWithdrawRecoveryCleared_Param_rebalanceNonce { init_state axiom ghost_RebalanceWithdrawRecoveryCleared_Param_rebalanceNonce == 0; }

/// ─── Event: CcipSendRecoveryStored ──────────────────────────
ghost mathint ghost_CcipSendRecoveryStored_EventCount { init_state axiom ghost_CcipSendRecoveryStored_EventCount == 0; }
ghost Types.CcipTx ghost_CcipSendRecoveryStored_Param_ccipTxType { init_state axiom ghost_CcipSendRecoveryStored_Param_ccipTxType == Types.CcipTx.EPOCH_NET_DEPOSIT; }
ghost uint64 ghost_CcipSendRecoveryStored_Param_destinationChainSelector { init_state axiom ghost_CcipSendRecoveryStored_Param_destinationChainSelector == 0; }
ghost uint256 ghost_CcipSendRecoveryStored_Param_amount { init_state axiom ghost_CcipSendRecoveryStored_Param_amount == 0; }

/// ─── Event: CcipSendRecoveryCleared ─────────────────────────
ghost mathint ghost_CcipSendRecoveryCleared_EventCount { init_state axiom ghost_CcipSendRecoveryCleared_EventCount == 0; }
ghost Types.CcipTx ghost_CcipSendRecoveryCleared_Param_ccipTxType { init_state axiom ghost_CcipSendRecoveryCleared_Param_ccipTxType == Types.CcipTx.EPOCH_NET_DEPOSIT; }
ghost uint64 ghost_CcipSendRecoveryCleared_Param_destinationChainSelector { init_state axiom ghost_CcipSendRecoveryCleared_Param_destinationChainSelector == 0; }
ghost uint256 ghost_CcipSendRecoveryCleared_Param_amount { init_state axiom ghost_CcipSendRecoveryCleared_Param_amount == 0; }

/// ─── Event: CCIPBridged ──────────────────────────────────────
ghost mathint ghost_CCIPBridged_EventCount { init_state axiom ghost_CCIPBridged_EventCount == 0; }
ghost bytes32 ghost_CCIPBridged_Param_ccipMessageId { init_state axiom ghost_CCIPBridged_Param_ccipMessageId == to_bytes32(0); }
ghost uint256 ghost_CCIPBridged_Param_amount { init_state axiom ghost_CCIPBridged_Param_amount == 0; }
ghost Types.CcipTx ghost_CCIPBridged_Param_ccipTxType { init_state axiom ghost_CCIPBridged_Param_ccipTxType == Types.CcipTx.EPOCH_NET_DEPOSIT; }

/// ─── Event: DepositToStrategySuccess ─────────────────────────
ghost mathint ghost_DepositToStrategySuccess_EventCount { init_state axiom ghost_DepositToStrategySuccess_EventCount == 0; }
ghost uint256 ghost_DepositToStrategySuccess_Param_epochNonce { init_state axiom ghost_DepositToStrategySuccess_Param_epochNonce == 0; }
ghost uint256 ghost_DepositToStrategySuccess_Param_amount { init_state axiom ghost_DepositToStrategySuccess_Param_amount == 0; }

/// ─── Event: DepositToStrategyFailure ────────────────────────
ghost mathint ghost_DepositToStrategyFailure_EventCount { init_state axiom ghost_DepositToStrategyFailure_EventCount == 0; }
ghost uint256 ghost_DepositToStrategyFailure_Param_epochNonce { init_state axiom ghost_DepositToStrategyFailure_Param_epochNonce == 0; }
ghost uint256 ghost_DepositToStrategyFailure_Param_amount { init_state axiom ghost_DepositToStrategyFailure_Param_amount == 0; }

/// ─── Event: WithdrawFromStrategySuccess ──────────────────────
ghost mathint ghost_WithdrawFromStrategySuccess_EventCount { init_state axiom ghost_WithdrawFromStrategySuccess_EventCount == 0; }
ghost uint256 ghost_WithdrawFromStrategySuccess_Param_epochNonce { init_state axiom ghost_WithdrawFromStrategySuccess_Param_epochNonce == 0; }
ghost uint256 ghost_WithdrawFromStrategySuccess_Param_amount { init_state axiom ghost_WithdrawFromStrategySuccess_Param_amount == 0; }

/// ─── Event: ActiveProtocolAdapterSet ─────────────────────────
ghost mathint ghost_ActiveProtocolAdapterSet_EventCount { init_state axiom ghost_ActiveProtocolAdapterSet_EventCount == 0; }
ghost bytes32 ghost_ActiveProtocolAdapterSet_Param_protocolId { init_state axiom ghost_ActiveProtocolAdapterSet_Param_protocolId == to_bytes32(0); }
ghost address ghost_ActiveProtocolAdapterSet_Param_adapter { init_state axiom ghost_ActiveProtocolAdapterSet_Param_adapter == 0; }

/// ─── Event: ActiveProtocolAdapterCleared ─────────────────────
ghost mathint ghost_ActiveProtocolAdapterCleared_EventCount { init_state axiom ghost_ActiveProtocolAdapterCleared_EventCount == 0; }
ghost address ghost_ActiveProtocolAdapterCleared_Param_adapter { init_state axiom ghost_ActiveProtocolAdapterCleared_Param_adapter == 0; }

/// ─── Event: RebalanceDepositSuccess ──────────────────────────
ghost mathint ghost_RebalanceDepositSuccess_EventCount { init_state axiom ghost_RebalanceDepositSuccess_EventCount == 0; }
ghost uint256 ghost_RebalanceDepositSuccess_Param_nonce { init_state axiom ghost_RebalanceDepositSuccess_Param_nonce == 0; }
ghost uint256 ghost_RebalanceDepositSuccess_Param_amount { init_state axiom ghost_RebalanceDepositSuccess_Param_amount == 0; }

/// ─── Event: RebalanceDepositFailure ──────────────────────────
ghost mathint ghost_RebalanceDepositFailure_EventCount { init_state axiom ghost_RebalanceDepositFailure_EventCount == 0; }
ghost uint256 ghost_RebalanceDepositFailure_Param_nonce { init_state axiom ghost_RebalanceDepositFailure_Param_nonce == 0; }
ghost uint256 ghost_RebalanceDepositFailure_Param_amount { init_state axiom ghost_RebalanceDepositFailure_Param_amount == 0; }

/// ─── Event: RebalanceDepositRecoveryStored ───────────────────
ghost mathint ghost_RebalanceDepositRecoveryStored_EventCount { init_state axiom ghost_RebalanceDepositRecoveryStored_EventCount == 0; }
ghost uint256 ghost_RebalanceDepositRecoveryStored_Param_nonce { init_state axiom ghost_RebalanceDepositRecoveryStored_Param_nonce == 0; }
ghost uint256 ghost_RebalanceDepositRecoveryStored_Param_amount { init_state axiom ghost_RebalanceDepositRecoveryStored_Param_amount == 0; }

/// ─── Event: RebalanceDepositRecoveryCleared ──────────────────
ghost mathint ghost_RebalanceDepositRecoveryCleared_EventCount { init_state axiom ghost_RebalanceDepositRecoveryCleared_EventCount == 0; }
ghost uint256 ghost_RebalanceDepositRecoveryCleared_Param_nonce { init_state axiom ghost_RebalanceDepositRecoveryCleared_Param_nonce == 0; }

/// ─── Event: WithdrawFromStrategyFailure ─────────────────────
ghost mathint ghost_WithdrawFromStrategyFailure_EventCount { init_state axiom ghost_WithdrawFromStrategyFailure_EventCount == 0; }
ghost uint256 ghost_WithdrawFromStrategyFailure_Param_epochNonce { init_state axiom ghost_WithdrawFromStrategyFailure_Param_epochNonce == 0; }
ghost uint256 ghost_WithdrawFromStrategyFailure_Param_amount { init_state axiom ghost_WithdrawFromStrategyFailure_Param_amount == 0; }

/// ─── Event: RebalanceWithdrawSuccess ────────────────────────
ghost mathint ghost_RebalanceWithdrawSuccess_EventCount { init_state axiom ghost_RebalanceWithdrawSuccess_EventCount == 0; }
ghost uint256 ghost_RebalanceWithdrawSuccess_Param_nonce { init_state axiom ghost_RebalanceWithdrawSuccess_Param_nonce == 0; }
ghost uint256 ghost_RebalanceWithdrawSuccess_Param_amount { init_state axiom ghost_RebalanceWithdrawSuccess_Param_amount == 0; }

/// ─── Event: RebalanceWithdrawFailure ────────────────────────
ghost mathint ghost_RebalanceWithdrawFailure_EventCount { init_state axiom ghost_RebalanceWithdrawFailure_EventCount == 0; }
ghost uint256 ghost_RebalanceWithdrawFailure_Param_nonce { init_state axiom ghost_RebalanceWithdrawFailure_Param_nonce == 0; }

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/
/// ─── ChildVault storage hooks ────────────────────────────────
hook Sstore currentContract.ext_yieldcoin_storage_ChildVault.s_rebalanceWithdrawRecovery.rebalanceNonce uint256 newValue {
    ghost_rebalanceWithdrawRecovery_rebalanceNonce_StoreCount = ghost_rebalanceWithdrawRecovery_rebalanceNonce_StoreCount + 1;
    ghost_rebalanceWithdrawRecovery_rebalanceNonce_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ChildVault.s_rebalanceWithdrawRecovery.strategy.protocolId bytes32 newValue {
    ghost_rebalanceWithdrawRecovery_protocolId_StoreCount = ghost_rebalanceWithdrawRecovery_protocolId_StoreCount + 1;
    ghost_rebalanceWithdrawRecovery_protocolId_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ChildVault.s_rebalanceWithdrawRecovery.strategy.chainSelector uint64 newValue {
    ghost_rebalanceWithdrawRecovery_chainSelector_StoreCount = ghost_rebalanceWithdrawRecovery_chainSelector_StoreCount + 1;
    ghost_rebalanceWithdrawRecovery_chainSelector_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ChildVault.s_rebalanceWithdrawRecovery.createdAt uint256 newValue {
    ghost_rebalanceWithdrawRecovery_createdAt_StoreCount = ghost_rebalanceWithdrawRecovery_createdAt_StoreCount + 1;
    ghost_rebalanceWithdrawRecovery_createdAt_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ChildVault.s_epochDepositRecovery.epochNonce uint256 newValue {
    ghost_epochDepositRecovery_epochNonce_StoreCount = ghost_epochDepositRecovery_epochNonce_StoreCount + 1;
    ghost_epochDepositRecovery_epochNonce_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ChildVault.s_epochDepositRecovery.amount uint256 newValue {
    ghost_epochDepositRecovery_amount_StoreCount = ghost_epochDepositRecovery_amount_StoreCount + 1;
    ghost_epochDepositRecovery_amount_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ChildVault.s_epochDepositRecovery.createdAt uint256 newValue {
    ghost_epochDepositRecovery_createdAt_StoreCount = ghost_epochDepositRecovery_createdAt_StoreCount + 1;
    ghost_epochDepositRecovery_createdAt_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ChildVault.s_epochWithdrawRecovery.epochNonce uint256 newValue {
    ghost_epochWithdrawRecovery_epochNonce_StoreCount = ghost_epochWithdrawRecovery_epochNonce_StoreCount + 1;
    ghost_epochWithdrawRecovery_epochNonce_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ChildVault.s_epochWithdrawRecovery.amount uint256 newValue {
    ghost_epochWithdrawRecovery_amount_StoreCount = ghost_epochWithdrawRecovery_amount_StoreCount + 1;
    ghost_epochWithdrawRecovery_amount_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ChildVault.s_epochWithdrawRecovery.createdAt uint256 newValue {
    ghost_epochWithdrawRecovery_createdAt_StoreCount = ghost_epochWithdrawRecovery_createdAt_StoreCount + 1;
    ghost_epochWithdrawRecovery_createdAt_StoredValue = newValue;
}

// hook Sstore currentContract.ext_yieldcoin_storage_ChildVault.s_ccipSendRecovery.ccipTxType Types.CcipTx newValue {
//     ghost_ccipSendRecovery_ccipTxType_StoreCount = ghost_ccipSendRecovery_ccipTxType_StoreCount + 1;
//     ghost_ccipSendRecovery_ccipTxType_StoredValue = newValue;
// }

hook Sstore currentContract.ext_yieldcoin_storage_ChildVault.s_ccipSendRecovery.amount uint256 newValue {
    ghost_ccipSendRecovery_amount_StoreCount = ghost_ccipSendRecovery_amount_StoreCount + 1;
    ghost_ccipSendRecovery_amount_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ChildVault.s_ccipSendRecovery.destinationChainSelector uint64 newValue {
    ghost_ccipSendRecovery_destinationChainSelector_StoreCount = ghost_ccipSendRecovery_destinationChainSelector_StoreCount + 1;
    ghost_ccipSendRecovery_destinationChainSelector_StoredValue = newValue;
}

// hook Sstore currentContract.ext_yieldcoin_storage_ChildVault.s_ccipSendRecovery.txData bytes newValue {
//     ghost_ccipSendRecovery_txData_StoreCount = ghost_ccipSendRecovery_txData_StoreCount + 1;
//     ghost_ccipSendRecovery_txData_StoredValue = newValue;
// }

hook Sstore currentContract.ext_yieldcoin_storage_ChildVault.s_ccipSendRecovery.createdAt uint256 newValue {
    ghost_ccipSendRecovery_createdAt_StoreCount = ghost_ccipSendRecovery_createdAt_StoreCount + 1;
    ghost_ccipSendRecovery_createdAt_StoredValue = newValue;
}

/// ─── BaseVault storage hooks used by ChildVault flows ────────
hook Sstore currentContract.ext_yieldcoin_storage_BaseVault.s_recoveryMode Types.RecoveryMode newValue {
    ghost_recoveryMode_StoreCount = ghost_recoveryMode_StoreCount + 1;
    ghost_recoveryMode_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_BaseVault.s_activeProtocolAdapter address newValue {
    ghost_activeProtocolAdapter_StoreCount = ghost_activeProtocolAdapter_StoreCount + 1;
    ghost_activeProtocolAdapter_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_BaseVault.s_rebalanceDepositRecovery.rebalanceNonce uint256 newValue {
    ghost_rebalanceDepositRecovery_nonce_StoreCount = ghost_rebalanceDepositRecovery_nonce_StoreCount + 1;
    ghost_rebalanceDepositRecovery_nonce_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_BaseVault.s_rebalanceDepositRecovery.amount uint256 newValue {
    ghost_rebalanceDepositRecovery_amount_StoreCount = ghost_rebalanceDepositRecovery_amount_StoreCount + 1;
    ghost_rebalanceDepositRecovery_amount_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_BaseVault.s_rebalanceDepositRecovery.createdAt uint256 newValue {
    ghost_rebalanceDepositRecovery_createdAt_StoreCount = ghost_rebalanceDepositRecovery_createdAt_StoreCount + 1;
    ghost_rebalanceDepositRecovery_createdAt_StoredValue = newValue;
}

/// ─── Event hooks ─────────────────────────────────────────────
hook LOG2(uint offset, uint length, bytes32 t0, bytes32 t1) {
    if (t0 == EpochDepositRecoveryClearedEvent()) {
        ghost_EpochDepositRecoveryCleared_EventCount = ghost_EpochDepositRecoveryCleared_EventCount + 1;
        ghost_EpochDepositRecoveryCleared_Param_epochNonce = bytes32ToUint256(t1);
    }
    if (t0 == EpochWithdrawRecoveryClearedEvent()) {
        ghost_EpochWithdrawRecoveryCleared_EventCount = ghost_EpochWithdrawRecoveryCleared_EventCount + 1;
        ghost_EpochWithdrawRecoveryCleared_Param_epochNonce = bytes32ToUint256(t1);
    }
    if (t0 == RebalanceWithdrawRecoveryClearedEvent()) {
        ghost_RebalanceWithdrawRecoveryCleared_EventCount = ghost_RebalanceWithdrawRecoveryCleared_EventCount + 1;
        ghost_RebalanceWithdrawRecoveryCleared_Param_rebalanceNonce = bytes32ToUint256(t1);
    }
    if (t0 == RebalanceWithdrawFailureEvent()) {
        ghost_RebalanceWithdrawFailure_EventCount = ghost_RebalanceWithdrawFailure_EventCount + 1;
        ghost_RebalanceWithdrawFailure_Param_nonce = bytes32ToUint256(t1);
    }
    if (t0 == RebalanceDepositRecoveryClearedEvent()) {
        ghost_RebalanceDepositRecoveryCleared_EventCount = ghost_RebalanceDepositRecoveryCleared_EventCount + 1;
        ghost_RebalanceDepositRecoveryCleared_Param_nonce = bytes32ToUint256(t1);
    }
    if (t0 == ActiveProtocolAdapterClearedEvent()) {
        ghost_ActiveProtocolAdapterCleared_EventCount = ghost_ActiveProtocolAdapterCleared_EventCount + 1;
        ghost_ActiveProtocolAdapterCleared_Param_adapter = bytes32ToAddress(t1);
    }
}

hook LOG3(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2) {
    if (t0 == EpochDepositRecoveryStoredEvent()) {
        ghost_EpochDepositRecoveryStored_EventCount = ghost_EpochDepositRecoveryStored_EventCount + 1;
        ghost_EpochDepositRecoveryStored_Param_epochNonce = bytes32ToUint256(t1);
        ghost_EpochDepositRecoveryStored_Param_amount = bytes32ToUint256(t2);
    }
    if (t0 == EpochWithdrawRecoveryStoredEvent()) {
        ghost_EpochWithdrawRecoveryStored_EventCount = ghost_EpochWithdrawRecoveryStored_EventCount + 1;
        ghost_EpochWithdrawRecoveryStored_Param_epochNonce = bytes32ToUint256(t1);
        ghost_EpochWithdrawRecoveryStored_Param_amount = bytes32ToUint256(t2);
    }
    if (t0 == DepositToStrategySuccessEvent()) {
        ghost_DepositToStrategySuccess_EventCount = ghost_DepositToStrategySuccess_EventCount + 1;
        ghost_DepositToStrategySuccess_Param_epochNonce = bytes32ToUint256(t1);
        ghost_DepositToStrategySuccess_Param_amount = bytes32ToUint256(t2);
    }
    if (t0 == DepositToStrategyFailureEvent()) {
        ghost_DepositToStrategyFailure_EventCount = ghost_DepositToStrategyFailure_EventCount + 1;
        ghost_DepositToStrategyFailure_Param_epochNonce = bytes32ToUint256(t1);
        ghost_DepositToStrategyFailure_Param_amount = bytes32ToUint256(t2);
    }
    if (t0 == WithdrawFromStrategySuccessEvent()) {
        ghost_WithdrawFromStrategySuccess_EventCount = ghost_WithdrawFromStrategySuccess_EventCount + 1;
        ghost_WithdrawFromStrategySuccess_Param_epochNonce = bytes32ToUint256(t1);
        ghost_WithdrawFromStrategySuccess_Param_amount = bytes32ToUint256(t2);
    }
    if (t0 == ActiveProtocolAdapterSetEvent()) {
        ghost_ActiveProtocolAdapterSet_EventCount = ghost_ActiveProtocolAdapterSet_EventCount + 1;
        ghost_ActiveProtocolAdapterSet_Param_protocolId = t1;
        ghost_ActiveProtocolAdapterSet_Param_adapter = bytes32ToAddress(t2);
    }
    if (t0 == RebalanceDepositSuccessEvent()) {
        ghost_RebalanceDepositSuccess_EventCount = ghost_RebalanceDepositSuccess_EventCount + 1;
        ghost_RebalanceDepositSuccess_Param_nonce = bytes32ToUint256(t1);
        ghost_RebalanceDepositSuccess_Param_amount = bytes32ToUint256(t2);
    }
    if (t0 == RebalanceDepositFailureEvent()) {
        ghost_RebalanceDepositFailure_EventCount = ghost_RebalanceDepositFailure_EventCount + 1;
        ghost_RebalanceDepositFailure_Param_nonce = bytes32ToUint256(t1);
        ghost_RebalanceDepositFailure_Param_amount = bytes32ToUint256(t2);
    }
    if (t0 == RebalanceDepositRecoveryStoredEvent()) {
        ghost_RebalanceDepositRecoveryStored_EventCount = ghost_RebalanceDepositRecoveryStored_EventCount + 1;
        ghost_RebalanceDepositRecoveryStored_Param_nonce = bytes32ToUint256(t1);
        ghost_RebalanceDepositRecoveryStored_Param_amount = bytes32ToUint256(t2);
    }
    if (t0 == WithdrawFromStrategyFailureEvent()) {
        ghost_WithdrawFromStrategyFailure_EventCount = ghost_WithdrawFromStrategyFailure_EventCount + 1;
        ghost_WithdrawFromStrategyFailure_Param_epochNonce = bytes32ToUint256(t1);
        ghost_WithdrawFromStrategyFailure_Param_amount = bytes32ToUint256(t2);
    }
    if (t0 == RebalanceWithdrawSuccessEvent()) {
        ghost_RebalanceWithdrawSuccess_EventCount = ghost_RebalanceWithdrawSuccess_EventCount + 1;
        ghost_RebalanceWithdrawSuccess_Param_nonce = bytes32ToUint256(t1);
        ghost_RebalanceWithdrawSuccess_Param_amount = bytes32ToUint256(t2);
    }
}

hook LOG4(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2, bytes32 t3) {
    if (t0 == CCIPBridgedEvent()) {
        ghost_CCIPBridged_EventCount = ghost_CCIPBridged_EventCount + 1;
        ghost_CCIPBridged_Param_ccipMessageId = t1;
        ghost_CCIPBridged_Param_amount = bytes32ToUint256(t2);
        ghost_CCIPBridged_Param_ccipTxType = uint8ToCcipTxType(bytes32ToUint8(t3));
    }
    if (t0 == RebalanceWithdrawRecoveryStoredEvent()) {
        ghost_RebalanceWithdrawRecoveryStored_EventCount = ghost_RebalanceWithdrawRecoveryStored_EventCount + 1;
        ghost_RebalanceWithdrawRecoveryStored_Param_rebalanceNonce = bytes32ToUint256(t1);
        ghost_RebalanceWithdrawRecoveryStored_Param_protocolId = t2;
        ghost_RebalanceWithdrawRecoveryStored_Param_chainSelector = bytes32ToUint64(t3);
    }
    if (t0 == CcipSendRecoveryStoredEvent()) {
        ghost_CcipSendRecoveryStored_EventCount = ghost_CcipSendRecoveryStored_EventCount + 1;
        ghost_CcipSendRecoveryStored_Param_ccipTxType = uint8ToCcipTxType(bytes32ToUint8(t1));
        ghost_CcipSendRecoveryStored_Param_destinationChainSelector = bytes32ToUint64(t2);
        ghost_CcipSendRecoveryStored_Param_amount = bytes32ToUint256(t3);
    }
    if (t0 == CcipSendRecoveryClearedEvent()) {
        ghost_CcipSendRecoveryCleared_EventCount = ghost_CcipSendRecoveryCleared_EventCount + 1;
        ghost_CcipSendRecoveryCleared_Param_ccipTxType = uint8ToCcipTxType(bytes32ToUint8(t1));
        ghost_CcipSendRecoveryCleared_Param_destinationChainSelector = bytes32ToUint64(t2);
        ghost_CcipSendRecoveryCleared_Param_amount = bytes32ToUint256(t3);
    }
}

/*//////////////////////////////////////////////////////////////
                           INVARIANTS
//////////////////////////////////////////////////////////////*/
/// @dev filtered: upgradeToAndCall to stop delegatecall havocing immutable state
/// @dev Certora storage analysis can fail on the other filtered storage-extension paths for these methods.
invariant validParentChainSelector()
    currentContract.i_parentChainSelector != 0
    && currentContract.i_parentChainSelector != currentContract.i_thisChainSelector
    filtered {
        f -> f.selector != sig:upgradeToAndCall(address,bytes).selector
            && f.selector != sig:ccipSend(uint256,uint64,Types.CcipTx,bytes).selector
            && f.selector != sig:executeRebalance(uint256,Types.Strategy).selector
            && f.selector != sig:recoverFailedRebalanceWithdraw().selector
            && f.selector != sig:recoverFailedEpochWithdraw().selector
            && f.selector != sig:executeEpochWithdraw(uint256,uint256).selector
    }

/// @dev filtered: upgradeToAndCall to stop delegatecall havocing immutable state.
/// @dev Certora storage analysis can fail on the other filtered storage-extension paths for these methods.
invariant noZeroChainSelector()
    currentContract.i_thisChainSelector != 0
    filtered {
        f -> f.selector != sig:upgradeToAndCall(address,bytes).selector
            && f.selector != sig:ccipSend(uint256,uint64,Types.CcipTx,bytes).selector
            && f.selector != sig:executeRebalance(uint256,Types.Strategy).selector
            && f.selector != sig:recoverFailedRebalanceWithdraw().selector
            && f.selector != sig:recoverFailedEpochWithdraw().selector
            && f.selector != sig:executeEpochWithdraw(uint256,uint256).selector
    }

/// @dev filtered: upgradeToAndCall to stop delegatecall havocing immutable state.
/// @dev Certora storage analysis can fail on the other filtered storage-extension paths for these methods.
invariant noZeroAssetPrecision(env e)
    asset.decimals(e) > 0 => currentContract.i_assetPrecision != 0
    filtered {
        f -> f.selector != sig:upgradeToAndCall(address,bytes).selector
            && f.selector != sig:ccipSend(uint256,uint64,Types.CcipTx,bytes).selector
            && f.selector != sig:executeRebalance(uint256,Types.Strategy).selector
            && f.selector != sig:recoverFailedRebalanceWithdraw().selector
            && f.selector != sig:recoverFailedEpochWithdraw().selector
            && f.selector != sig:executeEpochWithdraw(uint256,uint256).selector
    }

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/

/// ─────────────────── INITIALIZE CHILD VAULT ──────────────────

/// @notice ChildVault initialization reverts when the contract has already been initialized
/// @dev Verifies that repeated initialization leaves all vault state unchanged
rule initialize_RevertWhen_AlreadyInitialized() {
    env e;
    BaseVault.InitParams params;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require params.defaultAdmin != 0, "default admin should not be zero";
    require params.pauser != 0, "pauser should not be zero";
    require params.unpauser != 0, "unpauser should not be zero";
    require params.configOperator != 0, "config operator should not be zero";
    require params.emergencyReceiver != 0, "emergency receiver should not be zero";
    require params.upgrader != 0, "upgrader should not be zero";
    require params.initialDefaultCcipGasLimit != 0, "default CCIP gas limit should not be zero";

    /// @dev revert condition being verified
    require isInitialized(), "contract should already be initialized";

    storage before = lastStorage;

    initialize@withrevert(e, params);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// ─────────────────── CCIP RECEIVE ────────────────────────────

/// @notice CCIP receive reverts when the caller is not the configured CCIP router
/// @dev Verifies that an unauthorized delivery attempt leaves all vault state unchanged
rule ccipReceive_RevertWhen_CallerIsNotCCIPRouter() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be the registered vault";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.depositReverts();
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_DEPOSIT, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch deposit";

    /// @dev revert condition being verified
    require e.msg.sender != getRouter(), "caller should not be the CCIP router";

    storage before = lastStorage;

    ccipReceive@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice CCIP receive reverts when called during an active non-reentrant execution
/// @dev Verifies that a reentrant delivery attempt leaves all vault state unchanged
rule ccipReceive_RevertWhen_ReentrantCall() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be the registered vault";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.depositReverts();
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_DEPOSIT, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch deposit";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";

    storage before = lastStorage;

    ccipReceive@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice CCIP receive reverts when the decoded sender is not the registered vault for the source chain
/// @dev Verifies that an unauthorized cross-chain sender leaves all vault state unchanged
rule ccipReceive_RevertWhen_SenderIsNotAllowed() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.depositReverts();
    require message.sender == encodeAddress(sender), "message sender should encode the supplied sender";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_DEPOSIT, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch deposit";

    /// @dev revert condition being verified
    require sender != getCrosschainVault(message.sourceChainSelector), "sender should not be the registered vault";

    storage before = lastStorage;

    ccipReceive@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice CCIP receive reverts when a zero sender is supplied for an unregistered source chain
/// @dev Verifies that an unset cross-chain vault cannot authorize the zero address
rule ccipReceive_RevertWhen_SenderAndRegisteredVaultAreZero() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.depositReverts(), "adapter deposit should not revert";
    require adapter != currentContract, "adapter should not be the vault";
    require message.sender == encodeAddress(sender), "message sender should encode the supplied sender";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_DEPOSIT, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch deposit";

    /// @dev revert condition being verified
    require sender == 0, "sender should be zero";
    require getCrosschainVault(message.sourceChainSelector) == 0, "source chain should not have a registered vault";

    storage before = lastStorage;

    ccipReceive@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice CCIP receive reverts when the encoded sender is too short to decode as an address
/// @dev Verifies that malformed sender data leaves all vault state unchanged
rule ccipReceive_RevertWhen_SenderEncodingIsMalformed() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_DEPOSIT, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch deposit";

    /// @dev revert condition being verified
    require message.sender.length < 32, "message sender should be too short to decode";

    storage before = lastStorage;

    ccipReceive@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice CCIP receive reverts when any recovery operation is already pending
/// @dev Verifies that a pending recovery cannot be overwritten by a new delivery
rule ccipReceive_RevertWhen_RecoveryAlreadyPending() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be the registered vault";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.depositReverts();
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_DEPOSIT, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch deposit";

    /// @dev revert condition being verified
    require getRecoveryMode() != Types.RecoveryMode.NONE, "recovery should be pending";

    storage before = lastStorage;

    ccipReceive@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice CCIP receive reverts unless exactly one token amount is delivered
/// @dev Verifies that an invalid token-amount array leaves all vault state unchanged
rule ccipReceive_RevertWhen_TokenAmountsLengthIsInvalid() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be the registered vault";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.depositReverts();
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_DEPOSIT, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch deposit";

    /// @dev revert condition being verified
    require message.destTokenAmounts.length != 1, "token amounts length should be invalid";

    storage before = lastStorage;

    ccipReceive@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice CCIP receive reverts when the delivered token is not the vault asset
/// @dev Verifies that an invalid received token leaves all vault state unchanged
rule ccipReceive_RevertWhen_ReceivedTokenIsInvalid() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be the registered vault";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.depositReverts();
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_DEPOSIT, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch deposit";

    /// @dev revert condition being verified
    require message.destTokenAmounts[0].token != getAsset(), "delivered token should not be the vault asset";

    storage before = lastStorage;

    ccipReceive@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice CCIP receive reverts when the delivered asset amount is zero
/// @dev Verifies that a zero-value delivery leaves all vault state unchanged
rule ccipReceive_RevertWhen_ReceivedAmountIsZero() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be the registered vault";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.depositReverts();
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_DEPOSIT, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch deposit";

    /// @dev revert condition being verified
    require message.destTokenAmounts[0].amount == 0, "delivered amount should be zero";

    storage before = lastStorage;

    ccipReceive@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice CCIP receive reverts when the message data is too short to decode its transaction envelope
/// @dev Verifies that malformed transaction data leaves all vault state unchanged
rule ccipReceive_RevertWhen_TxDataEncodingIsMalformed() {
    env e;
    Client.Any2EVMMessage message;
    uint256 singleValue;
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be the registered vault";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";

    /// @dev revert condition being verified
    require message.data == encodeEpochNonce(singleValue),
        "message data should contain only one value instead of the required transaction type and payload";

    storage before = lastStorage;

    ccipReceive@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice CCIP receive reverts when the encoded transaction type is outside the CcipTx enum
/// @dev Verifies that an invalid enum discriminant leaves all vault state unchanged
rule ccipReceive_RevertWhen_TxTypeEncodingIsOutOfRange() {
    env e;
    Client.Any2EVMMessage message;
    uint256 rawCcipTxType;
    uint256 epochNonce;
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be the registered vault";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeRawCcipTxData(rawCcipTxType, encodeEpochNonce(epochNonce)),
        "message data should encode the raw transaction type";

    /// @dev revert condition being verified
    require rawCcipTxType > 2, "transaction type should be outside the CcipTx enum";

    storage before = lastStorage;

    ccipReceive@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice CCIP receive reverts when the transaction type is unsupported by ChildVault
/// @dev Verifies that an unsupported transaction type leaves all vault state unchanged
rule ccipReceive_RevertWhen_TxTypeIsInvalid() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    address sender;
    Types.CcipTx ccipTxType;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be the registered vault";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.depositReverts();
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(ccipTxType, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch withdraw";

    /// @dev revert condition being verified
    require ccipTxType == Types.CcipTx.EPOCH_NET_WITHDRAW, "transaction type should be unsupported";

    storage before = lastStorage;

    ccipReceive@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice CCIP epoch deposit reverts when no active protocol adapter is configured
/// @dev Verifies that a deposit without an active strategy leaves all vault state unchanged
rule ccipReceive_EPOCH_NET_DEPOSIT_RevertWhen_NoActiveAdapter() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be the registered vault";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_DEPOSIT, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch deposit";

    /// @dev revert condition being verified
    require getActiveProtocolAdapter() == 0, "active adapter should be zero";

    storage before = lastStorage;

    ccipReceive@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice CCIP epoch deposit reverts when its payload is too short to decode the epoch nonce
/// @dev Verifies that malformed epoch data leaves all vault state unchanged
rule ccipReceive_EPOCH_NET_DEPOSIT_RevertWhen_PayloadEncodingIsMalformed() {
    env e;
    Client.Any2EVMMessage message;
    bytes data;
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be the registered vault";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_DEPOSIT, data),
        "message data should encode an epoch deposit";

    /// @dev revert condition being verified
    require data.length < 32, "epoch deposit payload should be too short to decode";

    storage before = lastStorage;

    ccipReceive@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice A successful CCIP epoch deposit transfers the delivered asset into the active adapter
/// @dev Verifies exact balances, adapter TVL, unchanged recovery state, storage writes, and events
rule ccipReceive_EPOCH_NET_DEPOSIT_Success() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be the registered vault";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.depositReverts(), "adapter deposit should not revert";
    require adapter != currentContract, "adapter should not be the vault";
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_DEPOSIT, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch deposit";
    require decodeCcipTxType(message.data) == Types.CcipTx.EPOCH_NET_DEPOSIT,
        "decoded transaction type should be epoch net deposit";
    require decodeCcipTxPayload(message.data) == encodeEpochNonce(epochNonce),
        "decoded payload should encode the epoch nonce";

    uint256 amount = message.destTokenAmounts[0].amount;
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();
    Types.EpochRecovery recoveryBefore = getEpochDepositRecovery();

    /// @dev mock token and adapter arithmetic conditions
    require amount <= vaultBalanceBefore, "vault asset balance should cover the deposit amount";
    require adapterBalanceBefore <= max_uint256 - amount, "adapter asset balance should not overflow";
    require adapterTVLBefore <= max_uint256 - amount, "adapter TVL should not overflow";

    /// @dev set ghost starting values
    require ghost_DepositToStrategySuccess_EventCount == 0;
    require ghost_DepositToStrategyFailure_EventCount == 0;
    require ghost_EpochDepositRecoveryStored_EventCount == 0;
    require ghost_recoveryMode_StoreCount == 0;
    require ghost_epochDepositRecovery_epochNonce_StoreCount == 0;
    require ghost_epochDepositRecovery_amount_StoreCount == 0;
    require ghost_epochDepositRecovery_createdAt_StoreCount == 0;

    ccipReceive@withrevert(e, message);


    assert !lastReverted;
    Types.EpochRecovery recoveryAfter = getEpochDepositRecovery();
    assert asset.balanceOf(currentContract) == vaultBalanceBefore - amount;
    assert asset.balanceOf(adapter) == adapterBalanceBefore + amount;
    assert adapter.getTVL() == adapterTVLBefore + amount;
    assert getRecoveryMode() == Types.RecoveryMode.NONE;
    assert recoveryAfter.epochNonce == recoveryBefore.epochNonce;
    assert recoveryAfter.amount == recoveryBefore.amount;
    assert recoveryAfter.createdAt == recoveryBefore.createdAt;
    assert ghost_DepositToStrategySuccess_EventCount == 1;
    assert ghost_DepositToStrategySuccess_Param_epochNonce == epochNonce;
    assert ghost_DepositToStrategySuccess_Param_amount == amount;
    assert ghost_DepositToStrategyFailure_EventCount == 0;
    assert ghost_EpochDepositRecoveryStored_EventCount == 0;
    assert ghost_recoveryMode_StoreCount == 0;
    assert ghost_epochDepositRecovery_epochNonce_StoreCount == 0;
    assert ghost_epochDepositRecovery_amount_StoreCount == 0;
    assert ghost_epochDepositRecovery_createdAt_StoreCount == 0;
}

/// @notice A failed CCIP epoch deposit stores recovery for the delivered asset
/// @dev Verifies unchanged balances and TVL, exact recovery state, storage writes, and failure events
rule ccipReceive_EPOCH_NET_DEPOSIT_FailedDepositStoresRecovery() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be the registered vault";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require adapter.depositReverts(), "adapter deposit should revert";
    require adapter != currentContract, "adapter should not be the vault";
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_DEPOSIT, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch deposit";
    require decodeCcipTxType(message.data) == Types.CcipTx.EPOCH_NET_DEPOSIT,
        "decoded transaction type should be epoch net deposit";
    require decodeCcipTxPayload(message.data) == encodeEpochNonce(epochNonce),
        "decoded payload should encode the epoch nonce";

    uint256 amount = message.destTokenAmounts[0].amount;
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token arithmetic condition
    require amount <= vaultBalanceBefore, "vault asset balance should cover the deposit amount";

    /// @dev set ghost starting values
    require ghost_DepositToStrategySuccess_EventCount == 0;
    require ghost_DepositToStrategyFailure_EventCount == 0;
    require ghost_EpochDepositRecoveryStored_EventCount == 0;
    require ghost_recoveryMode_StoreCount == 0;
    require ghost_epochDepositRecovery_epochNonce_StoreCount == 0;
    require ghost_epochDepositRecovery_amount_StoreCount == 0;
    require ghost_epochDepositRecovery_createdAt_StoreCount == 0;

    ccipReceive@withrevert(e, message);

    assert !lastReverted;
    Types.EpochRecovery recovery = getEpochDepositRecovery();
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert getRecoveryMode() == Types.RecoveryMode.EPOCH_DEPOSIT;
    assert recovery.epochNonce == epochNonce;
    assert recovery.amount == amount;
    assert recovery.createdAt == e.block.timestamp;
    assert ghost_DepositToStrategySuccess_EventCount == 0;
    assert ghost_DepositToStrategyFailure_EventCount == 1;
    assert ghost_DepositToStrategyFailure_Param_epochNonce == epochNonce;
    assert ghost_DepositToStrategyFailure_Param_amount == amount;
    assert ghost_EpochDepositRecoveryStored_EventCount == 1;
    assert ghost_EpochDepositRecoveryStored_Param_epochNonce == epochNonce;
    assert ghost_EpochDepositRecoveryStored_Param_amount == amount;
    assert ghost_epochDepositRecovery_epochNonce_StoreCount == 1;
    assert ghost_epochDepositRecovery_epochNonce_StoredValue == epochNonce;
    assert ghost_epochDepositRecovery_amount_StoreCount == 1;
    assert ghost_epochDepositRecovery_amount_StoredValue == amount;
    assert ghost_epochDepositRecovery_createdAt_StoreCount == 1;
    assert ghost_epochDepositRecovery_createdAt_StoredValue == e.block.timestamp;
    assert ghost_recoveryMode_StoreCount == 1 => ghost_recoveryMode_StoredValue == Types.RecoveryMode.EPOCH_DEPOSIT,
        "recovery mode stored value is only meaningful when the recovery mode hook fires, which may not happen due to state packing";
}

/// @notice CCIP rebalance reverts when the target protocol adapter is not registered
/// @dev Verifies that an unknown target protocol leaves all vault state unchanged
rule ccipReceive_REBALANCE_RevertWhen_AdapterNotRegistered() {
    env e;
    Client.Any2EVMMessage message;
    uint256 rebalanceNonce;
    bytes32 protocolId;
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be the registered vault";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.REBALANCE, encodeRebalanceData(rebalanceNonce, protocolId)),
        "message data should encode a rebalance";

    /// @dev revert condition being verified
    require adapterRegistry.getAdapter(e, protocolId) == 0, "adapter should not be registered";

    storage before = lastStorage;

    ccipReceive@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice CCIP rebalance reverts when its payload is too short to decode the nonce and protocol ID
/// @dev Verifies that malformed rebalance data leaves all vault state unchanged
rule ccipReceive_REBALANCE_RevertWhen_PayloadEncodingIsMalformed() {
    env e;
    Client.Any2EVMMessage message;
    bytes data;
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be the registered vault";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.REBALANCE, data),
        "message data should encode a rebalance";

    /// @dev revert condition being verified
    require data.length < 64, "rebalance payload should be too short to decode";

    storage before = lastStorage;

    ccipReceive@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice CCIP rebalance reverts when the registered adapter is bound to another vault
/// @dev Verifies that an invalid target adapter leaves all vault state unchanged
rule ccipReceive_REBALANCE_RevertWhen_AdapterVaultIsInvalid() {
    env e;
    Client.Any2EVMMessage message;
    uint256 rebalanceNonce;
    bytes32 protocolId;
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be the registered vault";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require invalidAdapter.getVault() != currentContract, "adapter vault should not be this vault";
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.REBALANCE, encodeRebalanceData(rebalanceNonce, protocolId)),
        "message data should encode a rebalance";

    /// @dev revert condition being verified
    require adapterRegistry.getAdapter(e, protocolId) == invalidAdapter, "invalid adapter should be registered";

    storage before = lastStorage;

    ccipReceive@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice A successful CCIP rebalance selects the target adapter and deposits the delivered asset
/// @dev Verifies exact balances, adapter TVL, unchanged recovery state, storage writes, and events
rule ccipReceive_REBALANCE_Success() {
    env e;
    Client.Any2EVMMessage message;
    uint256 rebalanceNonce;
    bytes32 protocolId;
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be the registered vault";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require adapterRegistry.getAdapter(e, protocolId) == adapter, "adapter should be registered";
    require adapter.getVault() == currentContract, "adapter should be bound to the vault";
    require !adapter.depositReverts(), "adapter deposit should not revert";
    require adapter != currentContract, "adapter should not be the vault";
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.REBALANCE, encodeRebalanceData(rebalanceNonce, protocolId)),
        "message data should encode a rebalance";

    uint256 amount = message.destTokenAmounts[0].amount;
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();
    Types.RebalanceDepositRecovery recoveryBefore = getRebalanceDepositRecovery();

    /// @dev mock token and adapter arithmetic conditions
    require amount <= vaultBalanceBefore, "vault asset balance should cover the deposit amount";
    require adapterBalanceBefore <= max_uint256 - amount, "adapter asset balance should not overflow";
    require adapterTVLBefore <= max_uint256 - amount, "adapter TVL should not overflow";

    /// @dev set ghost starting values
    require ghost_ActiveProtocolAdapterSet_EventCount == 0;
    require ghost_RebalanceDepositSuccess_EventCount == 0;
    require ghost_RebalanceDepositFailure_EventCount == 0;
    require ghost_RebalanceDepositRecoveryStored_EventCount == 0;
    require ghost_activeProtocolAdapter_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;
    require ghost_rebalanceDepositRecovery_nonce_StoreCount == 0;
    require ghost_rebalanceDepositRecovery_amount_StoreCount == 0;
    require ghost_rebalanceDepositRecovery_createdAt_StoreCount == 0;

    ccipReceive@withrevert(e, message);


    assert !lastReverted;
    Types.RebalanceDepositRecovery recoveryAfter = getRebalanceDepositRecovery();
    assert getActiveProtocolAdapter() == adapter;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore - amount;
    assert asset.balanceOf(adapter) == adapterBalanceBefore + amount;
    assert adapter.getTVL() == adapterTVLBefore + amount;
    assert getRecoveryMode() == Types.RecoveryMode.NONE;
    assert recoveryAfter.rebalanceNonce == recoveryBefore.rebalanceNonce;
    assert recoveryAfter.amount == recoveryBefore.amount;
    assert recoveryAfter.createdAt == recoveryBefore.createdAt;
    assert ghost_ActiveProtocolAdapterSet_EventCount == 1;
    assert ghost_ActiveProtocolAdapterSet_Param_protocolId == protocolId;
    assert ghost_ActiveProtocolAdapterSet_Param_adapter == adapter;
    assert ghost_RebalanceDepositSuccess_EventCount == 1;
    assert ghost_RebalanceDepositSuccess_Param_nonce == rebalanceNonce;
    assert ghost_RebalanceDepositSuccess_Param_amount == amount;
    assert ghost_RebalanceDepositFailure_EventCount == 0;
    assert ghost_RebalanceDepositRecoveryStored_EventCount == 0;
    assert ghost_activeProtocolAdapter_StoreCount == 1;
    assert ghost_activeProtocolAdapter_StoredValue == adapter;
    assert ghost_recoveryMode_StoreCount == 0;
    assert ghost_rebalanceDepositRecovery_nonce_StoreCount == 0;
    assert ghost_rebalanceDepositRecovery_amount_StoreCount == 0;
    assert ghost_rebalanceDepositRecovery_createdAt_StoreCount == 0;
}

/// @notice A failed CCIP rebalance deposit selects the target adapter and stores recovery
/// @dev Verifies unchanged balances and TVL, exact recovery state, storage writes, and failure events
rule ccipReceive_REBALANCE_FailedDepositStoresRecovery() {
    env e;
    Client.Any2EVMMessage message;
    uint256 rebalanceNonce;
    bytes32 protocolId;
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be the registered vault";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require adapterRegistry.getAdapter(e, protocolId) == adapter, "adapter should be registered";
    require adapter.getVault() == currentContract, "adapter should be bound to the vault";
    require adapter.depositReverts(), "adapter deposit should revert";
    require adapter != currentContract, "adapter should not be the vault";
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.REBALANCE, encodeRebalanceData(rebalanceNonce, protocolId)),
        "message data should encode a rebalance";

    uint256 amount = message.destTokenAmounts[0].amount;
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token arithmetic condition
    require amount <= vaultBalanceBefore, "vault asset balance should cover the deposit amount";

    /// @dev set ghost starting values
    require ghost_ActiveProtocolAdapterSet_EventCount == 0;
    require ghost_RebalanceDepositSuccess_EventCount == 0;
    require ghost_RebalanceDepositFailure_EventCount == 0;
    require ghost_RebalanceDepositRecoveryStored_EventCount == 0;
    require ghost_activeProtocolAdapter_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;
    require ghost_rebalanceDepositRecovery_nonce_StoreCount == 0;
    require ghost_rebalanceDepositRecovery_amount_StoreCount == 0;
    require ghost_rebalanceDepositRecovery_createdAt_StoreCount == 0;

    ccipReceive@withrevert(e, message);


    assert !lastReverted;
    Types.RebalanceDepositRecovery recovery = getRebalanceDepositRecovery();
    assert getActiveProtocolAdapter() == adapter;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT;
    assert recovery.rebalanceNonce == rebalanceNonce;
    assert recovery.amount == amount;
    assert recovery.createdAt == e.block.timestamp;
    assert ghost_ActiveProtocolAdapterSet_EventCount == 1;
    assert ghost_ActiveProtocolAdapterSet_Param_protocolId == protocolId;
    assert ghost_ActiveProtocolAdapterSet_Param_adapter == adapter;
    assert ghost_RebalanceDepositSuccess_EventCount == 0;
    assert ghost_RebalanceDepositFailure_EventCount == 1;
    assert ghost_RebalanceDepositFailure_Param_nonce == rebalanceNonce;
    assert ghost_RebalanceDepositFailure_Param_amount == amount;
    assert ghost_RebalanceDepositRecoveryStored_EventCount == 1;
    assert ghost_RebalanceDepositRecoveryStored_Param_nonce == rebalanceNonce;
    assert ghost_RebalanceDepositRecoveryStored_Param_amount == amount;
    assert ghost_activeProtocolAdapter_StoreCount == 1;
    assert ghost_activeProtocolAdapter_StoredValue == adapter;
    assert ghost_recoveryMode_StoreCount == 1 => ghost_recoveryMode_StoredValue == Types.RecoveryMode.REBALANCE_DEPOSIT,
        "recovery mode stored value is only meaningful when the recovery mode hook fires, which may not happen due to state packing";
    assert ghost_rebalanceDepositRecovery_nonce_StoreCount == 1;
    assert ghost_rebalanceDepositRecovery_nonce_StoredValue == rebalanceNonce;
    assert ghost_rebalanceDepositRecovery_amount_StoreCount == 1;
    assert ghost_rebalanceDepositRecovery_amount_StoredValue == amount;
    assert ghost_rebalanceDepositRecovery_createdAt_StoreCount == 1;
    assert ghost_rebalanceDepositRecovery_createdAt_StoredValue == e.block.timestamp;
}

/// ─────────────────── TRY CCIP SEND ───────────────────────────

/// @notice Try CCIP send reverts when the caller is not the vault itself
/// @dev Verifies that an unauthorized call leaves all vault state unchanged and does not bridge assets
rule tryCcipSend_RevertWhen_CallerIsNotSelf() {
    env e;
    uint256 bridgeAmount;
    uint64 destinationChainSelector;
    Types.CcipTx ccipTxType;
    bytes txData;
    uint256 epochNonce;
    uint256 rebalanceNonce;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require bridgeAmount != 0, "bridge amount should not be zero";
    require destinationChainSelector != 0, "destination chain selector should not be zero";
    require destinationChainSelector != getThisChainSelector(), "destination should not be this chain";
    require getCrosschainVault(destinationChainSelector) != 0, "destination vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";
    require (
        ccipTxType == Types.CcipTx.EPOCH_NET_WITHDRAW
            && txData == encodeEpochNonce(epochNonce)
    ) || (
        ccipTxType == Types.CcipTx.REBALANCE
            && txData == encodeRebalanceData(rebalanceNonce, protocolId)
    ), "transaction type and data should encode a supported ChildVault send";

    /// @dev revert condition being verified
    require e.msg.sender != currentContract, "caller should not be the vault";

    storage before = lastStorage;
    address router = getRouter();
    uint256 vaultLinkBalanceBefore = link.balanceOf(currentContract);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);

    /// @dev set ghost starting values
    require ghost_CCIPBridged_EventCount == 0;

    tryCcipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, txData);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore;
    assert link.balanceOf(router) == routerLinkBalanceBefore;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(router) == routerAssetBalanceBefore;
    assert ghost_CCIPBridged_EventCount == 0;
}

/// @notice Try CCIP send reverts when the bridge amount is zero
/// @dev Verifies that CCIP validation rejects zero sends before assets are bridged
rule tryCcipSend_RevertWhen_BridgeAmountIsZero() {
    env e;
    uint64 destinationChainSelector;
    Types.CcipTx ccipTxType;
    bytes txData;
    uint256 epochNonce;
    uint256 rebalanceNonce;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == currentContract, "caller should be the vault";
    require destinationChainSelector != 0, "destination chain selector should not be zero";
    require destinationChainSelector != getThisChainSelector(), "destination should not be this chain";
    require getCrosschainVault(destinationChainSelector) != 0, "destination vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";
    require (
        ccipTxType == Types.CcipTx.EPOCH_NET_WITHDRAW
            && txData == encodeEpochNonce(epochNonce)
    ) || (
        ccipTxType == Types.CcipTx.REBALANCE
            && txData == encodeRebalanceData(rebalanceNonce, protocolId)
    ), "transaction type and data should encode a supported ChildVault send";

    /// @dev revert condition being verified
    uint256 bridgeAmount = 0;

    storage before = lastStorage;
    address router = getRouter();
    uint256 vaultLinkBalanceBefore = link.balanceOf(currentContract);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);

    /// @dev set ghost starting values
    require ghost_CCIPBridged_EventCount == 0;

    tryCcipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, txData);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore;
    assert link.balanceOf(router) == routerLinkBalanceBefore;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(router) == routerAssetBalanceBefore;
    assert ghost_CCIPBridged_EventCount == 0;
}

/// @notice Try CCIP send reverts when the destination chain selector is zero
/// @dev Verifies that CCIP validation rejects an unset destination before assets are bridged
rule tryCcipSend_RevertWhen_DestinationChainIsZero() {
    env e;
    uint256 bridgeAmount;
    Types.CcipTx ccipTxType;
    bytes txData;
    uint256 epochNonce;
    uint256 rebalanceNonce;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == currentContract, "caller should be the vault";
    require bridgeAmount != 0, "bridge amount should not be zero";
    require getThisChainSelector() != 0, "this chain selector should not be zero";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";
    require (
        ccipTxType == Types.CcipTx.EPOCH_NET_WITHDRAW
            && txData == encodeEpochNonce(epochNonce)
    ) || (
        ccipTxType == Types.CcipTx.REBALANCE
            && txData == encodeRebalanceData(rebalanceNonce, protocolId)
    ), "transaction type and data should encode a supported ChildVault send";

    /// @dev revert condition being verified
    uint64 destinationChainSelector = 0;

    storage before = lastStorage;
    address router = getRouter();
    uint256 vaultLinkBalanceBefore = link.balanceOf(currentContract);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);

    /// @dev mock token arithmetic conditions
    require bridgeAmount <= vaultAssetBalanceBefore, "vault asset balance should cover the bridge amount";
    require routerAssetBalanceBefore <= max_uint256 - bridgeAmount, "router asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_CCIPBridged_EventCount == 0;

    tryCcipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, txData);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore;
    assert link.balanceOf(router) == routerLinkBalanceBefore;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(router) == routerAssetBalanceBefore;
    assert ghost_CCIPBridged_EventCount == 0;
}

/// @notice Try CCIP send reverts when the destination is this chain
/// @dev Verifies that CCIP validation rejects same-chain sends before assets are bridged
rule tryCcipSend_RevertWhen_DestinationIsSelfChain() {
    env e;
    uint256 bridgeAmount;
    Types.CcipTx ccipTxType;
    bytes txData;
    uint256 epochNonce;
    uint256 rebalanceNonce;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == currentContract, "caller should be the vault";
    require bridgeAmount != 0, "bridge amount should not be zero";
    require getThisChainSelector() != 0, "this chain selector should not be zero";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";
    require (
        ccipTxType == Types.CcipTx.EPOCH_NET_WITHDRAW
            && txData == encodeEpochNonce(epochNonce)
    ) || (
        ccipTxType == Types.CcipTx.REBALANCE
            && txData == encodeRebalanceData(rebalanceNonce, protocolId)
    ), "transaction type and data should encode a supported ChildVault send";

    /// @dev revert condition being verified
    uint64 destinationChainSelector = getThisChainSelector();

    storage before = lastStorage;
    address router = getRouter();
    uint256 vaultLinkBalanceBefore = link.balanceOf(currentContract);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);

    /// @dev mock token arithmetic conditions
    require bridgeAmount <= vaultAssetBalanceBefore, "vault asset balance should cover the bridge amount";
    require routerAssetBalanceBefore <= max_uint256 - bridgeAmount, "router asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_CCIPBridged_EventCount == 0;

    tryCcipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, txData);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore;
    assert link.balanceOf(router) == routerLinkBalanceBefore;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(router) == routerAssetBalanceBefore;
    assert ghost_CCIPBridged_EventCount == 0;
}

/// @notice Try CCIP send reverts when the destination vault is not registered
/// @dev Verifies that CCIP validation rejects unregistered destinations before assets are bridged
rule tryCcipSend_RevertWhen_DestinationVaultNotRegistered() {
    env e;
    uint256 bridgeAmount;
    uint64 destinationChainSelector;
    Types.CcipTx ccipTxType;
    bytes txData;
    uint256 epochNonce;
    uint256 rebalanceNonce;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == currentContract, "caller should be the vault";
    require bridgeAmount != 0, "bridge amount should not be zero";
    require destinationChainSelector != 0, "destination chain selector should not be zero";
    require destinationChainSelector != getThisChainSelector(), "destination should not be this chain";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";
    require (
        ccipTxType == Types.CcipTx.EPOCH_NET_WITHDRAW
            && txData == encodeEpochNonce(epochNonce)
    ) || (
        ccipTxType == Types.CcipTx.REBALANCE
            && txData == encodeRebalanceData(rebalanceNonce, protocolId)
    ), "transaction type and data should encode a supported ChildVault send";

    /// @dev revert condition being verified
    require getCrosschainVault(destinationChainSelector) == 0, "destination vault should not be registered";

    storage before = lastStorage;
    address router = getRouter();
    uint256 vaultLinkBalanceBefore = link.balanceOf(currentContract);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);

    /// @dev mock token arithmetic conditions
    require bridgeAmount <= vaultAssetBalanceBefore, "vault asset balance should cover the bridge amount";
    require routerAssetBalanceBefore <= max_uint256 - bridgeAmount, "router asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_CCIPBridged_EventCount == 0;

    tryCcipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, txData);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore;
    assert link.balanceOf(router) == routerLinkBalanceBefore;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(router) == routerAssetBalanceBefore;
    assert ghost_CCIPBridged_EventCount == 0;
}

/// @notice Try CCIP send reverts when the router fee lookup fails
/// @dev Verifies atomic rollback because direct self-call sends are not caught
rule tryCcipSend_RevertWhen_RouterGetFeeReverts() {
    env e;
    uint256 bridgeAmount;
    uint64 destinationChainSelector;
    Types.CcipTx ccipTxType;
    bytes txData;
    uint256 epochNonce;
    uint256 rebalanceNonce;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == currentContract, "caller should be the vault";
    require bridgeAmount != 0, "bridge amount should not be zero";
    require destinationChainSelector != 0, "destination chain selector should not be zero";
    require destinationChainSelector != getThisChainSelector(), "destination should not be this chain";
    require getCrosschainVault(destinationChainSelector) != 0, "destination vault should be registered";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";
    require (
        ccipTxType == Types.CcipTx.EPOCH_NET_WITHDRAW
            && txData == encodeEpochNonce(epochNonce)
    ) || (
        ccipTxType == Types.CcipTx.REBALANCE
            && txData == encodeRebalanceData(rebalanceNonce, protocolId)
    ), "transaction type and data should encode a supported ChildVault send";

    /// @dev revert condition being verified
    require ccipRouter.getFeeReverts(), "router fee lookup should revert";

    storage before = lastStorage;
    address router = getRouter();
    uint256 vaultLinkBalanceBefore = link.balanceOf(currentContract);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);

    /// @dev mock token arithmetic conditions
    require bridgeAmount <= vaultAssetBalanceBefore, "vault asset balance should cover the bridge amount";
    require routerAssetBalanceBefore <= max_uint256 - bridgeAmount, "router asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_CCIPBridged_EventCount == 0;

    tryCcipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, txData);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore;
    assert link.balanceOf(router) == routerLinkBalanceBefore;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(router) == routerAssetBalanceBefore;
    assert ghost_CCIPBridged_EventCount == 0;
}

/// @notice Try CCIP send reverts when the router send fails
/// @dev Verifies atomic rollback because direct self-call sends are not caught
rule tryCcipSend_RevertWhen_RouterCcipSendReverts() {
    env e;
    uint256 bridgeAmount;
    uint64 destinationChainSelector;
    Types.CcipTx ccipTxType;
    bytes txData;
    uint256 epochNonce;
    uint256 rebalanceNonce;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == currentContract, "caller should be the vault";
    require bridgeAmount != 0, "bridge amount should not be zero";
    require destinationChainSelector != 0, "destination chain selector should not be zero";
    require destinationChainSelector != getThisChainSelector(), "destination should not be this chain";
    require getCrosschainVault(destinationChainSelector) != 0, "destination vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require (
        ccipTxType == Types.CcipTx.EPOCH_NET_WITHDRAW
            && txData == encodeEpochNonce(epochNonce)
    ) || (
        ccipTxType == Types.CcipTx.REBALANCE
            && txData == encodeRebalanceData(rebalanceNonce, protocolId)
    ), "transaction type and data should encode a supported ChildVault send";

    /// @dev revert condition being verified
    require ccipRouter.ccipSendReverts(), "router send should revert";

    storage before = lastStorage;
    uint256 fee = ccipRouter.getFee();
    address router = getRouter();
    uint256 vaultLinkBalanceBefore = link.balanceOf(currentContract);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);

    /// @dev mock token arithmetic conditions
    require fee <= vaultLinkBalanceBefore, "vault LINK balance should cover the CCIP fee";
    require routerLinkBalanceBefore <= max_uint256 - fee, "router LINK balance should not overflow";
    require bridgeAmount <= vaultAssetBalanceBefore, "vault asset balance should cover the bridge amount";
    require routerAssetBalanceBefore <= max_uint256 - bridgeAmount, "router asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_CCIPBridged_EventCount == 0;

    tryCcipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, txData);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore;
    assert link.balanceOf(router) == routerLinkBalanceBefore;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(router) == routerAssetBalanceBefore;
    assert ghost_CCIPBridged_EventCount == 0;
}

/// @notice Try CCIP send forwards a valid self-call to BaseVault CCIP execution
/// @dev Verifies exact LINK and asset transfers and the emitted bridge event
rule tryCcipSend_Success() {
    env e;
    uint256 bridgeAmount;
    uint64 destinationChainSelector;
    Types.CcipTx ccipTxType;
    bytes txData;
    uint256 epochNonce;
    uint256 rebalanceNonce;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require bridgeAmount != 0, "bridge amount should not be zero";
    require destinationChainSelector != 0, "destination chain selector should not be zero";
    require destinationChainSelector != getThisChainSelector(), "destination should not be this chain";
    require getCrosschainVault(destinationChainSelector) != 0, "destination vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";
    require (
        ccipTxType == Types.CcipTx.EPOCH_NET_WITHDRAW
            && txData == encodeEpochNonce(epochNonce)
    ) || (
        ccipTxType == Types.CcipTx.REBALANCE
            && txData == encodeRebalanceData(rebalanceNonce, protocolId)
    ), "transaction type and data should encode a supported ChildVault send";

    /// @dev success condition being verified
    require e.msg.sender == currentContract, "caller should be the vault";

    uint256 fee = ccipRouter.getFee();
    address router = getRouter();
    uint256 vaultLinkBalanceBefore = link.balanceOf(currentContract);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);

    /// @dev mock token arithmetic conditions
    require fee <= vaultLinkBalanceBefore, "vault LINK balance should cover the CCIP fee";
    require routerLinkBalanceBefore <= max_uint256 - fee, "router LINK balance should not overflow";
    require bridgeAmount <= vaultAssetBalanceBefore, "vault asset balance should cover the bridge amount";
    require routerAssetBalanceBefore <= max_uint256 - bridgeAmount, "router asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_CCIPBridged_EventCount == 0;

    tryCcipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, txData);

    assert !lastReverted;
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore - fee;
    assert link.balanceOf(router) == routerLinkBalanceBefore + fee;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore - bridgeAmount;
    assert asset.balanceOf(router) == routerAssetBalanceBefore + bridgeAmount;
    assert ghost_CCIPBridged_EventCount == 1;
    assert ghost_CCIPBridged_Param_ccipMessageId != to_bytes32(0);
    assert ghost_CCIPBridged_Param_amount == bridgeAmount;
    assert ghost_CCIPBridged_Param_ccipTxType == ccipTxType;
}

/// ─────────────────── RECOVER FAILED EPOCH DEPOSIT ───────────

/// @notice Epoch deposit recovery reverts when the call is reentrant
/// @dev Verifies that recovery state, balances, TVL, and events remain unchanged
rule recoverFailedEpochDeposit_RevertWhen_ReentrantCall() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getRecoveryMode() == Types.RecoveryMode.EPOCH_DEPOSIT, "epoch deposit recovery should be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.depositReverts(), "adapter deposit should not revert";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";

    storage before = lastStorage;
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev set ghost starting values
    require ghost_EpochDepositRecoveryCleared_EventCount == 0;
    require ghost_DepositToStrategySuccess_EventCount == 0;

    recoverFailedEpochDeposit@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_EpochDepositRecoveryCleared_EventCount == 0;
    assert ghost_DepositToStrategySuccess_EventCount == 0;
}

/// @notice Epoch deposit recovery reverts when no epoch deposit recovery is pending
/// @dev Verifies that balances, TVL, and events remain unchanged
rule recoverFailedEpochDeposit_RevertWhen_NoPendingRecovery() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.depositReverts(), "adapter deposit should not revert";

    /// @dev revert condition being verified
    require getRecoveryMode() != Types.RecoveryMode.EPOCH_DEPOSIT, "epoch deposit recovery should not be pending";

    storage before = lastStorage;
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev set ghost starting values
    require ghost_EpochDepositRecoveryCleared_EventCount == 0;
    require ghost_DepositToStrategySuccess_EventCount == 0;

    recoverFailedEpochDeposit@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_EpochDepositRecoveryCleared_EventCount == 0;
    assert ghost_DepositToStrategySuccess_EventCount == 0;
}

/// @notice Epoch deposit recovery reverts when no active adapter is set
/// @dev Verifies that recovery state, balances, TVL, and events remain unchanged
rule recoverFailedEpochDeposit_RevertWhen_NoActiveAdapter() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.EPOCH_DEPOSIT, "epoch deposit recovery should be pending";
    require getEpochDepositRecovery().amount != 0, "recovery amount should not be zero";
    require !adapter.depositReverts(), "adapter deposit should not revert";

    /// @dev revert condition being verified
    require getActiveProtocolAdapter() == 0, "active adapter should not be set";

    storage before = lastStorage;
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev set ghost starting values
    require ghost_EpochDepositRecoveryCleared_EventCount == 0;
    require ghost_DepositToStrategySuccess_EventCount == 0;

    recoverFailedEpochDeposit@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_EpochDepositRecoveryCleared_EventCount == 0;
    assert ghost_DepositToStrategySuccess_EventCount == 0;
}

/// @notice Epoch deposit recovery reverts when the adapter deposit fails
/// @dev Verifies atomic rollback of recovery state, balances, TVL, and events
rule recoverFailedEpochDeposit_RevertWhen_DepositFails() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.EPOCH_DEPOSIT, "epoch deposit recovery should be pending";
    require getEpochDepositRecovery().amount != 0, "recovery amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";

    /// @dev revert condition being verified
    require adapter.depositReverts(), "adapter deposit should revert";

    storage before = lastStorage;
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev set ghost starting values
    require ghost_EpochDepositRecoveryCleared_EventCount == 0;
    require ghost_DepositToStrategySuccess_EventCount == 0;

    recoverFailedEpochDeposit@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_EpochDepositRecoveryCleared_EventCount == 0;
    assert ghost_DepositToStrategySuccess_EventCount == 0;
}

/// @notice Epoch deposit recovery deposits the stored amount and clears recovery
/// @dev Verifies balances, TVL, recovery deletion, storage writes, and events
rule recoverFailedEpochDeposit_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.EPOCH_DEPOSIT, "epoch deposit recovery should be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.depositReverts(), "adapter deposit should not revert";
    require adapter != currentContract, "adapter should not be the vault";

    Types.EpochRecovery recovery = getEpochDepositRecovery();
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token and adapter arithmetic conditions
    require recovery.amount != 0, "recovery amount should not be zero";
    require recovery.amount <= vaultAssetBalanceBefore, "vault asset balance should cover the recovery amount";
    require adapterAssetBalanceBefore <= max_uint256 - recovery.amount, "adapter asset balance should not overflow";
    require adapterTVLBefore <= max_uint256 - recovery.amount, "adapter TVL should not overflow";

    /// @dev set ghost starting values
    require ghost_EpochDepositRecoveryCleared_EventCount == 0;
    require ghost_DepositToStrategySuccess_EventCount == 0;
    require ghost_epochDepositRecovery_epochNonce_StoreCount == 0;
    require ghost_epochDepositRecovery_amount_StoreCount == 0;
    require ghost_epochDepositRecovery_createdAt_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;

    recoverFailedEpochDeposit@withrevert(e);

    assert !lastReverted;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore - recovery.amount;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore + recovery.amount;
    assert adapter.getTVL() == adapterTVLBefore + recovery.amount;
    assert getRecoveryMode() == Types.RecoveryMode.NONE;
    assert getEpochDepositRecovery().epochNonce == 0;
    assert getEpochDepositRecovery().amount == 0;
    assert getEpochDepositRecovery().createdAt == 0;
    assert ghost_EpochDepositRecoveryCleared_EventCount == 1;
    assert ghost_EpochDepositRecoveryCleared_Param_epochNonce == recovery.epochNonce;
    assert ghost_DepositToStrategySuccess_EventCount == 1;
    assert ghost_DepositToStrategySuccess_Param_epochNonce == recovery.epochNonce;
    assert ghost_DepositToStrategySuccess_Param_amount == recovery.amount;
    assert ghost_epochDepositRecovery_epochNonce_StoreCount == 1;
    assert ghost_epochDepositRecovery_epochNonce_StoredValue == 0;
    assert ghost_epochDepositRecovery_amount_StoreCount == 1;
    assert ghost_epochDepositRecovery_amount_StoredValue == 0;
    assert ghost_epochDepositRecovery_createdAt_StoreCount == 1;
    assert ghost_epochDepositRecovery_createdAt_StoredValue == 0;
    assert ghost_recoveryMode_StoreCount == 1 => ghost_recoveryMode_StoredValue == Types.RecoveryMode.NONE,
        "recovery mode stored value is only meaningful when the recovery mode hook fires, which may not happen due to state packing";
}

/// ─────────────────── RECOVER FAILED REBALANCE DEPOSIT ───────

/// @notice Rebalance deposit recovery reverts when the call is reentrant
/// @dev Verifies that recovery state, balances, TVL, and events remain unchanged
rule recoverFailedRebalanceDeposit_RevertWhen_ReentrantCall() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT, "rebalance deposit recovery should be pending";
    require getRebalanceDepositRecovery().amount != 0, "recovery amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.depositReverts(), "adapter deposit should not revert";
    require adapter != currentContract, "adapter should not be the vault";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";

    storage before = lastStorage;
    Types.RebalanceDepositRecovery recovery = getRebalanceDepositRecovery();
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token and adapter arithmetic conditions
    require recovery.amount <= vaultAssetBalanceBefore, "vault asset balance should cover the recovery amount";
    require adapterAssetBalanceBefore <= max_uint256 - recovery.amount, "adapter asset balance should not overflow";
    require adapterTVLBefore <= max_uint256 - recovery.amount, "adapter TVL should not overflow";

    /// @dev set ghost starting values
    require ghost_RebalanceDepositRecoveryCleared_EventCount == 0;
    require ghost_RebalanceDepositSuccess_EventCount == 0;

    recoverFailedRebalanceDeposit@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_RebalanceDepositRecoveryCleared_EventCount == 0;
    assert ghost_RebalanceDepositSuccess_EventCount == 0;
}

/// @notice Rebalance deposit recovery reverts when no rebalance deposit recovery is pending
/// @dev Verifies that balances, TVL, and events remain unchanged
rule recoverFailedRebalanceDeposit_RevertWhen_NoPendingRecovery() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRebalanceDepositRecovery().amount != 0, "recovery amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.depositReverts(), "adapter deposit should not revert";
    require adapter != currentContract, "adapter should not be the vault";

    /// @dev revert condition being verified
    require getRecoveryMode() != Types.RecoveryMode.REBALANCE_DEPOSIT,
        "rebalance deposit recovery should not be pending";

    storage before = lastStorage;
    Types.RebalanceDepositRecovery recovery = getRebalanceDepositRecovery();
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token and adapter arithmetic conditions
    require recovery.amount <= vaultAssetBalanceBefore, "vault asset balance should cover the recovery amount";
    require adapterAssetBalanceBefore <= max_uint256 - recovery.amount, "adapter asset balance should not overflow";
    require adapterTVLBefore <= max_uint256 - recovery.amount, "adapter TVL should not overflow";

    /// @dev set ghost starting values
    require ghost_RebalanceDepositRecoveryCleared_EventCount == 0;
    require ghost_RebalanceDepositSuccess_EventCount == 0;

    recoverFailedRebalanceDeposit@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_RebalanceDepositRecoveryCleared_EventCount == 0;
    assert ghost_RebalanceDepositSuccess_EventCount == 0;
}

/// @notice Rebalance deposit recovery reverts when no active adapter is set
/// @dev Verifies that recovery state, balances, TVL, and events remain unchanged
rule recoverFailedRebalanceDeposit_RevertWhen_NoActiveAdapter() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT, "rebalance deposit recovery should be pending";
    require getRebalanceDepositRecovery().amount != 0, "recovery amount should not be zero";
    require !adapter.depositReverts(), "adapter deposit should not revert";
    require adapter != currentContract, "adapter should not be the vault";

    /// @dev revert condition being verified
    require getActiveProtocolAdapter() == 0, "active adapter should not be set";

    storage before = lastStorage;
    Types.RebalanceDepositRecovery recovery = getRebalanceDepositRecovery();
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token and adapter arithmetic conditions
    require recovery.amount <= vaultAssetBalanceBefore, "vault asset balance should cover the recovery amount";
    require adapterAssetBalanceBefore <= max_uint256 - recovery.amount, "adapter asset balance should not overflow";
    require adapterTVLBefore <= max_uint256 - recovery.amount, "adapter TVL should not overflow";

    /// @dev set ghost starting values
    require ghost_RebalanceDepositRecoveryCleared_EventCount == 0;
    require ghost_RebalanceDepositSuccess_EventCount == 0;

    recoverFailedRebalanceDeposit@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_RebalanceDepositRecoveryCleared_EventCount == 0;
    assert ghost_RebalanceDepositSuccess_EventCount == 0;
}

/// @notice Rebalance deposit recovery reverts when the adapter deposit fails
/// @dev Verifies atomic rollback of recovery state, balances, TVL, and events
rule recoverFailedRebalanceDeposit_RevertWhen_DepositFails() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT, "rebalance deposit recovery should be pending";
    require getRebalanceDepositRecovery().amount != 0, "recovery amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require adapter != currentContract, "adapter should not be the vault";

    /// @dev revert condition being verified
    require adapter.depositReverts(), "adapter deposit should revert";

    storage before = lastStorage;
    Types.RebalanceDepositRecovery recovery = getRebalanceDepositRecovery();
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token and adapter arithmetic conditions
    require recovery.amount <= vaultAssetBalanceBefore, "vault asset balance should cover the recovery amount";
    require adapterAssetBalanceBefore <= max_uint256 - recovery.amount, "adapter asset balance should not overflow";
    require adapterTVLBefore <= max_uint256 - recovery.amount, "adapter TVL should not overflow";

    /// @dev set ghost starting values
    require ghost_RebalanceDepositRecoveryCleared_EventCount == 0;
    require ghost_RebalanceDepositSuccess_EventCount == 0;

    recoverFailedRebalanceDeposit@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_RebalanceDepositRecoveryCleared_EventCount == 0;
    assert ghost_RebalanceDepositSuccess_EventCount == 0;
}

/// @notice Rebalance deposit recovery deposits the stored amount and clears recovery
/// @dev Verifies balances, TVL, recovery deletion, storage writes, and events
rule recoverFailedRebalanceDeposit_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT, "rebalance deposit recovery should be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.depositReverts(), "adapter deposit should not revert";
    require adapter != currentContract, "adapter should not be the vault";

    Types.RebalanceDepositRecovery recovery = getRebalanceDepositRecovery();
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token and adapter arithmetic conditions
    require recovery.amount != 0, "recovery amount should not be zero";
    require recovery.amount <= vaultAssetBalanceBefore, "vault asset balance should cover the recovery amount";
    require adapterAssetBalanceBefore <= max_uint256 - recovery.amount, "adapter asset balance should not overflow";
    require adapterTVLBefore <= max_uint256 - recovery.amount, "adapter TVL should not overflow";

    /// @dev set ghost starting values
    require ghost_RebalanceDepositRecoveryCleared_EventCount == 0;
    require ghost_RebalanceDepositSuccess_EventCount == 0;
    require ghost_rebalanceDepositRecovery_nonce_StoreCount == 0;
    require ghost_rebalanceDepositRecovery_amount_StoreCount == 0;
    require ghost_rebalanceDepositRecovery_createdAt_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;

    recoverFailedRebalanceDeposit@withrevert(e);

    assert !lastReverted;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore - recovery.amount;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore + recovery.amount;
    assert adapter.getTVL() == adapterTVLBefore + recovery.amount;
    assert getRecoveryMode() == Types.RecoveryMode.NONE;
    assert getRebalanceDepositRecovery().rebalanceNonce == 0;
    assert getRebalanceDepositRecovery().amount == 0;
    assert getRebalanceDepositRecovery().createdAt == 0;
    assert ghost_RebalanceDepositRecoveryCleared_EventCount == 1;
    assert ghost_RebalanceDepositRecoveryCleared_Param_nonce == recovery.rebalanceNonce;
    assert ghost_RebalanceDepositSuccess_EventCount == 1;
    assert ghost_RebalanceDepositSuccess_Param_nonce == recovery.rebalanceNonce;
    assert ghost_RebalanceDepositSuccess_Param_amount == recovery.amount;
    assert ghost_rebalanceDepositRecovery_nonce_StoreCount == 1;
    assert ghost_rebalanceDepositRecovery_nonce_StoredValue == 0;
    assert ghost_rebalanceDepositRecovery_amount_StoreCount == 1;
    assert ghost_rebalanceDepositRecovery_amount_StoredValue == 0;
    assert ghost_rebalanceDepositRecovery_createdAt_StoreCount == 1;
    assert ghost_rebalanceDepositRecovery_createdAt_StoredValue == 0;
    assert ghost_recoveryMode_StoreCount == 1 => ghost_recoveryMode_StoredValue == Types.RecoveryMode.NONE,
        "recovery mode stored value is only meaningful when the recovery mode hook fires, which may not happen due to state packing";
}

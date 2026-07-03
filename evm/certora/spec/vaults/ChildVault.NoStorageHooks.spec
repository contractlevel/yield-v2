using MockAdapterRegistry as adapterRegistry;
using MockProtocolAdapter as adapter;
using MockProtocolAdapter as targetAdapter;
using MockInvalidProtocolAdapter as invalidAdapter;
using MockUSDC as asset;
using MockLINK as link;
using MockCCIPRouter as ccipRouter;

/// Verification of ChildVault flows that cannot run with typed storage hooks.
/// @author @contractlevel
/// @notice Verifies observable ChildVault behavior through getters, balances, reverts, and event hooks.
/// @dev This spec intentionally excludes Sstore hooks because Certora storage analysis fails on some ERC-7201/dynamic-bytes paths.

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
    function clearCcipSendRecovery() external returns (Types.CcipSendRecovery);

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
    function getCcipSendRecoveryEpochNonce() external returns (uint256) envfree;
    function getCcipSendRecoveryRebalanceData() external returns (uint256, bytes32) envfree;
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
    function ccipRouter.getFee(uint64, Client.EVM2AnyMessage) external returns (uint256) envfree;
    function ccipRouter.ccipSend(uint64, Client.EVM2AnyMessage) external returns (bytes32);
    function ccipRouter.getFeeReverts() external returns (bool) envfree;
    function ccipRouter.ccipSendReverts() external returns (bool) envfree;
    function link.transfer(address, uint256) external returns (bool);
    function asset.transfer(address, uint256) external returns (bool);
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

definition WithdrawFromStrategyFailureEvent() returns bytes32 =
// keccak256("WithdrawFromStrategyFailure(uint256,uint256)")
    to_bytes32(0x37f4f811d10c7b3a19d28781f245b42c5320a1736a27b2b43b34f9360c760e38);

definition RebalanceWithdrawSuccessEvent() returns bytes32 =
// keccak256("RebalanceWithdrawSuccess(uint256,uint256)")
    to_bytes32(0xbda9c2bb85185244245a5c12fdd1e1107c46dc54a6d54d015bccf78aec5a8668);

definition RebalanceWithdrawFailureEvent() returns bytes32 =
// keccak256("RebalanceWithdrawFailure(uint256)")
    to_bytes32(0x419b356601ce305e332b89009cbc4ec088b901dadd6b8a6e19ee038183ff64e6);

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
/// @dev Event hooks only. Typed storage hooks belong in ChildVault.spec.
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
                             RULES
//////////////////////////////////////////////////////////////*/

/// ─────────────────── CCIP SEND ───────────────────────────────

/// @notice ChildVault CCIP send reverts when any recovery operation is already pending
/// @dev Verifies that a pending recovery cannot be overwritten by a new send
rule ccipSend_RevertWhen_RecoveryAlreadyPending() {
    env e;
    uint256 bridgeAmount;
    uint64 destinationChainSelector;
    Types.CcipTx ccipTxType;
    bytes txData;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require bridgeAmount != 0, "bridge amount should not be zero";
    require destinationChainSelector != 0, "destination chain selector should not be zero";
    require destinationChainSelector != getThisChainSelector(), "destination should not be this chain";
    require getCrosschainVault(destinationChainSelector) != 0, "destination vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev revert condition being verified
    require getRecoveryMode() != Types.RecoveryMode.NONE, "recovery should be pending";


    ccipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, txData);

    assert lastReverted;
}

/// @notice ChildVault CCIP send reverts when the bridge amount is zero
/// @dev Verifies that an invalid bridge amount leaves all vault state unchanged
rule ccipSend_RevertWhen_BridgeAmountIsZero() {
    env e;
    uint64 destinationChainSelector;
    Types.CcipTx ccipTxType;
    bytes txData;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require destinationChainSelector != 0, "destination chain selector should not be zero";
    require destinationChainSelector != getThisChainSelector(), "destination should not be this chain";
    require getCrosschainVault(destinationChainSelector) != 0, "destination vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev revert condition being verified
    uint256 bridgeAmount = 0;


    ccipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, txData);

    assert lastReverted;
}

/// @notice ChildVault CCIP send reverts when the destination chain selector is zero
/// @dev Verifies that an invalid destination leaves all vault state unchanged
rule ccipSend_RevertWhen_DestinationChainIsZero() {
    env e;
    uint256 bridgeAmount;
    Types.CcipTx ccipTxType;
    bytes txData;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require bridgeAmount != 0, "bridge amount should not be zero";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev revert condition being verified
    uint64 destinationChainSelector = 0;


    ccipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, txData);

    assert lastReverted;
}

/// @notice ChildVault CCIP send reverts when the destination is the current chain
/// @dev Verifies that an invalid self-chain destination leaves all vault state unchanged
rule ccipSend_RevertWhen_DestinationIsSelfChain() {
    env e;
    uint256 bridgeAmount;
    Types.CcipTx ccipTxType;
    bytes txData;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require bridgeAmount != 0, "bridge amount should not be zero";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev revert condition being verified
    uint64 destinationChainSelector = getThisChainSelector();


    ccipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, txData);

    assert lastReverted;
}

/// @notice ChildVault CCIP send reverts when no destination vault is registered
/// @dev Verifies that an unset destination vault leaves all vault state unchanged
rule ccipSend_RevertWhen_DestinationVaultNotRegistered() {
    env e;
    uint256 bridgeAmount;
    uint64 destinationChainSelector;
    Types.CcipTx ccipTxType;
    bytes txData;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require bridgeAmount != 0, "bridge amount should not be zero";
    require destinationChainSelector != 0, "destination chain selector should not be zero";
    require destinationChainSelector != getThisChainSelector(), "destination should not be this chain";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev revert condition being verified
    require getCrosschainVault(destinationChainSelector) == 0, "destination vault should not be registered";


    ccipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, txData);

    assert lastReverted;
}

/// @notice A successful ChildVault CCIP send bridges the asset without storing recovery
/// @dev Verifies exact LINK and asset balances, unchanged recovery state, events
rule ccipSend_Success() {
    env e;
    uint256 bridgeAmount;
    uint64 destinationChainSelector;
    Types.CcipTx ccipTxType;
    bytes txData;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require bridgeAmount != 0, "bridge amount should not be zero";
    require destinationChainSelector != 0, "destination chain selector should not be zero";
    require destinationChainSelector != getThisChainSelector(), "destination should not be this chain";
    require getCrosschainVault(destinationChainSelector) != 0, "destination vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

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
    require ghost_CcipSendRecoveryStored_EventCount == 0;

    ccipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, txData);

    assert !lastReverted;
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore - fee;
    assert link.balanceOf(router) == routerLinkBalanceBefore + fee;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore - bridgeAmount;
    assert asset.balanceOf(router) == routerAssetBalanceBefore + bridgeAmount;
    assert getRecoveryMode() == Types.RecoveryMode.NONE;
    assert ghost_CCIPBridged_EventCount == 1;
    assert ghost_CCIPBridged_Param_ccipMessageId != to_bytes32(0);
    assert ghost_CCIPBridged_Param_amount == bridgeAmount;
    assert ghost_CCIPBridged_Param_ccipTxType == ccipTxType;
    assert ghost_CcipSendRecoveryStored_EventCount == 0;
}

/// @notice ChildVault stores CCIP send recovery when the router fee lookup fails
/// @dev Verifies unchanged token balances, exact recovery state, events
rule ccipSend_When_RouterGetFeeReverts_StoresRecovery() {
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
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
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

    /// @dev failure condition being verified
    require ccipRouter.getFeeReverts(), "router fee lookup should revert";

    address router = getRouter();
    uint256 vaultLinkBalanceBefore = link.balanceOf(currentContract);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);

    /// @dev set ghost starting values
    require ghost_CCIPBridged_EventCount == 0;
    require ghost_CcipSendRecoveryStored_EventCount == 0;

    ccipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, txData);

    assert !lastReverted;
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore;
    assert link.balanceOf(router) == routerLinkBalanceBefore;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(router) == routerAssetBalanceBefore;
    assert getRecoveryMode() == Types.RecoveryMode.CCIP_SEND;
    assert getCcipSendRecoveryTxType() == ccipTxType;
    assert getCcipSendRecoveryAmount() == bridgeAmount;
    assert getCcipSendRecoveryDestinationChainSelector() == destinationChainSelector;
    assert getCcipSendRecoveryCreatedAt() == e.block.timestamp;
    // assert ccipTxType == Types.CcipTx.EPOCH_NET_WITHDRAW
    //     => getCcipSendRecoveryTxData() == encodeEpochNonce(epochNonce);
    // assert ccipTxType == Types.CcipTx.REBALANCE
    //     => getCcipSendRecoveryTxData() == encodeRebalanceData(rebalanceNonce, protocolId);
    // assert getCcipSendRecoveryTxData() == txData;
    assert ghost_CCIPBridged_EventCount == 0;
    assert ghost_CcipSendRecoveryStored_EventCount == 1;
    assert ghost_CcipSendRecoveryStored_Param_ccipTxType == ccipTxType;
    assert ghost_CcipSendRecoveryStored_Param_destinationChainSelector == destinationChainSelector;
    assert ghost_CcipSendRecoveryStored_Param_amount == bridgeAmount;
}

/// @notice ChildVault stores CCIP send recovery when the router send fails
/// @dev Verifies atomic token rollback, exact recovery state, events
rule ccipSend_When_RouterCcipSendReverts_StoresRecovery() {
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
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
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

    /// @dev failure condition being verified
    require ccipRouter.ccipSendReverts(), "router send should revert";

    address router = getRouter();
    uint256 vaultLinkBalanceBefore = link.balanceOf(currentContract);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);

    /// @dev set ghost starting values
    require ghost_CCIPBridged_EventCount == 0;
    require ghost_CcipSendRecoveryStored_EventCount == 0;

    ccipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, txData);

    assert !lastReverted;
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore;
    assert link.balanceOf(router) == routerLinkBalanceBefore;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(router) == routerAssetBalanceBefore;
    assert getRecoveryMode() == Types.RecoveryMode.CCIP_SEND;
    assert getCcipSendRecoveryTxType() == ccipTxType;
    assert getCcipSendRecoveryAmount() == bridgeAmount;
    assert getCcipSendRecoveryDestinationChainSelector() == destinationChainSelector;
    assert getCcipSendRecoveryCreatedAt() == e.block.timestamp;
    // assert ccipTxType == Types.CcipTx.EPOCH_NET_WITHDRAW
    //     => getCcipSendRecoveryTxData() == encodeEpochNonce(epochNonce);
    // assert ccipTxType == Types.CcipTx.REBALANCE
    //     => getCcipSendRecoveryTxData() == encodeRebalanceData(rebalanceNonce, protocolId);
    // assert getCcipSendRecoveryTxData() == txData;
    assert ghost_CCIPBridged_EventCount == 0;
    assert ghost_CcipSendRecoveryStored_EventCount == 1;
    assert ghost_CcipSendRecoveryStored_Param_ccipTxType == ccipTxType;
    assert ghost_CcipSendRecoveryStored_Param_destinationChainSelector == destinationChainSelector;
    assert ghost_CcipSendRecoveryStored_Param_amount == bridgeAmount;
}

/// ─────────────────── EXECUTE EPOCH WITHDRAW ──────────────────

/// @notice Epoch withdraw reverts when the caller does not have the epoch operator role
/// @dev Verifies that an unauthorized call leaves all vault state unchanged
rule executeEpochWithdraw_RevertWhen_CallerDoesNotHaveEPOCH_OPERATOR_ROLE() {
    env e;
    uint256 epochNonce;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require amount != 0, "amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() >= amount, "adapter TVL should cover the withdraw amount";
    require getCrosschainVault(getParentChainSelector()) != 0, "parent vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require currentContract.i_parentChainSelector != 0 && currentContract.i_parentChainSelector != currentContract.i_thisChainSelector,
        "destination selector should be valid";

    /// @dev revert condition being verified
    require !hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);


    executeEpochWithdraw@withrevert(e, epochNonce, amount);

    assert lastReverted;
}

/// @notice Epoch withdraw reverts when called during an active non-reentrant execution
/// @dev Verifies that a reentrant call leaves all vault state unchanged
rule executeEpochWithdraw_RevertWhen_ReentrantCall() {
    env e;
    uint256 epochNonce;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require amount != 0, "amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() >= amount, "adapter TVL should cover the withdraw amount";
    require getCrosschainVault(getParentChainSelector()) != 0, "parent vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require currentContract.i_parentChainSelector != 0 && currentContract.i_parentChainSelector != currentContract.i_thisChainSelector,
        "destination selector should be valid";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";


    executeEpochWithdraw@withrevert(e, epochNonce, amount);

    assert lastReverted;
}

/// @notice Epoch withdraw reverts when any recovery operation is already pending
/// @dev Verifies that a pending recovery cannot be overwritten
rule executeEpochWithdraw_RevertWhen_RecoveryAlreadyPending() {
    env e;
    uint256 epochNonce;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require amount != 0, "amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() >= amount, "adapter TVL should cover the withdraw amount";
    require getCrosschainVault(getParentChainSelector()) != 0, "parent vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require currentContract.i_parentChainSelector != 0 && currentContract.i_parentChainSelector != currentContract.i_thisChainSelector,
        "destination selector should be valid";

    /// @dev revert condition being verified
    require getRecoveryMode() != Types.RecoveryMode.NONE, "recovery should be pending";


    executeEpochWithdraw@withrevert(e, epochNonce, amount);

    assert lastReverted;
}

/// @notice Epoch withdraw reverts when the requested amount is zero
/// @dev Verifies that zero input is rejected before adapter interaction
rule executeEpochWithdraw_RevertWhen_AmountIsZero() {
    env e;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require currentContract.i_parentChainSelector != 0 && currentContract.i_parentChainSelector != currentContract.i_thisChainSelector,
        "destination selector should be valid";

    /// @dev revert condition being verified
    uint256 amount = 0;


    executeEpochWithdraw@withrevert(e, epochNonce, amount);

    assert lastReverted;
}

/// @notice Epoch withdraw reverts when no active protocol adapter is configured
/// @dev Verifies that a missing strategy leaves all vault state unchanged
rule executeEpochWithdraw_RevertWhen_NoActiveAdapter() {
    env e;
    uint256 epochNonce;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require amount != 0, "amount should not be zero";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require currentContract.i_parentChainSelector != 0 && currentContract.i_parentChainSelector != currentContract.i_thisChainSelector,
        "destination selector should be valid";

    /// @dev revert condition being verified
    require getActiveProtocolAdapter() == 0, "active adapter should be zero";


    executeEpochWithdraw@withrevert(e, epochNonce, amount);

    assert lastReverted;
}

/// @notice Epoch withdraw reverts when a successful adapter call returns zero asset
/// @dev Verifies atomic rollback and that no success, failure, recovery, or bridge event is emitted
rule executeEpochWithdraw_RevertWhen_AmountOutIsZero() {
    env e;
    uint256 epochNonce;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require amount != 0, "amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require currentContract.i_parentChainSelector != 0 && currentContract.i_parentChainSelector != currentContract.i_thisChainSelector,
        "destination selector should be valid";

    /// @dev revert condition being verified
    require adapter.getTVL() == 0, "adapter withdraw should return zero";

    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);

    /// @dev set ghost starting values
    require ghost_WithdrawFromStrategySuccess_EventCount == 0;
    require ghost_WithdrawFromStrategyFailure_EventCount == 0;
    require ghost_EpochWithdrawRecoveryStored_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;

    executeEpochWithdraw@withrevert(e, epochNonce, amount);

    assert lastReverted;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == 0;
    assert ghost_WithdrawFromStrategySuccess_EventCount == 0;
    assert ghost_WithdrawFromStrategyFailure_EventCount == 0;
    assert ghost_EpochWithdrawRecoveryStored_EventCount == 0;
    assert ghost_CCIPBridged_EventCount == 0;
}

/// @notice Epoch withdraw reverts when no parent vault is registered for the parent chain
/// @dev Verifies atomic rollback of the completed adapter withdrawal and all emitted events
rule executeEpochWithdraw_RevertWhen_ParentVaultNotRegistered() {
    env e;
    uint256 epochNonce;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require amount != 0, "amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() > 0, "adapter withdraw should return a nonzero amount";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";
    require currentContract.i_parentChainSelector != 0
        && currentContract.i_parentChainSelector != currentContract.i_thisChainSelector,
        "destination selector should be valid";

    /// @dev revert condition being verified
    require getCrosschainVault(getParentChainSelector()) == 0, "parent vault should not be registered";

    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev set ghost starting values
    require ghost_WithdrawFromStrategySuccess_EventCount == 0;
    require ghost_WithdrawFromStrategyFailure_EventCount == 0;
    require ghost_EpochWithdrawRecoveryStored_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;
    require ghost_CcipSendRecoveryStored_EventCount == 0;

    executeEpochWithdraw@withrevert(e, epochNonce, amount);

    assert lastReverted;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_WithdrawFromStrategySuccess_EventCount == 0;
    assert ghost_WithdrawFromStrategyFailure_EventCount == 0;
    assert ghost_EpochWithdrawRecoveryStored_EventCount == 0;
    assert ghost_CCIPBridged_EventCount == 0;
    assert ghost_CcipSendRecoveryStored_EventCount == 0;
}

/// @notice A failed epoch withdraw stores recovery for the requested amount
/// @dev Verifies unchanged balances and TVL, exact recovery state, failure events
rule executeEpochWithdraw_When_WithdrawFails_StoresRecovery() {
    env e;
    uint256 epochNonce;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require amount != 0, "amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require currentContract.i_parentChainSelector != 0 && currentContract.i_parentChainSelector != currentContract.i_thisChainSelector,
        "destination selector should be valid";

    /// @dev failure condition being verified
    require adapter.withdrawReverts(), "adapter withdraw should revert";

    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev set ghost starting values
    require ghost_WithdrawFromStrategySuccess_EventCount == 0;
    require ghost_WithdrawFromStrategyFailure_EventCount == 0;
    require ghost_EpochWithdrawRecoveryStored_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;

    executeEpochWithdraw@withrevert(e, epochNonce, amount);

    assert !lastReverted;
    Types.EpochRecovery recovery = getEpochWithdrawRecovery();
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert getRecoveryMode() == Types.RecoveryMode.EPOCH_WITHDRAW;
    assert recovery.epochNonce == epochNonce;
    assert recovery.amount == amount;
    assert recovery.createdAt == e.block.timestamp;
    assert ghost_WithdrawFromStrategySuccess_EventCount == 0;
    assert ghost_WithdrawFromStrategyFailure_EventCount == 1;
    assert ghost_WithdrawFromStrategyFailure_Param_epochNonce == epochNonce;
    assert ghost_WithdrawFromStrategyFailure_Param_amount == amount;
    assert ghost_EpochWithdrawRecoveryStored_EventCount == 1;
    assert ghost_EpochWithdrawRecoveryStored_Param_epochNonce == epochNonce;
    assert ghost_EpochWithdrawRecoveryStored_Param_amount == amount;
    assert ghost_CCIPBridged_EventCount == 0;
}

/// @notice A successful epoch withdraw bridges the actual withdrawn asset to the parent chain
/// @dev Verifies exact balances, adapter TVL, events, and absence of recovery state
rule executeEpochWithdraw_Success() {
    env e;
    uint256 epochNonce;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require amount != 0, "amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() > 0, "adapter withdraw should return a nonzero amount";
    require getCrosschainVault(getParentChainSelector()) != 0, "parent vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require currentContract.i_parentChainSelector != 0 && currentContract.i_parentChainSelector != currentContract.i_thisChainSelector,
        "destination selector should be valid";

    uint256 fee = ccipRouter.getFee();
    address router = getRouter();
    uint256 vaultLinkBalanceBefore = link.balanceOf(currentContract);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);
    uint256 adapterTVLBefore = adapter.getTVL();
    uint256 amountOut = amount > adapterTVLBefore ? adapterTVLBefore : amount;

    /// @dev mock token arithmetic conditions
    require amountOut <= adapterAssetBalanceBefore, "adapter asset balance should cover the withdrawn amount";
    require vaultAssetBalanceBefore <= max_uint256 - amountOut, "vault asset balance should not overflow";
    require fee <= vaultLinkBalanceBefore, "vault LINK balance should cover the CCIP fee";
    require routerLinkBalanceBefore <= max_uint256 - fee, "router LINK balance should not overflow";
    require routerAssetBalanceBefore <= max_uint256 - amountOut, "router asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_WithdrawFromStrategySuccess_EventCount == 0;
    require ghost_WithdrawFromStrategyFailure_EventCount == 0;
    require ghost_EpochWithdrawRecoveryStored_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;

    executeEpochWithdraw@withrevert(e, epochNonce, amount);

    assert !lastReverted;
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore - fee;
    assert link.balanceOf(router) == routerLinkBalanceBefore + fee;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore - amountOut;
    assert asset.balanceOf(router) == routerAssetBalanceBefore + amountOut;
    assert adapter.getTVL() == adapterTVLBefore - amountOut;
    assert getRecoveryMode() == Types.RecoveryMode.NONE;
    assert ghost_WithdrawFromStrategySuccess_EventCount == 1;
    assert ghost_WithdrawFromStrategySuccess_Param_epochNonce == epochNonce;
    assert ghost_WithdrawFromStrategySuccess_Param_amount == amountOut;
    assert ghost_WithdrawFromStrategyFailure_EventCount == 0;
    assert ghost_EpochWithdrawRecoveryStored_EventCount == 0;
    assert ghost_CCIPBridged_EventCount == 1;
    assert ghost_CCIPBridged_Param_amount == amountOut;
    assert ghost_CCIPBridged_Param_ccipTxType == Types.CcipTx.EPOCH_NET_WITHDRAW;
}

/// @notice Epoch withdraw stores CCIP recovery when the router fee lookup fails after withdrawal
/// @dev Verifies that the withdrawal remains committed and the withdrawn asset stays in the vault
rule executeEpochWithdraw_When_RouterGetFeeReverts_StoresCcipSendRecovery() {
    env e;
    uint256 epochNonce;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require amount != 0, "amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() > 0, "adapter withdraw should return a nonzero amount";
    require getCrosschainVault(getParentChainSelector()) != 0, "parent vault should be registered";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";
    require currentContract.i_parentChainSelector != 0 && currentContract.i_parentChainSelector != currentContract.i_thisChainSelector,
        "destination selector should be valid";

    /// @dev failure condition being verified
    require ccipRouter.getFeeReverts(), "router fee lookup should revert";

    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();
    uint256 vaultLinkBalanceBefore = link.balanceOf(currentContract);
    address router = getRouter();
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);
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

    executeEpochWithdraw@withrevert(e, epochNonce, amount);

    assert !lastReverted;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore + amountOut;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore - amountOut;
    assert asset.balanceOf(router) == routerAssetBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore - amountOut;
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore;
    assert link.balanceOf(router) == routerLinkBalanceBefore;
    assert getRecoveryMode() == Types.RecoveryMode.CCIP_SEND;
    assert getCcipSendRecoveryTxType() == Types.CcipTx.EPOCH_NET_WITHDRAW;
    assert getCcipSendRecoveryAmount() == amountOut;
    assert getCcipSendRecoveryDestinationChainSelector() == getParentChainSelector();
    assert getCcipSendRecoveryCreatedAt() == e.block.timestamp;
    assert ghost_WithdrawFromStrategySuccess_EventCount == 1;
    assert ghost_WithdrawFromStrategySuccess_Param_epochNonce == epochNonce;
    assert ghost_WithdrawFromStrategySuccess_Param_amount == amountOut;
    assert ghost_WithdrawFromStrategyFailure_EventCount == 0;
    assert ghost_EpochWithdrawRecoveryStored_EventCount == 0;
    assert ghost_CCIPBridged_EventCount == 0;
    assert ghost_CcipSendRecoveryStored_EventCount == 1;
    assert ghost_CcipSendRecoveryStored_Param_ccipTxType == Types.CcipTx.EPOCH_NET_WITHDRAW;
    assert ghost_CcipSendRecoveryStored_Param_destinationChainSelector == getParentChainSelector();
    assert ghost_CcipSendRecoveryStored_Param_amount == amountOut;
}

/// ─────────────────── RECOVER FAILED REBALANCE WITHDRAW ──────

/// @notice Rebalance withdraw recovery reverts when the call is reentrant
/// @dev Verifies that recovery state, balances, TVL, and events remain unchanged
rule recoverFailedRebalanceWithdraw_RevertWhen_ReentrantCall() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_WITHDRAW, "rebalance withdraw recovery should be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() > 0, "adapter withdraw should return a nonzero amount";
    Types.RebalanceWithdrawRecovery recovery = getRebalanceWithdrawRecovery();
    require (
        recovery.strategy.chainSelector == getThisChainSelector()
            && adapterRegistry.getAdapter(e, recovery.strategy.protocolId) == adapter
            && adapter.getVault() == currentContract
            && !adapter.depositReverts()
            && adapter != currentContract
    ) || (
        recovery.strategy.chainSelector != 0
            && recovery.strategy.chainSelector != getThisChainSelector()
            && getCrosschainVault(recovery.strategy.chainSelector) != 0
            && !ccipRouter.getFeeReverts()
            && !ccipRouter.ccipSendReverts()
    ), "stored recovery strategy should be executable";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";

    storage before = lastStorage;
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token arithmetic conditions
    require adapterTVLBefore <= adapterAssetBalanceBefore, "adapter asset balance should cover the withdrawal";
    require vaultAssetBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_RebalanceWithdrawRecoveryCleared_EventCount == 0;
    require ghost_RebalanceWithdrawSuccess_EventCount == 0;

    recoverFailedRebalanceWithdraw@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_RebalanceWithdrawRecoveryCleared_EventCount == 0;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 0;
}

/// @notice Rebalance withdraw recovery reverts when no rebalance withdraw recovery is pending
/// @dev Verifies that balances, TVL, and events remain unchanged
rule recoverFailedRebalanceWithdraw_RevertWhen_NoPendingRecovery() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() > 0, "adapter withdraw should return a nonzero amount";
    Types.RebalanceWithdrawRecovery recovery = getRebalanceWithdrawRecovery();
    require (
        recovery.strategy.chainSelector == getThisChainSelector()
            && adapterRegistry.getAdapter(e, recovery.strategy.protocolId) == adapter
            && adapter.getVault() == currentContract
            && !adapter.depositReverts()
            && adapter != currentContract
    ) || (
        recovery.strategy.chainSelector != 0
            && recovery.strategy.chainSelector != getThisChainSelector()
            && getCrosschainVault(recovery.strategy.chainSelector) != 0
            && !ccipRouter.getFeeReverts()
            && !ccipRouter.ccipSendReverts()
    ), "stored recovery strategy should be executable";

    /// @dev revert condition being verified
    require getRecoveryMode() != Types.RecoveryMode.REBALANCE_WITHDRAW,
        "rebalance withdraw recovery should not be pending";

    storage before = lastStorage;
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token arithmetic conditions
    require adapterTVLBefore <= adapterAssetBalanceBefore, "adapter asset balance should cover the withdrawal";
    require vaultAssetBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_RebalanceWithdrawRecoveryCleared_EventCount == 0;
    require ghost_RebalanceWithdrawSuccess_EventCount == 0;

    recoverFailedRebalanceWithdraw@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_RebalanceWithdrawRecoveryCleared_EventCount == 0;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 0;
}

/// @notice Rebalance withdraw recovery reverts when no active adapter is set
/// @dev Verifies that recovery state, balances, TVL, and events remain unchanged
rule recoverFailedRebalanceWithdraw_RevertWhen_NoActiveAdapter() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_WITHDRAW, "rebalance withdraw recovery should be pending";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() > 0, "adapter withdraw should return a nonzero amount";
    Types.RebalanceWithdrawRecovery recovery = getRebalanceWithdrawRecovery();
    require (
        recovery.strategy.chainSelector == getThisChainSelector()
            && adapterRegistry.getAdapter(e, recovery.strategy.protocolId) == adapter
            && adapter.getVault() == currentContract
            && !adapter.depositReverts()
            && adapter != currentContract
    ) || (
        recovery.strategy.chainSelector != 0
            && recovery.strategy.chainSelector != getThisChainSelector()
            && getCrosschainVault(recovery.strategy.chainSelector) != 0
            && !ccipRouter.getFeeReverts()
            && !ccipRouter.ccipSendReverts()
    ), "stored recovery strategy should be executable";

    /// @dev revert condition being verified
    require getActiveProtocolAdapter() == 0, "active adapter should not be set";

    storage before = lastStorage;
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token arithmetic conditions
    require adapterTVLBefore <= adapterAssetBalanceBefore, "adapter asset balance should cover the withdrawal";
    require vaultAssetBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_RebalanceWithdrawRecoveryCleared_EventCount == 0;
    require ghost_RebalanceWithdrawSuccess_EventCount == 0;

    recoverFailedRebalanceWithdraw@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_RebalanceWithdrawRecoveryCleared_EventCount == 0;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 0;
}

/// @notice Rebalance withdraw recovery reverts when the adapter withdraw fails
/// @dev Verifies atomic rollback of recovery state, balances, TVL, and events
rule recoverFailedRebalanceWithdraw_RevertWhen_WithdrawFails() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_WITHDRAW, "rebalance withdraw recovery should be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    Types.RebalanceWithdrawRecovery recovery = getRebalanceWithdrawRecovery();
    require (
        recovery.strategy.chainSelector == getThisChainSelector()
            && adapterRegistry.getAdapter(e, recovery.strategy.protocolId) == adapter
            && adapter.getVault() == currentContract
            && !adapter.depositReverts()
            && adapter != currentContract
    ) || (
        recovery.strategy.chainSelector != 0
            && recovery.strategy.chainSelector != getThisChainSelector()
            && getCrosschainVault(recovery.strategy.chainSelector) != 0
            && !ccipRouter.getFeeReverts()
            && !ccipRouter.ccipSendReverts()
    ), "stored recovery strategy should be executable";

    /// @dev revert condition being verified
    require adapter.withdrawReverts(), "adapter withdraw should revert";

    storage before = lastStorage;
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token arithmetic conditions
    require adapterTVLBefore <= adapterAssetBalanceBefore, "adapter asset balance should cover the withdrawal";
    require vaultAssetBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_RebalanceWithdrawRecoveryCleared_EventCount == 0;
    require ghost_RebalanceWithdrawSuccess_EventCount == 0;

    recoverFailedRebalanceWithdraw@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_RebalanceWithdrawRecoveryCleared_EventCount == 0;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 0;
}

/// @notice Rebalance withdraw recovery reverts when the retry withdraw returns zero
/// @dev Verifies that zero recovery output leaves recovery state, balances, TVL, and events unchanged
rule recoverFailedRebalanceWithdraw_RevertWhen_AmountRebalancedIsZero() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_WITHDRAW, "rebalance withdraw recovery should be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    Types.RebalanceWithdrawRecovery recovery = getRebalanceWithdrawRecovery();
    require (
        recovery.strategy.chainSelector == getThisChainSelector()
            && adapterRegistry.getAdapter(e, recovery.strategy.protocolId) == adapter
            && adapter.getVault() == currentContract
            && !adapter.depositReverts()
            && adapter != currentContract
    ) || (
        recovery.strategy.chainSelector != 0
            && recovery.strategy.chainSelector != getThisChainSelector()
            && getCrosschainVault(recovery.strategy.chainSelector) != 0
            && !ccipRouter.getFeeReverts()
            && !ccipRouter.ccipSendReverts()
    ), "stored recovery strategy should be executable";

    /// @dev revert condition being verified
    require adapter.getTVL() == 0, "adapter withdraw should return zero";

    storage before = lastStorage;
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);

    /// @dev set ghost starting values
    require ghost_RebalanceWithdrawRecoveryCleared_EventCount == 0;
    require ghost_RebalanceWithdrawSuccess_EventCount == 0;

    recoverFailedRebalanceWithdraw@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore;
    assert adapter.getTVL() == 0;
    assert ghost_RebalanceWithdrawRecoveryCleared_EventCount == 0;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 0;
}

/// @notice Local rebalance withdraw recovery reverts when the target protocol adapter is not registered
/// @dev Verifies atomic rollback of the completed source withdrawal and recovery clear
rule recoverFailedRebalanceWithdraw_Local_RevertWhen_TargetAdapterNotRegistered() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_WITHDRAW, "rebalance withdraw recovery should be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() > 0, "adapter withdraw should return a nonzero amount";
    Types.RebalanceWithdrawRecovery recovery = getRebalanceWithdrawRecovery();
    require recovery.strategy.chainSelector == getThisChainSelector(), "target strategy should be on this chain";

    /// @dev revert condition being verified
    require adapterRegistry.getAdapter(e, recovery.strategy.protocolId) == 0, "target adapter should not be registered";

    storage before = lastStorage;
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token arithmetic conditions
    require adapterTVLBefore <= adapterAssetBalanceBefore, "adapter asset balance should cover the withdrawal";
    require vaultAssetBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_RebalanceWithdrawRecoveryCleared_EventCount == 0;
    require ghost_RebalanceWithdrawSuccess_EventCount == 0;

    recoverFailedRebalanceWithdraw@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_RebalanceWithdrawRecoveryCleared_EventCount == 0;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 0;
}

/// @notice Local rebalance withdraw recovery reverts when the target adapter is bound to another vault
/// @dev Verifies atomic rollback of the completed source withdrawal and recovery clear
rule recoverFailedRebalanceWithdraw_Local_RevertWhen_TargetAdapterVaultIsInvalid() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_WITHDRAW, "rebalance withdraw recovery should be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() > 0, "adapter withdraw should return a nonzero amount";
    Types.RebalanceWithdrawRecovery recovery = getRebalanceWithdrawRecovery();
    require recovery.strategy.chainSelector == getThisChainSelector(), "target strategy should be on this chain";
    require invalidAdapter.getVault() != currentContract, "target adapter should not be bound to this vault";

    /// @dev revert condition being verified
    require adapterRegistry.getAdapter(e, recovery.strategy.protocolId) == invalidAdapter,
        "invalid target adapter should be registered";

    storage before = lastStorage;
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token arithmetic conditions
    require adapterTVLBefore <= adapterAssetBalanceBefore, "adapter asset balance should cover the withdrawal";
    require vaultAssetBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_RebalanceWithdrawRecoveryCleared_EventCount == 0;
    require ghost_RebalanceWithdrawSuccess_EventCount == 0;

    recoverFailedRebalanceWithdraw@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_RebalanceWithdrawRecoveryCleared_EventCount == 0;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 0;
}

/// @notice Local rebalance withdraw recovery withdraws and redeposits into the recovered target adapter
/// @dev Verifies exact balances, recovery deletion, active adapter update, and events
rule recoverFailedRebalanceWithdraw_Local_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_WITHDRAW, "rebalance withdraw recovery should be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require !adapter.depositReverts(), "target adapter deposit should not revert";
    Types.RebalanceWithdrawRecovery recovery = getRebalanceWithdrawRecovery();
    require recovery.strategy.chainSelector == getThisChainSelector(), "target strategy should be on this chain";
    require adapterRegistry.getAdapter(e, recovery.strategy.protocolId) == adapter, "target adapter should be registered";
    require adapter.getVault() == currentContract, "target adapter should be bound to the vault";
    require adapter != currentContract, "adapter should not be the vault";

    uint256 amountRebalanced = adapter.getTVL();
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);

    /// @dev mock token arithmetic conditions
    require amountRebalanced != 0, "adapter withdraw should return a nonzero amount";
    require amountRebalanced <= adapterAssetBalanceBefore, "adapter asset balance should cover the withdrawal";
    require vaultAssetBalanceBefore <= max_uint256 - amountRebalanced, "vault asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_RebalanceWithdrawRecoveryCleared_EventCount == 0;
    require ghost_RebalanceWithdrawSuccess_EventCount == 0;
    require ghost_ActiveProtocolAdapterSet_EventCount == 0;
    require ghost_RebalanceDepositSuccess_EventCount == 0;
    require ghost_RebalanceDepositFailure_EventCount == 0;
    require ghost_RebalanceDepositRecoveryStored_EventCount == 0;

    recoverFailedRebalanceWithdraw@withrevert(e);

    assert !lastReverted;
    assert getActiveProtocolAdapter() == adapter;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore;
    assert adapter.getTVL() == amountRebalanced;
    assert getRecoveryMode() == Types.RecoveryMode.NONE;
    assert getRebalanceWithdrawRecovery().rebalanceNonce == 0;
    assert getRebalanceWithdrawRecovery().strategy.protocolId == to_bytes32(0);
    assert getRebalanceWithdrawRecovery().strategy.chainSelector == 0;
    assert getRebalanceWithdrawRecovery().createdAt == 0;
    assert ghost_RebalanceWithdrawRecoveryCleared_EventCount == 1;
    assert ghost_RebalanceWithdrawRecoveryCleared_Param_rebalanceNonce == recovery.rebalanceNonce;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 1;
    assert ghost_RebalanceWithdrawSuccess_Param_nonce == recovery.rebalanceNonce;
    assert ghost_RebalanceWithdrawSuccess_Param_amount == amountRebalanced;
    assert ghost_ActiveProtocolAdapterSet_EventCount == 1;
    assert ghost_ActiveProtocolAdapterSet_Param_protocolId == recovery.strategy.protocolId;
    assert ghost_ActiveProtocolAdapterSet_Param_adapter == adapter;
    assert ghost_RebalanceDepositSuccess_EventCount == 1;
    assert ghost_RebalanceDepositSuccess_Param_nonce == recovery.rebalanceNonce;
    assert ghost_RebalanceDepositSuccess_Param_amount == amountRebalanced;
    assert ghost_RebalanceDepositFailure_EventCount == 0;
    assert ghost_RebalanceDepositRecoveryStored_EventCount == 0;
}

// @review vacuous
/// @notice Local rebalance withdraw recovery can move funds to a distinct recovered target adapter
/// @dev Verifies source and target adapter balances/TVL independently
rule recoverFailedRebalanceWithdraw_Local_DistinctTargetAdapter_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_WITHDRAW, "rebalance withdraw recovery should be pending";
    require getActiveProtocolAdapter() == adapter, "source adapter should be active";
    require targetAdapter != adapter, "target adapter should be distinct from source adapter";
    require targetAdapter != currentContract, "target adapter should not be the vault";
    require !adapter.withdrawReverts(), "source adapter withdraw should not revert";
    require !targetAdapter.depositReverts(), "target adapter deposit should not revert";
    Types.RebalanceWithdrawRecovery recovery = getRebalanceWithdrawRecovery();
    require recovery.strategy.chainSelector == getThisChainSelector(), "target strategy should be on this chain";
    require adapterRegistry.getAdapter(e, recovery.strategy.protocolId) == targetAdapter,
        "target adapter should be registered";
    require targetAdapter.getVault() == currentContract, "target adapter should be bound to the vault";

    uint256 amountRebalanced = adapter.getTVL();
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 sourceAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 targetAssetBalanceBefore = asset.balanceOf(targetAdapter);
    uint256 targetTVLBefore = targetAdapter.getTVL();

    /// @dev mock token arithmetic conditions
    require amountRebalanced != 0, "source withdraw should return a nonzero amount";
    require amountRebalanced <= sourceAssetBalanceBefore, "source adapter balance should cover the withdrawal";
    require vaultAssetBalanceBefore <= max_uint256 - amountRebalanced, "vault asset balance should not overflow";
    require targetAssetBalanceBefore <= max_uint256 - amountRebalanced, "target balance should not overflow";
    require targetTVLBefore <= max_uint256 - amountRebalanced, "target TVL should not overflow";

    /// @dev set ghost starting values
    require ghost_RebalanceWithdrawRecoveryCleared_EventCount == 0;
    require ghost_RebalanceWithdrawSuccess_EventCount == 0;
    require ghost_ActiveProtocolAdapterSet_EventCount == 0;
    require ghost_RebalanceDepositSuccess_EventCount == 0;
    require ghost_RebalanceDepositFailure_EventCount == 0;
    require ghost_RebalanceDepositRecoveryStored_EventCount == 0;

    recoverFailedRebalanceWithdraw@withrevert(e);

    assert !lastReverted;
    assert getActiveProtocolAdapter() == targetAdapter;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(adapter) == sourceAssetBalanceBefore - amountRebalanced;
    assert asset.balanceOf(targetAdapter) == targetAssetBalanceBefore + amountRebalanced;
    assert adapter.getTVL() == 0;
    assert targetAdapter.getTVL() == targetTVLBefore + amountRebalanced;
    assert getRecoveryMode() == Types.RecoveryMode.NONE;
    assert getRebalanceWithdrawRecovery().rebalanceNonce == 0;
    assert getRebalanceWithdrawRecovery().strategy.protocolId == to_bytes32(0);
    assert getRebalanceWithdrawRecovery().strategy.chainSelector == 0;
    assert getRebalanceWithdrawRecovery().createdAt == 0;
    assert ghost_RebalanceWithdrawRecoveryCleared_EventCount == 1;
    assert ghost_RebalanceWithdrawRecoveryCleared_Param_rebalanceNonce == recovery.rebalanceNonce;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 1;
    assert ghost_RebalanceWithdrawSuccess_Param_nonce == recovery.rebalanceNonce;
    assert ghost_RebalanceWithdrawSuccess_Param_amount == amountRebalanced;
    assert ghost_ActiveProtocolAdapterSet_EventCount == 1;
    assert ghost_ActiveProtocolAdapterSet_Param_protocolId == recovery.strategy.protocolId;
    assert ghost_ActiveProtocolAdapterSet_Param_adapter == targetAdapter;
    assert ghost_RebalanceDepositSuccess_EventCount == 1;
    assert ghost_RebalanceDepositSuccess_Param_nonce == recovery.rebalanceNonce;
    assert ghost_RebalanceDepositSuccess_Param_amount == amountRebalanced;
    assert ghost_RebalanceDepositFailure_EventCount == 0;
    assert ghost_RebalanceDepositRecoveryStored_EventCount == 0;
}

/// @notice Local rebalance withdraw recovery stores rebalance deposit recovery when target deposit fails
/// @dev Verifies the old withdraw recovery is cleared before the new deposit recovery is stored
rule recoverFailedRebalanceWithdraw_Local_When_DepositFails_StoresRecovery() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_WITHDRAW, "rebalance withdraw recovery should be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    Types.RebalanceWithdrawRecovery recovery = getRebalanceWithdrawRecovery();
    require recovery.strategy.chainSelector == getThisChainSelector(), "target strategy should be on this chain";
    require adapterRegistry.getAdapter(e, recovery.strategy.protocolId) == adapter, "target adapter should be registered";
    require adapter.getVault() == currentContract, "target adapter should be bound to the vault";
    require adapter != currentContract, "adapter should not be the vault";

    /// @dev failure condition being verified
    require adapter.depositReverts(), "target adapter deposit should revert";

    uint256 amountRebalanced = adapter.getTVL();
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);

    /// @dev mock token arithmetic conditions
    require amountRebalanced != 0, "adapter withdraw should return a nonzero amount";
    require amountRebalanced <= adapterAssetBalanceBefore, "adapter asset balance should cover the withdrawal";
    require vaultAssetBalanceBefore <= max_uint256 - amountRebalanced, "vault asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_RebalanceWithdrawRecoveryCleared_EventCount == 0;
    require ghost_RebalanceWithdrawSuccess_EventCount == 0;
    require ghost_ActiveProtocolAdapterSet_EventCount == 0;
    require ghost_RebalanceDepositSuccess_EventCount == 0;
    require ghost_RebalanceDepositFailure_EventCount == 0;
    require ghost_RebalanceDepositRecoveryStored_EventCount == 0;

    recoverFailedRebalanceWithdraw@withrevert(e);

    assert !lastReverted;
    assert getActiveProtocolAdapter() == adapter;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore + amountRebalanced;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore - amountRebalanced;
    assert adapter.getTVL() == 0;
    assert getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT;
    assert getRebalanceWithdrawRecovery().rebalanceNonce == 0;
    assert getRebalanceWithdrawRecovery().strategy.protocolId == to_bytes32(0);
    assert getRebalanceWithdrawRecovery().strategy.chainSelector == 0;
    assert getRebalanceWithdrawRecovery().createdAt == 0;
    Types.RebalanceDepositRecovery depositRecovery = getRebalanceDepositRecovery();
    assert depositRecovery.rebalanceNonce == recovery.rebalanceNonce;
    assert depositRecovery.amount == amountRebalanced;
    assert depositRecovery.createdAt == e.block.timestamp;
    assert ghost_RebalanceWithdrawRecoveryCleared_EventCount == 1;
    assert ghost_RebalanceWithdrawRecoveryCleared_Param_rebalanceNonce == recovery.rebalanceNonce;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 1;
    assert ghost_RebalanceWithdrawSuccess_Param_nonce == recovery.rebalanceNonce;
    assert ghost_RebalanceWithdrawSuccess_Param_amount == amountRebalanced;
    assert ghost_ActiveProtocolAdapterSet_EventCount == 1;
    assert ghost_ActiveProtocolAdapterSet_Param_protocolId == recovery.strategy.protocolId;
    assert ghost_ActiveProtocolAdapterSet_Param_adapter == adapter;
    assert ghost_RebalanceDepositSuccess_EventCount == 0;
    assert ghost_RebalanceDepositFailure_EventCount == 1;
    assert ghost_RebalanceDepositFailure_Param_nonce == recovery.rebalanceNonce;
    assert ghost_RebalanceDepositFailure_Param_amount == amountRebalanced;
    assert ghost_RebalanceDepositRecoveryStored_EventCount == 1;
    assert ghost_RebalanceDepositRecoveryStored_Param_nonce == recovery.rebalanceNonce;
    assert ghost_RebalanceDepositRecoveryStored_Param_amount == amountRebalanced;
}

/// @notice Remote rebalance withdraw recovery reverts when the target chain selector is zero
/// @dev Verifies atomic rollback because CCIP validation runs before the caught router send
rule recoverFailedRebalanceWithdraw_Remote_RevertWhen_TargetChainSelectorIsZero() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_WITHDRAW, "rebalance withdraw recovery should be pending";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require getThisChainSelector() != 0, "this chain selector should not be zero";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    Types.RebalanceWithdrawRecovery recovery = getRebalanceWithdrawRecovery();

    /// @dev failure condition being verified
    require recovery.strategy.chainSelector == 0, "target chain selector should be zero";

    storage before = lastStorage;
    uint256 adapterTVLBefore = adapter.getTVL();
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    address router = getRouter();
    uint256 routerBalanceBefore = asset.balanceOf(router);

    /// @dev mock token arithmetic conditions
    require adapterTVLBefore != 0, "adapter withdraw should return a nonzero amount";
    require adapterTVLBefore <= adapterBalanceBefore, "adapter asset balance should cover the withdrawal";
    require vaultBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_RebalanceWithdrawRecoveryCleared_EventCount == 0;
    require ghost_RebalanceWithdrawSuccess_EventCount == 0;
    require ghost_ActiveProtocolAdapterCleared_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;
    require ghost_CcipSendRecoveryStored_EventCount == 0;

    recoverFailedRebalanceWithdraw@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert asset.balanceOf(router) == routerBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_RebalanceWithdrawRecoveryCleared_EventCount == 0;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 0;
    assert ghost_ActiveProtocolAdapterCleared_EventCount == 0;
    assert ghost_CCIPBridged_EventCount == 0;
    assert ghost_CcipSendRecoveryStored_EventCount == 0;
}

/// @notice Remote rebalance withdraw recovery reverts when no target vault is registered
/// @dev Verifies atomic rollback because CCIP validation runs before the caught router send
rule recoverFailedRebalanceWithdraw_Remote_RevertWhen_TargetVaultNotRegistered() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_WITHDRAW, "rebalance withdraw recovery should be pending";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    Types.RebalanceWithdrawRecovery recovery = getRebalanceWithdrawRecovery();
    require recovery.strategy.chainSelector != 0, "target chain selector should not be zero";
    require recovery.strategy.chainSelector != getThisChainSelector(), "target strategy should be remote";

    /// @dev failure condition being verified
    require getCrosschainVault(recovery.strategy.chainSelector) == 0, "target vault should not be registered";

    storage before = lastStorage;
    uint256 adapterTVLBefore = adapter.getTVL();
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    address router = getRouter();
    uint256 routerBalanceBefore = asset.balanceOf(router);

    /// @dev mock token arithmetic conditions
    require adapterTVLBefore != 0, "adapter withdraw should return a nonzero amount";
    require adapterTVLBefore <= adapterBalanceBefore, "adapter asset balance should cover the withdrawal";
    require vaultBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_RebalanceWithdrawRecoveryCleared_EventCount == 0;
    require ghost_RebalanceWithdrawSuccess_EventCount == 0;
    require ghost_ActiveProtocolAdapterCleared_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;
    require ghost_CcipSendRecoveryStored_EventCount == 0;

    recoverFailedRebalanceWithdraw@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert asset.balanceOf(router) == routerBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_RebalanceWithdrawRecoveryCleared_EventCount == 0;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 0;
    assert ghost_ActiveProtocolAdapterCleared_EventCount == 0;
    assert ghost_CCIPBridged_EventCount == 0;
    assert ghost_CcipSendRecoveryStored_EventCount == 0;
}

/// @notice Remote rebalance withdraw recovery bridges the recovered TVL to the target chain
/// @dev Verifies exact balances, recovery deletion, active adapter clearing, and events
rule recoverFailedRebalanceWithdraw_Remote_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_WITHDRAW, "rebalance withdraw recovery should be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    Types.RebalanceWithdrawRecovery recovery = getRebalanceWithdrawRecovery();
    require recovery.strategy.chainSelector != 0, "target chain selector should not be zero";
    require recovery.strategy.chainSelector != getThisChainSelector(), "target strategy should be remote";
    require getCrosschainVault(recovery.strategy.chainSelector) != 0, "target vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    uint256 amountRebalanced = adapter.getTVL();
    uint256 fee = ccipRouter.getFee();
    address router = getRouter();
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);
    uint256 vaultLinkBalanceBefore = link.balanceOf(currentContract);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);

    /// @dev mock token arithmetic conditions
    require amountRebalanced != 0, "adapter withdraw should return a nonzero amount";
    require amountRebalanced <= adapterAssetBalanceBefore, "adapter asset balance should cover the withdrawal";
    require vaultAssetBalanceBefore <= max_uint256 - amountRebalanced, "vault asset balance should not overflow";
    require routerAssetBalanceBefore <= max_uint256 - amountRebalanced, "router asset balance should not overflow";
    require fee <= vaultLinkBalanceBefore, "vault LINK balance should cover the CCIP fee";
    require routerLinkBalanceBefore <= max_uint256 - fee, "router LINK balance should not overflow";

    /// @dev set ghost starting values
    require ghost_RebalanceWithdrawRecoveryCleared_EventCount == 0;
    require ghost_RebalanceWithdrawSuccess_EventCount == 0;
    require ghost_ActiveProtocolAdapterCleared_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;
    require ghost_CcipSendRecoveryStored_EventCount == 0;

    recoverFailedRebalanceWithdraw@withrevert(e);

    assert !lastReverted;
    assert getActiveProtocolAdapter() == 0;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore - amountRebalanced;
    assert asset.balanceOf(router) == routerAssetBalanceBefore + amountRebalanced;
    assert adapter.getTVL() == 0;
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore - fee;
    assert link.balanceOf(router) == routerLinkBalanceBefore + fee;
    assert getRecoveryMode() == Types.RecoveryMode.NONE;
    assert getRebalanceWithdrawRecovery().rebalanceNonce == 0;
    assert getRebalanceWithdrawRecovery().strategy.protocolId == to_bytes32(0);
    assert getRebalanceWithdrawRecovery().strategy.chainSelector == 0;
    assert getRebalanceWithdrawRecovery().createdAt == 0;
    assert ghost_RebalanceWithdrawRecoveryCleared_EventCount == 1;
    assert ghost_RebalanceWithdrawRecoveryCleared_Param_rebalanceNonce == recovery.rebalanceNonce;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 1;
    assert ghost_RebalanceWithdrawSuccess_Param_nonce == recovery.rebalanceNonce;
    assert ghost_RebalanceWithdrawSuccess_Param_amount == amountRebalanced;
    assert ghost_ActiveProtocolAdapterCleared_EventCount == 1;
    assert ghost_ActiveProtocolAdapterCleared_Param_adapter == adapter;
    assert ghost_CCIPBridged_EventCount == 1;
    assert ghost_CCIPBridged_Param_amount == amountRebalanced;
    assert ghost_CCIPBridged_Param_ccipTxType == Types.CcipTx.REBALANCE;
    assert ghost_CcipSendRecoveryStored_EventCount == 0;
}

// @review vacuous
/// @notice Remote rebalance withdraw recovery stores CCIP recovery when the router fee lookup fails
/// @dev Verifies that withdrawal and active adapter clearing remain committed
rule recoverFailedRebalanceWithdraw_Remote_When_RouterGetFeeReverts_StoresCcipSendRecovery() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_WITHDRAW, "rebalance withdraw recovery should be pending";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    Types.RebalanceWithdrawRecovery recovery = getRebalanceWithdrawRecovery();
    require recovery.strategy.chainSelector != 0, "target chain selector should not be zero";
    require recovery.strategy.chainSelector != getThisChainSelector(), "target strategy should be remote";
    require getCrosschainVault(recovery.strategy.chainSelector) != 0, "target vault should be registered";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev failure condition being verified
    require ccipRouter.getFeeReverts(), "router fee lookup should revert";

    uint256 amountRebalanced = adapter.getTVL();
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    address router = getRouter();
    uint256 routerBalanceBefore = asset.balanceOf(router);

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

    recoverFailedRebalanceWithdraw@withrevert(e);

    assert !lastReverted;
    assert getActiveProtocolAdapter() == 0;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore + amountRebalanced;
    assert asset.balanceOf(adapter) == adapterBalanceBefore - amountRebalanced;
    assert asset.balanceOf(router) == routerBalanceBefore;
    assert adapter.getTVL() == 0;
    assert getRecoveryMode() == Types.RecoveryMode.CCIP_SEND;
    assert getRebalanceWithdrawRecovery().rebalanceNonce == 0;
    assert getRebalanceWithdrawRecovery().strategy.protocolId == to_bytes32(0);
    assert getRebalanceWithdrawRecovery().strategy.chainSelector == 0;
    assert getRebalanceWithdrawRecovery().createdAt == 0;
    assert getCcipSendRecoveryTxType() == Types.CcipTx.REBALANCE;
    assert getCcipSendRecoveryAmount() == amountRebalanced;
    assert getCcipSendRecoveryDestinationChainSelector() == recovery.strategy.chainSelector;
    uint256 storedRebalanceNonce;
    bytes32 storedProtocolId;
    (storedRebalanceNonce, storedProtocolId) = getCcipSendRecoveryRebalanceData();
    assert storedRebalanceNonce == recovery.rebalanceNonce;
    assert storedProtocolId == recovery.strategy.protocolId;
    assert getCcipSendRecoveryCreatedAt() == e.block.timestamp;
    assert ghost_RebalanceWithdrawRecoveryCleared_EventCount == 1;
    assert ghost_RebalanceWithdrawRecoveryCleared_Param_rebalanceNonce == recovery.rebalanceNonce;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 1;
    assert ghost_RebalanceWithdrawSuccess_Param_nonce == recovery.rebalanceNonce;
    assert ghost_RebalanceWithdrawSuccess_Param_amount == amountRebalanced;
    assert ghost_ActiveProtocolAdapterCleared_EventCount == 1;
    assert ghost_ActiveProtocolAdapterCleared_Param_adapter == adapter;
    assert ghost_CCIPBridged_EventCount == 0;
    assert ghost_CcipSendRecoveryStored_EventCount == 1;
    assert ghost_CcipSendRecoveryStored_Param_ccipTxType == Types.CcipTx.REBALANCE;
    assert ghost_CcipSendRecoveryStored_Param_destinationChainSelector == recovery.strategy.chainSelector;
    assert ghost_CcipSendRecoveryStored_Param_amount == amountRebalanced;
}

// @review vacuous
/// @notice Remote rebalance withdraw recovery stores CCIP recovery when the router send fails
/// @dev Verifies atomic send rollback while preserving withdrawal and active adapter clearing
rule recoverFailedRebalanceWithdraw_Remote_When_RouterCcipSendReverts_StoresCcipSendRecovery() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_WITHDRAW, "rebalance withdraw recovery should be pending";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    Types.RebalanceWithdrawRecovery recovery = getRebalanceWithdrawRecovery();
    require recovery.strategy.chainSelector != 0, "target chain selector should not be zero";
    require recovery.strategy.chainSelector != getThisChainSelector(), "target strategy should be remote";
    require getCrosschainVault(recovery.strategy.chainSelector) != 0, "target vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";

    /// @dev failure condition being verified
    require ccipRouter.ccipSendReverts(), "router send should revert";

    uint256 amountRebalanced = adapter.getTVL();
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    address router = getRouter();
    uint256 routerBalanceBefore = asset.balanceOf(router);

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

    recoverFailedRebalanceWithdraw@withrevert(e);

    assert !lastReverted;
    assert getActiveProtocolAdapter() == 0;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore + amountRebalanced;
    assert asset.balanceOf(adapter) == adapterBalanceBefore - amountRebalanced;
    assert asset.balanceOf(router) == routerBalanceBefore;
    assert adapter.getTVL() == 0;
    assert getRecoveryMode() == Types.RecoveryMode.CCIP_SEND;
    assert getRebalanceWithdrawRecovery().rebalanceNonce == 0;
    assert getRebalanceWithdrawRecovery().strategy.protocolId == to_bytes32(0);
    assert getRebalanceWithdrawRecovery().strategy.chainSelector == 0;
    assert getRebalanceWithdrawRecovery().createdAt == 0;
    assert getCcipSendRecoveryTxType() == Types.CcipTx.REBALANCE;
    assert getCcipSendRecoveryAmount() == amountRebalanced;
    assert getCcipSendRecoveryDestinationChainSelector() == recovery.strategy.chainSelector;
    uint256 storedRebalanceNonce;
    bytes32 storedProtocolId;
    (storedRebalanceNonce, storedProtocolId) = getCcipSendRecoveryRebalanceData();
    assert storedRebalanceNonce == recovery.rebalanceNonce;
    assert storedProtocolId == recovery.strategy.protocolId;
    assert getCcipSendRecoveryCreatedAt() == e.block.timestamp;
    assert ghost_RebalanceWithdrawRecoveryCleared_EventCount == 1;
    assert ghost_RebalanceWithdrawRecoveryCleared_Param_rebalanceNonce == recovery.rebalanceNonce;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 1;
    assert ghost_RebalanceWithdrawSuccess_Param_nonce == recovery.rebalanceNonce;
    assert ghost_RebalanceWithdrawSuccess_Param_amount == amountRebalanced;
    assert ghost_ActiveProtocolAdapterCleared_EventCount == 1;
    assert ghost_ActiveProtocolAdapterCleared_Param_adapter == adapter;
    assert ghost_CCIPBridged_EventCount == 0;
    assert ghost_CcipSendRecoveryStored_EventCount == 1;
    assert ghost_CcipSendRecoveryStored_Param_ccipTxType == Types.CcipTx.REBALANCE;
    assert ghost_CcipSendRecoveryStored_Param_destinationChainSelector == recovery.strategy.chainSelector;
    assert ghost_CcipSendRecoveryStored_Param_amount == amountRebalanced;
}

/// @notice Epoch withdraw stores CCIP recovery when the router send fails after withdrawal
/// @dev Verifies atomic send rollback while preserving the completed strategy withdrawal
rule executeEpochWithdraw_When_RouterCcipSendReverts_StoresCcipSendRecovery() {
    env e;
    uint256 epochNonce;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
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
    require ccipRouter.ccipSendReverts(), "router send should revert";

    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();
    uint256 vaultLinkBalanceBefore = link.balanceOf(currentContract);
    address router = getRouter();
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);
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

    executeEpochWithdraw@withrevert(e, epochNonce, amount);

    assert !lastReverted;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore + amountOut;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore - amountOut;
    assert asset.balanceOf(router) == routerAssetBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore - amountOut;
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore;
    assert link.balanceOf(router) == routerLinkBalanceBefore;
    assert getRecoveryMode() == Types.RecoveryMode.CCIP_SEND;
    assert getCcipSendRecoveryTxType() == Types.CcipTx.EPOCH_NET_WITHDRAW;
    assert getCcipSendRecoveryAmount() == amountOut;
    assert getCcipSendRecoveryDestinationChainSelector() == getParentChainSelector();
    assert getCcipSendRecoveryCreatedAt() == e.block.timestamp;
    assert ghost_WithdrawFromStrategySuccess_EventCount == 1;
    assert ghost_WithdrawFromStrategySuccess_Param_epochNonce == epochNonce;
    assert ghost_WithdrawFromStrategySuccess_Param_amount == amountOut;
    assert ghost_WithdrawFromStrategyFailure_EventCount == 0;
    assert ghost_EpochWithdrawRecoveryStored_EventCount == 0;
    assert ghost_CCIPBridged_EventCount == 0;
    assert ghost_CcipSendRecoveryStored_EventCount == 1;
    assert ghost_CcipSendRecoveryStored_Param_ccipTxType == Types.CcipTx.EPOCH_NET_WITHDRAW;
    assert ghost_CcipSendRecoveryStored_Param_destinationChainSelector == getParentChainSelector();
    assert ghost_CcipSendRecoveryStored_Param_amount == amountOut;
}

/// ─────────────────── EXECUTE REBALANCE ───────────────────────

/// @notice Rebalance execution reverts when the caller does not have the rebalance operator role
/// @dev Verifies that an unauthorized call leaves all vault state unchanged
rule executeRebalance_RevertWhen_CallerDoesNotHaveREBALANCE_OPERATOR_ROLE() {
    env e;
    uint256 rebalanceNonce;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() > 0, "adapter withdraw should return a nonzero amount";
    require newStrategy.chainSelector == getThisChainSelector(), "target strategy should be on this chain";
    require adapterRegistry.getAdapter(e, newStrategy.protocolId) == adapter, "target adapter should be registered";
    require adapter.getVault() == currentContract, "target adapter should be bound to the vault";
    require !adapter.depositReverts(), "target adapter deposit should not revert";

    /// @dev revert condition being verified
    require !hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);


    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert lastReverted;
}

/// @notice Rebalance execution reverts when called during an active non-reentrant execution
/// @dev Verifies that a reentrant call leaves all vault state unchanged
rule executeRebalance_RevertWhen_ReentrantCall() {
    env e;
    uint256 rebalanceNonce;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() > 0, "adapter withdraw should return a nonzero amount";
    require newStrategy.chainSelector == getThisChainSelector(), "target strategy should be on this chain";
    require adapterRegistry.getAdapter(e, newStrategy.protocolId) == adapter, "target adapter should be registered";
    require adapter.getVault() == currentContract, "target adapter should be bound to the vault";
    require !adapter.depositReverts(), "target adapter deposit should not revert";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";


    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert lastReverted;
}

/// @notice Rebalance execution reverts when any recovery operation is already pending
/// @dev Verifies that an existing recovery cannot be overwritten
rule executeRebalance_RevertWhen_RecoveryAlreadyPending() {
    env e;
    uint256 rebalanceNonce;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() > 0, "adapter withdraw should return a nonzero amount";
    require newStrategy.chainSelector == getThisChainSelector(), "target strategy should be on this chain";
    require adapterRegistry.getAdapter(e, newStrategy.protocolId) == adapter, "target adapter should be registered";
    require adapter.getVault() == currentContract, "target adapter should be bound to the vault";
    require !adapter.depositReverts(), "target adapter deposit should not revert";

    /// @dev revert condition being verified
    require getRecoveryMode() != Types.RecoveryMode.NONE, "recovery should be pending";


    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert lastReverted;
}

/// @notice Rebalance execution reverts when no active protocol adapter is configured
/// @dev Verifies that a missing source strategy leaves all vault state unchanged
rule executeRebalance_RevertWhen_NoActiveAdapter() {
    env e;
    uint256 rebalanceNonce;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require newStrategy.chainSelector == getThisChainSelector(), "target strategy should be on this chain";
    require adapterRegistry.getAdapter(e, newStrategy.protocolId) == adapter, "target adapter should be registered";
    require adapter.getVault() == currentContract, "target adapter should be bound to the vault";
    require !adapter.depositReverts(), "target adapter deposit should not revert";

    /// @dev revert condition being verified
    require getActiveProtocolAdapter() == 0, "active adapter should be zero";


    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert lastReverted;
}

/// @notice Rebalance execution reverts when a successful source withdrawal returns zero asset
/// @dev Verifies atomic rollback and absence of rebalance events
rule executeRebalance_RevertWhen_AmountRebalancedIsZero() {
    env e;
    uint256 rebalanceNonce;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require newStrategy.chainSelector == getThisChainSelector(), "target strategy should be on this chain";
    require adapterRegistry.getAdapter(e, newStrategy.protocolId) == adapter, "target adapter should be registered";
    require adapter.getVault() == currentContract, "target adapter should be bound to the vault";
    require !adapter.depositReverts(), "target adapter deposit should not revert";

    /// @dev revert condition being verified
    require adapter.getTVL() == 0, "adapter withdraw should return zero";

    require ghost_RebalanceWithdrawSuccess_EventCount == 0;
    require ghost_RebalanceWithdrawFailure_EventCount == 0;
    require ghost_RebalanceWithdrawRecoveryStored_EventCount == 0;

    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert lastReverted;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 0;
    assert ghost_RebalanceWithdrawFailure_EventCount == 0;
    assert ghost_RebalanceWithdrawRecoveryStored_EventCount == 0;
}

/// @notice A failed source withdrawal reverts when the recovery target chain selector is zero
/// @dev Verifies that invalid recovery data rolls back the failure event and leaves state unchanged
rule executeRebalance_When_WithdrawFails_RevertWhen_TargetChainSelectorIsZero() {
    env e;
    uint256 rebalanceNonce;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";

    /// @dev failure and revert conditions being verified
    require adapter.withdrawReverts(), "adapter withdraw should revert";
    require newStrategy.chainSelector == 0, "target chain selector should be zero";

    require ghost_RebalanceWithdrawFailure_EventCount == 0;
    require ghost_RebalanceWithdrawRecoveryStored_EventCount == 0;

    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert lastReverted;
    assert ghost_RebalanceWithdrawFailure_EventCount == 0;
    assert ghost_RebalanceWithdrawRecoveryStored_EventCount == 0;
}

/// @notice A failed source withdrawal stores recovery for the target strategy
/// @dev Verifies exact recovery state, failure events
rule executeRebalance_When_WithdrawFails_StoresRecovery() {
    env e;
    uint256 rebalanceNonce;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require newStrategy.chainSelector != 0, "target chain selector should not be zero";

    /// @dev failure condition being verified
    require adapter.withdrawReverts(), "adapter withdraw should revert";

    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    require ghost_RebalanceWithdrawSuccess_EventCount == 0;
    require ghost_RebalanceWithdrawFailure_EventCount == 0;
    require ghost_RebalanceWithdrawRecoveryStored_EventCount == 0;

    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert !lastReverted;
    Types.RebalanceWithdrawRecovery recovery = getRebalanceWithdrawRecovery();
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert getRecoveryMode() == Types.RecoveryMode.REBALANCE_WITHDRAW;
    assert recovery.rebalanceNonce == rebalanceNonce;
    assert recovery.strategy.protocolId == newStrategy.protocolId;
    assert recovery.strategy.chainSelector == newStrategy.chainSelector;
    assert recovery.createdAt == e.block.timestamp;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 0;
    assert ghost_RebalanceWithdrawFailure_EventCount == 1;
    assert ghost_RebalanceWithdrawFailure_Param_nonce == rebalanceNonce;
    assert ghost_RebalanceWithdrawRecoveryStored_EventCount == 1;
    assert ghost_RebalanceWithdrawRecoveryStored_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_RebalanceWithdrawRecoveryStored_Param_protocolId == newStrategy.protocolId;
    assert ghost_RebalanceWithdrawRecoveryStored_Param_chainSelector == newStrategy.chainSelector;
}

/// @notice A local rebalance reverts when the target protocol adapter is not registered
/// @dev Verifies atomic rollback of the completed source withdrawal
rule executeRebalance_Local_RevertWhen_TargetAdapterNotRegistered() {
    env e;
    uint256 rebalanceNonce;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() > 0, "adapter withdraw should return a nonzero amount";
    require newStrategy.chainSelector == getThisChainSelector(), "target strategy should be on this chain";

    /// @dev revert condition being verified
    require adapterRegistry.getAdapter(e, newStrategy.protocolId) == 0, "target adapter should not be registered";

    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert lastReverted;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
}

/// @notice A local rebalance reverts when the target adapter is bound to another vault
/// @dev Verifies atomic rollback of the completed source withdrawal
rule executeRebalance_Local_RevertWhen_TargetAdapterVaultIsInvalid() {
    env e;
    uint256 rebalanceNonce;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() > 0, "adapter withdraw should return a nonzero amount";
    require newStrategy.chainSelector == getThisChainSelector(), "target strategy should be on this chain";
    require invalidAdapter.getVault() != currentContract, "target adapter should not be bound to this vault";

    /// @dev revert condition being verified
    require adapterRegistry.getAdapter(e, newStrategy.protocolId) == invalidAdapter,
        "invalid target adapter should be registered";

    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert lastReverted;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
}

/// @notice A successful local rebalance withdraws and redeposits the full source TVL
/// @dev Verifies exact balances, adapter state, recovery state, events
rule executeRebalance_Local_Success() {
    env e;
    uint256 rebalanceNonce;
    Types.Strategy newStrategy;

    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require !adapter.depositReverts(), "target adapter deposit should not revert";
    require newStrategy.chainSelector == getThisChainSelector(), "target strategy should be on this chain";
    require adapterRegistry.getAdapter(e, newStrategy.protocolId) == adapter, "target adapter should be registered";
    require adapter.getVault() == currentContract, "target adapter should be bound to the vault";

    uint256 amountRebalanced = adapter.getTVL();
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    require amountRebalanced > 0, "adapter withdraw should return a nonzero amount";
    require amountRebalanced <= adapterBalanceBefore, "adapter balance should cover the withdrawal";
    require vaultBalanceBefore <= max_uint256 - amountRebalanced, "vault balance should not overflow";

    require ghost_RebalanceWithdrawSuccess_EventCount == 0;
    require ghost_RebalanceWithdrawFailure_EventCount == 0;
    require ghost_ActiveProtocolAdapterSet_EventCount == 0;
    require ghost_RebalanceDepositSuccess_EventCount == 0;
    require ghost_RebalanceDepositFailure_EventCount == 0;
    require ghost_RebalanceDepositRecoveryStored_EventCount == 0;

    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert !lastReverted;
    assert getActiveProtocolAdapter() == adapter;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == amountRebalanced;
    assert getRecoveryMode() == Types.RecoveryMode.NONE;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 1;
    assert ghost_RebalanceWithdrawSuccess_Param_nonce == rebalanceNonce;
    assert ghost_RebalanceWithdrawSuccess_Param_amount == amountRebalanced;
    assert ghost_RebalanceWithdrawFailure_EventCount == 0;
    assert ghost_ActiveProtocolAdapterSet_EventCount == 1;
    assert ghost_ActiveProtocolAdapterSet_Param_protocolId == newStrategy.protocolId;
    assert ghost_ActiveProtocolAdapterSet_Param_adapter == adapter;
    assert ghost_RebalanceDepositSuccess_EventCount == 1;
    assert ghost_RebalanceDepositSuccess_Param_nonce == rebalanceNonce;
    assert ghost_RebalanceDepositSuccess_Param_amount == amountRebalanced;
    assert ghost_RebalanceDepositFailure_EventCount == 0;
    assert ghost_RebalanceDepositRecoveryStored_EventCount == 0;
}

// @review vacuous
/// @notice A successful local rebalance can move funds from one adapter to a distinct target adapter
/// @dev Verifies source and target adapter balances/TVL independently.
rule executeRebalance_Local_DistinctTargetAdapter_Success() {
    env e;
    uint256 rebalanceNonce;
    Types.Strategy newStrategy;

    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getActiveProtocolAdapter() == adapter, "source adapter should be active";
    require targetAdapter != adapter, "target adapter should be distinct from source adapter";
    require targetAdapter != currentContract, "target adapter should not be the vault";
    require !adapter.withdrawReverts(), "source adapter withdraw should not revert";
    require !targetAdapter.depositReverts(), "target adapter deposit should not revert";
    require newStrategy.chainSelector == getThisChainSelector(), "target strategy should be on this chain";
    require adapterRegistry.getAdapter(e, newStrategy.protocolId) == targetAdapter,
        "target adapter should be registered";
    require targetAdapter.getVault() == currentContract, "target adapter should be bound to the vault";

    uint256 amountRebalanced = adapter.getTVL();
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 sourceBalanceBefore = asset.balanceOf(adapter);
    uint256 targetBalanceBefore = asset.balanceOf(targetAdapter);
    uint256 targetTVLBefore = targetAdapter.getTVL();

    require amountRebalanced > 0, "source withdraw should return a nonzero amount";
    require amountRebalanced <= sourceBalanceBefore, "source adapter balance should cover the withdrawal";
    require vaultBalanceBefore <= max_uint256 - amountRebalanced, "vault balance should not overflow";
    require targetBalanceBefore <= max_uint256 - amountRebalanced, "target balance should not overflow";
    require targetTVLBefore <= max_uint256 - amountRebalanced, "target TVL should not overflow";

    require ghost_RebalanceWithdrawSuccess_EventCount == 0;
    require ghost_RebalanceWithdrawFailure_EventCount == 0;
    require ghost_ActiveProtocolAdapterSet_EventCount == 0;
    require ghost_RebalanceDepositSuccess_EventCount == 0;
    require ghost_RebalanceDepositFailure_EventCount == 0;
    require ghost_RebalanceDepositRecoveryStored_EventCount == 0;

    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert !lastReverted;
    assert getActiveProtocolAdapter() == targetAdapter;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == sourceBalanceBefore - amountRebalanced;
    assert asset.balanceOf(targetAdapter) == targetBalanceBefore + amountRebalanced;
    assert adapter.getTVL() == 0;
    assert targetAdapter.getTVL() == targetTVLBefore + amountRebalanced;
    assert getRecoveryMode() == Types.RecoveryMode.NONE;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 1;
    assert ghost_RebalanceWithdrawSuccess_Param_nonce == rebalanceNonce;
    assert ghost_RebalanceWithdrawSuccess_Param_amount == amountRebalanced;
    assert ghost_RebalanceWithdrawFailure_EventCount == 0;
    assert ghost_ActiveProtocolAdapterSet_EventCount == 1;
    assert ghost_ActiveProtocolAdapterSet_Param_protocolId == newStrategy.protocolId;
    assert ghost_ActiveProtocolAdapterSet_Param_adapter == targetAdapter;
    assert ghost_RebalanceDepositSuccess_EventCount == 1;
    assert ghost_RebalanceDepositSuccess_Param_nonce == rebalanceNonce;
    assert ghost_RebalanceDepositSuccess_Param_amount == amountRebalanced;
    assert ghost_RebalanceDepositFailure_EventCount == 0;
    assert ghost_RebalanceDepositRecoveryStored_EventCount == 0;
}

/// @notice A failed local target deposit stores rebalance deposit recovery
/// @dev Verifies that the withdrawn asset remains in the vault with exact recovery state and events
rule executeRebalance_Local_When_DepositFails_StoresRecovery() {
    env e;
    uint256 rebalanceNonce;
    Types.Strategy newStrategy;

    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.depositReverts(), "target adapter deposit should revert";
    require newStrategy.chainSelector == getThisChainSelector(), "target strategy should be on this chain";
    require adapterRegistry.getAdapter(e, newStrategy.protocolId) == adapter, "target adapter should be registered";
    require adapter.getVault() == currentContract, "target adapter should be bound to the vault";

    uint256 amountRebalanced = adapter.getTVL();
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    require amountRebalanced > 0, "adapter withdraw should return a nonzero amount";
    require amountRebalanced <= adapterBalanceBefore, "adapter balance should cover the withdrawal";
    require vaultBalanceBefore <= max_uint256 - amountRebalanced, "vault balance should not overflow";

    require ghost_RebalanceWithdrawSuccess_EventCount == 0;
    require ghost_ActiveProtocolAdapterSet_EventCount == 0;
    require ghost_RebalanceDepositSuccess_EventCount == 0;
    require ghost_RebalanceDepositFailure_EventCount == 0;
    require ghost_RebalanceDepositRecoveryStored_EventCount == 0;

    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert !lastReverted;
    Types.RebalanceDepositRecovery recovery = getRebalanceDepositRecovery();
    assert getActiveProtocolAdapter() == adapter;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore + amountRebalanced;
    assert asset.balanceOf(adapter) == adapterBalanceBefore - amountRebalanced;
    assert adapter.getTVL() == 0;
    assert getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT;
    assert recovery.rebalanceNonce == rebalanceNonce;
    assert recovery.amount == amountRebalanced;
    assert recovery.createdAt == e.block.timestamp;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 1;
    assert ghost_RebalanceWithdrawSuccess_Param_nonce == rebalanceNonce;
    assert ghost_RebalanceWithdrawSuccess_Param_amount == amountRebalanced;
    assert ghost_ActiveProtocolAdapterSet_EventCount == 1;
    assert ghost_ActiveProtocolAdapterSet_Param_protocolId == newStrategy.protocolId;
    assert ghost_ActiveProtocolAdapterSet_Param_adapter == adapter;
    assert ghost_RebalanceDepositSuccess_EventCount == 0;
    assert ghost_RebalanceDepositFailure_EventCount == 1;
    assert ghost_RebalanceDepositFailure_Param_nonce == rebalanceNonce;
    assert ghost_RebalanceDepositFailure_Param_amount == amountRebalanced;
    assert ghost_RebalanceDepositRecoveryStored_EventCount == 1;
    assert ghost_RebalanceDepositRecoveryStored_Param_nonce == rebalanceNonce;
    assert ghost_RebalanceDepositRecoveryStored_Param_amount == amountRebalanced;
}

/// @notice A remote rebalance reverts when the target chain selector is zero
/// @dev Verifies atomic rollback of the source withdrawal and active adapter clearing
rule executeRebalance_Remote_RevertWhen_TargetChainSelectorIsZero() {
    env e;
    uint256 rebalanceNonce;
    Types.Strategy newStrategy;

    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() > 0, "adapter withdraw should return a nonzero amount";
    require getThisChainSelector() != 0, "this chain should not be 0";

    /// @dev revert condition being verified
    require newStrategy.chainSelector == 0, "target chain selector should be zero";

    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();
    require adapterTVLBefore <= adapterBalanceBefore, "adapter balance should cover the withdrawal";
    require vaultBalanceBefore <= max_uint256 - adapterTVLBefore, "vault balance should not overflow";
    require adapterTVLBefore < max_uint256, "adapter TVL should be below the maximum uint256 value";
    require ghost_ActiveProtocolAdapterCleared_EventCount == 0;

    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert lastReverted;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_ActiveProtocolAdapterCleared_EventCount == 0;
}

/// @notice A remote rebalance reverts when no target vault is registered
/// @dev Verifies atomic rollback of the source withdrawal and active adapter clearing
rule executeRebalance_Remote_RevertWhen_TargetVaultNotRegistered() {
    env e;
    uint256 rebalanceNonce;
    Types.Strategy newStrategy;

    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() > 0, "adapter withdraw should return a nonzero amount";
    require newStrategy.chainSelector != 0, "target chain selector should not be zero";
    require newStrategy.chainSelector != getThisChainSelector(), "target strategy should be remote";

    /// @dev revert condition being verified
    require getCrosschainVault(newStrategy.chainSelector) == 0, "target vault should not be registered";

    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();
    require adapterTVLBefore <= adapterBalanceBefore, "adapter balance should cover the withdrawal";
    require vaultBalanceBefore <= max_uint256 - adapterTVLBefore, "vault balance should not overflow";
    require ghost_ActiveProtocolAdapterCleared_EventCount == 0;

    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert lastReverted;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_ActiveProtocolAdapterCleared_EventCount == 0;
}

/// @notice A successful remote rebalance bridges the full source TVL to the target child
/// @dev Verifies exact balances, active adapter clearing, recovery state, and events
rule executeRebalance_Remote_Success() {
    env e;
    uint256 rebalanceNonce;
    Types.Strategy newStrategy;

    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require newStrategy.chainSelector != 0, "target chain selector should not be zero";
    require newStrategy.chainSelector != getThisChainSelector(), "target strategy should be remote";
    require getCrosschainVault(newStrategy.chainSelector) != 0, "target vault should be registered";
    require getCcipGasLimit(newStrategy.chainSelector) != 0, "target chain CCIP gas limit should not be zero";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    uint256 amountRebalanced = adapter.getTVL();
    uint256 fee = ccipRouter.getFee();
    address router = getRouter();
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);
    uint256 vaultLinkBalanceBefore = link.balanceOf(currentContract);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);
    require amountRebalanced > 0, "adapter withdraw should return a nonzero amount";
    require amountRebalanced <= adapterAssetBalanceBefore, "adapter balance should cover the withdrawal";
    require vaultAssetBalanceBefore <= max_uint256 - amountRebalanced, "vault balance should not overflow";
    require routerAssetBalanceBefore <= max_uint256 - amountRebalanced, "router asset balance should not overflow";
    require fee <= vaultLinkBalanceBefore, "vault LINK balance should cover the CCIP fee";
    require routerLinkBalanceBefore <= max_uint256 - fee, "router LINK balance should not overflow";

    require ghost_RebalanceWithdrawSuccess_EventCount == 0;
    require ghost_ActiveProtocolAdapterCleared_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;
    require ghost_CcipSendRecoveryStored_EventCount == 0;

    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert !lastReverted;
    assert getActiveProtocolAdapter() == 0;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore - amountRebalanced;
    assert asset.balanceOf(router) == routerAssetBalanceBefore + amountRebalanced;
    assert adapter.getTVL() == 0;
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore - fee;
    assert link.balanceOf(router) == routerLinkBalanceBefore + fee;
    assert getRecoveryMode() == Types.RecoveryMode.NONE;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 1;
    assert ghost_RebalanceWithdrawSuccess_Param_nonce == rebalanceNonce;
    assert ghost_RebalanceWithdrawSuccess_Param_amount == amountRebalanced;
    assert ghost_ActiveProtocolAdapterCleared_EventCount == 1;
    assert ghost_ActiveProtocolAdapterCleared_Param_adapter == adapter;
    assert ghost_CCIPBridged_EventCount == 1;
    assert ghost_CCIPBridged_Param_amount == amountRebalanced;
    assert ghost_CCIPBridged_Param_ccipTxType == Types.CcipTx.REBALANCE;
    assert ghost_CcipSendRecoveryStored_EventCount == 0;
}

// @review vacuous
/// @notice A remote rebalance stores CCIP recovery when the router fee lookup fails
/// @dev Verifies that withdrawal and active adapter clearing remain committed
rule executeRebalance_Remote_When_RouterGetFeeReverts_StoresCcipSendRecovery() {
    env e;
    uint256 rebalanceNonce;
    Types.Strategy newStrategy;

    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require newStrategy.chainSelector != 0, "target chain selector should not be zero";
    require newStrategy.chainSelector != getThisChainSelector(), "target strategy should be remote";
    require getCrosschainVault(newStrategy.chainSelector) != 0, "target vault should be registered";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev failure condition being verified
    require ccipRouter.getFeeReverts(), "router fee lookup should revert";

    uint256 amountRebalanced = adapter.getTVL();
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    address router = getRouter();
    uint256 routerBalanceBefore = asset.balanceOf(router);
    require amountRebalanced > 0, "adapter withdraw should return a nonzero amount";
    require amountRebalanced <= adapterBalanceBefore, "adapter balance should cover the withdrawal";
    require vaultBalanceBefore <= max_uint256 - amountRebalanced, "vault balance should not overflow";

    require ghost_RebalanceWithdrawSuccess_EventCount == 0;
    require ghost_ActiveProtocolAdapterCleared_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;
    require ghost_CcipSendRecoveryStored_EventCount == 0;

    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert !lastReverted;
    assert getActiveProtocolAdapter() == 0;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore + amountRebalanced;
    assert asset.balanceOf(adapter) == adapterBalanceBefore - amountRebalanced;
    assert asset.balanceOf(router) == routerBalanceBefore;
    assert adapter.getTVL() == 0;
    assert getRecoveryMode() == Types.RecoveryMode.CCIP_SEND;
    assert getCcipSendRecoveryTxType() == Types.CcipTx.REBALANCE;
    assert getCcipSendRecoveryAmount() == amountRebalanced;
    assert getCcipSendRecoveryDestinationChainSelector() == newStrategy.chainSelector;
    uint256 storedRebalanceNonce;
    bytes32 storedProtocolId;
    (storedRebalanceNonce, storedProtocolId) = getCcipSendRecoveryRebalanceData();
    assert storedRebalanceNonce == rebalanceNonce;
    assert storedProtocolId == newStrategy.protocolId;
    assert getCcipSendRecoveryCreatedAt() == e.block.timestamp;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 1;
    assert ghost_RebalanceWithdrawSuccess_Param_nonce == rebalanceNonce;
    assert ghost_RebalanceWithdrawSuccess_Param_amount == amountRebalanced;
    assert ghost_ActiveProtocolAdapterCleared_EventCount == 1;
    assert ghost_ActiveProtocolAdapterCleared_Param_adapter == adapter;
    assert ghost_CCIPBridged_EventCount == 0;
    assert ghost_CcipSendRecoveryStored_EventCount == 1;
    assert ghost_CcipSendRecoveryStored_Param_ccipTxType == Types.CcipTx.REBALANCE;
    assert ghost_CcipSendRecoveryStored_Param_destinationChainSelector == newStrategy.chainSelector;
    assert ghost_CcipSendRecoveryStored_Param_amount == amountRebalanced;
}

// @review vacuous
/// @notice A remote rebalance stores CCIP recovery when the router send fails
/// @dev Verifies atomic send rollback while preserving withdrawal and active adapter clearing
rule executeRebalance_Remote_When_RouterCcipSendReverts_StoresCcipSendRecovery() {
    env e;
    uint256 rebalanceNonce;
    Types.Strategy newStrategy;

    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require newStrategy.chainSelector != 0, "target chain selector should not be zero";
    require newStrategy.chainSelector != getThisChainSelector(), "target strategy should be remote";
    require getCrosschainVault(newStrategy.chainSelector) != 0, "target vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";

    /// @dev failure condition being verified
    require ccipRouter.ccipSendReverts(), "router send should revert";

    uint256 amountRebalanced = adapter.getTVL();
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    address router = getRouter();
    uint256 routerBalanceBefore = asset.balanceOf(router);
    require amountRebalanced > 0, "adapter withdraw should return a nonzero amount";
    require amountRebalanced <= adapterBalanceBefore, "adapter balance should cover the withdrawal";
    require vaultBalanceBefore <= max_uint256 - amountRebalanced, "vault balance should not overflow";

    require ghost_RebalanceWithdrawSuccess_EventCount == 0;
    require ghost_ActiveProtocolAdapterCleared_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;
    require ghost_CcipSendRecoveryStored_EventCount == 0;

    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert !lastReverted;
    assert getActiveProtocolAdapter() == 0;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore + amountRebalanced;
    assert asset.balanceOf(adapter) == adapterBalanceBefore - amountRebalanced;
    assert asset.balanceOf(router) == routerBalanceBefore;
    assert adapter.getTVL() == 0;
    assert getRecoveryMode() == Types.RecoveryMode.CCIP_SEND;
    assert getCcipSendRecoveryTxType() == Types.CcipTx.REBALANCE;
    assert getCcipSendRecoveryAmount() == amountRebalanced;
    assert getCcipSendRecoveryDestinationChainSelector() == newStrategy.chainSelector;
    uint256 storedRebalanceNonce;
    bytes32 storedProtocolId;
    (storedRebalanceNonce, storedProtocolId) = getCcipSendRecoveryRebalanceData();
    assert storedRebalanceNonce == rebalanceNonce;
    assert storedProtocolId == newStrategy.protocolId;
    assert getCcipSendRecoveryCreatedAt() == e.block.timestamp;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 1;
    assert ghost_RebalanceWithdrawSuccess_Param_nonce == rebalanceNonce;
    assert ghost_RebalanceWithdrawSuccess_Param_amount == amountRebalanced;
    assert ghost_ActiveProtocolAdapterCleared_EventCount == 1;
    assert ghost_ActiveProtocolAdapterCleared_Param_adapter == adapter;
    assert ghost_CCIPBridged_EventCount == 0;
    assert ghost_CcipSendRecoveryStored_EventCount == 1;
    assert ghost_CcipSendRecoveryStored_Param_ccipTxType == Types.CcipTx.REBALANCE;
    assert ghost_CcipSendRecoveryStored_Param_destinationChainSelector == newStrategy.chainSelector;
    assert ghost_CcipSendRecoveryStored_Param_amount == amountRebalanced;
}


/// ─────────────────── RECOVER FAILED EPOCH WITHDRAW ──────────

/// @notice Epoch withdraw recovery reverts when the call is reentrant
/// @dev Verifies that recovery state, balances, TVL, and events remain unchanged
rule recoverFailedEpochWithdraw_RevertWhen_ReentrantCall() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getRecoveryMode() == Types.RecoveryMode.EPOCH_WITHDRAW, "epoch withdraw recovery should be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require getEpochWithdrawRecovery().amount != 0, "recovery amount should not be zero";
    require adapter.getTVL() > 0, "adapter withdraw should return a nonzero amount";
    require getCrosschainVault(getParentChainSelector()) != 0, "parent vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";
    require currentContract.i_parentChainSelector != 0 && currentContract.i_parentChainSelector != currentContract.i_thisChainSelector,
        "destination selector should be valid";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";

    storage before = lastStorage;
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token arithmetic conditions
    require adapterTVLBefore <= adapterAssetBalanceBefore, "adapter asset balance should cover the withdrawn amount";
    require vaultAssetBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_EpochWithdrawRecoveryCleared_EventCount == 0;
    require ghost_WithdrawFromStrategySuccess_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;

    recoverFailedEpochWithdraw@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_EpochWithdrawRecoveryCleared_EventCount == 0;
    assert ghost_WithdrawFromStrategySuccess_EventCount == 0;
    assert ghost_CCIPBridged_EventCount == 0;
}

/// @notice Epoch withdraw recovery reverts when no epoch withdraw recovery is pending
/// @dev Verifies that balances, TVL, and events remain unchanged
rule recoverFailedEpochWithdraw_RevertWhen_NoPendingRecovery() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require getCrosschainVault(getParentChainSelector()) != 0, "parent vault should be registered";
    require getEpochWithdrawRecovery().amount != 0, "recovery amount should not be zero";
    require adapter.getTVL() > 0, "adapter withdraw should return a nonzero amount";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";
    require currentContract.i_parentChainSelector != 0 && currentContract.i_parentChainSelector != currentContract.i_thisChainSelector,
        "destination selector should be valid";

    /// @dev revert condition being verified
    require getRecoveryMode() != Types.RecoveryMode.EPOCH_WITHDRAW, "epoch withdraw recovery should not be pending";

    storage before = lastStorage;
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token arithmetic conditions
    require adapterTVLBefore <= adapterAssetBalanceBefore, "adapter asset balance should cover the withdrawn amount";
    require vaultAssetBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_EpochWithdrawRecoveryCleared_EventCount == 0;
    require ghost_WithdrawFromStrategySuccess_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;

    recoverFailedEpochWithdraw@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_EpochWithdrawRecoveryCleared_EventCount == 0;
    assert ghost_WithdrawFromStrategySuccess_EventCount == 0;
    assert ghost_CCIPBridged_EventCount == 0;
}

/// @notice Epoch withdraw recovery reverts when no active adapter is set
/// @dev Verifies that recovery state, balances, TVL, and events remain unchanged
rule recoverFailedEpochWithdraw_RevertWhen_NoActiveAdapter() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.EPOCH_WITHDRAW, "epoch withdraw recovery should be pending";
    require getEpochWithdrawRecovery().amount != 0, "recovery amount should not be zero";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() > 0, "adapter withdraw should return a nonzero amount";
    require getCrosschainVault(getParentChainSelector()) != 0, "parent vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";
    require currentContract.i_parentChainSelector != 0 && currentContract.i_parentChainSelector != currentContract.i_thisChainSelector,
        "destination selector should be valid";

    /// @dev revert condition being verified
    require getActiveProtocolAdapter() == 0, "active adapter should not be set";

    storage before = lastStorage;
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token arithmetic conditions
    require adapterTVLBefore <= adapterAssetBalanceBefore, "adapter asset balance should cover the withdrawn amount";
    require vaultAssetBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_EpochWithdrawRecoveryCleared_EventCount == 0;
    require ghost_WithdrawFromStrategySuccess_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;

    recoverFailedEpochWithdraw@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_EpochWithdrawRecoveryCleared_EventCount == 0;
    assert ghost_WithdrawFromStrategySuccess_EventCount == 0;
    assert ghost_CCIPBridged_EventCount == 0;
}

/// @notice Epoch withdraw recovery reverts when the adapter withdraw fails
/// @dev Verifies atomic rollback of recovery state, balances, TVL, and events
rule recoverFailedEpochWithdraw_RevertWhen_WithdrawFails() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.EPOCH_WITHDRAW, "epoch withdraw recovery should be pending";
    require getEpochWithdrawRecovery().amount != 0, "recovery amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require adapter.getTVL() > 0, "adapter withdraw should return a nonzero amount";
    require getCrosschainVault(getParentChainSelector()) != 0, "parent vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";
    require currentContract.i_parentChainSelector != 0 && currentContract.i_parentChainSelector != currentContract.i_thisChainSelector,
        "destination selector should be valid";

    /// @dev revert condition being verified
    require adapter.withdrawReverts(), "adapter withdraw should revert";

    storage before = lastStorage;
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token arithmetic conditions
    require adapterTVLBefore <= adapterAssetBalanceBefore, "adapter asset balance should cover the withdrawn amount";
    require vaultAssetBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_EpochWithdrawRecoveryCleared_EventCount == 0;
    require ghost_WithdrawFromStrategySuccess_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;

    recoverFailedEpochWithdraw@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_EpochWithdrawRecoveryCleared_EventCount == 0;
    assert ghost_WithdrawFromStrategySuccess_EventCount == 0;
    assert ghost_CCIPBridged_EventCount == 0;
}

/// @notice Epoch withdraw recovery reverts when the retry withdraw returns zero
/// @dev Verifies that zero recovery output leaves recovery state, balances, TVL, and events unchanged
rule recoverFailedEpochWithdraw_RevertWhen_AmountOutIsZero() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.EPOCH_WITHDRAW, "epoch withdraw recovery should be pending";
    require getEpochWithdrawRecovery().amount != 0, "recovery amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require getCrosschainVault(getParentChainSelector()) != 0, "parent vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";
    require currentContract.i_parentChainSelector != 0 && currentContract.i_parentChainSelector != currentContract.i_thisChainSelector,
        "destination selector should be valid";

    /// @dev revert condition being verified
    require adapter.getTVL() == 0, "adapter withdraw should return zero";

    storage before = lastStorage;
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);

    /// @dev set ghost starting values
    require ghost_EpochWithdrawRecoveryCleared_EventCount == 0;
    require ghost_WithdrawFromStrategySuccess_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;

    recoverFailedEpochWithdraw@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore;
    assert adapter.getTVL() == 0;
    assert ghost_EpochWithdrawRecoveryCleared_EventCount == 0;
    assert ghost_WithdrawFromStrategySuccess_EventCount == 0;
    assert ghost_CCIPBridged_EventCount == 0;
}

/// @notice Epoch withdraw recovery reverts when the parent chain selector is invalid
/// @dev Verifies atomic rollback because CCIP validation runs before the caught router send
rule recoverFailedEpochWithdraw_RevertWhen_ParentChainSelectorInvalid() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.EPOCH_WITHDRAW, "epoch withdraw recovery should be pending";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require getEpochWithdrawRecovery().amount != 0, "recovery amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() > 0, "adapter withdraw should return a nonzero amount";
    require getCrosschainVault(getParentChainSelector()) != 0, "parent vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev failure condition being verified
    require currentContract.i_parentChainSelector == 0 || currentContract.i_parentChainSelector == currentContract.i_thisChainSelector,
        "destination selector should be invalid";

    storage before = lastStorage;
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();
    address router = getRouter();
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);
    uint256 vaultLinkBalanceBefore = link.balanceOf(currentContract);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);

    /// @dev mock token arithmetic conditions
    require adapterTVLBefore <= adapterAssetBalanceBefore, "adapter asset balance should cover the withdrawn amount";
    require vaultAssetBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_EpochWithdrawRecoveryCleared_EventCount == 0;
    require ghost_WithdrawFromStrategySuccess_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;
    require ghost_CcipSendRecoveryStored_EventCount == 0;

    recoverFailedEpochWithdraw@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore;
    assert asset.balanceOf(router) == routerAssetBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore;
    assert link.balanceOf(router) == routerLinkBalanceBefore;
    assert ghost_EpochWithdrawRecoveryCleared_EventCount == 0;
    assert ghost_WithdrawFromStrategySuccess_EventCount == 0;
    assert ghost_CCIPBridged_EventCount == 0;
    assert ghost_CcipSendRecoveryStored_EventCount == 0;
}

/// @notice Epoch withdraw recovery reverts when the parent vault is not registered
/// @dev Verifies atomic rollback because CCIP validation runs before the caught router send
rule recoverFailedEpochWithdraw_RevertWhen_ParentVaultNotRegistered() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.EPOCH_WITHDRAW, "epoch withdraw recovery should be pending";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require getEpochWithdrawRecovery().amount != 0, "recovery amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() > 0, "adapter withdraw should return a nonzero amount";
    require currentContract.i_parentChainSelector != 0 && currentContract.i_parentChainSelector != currentContract.i_thisChainSelector,
        "destination selector should be valid";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev failure condition being verified
    require getCrosschainVault(getParentChainSelector()) == 0, "parent vault should not be registered";

    storage before = lastStorage;
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();
    address router = getRouter();
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);
    uint256 vaultLinkBalanceBefore = link.balanceOf(currentContract);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);

    /// @dev mock token arithmetic conditions
    require adapterTVLBefore <= adapterAssetBalanceBefore, "adapter asset balance should cover the withdrawn amount";
    require vaultAssetBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_EpochWithdrawRecoveryCleared_EventCount == 0;
    require ghost_WithdrawFromStrategySuccess_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;
    require ghost_CcipSendRecoveryStored_EventCount == 0;

    recoverFailedEpochWithdraw@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore;
    assert asset.balanceOf(router) == routerAssetBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore;
    assert link.balanceOf(router) == routerLinkBalanceBefore;
    assert ghost_EpochWithdrawRecoveryCleared_EventCount == 0;
    assert ghost_WithdrawFromStrategySuccess_EventCount == 0;
    assert ghost_CCIPBridged_EventCount == 0;
    assert ghost_CcipSendRecoveryStored_EventCount == 0;
}

/// @notice Epoch withdraw recovery withdraws the stored amount, clears recovery, and bridges to the parent
/// @dev Verifies balances, TVL, recovery deletion, storage writes, and events
rule recoverFailedEpochWithdraw_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.EPOCH_WITHDRAW, "epoch withdraw recovery should be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require getCrosschainVault(getParentChainSelector()) != 0, "parent vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";
    require currentContract.i_parentChainSelector != 0 && currentContract.i_parentChainSelector != currentContract.i_thisChainSelector,
        "destination selector should be valid";

    Types.EpochRecovery recovery = getEpochWithdrawRecovery();
    uint256 adapterTVLBefore = adapter.getTVL();
    uint256 amountOut = recovery.amount > adapterTVLBefore ? adapterTVLBefore : recovery.amount;
    uint256 fee = ccipRouter.getFee();
    address router = getRouter();
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);
    uint256 vaultLinkBalanceBefore = link.balanceOf(currentContract);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);

    /// @dev mock token arithmetic conditions
    require recovery.amount != 0, "recovery amount should not be zero";
    require amountOut != 0, "withdraw amount out should not be zero";
    require amountOut <= adapterAssetBalanceBefore, "adapter asset balance should cover the withdrawn amount";
    require fee <= vaultLinkBalanceBefore, "vault LINK balance should cover the CCIP fee";
    require routerLinkBalanceBefore <= max_uint256 - fee, "router LINK balance should not overflow";
    require routerAssetBalanceBefore <= max_uint256 - amountOut, "router asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_EpochWithdrawRecoveryCleared_EventCount == 0;
    require ghost_WithdrawFromStrategySuccess_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;

    recoverFailedEpochWithdraw@withrevert(e);

    assert !lastReverted;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore - amountOut;
    assert asset.balanceOf(router) == routerAssetBalanceBefore + amountOut;
    assert adapter.getTVL() == adapterTVLBefore - amountOut;
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore - fee;
    assert link.balanceOf(router) == routerLinkBalanceBefore + fee;
    assert getRecoveryMode() == Types.RecoveryMode.NONE;
    assert getEpochWithdrawRecovery().epochNonce == 0;
    assert getEpochWithdrawRecovery().amount == 0;
    assert getEpochWithdrawRecovery().createdAt == 0;
    assert ghost_EpochWithdrawRecoveryCleared_EventCount == 1;
    assert ghost_EpochWithdrawRecoveryCleared_Param_epochNonce == recovery.epochNonce;
    assert ghost_WithdrawFromStrategySuccess_EventCount == 1;
    assert ghost_WithdrawFromStrategySuccess_Param_epochNonce == recovery.epochNonce;
    assert ghost_WithdrawFromStrategySuccess_Param_amount == amountOut;
    assert ghost_CCIPBridged_EventCount == 1;
    assert ghost_CCIPBridged_Param_amount == amountOut;
    assert ghost_CCIPBridged_Param_ccipTxType == Types.CcipTx.EPOCH_NET_WITHDRAW;
}

/// @notice Epoch withdraw recovery stores CCIP recovery when the router fee lookup fails after withdrawal
/// @dev Verifies that epoch withdraw recovery is cleared and the withdrawn asset stays in the vault
rule recoverFailedEpochWithdraw_When_RouterGetFeeReverts_StoresCcipSendRecovery() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.EPOCH_WITHDRAW, "epoch withdraw recovery should be pending";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() > 0, "adapter withdraw should return a nonzero amount";
    require getCrosschainVault(getParentChainSelector()) != 0, "parent vault should be registered";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";
    require currentContract.i_parentChainSelector != 0 && currentContract.i_parentChainSelector != currentContract.i_thisChainSelector,
        "destination selector should be valid";

    /// @dev failure condition being verified
    require ccipRouter.getFeeReverts(), "router fee lookup should revert";

    Types.EpochRecovery recovery = getEpochWithdrawRecovery();
    uint256 adapterTVLBefore = adapter.getTVL();
    uint256 amountOut = recovery.amount > adapterTVLBefore ? adapterTVLBefore : recovery.amount;
    address router = getRouter();
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);
    uint256 vaultLinkBalanceBefore = link.balanceOf(currentContract);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);

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

    recoverFailedEpochWithdraw@withrevert(e);

    assert !lastReverted;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore + amountOut;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore - amountOut;
    assert asset.balanceOf(router) == routerAssetBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore - amountOut;
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore;
    assert link.balanceOf(router) == routerLinkBalanceBefore;
    assert getEpochWithdrawRecovery().epochNonce == 0;
    assert getEpochWithdrawRecovery().amount == 0;
    assert getEpochWithdrawRecovery().createdAt == 0;
    assert getRecoveryMode() == Types.RecoveryMode.CCIP_SEND;
    assert getCcipSendRecoveryTxType() == Types.CcipTx.EPOCH_NET_WITHDRAW;
    assert getCcipSendRecoveryAmount() == amountOut;
    assert getCcipSendRecoveryDestinationChainSelector() == getParentChainSelector();
    assert getCcipSendRecoveryCreatedAt() == e.block.timestamp;
    assert ghost_EpochWithdrawRecoveryCleared_EventCount == 1;
    assert ghost_EpochWithdrawRecoveryCleared_Param_epochNonce == recovery.epochNonce;
    assert ghost_WithdrawFromStrategySuccess_EventCount == 1;
    assert ghost_WithdrawFromStrategySuccess_Param_epochNonce == recovery.epochNonce;
    assert ghost_WithdrawFromStrategySuccess_Param_amount == amountOut;
    assert ghost_CCIPBridged_EventCount == 0;
    assert ghost_CcipSendRecoveryStored_EventCount == 1;
    assert ghost_CcipSendRecoveryStored_Param_ccipTxType == Types.CcipTx.EPOCH_NET_WITHDRAW;
    assert ghost_CcipSendRecoveryStored_Param_destinationChainSelector == getParentChainSelector();
    assert ghost_CcipSendRecoveryStored_Param_amount == amountOut;
}

/// @notice Epoch withdraw recovery stores CCIP recovery when the router send fails after withdrawal
/// @dev Verifies atomic send rollback while preserving the completed recovery withdrawal
rule recoverFailedEpochWithdraw_When_RouterCcipSendReverts_StoresCcipSendRecovery() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.EPOCH_WITHDRAW, "epoch withdraw recovery should be pending";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() > 0, "adapter withdraw should return a nonzero amount";
    require getCrosschainVault(getParentChainSelector()) != 0, "parent vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require currentContract.i_parentChainSelector != 0 && currentContract.i_parentChainSelector != currentContract.i_thisChainSelector,
        "destination selector should be valid";

    /// @dev failure condition being verified
    require ccipRouter.ccipSendReverts(), "router send should revert";

    Types.EpochRecovery recovery = getEpochWithdrawRecovery();
    uint256 adapterTVLBefore = adapter.getTVL();
    uint256 amountOut = recovery.amount > adapterTVLBefore ? adapterTVLBefore : recovery.amount;
    address router = getRouter();
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);
    uint256 vaultLinkBalanceBefore = link.balanceOf(currentContract);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);

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

    recoverFailedEpochWithdraw@withrevert(e);

    assert !lastReverted;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore + amountOut;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore - amountOut;
    assert asset.balanceOf(router) == routerAssetBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore - amountOut;
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore;
    assert link.balanceOf(router) == routerLinkBalanceBefore;
    assert getEpochWithdrawRecovery().epochNonce == 0;
    assert getEpochWithdrawRecovery().amount == 0;
    assert getEpochWithdrawRecovery().createdAt == 0;
    assert getRecoveryMode() == Types.RecoveryMode.CCIP_SEND;
    assert getCcipSendRecoveryTxType() == Types.CcipTx.EPOCH_NET_WITHDRAW;
    assert getCcipSendRecoveryAmount() == amountOut;
    assert getCcipSendRecoveryDestinationChainSelector() == getParentChainSelector();
    assert getCcipSendRecoveryCreatedAt() == e.block.timestamp;
    assert ghost_EpochWithdrawRecoveryCleared_EventCount == 1;
    assert ghost_EpochWithdrawRecoveryCleared_Param_epochNonce == recovery.epochNonce;
    assert ghost_WithdrawFromStrategySuccess_EventCount == 1;
    assert ghost_WithdrawFromStrategySuccess_Param_epochNonce == recovery.epochNonce;
    assert ghost_WithdrawFromStrategySuccess_Param_amount == amountOut;
    assert ghost_CCIPBridged_EventCount == 0;
    assert ghost_CcipSendRecoveryStored_EventCount == 1;
    assert ghost_CcipSendRecoveryStored_Param_ccipTxType == Types.CcipTx.EPOCH_NET_WITHDRAW;
    assert ghost_CcipSendRecoveryStored_Param_destinationChainSelector == getParentChainSelector();
    assert ghost_CcipSendRecoveryStored_Param_amount == amountOut;
}

/// ─────────────────── RECOVER FAILED CCIP SEND ───────────────

/// @notice CCIP send recovery reverts when the call is reentrant
/// @dev Verifies that recovery state, balances, and events remain unchanged
rule recoverFailedCcipSend_RevertWhen_ReentrantCall() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getRecoveryMode() == Types.RecoveryMode.CCIP_SEND, "CCIP send recovery should be pending";
    require getCcipSendRecoveryAmount() != 0, "recovery amount should not be zero";
    require getCcipSendRecoveryDestinationChainSelector() != 0, "destination chain selector should not be zero";
    require getCcipSendRecoveryDestinationChainSelector() != getThisChainSelector(), "destination should not be this chain";
    require getCrosschainVault(getCcipSendRecoveryDestinationChainSelector()) != 0, "destination vault should be registered";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "stored CCIP tx data should be empty and well-formed";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";

    storage before = lastStorage;
    uint256 bridgeAmount = getCcipSendRecoveryAmount();
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
    require ghost_CcipSendRecoveryCleared_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;

    recoverFailedCcipSend@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore;
    assert link.balanceOf(router) == routerLinkBalanceBefore;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(router) == routerAssetBalanceBefore;
    assert ghost_CcipSendRecoveryCleared_EventCount == 0;
    assert ghost_CCIPBridged_EventCount == 0;
}

/// @notice CCIP send recovery reverts when no CCIP send recovery is pending
/// @dev Verifies that balances and events remain unchanged
rule recoverFailedCcipSend_RevertWhen_NoPendingRecovery() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getCcipSendRecoveryAmount() != 0, "recovery amount should not be zero";
    require getCcipSendRecoveryDestinationChainSelector() != 0, "destination chain selector should not be zero";
    require getCcipSendRecoveryDestinationChainSelector() != getThisChainSelector(), "destination should not be this chain";
    require getCrosschainVault(getCcipSendRecoveryDestinationChainSelector()) != 0, "destination vault should be registered";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "stored CCIP tx data should be empty and well-formed";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev revert condition being verified
    require getRecoveryMode() != Types.RecoveryMode.CCIP_SEND, "CCIP send recovery should not be pending";

    storage before = lastStorage;
    uint256 bridgeAmount = getCcipSendRecoveryAmount();
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
    require ghost_CcipSendRecoveryCleared_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;

    recoverFailedCcipSend@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore;
    assert link.balanceOf(router) == routerLinkBalanceBefore;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(router) == routerAssetBalanceBefore;
    assert ghost_CcipSendRecoveryCleared_EventCount == 0;
    assert ghost_CCIPBridged_EventCount == 0;
}

/// @notice CCIP send recovery reverts when the stored bridge amount is zero
/// @dev Verifies atomic rollback because CCIP validation rejects zero amounts
rule recoverFailedCcipSend_RevertWhen_AmountIsZero() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.CCIP_SEND, "CCIP send recovery should be pending";
    require getCcipSendRecoveryDestinationChainSelector() != 0, "destination chain selector should not be zero";
    require getCcipSendRecoveryDestinationChainSelector() != getThisChainSelector(), "destination should not be this chain";
    require getCrosschainVault(getCcipSendRecoveryDestinationChainSelector()) != 0, "destination vault should be registered";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "stored CCIP tx data should be empty and well-formed";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev revert condition being verified
    require getCcipSendRecoveryAmount() == 0, "recovery amount should be zero";

    storage before = lastStorage;
    address router = getRouter();
    uint256 vaultLinkBalanceBefore = link.balanceOf(currentContract);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);

    /// @dev set ghost starting values
    require ghost_CcipSendRecoveryCleared_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;

    recoverFailedCcipSend@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore;
    assert link.balanceOf(router) == routerLinkBalanceBefore;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(router) == routerAssetBalanceBefore;
    assert ghost_CcipSendRecoveryCleared_EventCount == 0;
    assert ghost_CCIPBridged_EventCount == 0;
}

/// @notice CCIP send recovery reverts when the stored destination selector is invalid
/// @dev Verifies atomic rollback because CCIP validation rejects zero and same-chain destinations
rule recoverFailedCcipSend_RevertWhen_DestinationChainSelectorInvalid() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.CCIP_SEND, "CCIP send recovery should be pending";
    require getCcipSendRecoveryAmount() != 0, "recovery amount should not be zero";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "stored CCIP tx data should be empty and well-formed";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev revert condition being verified
    require getCcipSendRecoveryDestinationChainSelector() == 0
        || getCcipSendRecoveryDestinationChainSelector() == getThisChainSelector(),
        "destination selector should be invalid";

    storage before = lastStorage;
    uint256 bridgeAmount = getCcipSendRecoveryAmount();
    address router = getRouter();
    uint256 vaultLinkBalanceBefore = link.balanceOf(currentContract);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);

    /// @dev mock token arithmetic conditions
    require bridgeAmount <= vaultAssetBalanceBefore, "vault asset balance should cover the bridge amount";
    require routerAssetBalanceBefore <= max_uint256 - bridgeAmount, "router asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_CcipSendRecoveryCleared_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;

    recoverFailedCcipSend@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore;
    assert link.balanceOf(router) == routerLinkBalanceBefore;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(router) == routerAssetBalanceBefore;
    assert ghost_CcipSendRecoveryCleared_EventCount == 0;
    assert ghost_CCIPBridged_EventCount == 0;
}

/// @notice CCIP send recovery reverts when the destination vault is not registered
/// @dev Verifies atomic rollback because CCIP validation requires a registered destination vault
rule recoverFailedCcipSend_RevertWhen_DestinationVaultNotRegistered() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.CCIP_SEND, "CCIP send recovery should be pending";
    require getCcipSendRecoveryAmount() != 0, "recovery amount should not be zero";
    require getCcipSendRecoveryDestinationChainSelector() != 0, "destination chain selector should not be zero";
    require getCcipSendRecoveryDestinationChainSelector() != getThisChainSelector(), "destination should not be this chain";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "stored CCIP tx data should be empty and well-formed";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev revert condition being verified
    require getCrosschainVault(getCcipSendRecoveryDestinationChainSelector()) == 0,
        "destination vault should not be registered";

    storage before = lastStorage;
    uint256 bridgeAmount = getCcipSendRecoveryAmount();
    address router = getRouter();
    uint256 vaultLinkBalanceBefore = link.balanceOf(currentContract);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);

    /// @dev mock token arithmetic conditions
    require bridgeAmount <= vaultAssetBalanceBefore, "vault asset balance should cover the bridge amount";
    require routerAssetBalanceBefore <= max_uint256 - bridgeAmount, "router asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_CcipSendRecoveryCleared_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;

    recoverFailedCcipSend@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore;
    assert link.balanceOf(router) == routerLinkBalanceBefore;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(router) == routerAssetBalanceBefore;
    assert ghost_CcipSendRecoveryCleared_EventCount == 0;
    assert ghost_CCIPBridged_EventCount == 0;
}

/// @notice CCIP send recovery clear deletes recovery state and emits CcipSendRecoveryCleared
/// @dev Verifies the internal clear boundary used by recoverFailedCcipSend before BaseVaultCcipLib._send.
///      CCIP send validation, router calls, token movement, and CCIPBridged are verified in BaseVaultCcipLib.spec.
rule clearCcipSendRecovery_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";

    /// @dev success conditions being verified
    require getRecoveryMode() == Types.RecoveryMode.CCIP_SEND, "CCIP send recovery should be pending";
    require getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0),
        "stored CCIP tx data should be empty and well-formed";

    Types.CcipTx ccipTxType = getCcipSendRecoveryTxType();
    uint64 destinationChainSelector = getCcipSendRecoveryDestinationChainSelector();
    uint256 bridgeAmount = getCcipSendRecoveryAmount();

    /// @dev set ghost starting values
    require ghost_CcipSendRecoveryCleared_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;

    clearCcipSendRecovery@withrevert(e);

    assert !lastReverted;
    assert getRecoveryMode() == Types.RecoveryMode.NONE;
    assert getCcipSendRecoveryTxType() == Types.CcipTx.EPOCH_NET_DEPOSIT;
    assert getCcipSendRecoveryAmount() == 0;
    assert getCcipSendRecoveryDestinationChainSelector() == 0;
    assert getCcipSendRecoveryCreatedAt() == 0;
    assert getCcipSendRecoveryTxDataStorageSlot() == to_bytes32(0);
    assert ghost_CcipSendRecoveryCleared_EventCount == 1;
    assert ghost_CcipSendRecoveryCleared_Param_ccipTxType == ccipTxType;
    assert ghost_CcipSendRecoveryCleared_Param_destinationChainSelector == destinationChainSelector;
    assert ghost_CcipSendRecoveryCleared_Param_amount == bridgeAmount;
    assert ghost_CCIPBridged_EventCount == 0;
}

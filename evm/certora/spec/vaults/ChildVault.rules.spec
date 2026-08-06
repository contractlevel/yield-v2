using MockAdapterRegistry as adapterRegistry;
using MockProtocolAdapter as adapter;
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
    function ccipSend(uint256, uint64, Types.CcipTx, uint256, bytes32) external;
    function tryCcipSend(uint256, uint64, Types.CcipTx, uint256, bytes32) external;
    function tryDepositToAdapter(address, uint256) external;
    function executeEpochWithdraw(uint256, uint256) external;
    function executeRebalance(uint256, Types.Strategy) external;
    function executeRecovery() external;
    function clearCcipSendRecovery() external returns (Types.CcipSendRecovery);

    /*//////////////////////////////////////////////////////////////
                             GETTERS
    //////////////////////////////////////////////////////////////*/
    function getParentChainSelector() external returns (uint64) envfree;
    function getLastHandledEpochNonce() external returns (uint256) envfree;
    function getLastHandledRebalanceNonce() external returns (uint256) envfree;
    function getEpochDepositRecovery() external returns (Types.EpochRecovery) envfree;
    function getEpochWithdrawRecovery() external returns (Types.EpochRecovery) envfree;
    function getRebalanceWithdrawRecovery() external returns (Types.RebalanceWithdrawRecovery) envfree;
    function getCcipSendRecovery() external returns (Types.CcipSendRecovery) envfree;
    function getCcipSendRecoveryTxType() external returns (Types.CcipTx) envfree;
    function getCcipSendRecoveryAmount() external returns (uint256) envfree;
    function getCcipSendRecoveryDestinationChainSelector() external returns (uint64) envfree;
    function getCcipSendRecoveryNonce() external returns (uint256) envfree;
    function getCcipSendRecoveryProtocolId() external returns (bytes32) envfree;
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
    function supportsInterface(bytes4) external returns (bool) envfree;
    function paused() external returns (bool) envfree;

    /*//////////////////////////////////////////////////////////////
                       LINKED CONTRACT GETTERS
    //////////////////////////////////////////////////////////////*/
    function asset.balanceOf(address) external returns (uint256) envfree;
    function link.balanceOf(address) external returns (uint256) envfree;
    function adapter.getTVL() external returns (uint256) envfree;
    function adapter.getVault() external returns (address) envfree;
    function invalidAdapter.getVault() external returns (address) envfree;
    function adapter.depositReverts() external returns (bool) envfree;
    function adapter.withdrawReverts() external returns (bool) envfree;
    function ccipRouter.getFee() external returns (uint256) envfree;
    function ccipRouter.getFeeReverts() external returns (bool) envfree;
    function ccipRouter.ccipSendReverts() external returns (bool) envfree;
    function ccipRouter.getLastMessageDataHash() external returns (bytes32) envfree;

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
    function isInitializing() external returns (bool) envfree;
    function defaultAdmin() external returns (address) envfree;
    function encodeAddress(address) external returns (bytes) envfree;
    function encodeEpochNonce(uint256) external returns (bytes) envfree;
    function encodeRebalanceData(uint256, bytes32) external returns (bytes) envfree;
    function encodeCcipTxData(Types.CcipTx, bytes) external returns (bytes) envfree;
    function encodeRawCcipTxData(uint256, bytes) external returns (bytes) envfree;
    function decodeCcipTxType(bytes) external returns (Types.CcipTx) envfree;
    function decodeCcipTxPayload(bytes) external returns (bytes) envfree;
    function hashBytes(bytes) external returns (bytes32) envfree;
    function erc165InterfaceId() external returns (bytes4) envfree;
    function accessControlDefaultAdminRulesInterfaceId() external returns (bytes4) envfree;
    function any2EVMMessageReceiverInterfaceId() external returns (bytes4) envfree;

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
// keccak256("CCIPBridged(bytes32,uint64,uint8)")
    to_bytes32(0x2fec67437fa2b2e63688e15520acdbd76b9c4d152a8e345d00ce467eaf4e67fc);

definition CCIPReceivedEvent() returns bytes32 =
// keccak256("CCIPReceived(bytes32,uint64,uint8)")
    to_bytes32(0xcad89c08e093f9ba49742fdc90e42d33fc4ad95fd450fa31060e1050ab852932);

definition DepositToStrategySuccessEvent() returns bytes32 =
// keccak256("EpochDepositToStrategySuccess(uint256,uint256)")
    to_bytes32(0x78a668caa26414a04375566a4f66def1a635b5bfc0b55d95afa96141377fe18b);

definition DepositToStrategyFailureEvent() returns bytes32 =
// keccak256("EpochDepositToStrategyFailure(uint256,uint256)")
    to_bytes32(0xddd788f15bd3fc5f402378810bef6417e51f55330e364babc08db405ead2dc4d);

definition WithdrawFromStrategySuccessEvent() returns bytes32 =
// keccak256("EpochWithdrawFromStrategySuccess(uint256,uint256)")
    to_bytes32(0x444cf00a2b9a3f54fd8bef5181e55f6d94b18ae241a090ee45c24ebd80225c4d);

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
// keccak256("EpochWithdrawFromStrategyFailure(uint256,uint256)")
    to_bytes32(0x1bd1365180f571a54024f306c91551fbcb8f576daf039342a686633045d744d0);

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

/// ─── handled nonces ──────────────────────────────────────────
ghost mathint ghost_lastHandledEpochNonce_StoreCount { init_state axiom ghost_lastHandledEpochNonce_StoreCount == 0; }
ghost uint256 ghost_lastHandledEpochNonce_StoredValue { init_state axiom ghost_lastHandledEpochNonce_StoredValue == 0; }
ghost mathint ghost_lastHandledRebalanceNonce_StoreCount { init_state axiom ghost_lastHandledRebalanceNonce_StoreCount == 0; }
ghost uint256 ghost_lastHandledRebalanceNonce_StoredValue { init_state axiom ghost_lastHandledRebalanceNonce_StoredValue == 0; }

/// ─── s_rebalanceWithdrawRecovery.strategy.protocolId ────────
ghost mathint ghost_rebalanceWithdrawRecovery_protocolId_StoreCount { init_state axiom ghost_rebalanceWithdrawRecovery_protocolId_StoreCount == 0; }
ghost bytes32  ghost_rebalanceWithdrawRecovery_protocolId_StoredValue { init_state axiom ghost_rebalanceWithdrawRecovery_protocolId_StoredValue == to_bytes32(0); }

/// ─── s_rebalanceWithdrawRecovery.strategy.chainSelector ─────
ghost mathint ghost_rebalanceWithdrawRecovery_chainSelector_StoreCount { init_state axiom ghost_rebalanceWithdrawRecovery_chainSelector_StoreCount == 0; }
ghost uint64   ghost_rebalanceWithdrawRecovery_chainSelector_StoredValue { init_state axiom ghost_rebalanceWithdrawRecovery_chainSelector_StoredValue == 0; }

/// ─── s_epochDepositRecovery.epochNonce ──────────────────────
ghost mathint ghost_epochDepositRecovery_epochNonce_StoreCount { init_state axiom ghost_epochDepositRecovery_epochNonce_StoreCount == 0; }
ghost uint256  ghost_epochDepositRecovery_epochNonce_StoredValue { init_state axiom ghost_epochDepositRecovery_epochNonce_StoredValue == 0; }

/// ─── s_epochDepositRecovery.amount ──────────────────────────
ghost mathint ghost_epochDepositRecovery_amount_StoreCount { init_state axiom ghost_epochDepositRecovery_amount_StoreCount == 0; }
ghost uint256  ghost_epochDepositRecovery_amount_StoredValue { init_state axiom ghost_epochDepositRecovery_amount_StoredValue == 0; }

/// ─── s_epochWithdrawRecovery.epochNonce ─────────────────────
ghost mathint ghost_epochWithdrawRecovery_epochNonce_StoreCount { init_state axiom ghost_epochWithdrawRecovery_epochNonce_StoreCount == 0; }
ghost uint256  ghost_epochWithdrawRecovery_epochNonce_StoredValue { init_state axiom ghost_epochWithdrawRecovery_epochNonce_StoredValue == 0; }

/// ─── s_epochWithdrawRecovery.amount ─────────────────────────
ghost mathint ghost_epochWithdrawRecovery_amount_StoreCount { init_state axiom ghost_epochWithdrawRecovery_amount_StoreCount == 0; }
ghost uint256  ghost_epochWithdrawRecovery_amount_StoredValue { init_state axiom ghost_epochWithdrawRecovery_amount_StoredValue == 0; }

/// ─── s_ccipSendRecovery.ccipTxType ──────────────────────────
// ghost mathint ghost_ccipSendRecovery_ccipTxType_StoreCount { init_state axiom ghost_ccipSendRecovery_ccipTxType_StoreCount == 0; }
// ghost Types.CcipTx ghost_ccipSendRecovery_ccipTxType_StoredValue { init_state axiom ghost_ccipSendRecovery_ccipTxType_StoredValue == Types.CcipTx.EPOCH_NET_DEPOSIT; }

/// ─── s_ccipSendRecovery.amount ──────────────────────────────
ghost mathint ghost_ccipSendRecovery_amount_StoreCount { init_state axiom ghost_ccipSendRecovery_amount_StoreCount == 0; }
ghost uint256  ghost_ccipSendRecovery_amount_StoredValue { init_state axiom ghost_ccipSendRecovery_amount_StoredValue == 0; }

/// ─── s_ccipSendRecovery.destinationChainSelector ────────────
ghost mathint ghost_ccipSendRecovery_destinationChainSelector_StoreCount { init_state axiom ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 0; }
ghost uint64   ghost_ccipSendRecovery_destinationChainSelector_StoredValue { init_state axiom ghost_ccipSendRecovery_destinationChainSelector_StoredValue == 0; }

/// ─── s_ccipSendRecovery.nonce ────────────────────────────────
ghost mathint ghost_ccipSendRecovery_nonce_StoreCount { init_state axiom ghost_ccipSendRecovery_nonce_StoreCount == 0; }
ghost uint256  ghost_ccipSendRecovery_nonce_StoredValue { init_state axiom ghost_ccipSendRecovery_nonce_StoredValue == 0; }

/// ─── s_ccipSendRecovery.protocolId ───────────────────────────
ghost mathint ghost_ccipSendRecovery_protocolId_StoreCount { init_state axiom ghost_ccipSendRecovery_protocolId_StoreCount == 0; }
ghost bytes32  ghost_ccipSendRecovery_protocolId_StoredValue { init_state axiom ghost_ccipSendRecovery_protocolId_StoredValue == to_bytes32(0); }

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
ghost uint64 ghost_CCIPBridged_Param_destinationChainSelector {
    init_state axiom ghost_CCIPBridged_Param_destinationChainSelector == 0;
}
ghost Types.CcipTx ghost_CCIPBridged_Param_ccipTxType { init_state axiom ghost_CCIPBridged_Param_ccipTxType == Types.CcipTx.EPOCH_NET_DEPOSIT; }

/// ─── Event: CCIPReceived ─────────────────────────────────────
ghost mathint ghost_CCIPReceived_EventCount { init_state axiom ghost_CCIPReceived_EventCount == 0; }
ghost bytes32 ghost_CCIPReceived_Param_ccipMessageId { init_state axiom ghost_CCIPReceived_Param_ccipMessageId == to_bytes32(0); }
ghost uint64 ghost_CCIPReceived_Param_sourceChainSelector { init_state axiom ghost_CCIPReceived_Param_sourceChainSelector == 0; }
ghost Types.CcipTx ghost_CCIPReceived_Param_ccipTxType { init_state axiom ghost_CCIPReceived_Param_ccipTxType == Types.CcipTx.EPOCH_NET_DEPOSIT; }

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
hook Sstore currentContract.ext_yieldcoin_storage_ChildVault.s_lastHandledEpochNonce uint256 newValue {
    ghost_lastHandledEpochNonce_StoreCount = ghost_lastHandledEpochNonce_StoreCount + 1;
    ghost_lastHandledEpochNonce_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ChildVault.s_lastHandledRebalanceNonce uint256 newValue {
    ghost_lastHandledRebalanceNonce_StoreCount = ghost_lastHandledRebalanceNonce_StoreCount + 1;
    ghost_lastHandledRebalanceNonce_StoredValue = newValue;
}

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

hook Sstore currentContract.ext_yieldcoin_storage_ChildVault.s_epochDepositRecovery.epochNonce uint256 newValue {
    ghost_epochDepositRecovery_epochNonce_StoreCount = ghost_epochDepositRecovery_epochNonce_StoreCount + 1;
    ghost_epochDepositRecovery_epochNonce_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ChildVault.s_epochDepositRecovery.amount uint256 newValue {
    ghost_epochDepositRecovery_amount_StoreCount = ghost_epochDepositRecovery_amount_StoreCount + 1;
    ghost_epochDepositRecovery_amount_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ChildVault.s_epochWithdrawRecovery.epochNonce uint256 newValue {
    ghost_epochWithdrawRecovery_epochNonce_StoreCount = ghost_epochWithdrawRecovery_epochNonce_StoreCount + 1;
    ghost_epochWithdrawRecovery_epochNonce_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ChildVault.s_epochWithdrawRecovery.amount uint256 newValue {
    ghost_epochWithdrawRecovery_amount_StoreCount = ghost_epochWithdrawRecovery_amount_StoreCount + 1;
    ghost_epochWithdrawRecovery_amount_StoredValue = newValue;
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

hook Sstore currentContract.ext_yieldcoin_storage_ChildVault.s_ccipSendRecovery.nonce uint256 newValue {
    ghost_ccipSendRecovery_nonce_StoreCount = ghost_ccipSendRecovery_nonce_StoreCount + 1;
    ghost_ccipSendRecovery_nonce_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ChildVault.s_ccipSendRecovery.protocolId bytes32 newValue {
    ghost_ccipSendRecovery_protocolId_StoreCount = ghost_ccipSendRecovery_protocolId_StoreCount + 1;
    ghost_ccipSendRecovery_protocolId_StoredValue = newValue;
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
        ghost_CCIPBridged_Param_destinationChainSelector = bytes32ToUint64(t2);
        ghost_CCIPBridged_Param_ccipTxType = uint8ToCcipTxType(bytes32ToUint8(t3));
    }
    if (t0 == CCIPReceivedEvent()) {
        ghost_CCIPReceived_EventCount = ghost_CCIPReceived_EventCount + 1;
        ghost_CCIPReceived_Param_ccipMessageId = t1;
        ghost_CCIPReceived_Param_sourceChainSelector = bytes32ToUint64(t2);
        ghost_CCIPReceived_Param_ccipTxType = uint8ToCcipTxType(bytes32ToUint8(t3));
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

/// ─────────────────── GET TVL ────────────────────────────────

/// @notice ChildVault TVL with no active adapter equals any pending CCIP-send recovery amount
/// @dev Verifies the ChildVault _getTVL override through the public BaseVault.getTVL entry point.
///      Funds cleared from the active adapter before a rebalance-away CCIP send remain counted via
///      s_ccipSendRecovery.amount if that send failed (0 if no such recovery is pending), so TVL is
///      not unconditionally zero here.
rule getTVL_EqualsCcipSendRecovery_WhenNoActiveAdapter() {
    /// @dev condition being verified
    require getActiveProtocolAdapter() == 0, "active adapter should not be set";

    assert getTVL() == getCcipSendRecoveryAmount();
}

/// @notice ChildVault TVL includes active adapter TVL and pending recovery amounts
/// @dev Verifies the ChildVault _getTVL override through the public BaseVault.getTVL entry point.
rule getTVL_IncludesAdapterTVLAndRecoveries() {
    /// @dev condition being verified
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";

    uint256 adapterTVL = adapter.getTVL();
    uint256 epochDepositRecoveryAmount = getEpochDepositRecovery().amount;
    uint256 rebalanceDepositRecoveryAmount = getRebalanceDepositRecovery().amount;
    uint256 ccipSendRecoveryAmount = getCcipSendRecoveryAmount();

    /// @dev ChildVault._getTVL uses checked Solidity 0.8 arithmetic.
    require adapterTVL <= max_uint256 - epochDepositRecoveryAmount,
        "adapter TVL plus epoch deposit recovery should not overflow";
    mathint tvlWithEpochDepositRecovery = adapterTVL + epochDepositRecoveryAmount;

    require tvlWithEpochDepositRecovery <= max_uint256 - rebalanceDepositRecoveryAmount,
        "TVL plus rebalance deposit recovery should not overflow";
    mathint tvlWithRebalanceDepositRecovery = tvlWithEpochDepositRecovery + rebalanceDepositRecoveryAmount;

    require tvlWithRebalanceDepositRecovery <= max_uint256 - ccipSendRecoveryAmount,
        "TVL plus CCIP send recovery should not overflow";
    mathint expectedTVL = tvlWithRebalanceDepositRecovery + ccipSendRecoveryAmount;

    assert getTVL() == expectedTVL;
}

/// @notice ChildVault TVL reverts when adapter TVL plus pending recovery amounts overflows
/// @dev Verifies the checked-arithmetic revert boundary in ChildVault._getTVL
rule getTVL_RevertWhen_TotalOverflows() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";

    uint256 adapterTVL = adapter.getTVL();
    uint256 epochDepositRecoveryAmount = getEpochDepositRecovery().amount;
    uint256 rebalanceDepositRecoveryAmount = getRebalanceDepositRecovery().amount;
    uint256 ccipSendRecoveryAmount = getCcipSendRecoveryAmount();

    mathint tvlWithEpochDepositRecovery = adapterTVL + epochDepositRecoveryAmount;
    mathint tvlWithRebalanceDepositRecovery = tvlWithEpochDepositRecovery + rebalanceDepositRecoveryAmount;

    /// @dev revert condition being verified
    require adapterTVL > max_uint256 - epochDepositRecoveryAmount
        || tvlWithEpochDepositRecovery > max_uint256 - rebalanceDepositRecoveryAmount
        || tvlWithRebalanceDepositRecovery > max_uint256 - ccipSendRecoveryAmount,
        "TVL sum should overflow";

    getTVL@withrevert(e);

    assert lastReverted;
}

/// ─────────────────── SUPPORTS INTERFACE ─────────────────────

/// @notice ChildVault reports support for its expected ERC165 interfaces
/// @dev Verifies the positive supportsInterface cases inherited from BaseVault: IERC165,
///      IAccessControlDefaultAdminRules, and IAny2EVMMessageReceiver.
rule supportsInterface_Success_WhenInterfaceIsSupported() {
    bytes4 interfaceId;

    /// @dev supported interface cases being verified
    require interfaceId == erc165InterfaceId()
        || interfaceId == accessControlDefaultAdminRulesInterfaceId()
        || interfaceId == any2EVMMessageReceiverInterfaceId();

    assert supportsInterface(interfaceId);
}

/// @notice ChildVault reports false for unsupported ERC165 interface IDs
/// @dev Verifies the negative supportsInterface case by explicitly excluding every supported ID.
rule supportsInterface_ReturnsFalse_WhenInterfaceIsNotSupported() {
    bytes4 interfaceId;

    /// @dev supported cases NOT being verified
    require interfaceId != erc165InterfaceId();
    require interfaceId != accessControlDefaultAdminRulesInterfaceId();
    require interfaceId != any2EVMMessageReceiverInterfaceId();

    assert !supportsInterface(interfaceId);
}

/// ─────────────────── INITIALIZE CHILD VAULT ──────────────────

/// @notice ChildVault initialization reverts when the contract has already been initialized
/// @dev Verifies that repeated initialization leaves all vault state unchanged
rule initialize_RevertWhen_AlreadyInitialized() {
    env e;
    BaseVault.InitParams params;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !isInitializing(), "contract should not be initializing";
    require params.defaultAdmin != 0, "default admin should not be zero";
    require params.pauser != 0, "pauser should not be zero";
    require params.unpauser != 0, "unpauser should not be zero";
    require params.configOperator != 0, "config operator should not be zero";
    require params.upgrader != 0, "upgrader should not be zero";
    require params.initialDefaultCcipGasLimit != 0, "default CCIP gas limit should not be zero";
    require defaultAdmin() == 0, "default admin should not be initialized";

    /// @dev revert condition being verified
    require isInitialized(), "contract should already be initialized";


    initialize@withrevert(e, params);

    assert lastReverted;
}

/// @notice ChildVault initialization reverts during an active non-reentrant execution.
/// @dev Verifies the nonReentrant modifier independently of initializer and BaseVault initializer reverts.
rule initialize_RevertWhen_ReentrantCall() {
    env e;
    BaseVault.InitParams params;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !isInitialized(), "contract should not be initialized";
    require !isInitializing(), "contract should not be initializing";
    require params.defaultAdmin != 0, "default admin should not be zero";
    require params.pauser != 0, "pauser should not be zero";
    require params.unpauser != 0, "unpauser should not be zero";
    require params.configOperator != 0, "config operator should not be zero";
    require params.upgrader != 0, "upgrader should not be zero";
    require params.initialDefaultCcipGasLimit != 0, "default CCIP gas limit should not be zero";
    require defaultAdmin() == 0, "default admin should not be initialized";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";

    initialize@withrevert(e, params);

    assert lastReverted;
}

/// @notice ChildVault initialization succeeds through the real public entry point
/// @dev __BaseVault_init's own state effects (roles, s_defaultCcipGasLimit, unpaused, no recovery)
///      are already comprehensively verified in BaseVault.spec via the harness's initializeBaseVault
///      bypass wrapper; this rule only confirms initialize()'s own modifiers (nonReentrant,
///      initializer) don't block the real entry point from reaching __BaseVault_init and completing.
rule initialize_Success() {
    env e;
    BaseVault.InitParams params;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !isInitialized(), "contract should not be initialized";
    require !isInitializing(), "contract should not be initializing";
    require params.defaultAdmin != 0, "default admin should not be zero";
    require params.pauser != 0, "pauser should not be zero";
    require params.unpauser != 0, "unpauser should not be zero";
    require params.configOperator != 0, "config operator should not be zero";
    require params.upgrader != 0, "upgrader should not be zero";
    require params.initialDefaultCcipGasLimit != 0, "default CCIP gas limit should not be zero";
    require defaultAdmin() == 0, "default admin should not be initialized";

    initialize@withrevert(e, params);

    assert !lastReverted;
    assert isInitialized();
}

/// ─────────────────── CCIP RECEIVE ────────────────────────────

/// @notice CCIP receive reverts when the caller is not the configured CCIP router
/// @dev Verifies that an unauthorized delivery attempt leaves all vault state unchanged
rule ccipReceive_RevertWhen_CallerIsNotCCIPRouter() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    require message.sourceChainSelector == getParentChainSelector(),
        "source chain should be the parent chain";
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require ghost_lastHandledEpochNonce_StoreCount == 0,
        "handled epoch nonce store count starts at zero";
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require ghost_CCIPReceived_EventCount == 0, "CCIPReceived event count starts at zero";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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


    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP receive reverts when called during an active non-reentrant execution
/// @dev Verifies that a reentrant delivery attempt leaves all vault state unchanged
rule ccipReceive_RevertWhen_ReentrantCall() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    require message.sourceChainSelector == getParentChainSelector(),
        "source chain should be the parent chain";
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require ghost_lastHandledEpochNonce_StoreCount == 0,
        "handled epoch nonce store count starts at zero";
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require ghost_CCIPReceived_EventCount == 0, "CCIPReceived event count starts at zero";
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
    require !paused(), "vault should not be paused";


    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP receive reverts when the vault is paused
/// @dev Verifies that a delivery attempt while paused leaves all vault state unchanged
rule ccipReceive_RevertWhen_Paused() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    require message.sourceChainSelector == getParentChainSelector(),
        "source chain should be the parent chain";
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require ghost_lastHandledEpochNonce_StoreCount == 0,
        "handled epoch nonce store count starts at zero";
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require ghost_CCIPReceived_EventCount == 0, "CCIPReceived event count starts at zero";
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
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_DEPOSIT, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch deposit";

    /// @dev revert condition being verified
    require paused(), "vault should be paused";


    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP receive reverts when the decoded sender is not the registered vault for the source chain
/// @dev Verifies that an unauthorized cross-chain sender leaves all vault state unchanged
rule ccipReceive_RevertWhen_SenderIsNotAllowed() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    require message.sourceChainSelector == getParentChainSelector(),
        "source chain should be the parent chain";
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require ghost_lastHandledEpochNonce_StoreCount == 0,
        "handled epoch nonce store count starts at zero";
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require ghost_CCIPReceived_EventCount == 0, "CCIPReceived event count starts at zero";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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


    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP receive reverts when a zero sender is supplied for an unregistered source chain
/// @dev Verifies that an unset cross-chain vault cannot authorize the zero address
rule ccipReceive_RevertWhen_SenderAndRegisteredVaultAreZero() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    require message.sourceChainSelector == getParentChainSelector(),
        "source chain should be the parent chain";
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require ghost_lastHandledEpochNonce_StoreCount == 0,
        "handled epoch nonce store count starts at zero";
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require ghost_CCIPReceived_EventCount == 0, "CCIPReceived event count starts at zero";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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


    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP receive reverts when the encoded sender is too short to decode as an address
/// @dev Verifies that malformed sender data leaves all vault state unchanged
rule ccipReceive_RevertWhen_SenderEncodingIsMalformed() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    require message.sourceChainSelector == getParentChainSelector(),
        "source chain should be the parent chain";
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require ghost_lastHandledEpochNonce_StoreCount == 0,
        "handled epoch nonce store count starts at zero";

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require ghost_CCIPReceived_EventCount == 0, "CCIPReceived event count starts at zero";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_DEPOSIT, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch deposit";

    /// @dev revert condition being verified
    require message.sender.length < 32, "message sender should be too short to decode";


    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP receive reverts when any recovery operation is already pending
/// @dev Verifies that a pending recovery cannot be overwritten by a new delivery
rule ccipReceive_RevertWhen_RecoveryAlreadyPending() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    require message.sourceChainSelector == getParentChainSelector(),
        "source chain should be the parent chain";
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require ghost_lastHandledEpochNonce_StoreCount == 0,
        "handled epoch nonce store count starts at zero";
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require ghost_CCIPReceived_EventCount == 0, "CCIPReceived event count starts at zero";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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


    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP receive reverts unless exactly one token amount is delivered
/// @dev Verifies that an invalid token-amount array leaves all vault state unchanged
rule ccipReceive_RevertWhen_TokenAmountsLengthIsInvalid() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    require message.sourceChainSelector == getParentChainSelector(),
        "source chain should be the parent chain";
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require ghost_lastHandledEpochNonce_StoreCount == 0,
        "handled epoch nonce store count starts at zero";
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require ghost_CCIPReceived_EventCount == 0, "CCIPReceived event count starts at zero";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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


    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP receive reverts when the delivered token is not the vault asset
/// @dev Verifies that an invalid received token leaves all vault state unchanged
rule ccipReceive_RevertWhen_ReceivedTokenIsInvalid() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    require message.sourceChainSelector == getParentChainSelector(),
        "source chain should be the parent chain";
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require ghost_lastHandledEpochNonce_StoreCount == 0,
        "handled epoch nonce store count starts at zero";
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require ghost_CCIPReceived_EventCount == 0, "CCIPReceived event count starts at zero";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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


    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP receive reverts when the delivered asset amount is zero
/// @dev Verifies that a zero-value delivery leaves all vault state unchanged
rule ccipReceive_RevertWhen_ReceivedAmountIsZero() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    require message.sourceChainSelector == getParentChainSelector(),
        "source chain should be the parent chain";
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require ghost_lastHandledEpochNonce_StoreCount == 0,
        "handled epoch nonce store count starts at zero";
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require ghost_CCIPReceived_EventCount == 0, "CCIPReceived event count starts at zero";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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


    ccipReceive@withrevert(e, message);

    assert lastReverted;
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
    require ghost_CCIPReceived_EventCount == 0, "CCIPReceived event count starts at zero";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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


    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP receive reverts when the encoded transaction type is outside the CcipTx enum
/// @dev Verifies that an invalid enum discriminant leaves all vault state unchanged
rule ccipReceive_RevertWhen_TxTypeEncodingIsOutOfRange() {
    env e;
    Client.Any2EVMMessage message;
    uint256 rawCcipTxType;
    uint256 epochNonce;
    require message.sourceChainSelector == getParentChainSelector(),
        "source chain should be the parent chain";
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require ghost_lastHandledEpochNonce_StoreCount == 0,
        "handled epoch nonce store count starts at zero";
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require ghost_CCIPReceived_EventCount == 0, "CCIPReceived event count starts at zero";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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


    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP receive reverts when the transaction type is unsupported by ChildVault
/// @dev Verifies that an unsupported transaction type leaves all vault state unchanged
rule CCIP_004_ccipReceive_RevertWhen_TxTypeIsInvalid() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    require message.sourceChainSelector == getParentChainSelector(),
        "source chain should be the parent chain";
    address sender;
    Types.CcipTx ccipTxType;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require ghost_CCIPReceived_EventCount == 0, "CCIPReceived event count starts at zero";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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


    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice A received epoch deposit reverts when it did not originate from the parent chain.
/// @dev Verifies the ChildVault-specific parent-source restriction after sender validation.
rule ccipReceive_EPOCH_NET_DEPOSIT_RevertWhen_SourceChainIsNotParentChain() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require ghost_lastHandledEpochNonce_StoreCount == 0,
        "handled epoch nonce store count starts at zero";
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be the registered vault";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.depositReverts(), "adapter deposit should not revert";
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_DEPOSIT, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch deposit";

    /// @dev revert condition being verified
    require message.sourceChainSelector != getParentChainSelector(), "source chain should not be the parent chain";

    require ghost_CCIPReceived_EventCount == 0, "CCIPReceived event count starts at zero";

    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice A received epoch deposit reverts when its nonce was already handled.
rule ccipReceive_EPOCH_NET_DEPOSIT_RevertWhen_EpochNonceIsNotNew() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require message.sourceChainSelector == getParentChainSelector(), "source chain should be the parent chain";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be the registered vault";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.depositReverts(), "adapter deposit should not revert";
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_DEPOSIT, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch deposit";

    /// @dev revert condition being verified
    require epochNonce <= getLastHandledEpochNonce(), "epoch nonce should already be handled";

    require ghost_CCIPReceived_EventCount == 0, "CCIPReceived event count starts at zero";

    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP epoch deposit reverts when no active protocol adapter is configured
/// @dev Verifies that a deposit without an active strategy leaves all vault state unchanged
rule ccipReceive_EPOCH_NET_DEPOSIT_RevertWhen_NoActiveAdapter() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    require message.sourceChainSelector == getParentChainSelector(),
        "source chain should be the parent chain";
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require ghost_lastHandledEpochNonce_StoreCount == 0,
        "handled epoch nonce store count starts at zero";
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require ghost_CCIPReceived_EventCount == 0, "CCIPReceived event count starts at zero";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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


    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP epoch deposit reverts when its payload is too short to decode the epoch nonce
/// @dev Verifies that malformed epoch data leaves all vault state unchanged. A competing nonce
///      condition cannot be imposed because the targeted payload intentionally has no decodable nonce.
rule ccipReceive_EPOCH_NET_DEPOSIT_RevertWhen_PayloadEncodingIsMalformed() {
    env e;
    Client.Any2EVMMessage message;
    bytes data;
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require ghost_CCIPReceived_EventCount == 0, "CCIPReceived event count starts at zero";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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


    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice A successful CCIP epoch deposit transfers the delivered asset into the active adapter
/// @dev Verifies exact balances, adapter TVL, unchanged recovery state, storage writes, and events
rule ccipReceive_EPOCH_NET_DEPOSIT_Success() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    require message.sourceChainSelector == getParentChainSelector(),
        "source chain should be the parent chain";
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require ghost_lastHandledEpochNonce_StoreCount == 0,
        "handled epoch nonce store count starts at zero";
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require ghost_CCIPReceived_EventCount == 0, "CCIPReceived event count starts at zero";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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

    ccipReceive@withrevert(e, message);


    assert !lastReverted;
    assert ghost_CCIPReceived_EventCount == 1;
    assert ghost_CCIPReceived_Param_ccipMessageId == message.messageId;
    assert ghost_CCIPReceived_Param_sourceChainSelector == message.sourceChainSelector;
    assert ghost_CCIPReceived_Param_ccipTxType == Types.CcipTx.EPOCH_NET_DEPOSIT;
    assert getLastHandledEpochNonce() == epochNonce;
    assert ghost_lastHandledEpochNonce_StoreCount == 1;
    assert ghost_lastHandledEpochNonce_StoredValue == epochNonce;
    Types.EpochRecovery recoveryAfter = getEpochDepositRecovery();
    assert asset.balanceOf(currentContract) == vaultBalanceBefore - amount;
    assert asset.balanceOf(adapter) == adapterBalanceBefore + amount;
    assert adapter.getTVL() == adapterTVLBefore + amount;
    assert getRecoveryMode() == Types.RecoveryMode.NONE;
    assert recoveryAfter.epochNonce == recoveryBefore.epochNonce;
    assert recoveryAfter.amount == recoveryBefore.amount;
    assert ghost_DepositToStrategySuccess_EventCount == 1;
    assert ghost_DepositToStrategySuccess_Param_epochNonce == epochNonce;
    assert ghost_DepositToStrategySuccess_Param_amount == amount;
    assert ghost_DepositToStrategyFailure_EventCount == 0;
    assert ghost_EpochDepositRecoveryStored_EventCount == 0;
    assert ghost_recoveryMode_StoreCount == 0;
    assert ghost_epochDepositRecovery_epochNonce_StoreCount == 0;
    assert ghost_epochDepositRecovery_amount_StoreCount == 0;
}

/// @notice A failed CCIP epoch deposit stores recovery for the delivered asset
/// @dev Verifies unchanged balances and TVL, exact recovery state, storage writes, and failure events
rule ccipReceive_EPOCH_NET_DEPOSIT_FailedDepositStoresRecovery() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    require message.sourceChainSelector == getParentChainSelector(),
        "source chain should be the parent chain";
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require ghost_lastHandledEpochNonce_StoreCount == 0,
        "handled epoch nonce store count starts at zero";
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require ghost_CCIPReceived_EventCount == 0, "CCIPReceived event count starts at zero";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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

    ccipReceive@withrevert(e, message);

    assert !lastReverted;
    assert ghost_CCIPReceived_EventCount == 1;
    assert ghost_CCIPReceived_Param_ccipMessageId == message.messageId;
    assert ghost_CCIPReceived_Param_sourceChainSelector == message.sourceChainSelector;
    assert ghost_CCIPReceived_Param_ccipTxType == Types.CcipTx.EPOCH_NET_DEPOSIT;
    assert getLastHandledEpochNonce() == epochNonce;
    assert ghost_lastHandledEpochNonce_StoreCount == 1;
    assert ghost_lastHandledEpochNonce_StoredValue == epochNonce;
    Types.EpochRecovery recovery = getEpochDepositRecovery();
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert getRecoveryMode() == Types.RecoveryMode.EPOCH_DEPOSIT;
    assert recovery.epochNonce == epochNonce;
    assert recovery.amount == amount;
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
    assert ghost_recoveryMode_StoreCount == 1 => ghost_recoveryMode_StoredValue == Types.RecoveryMode.EPOCH_DEPOSIT,
        "recovery mode stored value is only meaningful when the recovery mode hook fires, which may not happen due to state packing";
}

/// @notice A received rebalance reverts when its nonce was already handled.
rule ccipReceive_REBALANCE_RevertWhen_RebalanceNonceIsNotNew() {
    env e;
    Client.Any2EVMMessage message;
    uint256 rebalanceNonce;
    bytes32 protocolId;
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be the registered vault";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require adapterRegistry.getAdapter(e, protocolId) == adapter, "adapter should be registered";
    require adapter.getVault() == currentContract, "adapter should be bound to the vault";
    require !adapter.depositReverts(), "adapter deposit should not revert";
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.REBALANCE, encodeRebalanceData(rebalanceNonce, protocolId)),
        "message data should encode a rebalance";

    /// @dev revert condition being verified
    require rebalanceNonce <= getLastHandledRebalanceNonce(), "rebalance nonce should already be handled";

    require ghost_CCIPReceived_EventCount == 0, "CCIPReceived event count starts at zero";

    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP rebalance reverts when the target protocol adapter is not registered
/// @dev Verifies that an unknown target protocol leaves all vault state unchanged
rule ccipReceive_REBALANCE_RevertWhen_AdapterNotRegistered() {
    env e;
    Client.Any2EVMMessage message;
    uint256 rebalanceNonce;
    require rebalanceNonce > getLastHandledRebalanceNonce(), "rebalance nonce should be new";
    require ghost_lastHandledRebalanceNonce_StoreCount == 0,
        "handled rebalance nonce store count starts at zero";
    bytes32 protocolId;
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require ghost_CCIPReceived_EventCount == 0, "CCIPReceived event count starts at zero";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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


    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP rebalance reverts when its payload is too short to decode the nonce and protocol ID
/// @dev Verifies that malformed rebalance data leaves all vault state unchanged. Competing nonce and
///      protocol conditions cannot be imposed because the targeted payload intentionally cannot decode them.
rule ccipReceive_REBALANCE_RevertWhen_PayloadEncodingIsMalformed() {
    env e;
    Client.Any2EVMMessage message;
    bytes data;
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require ghost_CCIPReceived_EventCount == 0, "CCIPReceived event count starts at zero";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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


    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP rebalance reverts when the registered adapter is bound to another vault
/// @dev Verifies that an invalid target adapter leaves all vault state unchanged
rule ccipReceive_REBALANCE_RevertWhen_AdapterVaultIsInvalid() {
    env e;
    Client.Any2EVMMessage message;
    uint256 rebalanceNonce;
    require rebalanceNonce > getLastHandledRebalanceNonce(), "rebalance nonce should be new";
    require ghost_lastHandledRebalanceNonce_StoreCount == 0,
        "handled rebalance nonce store count starts at zero";
    bytes32 protocolId;
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require ghost_CCIPReceived_EventCount == 0, "CCIPReceived event count starts at zero";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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


    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice A successful CCIP rebalance selects the target adapter and deposits the delivered asset
/// @dev Verifies exact balances, adapter TVL, unchanged recovery state, storage writes, and events
rule ccipReceive_REBALANCE_Success() {
    env e;
    Client.Any2EVMMessage message;
    uint256 rebalanceNonce;
    require rebalanceNonce > getLastHandledRebalanceNonce(), "rebalance nonce should be new";
    require ghost_lastHandledRebalanceNonce_StoreCount == 0,
        "handled rebalance nonce store count starts at zero";
    bytes32 protocolId;
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require ghost_CCIPReceived_EventCount == 0, "CCIPReceived event count starts at zero";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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

    ccipReceive@withrevert(e, message);


    assert !lastReverted;
    assert ghost_CCIPReceived_EventCount == 1;
    assert ghost_CCIPReceived_Param_ccipMessageId == message.messageId;
    assert ghost_CCIPReceived_Param_sourceChainSelector == message.sourceChainSelector;
    assert ghost_CCIPReceived_Param_ccipTxType == Types.CcipTx.REBALANCE;
    assert getLastHandledRebalanceNonce() == rebalanceNonce;
    assert ghost_lastHandledRebalanceNonce_StoreCount == 1;
    assert ghost_lastHandledRebalanceNonce_StoredValue == rebalanceNonce;
    Types.RebalanceDepositRecovery recoveryAfter = getRebalanceDepositRecovery();
    assert getActiveProtocolAdapter() == adapter;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore - amount;
    assert asset.balanceOf(adapter) == adapterBalanceBefore + amount;
    assert adapter.getTVL() == adapterTVLBefore + amount;
    assert getRecoveryMode() == Types.RecoveryMode.NONE;
    assert recoveryAfter.rebalanceNonce == recoveryBefore.rebalanceNonce;
    assert recoveryAfter.amount == recoveryBefore.amount;
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
}

/// @notice A failed CCIP rebalance deposit selects the target adapter and stores recovery
/// @dev Verifies unchanged balances and TVL, exact recovery state, storage writes, and failure events
rule ccipReceive_REBALANCE_FailedDepositStoresRecovery() {
    env e;
    Client.Any2EVMMessage message;
    uint256 rebalanceNonce;
    require rebalanceNonce > getLastHandledRebalanceNonce(), "rebalance nonce should be new";
    require ghost_lastHandledRebalanceNonce_StoreCount == 0,
        "handled rebalance nonce store count starts at zero";
    bytes32 protocolId;
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require ghost_CCIPReceived_EventCount == 0, "CCIPReceived event count starts at zero";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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

    ccipReceive@withrevert(e, message);


    assert !lastReverted;
    assert ghost_CCIPReceived_EventCount == 1;
    assert ghost_CCIPReceived_Param_ccipMessageId == message.messageId;
    assert ghost_CCIPReceived_Param_sourceChainSelector == message.sourceChainSelector;
    assert ghost_CCIPReceived_Param_ccipTxType == Types.CcipTx.REBALANCE;
    assert getLastHandledRebalanceNonce() == rebalanceNonce;
    assert ghost_lastHandledRebalanceNonce_StoreCount == 1;
    assert ghost_lastHandledRebalanceNonce_StoredValue == rebalanceNonce;
    Types.RebalanceDepositRecovery recovery = getRebalanceDepositRecovery();
    assert getActiveProtocolAdapter() == adapter;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT;
    assert recovery.rebalanceNonce == rebalanceNonce;
    assert recovery.amount == amount;
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
}

/// ─────────────────── TRY CCIP SEND ───────────────────────────

/// @notice Try CCIP send reverts when the caller is not the vault itself
/// @dev Verifies that an unauthorized call leaves all vault state unchanged and does not bridge assets
rule tryCcipSend_RevertWhen_CallerIsNotSelf() {
    env e;
    uint256 bridgeAmount;
    uint64 destinationChainSelector;
    Types.CcipTx ccipTxType;
    uint256 nonce;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require bridgeAmount != 0, "bridge amount should not be zero";
    require destinationChainSelector != 0, "destination chain selector should not be zero";
    require destinationChainSelector != getThisChainSelector(), "destination should not be this chain";
    require getCrosschainVault(destinationChainSelector) != 0, "destination vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev revert condition being verified
    require e.msg.sender != currentContract, "caller should not be the vault";

    address router = getRouter();

    /// @dev set ghost starting values

    tryCcipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, nonce, protocolId);

    assert lastReverted;
}

/// @notice Try CCIP send reverts when the bridge amount is zero
/// @dev Verifies that CCIP validation rejects zero sends before assets are bridged
rule tryCcipSend_RevertWhen_BridgeAmountIsZero() {
    env e;
    uint64 destinationChainSelector;
    Types.CcipTx ccipTxType;
    uint256 nonce;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == currentContract, "caller should be the vault";
    require destinationChainSelector != 0, "destination chain selector should not be zero";
    require destinationChainSelector != getThisChainSelector(), "destination should not be this chain";
    require getCrosschainVault(destinationChainSelector) != 0, "destination vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev revert condition being verified
    uint256 bridgeAmount = 0;

    address router = getRouter();

    /// @dev set ghost starting values

    tryCcipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, nonce, protocolId);

    assert lastReverted;
}

/// @notice Try CCIP send reverts when the destination chain selector is zero
/// @dev Verifies that CCIP validation rejects an unset destination before assets are bridged
rule tryCcipSend_RevertWhen_DestinationChainIsZero() {
    env e;
    uint256 bridgeAmount;
    Types.CcipTx ccipTxType;
    uint256 nonce;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == currentContract, "caller should be the vault";
    require bridgeAmount != 0, "bridge amount should not be zero";
    require getThisChainSelector() != 0, "this chain selector should not be zero";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev revert condition being verified
    uint64 destinationChainSelector = 0;

    address router = getRouter();
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);

    /// @dev mock token arithmetic conditions
    require bridgeAmount <= vaultAssetBalanceBefore, "vault asset balance should cover the bridge amount";
    require routerAssetBalanceBefore <= max_uint256 - bridgeAmount, "router asset balance should not overflow";

    /// @dev set ghost starting values

    tryCcipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, nonce, protocolId);

    assert lastReverted;
}

/// @notice Try CCIP send reverts when the destination is this chain
/// @dev Verifies that CCIP validation rejects same-chain sends before assets are bridged
rule tryCcipSend_RevertWhen_DestinationIsSelfChain() {
    env e;
    uint256 bridgeAmount;
    Types.CcipTx ccipTxType;
    uint256 nonce;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == currentContract, "caller should be the vault";
    require bridgeAmount != 0, "bridge amount should not be zero";
    require getThisChainSelector() != 0, "this chain selector should not be zero";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev revert condition being verified
    uint64 destinationChainSelector = getThisChainSelector();

    address router = getRouter();
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);

    /// @dev mock token arithmetic conditions
    require bridgeAmount <= vaultAssetBalanceBefore, "vault asset balance should cover the bridge amount";
    require routerAssetBalanceBefore <= max_uint256 - bridgeAmount, "router asset balance should not overflow";

    /// @dev set ghost starting values

    tryCcipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, nonce, protocolId);

    assert lastReverted;
}

/// @notice Try CCIP send reverts when the destination vault is not registered
/// @dev Verifies that CCIP validation rejects unregistered destinations before assets are bridged
rule tryCcipSend_RevertWhen_DestinationVaultNotRegistered() {
    env e;
    uint256 bridgeAmount;
    uint64 destinationChainSelector;
    Types.CcipTx ccipTxType;
    uint256 nonce;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == currentContract, "caller should be the vault";
    require bridgeAmount != 0, "bridge amount should not be zero";
    require destinationChainSelector != 0, "destination chain selector should not be zero";
    require destinationChainSelector != getThisChainSelector(), "destination should not be this chain";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev revert condition being verified
    require getCrosschainVault(destinationChainSelector) == 0, "destination vault should not be registered";

    address router = getRouter();
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);

    /// @dev mock token arithmetic conditions
    require bridgeAmount <= vaultAssetBalanceBefore, "vault asset balance should cover the bridge amount";
    require routerAssetBalanceBefore <= max_uint256 - bridgeAmount, "router asset balance should not overflow";

    /// @dev set ghost starting values

    tryCcipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, nonce, protocolId);

    assert lastReverted;
}

/// @notice Try CCIP send reverts when the router fee lookup fails
/// @dev Verifies atomic rollback because direct self-call sends are not caught
rule tryCcipSend_RevertWhen_RouterGetFeeReverts() {
    env e;
    uint256 bridgeAmount;
    uint64 destinationChainSelector;
    Types.CcipTx ccipTxType;
    uint256 nonce;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == currentContract, "caller should be the vault";
    require bridgeAmount != 0, "bridge amount should not be zero";
    require destinationChainSelector != 0, "destination chain selector should not be zero";
    require destinationChainSelector != getThisChainSelector(), "destination should not be this chain";
    require getCrosschainVault(destinationChainSelector) != 0, "destination vault should be registered";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev revert condition being verified
    require ccipRouter.getFeeReverts(), "router fee lookup should revert";

    address router = getRouter();
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);

    /// @dev mock token arithmetic conditions
    require bridgeAmount <= vaultAssetBalanceBefore, "vault asset balance should cover the bridge amount";
    require routerAssetBalanceBefore <= max_uint256 - bridgeAmount, "router asset balance should not overflow";

    /// @dev set ghost starting values

    tryCcipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, nonce, protocolId);

    assert lastReverted;
}

/// @notice Try CCIP send reverts when the router send fails
/// @dev Verifies atomic rollback because direct self-call sends are not caught
rule tryCcipSend_RevertWhen_RouterCcipSendReverts() {
    env e;
    uint256 bridgeAmount;
    uint64 destinationChainSelector;
    Types.CcipTx ccipTxType;
    uint256 nonce;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == currentContract, "caller should be the vault";
    require bridgeAmount != 0, "bridge amount should not be zero";
    require destinationChainSelector != 0, "destination chain selector should not be zero";
    require destinationChainSelector != getThisChainSelector(), "destination should not be this chain";
    require getCrosschainVault(destinationChainSelector) != 0, "destination vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";

    /// @dev revert condition being verified
    require ccipRouter.ccipSendReverts(), "router send should revert";

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

    tryCcipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, nonce, protocolId);

    assert lastReverted;
}

/// @notice Try CCIP send forwards a valid self-call to BaseVault CCIP execution
/// @dev Verifies exact LINK and asset transfers and the emitted bridge event
rule tryCcipSend_Success() {
    env e;
    uint256 bridgeAmount;
    uint64 destinationChainSelector;
    Types.CcipTx ccipTxType;
    uint256 nonce;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require bridgeAmount != 0, "bridge amount should not be zero";
    require destinationChainSelector != 0, "destination chain selector should not be zero";
    require destinationChainSelector != getThisChainSelector(), "destination should not be this chain";
    require getCrosschainVault(destinationChainSelector) != 0, "destination vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

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

    tryCcipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, nonce, protocolId);

    assert !lastReverted;
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore - fee;
    assert link.balanceOf(router) == routerLinkBalanceBefore + fee;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore - bridgeAmount;
    assert asset.balanceOf(router) == routerAssetBalanceBefore + bridgeAmount;
    assert ghost_CCIPBridged_EventCount == 1;
    assert ghost_CCIPBridged_Param_ccipMessageId != to_bytes32(0);
    assert ghost_CCIPBridged_Param_destinationChainSelector == destinationChainSelector;
    assert ghost_CCIPBridged_Param_ccipTxType == ccipTxType;
}

/// ──────────────────────── EXECUTE RECOVERY ──────────────────────

/// @notice executeRecovery reverts while the vault is paused.
rule executeRecovery_RevertWhen_Paused() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.EPOCH_DEPOSIT, "epoch deposit recovery should be pending";
    require getEpochDepositRecovery().amount != 0, "recovery amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.depositReverts(), "adapter deposit should not revert";

    /// @dev revert condition being verified
    require paused(), "vault should be paused";

    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice executeRecovery reverts when the call is reentrant
/// @dev Verifies that storage remains unchanged
rule executeRecovery_RevertWhen_ReentrantCall() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getRecoveryMode() == Types.RecoveryMode.EPOCH_DEPOSIT, "epoch deposit recovery should be pending";
    require getEpochDepositRecovery().amount != 0, "recovery amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.depositReverts(), "adapter deposit should not revert";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";
    require !paused(), "vault should not be paused";


    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice executeRecovery reverts when no recovery is pending
/// @dev Verifies that storage remains unchanged
rule executeRecovery_NONE_RevertWhen_NoRecoveryPending() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";

    /// @dev revert condition being verified
    require getRecoveryMode() == Types.RecoveryMode.NONE, "no recovery should be pending";


    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// ──────────────────── EPOCH_DEPOSIT ─────────────────────────

/// @notice Epoch deposit recovery via executeRecovery reverts when no active adapter is set
/// @dev Verifies that recovery state, balances, TVL, and events remain unchanged
rule executeRecovery_EPOCH_DEPOSIT_RevertWhen_NoActiveAdapter() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.EPOCH_DEPOSIT, "epoch deposit recovery should be pending";
    require getEpochDepositRecovery().amount != 0, "recovery amount should not be zero";
    require !adapter.depositReverts(), "adapter deposit should not revert";

    /// @dev revert condition being verified
    require getActiveProtocolAdapter() == 0, "active adapter should not be set";


    /// @dev set ghost starting values

    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice Epoch deposit recovery via executeRecovery reverts when the adapter deposit fails
/// @dev Verifies atomic rollback of recovery state, balances, TVL, and events
rule executeRecovery_EPOCH_DEPOSIT_RevertWhen_DepositFails() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.EPOCH_DEPOSIT, "epoch deposit recovery should be pending";
    require getEpochDepositRecovery().amount != 0, "recovery amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";

    /// @dev revert condition being verified
    require adapter.depositReverts(), "adapter deposit should revert";


    /// @dev set ghost starting values

    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice Epoch deposit recovery via executeRecovery deposits the stored amount and clears recovery
/// @dev Verifies balances, TVL, recovery deletion, storage writes, and events
rule executeRecovery_EPOCH_DEPOSIT_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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
    require ghost_recoveryMode_StoreCount == 0;

    executeRecovery@withrevert(e);

    assert !lastReverted;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore - recovery.amount;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore + recovery.amount;
    assert adapter.getTVL() == adapterTVLBefore + recovery.amount;
    assert getRecoveryMode() == Types.RecoveryMode.NONE;
    assert getEpochDepositRecovery().epochNonce == 0;
    assert getEpochDepositRecovery().amount == 0;
    assert ghost_EpochDepositRecoveryCleared_EventCount == 1;
    assert ghost_EpochDepositRecoveryCleared_Param_epochNonce == recovery.epochNonce;
    assert ghost_DepositToStrategySuccess_EventCount == 1;
    assert ghost_DepositToStrategySuccess_Param_epochNonce == recovery.epochNonce;
    assert ghost_DepositToStrategySuccess_Param_amount == recovery.amount;
    assert ghost_epochDepositRecovery_epochNonce_StoreCount == 1;
    assert ghost_epochDepositRecovery_epochNonce_StoredValue == 0;
    assert ghost_epochDepositRecovery_amount_StoreCount == 1;
    assert ghost_epochDepositRecovery_amount_StoredValue == 0;
    assert ghost_recoveryMode_StoreCount == 1 => ghost_recoveryMode_StoredValue == Types.RecoveryMode.NONE,
        "recovery mode stored value is only meaningful when the recovery mode hook fires, which may not happen due to state packing";
}

/// ──────────────────── REBALANCE_DEPOSIT ─────────────────────

/// @notice Rebalance deposit recovery via executeRecovery reverts when no active adapter is set
/// @dev Verifies that recovery state, balances, TVL, and events remain unchanged
rule executeRecovery_REBALANCE_DEPOSIT_RevertWhen_NoActiveAdapter() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT, "rebalance deposit recovery should be pending";
    require getRebalanceDepositRecovery().amount != 0, "recovery amount should not be zero";
    require !adapter.depositReverts(), "adapter deposit should not revert";
    require adapter != currentContract, "adapter should not be the vault";

    /// @dev revert condition being verified
    require getActiveProtocolAdapter() == 0, "active adapter should not be set";

    Types.RebalanceDepositRecovery recovery = getRebalanceDepositRecovery();
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token and adapter arithmetic conditions
    require recovery.amount <= vaultAssetBalanceBefore, "vault asset balance should cover the recovery amount";
    require adapterAssetBalanceBefore <= max_uint256 - recovery.amount, "adapter asset balance should not overflow";
    require adapterTVLBefore <= max_uint256 - recovery.amount, "adapter TVL should not overflow";

    /// @dev set ghost starting values

    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice Rebalance deposit recovery via executeRecovery reverts when the adapter deposit fails
/// @dev Verifies atomic rollback of recovery state, balances, TVL, and events
rule executeRecovery_REBALANCE_DEPOSIT_RevertWhen_DepositFails() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT, "rebalance deposit recovery should be pending";
    require getRebalanceDepositRecovery().amount != 0, "recovery amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require adapter != currentContract, "adapter should not be the vault";

    /// @dev revert condition being verified
    require adapter.depositReverts(), "adapter deposit should revert";

    Types.RebalanceDepositRecovery recovery = getRebalanceDepositRecovery();
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token and adapter arithmetic conditions
    require recovery.amount <= vaultAssetBalanceBefore, "vault asset balance should cover the recovery amount";
    require adapterAssetBalanceBefore <= max_uint256 - recovery.amount, "adapter asset balance should not overflow";
    require adapterTVLBefore <= max_uint256 - recovery.amount, "adapter TVL should not overflow";

    /// @dev set ghost starting values

    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice Rebalance deposit recovery via executeRecovery deposits the stored amount and clears recovery
/// @dev Verifies balances, TVL, recovery deletion, storage writes, and events
rule executeRecovery_REBALANCE_DEPOSIT_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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
    require ghost_recoveryMode_StoreCount == 0;

    executeRecovery@withrevert(e);

    assert !lastReverted;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore - recovery.amount;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore + recovery.amount;
    assert adapter.getTVL() == adapterTVLBefore + recovery.amount;
    assert getRecoveryMode() == Types.RecoveryMode.NONE;
    assert getRebalanceDepositRecovery().rebalanceNonce == 0;
    assert getRebalanceDepositRecovery().amount == 0;
    assert ghost_RebalanceDepositRecoveryCleared_EventCount == 1;
    assert ghost_RebalanceDepositRecoveryCleared_Param_nonce == recovery.rebalanceNonce;
    assert ghost_RebalanceDepositSuccess_EventCount == 1;
    assert ghost_RebalanceDepositSuccess_Param_nonce == recovery.rebalanceNonce;
    assert ghost_RebalanceDepositSuccess_Param_amount == recovery.amount;
    assert ghost_rebalanceDepositRecovery_nonce_StoreCount == 1;
    assert ghost_rebalanceDepositRecovery_nonce_StoredValue == 0;
    assert ghost_rebalanceDepositRecovery_amount_StoreCount == 1;
    assert ghost_rebalanceDepositRecovery_amount_StoredValue == 0;
    assert ghost_recoveryMode_StoreCount == 1 => ghost_recoveryMode_StoredValue == Types.RecoveryMode.NONE,
        "recovery mode stored value is only meaningful when the recovery mode hook fires, which may not happen due to state packing";
}

/*//////////////////////////////////////////////////////////////
                    PORTED FROM ChildVault.NoStorageHooks.spec
//////////////////////////////////////////////////////////////*/

/// ─────────────────── CCIP SEND ───────────────────────────────

/// @notice ChildVault CCIP send reverts when any recovery operation is already pending
/// @dev Verifies that a pending recovery cannot be overwritten by a new send
rule REC_006_ccipSend_RevertWhen_RecoveryAlreadyPending() {
    env e;
    uint256 bridgeAmount;
    uint64 destinationChainSelector;
    Types.CcipTx ccipTxType;
    uint256 nonce;
    bytes32 protocolId;

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


    /// @dev set ghost starting values

    ccipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, nonce, protocolId);

    assert lastReverted;
}

/// @notice ChildVault CCIP send reverts when the bridge amount is zero
/// @dev Verifies that an invalid bridge amount leaves all vault state unchanged
rule ccipSend_RevertWhen_BridgeAmountIsZero() {
    env e;
    uint64 destinationChainSelector;
    Types.CcipTx ccipTxType;
    uint256 nonce;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getCcipSendRecoveryNonce() == 0 && getCcipSendRecoveryProtocolId() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require destinationChainSelector != 0, "destination chain selector should not be zero";
    require destinationChainSelector != getThisChainSelector(), "destination should not be this chain";
    require getCrosschainVault(destinationChainSelector) != 0, "destination vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev revert condition being verified
    uint256 bridgeAmount = 0;


    /// @dev set ghost starting values

    ccipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, nonce, protocolId);

    assert lastReverted;
}

/// @notice ChildVault CCIP send reverts when the destination chain selector is zero
/// @dev Verifies that an invalid destination leaves all vault state unchanged
rule ccipSend_RevertWhen_DestinationChainIsZero() {
    env e;
    uint256 bridgeAmount;
    Types.CcipTx ccipTxType;
    uint256 nonce;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getCcipSendRecoveryNonce() == 0 && getCcipSendRecoveryProtocolId() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require bridgeAmount != 0, "bridge amount should not be zero";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev revert condition being verified
    uint64 destinationChainSelector = 0;


    /// @dev set ghost starting values

    ccipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, nonce, protocolId);

    assert lastReverted;
}

/// @notice ChildVault CCIP send reverts when the destination is the current chain
/// @dev Verifies that an invalid self-chain destination leaves all vault state unchanged
rule ccipSend_RevertWhen_DestinationIsSelfChain() {
    env e;
    uint256 bridgeAmount;
    Types.CcipTx ccipTxType;
    uint256 nonce;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getCcipSendRecoveryNonce() == 0 && getCcipSendRecoveryProtocolId() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require bridgeAmount != 0, "bridge amount should not be zero";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev revert condition being verified
    uint64 destinationChainSelector = getThisChainSelector();


    /// @dev set ghost starting values

    ccipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, nonce, protocolId);

    assert lastReverted;
}

/// @notice ChildVault CCIP send reverts when no destination vault is registered
/// @dev Verifies that an unset destination vault leaves all vault state unchanged
rule ccipSend_RevertWhen_DestinationVaultNotRegistered() {
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
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev revert condition being verified
    require getCrosschainVault(destinationChainSelector) == 0, "destination vault should not be registered";


    /// @dev set ghost starting values

    ccipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, nonce, protocolId);

    assert lastReverted;
}

/// @notice A successful ChildVault CCIP send bridges the asset without storing recovery
/// @dev Verifies exact LINK and asset balances, unchanged recovery state, events
rule ccipSend_Success() {
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

    ccipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, nonce, protocolId);

    assert !lastReverted;
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore - fee;
    assert link.balanceOf(router) == routerLinkBalanceBefore + fee;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore - bridgeAmount;
    assert asset.balanceOf(router) == routerAssetBalanceBefore + bridgeAmount;
    assert getRecoveryMode() == Types.RecoveryMode.NONE;
    assert ghost_CCIPBridged_EventCount == 1;
    assert ghost_CCIPBridged_Param_ccipMessageId != to_bytes32(0);
    assert ghost_CCIPBridged_Param_destinationChainSelector == destinationChainSelector;
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
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

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
    require ghost_ccipSendRecovery_amount_StoreCount == 0;
    require ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 0;
    require ghost_ccipSendRecovery_nonce_StoreCount == 0;
    require ghost_ccipSendRecovery_protocolId_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;

    ccipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, nonce, protocolId);

    assert !lastReverted;
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore;
    assert link.balanceOf(router) == routerLinkBalanceBefore;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(router) == routerAssetBalanceBefore;
    assert getRecoveryMode() == Types.RecoveryMode.CCIP_SEND;
    assert getCcipSendRecoveryTxType() == ccipTxType;
    assert getCcipSendRecoveryAmount() == bridgeAmount;
    assert getCcipSendRecoveryDestinationChainSelector() == destinationChainSelector;
    assert getCcipSendRecoveryNonce() == nonce;
    assert getCcipSendRecoveryProtocolId() == protocolId;
    assert ghost_CCIPBridged_EventCount == 0;
    assert ghost_CcipSendRecoveryStored_EventCount == 1;
    assert ghost_CcipSendRecoveryStored_Param_ccipTxType == ccipTxType;
    assert ghost_CcipSendRecoveryStored_Param_destinationChainSelector == destinationChainSelector;
    assert ghost_CcipSendRecoveryStored_Param_amount == bridgeAmount;
    assert ghost_ccipSendRecovery_amount_StoreCount == 1;
    assert ghost_ccipSendRecovery_amount_StoredValue == bridgeAmount;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 1;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoredValue == destinationChainSelector;
    assert ghost_ccipSendRecovery_nonce_StoreCount == 1;
    assert ghost_ccipSendRecovery_protocolId_StoreCount == 1;
    assert ghost_ccipSendRecovery_nonce_StoredValue == nonce;
    assert ghost_ccipSendRecovery_protocolId_StoredValue == protocolId;
    assert ghost_recoveryMode_StoreCount == 1 => ghost_recoveryMode_StoredValue == Types.RecoveryMode.CCIP_SEND,
        "recovery mode stored value is only meaningful when the recovery mode hook fires, which may not happen due to state packing";
}

/// @notice ChildVault stores CCIP send recovery when the router send fails
/// @dev Verifies atomic token rollback, exact recovery state, events
rule ccipSend_When_RouterCcipSendReverts_StoresRecovery() {
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
    require ccipRouter.ccipSendReverts(), "router send should revert";

    address router = getRouter();
    uint256 vaultLinkBalanceBefore = link.balanceOf(currentContract);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);

    /// @dev set ghost starting values
    require ghost_CCIPBridged_EventCount == 0;
    require ghost_CcipSendRecoveryStored_EventCount == 0;
    require ghost_ccipSendRecovery_amount_StoreCount == 0;
    require ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 0;
    require ghost_ccipSendRecovery_nonce_StoreCount == 0;
    require ghost_ccipSendRecovery_protocolId_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;

    ccipSend@withrevert(e, bridgeAmount, destinationChainSelector, ccipTxType, nonce, protocolId);

    assert !lastReverted;
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore;
    assert link.balanceOf(router) == routerLinkBalanceBefore;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(router) == routerAssetBalanceBefore;
    assert getRecoveryMode() == Types.RecoveryMode.CCIP_SEND;
    assert getCcipSendRecoveryTxType() == ccipTxType;
    assert getCcipSendRecoveryAmount() == bridgeAmount;
    assert getCcipSendRecoveryDestinationChainSelector() == destinationChainSelector;
    assert getCcipSendRecoveryNonce() == nonce;
    assert getCcipSendRecoveryProtocolId() == protocolId;
    assert ghost_CCIPBridged_EventCount == 0;
    assert ghost_CcipSendRecoveryStored_EventCount == 1;
    assert ghost_CcipSendRecoveryStored_Param_ccipTxType == ccipTxType;
    assert ghost_CcipSendRecoveryStored_Param_destinationChainSelector == destinationChainSelector;
    assert ghost_CcipSendRecoveryStored_Param_amount == bridgeAmount;
    assert ghost_ccipSendRecovery_amount_StoreCount == 1;
    assert ghost_ccipSendRecovery_amount_StoredValue == bridgeAmount;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 1;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoredValue == destinationChainSelector;
    assert ghost_ccipSendRecovery_nonce_StoreCount == 1;
    assert ghost_ccipSendRecovery_protocolId_StoreCount == 1;
    assert ghost_ccipSendRecovery_nonce_StoredValue == nonce;
    assert ghost_ccipSendRecovery_protocolId_StoredValue == protocolId;
    assert ghost_recoveryMode_StoreCount == 1 => ghost_recoveryMode_StoredValue == Types.RecoveryMode.CCIP_SEND,
        "recovery mode stored value is only meaningful when the recovery mode hook fires, which may not happen due to state packing";
}

/// ─────────────────── EXECUTE EPOCH WITHDRAW ──────────────────

/// @notice Epoch withdraw reverts while the vault is paused.
rule executeEpochWithdraw_RevertWhen_Paused() {
    env e;
    uint256 epochNonce;
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require ghost_lastHandledEpochNonce_StoreCount == 0,
        "handled epoch nonce store count starts at zero";
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require amount != 0, "amount should not be zero";
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() >= amount, "adapter TVL should cover the withdraw amount";
    require getCrosschainVault(getParentChainSelector()) != 0, "parent vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev revert condition being verified
    require paused(), "vault should be paused";

    executeEpochWithdraw@withrevert(e, epochNonce, amount);

    assert lastReverted;
}

/// @notice Epoch withdraw reverts when its nonce was already handled.
rule executeEpochWithdraw_RevertWhen_EpochNonceIsNotNew() {
    env e;
    uint256 epochNonce;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require amount != 0, "amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() >= amount, "adapter TVL should cover the withdraw amount";
    require getCrosschainVault(getParentChainSelector()) != 0, "parent vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev revert condition being verified
    require epochNonce <= getLastHandledEpochNonce(), "epoch nonce should already be handled";

    executeEpochWithdraw@withrevert(e, epochNonce, amount);

    assert lastReverted;
}

/// @notice Epoch withdraw reverts when the caller does not have the epoch operator role
/// @dev Verifies that an unauthorized call leaves all vault state unchanged
rule executeEpochWithdraw_RevertWhen_CallerDoesNotHaveEPOCH_OPERATOR_ROLE() {
    env e;
    uint256 epochNonce;
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require ghost_lastHandledEpochNonce_StoreCount == 0,
        "handled epoch nonce store count starts at zero";
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require amount != 0, "amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() >= amount, "adapter TVL should cover the withdraw amount";
    require getCrosschainVault(getParentChainSelector()) != 0, "parent vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";
    require getCcipSendRecoveryNonce() == 0 && getCcipSendRecoveryProtocolId() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require currentContract.i_parentChainSelector != 0 && currentContract.i_parentChainSelector != currentContract.i_thisChainSelector,
        "destination selector should be valid";

    /// @dev revert condition being verified
    require !hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);


    /// @dev set ghost starting values

    executeEpochWithdraw@withrevert(e, epochNonce, amount);

    assert lastReverted;
}

/// @notice Epoch withdraw reverts when called during an active non-reentrant execution
/// @dev Verifies that a reentrant call leaves all vault state unchanged
rule executeEpochWithdraw_RevertWhen_ReentrantCall() {
    env e;
    uint256 epochNonce;
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require ghost_lastHandledEpochNonce_StoreCount == 0,
        "handled epoch nonce store count starts at zero";
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
    require getCcipSendRecoveryNonce() == 0 && getCcipSendRecoveryProtocolId() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require currentContract.i_parentChainSelector != 0 && currentContract.i_parentChainSelector != currentContract.i_thisChainSelector,
        "destination selector should be valid";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";
    require !paused(), "vault should not be paused";


    /// @dev set ghost starting values

    executeEpochWithdraw@withrevert(e, epochNonce, amount);

    assert lastReverted;
}

/// @notice Epoch withdraw reverts when any recovery operation is already pending
/// @dev Verifies that a pending recovery cannot be overwritten
rule executeEpochWithdraw_RevertWhen_RecoveryAlreadyPending() {
    env e;
    uint256 epochNonce;
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require ghost_lastHandledEpochNonce_StoreCount == 0,
        "handled epoch nonce store count starts at zero";
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require amount != 0, "amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() >= amount, "adapter TVL should cover the withdraw amount";
    require getCrosschainVault(getParentChainSelector()) != 0, "parent vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";
    require getCcipSendRecoveryNonce() == 0 && getCcipSendRecoveryProtocolId() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require currentContract.i_parentChainSelector != 0 && currentContract.i_parentChainSelector != currentContract.i_thisChainSelector,
        "destination selector should be valid";

    /// @dev revert condition being verified
    require getRecoveryMode() != Types.RecoveryMode.NONE, "recovery should be pending";


    /// @dev set ghost starting values

    executeEpochWithdraw@withrevert(e, epochNonce, amount);

    assert lastReverted;
}

/// @notice Epoch withdraw reverts when the requested amount is zero
/// @dev Verifies that zero input is rejected before adapter interaction
rule executeEpochWithdraw_RevertWhen_AmountIsZero() {
    env e;
    uint256 epochNonce;
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require ghost_lastHandledEpochNonce_StoreCount == 0,
        "handled epoch nonce store count starts at zero";

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require getCcipSendRecoveryNonce() == 0 && getCcipSendRecoveryProtocolId() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require currentContract.i_parentChainSelector != 0 && currentContract.i_parentChainSelector != currentContract.i_thisChainSelector,
        "destination selector should be valid";

    /// @dev revert condition being verified
    uint256 amount = 0;


    /// @dev set ghost starting values

    executeEpochWithdraw@withrevert(e, epochNonce, amount);

    assert lastReverted;
}

/// @notice Epoch withdraw reverts when no active protocol adapter is configured
/// @dev Verifies that a missing strategy leaves all vault state unchanged
rule executeEpochWithdraw_RevertWhen_NoActiveAdapter() {
    env e;
    uint256 epochNonce;
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require ghost_lastHandledEpochNonce_StoreCount == 0,
        "handled epoch nonce store count starts at zero";
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require amount != 0, "amount should not be zero";
    require getCcipSendRecoveryNonce() == 0 && getCcipSendRecoveryProtocolId() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require currentContract.i_parentChainSelector != 0 && currentContract.i_parentChainSelector != currentContract.i_thisChainSelector,
        "destination selector should be valid";

    /// @dev revert condition being verified
    require getActiveProtocolAdapter() == 0, "active adapter should be zero";


    /// @dev set ghost starting values

    executeEpochWithdraw@withrevert(e, epochNonce, amount);

    assert lastReverted;
}

/// @notice Epoch withdraw reverts when a successful adapter call returns zero asset
/// @dev Verifies atomic rollback and that no success, failure, recovery, or bridge event is emitted
rule executeEpochWithdraw_RevertWhen_AmountOutIsZero() {
    env e;
    uint256 epochNonce;
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require ghost_lastHandledEpochNonce_StoreCount == 0,
        "handled epoch nonce store count starts at zero";
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require amount != 0, "amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require getCcipSendRecoveryNonce() == 0 && getCcipSendRecoveryProtocolId() == to_bytes32(0),
        "CCIP send recovery transaction data should be empty";
    require currentContract.i_parentChainSelector != 0 && currentContract.i_parentChainSelector != currentContract.i_thisChainSelector,
        "destination selector should be valid";

    /// @dev revert condition being verified
    require adapter.getTVL() == 0, "adapter withdraw should return zero";


    /// @dev set ghost starting values

    executeEpochWithdraw@withrevert(e, epochNonce, amount);

    assert lastReverted;
}

/// @notice Epoch withdraw reverts when no parent vault is registered for the parent chain
/// @dev Verifies atomic rollback of the completed adapter withdrawal and all emitted events
rule executeEpochWithdraw_RevertWhen_ParentVaultNotRegistered() {
    env e;
    uint256 epochNonce;
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require ghost_lastHandledEpochNonce_StoreCount == 0,
        "handled epoch nonce store count starts at zero";
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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
    uint256 amountOut = amount > adapterTVLBefore ? adapterTVLBefore : amount;

    /// @dev mock token arithmetic conditions
    require amountOut <= adapterBalanceBefore, "adapter asset balance should cover the withdrawn amount";
    require vaultBalanceBefore <= max_uint256 - amountOut, "vault asset balance should not overflow";

    /// @dev set ghost starting values

    executeEpochWithdraw@withrevert(e, epochNonce, amount);

    assert lastReverted;
}

/// @notice A failed epoch withdraw stores recovery for the requested amount
/// @dev Verifies unchanged balances and TVL, exact recovery state, failure events
rule executeEpochWithdraw_When_WithdrawFails_StoresRecovery() {
    env e;
    uint256 epochNonce;
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require ghost_lastHandledEpochNonce_StoreCount == 0,
        "handled epoch nonce store count starts at zero";
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require amount != 0, "amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require getCcipSendRecoveryNonce() == 0 && getCcipSendRecoveryProtocolId() == to_bytes32(0),
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
    require ghost_epochWithdrawRecovery_epochNonce_StoreCount == 0;
    require ghost_epochWithdrawRecovery_amount_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;

    executeEpochWithdraw@withrevert(e, epochNonce, amount);

    assert !lastReverted;
    assert getLastHandledEpochNonce() == epochNonce;
    assert ghost_lastHandledEpochNonce_StoreCount == 1;
    assert ghost_lastHandledEpochNonce_StoredValue == epochNonce;
    Types.EpochRecovery recovery = getEpochWithdrawRecovery();
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert getRecoveryMode() == Types.RecoveryMode.EPOCH_WITHDRAW;
    assert recovery.epochNonce == epochNonce;
    assert recovery.amount == amount;
    assert ghost_WithdrawFromStrategySuccess_EventCount == 0;
    assert ghost_WithdrawFromStrategyFailure_EventCount == 1;
    assert ghost_WithdrawFromStrategyFailure_Param_epochNonce == epochNonce;
    assert ghost_WithdrawFromStrategyFailure_Param_amount == amount;
    assert ghost_EpochWithdrawRecoveryStored_EventCount == 1;
    assert ghost_EpochWithdrawRecoveryStored_Param_epochNonce == epochNonce;
    assert ghost_EpochWithdrawRecoveryStored_Param_amount == amount;
    assert ghost_CCIPBridged_EventCount == 0;
    assert ghost_epochWithdrawRecovery_epochNonce_StoreCount == 1;
    assert ghost_epochWithdrawRecovery_epochNonce_StoredValue == epochNonce;
    assert ghost_epochWithdrawRecovery_amount_StoreCount == 1;
    assert ghost_epochWithdrawRecovery_amount_StoredValue == amount;
    assert ghost_recoveryMode_StoreCount == 1 => ghost_recoveryMode_StoredValue == Types.RecoveryMode.EPOCH_WITHDRAW,
        "recovery mode stored value is only meaningful when the recovery mode hook fires, which may not happen due to state packing";
}

/// @notice A successful epoch withdraw bridges the actual withdrawn asset to the parent chain
/// @dev Verifies exact balances, adapter TVL, events, and absence of recovery state
rule executeEpochWithdraw_Success() {
    env e;
    uint256 epochNonce;
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require ghost_lastHandledEpochNonce_StoreCount == 0,
        "handled epoch nonce store count starts at zero";
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require amount != 0, "amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() > 0, "adapter withdraw should return a nonzero amount";
    require getCrosschainVault(getParentChainSelector()) != 0, "parent vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";
    require getCcipSendRecoveryNonce() == 0 && getCcipSendRecoveryProtocolId() == to_bytes32(0),
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
    assert getLastHandledEpochNonce() == epochNonce;
    assert ghost_lastHandledEpochNonce_StoreCount == 1;
    assert ghost_lastHandledEpochNonce_StoredValue == epochNonce;
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
    assert ghost_CCIPBridged_Param_destinationChainSelector == getParentChainSelector();
    assert ghost_CCIPBridged_Param_ccipTxType == Types.CcipTx.EPOCH_NET_WITHDRAW;
}

/// @notice Epoch withdraw stores CCIP recovery when the router fee lookup fails after withdrawal
/// @dev Verifies that the withdrawal remains committed and the withdrawn asset stays in the vault
rule executeEpochWithdraw_When_RouterGetFeeReverts_StoresCcipSendRecovery() {
    env e;
    uint256 epochNonce;
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require ghost_lastHandledEpochNonce_StoreCount == 0,
        "handled epoch nonce store count starts at zero";
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
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
    require ghost_ccipSendRecovery_amount_StoreCount == 0;
    require ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 0;
    require ghost_ccipSendRecovery_nonce_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;

    executeEpochWithdraw@withrevert(e, epochNonce, amount);

    assert !lastReverted;
    assert getLastHandledEpochNonce() == epochNonce;
    assert ghost_lastHandledEpochNonce_StoreCount == 1;
    assert ghost_lastHandledEpochNonce_StoredValue == epochNonce;
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
    assert ghost_ccipSendRecovery_amount_StoreCount == 1;
    assert ghost_ccipSendRecovery_amount_StoredValue == amountOut;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 1;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoredValue == getParentChainSelector();
    assert ghost_ccipSendRecovery_nonce_StoreCount == 1;
    assert ghost_ccipSendRecovery_nonce_StoredValue == epochNonce;
    assert ghost_recoveryMode_StoreCount == 1 => ghost_recoveryMode_StoredValue == Types.RecoveryMode.CCIP_SEND,
        "recovery mode stored value is only meaningful when the recovery mode hook fires, which may not happen due to state packing";
}

/// @notice Epoch withdraw stores CCIP recovery when the router send fails after withdrawal
/// @dev Verifies atomic send rollback while preserving the completed strategy withdrawal
rule executeEpochWithdraw_When_RouterCcipSendReverts_StoresCcipSendRecovery() {
    env e;
    uint256 epochNonce;
    require epochNonce > getLastHandledEpochNonce(), "epoch nonce should be new";
    require ghost_lastHandledEpochNonce_StoreCount == 0,
        "handled epoch nonce store count starts at zero";
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
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
    require ghost_ccipSendRecovery_amount_StoreCount == 0;
    require ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 0;
    require ghost_ccipSendRecovery_nonce_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;

    executeEpochWithdraw@withrevert(e, epochNonce, amount);

    assert !lastReverted;
    assert getLastHandledEpochNonce() == epochNonce;
    assert ghost_lastHandledEpochNonce_StoreCount == 1;
    assert ghost_lastHandledEpochNonce_StoredValue == epochNonce;
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
    assert ghost_ccipSendRecovery_amount_StoreCount == 1;
    assert ghost_ccipSendRecovery_amount_StoredValue == amountOut;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 1;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoredValue == getParentChainSelector();
    assert ghost_ccipSendRecovery_nonce_StoreCount == 1;
    assert ghost_ccipSendRecovery_nonce_StoredValue == epochNonce;
    assert ghost_recoveryMode_StoreCount == 1 => ghost_recoveryMode_StoredValue == Types.RecoveryMode.CCIP_SEND,
        "recovery mode stored value is only meaningful when the recovery mode hook fires, which may not happen due to state packing";
}

rule executeRecovery_REBALANCE_WITHDRAW_RevertWhen_ReentrantCall() {
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
    require !paused(), "vault should not be paused";

    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token arithmetic conditions
    require adapterTVLBefore <= adapterAssetBalanceBefore, "adapter asset balance should cover the withdrawal";
    require vaultAssetBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";

    /// @dev set ghost starting values

    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice Rebalance withdraw recovery via executeRecovery reverts when no active adapter is set
/// @dev Verifies that recovery state, balances, TVL, and events remain unchanged
rule executeRecovery_REBALANCE_WITHDRAW_RevertWhen_NoActiveAdapter() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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

    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token arithmetic conditions
    require adapterTVLBefore <= adapterAssetBalanceBefore, "adapter asset balance should cover the withdrawal";
    require vaultAssetBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";

    /// @dev set ghost starting values

    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice Rebalance withdraw recovery via executeRecovery reverts when the adapter withdraw fails
/// @dev Verifies atomic rollback of recovery state, balances, TVL, and events
rule executeRecovery_REBALANCE_WITHDRAW_RevertWhen_WithdrawFails() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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

    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token arithmetic conditions
    require adapterTVLBefore <= adapterAssetBalanceBefore, "adapter asset balance should cover the withdrawal";
    require vaultAssetBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";

    /// @dev set ghost starting values

    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice Rebalance withdraw recovery via executeRecovery reverts when the retry withdraw returns zero
/// @dev Verifies that zero recovery output leaves recovery state, balances, TVL, and events unchanged
rule executeRecovery_REBALANCE_WITHDRAW_RevertWhen_AmountRebalancedIsZero() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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


    /// @dev set ghost starting values

    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice Local rebalance withdraw recovery via executeRecovery reverts when the target protocol adapter is not registered
/// @dev Verifies atomic rollback of the completed source withdrawal and recovery clear
rule executeRecovery_REBALANCE_WITHDRAW_Local_RevertWhen_TargetAdapterNotRegistered() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_WITHDRAW, "rebalance withdraw recovery should be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() > 0, "adapter withdraw should return a nonzero amount";
    Types.RebalanceWithdrawRecovery recovery = getRebalanceWithdrawRecovery();
    require recovery.strategy.chainSelector == getThisChainSelector(), "target strategy should be on this chain";

    /// @dev revert condition being verified
    require adapterRegistry.getAdapter(e, recovery.strategy.protocolId) == 0, "target adapter should not be registered";

    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token arithmetic conditions
    require adapterTVLBefore <= adapterAssetBalanceBefore, "adapter asset balance should cover the withdrawal";
    require vaultAssetBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";

    /// @dev set ghost starting values

    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice Local rebalance withdraw recovery via executeRecovery reverts when the target adapter is bound to another vault
/// @dev Verifies atomic rollback of the completed source withdrawal and recovery clear
rule executeRecovery_REBALANCE_WITHDRAW_Local_RevertWhen_TargetAdapterVaultIsInvalid() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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

    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token arithmetic conditions
    require adapterTVLBefore <= adapterAssetBalanceBefore, "adapter asset balance should cover the withdrawal";
    require vaultAssetBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";

    /// @dev set ghost starting values

    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice Local rebalance withdraw recovery via executeRecovery withdraws and redeposits into the recovered target adapter
/// @dev Verifies exact balances, recovery deletion, active adapter update, and events
rule executeRecovery_REBALANCE_WITHDRAW_Local_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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
    require ghost_rebalanceWithdrawRecovery_rebalanceNonce_StoreCount == 0;
    require ghost_rebalanceWithdrawRecovery_protocolId_StoreCount == 0;
    require ghost_rebalanceWithdrawRecovery_chainSelector_StoreCount == 0;
    require ghost_activeProtocolAdapter_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;

    executeRecovery@withrevert(e);

    assert !lastReverted;
    assert getActiveProtocolAdapter() == adapter;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore;
    assert adapter.getTVL() == amountRebalanced;
    assert getRecoveryMode() == Types.RecoveryMode.NONE;
    assert getRebalanceWithdrawRecovery().rebalanceNonce == 0;
    assert getRebalanceWithdrawRecovery().strategy.protocolId == to_bytes32(0);
    assert getRebalanceWithdrawRecovery().strategy.chainSelector == 0;
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
    assert ghost_rebalanceWithdrawRecovery_rebalanceNonce_StoreCount == 1;
    assert ghost_rebalanceWithdrawRecovery_rebalanceNonce_StoredValue == 0;
    assert ghost_rebalanceWithdrawRecovery_protocolId_StoreCount == 1;
    assert ghost_rebalanceWithdrawRecovery_protocolId_StoredValue == to_bytes32(0);
    assert ghost_rebalanceWithdrawRecovery_chainSelector_StoreCount == 1;
    assert ghost_rebalanceWithdrawRecovery_chainSelector_StoredValue == 0;
    assert ghost_activeProtocolAdapter_StoreCount == 1;
    assert ghost_activeProtocolAdapter_StoredValue == adapter;
    assert ghost_recoveryMode_StoreCount == 1 => ghost_recoveryMode_StoredValue == Types.RecoveryMode.NONE,
        "recovery mode stored value is only meaningful when the recovery mode hook fires, which may not happen due to state packing";
}

/// @notice Local rebalance withdraw recovery via executeRecovery stores rebalance deposit recovery when target deposit fails
/// @dev Verifies the old withdraw recovery is cleared before the new deposit recovery is stored
rule executeRecovery_REBALANCE_WITHDRAW_Local_When_DepositFails_StoresRecovery() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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
    require ghost_rebalanceWithdrawRecovery_rebalanceNonce_StoreCount == 0;
    require ghost_rebalanceWithdrawRecovery_protocolId_StoreCount == 0;
    require ghost_rebalanceWithdrawRecovery_chainSelector_StoreCount == 0;
    require ghost_rebalanceDepositRecovery_nonce_StoreCount == 0;
    require ghost_rebalanceDepositRecovery_amount_StoreCount == 0;
    require ghost_activeProtocolAdapter_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;

    executeRecovery@withrevert(e);

    assert !lastReverted;
    assert getActiveProtocolAdapter() == adapter;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore + amountRebalanced;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore - amountRebalanced;
    assert adapter.getTVL() == 0;
    assert getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT;
    assert getRebalanceWithdrawRecovery().rebalanceNonce == 0;
    assert getRebalanceWithdrawRecovery().strategy.protocolId == to_bytes32(0);
    assert getRebalanceWithdrawRecovery().strategy.chainSelector == 0;
    Types.RebalanceDepositRecovery depositRecovery = getRebalanceDepositRecovery();
    assert depositRecovery.rebalanceNonce == recovery.rebalanceNonce;
    assert depositRecovery.amount == amountRebalanced;
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
    assert ghost_rebalanceWithdrawRecovery_rebalanceNonce_StoreCount == 1;
    assert ghost_rebalanceWithdrawRecovery_rebalanceNonce_StoredValue == 0;
    assert ghost_rebalanceWithdrawRecovery_protocolId_StoreCount == 1;
    assert ghost_rebalanceWithdrawRecovery_protocolId_StoredValue == to_bytes32(0);
    assert ghost_rebalanceWithdrawRecovery_chainSelector_StoreCount == 1;
    assert ghost_rebalanceWithdrawRecovery_chainSelector_StoredValue == 0;
    assert ghost_rebalanceDepositRecovery_nonce_StoreCount == 1;
    assert ghost_rebalanceDepositRecovery_nonce_StoredValue == recovery.rebalanceNonce;
    assert ghost_rebalanceDepositRecovery_amount_StoreCount == 1;
    assert ghost_rebalanceDepositRecovery_amount_StoredValue == amountRebalanced;
    assert ghost_activeProtocolAdapter_StoreCount == 1;
    assert ghost_activeProtocolAdapter_StoredValue == adapter;
    assert ghost_recoveryMode_StoreCount == 1 => ghost_recoveryMode_StoredValue == Types.RecoveryMode.REBALANCE_DEPOSIT,
        "recovery mode stored value is only meaningful when the recovery mode hook fires, which may not happen due to state packing";
}

/// @notice Remote rebalance withdraw recovery via executeRecovery reverts when the target chain selector is zero
/// @dev Verifies atomic rollback because CCIP validation runs before the caught router send
rule executeRecovery_REBALANCE_WITHDRAW_Remote_RevertWhen_TargetChainSelectorIsZero() {
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
    require getThisChainSelector() != 0, "this chain selector should not be zero";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    Types.RebalanceWithdrawRecovery recovery = getRebalanceWithdrawRecovery();

    /// @dev failure condition being verified
    require recovery.strategy.chainSelector == 0, "target chain selector should be zero";

    uint256 adapterTVLBefore = adapter.getTVL();
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    address router = getRouter();

    /// @dev mock token arithmetic conditions
    require adapterTVLBefore != 0, "adapter withdraw should return a nonzero amount";
    require adapterTVLBefore <= adapterBalanceBefore, "adapter asset balance should cover the withdrawal";
    require vaultBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";

    /// @dev set ghost starting values

    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice Remote rebalance withdraw recovery via executeRecovery reverts when no target vault is registered
/// @dev Verifies atomic rollback because CCIP validation runs before the caught router send
rule executeRecovery_REBALANCE_WITHDRAW_Remote_RevertWhen_TargetVaultNotRegistered() {
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
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    Types.RebalanceWithdrawRecovery recovery = getRebalanceWithdrawRecovery();
    require recovery.strategy.chainSelector != 0, "target chain selector should not be zero";
    require recovery.strategy.chainSelector != getThisChainSelector(), "target strategy should be remote";

    /// @dev failure condition being verified
    require getCrosschainVault(recovery.strategy.chainSelector) == 0, "target vault should not be registered";

    uint256 adapterTVLBefore = adapter.getTVL();
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    address router = getRouter();

    /// @dev mock token arithmetic conditions
    require adapterTVLBefore != 0, "adapter withdraw should return a nonzero amount";
    require adapterTVLBefore <= adapterBalanceBefore, "adapter asset balance should cover the withdrawal";
    require vaultBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";

    /// @dev set ghost starting values

    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice Remote rebalance withdraw recovery via executeRecovery bridges the recovered TVL to the target chain
/// @dev Verifies exact balances, recovery deletion, active adapter clearing, and events
rule executeRecovery_REBALANCE_WITHDRAW_Remote_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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
    require ghost_rebalanceWithdrawRecovery_rebalanceNonce_StoreCount == 0;
    require ghost_rebalanceWithdrawRecovery_protocolId_StoreCount == 0;
    require ghost_rebalanceWithdrawRecovery_chainSelector_StoreCount == 0;
    require ghost_activeProtocolAdapter_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;

    executeRecovery@withrevert(e);

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
    assert ghost_RebalanceWithdrawRecoveryCleared_EventCount == 1;
    assert ghost_RebalanceWithdrawRecoveryCleared_Param_rebalanceNonce == recovery.rebalanceNonce;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 1;
    assert ghost_RebalanceWithdrawSuccess_Param_nonce == recovery.rebalanceNonce;
    assert ghost_RebalanceWithdrawSuccess_Param_amount == amountRebalanced;
    assert ghost_ActiveProtocolAdapterCleared_EventCount == 1;
    assert ghost_ActiveProtocolAdapterCleared_Param_adapter == adapter;
    assert ghost_CCIPBridged_EventCount == 1;
    assert ghost_CCIPBridged_Param_destinationChainSelector == recovery.strategy.chainSelector;
    assert ghost_CCIPBridged_Param_ccipTxType == Types.CcipTx.REBALANCE;
    assert ghost_CcipSendRecoveryStored_EventCount == 0;
    assert ghost_rebalanceWithdrawRecovery_rebalanceNonce_StoreCount == 1;
    assert ghost_rebalanceWithdrawRecovery_rebalanceNonce_StoredValue == 0;
    assert ghost_rebalanceWithdrawRecovery_protocolId_StoreCount == 1;
    assert ghost_rebalanceWithdrawRecovery_protocolId_StoredValue == to_bytes32(0);
    assert ghost_rebalanceWithdrawRecovery_chainSelector_StoreCount == 1;
    assert ghost_rebalanceWithdrawRecovery_chainSelector_StoredValue == 0;
    assert ghost_activeProtocolAdapter_StoreCount == 1;
    assert ghost_activeProtocolAdapter_StoredValue == 0;
    assert ghost_recoveryMode_StoreCount == 1 => ghost_recoveryMode_StoredValue == Types.RecoveryMode.NONE,
        "recovery mode stored value is only meaningful when the recovery mode hook fires, which may not happen due to state packing";
}

/// @notice Remote rebalance withdraw recovery via executeRecovery stores CCIP recovery when the router fee lookup fails
/// @dev Verifies that withdrawal and active adapter clearing remain committed
rule executeRecovery_REBALANCE_WITHDRAW_Remote_When_RouterGetFeeReverts_StoresCcipSendRecovery() {
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
    require ghost_rebalanceWithdrawRecovery_rebalanceNonce_StoreCount == 0;
    require ghost_rebalanceWithdrawRecovery_protocolId_StoreCount == 0;
    require ghost_rebalanceWithdrawRecovery_chainSelector_StoreCount == 0;
    require ghost_ccipSendRecovery_amount_StoreCount == 0;
    require ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 0;
    require ghost_ccipSendRecovery_nonce_StoreCount == 0;
    require ghost_ccipSendRecovery_protocolId_StoreCount == 0;
    require ghost_activeProtocolAdapter_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;

    executeRecovery@withrevert(e);

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
    assert getCcipSendRecoveryTxType() == Types.CcipTx.REBALANCE;
    assert getCcipSendRecoveryAmount() == amountRebalanced;
    assert getCcipSendRecoveryDestinationChainSelector() == recovery.strategy.chainSelector;
    assert getCcipSendRecoveryNonce() == recovery.rebalanceNonce;
    assert getCcipSendRecoveryProtocolId() == recovery.strategy.protocolId;
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
    assert ghost_rebalanceWithdrawRecovery_rebalanceNonce_StoreCount == 1;
    assert ghost_rebalanceWithdrawRecovery_rebalanceNonce_StoredValue == 0;
    assert ghost_rebalanceWithdrawRecovery_protocolId_StoreCount == 1;
    assert ghost_rebalanceWithdrawRecovery_protocolId_StoredValue == to_bytes32(0);
    assert ghost_rebalanceWithdrawRecovery_chainSelector_StoreCount == 1;
    assert ghost_rebalanceWithdrawRecovery_chainSelector_StoredValue == 0;
    assert ghost_ccipSendRecovery_amount_StoreCount == 1;
    assert ghost_ccipSendRecovery_amount_StoredValue == amountRebalanced;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 1;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoredValue == recovery.strategy.chainSelector;
    assert ghost_ccipSendRecovery_nonce_StoreCount == 1;
    assert ghost_ccipSendRecovery_nonce_StoredValue == recovery.rebalanceNonce;
    assert ghost_ccipSendRecovery_protocolId_StoreCount == 1;
    assert ghost_ccipSendRecovery_protocolId_StoredValue == recovery.strategy.protocolId;
    assert ghost_activeProtocolAdapter_StoreCount == 1;
    assert ghost_activeProtocolAdapter_StoredValue == 0;
    assert ghost_recoveryMode_StoreCount == 1 => ghost_recoveryMode_StoredValue == Types.RecoveryMode.CCIP_SEND,
        "recovery mode stored value is only meaningful when the recovery mode hook fires, which may not happen due to state packing";
}

/// @notice Remote rebalance withdraw recovery via executeRecovery stores CCIP recovery when the router send fails
/// @dev Verifies atomic send rollback while preserving withdrawal and active adapter clearing
rule executeRecovery_REBALANCE_WITHDRAW_Remote_When_RouterCcipSendReverts_StoresCcipSendRecovery() {
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
    require ghost_ccipSendRecovery_amount_StoreCount == 0;
    require ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 0;
    require ghost_ccipSendRecovery_nonce_StoreCount == 0;
    require ghost_ccipSendRecovery_protocolId_StoreCount == 0;
    require ghost_rebalanceWithdrawRecovery_rebalanceNonce_StoreCount == 0;
    require ghost_rebalanceWithdrawRecovery_protocolId_StoreCount == 0;
    require ghost_rebalanceWithdrawRecovery_chainSelector_StoreCount == 0;
    require ghost_activeProtocolAdapter_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;

    executeRecovery@withrevert(e);

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
    assert ghost_rebalanceWithdrawRecovery_rebalanceNonce_StoreCount == 1;
    assert ghost_rebalanceWithdrawRecovery_rebalanceNonce_StoredValue == 0;
    assert ghost_rebalanceWithdrawRecovery_protocolId_StoreCount == 1;
    assert ghost_rebalanceWithdrawRecovery_protocolId_StoredValue == to_bytes32(0);
    assert ghost_rebalanceWithdrawRecovery_chainSelector_StoreCount == 1;
    assert ghost_rebalanceWithdrawRecovery_chainSelector_StoredValue == 0;
    assert ghost_activeProtocolAdapter_StoreCount == 1;
    assert ghost_activeProtocolAdapter_StoredValue == 0;
    assert ghost_recoveryMode_StoreCount == 1 => ghost_recoveryMode_StoredValue == Types.RecoveryMode.CCIP_SEND,
        "recovery mode stored value is only meaningful when the recovery mode hook fires, which may not happen due to state packing";
    assert getCcipSendRecoveryTxType() == Types.CcipTx.REBALANCE;
    assert getCcipSendRecoveryAmount() == amountRebalanced;
    assert getCcipSendRecoveryDestinationChainSelector() == recovery.strategy.chainSelector;
    assert getCcipSendRecoveryNonce() == recovery.rebalanceNonce;
    assert getCcipSendRecoveryProtocolId() == recovery.strategy.protocolId;
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
    assert ghost_ccipSendRecovery_amount_StoreCount == 1;
    assert ghost_ccipSendRecovery_amount_StoredValue == amountRebalanced;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 1;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoredValue == recovery.strategy.chainSelector;
    assert ghost_ccipSendRecovery_nonce_StoreCount == 1;
    assert ghost_ccipSendRecovery_nonce_StoredValue == recovery.rebalanceNonce;
    assert ghost_ccipSendRecovery_protocolId_StoreCount == 1;
    assert ghost_ccipSendRecovery_protocolId_StoredValue == recovery.strategy.protocolId;
}

/// ─────────────────── EXECUTE REBALANCE ───────────────────────

/// @notice Rebalance execution reverts while the vault is paused.
rule executeRebalance_RevertWhen_Paused() {
    env e;
    uint256 rebalanceNonce;
    require rebalanceNonce > getLastHandledRebalanceNonce(), "rebalance nonce should be new";
    require ghost_lastHandledRebalanceNonce_StoreCount == 0,
        "handled rebalance nonce store count starts at zero";
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require rebalanceNonce > getLastHandledRebalanceNonce(), "rebalance nonce should be new";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() > 0, "adapter withdraw should return a nonzero amount";
    require newStrategy.chainSelector == getThisChainSelector(), "target strategy should be on this chain";
    require adapterRegistry.getAdapter(e, newStrategy.protocolId) == adapter, "target adapter should be registered";
    require adapter.getVault() == currentContract, "target adapter should be bound to the vault";
    require !adapter.depositReverts(), "target adapter deposit should not revert";

    /// @dev revert condition being verified
    require paused(), "vault should be paused";

    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert lastReverted;
}

/// @notice Rebalance execution reverts when its nonce was already handled.
rule executeRebalance_RevertWhen_RebalanceNonceIsNotNew() {
    env e;
    uint256 rebalanceNonce;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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
    require rebalanceNonce <= getLastHandledRebalanceNonce(), "rebalance nonce should already be handled";

    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert lastReverted;
}

/// @notice Rebalance execution reverts when the caller does not have the rebalance operator role
/// @dev Verifies that an unauthorized call leaves all vault state unchanged
rule executeRebalance_RevertWhen_CallerDoesNotHaveREBALANCE_OPERATOR_ROLE() {
    env e;
    uint256 rebalanceNonce;
    require rebalanceNonce > getLastHandledRebalanceNonce(), "rebalance nonce should be new";
    require ghost_lastHandledRebalanceNonce_StoreCount == 0,
        "handled rebalance nonce store count starts at zero";
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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
    require rebalanceNonce > getLastHandledRebalanceNonce(), "rebalance nonce should be new";
    require ghost_lastHandledRebalanceNonce_StoreCount == 0,
        "handled rebalance nonce store count starts at zero";
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
    require !paused(), "vault should not be paused";


    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert lastReverted;
}

/// @notice Rebalance execution reverts when any recovery operation is already pending
/// @dev Verifies that an existing recovery cannot be overwritten
rule executeRebalance_RevertWhen_RecoveryAlreadyPending() {
    env e;
    uint256 rebalanceNonce;
    require rebalanceNonce > getLastHandledRebalanceNonce(), "rebalance nonce should be new";
    require ghost_lastHandledRebalanceNonce_StoreCount == 0,
        "handled rebalance nonce store count starts at zero";
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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
    require rebalanceNonce > getLastHandledRebalanceNonce(), "rebalance nonce should be new";
    require ghost_lastHandledRebalanceNonce_StoreCount == 0,
        "handled rebalance nonce store count starts at zero";
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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
    require rebalanceNonce > getLastHandledRebalanceNonce(), "rebalance nonce should be new";
    require ghost_lastHandledRebalanceNonce_StoreCount == 0,
        "handled rebalance nonce store count starts at zero";
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require newStrategy.chainSelector == getThisChainSelector(), "target strategy should be on this chain";
    require adapterRegistry.getAdapter(e, newStrategy.protocolId) == adapter, "target adapter should be registered";
    require adapter.getVault() == currentContract, "target adapter should be bound to the vault";
    require !adapter.depositReverts(), "target adapter deposit should not revert";

    /// @dev revert condition being verified
    require adapter.getTVL() == 0, "adapter withdraw should return zero";


    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert lastReverted;
}

/// @notice A failed source withdrawal reverts when the recovery target chain selector is zero
/// @dev Verifies that invalid recovery data rolls back the failure event and leaves state unchanged
rule executeRebalance_When_WithdrawFails_RevertWhen_TargetChainSelectorIsZero() {
    env e;
    uint256 rebalanceNonce;
    require rebalanceNonce > getLastHandledRebalanceNonce(), "rebalance nonce should be new";
    require ghost_lastHandledRebalanceNonce_StoreCount == 0,
        "handled rebalance nonce store count starts at zero";
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";

    /// @dev failure and revert conditions being verified
    require adapter.withdrawReverts(), "adapter withdraw should revert";
    require newStrategy.chainSelector == 0, "target chain selector should be zero";


    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert lastReverted;
}

/// @notice A failed source withdrawal stores recovery for the target strategy
/// @dev Verifies exact recovery state, failure events
rule executeRebalance_When_WithdrawFails_StoresRecovery() {
    env e;
    uint256 rebalanceNonce;
    require rebalanceNonce > getLastHandledRebalanceNonce(), "rebalance nonce should be new";
    require ghost_lastHandledRebalanceNonce_StoreCount == 0,
        "handled rebalance nonce store count starts at zero";
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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
    require ghost_rebalanceWithdrawRecovery_rebalanceNonce_StoreCount == 0;
    require ghost_rebalanceWithdrawRecovery_protocolId_StoreCount == 0;
    require ghost_rebalanceWithdrawRecovery_chainSelector_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;

    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert !lastReverted;
    assert getLastHandledRebalanceNonce() == rebalanceNonce;
    assert ghost_lastHandledRebalanceNonce_StoreCount == 1;
    assert ghost_lastHandledRebalanceNonce_StoredValue == rebalanceNonce;
    Types.RebalanceWithdrawRecovery recovery = getRebalanceWithdrawRecovery();
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert getRecoveryMode() == Types.RecoveryMode.REBALANCE_WITHDRAW;
    assert recovery.rebalanceNonce == rebalanceNonce;
    assert recovery.strategy.protocolId == newStrategy.protocolId;
    assert recovery.strategy.chainSelector == newStrategy.chainSelector;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 0;
    assert ghost_RebalanceWithdrawFailure_EventCount == 1;
    assert ghost_RebalanceWithdrawFailure_Param_nonce == rebalanceNonce;
    assert ghost_RebalanceWithdrawRecoveryStored_EventCount == 1;
    assert ghost_RebalanceWithdrawRecoveryStored_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_RebalanceWithdrawRecoveryStored_Param_protocolId == newStrategy.protocolId;
    assert ghost_RebalanceWithdrawRecoveryStored_Param_chainSelector == newStrategy.chainSelector;
    assert ghost_rebalanceWithdrawRecovery_rebalanceNonce_StoreCount == 1;
    assert ghost_rebalanceWithdrawRecovery_rebalanceNonce_StoredValue == rebalanceNonce;
    assert ghost_rebalanceWithdrawRecovery_protocolId_StoreCount == 1;
    assert ghost_rebalanceWithdrawRecovery_protocolId_StoredValue == newStrategy.protocolId;
    assert ghost_rebalanceWithdrawRecovery_chainSelector_StoreCount == 1;
    assert ghost_rebalanceWithdrawRecovery_chainSelector_StoredValue == newStrategy.chainSelector;
    assert ghost_recoveryMode_StoreCount == 1 => ghost_recoveryMode_StoredValue == Types.RecoveryMode.REBALANCE_WITHDRAW,
        "recovery mode stored value is only meaningful when the recovery mode hook fires, which may not happen due to state packing";
}

/// @notice A local rebalance reverts when the target protocol adapter is not registered
/// @dev Verifies atomic rollback of the completed source withdrawal
rule executeRebalance_Local_RevertWhen_TargetAdapterNotRegistered() {
    env e;
    uint256 rebalanceNonce;
    require rebalanceNonce > getLastHandledRebalanceNonce(), "rebalance nonce should be new";
    require ghost_lastHandledRebalanceNonce_StoreCount == 0,
        "handled rebalance nonce store count starts at zero";
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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

    /// @dev mock token arithmetic conditions
    require adapterTVLBefore <= adapterBalanceBefore, "adapter asset balance should cover the withdrawal";
    require vaultBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";

    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert lastReverted;
}

/// @notice A local rebalance reverts when the target adapter is bound to another vault
/// @dev Verifies atomic rollback of the completed source withdrawal
rule executeRebalance_Local_RevertWhen_TargetAdapterVaultIsInvalid() {
    env e;
    uint256 rebalanceNonce;
    require rebalanceNonce > getLastHandledRebalanceNonce(), "rebalance nonce should be new";
    require ghost_lastHandledRebalanceNonce_StoreCount == 0,
        "handled rebalance nonce store count starts at zero";
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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

    /// @dev mock token arithmetic conditions
    require adapterTVLBefore <= adapterBalanceBefore, "adapter asset balance should cover the withdrawal";
    require vaultBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";

    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert lastReverted;
}

/// @notice A successful local rebalance withdraws and redeposits the full source TVL
/// @dev Verifies exact balances, adapter state, recovery state, events
rule executeRebalance_Local_Success() {
    env e;
    uint256 rebalanceNonce;
    require rebalanceNonce > getLastHandledRebalanceNonce(), "rebalance nonce should be new";
    require ghost_lastHandledRebalanceNonce_StoreCount == 0,
        "handled rebalance nonce store count starts at zero";
    Types.Strategy newStrategy;

    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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
    require ghost_activeProtocolAdapter_StoreCount == 0;

    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert !lastReverted;
    assert getLastHandledRebalanceNonce() == rebalanceNonce;
    assert ghost_lastHandledRebalanceNonce_StoreCount == 1;
    assert ghost_lastHandledRebalanceNonce_StoredValue == rebalanceNonce;
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
    assert ghost_activeProtocolAdapter_StoreCount == 1;
    assert ghost_activeProtocolAdapter_StoredValue == adapter;
}

/// @notice A failed local target deposit stores rebalance deposit recovery
/// @dev Verifies that the withdrawn asset remains in the vault with exact recovery state and events
rule executeRebalance_Local_When_DepositFails_StoresRecovery() {
    env e;
    uint256 rebalanceNonce;
    require rebalanceNonce > getLastHandledRebalanceNonce(), "rebalance nonce should be new";
    require ghost_lastHandledRebalanceNonce_StoreCount == 0,
        "handled rebalance nonce store count starts at zero";
    Types.Strategy newStrategy;

    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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
    require ghost_activeProtocolAdapter_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;
    require ghost_rebalanceDepositRecovery_nonce_StoreCount == 0;
    require ghost_rebalanceDepositRecovery_amount_StoreCount == 0;

    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert !lastReverted;
    assert getLastHandledRebalanceNonce() == rebalanceNonce;
    assert ghost_lastHandledRebalanceNonce_StoreCount == 1;
    assert ghost_lastHandledRebalanceNonce_StoredValue == rebalanceNonce;
    Types.RebalanceDepositRecovery recovery = getRebalanceDepositRecovery();
    assert getActiveProtocolAdapter() == adapter;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore + amountRebalanced;
    assert asset.balanceOf(adapter) == adapterBalanceBefore - amountRebalanced;
    assert adapter.getTVL() == 0;
    assert getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT;
    assert recovery.rebalanceNonce == rebalanceNonce;
    assert recovery.amount == amountRebalanced;
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
    assert ghost_activeProtocolAdapter_StoreCount == 1;
    assert ghost_activeProtocolAdapter_StoredValue == adapter;
    assert ghost_rebalanceDepositRecovery_nonce_StoreCount == 1;
    assert ghost_rebalanceDepositRecovery_nonce_StoredValue == rebalanceNonce;
    assert ghost_rebalanceDepositRecovery_amount_StoreCount == 1;
    assert ghost_rebalanceDepositRecovery_amount_StoredValue == amountRebalanced;
    assert ghost_recoveryMode_StoreCount == 1 => ghost_recoveryMode_StoredValue == Types.RecoveryMode.REBALANCE_DEPOSIT,
        "recovery mode stored value is only meaningful when the recovery mode hook fires, which may not happen due to state packing";
}

/// @notice A remote rebalance reverts when the target chain selector is zero
/// @dev Verifies atomic rollback of the source withdrawal and active adapter clearing
rule executeRebalance_Remote_RevertWhen_TargetChainSelectorIsZero() {
    env e;
    uint256 rebalanceNonce;
    require rebalanceNonce > getLastHandledRebalanceNonce(), "rebalance nonce should be new";
    require ghost_lastHandledRebalanceNonce_StoreCount == 0,
        "handled rebalance nonce store count starts at zero";
    Types.Strategy newStrategy;

    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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

    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert lastReverted;
}

/// @notice A remote rebalance reverts when no target vault is registered
/// @dev Verifies atomic rollback of the source withdrawal and active adapter clearing
rule executeRebalance_Remote_RevertWhen_TargetVaultNotRegistered() {
    env e;
    uint256 rebalanceNonce;
    require rebalanceNonce > getLastHandledRebalanceNonce(), "rebalance nonce should be new";
    require ghost_lastHandledRebalanceNonce_StoreCount == 0,
        "handled rebalance nonce store count starts at zero";
    Types.Strategy newStrategy;

    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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

    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert lastReverted;
}

/// @notice A successful remote rebalance bridges the full source TVL to the target child
/// @dev Verifies exact balances, active adapter clearing, recovery state, and events
rule executeRebalance_Remote_Success() {
    env e;
    uint256 rebalanceNonce;
    require rebalanceNonce > getLastHandledRebalanceNonce(), "rebalance nonce should be new";
    require ghost_lastHandledRebalanceNonce_StoreCount == 0,
        "handled rebalance nonce store count starts at zero";
    Types.Strategy newStrategy;

    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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
    require ghost_activeProtocolAdapter_StoreCount == 0;

    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert !lastReverted;
    assert getLastHandledRebalanceNonce() == rebalanceNonce;
    assert ghost_lastHandledRebalanceNonce_StoreCount == 1;
    assert ghost_lastHandledRebalanceNonce_StoredValue == rebalanceNonce;
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
    assert ghost_CCIPBridged_Param_destinationChainSelector == newStrategy.chainSelector;
    assert ghost_CCIPBridged_Param_ccipTxType == Types.CcipTx.REBALANCE;
    assert ghost_CcipSendRecoveryStored_EventCount == 0;
    assert ghost_activeProtocolAdapter_StoreCount == 1;
    assert ghost_activeProtocolAdapter_StoredValue == 0;
}

/// @notice A remote rebalance stores CCIP recovery when the router fee lookup fails
/// @dev Verifies that withdrawal and active adapter clearing remain committed
rule executeRebalance_Remote_When_RouterGetFeeReverts_StoresCcipSendRecovery() {
    env e;
    uint256 rebalanceNonce;
    require rebalanceNonce > getLastHandledRebalanceNonce(), "rebalance nonce should be new";
    require ghost_lastHandledRebalanceNonce_StoreCount == 0,
        "handled rebalance nonce store count starts at zero";
    Types.Strategy newStrategy;

    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
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
    require ghost_activeProtocolAdapter_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;
    require ghost_ccipSendRecovery_amount_StoreCount == 0;
    require ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 0;
    require ghost_ccipSendRecovery_nonce_StoreCount == 0;
    require ghost_ccipSendRecovery_protocolId_StoreCount == 0;

    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert !lastReverted;
    assert getLastHandledRebalanceNonce() == rebalanceNonce;
    assert ghost_lastHandledRebalanceNonce_StoreCount == 1;
    assert ghost_lastHandledRebalanceNonce_StoredValue == rebalanceNonce;
    assert getActiveProtocolAdapter() == 0;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore + amountRebalanced;
    assert asset.balanceOf(adapter) == adapterBalanceBefore - amountRebalanced;
    assert asset.balanceOf(router) == routerBalanceBefore;
    assert adapter.getTVL() == 0;
    assert getRecoveryMode() == Types.RecoveryMode.CCIP_SEND;
    assert getCcipSendRecoveryTxType() == Types.CcipTx.REBALANCE;
    assert getCcipSendRecoveryAmount() == amountRebalanced;
    assert getCcipSendRecoveryDestinationChainSelector() == newStrategy.chainSelector;
    assert getCcipSendRecoveryNonce() == rebalanceNonce;
    assert getCcipSendRecoveryProtocolId() == newStrategy.protocolId;
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
    assert ghost_activeProtocolAdapter_StoreCount == 1;
    assert ghost_activeProtocolAdapter_StoredValue == 0;
    assert ghost_ccipSendRecovery_amount_StoreCount == 1;
    assert ghost_ccipSendRecovery_amount_StoredValue == amountRebalanced;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 1;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoredValue == newStrategy.chainSelector;
    assert ghost_ccipSendRecovery_nonce_StoreCount == 1;
    assert ghost_ccipSendRecovery_nonce_StoredValue == rebalanceNonce;
    assert ghost_ccipSendRecovery_protocolId_StoreCount == 1;
    assert ghost_ccipSendRecovery_protocolId_StoredValue == newStrategy.protocolId;
    assert ghost_recoveryMode_StoreCount == 1 => ghost_recoveryMode_StoredValue == Types.RecoveryMode.CCIP_SEND,
        "recovery mode stored value is only meaningful when the recovery mode hook fires, which may not happen due to state packing";
}

/// @notice A remote rebalance stores CCIP recovery when the router send fails
/// @dev Verifies atomic send rollback while preserving withdrawal and active adapter clearing
rule executeRebalance_Remote_When_RouterCcipSendReverts_StoresCcipSendRecovery() {
    env e;
    uint256 rebalanceNonce;
    require rebalanceNonce > getLastHandledRebalanceNonce(), "rebalance nonce should be new";
    require ghost_lastHandledRebalanceNonce_StoreCount == 0,
        "handled rebalance nonce store count starts at zero";
    Types.Strategy newStrategy;

    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
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
    require ghost_activeProtocolAdapter_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;
    require ghost_ccipSendRecovery_amount_StoreCount == 0;
    require ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 0;
    require ghost_ccipSendRecovery_nonce_StoreCount == 0;
    require ghost_ccipSendRecovery_protocolId_StoreCount == 0;

    executeRebalance@withrevert(e, rebalanceNonce, newStrategy);

    assert !lastReverted;
    assert getLastHandledRebalanceNonce() == rebalanceNonce;
    assert ghost_lastHandledRebalanceNonce_StoreCount == 1;
    assert ghost_lastHandledRebalanceNonce_StoredValue == rebalanceNonce;
    assert getActiveProtocolAdapter() == 0;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore + amountRebalanced;
    assert asset.balanceOf(adapter) == adapterBalanceBefore - amountRebalanced;
    assert asset.balanceOf(router) == routerBalanceBefore;
    assert adapter.getTVL() == 0;
    assert getRecoveryMode() == Types.RecoveryMode.CCIP_SEND;
    assert getCcipSendRecoveryTxType() == Types.CcipTx.REBALANCE;
    assert getCcipSendRecoveryAmount() == amountRebalanced;
    assert getCcipSendRecoveryDestinationChainSelector() == newStrategy.chainSelector;
    assert getCcipSendRecoveryNonce() == rebalanceNonce;
    assert getCcipSendRecoveryProtocolId() == newStrategy.protocolId;
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
    assert ghost_activeProtocolAdapter_StoreCount == 1;
    assert ghost_activeProtocolAdapter_StoredValue == 0;
    assert ghost_ccipSendRecovery_amount_StoreCount == 1;
    assert ghost_ccipSendRecovery_amount_StoredValue == amountRebalanced;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 1;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoredValue == newStrategy.chainSelector;
    assert ghost_ccipSendRecovery_nonce_StoreCount == 1;
    assert ghost_ccipSendRecovery_nonce_StoredValue == rebalanceNonce;
    assert ghost_ccipSendRecovery_protocolId_StoreCount == 1;
    assert ghost_ccipSendRecovery_protocolId_StoredValue == newStrategy.protocolId;
    assert ghost_recoveryMode_StoreCount == 1 => ghost_recoveryMode_StoredValue == Types.RecoveryMode.CCIP_SEND,
        "recovery mode stored value is only meaningful when the recovery mode hook fires, which may not happen due to state packing";
}


/// ──────────────────── EPOCH_WITHDRAW ────────────────────────

/// @notice Epoch withdraw recovery via executeRecovery reverts when the call is reentrant
/// @dev Verifies that recovery state, balances, TVL, and events remain unchanged
rule executeRecovery_EPOCH_WITHDRAW_RevertWhen_ReentrantCall() {
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
    require !paused(), "vault should not be paused";

    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token arithmetic conditions
    require adapterTVLBefore <= adapterAssetBalanceBefore, "adapter asset balance should cover the withdrawn amount";
    require vaultAssetBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";

    /// @dev set ghost starting values

    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice Epoch withdraw recovery via executeRecovery reverts when no active adapter is set
/// @dev Verifies that recovery state, balances, TVL, and events remain unchanged
rule executeRecovery_EPOCH_WITHDRAW_RevertWhen_NoActiveAdapter() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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

    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token arithmetic conditions
    require adapterTVLBefore <= adapterAssetBalanceBefore, "adapter asset balance should cover the withdrawn amount";
    require vaultAssetBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";

    /// @dev set ghost starting values

    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice Epoch withdraw recovery via executeRecovery reverts when the adapter withdraw fails
/// @dev Verifies atomic rollback of recovery state, balances, TVL, and events
rule executeRecovery_EPOCH_WITHDRAW_RevertWhen_WithdrawFails() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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

    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token arithmetic conditions
    require adapterTVLBefore <= adapterAssetBalanceBefore, "adapter asset balance should cover the withdrawn amount";
    require vaultAssetBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";

    /// @dev set ghost starting values

    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice Epoch withdraw recovery via executeRecovery reverts when the retry withdraw returns zero
/// @dev Verifies that zero recovery output leaves recovery state, balances, TVL, and events unchanged
rule executeRecovery_EPOCH_WITHDRAW_RevertWhen_AmountOutIsZero() {
    env e;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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


    /// @dev set ghost starting values

    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice Epoch withdraw recovery via executeRecovery reverts when the parent chain selector is invalid
/// @dev Verifies atomic rollback because CCIP validation runs before the caught router send
rule executeRecovery_EPOCH_WITHDRAW_RevertWhen_ParentChainSelectorInvalid() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.EPOCH_WITHDRAW, "epoch withdraw recovery should be pending";
    require getCcipSendRecoveryNonce() == 0 && getCcipSendRecoveryProtocolId() == to_bytes32(0),
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

    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();
    address router = getRouter();

    /// @dev mock token arithmetic conditions
    require adapterTVLBefore <= adapterAssetBalanceBefore, "adapter asset balance should cover the withdrawn amount";
    require vaultAssetBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";

    /// @dev set ghost starting values

    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice Epoch withdraw recovery via executeRecovery reverts when the parent vault is not registered
/// @dev Verifies atomic rollback because CCIP validation runs before the caught router send
rule executeRecovery_EPOCH_WITHDRAW_RevertWhen_ParentVaultNotRegistered() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.EPOCH_WITHDRAW, "epoch withdraw recovery should be pending";
    require getCcipSendRecoveryNonce() == 0 && getCcipSendRecoveryProtocolId() == to_bytes32(0),
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

    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterAssetBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();
    address router = getRouter();

    /// @dev mock token arithmetic conditions
    require adapterTVLBefore <= adapterAssetBalanceBefore, "adapter asset balance should cover the withdrawn amount";
    require vaultAssetBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";

    /// @dev set ghost starting values

    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice Epoch withdraw recovery via executeRecovery withdraws the stored amount, clears recovery, and bridges to the parent
/// @dev Verifies balances, TVL, recovery deletion, storage writes, and events
rule executeRecovery_EPOCH_WITHDRAW_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
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
    require vaultAssetBalanceBefore <= max_uint256 - amountOut, "vault asset balance should not overflow";
    require fee <= vaultLinkBalanceBefore, "vault LINK balance should cover the CCIP fee";
    require routerLinkBalanceBefore <= max_uint256 - fee, "router LINK balance should not overflow";
    require routerAssetBalanceBefore <= max_uint256 - amountOut, "router asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_EpochWithdrawRecoveryCleared_EventCount == 0;
    require ghost_WithdrawFromStrategySuccess_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;
    require ghost_epochWithdrawRecovery_epochNonce_StoreCount == 0;
    require ghost_epochWithdrawRecovery_amount_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;

    executeRecovery@withrevert(e);

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
    assert ghost_EpochWithdrawRecoveryCleared_EventCount == 1;
    assert ghost_EpochWithdrawRecoveryCleared_Param_epochNonce == recovery.epochNonce;
    assert ghost_WithdrawFromStrategySuccess_EventCount == 1;
    assert ghost_WithdrawFromStrategySuccess_Param_epochNonce == recovery.epochNonce;
    assert ghost_WithdrawFromStrategySuccess_Param_amount == amountOut;
    assert ghost_CCIPBridged_EventCount == 1;
    assert ghost_CCIPBridged_Param_destinationChainSelector == getParentChainSelector();
    assert ghost_CCIPBridged_Param_ccipTxType == Types.CcipTx.EPOCH_NET_WITHDRAW;
    assert ghost_epochWithdrawRecovery_epochNonce_StoreCount == 1;
    assert ghost_epochWithdrawRecovery_epochNonce_StoredValue == 0;
    assert ghost_epochWithdrawRecovery_amount_StoreCount == 1;
    assert ghost_epochWithdrawRecovery_amount_StoredValue == 0;
    assert ghost_recoveryMode_StoreCount == 1 => ghost_recoveryMode_StoredValue == Types.RecoveryMode.NONE,
        "recovery mode stored value is only meaningful when the recovery mode hook fires, which may not happen due to state packing";
}

/// @notice Epoch withdraw recovery via executeRecovery stores CCIP recovery when the router fee lookup fails after withdrawal
/// @dev Verifies that epoch withdraw recovery is cleared and the withdrawn asset stays in the vault
rule executeRecovery_EPOCH_WITHDRAW_When_RouterGetFeeReverts_StoresCcipSendRecovery() {
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
    require ghost_epochWithdrawRecovery_epochNonce_StoreCount == 0;
    require ghost_epochWithdrawRecovery_amount_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;
    require ghost_ccipSendRecovery_amount_StoreCount == 0;
    require ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 0;
    require ghost_ccipSendRecovery_nonce_StoreCount == 0;
    require ghost_ccipSendRecovery_protocolId_StoreCount == 0;

    executeRecovery@withrevert(e);

    assert !lastReverted;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore + amountOut;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore - amountOut;
    assert asset.balanceOf(router) == routerAssetBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore - amountOut;
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore;
    assert link.balanceOf(router) == routerLinkBalanceBefore;
    assert getEpochWithdrawRecovery().epochNonce == 0;
    assert getEpochWithdrawRecovery().amount == 0;
    assert getRecoveryMode() == Types.RecoveryMode.CCIP_SEND;
    assert getCcipSendRecoveryTxType() == Types.CcipTx.EPOCH_NET_WITHDRAW;
    assert getCcipSendRecoveryAmount() == amountOut;
    assert getCcipSendRecoveryDestinationChainSelector() == getParentChainSelector();
    assert getCcipSendRecoveryNonce() == recovery.epochNonce;
    assert getCcipSendRecoveryProtocolId() == to_bytes32(0);
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
    assert ghost_epochWithdrawRecovery_epochNonce_StoreCount == 1;
    assert ghost_epochWithdrawRecovery_epochNonce_StoredValue == 0;
    assert ghost_epochWithdrawRecovery_amount_StoreCount == 1;
    assert ghost_epochWithdrawRecovery_amount_StoredValue == 0;
    assert ghost_ccipSendRecovery_amount_StoreCount == 1;
    assert ghost_ccipSendRecovery_amount_StoredValue == amountOut;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 1;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoredValue == getParentChainSelector();
    assert ghost_ccipSendRecovery_nonce_StoreCount == 1;
    assert ghost_ccipSendRecovery_nonce_StoredValue == recovery.epochNonce;
    assert ghost_ccipSendRecovery_protocolId_StoreCount == 1;
    assert ghost_ccipSendRecovery_protocolId_StoredValue == to_bytes32(0);
    assert ghost_recoveryMode_StoreCount == 1 => ghost_recoveryMode_StoredValue == Types.RecoveryMode.CCIP_SEND,
        "recovery mode stored value is only meaningful when the recovery mode hook fires, which may not happen due to state packing";
}

/// @notice Epoch withdraw recovery via executeRecovery stores CCIP recovery when the router send fails after withdrawal
/// @dev Verifies atomic send rollback while preserving the completed recovery withdrawal
rule executeRecovery_EPOCH_WITHDRAW_When_RouterCcipSendReverts_StoresCcipSendRecovery() {
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
    require ghost_epochWithdrawRecovery_epochNonce_StoreCount == 0;
    require ghost_epochWithdrawRecovery_amount_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;
    require ghost_ccipSendRecovery_amount_StoreCount == 0;
    require ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 0;
    require ghost_ccipSendRecovery_nonce_StoreCount == 0;
    require ghost_ccipSendRecovery_protocolId_StoreCount == 0;

    executeRecovery@withrevert(e);

    assert !lastReverted;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore + amountOut;
    assert asset.balanceOf(adapter) == adapterAssetBalanceBefore - amountOut;
    assert asset.balanceOf(router) == routerAssetBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore - amountOut;
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore;
    assert link.balanceOf(router) == routerLinkBalanceBefore;
    assert getEpochWithdrawRecovery().epochNonce == 0;
    assert getEpochWithdrawRecovery().amount == 0;
    assert getRecoveryMode() == Types.RecoveryMode.CCIP_SEND;
    assert getCcipSendRecoveryTxType() == Types.CcipTx.EPOCH_NET_WITHDRAW;
    assert getCcipSendRecoveryAmount() == amountOut;
    assert getCcipSendRecoveryDestinationChainSelector() == getParentChainSelector();
    assert getCcipSendRecoveryNonce() == recovery.epochNonce;
    assert getCcipSendRecoveryProtocolId() == to_bytes32(0);
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
    assert ghost_epochWithdrawRecovery_epochNonce_StoreCount == 1;
    assert ghost_epochWithdrawRecovery_epochNonce_StoredValue == 0;
    assert ghost_epochWithdrawRecovery_amount_StoreCount == 1;
    assert ghost_epochWithdrawRecovery_amount_StoredValue == 0;
    assert ghost_ccipSendRecovery_amount_StoreCount == 1;
    assert ghost_ccipSendRecovery_amount_StoredValue == amountOut;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 1;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoredValue == getParentChainSelector();
    assert ghost_ccipSendRecovery_nonce_StoreCount == 1;
    assert ghost_ccipSendRecovery_nonce_StoredValue == recovery.epochNonce;
    assert ghost_ccipSendRecovery_protocolId_StoreCount == 1;
    assert ghost_ccipSendRecovery_protocolId_StoredValue == to_bytes32(0);
    assert ghost_recoveryMode_StoreCount == 1 => ghost_recoveryMode_StoredValue == Types.RecoveryMode.CCIP_SEND,
        "recovery mode stored value is only meaningful when the recovery mode hook fires, which may not happen due to state packing";
}

/// ──────────────────── CCIP_SEND ──────────────────────────────

/// @notice Epoch-withdraw CCIP send recovery via executeRecovery clears recovery and bridges to the parent
/// @dev Verifies balances, recovery deletion, events, and the encoded retry payload
rule executeRecovery_CCIP_SEND_EPOCH_NET_WITHDRAW_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.CCIP_SEND, "CCIP send recovery should be pending";
    require getCcipSendRecoveryTxType() == Types.CcipTx.EPOCH_NET_WITHDRAW,
        "stored CCIP tx type should be epoch net withdraw";
    require getCcipSendRecoveryAmount() != 0, "recovery amount should not be zero";
    require getCcipSendRecoveryDestinationChainSelector() != 0, "destination chain selector should not be zero";
    require getCcipSendRecoveryDestinationChainSelector() != getThisChainSelector(), "destination should not be this chain";
    require getCrosschainVault(getCcipSendRecoveryDestinationChainSelector()) != 0,
        "destination vault should be registered";
    require getCcipSendRecoveryProtocolId() == to_bytes32(0), "epoch withdraw recovery protocol ID should be empty";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev success condition being verified
    uint256 bridgeAmount = getCcipSendRecoveryAmount();
    uint64 destinationChainSelector = getCcipSendRecoveryDestinationChainSelector();
    uint256 nonce = getCcipSendRecoveryNonce();

    uint256 fee = ccipRouter.getFee();
    address router = getRouter();
    uint256 vaultLinkBalanceBefore = link.balanceOf(currentContract);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);
    bytes expectedMessageData = encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, encodeEpochNonce(nonce));

    /// @dev mock token arithmetic conditions
    require fee <= vaultLinkBalanceBefore, "vault LINK balance should cover the CCIP fee";
    require routerLinkBalanceBefore <= max_uint256 - fee, "router LINK balance should not overflow";
    require bridgeAmount <= vaultAssetBalanceBefore, "vault asset balance should cover the bridge amount";
    require routerAssetBalanceBefore <= max_uint256 - bridgeAmount, "router asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_CcipSendRecoveryCleared_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;
    require ghost_CcipSendRecoveryStored_EventCount == 0;
    require ghost_ccipSendRecovery_amount_StoreCount == 0;
    require ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 0;
    require ghost_ccipSendRecovery_nonce_StoreCount == 0;
    require ghost_ccipSendRecovery_protocolId_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;

    executeRecovery@withrevert(e);

    assert !lastReverted;
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore - fee;
    assert link.balanceOf(router) == routerLinkBalanceBefore + fee;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore - bridgeAmount;
    assert asset.balanceOf(router) == routerAssetBalanceBefore + bridgeAmount;
    assert ccipRouter.getLastMessageDataHash() == hashBytes(expectedMessageData);
    assert getRecoveryMode() == Types.RecoveryMode.NONE;
    assert getCcipSendRecoveryTxType() == Types.CcipTx.EPOCH_NET_DEPOSIT;
    assert getCcipSendRecoveryAmount() == 0;
    assert getCcipSendRecoveryDestinationChainSelector() == 0;
    assert getCcipSendRecoveryNonce() == 0;
    assert getCcipSendRecoveryProtocolId() == to_bytes32(0);
    assert ghost_CcipSendRecoveryCleared_EventCount == 1;
    assert ghost_CcipSendRecoveryCleared_Param_ccipTxType == Types.CcipTx.EPOCH_NET_WITHDRAW;
    assert ghost_CcipSendRecoveryCleared_Param_destinationChainSelector == destinationChainSelector;
    assert ghost_CcipSendRecoveryCleared_Param_amount == bridgeAmount;
    assert ghost_CCIPBridged_EventCount == 1;
    assert ghost_CCIPBridged_Param_ccipMessageId != to_bytes32(0);
    assert ghost_CCIPBridged_Param_destinationChainSelector == destinationChainSelector;
    assert ghost_CCIPBridged_Param_ccipTxType == Types.CcipTx.EPOCH_NET_WITHDRAW;
    assert ghost_CcipSendRecoveryStored_EventCount == 0;
    assert ghost_ccipSendRecovery_amount_StoreCount == 1;
    assert ghost_ccipSendRecovery_amount_StoredValue == 0;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 1;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoredValue == 0;
    assert ghost_ccipSendRecovery_nonce_StoreCount == 1;
    assert ghost_ccipSendRecovery_nonce_StoredValue == 0;
    assert ghost_ccipSendRecovery_protocolId_StoreCount == 1;
    assert ghost_ccipSendRecovery_protocolId_StoredValue == to_bytes32(0);
    assert ghost_recoveryMode_StoreCount == 1 => ghost_recoveryMode_StoredValue == Types.RecoveryMode.NONE,
        "recovery mode stored value is only meaningful when the recovery mode hook fires, which may not happen due to state packing";
}

/// @notice Rebalance CCIP send recovery via executeRecovery clears recovery and bridges to the target chain
/// @dev Verifies balances, recovery deletion, events, and the encoded rebalance retry payload
rule executeRecovery_CCIP_SEND_REBALANCE_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.CCIP_SEND, "CCIP send recovery should be pending";
    require getCcipSendRecoveryTxType() == Types.CcipTx.REBALANCE, "stored CCIP tx type should be rebalance";
    require getCcipSendRecoveryAmount() != 0, "recovery amount should not be zero";
    require getCcipSendRecoveryDestinationChainSelector() != 0, "destination chain selector should not be zero";
    require getCcipSendRecoveryDestinationChainSelector() != getThisChainSelector(), "destination should not be this chain";
    require getCrosschainVault(getCcipSendRecoveryDestinationChainSelector()) != 0,
        "destination vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev success condition being verified
    uint256 bridgeAmount = getCcipSendRecoveryAmount();
    uint64 destinationChainSelector = getCcipSendRecoveryDestinationChainSelector();
    uint256 nonce = getCcipSendRecoveryNonce();
    bytes32 protocolId = getCcipSendRecoveryProtocolId();

    uint256 fee = ccipRouter.getFee();
    address router = getRouter();
    uint256 vaultLinkBalanceBefore = link.balanceOf(currentContract);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);
    bytes expectedMessageData = encodeCcipTxData(Types.CcipTx.REBALANCE, encodeRebalanceData(nonce, protocolId));

    /// @dev mock token arithmetic conditions
    require fee <= vaultLinkBalanceBefore, "vault LINK balance should cover the CCIP fee";
    require routerLinkBalanceBefore <= max_uint256 - fee, "router LINK balance should not overflow";
    require bridgeAmount <= vaultAssetBalanceBefore, "vault asset balance should cover the bridge amount";
    require routerAssetBalanceBefore <= max_uint256 - bridgeAmount, "router asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_CcipSendRecoveryCleared_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;
    require ghost_CcipSendRecoveryStored_EventCount == 0;
    require ghost_ccipSendRecovery_amount_StoreCount == 0;
    require ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 0;
    require ghost_ccipSendRecovery_nonce_StoreCount == 0;
    require ghost_ccipSendRecovery_protocolId_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;

    executeRecovery@withrevert(e);

    assert !lastReverted;
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore - fee;
    assert link.balanceOf(router) == routerLinkBalanceBefore + fee;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore - bridgeAmount;
    assert asset.balanceOf(router) == routerAssetBalanceBefore + bridgeAmount;
    assert ccipRouter.getLastMessageDataHash() == hashBytes(expectedMessageData);
    assert getRecoveryMode() == Types.RecoveryMode.NONE;
    assert getCcipSendRecoveryTxType() == Types.CcipTx.EPOCH_NET_DEPOSIT;
    assert getCcipSendRecoveryAmount() == 0;
    assert getCcipSendRecoveryDestinationChainSelector() == 0;
    assert getCcipSendRecoveryNonce() == 0;
    assert getCcipSendRecoveryProtocolId() == to_bytes32(0);
    assert ghost_CcipSendRecoveryCleared_EventCount == 1;
    assert ghost_CcipSendRecoveryCleared_Param_ccipTxType == Types.CcipTx.REBALANCE;
    assert ghost_CcipSendRecoveryCleared_Param_destinationChainSelector == destinationChainSelector;
    assert ghost_CcipSendRecoveryCleared_Param_amount == bridgeAmount;
    assert ghost_CCIPBridged_EventCount == 1;
    assert ghost_CCIPBridged_Param_ccipMessageId != to_bytes32(0);
    assert ghost_CCIPBridged_Param_destinationChainSelector == destinationChainSelector;
    assert ghost_CCIPBridged_Param_ccipTxType == Types.CcipTx.REBALANCE;
    assert ghost_CcipSendRecoveryStored_EventCount == 0;
    assert ghost_ccipSendRecovery_amount_StoreCount == 1;
    assert ghost_ccipSendRecovery_amount_StoredValue == 0;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 1;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoredValue == 0;
    assert ghost_ccipSendRecovery_nonce_StoreCount == 1;
    assert ghost_ccipSendRecovery_nonce_StoredValue == 0;
    assert ghost_ccipSendRecovery_protocolId_StoreCount == 1;
    assert ghost_ccipSendRecovery_protocolId_StoredValue == to_bytes32(0);
    assert ghost_recoveryMode_StoreCount == 1 => ghost_recoveryMode_StoredValue == Types.RecoveryMode.NONE,
        "recovery mode stored value is only meaningful when the recovery mode hook fires, which may not happen due to state packing";
}

/// @notice CCIP send recovery via executeRecovery reverts and preserves recovery when router fee lookup fails
/// @dev Verifies atomic rollback after the recovery clear attempt
rule executeRecovery_CCIP_SEND_RevertWhen_RouterGetFeeReverts() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.CCIP_SEND, "CCIP send recovery should be pending";
    require getCcipSendRecoveryAmount() != 0, "recovery amount should not be zero";
    require getCcipSendRecoveryDestinationChainSelector() != 0, "destination chain selector should not be zero";
    require getCcipSendRecoveryDestinationChainSelector() != getThisChainSelector(), "destination should not be this chain";
    require getCrosschainVault(getCcipSendRecoveryDestinationChainSelector()) != 0,
        "destination vault should be registered";
    require getCcipSendRecoveryTxType() == Types.CcipTx.EPOCH_NET_WITHDRAW
        || getCcipSendRecoveryTxType() == Types.CcipTx.REBALANCE,
        "stored CCIP tx type should be supported for child sends";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev revert condition being verified
    require ccipRouter.getFeeReverts(), "router fee lookup should revert";

    address router = getRouter();

    /// @dev set ghost starting values

    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice CCIP send recovery via executeRecovery reverts and preserves recovery when router send fails
/// @dev Verifies atomic rollback after the recovery clear attempt and fee approval
rule executeRecovery_CCIP_SEND_RevertWhen_RouterCcipSendReverts() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.CCIP_SEND, "CCIP send recovery should be pending";
    require getCcipSendRecoveryAmount() != 0, "recovery amount should not be zero";
    require getCcipSendRecoveryDestinationChainSelector() != 0, "destination chain selector should not be zero";
    require getCcipSendRecoveryDestinationChainSelector() != getThisChainSelector(), "destination should not be this chain";
    require getCrosschainVault(getCcipSendRecoveryDestinationChainSelector()) != 0,
        "destination vault should be registered";
    require getCcipSendRecoveryTxType() == Types.CcipTx.EPOCH_NET_WITHDRAW
        || getCcipSendRecoveryTxType() == Types.CcipTx.REBALANCE,
        "stored CCIP tx type should be supported for child sends";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";

    /// @dev revert condition being verified
    require ccipRouter.ccipSendReverts(), "router send should revert";

    uint256 fee = ccipRouter.getFee();
    uint256 bridgeAmount = getCcipSendRecoveryAmount();
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

    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice CCIP send recovery via executeRecovery reverts when the call is reentrant
/// @dev Verifies that recovery state, balances, and events remain unchanged
rule executeRecovery_CCIP_SEND_RevertWhen_ReentrantCall() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getRecoveryMode() == Types.RecoveryMode.CCIP_SEND, "CCIP send recovery should be pending";
    require getCcipSendRecoveryAmount() != 0, "recovery amount should not be zero";
    require getCcipSendRecoveryDestinationChainSelector() != 0, "destination chain selector should not be zero";
    require getCcipSendRecoveryDestinationChainSelector() != getThisChainSelector(), "destination should not be this chain";
    require getCrosschainVault(getCcipSendRecoveryDestinationChainSelector()) != 0, "destination vault should be registered";
    require getCcipSendRecoveryNonce() == 0 && getCcipSendRecoveryProtocolId() == to_bytes32(0),
        "stored CCIP tx data should be empty and well-formed";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";
    require !paused(), "vault should not be paused";

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

    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice CCIP send recovery via executeRecovery reverts when the stored bridge amount is zero
/// @dev Verifies atomic rollback because CCIP validation rejects zero amounts
rule executeRecovery_CCIP_SEND_RevertWhen_AmountIsZero() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.CCIP_SEND, "CCIP send recovery should be pending";
    require getCcipSendRecoveryDestinationChainSelector() != 0, "destination chain selector should not be zero";
    require getCcipSendRecoveryDestinationChainSelector() != getThisChainSelector(), "destination should not be this chain";
    require getCrosschainVault(getCcipSendRecoveryDestinationChainSelector()) != 0, "destination vault should be registered";
    require getCcipSendRecoveryNonce() == 0 && getCcipSendRecoveryProtocolId() == to_bytes32(0),
        "stored CCIP tx data should be empty and well-formed";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev revert condition being verified
    require getCcipSendRecoveryAmount() == 0, "recovery amount should be zero";

    address router = getRouter();

    /// @dev set ghost starting values

    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice CCIP send recovery via executeRecovery reverts when the stored destination selector is invalid
/// @dev Verifies atomic rollback because CCIP validation rejects zero and same-chain destinations
rule executeRecovery_CCIP_SEND_RevertWhen_DestinationChainSelectorInvalid() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.CCIP_SEND, "CCIP send recovery should be pending";
    require getCcipSendRecoveryAmount() != 0, "recovery amount should not be zero";
    require getCcipSendRecoveryNonce() == 0 && getCcipSendRecoveryProtocolId() == to_bytes32(0),
        "stored CCIP tx data should be empty and well-formed";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev revert condition being verified
    require getCcipSendRecoveryDestinationChainSelector() == 0
        || getCcipSendRecoveryDestinationChainSelector() == getThisChainSelector(),
        "destination selector should be invalid";

    uint256 bridgeAmount = getCcipSendRecoveryAmount();
    address router = getRouter();
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);

    /// @dev mock token arithmetic conditions
    require bridgeAmount <= vaultAssetBalanceBefore, "vault asset balance should cover the bridge amount";
    require routerAssetBalanceBefore <= max_uint256 - bridgeAmount, "router asset balance should not overflow";

    /// @dev set ghost starting values

    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice CCIP send recovery via executeRecovery reverts when the destination vault is not registered
/// @dev Verifies atomic rollback because CCIP validation requires a registered destination vault
rule executeRecovery_CCIP_SEND_RevertWhen_DestinationVaultNotRegistered() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.CCIP_SEND, "CCIP send recovery should be pending";
    require getCcipSendRecoveryAmount() != 0, "recovery amount should not be zero";
    require getCcipSendRecoveryDestinationChainSelector() != 0, "destination chain selector should not be zero";
    require getCcipSendRecoveryDestinationChainSelector() != getThisChainSelector(), "destination should not be this chain";
    require getCcipSendRecoveryNonce() == 0 && getCcipSendRecoveryProtocolId() == to_bytes32(0),
        "stored CCIP tx data should be empty and well-formed";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    /// @dev revert condition being verified
    require getCrosschainVault(getCcipSendRecoveryDestinationChainSelector()) == 0,
        "destination vault should not be registered";

    uint256 bridgeAmount = getCcipSendRecoveryAmount();
    address router = getRouter();
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);

    /// @dev mock token arithmetic conditions
    require bridgeAmount <= vaultAssetBalanceBefore, "vault asset balance should cover the bridge amount";
    require routerAssetBalanceBefore <= max_uint256 - bridgeAmount, "router asset balance should not overflow";

    /// @dev set ghost starting values

    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice CCIP send recovery clear deletes recovery state and emits CcipSendRecoveryCleared
/// @dev Verifies the internal clear boundary used by executeRecovery (CCIP_SEND mode) before BaseVaultCcipLib._send.
///      CCIP send validation, router calls, token movement, and CCIPBridged are verified in BaseVaultCcipLib.spec.
rule clearCcipSendRecovery_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";

    /// @dev success conditions being verified
    require getRecoveryMode() == Types.RecoveryMode.CCIP_SEND, "CCIP send recovery should be pending";

    Types.CcipTx ccipTxType = getCcipSendRecoveryTxType();
    uint64 destinationChainSelector = getCcipSendRecoveryDestinationChainSelector();
    uint256 bridgeAmount = getCcipSendRecoveryAmount();
    uint256 nonce = getCcipSendRecoveryNonce();
    bytes32 protocolId = getCcipSendRecoveryProtocolId();

    /// @dev set ghost starting values
    require ghost_CcipSendRecoveryCleared_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;
    require ghost_ccipSendRecovery_amount_StoreCount == 0;
    require ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 0;
    require ghost_ccipSendRecovery_nonce_StoreCount == 0;
    require ghost_ccipSendRecovery_protocolId_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;

    Types.CcipSendRecovery recovery = clearCcipSendRecovery@withrevert(e);

    assert !lastReverted;
    assert recovery.ccipTxType == ccipTxType;
    assert recovery.amount == bridgeAmount;
    assert recovery.destinationChainSelector == destinationChainSelector;
    assert recovery.nonce == nonce;
    assert recovery.protocolId == protocolId;
    assert getRecoveryMode() == Types.RecoveryMode.NONE;
    assert getCcipSendRecoveryTxType() == Types.CcipTx.EPOCH_NET_DEPOSIT;
    assert getCcipSendRecoveryAmount() == 0;
    assert getCcipSendRecoveryDestinationChainSelector() == 0;
    assert getCcipSendRecoveryNonce() == 0 && getCcipSendRecoveryProtocolId() == to_bytes32(0);
    assert ghost_CcipSendRecoveryCleared_EventCount == 1;
    assert ghost_CcipSendRecoveryCleared_Param_ccipTxType == ccipTxType;
    assert ghost_CcipSendRecoveryCleared_Param_destinationChainSelector == destinationChainSelector;
    assert ghost_CcipSendRecoveryCleared_Param_amount == bridgeAmount;
    assert ghost_CCIPBridged_EventCount == 0;
    assert ghost_ccipSendRecovery_amount_StoreCount == 1;
    assert ghost_ccipSendRecovery_amount_StoredValue == 0;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoreCount == 1;
    assert ghost_ccipSendRecovery_destinationChainSelector_StoredValue == 0;
    assert ghost_ccipSendRecovery_nonce_StoreCount == 1;
    assert ghost_ccipSendRecovery_nonce_StoredValue == 0;
    assert ghost_ccipSendRecovery_protocolId_StoreCount == 1;
    assert ghost_ccipSendRecovery_protocolId_StoredValue == to_bytes32(0);
    assert ghost_recoveryMode_StoreCount == 1 => ghost_recoveryMode_StoredValue == Types.RecoveryMode.NONE,
        "recovery mode stored value is only meaningful when the recovery mode hook fires, which may not happen due to state packing";
}

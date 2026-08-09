using MockAdapterRegistry as adapterRegistry;
using MockProtocolAdapter as adapter;
using MockTargetProtocolAdapter as targetAdapter;
using MockInvalidProtocolAdapter as invalidAdapter;
using MockUSDC as asset;
using MockLINK as link;
using MockCCIPRouter as ccipRouter;
using MockYieldcoinShare as share;
using MockPolicyEngine as policyEngine;

/// Verification of ParentVault-specific function behavior
/// @author @contractlevel
/// @notice ParentVault is the single entry/exit point for users; it owns epoch, rebalance, and fee state.
/// @notice Shared BaseVault behavior is verified separately in BaseVault.spec.
/// @notice Deposit/withdraw/claim/cancel/closeEpoch/initiateRebalance/completeRebalance internals are
///         verified in isolation in the corresponding ParentVault*Lib.spec files; this spec covers the
///         vault's own entry-point wiring, access control, and state/events that live in ParentVault.sol itself.
/// @notice ParentVaultHarness stubs _runPolicyBefore/_runPolicyAfter to no-ops, so runPolicy-gated reverts
///         (e.g. PolicyEngineUndefined) are out of scope here for deposit/withdraw/claimShares/claimAsset/
///         cancelDeposit/cancelWithdraw. attachPolicyEngine itself does not go through that stub and is
///         fully covered.

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    /*//////////////////////////////////////////////////////////////
                       PARENTVAULT ENTRY POINTS
    //////////////////////////////////////////////////////////////*/
    function initialize(BaseVault.InitParams, address, address, address, address) external;
    function setInitialActiveProtocolAdapter(bytes32) external;
    function setTreasury(address) external;
    function deposit(uint256) external returns (uint256);
    function withdraw(uint256) external returns (uint256);
    function claimShares(uint256) external returns (uint256);
    function claimAsset(uint256) external returns (uint256);
    function cancelDeposit() external;
    function cancelWithdraw() external;
    function forceCancelDeposit(address) external;
    function ccipReceive(Client.Any2EVMMessage) external;
    function closeEpoch(uint256) external;
    function completeEpochDeposit() external;
    function initiateRebalance(Types.Strategy) external;
    function completeRebalance() external;
    function executeRecovery() external;
    function setSupportedProtocol(bytes32, bool) external;
    function attachPolicyEngine(address) external;

    /*//////////////////////////////////////////////////////////////
                             GETTERS
    //////////////////////////////////////////////////////////////*/
    function getRebalance() external returns (Types.Rebalance) envfree;
    function getEpoch(uint256) external returns (Types.Epoch) envfree;
    function getEpochNonce() external returns (uint256) envfree;
    function getTotalShares() external returns (uint256) envfree;
    function getDepositAmount(address, uint256) external returns (uint256) envfree;
    function getWithdrawShareBurnAmount(address, uint256) external returns (uint256) envfree;
    function getInitialActiveProtocolAdapterSet() external returns (bool) envfree;
    function getPerformanceFeeHighWaterMark() external returns (uint256) envfree;
    function getTreasury() external returns (address) envfree;
    function getShare() external returns (address) envfree;
    function getSharePrecision() external returns (uint256) envfree;
    function getMinDepositAmount() external returns (uint256) envfree;
    function getSupportedProtocol(bytes32) external returns (bool) envfree;
    function getPolicyEngine() external returns (address) envfree;
    function owner() external returns (address) envfree;
    function supportsInterface(bytes4) external returns (bool) envfree;

    /// BaseVault getters this spec's rules read directly
    function getActiveProtocolAdapter() external returns (address) envfree;
    function getRecoveryMode() external returns (Types.RecoveryMode) envfree;
    function getTVL() external returns (uint256) envfree;
    function getThisChainSelector() external returns (uint64) envfree;
    function getAsset() external returns (address) envfree;
    function getAssetPrecision() external returns (uint256) envfree;
    function getRouter() external returns (address) envfree;
    function getRebalanceDepositRecovery() external returns (Types.RebalanceDepositRecovery) envfree;
    function getCrosschainVault(uint64) external returns (address) envfree;
    function paused() external returns (bool) envfree;

    /*//////////////////////////////////////////////////////////////
                       LINKED CONTRACT GETTERS
    //////////////////////////////////////////////////////////////*/
    function asset.balanceOf(address) external returns (uint256) envfree;
    function asset.allowance(address, address) external returns (uint256) envfree;
    function share.balanceOf(address) external returns (uint256) envfree;
    function share.allowance(address, address) external returns (uint256) envfree;
    function share.totalSupply() external returns (uint256) envfree;
    function link.balanceOf(address) external returns (uint256) envfree;
    function adapter.getTVL() external returns (uint256) envfree;
    function adapter.getVault() external returns (address) envfree;
    function invalidAdapter.getVault() external returns (address) envfree;
    function adapter.depositReverts() external returns (bool) envfree;
    function adapter.withdrawReverts() external returns (bool) envfree;
    function targetAdapter.getTVL() external returns (uint256) envfree;
    function targetAdapter.getVault() external returns (address) envfree;
    function targetAdapter.depositReverts() external returns (bool) envfree;
    function ccipRouter.getFee() external returns (uint256) envfree;
    function ccipRouter.getFeeReverts() external returns (bool) envfree;
    function ccipRouter.ccipSendReverts() external returns (bool) envfree;
    function ccipRouter.getLastMessageDataHash() external returns (bytes32) envfree;

    /*//////////////////////////////////////////////////////////////
                           ACCESS CONTROL
    //////////////////////////////////////////////////////////////*/
    function hasRole(bytes32, address) external returns (bool) envfree;
    function DEFAULT_ADMIN_ROLE() external returns (bytes32) envfree;
    function defaultAdmin() external returns (address) envfree;
    function CONFIG_OPERATOR_ROLE() external returns (bytes32) envfree;
    function EPOCH_OPERATOR_ROLE() external returns (bytes32) envfree;
    function REBALANCE_OPERATOR_ROLE() external returns (bytes32) envfree;
    function POLICY_ENGINE_MANAGER_ROLE() external returns (bytes32) envfree;
    function CANCEL_DEPOSIT_OPERATOR_ROLE() external returns (bytes32) envfree;

    /*//////////////////////////////////////////////////////////////
                         HARNESS HELPERS
    //////////////////////////////////////////////////////////////*/
    function reentrancyGuardEntered() external returns (bool) envfree;
    function bytes32ToAddress(bytes32) external returns (address) envfree;
    function bytes32ToUint256(bytes32) external returns (uint256) envfree;
    function bytes32ToUint64(bytes32) external returns (uint64) envfree;
    function bytes32ToUint8(bytes32) external returns (uint8) envfree;
    function bytes32ToBool(bytes32) external returns (bool) envfree;
    function uint8ToCcipTxType(uint8) external returns (Types.CcipTx) envfree;
    function isInitialized() external returns (bool) envfree;
    function isInitializing() external returns (bool) envfree;
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
    function policyProtectedInterfaceId() external returns (bytes4) envfree;

    /*//////////////////////////////////////////////////////////////
                         DISPATCHER SUMMARIES
    //////////////////////////////////////////////////////////////*/
    function _.transfer(address, uint256) external => DISPATCHER(true);
    function _.transferFrom(address, address, uint256) external => DISPATCHER(true);
    function _.balanceOf(address) external => DISPATCHER(true);
    function _.approve(address, uint256) external => DISPATCHER(true);
    function _.forceApprove(address, uint256) external => DISPATCHER(true);
    function _.mint(address, uint256) external => DISPATCHER(true);
    function _.burn(address, uint256) external => DISPATCHER(true);
    function _.deposit(uint256) external => DISPATCHER(true);
    function _.withdraw(uint256) external => DISPATCHER(true);
    function _.getTVL() external => DISPATCHER(true);
    function _.getVault() external => DISPATCHER(true);
    function _.getAsset() external => DISPATCHER(true);
    function _.getAdapter(bytes32) external => DISPATCHER(true);
    function _.getFee(uint64, Client.EVM2AnyMessage) external => DISPATCHER(true);
    function _.ccipSend(uint64, Client.EVM2AnyMessage) external => DISPATCHER(true);
    function _.attach() external => DISPATCHER(true);
    function _.detach() external => DISPATCHER(true);
}

/*//////////////////////////////////////////////////////////////
                         DEFINITIONS
//////////////////////////////////////////////////////////////*/
definition DepositSubmittedEvent() returns bytes32 =
// keccak256("DepositSubmitted(uint256,address,uint256)")
    to_bytes32(0x6dbddde512af7c9b1f7d0a592199a3c85ceac007416f229dd16872d0024343c1);

definition WithdrawSubmittedEvent() returns bytes32 =
// keccak256("WithdrawSubmitted(uint256,address,uint256)")
    to_bytes32(0x4e28329a81623da3184e5f894334e11904009d4148c66bb1ea19eb28478b6351);

definition DepositClaimedEvent() returns bytes32 =
// keccak256("DepositClaimed(uint256,address,uint256)")
    to_bytes32(0xacb5e5700b5a312da42fca897046d87226094d7032852cc1a3cd9e4c54538b2c);

definition WithdrawClaimedEvent() returns bytes32 =
// keccak256("WithdrawClaimed(uint256,address,uint256)")
    to_bytes32(0xd652eec1c58b4b6f74acf69b1c7bd8163c76712b2c9547f6f2d7b14a88bd7f45);

definition DepositCancelledEvent() returns bytes32 =
// keccak256("DepositCancelled(uint256,address,uint256)")
    to_bytes32(0x24c9e122007bd4087408943168fbcd65248594530e482b6a9abe4484767eb0c3);

definition DepositForceCancelledEvent() returns bytes32 =
// keccak256("DepositForceCancelled(uint256,address,uint256)")
    to_bytes32(0x5ab5ba9c804f5bd8c25d7a48e5fd58b3e7b2c7729a0de56d8184368734c60c4b);

definition WithdrawCancelledEvent() returns bytes32 =
// keccak256("WithdrawCancelled(uint256,address,uint256)")
    to_bytes32(0x769d7210521411ed9ffb77cf3eacdd55cfde3d8dd5f99d7a6a908969b327b06f);

definition EpochOpenEvent() returns bytes32 =
// keccak256("EpochOpen(uint256)")
    to_bytes32(0x581f6669baee8fbb7926034742085996de6e2c904da8849660716d60148f9f3b);

definition EpochDepositExecutingEvent() returns bytes32 =
// keccak256("EpochDepositExecuting(uint256,uint256)")
    to_bytes32(0xa61849e22afb93d7cfe676ea2f393b96d7529f8e5ea5bc633327c8945f9b2b4f);

definition EpochWithdrawExecutingEvent() returns bytes32 =
// keccak256("EpochWithdrawExecuting(uint256,uint256)")
    to_bytes32(0x95711be73a8119e097a46812abd1fa8ec60493925e863579094178cb6d86ec38);

definition EpochClaimableEvent() returns bytes32 =
// keccak256("EpochClaimable(uint256)")
    to_bytes32(0x45d9681f238e455170e797872754deaef148c9e7836f9949104764a4f4cfae8a);

definition EpochWithdrawAmountShortEvent() returns bytes32 =
// keccak256("EpochWithdrawAmountShort(uint256,uint256,uint256)")
    to_bytes32(0x9087919bbb431a8a7241eebf12465b469fe3f4f78eeda82d3e47d41378977695);

definition RebalanceInitiatedEvent() returns bytes32 =
// keccak256("RebalanceInitiated(uint256,bytes32,uint64)")
    to_bytes32(0xda9fb704be9ea74218fb76d712b843d4940a81465712f0c6c56840fc62748d73);

definition RebalanceCompletedEvent() returns bytes32 =
// keccak256("RebalanceCompleted(uint256,bytes32,uint64)")
    to_bytes32(0x1b4570cbee52a827424cbed197d0efe2173b0a28c7ba636e76aefb0ad38b3467);

definition ManagementFeeCollectedEvent() returns bytes32 =
// keccak256("ManagementFeeCollected(uint256,uint256)")
    to_bytes32(0x6f4a589972e181c1010960e6cb88e05776a4f3a28373e49c69ffdf8cc30f1a31);

definition PerformanceFeeCollectedEvent() returns bytes32 =
// keccak256("PerformanceFeeCollected(uint256,uint256,uint256)")
    to_bytes32(0xdc4f167bfca42a54abc7c7dd90ec178ea116a54329d32a1a6cb1c6208d17177c);

definition InitialActiveProtocolAdapterSetEvent() returns bytes32 =
// keccak256("InitialActiveProtocolAdapterSet(bytes32,address)")
    to_bytes32(0x389c4eb5fd9b7beba97816c41d88380c67872bdd8d51e708ac90598a3725b112);

definition TreasurySetEvent() returns bytes32 =
// keccak256("TreasurySet(address)")
    to_bytes32(0x3c864541ef71378c6229510ed90f376565ee42d9c5e0904a984a9e863e6db44f);

definition SupportedProtocolSetEvent() returns bytes32 =
// keccak256("SupportedProtocolSet(bytes32,bool)")
    to_bytes32(0x56cc71f639333b7ecd9179fddeb0ecc00bcb82b3f98664a11601a28652604c48);

definition PolicyEngineAttachedEvent() returns bytes32 =
// keccak256("PolicyEngineAttached(address)")
    to_bytes32(0x57d241970863a27bedbf58b705b45a0b267f76f9a3a7fd432e217a37e4173fac);

definition PolicyEngineDetachFailedEvent() returns bytes32 =
// keccak256("PolicyEngineDetachFailed(address,bytes)")
    to_bytes32(0x5c3a3f63e48796286c8d14b455ed70b560ab62290af416cbe00f3f18afcbd4cd);

/// @dev IBaseVault events emitted directly from ParentVault.sol entry points (setInitialActiveProtocolAdapter,
///      initiateRebalance) via the shared _setActiveAdapter/_clearActiveAdapter internal helpers. Tracked here
///      because these ParentVault call sites are not covered by BaseVault.spec.
definition ActiveProtocolAdapterSetEvent() returns bytes32 =
// keccak256("ActiveProtocolAdapterSet(bytes32,address)")
    to_bytes32(0xf3628f0443ba881ea4c9543ca1d28250e78f2e019fffe8a8e722378625dcf598);

definition ActiveProtocolAdapterClearedEvent() returns bytes32 =
// keccak256("ActiveProtocolAdapterCleared(address)")
    to_bytes32(0x965689b74a63affbd22afb2528d6f7c11a4d1d2850b0f0cc8f647992386bf04f);

definition RebalanceWithdrawSuccessEvent() returns bytes32 =
// keccak256("RebalanceWithdrawSuccess(uint256,uint256)")
    to_bytes32(0xbda9c2bb85185244245a5c12fdd1e1107c46dc54a6d54d015bccf78aec5a8668);

/// @dev IBaseVault events emitted directly from ParentVault.sol's rebalance-deposit branches.
///      Tracked here because this ParentVault call site is not covered by BaseVault.spec.
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

/// @dev Mirrors the constants in ParentVaultFeesLib for modeling the management fee formula inline.
definition BPS_DENOMINATOR() returns uint256 = 10000;
definition PERFORMANCE_FEE_BPS() returns uint256 = 777;
definition MANAGEMENT_FEE_BPS() returns uint256 = 100;
definition YEAR() returns uint256 = 31536000;

/// @dev Mirrors ParentVaultEpochLib.MIN_EPOCH_PERIOD (not exposed via any ParentVault getter).
definition MIN_EPOCH_PERIOD() returns uint256 = 3600;
definition MIN_REBALANCE_PERIOD() returns uint256 = 3600;

/// @dev IBaseVault events emitted directly from ParentVault.sol's closeEpoch. Tracked here because
///      this ParentVault call site is not covered by BaseVault.spec.
definition EpochDepositToStrategySuccessEvent() returns bytes32 =
// keccak256("EpochDepositToStrategySuccess(uint256,uint256)")
    to_bytes32(0x78a668caa26414a04375566a4f66def1a635b5bfc0b55d95afa96141377fe18b);

definition EpochWithdrawFromStrategySuccessEvent() returns bytes32 =
// keccak256("EpochWithdrawFromStrategySuccess(uint256,uint256)")
    to_bytes32(0x444cf00a2b9a3f54fd8bef5181e55f6d94b18ae241a090ee45c24ebd80225c4d);

/// @dev BaseVaultCcipLib event emitted directly from ParentVault.sol's closeEpoch remote-deposit
///      branch (via _ccipSend). Tracked here because this ParentVault call site is not covered by
///      BaseVault.spec.
definition CCIPBridgedEvent() returns bytes32 =
// keccak256("CCIPBridged(bytes32,uint64,uint8)")
    to_bytes32(0x2fec67437fa2b2e63688e15520acdbd76b9c4d152a8e345d00ce467eaf4e67fc);

definition CCIPReceivedEvent() returns bytes32 =
// keccak256("CCIPReceived(bytes32,uint64,uint8)")
    to_bytes32(0xcad89c08e093f9ba49742fdc90e42d33fc4ad95fd450fa31060e1050ab852932);

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/

/// ─── Event: ActiveProtocolAdapterSet ──────────────────────────
ghost mathint ghost_ActiveProtocolAdapterSet_EventCount {
    init_state axiom ghost_ActiveProtocolAdapterSet_EventCount == 0;
}
ghost bytes32 ghost_ActiveProtocolAdapterSet_Param_protocolId {
    init_state axiom ghost_ActiveProtocolAdapterSet_Param_protocolId == to_bytes32(0);
}
ghost address ghost_ActiveProtocolAdapterSet_Param_adapter {
    init_state axiom ghost_ActiveProtocolAdapterSet_Param_adapter == 0;
}

/// ─── Event: ActiveProtocolAdapterCleared ──────────────────────
ghost mathint ghost_ActiveProtocolAdapterCleared_EventCount {
    init_state axiom ghost_ActiveProtocolAdapterCleared_EventCount == 0;
}
ghost address ghost_ActiveProtocolAdapterCleared_Param_adapter {
    init_state axiom ghost_ActiveProtocolAdapterCleared_Param_adapter == 0;
}

/// ─── Event: RebalanceWithdrawSuccess ───────────────────────────
ghost mathint ghost_RebalanceWithdrawSuccess_EventCount {
    init_state axiom ghost_RebalanceWithdrawSuccess_EventCount == 0;
}
ghost uint256 ghost_RebalanceWithdrawSuccess_Param_rebalanceNonce {
    init_state axiom ghost_RebalanceWithdrawSuccess_Param_rebalanceNonce == 0;
}
ghost uint256 ghost_RebalanceWithdrawSuccess_Param_amount {
    init_state axiom ghost_RebalanceWithdrawSuccess_Param_amount == 0;
}

/// ─── Event: RebalanceDepositSuccess ────────────────────────────
ghost mathint ghost_RebalanceDepositSuccess_EventCount {
    init_state axiom ghost_RebalanceDepositSuccess_EventCount == 0;
}
ghost uint256 ghost_RebalanceDepositSuccess_Param_rebalanceNonce {
    init_state axiom ghost_RebalanceDepositSuccess_Param_rebalanceNonce == 0;
}
ghost uint256 ghost_RebalanceDepositSuccess_Param_amount {
    init_state axiom ghost_RebalanceDepositSuccess_Param_amount == 0;
}

/// ─── Event: RebalanceDepositFailure ────────────────────────────
ghost mathint ghost_RebalanceDepositFailure_EventCount {
    init_state axiom ghost_RebalanceDepositFailure_EventCount == 0;
}
ghost uint256 ghost_RebalanceDepositFailure_Param_rebalanceNonce {
    init_state axiom ghost_RebalanceDepositFailure_Param_rebalanceNonce == 0;
}
ghost uint256 ghost_RebalanceDepositFailure_Param_amount {
    init_state axiom ghost_RebalanceDepositFailure_Param_amount == 0;
}

/// ─── Event: RebalanceDepositRecoveryStored ─────────────────────
ghost mathint ghost_RebalanceDepositRecoveryStored_EventCount {
    init_state axiom ghost_RebalanceDepositRecoveryStored_EventCount == 0;
}
ghost uint256 ghost_RebalanceDepositRecoveryStored_Param_rebalanceNonce {
    init_state axiom ghost_RebalanceDepositRecoveryStored_Param_rebalanceNonce == 0;
}
ghost uint256 ghost_RebalanceDepositRecoveryStored_Param_amount {
    init_state axiom ghost_RebalanceDepositRecoveryStored_Param_amount == 0;
}

/// ─── Event: RebalanceDepositRecoveryCleared ────────────────────
ghost mathint ghost_RebalanceDepositRecoveryCleared_EventCount {
    init_state axiom ghost_RebalanceDepositRecoveryCleared_EventCount == 0;
}
ghost uint256 ghost_RebalanceDepositRecoveryCleared_Param_rebalanceNonce {
    init_state axiom ghost_RebalanceDepositRecoveryCleared_Param_rebalanceNonce == 0;
}

/// ─── Event: EpochDepositToStrategySuccess ───────────────────────────
ghost mathint ghost_EpochDepositToStrategySuccess_EventCount {
    init_state axiom ghost_EpochDepositToStrategySuccess_EventCount == 0;
}
ghost uint256 ghost_EpochDepositToStrategySuccess_Param_epochNonce {
    init_state axiom ghost_EpochDepositToStrategySuccess_Param_epochNonce == 0;
}
ghost uint256 ghost_EpochDepositToStrategySuccess_Param_amount {
    init_state axiom ghost_EpochDepositToStrategySuccess_Param_amount == 0;
}

/// ─── Event: EpochWithdrawFromStrategySuccess ────────────────────────
ghost mathint ghost_EpochWithdrawFromStrategySuccess_EventCount {
    init_state axiom ghost_EpochWithdrawFromStrategySuccess_EventCount == 0;
}
ghost uint256 ghost_EpochWithdrawFromStrategySuccess_Param_epochNonce {
    init_state axiom ghost_EpochWithdrawFromStrategySuccess_Param_epochNonce == 0;
}
ghost uint256 ghost_EpochWithdrawFromStrategySuccess_Param_amount {
    init_state axiom ghost_EpochWithdrawFromStrategySuccess_Param_amount == 0;
}

/// ─── Event: CCIPBridged ─────────────────────────────────────────
ghost mathint ghost_CCIPBridged_EventCount {
    init_state axiom ghost_CCIPBridged_EventCount == 0;
}
ghost bytes32 ghost_CCIPBridged_Param_ccipMessageId {
    init_state axiom ghost_CCIPBridged_Param_ccipMessageId == to_bytes32(0);
}
ghost uint64 ghost_CCIPBridged_Param_destinationChainSelector {
    init_state axiom ghost_CCIPBridged_Param_destinationChainSelector == 0;
}
ghost Types.CcipTx ghost_CCIPBridged_Param_ccipTxType {
    init_state axiom ghost_CCIPBridged_Param_ccipTxType == Types.CcipTx.EPOCH_NET_DEPOSIT;
}

ghost mathint ghost_CCIPReceived_EventCount {
    init_state axiom ghost_CCIPReceived_EventCount == 0;
}
ghost bytes32 ghost_CCIPReceived_Param_ccipMessageId {
    init_state axiom ghost_CCIPReceived_Param_ccipMessageId == to_bytes32(0);
}
ghost uint64 ghost_CCIPReceived_Param_sourceChainSelector {
    init_state axiom ghost_CCIPReceived_Param_sourceChainSelector == 0;
}
ghost Types.CcipTx ghost_CCIPReceived_Param_ccipTxType {
    init_state axiom ghost_CCIPReceived_Param_ccipTxType == Types.CcipTx.EPOCH_NET_DEPOSIT;
}

/// ─── s_rebalance.nonce ───────────────────────────────────────
ghost mathint ghost_rebalance_nonce_StoreCount {
    init_state axiom ghost_rebalance_nonce_StoreCount == 0;
}
ghost uint256 ghost_rebalance_nonce_StoredValue {
    init_state axiom ghost_rebalance_nonce_StoredValue == 0;
}

/// ─── s_rebalance.state ───────────────────────────────────────
ghost mathint ghost_rebalance_state_StoreCount {
    init_state axiom ghost_rebalance_state_StoreCount == 0;
}
ghost Types.RebalanceState ghost_rebalance_state_StoredValue {
    init_state axiom ghost_rebalance_state_StoredValue == Types.RebalanceState.NONE;
}

/// ─── s_rebalance.activeStrategy.protocolId ───────────────────
ghost mathint ghost_rebalance_activeStrategy_protocolId_StoreCount {
    init_state axiom ghost_rebalance_activeStrategy_protocolId_StoreCount == 0;
}
ghost bytes32 ghost_rebalance_activeStrategy_protocolId_StoredValue {
    init_state axiom ghost_rebalance_activeStrategy_protocolId_StoredValue == to_bytes32(0);
}

/// ─── s_rebalance.activeStrategy.chainSelector ────────────────
ghost mathint ghost_rebalance_activeStrategy_chainSelector_StoreCount {
    init_state axiom ghost_rebalance_activeStrategy_chainSelector_StoreCount == 0;
}
ghost uint64 ghost_rebalance_activeStrategy_chainSelector_StoredValue {
    init_state axiom ghost_rebalance_activeStrategy_chainSelector_StoredValue == 0;
}

/// ─── s_rebalance.pendingStrategy.protocolId ──────────────────
ghost mathint ghost_rebalance_pendingStrategy_protocolId_StoreCount {
    init_state axiom ghost_rebalance_pendingStrategy_protocolId_StoreCount == 0;
}
ghost bytes32 ghost_rebalance_pendingStrategy_protocolId_StoredValue {
    init_state axiom ghost_rebalance_pendingStrategy_protocolId_StoredValue == to_bytes32(0);
}

/// ─── s_rebalance.pendingStrategy.chainSelector ───────────────
ghost mathint ghost_rebalance_pendingStrategy_chainSelector_StoreCount {
    init_state axiom ghost_rebalance_pendingStrategy_chainSelector_StoreCount == 0;
}
ghost uint64 ghost_rebalance_pendingStrategy_chainSelector_StoredValue {
    init_state axiom ghost_rebalance_pendingStrategy_chainSelector_StoredValue == 0;
}

/// ─── s_rebalance.lastRebalanceCompletedTimestamp ─────────────
ghost mathint ghost_rebalance_lastRebalanceCompletedTimestamp_StoreCount {
    init_state axiom ghost_rebalance_lastRebalanceCompletedTimestamp_StoreCount == 0;
}
ghost uint256 ghost_rebalance_lastRebalanceCompletedTimestamp_StoredValue {
    init_state axiom ghost_rebalance_lastRebalanceCompletedTimestamp_StoredValue == 0;
}

/// ─── s_totalShares ────────────────────────────────────────────
ghost mathint ghost_totalShares_StoreCount {
    init_state axiom ghost_totalShares_StoreCount == 0;
}
ghost uint256 ghost_totalShares_StoredValue {
    init_state axiom ghost_totalShares_StoredValue == 0;
}

/// ─── s_performanceFeeHighWaterMark ────────────────────────────
ghost mathint ghost_performanceFeeHighWaterMark_StoreCount {
    init_state axiom ghost_performanceFeeHighWaterMark_StoreCount == 0;
}
ghost uint256 ghost_performanceFeeHighWaterMark_StoredValue {
    init_state axiom ghost_performanceFeeHighWaterMark_StoredValue == 0;
}

/// ─── s_epochNonce ──────────────────────────────────────────────
ghost mathint ghost_epochNonce_StoreCount {
    init_state axiom ghost_epochNonce_StoreCount == 0;
}
ghost uint256 ghost_epochNonce_StoredValue {
    init_state axiom ghost_epochNonce_StoredValue == 0;
}

/// ─── s_treasury ────────────────────────────────────────────────
ghost mathint ghost_treasury_StoreCount {
    init_state axiom ghost_treasury_StoreCount == 0;
}
ghost address ghost_treasury_StoredValue {
    init_state axiom ghost_treasury_StoredValue == 0;
}

/// ─── s_initialActiveProtocolAdapterSet ──────────────────────────
ghost mathint ghost_initialActiveProtocolAdapterSet_StoreCount {
    init_state axiom ghost_initialActiveProtocolAdapterSet_StoreCount == 0;
}
ghost bool ghost_initialActiveProtocolAdapterSet_StoredValue {
    init_state axiom ghost_initialActiveProtocolAdapterSet_StoredValue == false;
}

/// ─── s_epochs[epochNonce].totalDepositAmount ─────────────────────
ghost mathint ghost_epoch_totalDepositAmount_StoreCount {
    init_state axiom ghost_epoch_totalDepositAmount_StoreCount == 0;
}
ghost uint256 ghost_epoch_totalDepositAmount_StoredKey {
    init_state axiom ghost_epoch_totalDepositAmount_StoredKey == 0;
}
ghost uint256 ghost_epoch_totalDepositAmount_StoredValue {
    init_state axiom ghost_epoch_totalDepositAmount_StoredValue == 0;
}

/// ─── s_epochs[epochNonce].totalShareBurnAmount ───────────────────
ghost mathint ghost_epoch_totalShareBurnAmount_StoreCount {
    init_state axiom ghost_epoch_totalShareBurnAmount_StoreCount == 0;
}
ghost uint256 ghost_epoch_totalShareBurnAmount_StoredKey {
    init_state axiom ghost_epoch_totalShareBurnAmount_StoredKey == 0;
}
ghost uint256 ghost_epoch_totalShareBurnAmount_StoredValue {
    init_state axiom ghost_epoch_totalShareBurnAmount_StoredValue == 0;
}

/// ─── s_epochs[epochNonce].totalWithdrawClaimAmount ───────────────
ghost mathint ghost_epoch_totalWithdrawClaimAmount_StoreCount {
    init_state axiom ghost_epoch_totalWithdrawClaimAmount_StoreCount == 0;
}
ghost uint256 ghost_epoch_totalWithdrawClaimAmount_StoredKey {
    init_state axiom ghost_epoch_totalWithdrawClaimAmount_StoredKey == 0;
}
ghost uint256 ghost_epoch_totalWithdrawClaimAmount_StoredValue {
    init_state axiom ghost_epoch_totalWithdrawClaimAmount_StoredValue == 0;
}

/// ─── s_epochs[epochNonce].pricePerShare ──────────────────────────
ghost mathint ghost_epoch_pricePerShare_StoreCount {
    init_state axiom ghost_epoch_pricePerShare_StoreCount == 0;
}
ghost uint256 ghost_epoch_pricePerShare_StoredKey {
    init_state axiom ghost_epoch_pricePerShare_StoredKey == 0;
}
ghost uint256 ghost_epoch_pricePerShare_StoredValue {
    init_state axiom ghost_epoch_pricePerShare_StoredValue == 0;
}

/// ─── s_epochs[epochNonce].remainingDepositClaimAmount ────────────
ghost mathint ghost_epoch_remainingDepositClaimAmount_StoreCount {
    init_state axiom ghost_epoch_remainingDepositClaimAmount_StoreCount == 0;
}
ghost uint256 ghost_epoch_remainingDepositClaimAmount_StoredKey {
    init_state axiom ghost_epoch_remainingDepositClaimAmount_StoredKey == 0;
}
ghost uint256 ghost_epoch_remainingDepositClaimAmount_StoredValue {
    init_state axiom ghost_epoch_remainingDepositClaimAmount_StoredValue == 0;
}

/// ─── s_epochs[epochNonce].remainingShareMintAmount ───────────────
ghost mathint ghost_epoch_remainingShareMintAmount_StoreCount {
    init_state axiom ghost_epoch_remainingShareMintAmount_StoreCount == 0;
}
ghost uint256 ghost_epoch_remainingShareMintAmount_StoredKey {
    init_state axiom ghost_epoch_remainingShareMintAmount_StoredKey == 0;
}
ghost uint256 ghost_epoch_remainingShareMintAmount_StoredValue {
    init_state axiom ghost_epoch_remainingShareMintAmount_StoredValue == 0;
}

/// ─── s_epochs[epochNonce].remainingShareBurnAmount ───────────────
ghost mathint ghost_epoch_remainingShareBurnAmount_StoreCount {
    init_state axiom ghost_epoch_remainingShareBurnAmount_StoreCount == 0;
}
ghost uint256 ghost_epoch_remainingShareBurnAmount_StoredKey {
    init_state axiom ghost_epoch_remainingShareBurnAmount_StoredKey == 0;
}
ghost uint256 ghost_epoch_remainingShareBurnAmount_StoredValue {
    init_state axiom ghost_epoch_remainingShareBurnAmount_StoredValue == 0;
}

/// ─── s_epochs[epochNonce].remainingWithdrawClaimAmount ───────────
ghost mathint ghost_epoch_remainingWithdrawClaimAmount_StoreCount {
    init_state axiom ghost_epoch_remainingWithdrawClaimAmount_StoreCount == 0;
}
ghost uint256 ghost_epoch_remainingWithdrawClaimAmount_StoredKey {
    init_state axiom ghost_epoch_remainingWithdrawClaimAmount_StoredKey == 0;
}
ghost uint256 ghost_epoch_remainingWithdrawClaimAmount_StoredValue {
    init_state axiom ghost_epoch_remainingWithdrawClaimAmount_StoredValue == 0;
}

/// ─── s_epochs[epochNonce].openedAtTimestamp ──────────────────────
ghost mathint ghost_epoch_openedAtTimestamp_StoreCount {
    init_state axiom ghost_epoch_openedAtTimestamp_StoreCount == 0;
}
ghost uint256 ghost_epoch_openedAtTimestamp_StoredKey {
    init_state axiom ghost_epoch_openedAtTimestamp_StoredKey == 0;
}
ghost uint256 ghost_epoch_openedAtTimestamp_StoredValue {
    init_state axiom ghost_epoch_openedAtTimestamp_StoredValue == 0;
}

/// ─── s_epochs[epochNonce].status ─────────────────────────────────
ghost mathint ghost_epoch_status_StoreCount {
    init_state axiom ghost_epoch_status_StoreCount == 0;
}
ghost uint256 ghost_epoch_status_StoredKey {
    init_state axiom ghost_epoch_status_StoredKey == 0;
}
ghost Types.EpochStatus ghost_epoch_status_StoredValue {
    init_state axiom ghost_epoch_status_StoredValue == Types.EpochStatus.NONE;
}

/// ─── s_deposits[depositor][epochNonce] ───────────────────────────
ghost mathint ghost_deposit_StoreCount {
    init_state axiom ghost_deposit_StoreCount == 0;
}
ghost address ghost_deposit_StoredKeyDepositor {
    init_state axiom ghost_deposit_StoredKeyDepositor == 0;
}
ghost uint256 ghost_deposit_StoredKeyEpochNonce {
    init_state axiom ghost_deposit_StoredKeyEpochNonce == 0;
}
ghost uint256 ghost_deposit_StoredValue {
    init_state axiom ghost_deposit_StoredValue == 0;
}

/// ─── s_withdraws[withdrawer][epochNonce] ─────────────────────────
ghost mathint ghost_withdraw_StoreCount {
    init_state axiom ghost_withdraw_StoreCount == 0;
}
ghost address ghost_withdraw_StoredKeyWithdrawer {
    init_state axiom ghost_withdraw_StoredKeyWithdrawer == 0;
}
ghost uint256 ghost_withdraw_StoredKeyEpochNonce {
    init_state axiom ghost_withdraw_StoredKeyEpochNonce == 0;
}
ghost uint256 ghost_withdraw_StoredValue {
    init_state axiom ghost_withdraw_StoredValue == 0;
}

/// ─── s_supportedProtocol[protocolId] ─────────────────────────────
ghost mathint ghost_supportedProtocol_StoreCount {
    init_state axiom ghost_supportedProtocol_StoreCount == 0;
}
ghost bytes32 ghost_supportedProtocol_StoredKey {
    init_state axiom ghost_supportedProtocol_StoredKey == to_bytes32(0);
}
ghost bool ghost_supportedProtocol_StoredValue {
    init_state axiom ghost_supportedProtocol_StoredValue == false;
}

/// ─── Event: DepositSubmitted ──────────────────────────────────────
ghost mathint ghost_DepositSubmitted_EventCount {
    init_state axiom ghost_DepositSubmitted_EventCount == 0;
}
ghost uint256 ghost_DepositSubmitted_Param_epochNonce {
    init_state axiom ghost_DepositSubmitted_Param_epochNonce == 0;
}
ghost address ghost_DepositSubmitted_Param_depositor {
    init_state axiom ghost_DepositSubmitted_Param_depositor == 0;
}
ghost uint256 ghost_DepositSubmitted_Param_amount {
    init_state axiom ghost_DepositSubmitted_Param_amount == 0;
}

/// ─── Event: WithdrawSubmitted ─────────────────────────────────────
ghost mathint ghost_WithdrawSubmitted_EventCount {
    init_state axiom ghost_WithdrawSubmitted_EventCount == 0;
}
ghost uint256 ghost_WithdrawSubmitted_Param_epochNonce {
    init_state axiom ghost_WithdrawSubmitted_Param_epochNonce == 0;
}
ghost address ghost_WithdrawSubmitted_Param_withdrawer {
    init_state axiom ghost_WithdrawSubmitted_Param_withdrawer == 0;
}
ghost uint256 ghost_WithdrawSubmitted_Param_shareBurnAmount {
    init_state axiom ghost_WithdrawSubmitted_Param_shareBurnAmount == 0;
}

/// ─── Event: DepositClaimed ────────────────────────────────────────
ghost mathint ghost_DepositClaimed_EventCount {
    init_state axiom ghost_DepositClaimed_EventCount == 0;
}
ghost uint256 ghost_DepositClaimed_Param_epochNonce {
    init_state axiom ghost_DepositClaimed_Param_epochNonce == 0;
}
ghost address ghost_DepositClaimed_Param_depositor {
    init_state axiom ghost_DepositClaimed_Param_depositor == 0;
}
ghost uint256 ghost_DepositClaimed_Param_shareMintAmount {
    init_state axiom ghost_DepositClaimed_Param_shareMintAmount == 0;
}

/// ─── Event: WithdrawClaimed ───────────────────────────────────────
ghost mathint ghost_WithdrawClaimed_EventCount {
    init_state axiom ghost_WithdrawClaimed_EventCount == 0;
}
ghost uint256 ghost_WithdrawClaimed_Param_epochNonce {
    init_state axiom ghost_WithdrawClaimed_Param_epochNonce == 0;
}
ghost address ghost_WithdrawClaimed_Param_withdrawer {
    init_state axiom ghost_WithdrawClaimed_Param_withdrawer == 0;
}
ghost uint256 ghost_WithdrawClaimed_Param_amount {
    init_state axiom ghost_WithdrawClaimed_Param_amount == 0;
}

/// ─── Event: DepositCancelled ──────────────────────────────────────
ghost mathint ghost_DepositCancelled_EventCount {
    init_state axiom ghost_DepositCancelled_EventCount == 0;
}
ghost uint256 ghost_DepositCancelled_Param_epochNonce {
    init_state axiom ghost_DepositCancelled_Param_epochNonce == 0;
}
ghost address ghost_DepositCancelled_Param_depositor {
    init_state axiom ghost_DepositCancelled_Param_depositor == 0;
}
ghost uint256 ghost_DepositCancelled_Param_amount {
    init_state axiom ghost_DepositCancelled_Param_amount == 0;
}

ghost mathint ghost_DepositForceCancelled_EventCount {
    init_state axiom ghost_DepositForceCancelled_EventCount == 0;
}
ghost uint256 ghost_DepositForceCancelled_Param_epochNonce {
    init_state axiom ghost_DepositForceCancelled_Param_epochNonce == 0;
}
ghost address ghost_DepositForceCancelled_Param_depositor {
    init_state axiom ghost_DepositForceCancelled_Param_depositor == 0;
}
ghost uint256 ghost_DepositForceCancelled_Param_amount {
    init_state axiom ghost_DepositForceCancelled_Param_amount == 0;
}

/// ─── Event: WithdrawCancelled ─────────────────────────────────────
ghost mathint ghost_WithdrawCancelled_EventCount {
    init_state axiom ghost_WithdrawCancelled_EventCount == 0;
}
ghost uint256 ghost_WithdrawCancelled_Param_epochNonce {
    init_state axiom ghost_WithdrawCancelled_Param_epochNonce == 0;
}
ghost address ghost_WithdrawCancelled_Param_withdrawer {
    init_state axiom ghost_WithdrawCancelled_Param_withdrawer == 0;
}
ghost uint256 ghost_WithdrawCancelled_Param_shareBurnAmount {
    init_state axiom ghost_WithdrawCancelled_Param_shareBurnAmount == 0;
}

/// ─── Event: EpochOpen ─────────────────────────────────────────────
ghost mathint ghost_EpochOpen_EventCount {
    init_state axiom ghost_EpochOpen_EventCount == 0;
}
ghost uint256 ghost_EpochOpen_Param_epochNonce {
    init_state axiom ghost_EpochOpen_Param_epochNonce == 0;
}

/// ─── Event: EpochDepositExecuting ────────────────────────────────
ghost mathint ghost_EpochDepositExecuting_EventCount {
    init_state axiom ghost_EpochDepositExecuting_EventCount == 0;
}
ghost uint256 ghost_EpochDepositExecuting_Param_epochNonce {
    init_state axiom ghost_EpochDepositExecuting_Param_epochNonce == 0;
}
ghost uint256 ghost_EpochDepositExecuting_Param_amount {
    init_state axiom ghost_EpochDepositExecuting_Param_amount == 0;
}

/// ─── Event: EpochWithdrawExecuting ───────────────────────────────
ghost mathint ghost_EpochWithdrawExecuting_EventCount {
    init_state axiom ghost_EpochWithdrawExecuting_EventCount == 0;
}
ghost uint256 ghost_EpochWithdrawExecuting_Param_epochNonce {
    init_state axiom ghost_EpochWithdrawExecuting_Param_epochNonce == 0;
}
ghost uint256 ghost_EpochWithdrawExecuting_Param_amount {
    init_state axiom ghost_EpochWithdrawExecuting_Param_amount == 0;
}

/// ─── Event: EpochClaimable ────────────────────────────────────────
ghost mathint ghost_EpochClaimable_EventCount {
    init_state axiom ghost_EpochClaimable_EventCount == 0;
}
ghost uint256 ghost_EpochClaimable_Param_epochNonce {
    init_state axiom ghost_EpochClaimable_Param_epochNonce == 0;
}

/// ─── Event: EpochWithdrawAmountShort ──────────────────────────────
ghost mathint ghost_EpochWithdrawAmountShort_EventCount {
    init_state axiom ghost_EpochWithdrawAmountShort_EventCount == 0;
}
ghost uint256 ghost_EpochWithdrawAmountShort_Param_epochNonce {
    init_state axiom ghost_EpochWithdrawAmountShort_Param_epochNonce == 0;
}
ghost uint256 ghost_EpochWithdrawAmountShort_Param_expectedAmount {
    init_state axiom ghost_EpochWithdrawAmountShort_Param_expectedAmount == 0;
}
ghost uint256 ghost_EpochWithdrawAmountShort_Param_actualAmount {
    init_state axiom ghost_EpochWithdrawAmountShort_Param_actualAmount == 0;
}

/// ─── Event: RebalanceInitiated ────────────────────────────────────
ghost mathint ghost_RebalanceInitiated_EventCount {
    init_state axiom ghost_RebalanceInitiated_EventCount == 0;
}
ghost uint256 ghost_RebalanceInitiated_Param_rebalanceNonce {
    init_state axiom ghost_RebalanceInitiated_Param_rebalanceNonce == 0;
}
ghost uint64 ghost_RebalanceInitiated_Param_chainSelector {
    init_state axiom ghost_RebalanceInitiated_Param_chainSelector == 0;
}
ghost bytes32 ghost_RebalanceInitiated_Param_protocolId {
    init_state axiom ghost_RebalanceInitiated_Param_protocolId == to_bytes32(0);
}

/// ─── Event: RebalanceCompleted ────────────────────────────────────
ghost mathint ghost_RebalanceCompleted_EventCount {
    init_state axiom ghost_RebalanceCompleted_EventCount == 0;
}
ghost uint256 ghost_RebalanceCompleted_Param_rebalanceNonce {
    init_state axiom ghost_RebalanceCompleted_Param_rebalanceNonce == 0;
}
ghost bytes32 ghost_RebalanceCompleted_Param_newProtocolId {
    init_state axiom ghost_RebalanceCompleted_Param_newProtocolId == to_bytes32(0);
}
ghost uint64 ghost_RebalanceCompleted_Param_newChainSelector {
    init_state axiom ghost_RebalanceCompleted_Param_newChainSelector == 0;
}

/// ─── Event: ManagementFeeCollected ────────────────────────────────
ghost mathint ghost_ManagementFeeCollected_EventCount {
    init_state axiom ghost_ManagementFeeCollected_EventCount == 0;
}
ghost uint256 ghost_ManagementFeeCollected_Param_rebalanceNonce {
    init_state axiom ghost_ManagementFeeCollected_Param_rebalanceNonce == 0;
}
ghost uint256 ghost_ManagementFeeCollected_Param_feeShares {
    init_state axiom ghost_ManagementFeeCollected_Param_feeShares == 0;
}

/// ─── Event: PerformanceFeeCollected ───────────────────────────────
ghost mathint ghost_PerformanceFeeCollected_EventCount {
    init_state axiom ghost_PerformanceFeeCollected_EventCount == 0;
}
ghost uint256 ghost_PerformanceFeeCollected_Param_epochNonce {
    init_state axiom ghost_PerformanceFeeCollected_Param_epochNonce == 0;
}
ghost uint256 ghost_PerformanceFeeCollected_Param_feeShares {
    init_state axiom ghost_PerformanceFeeCollected_Param_feeShares == 0;
}
ghost uint256 ghost_PerformanceFeeCollected_Param_settlementPricePerShare {
    init_state axiom ghost_PerformanceFeeCollected_Param_settlementPricePerShare == 0;
}

/// ─── Event: InitialActiveProtocolAdapterSet ───────────────────────
ghost mathint ghost_InitialActiveProtocolAdapterSet_EventCount {
    init_state axiom ghost_InitialActiveProtocolAdapterSet_EventCount == 0;
}
ghost bytes32 ghost_InitialActiveProtocolAdapterSet_Param_protocolId {
    init_state axiom ghost_InitialActiveProtocolAdapterSet_Param_protocolId == to_bytes32(0);
}
ghost address ghost_InitialActiveProtocolAdapterSet_Param_adapter {
    init_state axiom ghost_InitialActiveProtocolAdapterSet_Param_adapter == 0;
}

/// ─── Event: TreasurySet ───────────────────────────────────────────
ghost mathint ghost_TreasurySet_EventCount {
    init_state axiom ghost_TreasurySet_EventCount == 0;
}
ghost address ghost_TreasurySet_Param_treasury {
    init_state axiom ghost_TreasurySet_Param_treasury == 0;
}

/// ─── Event: SupportedProtocolSet ──────────────────────────────────
ghost mathint ghost_SupportedProtocolSet_EventCount {
    init_state axiom ghost_SupportedProtocolSet_EventCount == 0;
}
ghost bytes32 ghost_SupportedProtocolSet_Param_protocolId {
    init_state axiom ghost_SupportedProtocolSet_Param_protocolId == to_bytes32(0);
}
ghost bool ghost_SupportedProtocolSet_Param_isSupported {
    init_state axiom ghost_SupportedProtocolSet_Param_isSupported == false;
}

/// ─── Event: PolicyEngineAttached ──────────────────────────────────
ghost mathint ghost_PolicyEngineAttached_EventCount {
    init_state axiom ghost_PolicyEngineAttached_EventCount == 0;
}
ghost address ghost_PolicyEngineAttached_Param_policyEngine {
    init_state axiom ghost_PolicyEngineAttached_Param_policyEngine == 0;
}

/// ─── Event: PolicyEngineDetachFailed ──────────────────────────────
/// @dev `reason` (bytes) is non-indexed and not decodable from LOG topics; only EventCount + the
///      indexed `policyEngine` param are tracked here.
ghost mathint ghost_PolicyEngineDetachFailed_EventCount {
    init_state axiom ghost_PolicyEngineDetachFailed_EventCount == 0;
}
ghost address ghost_PolicyEngineDetachFailed_Param_policyEngine {
    init_state axiom ghost_PolicyEngineDetachFailed_Param_policyEngine == 0;
}

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/

/// ───────────────────────── STORAGE HOOKS ─────────────────────────
hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_rebalance.nonce uint256 newValue {
    ghost_rebalance_nonce_StoreCount = ghost_rebalance_nonce_StoreCount + 1;
    ghost_rebalance_nonce_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_rebalance.state Types.RebalanceState newValue {
    ghost_rebalance_state_StoreCount = ghost_rebalance_state_StoreCount + 1;
    ghost_rebalance_state_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_rebalance.activeStrategy.protocolId bytes32 newValue {
    ghost_rebalance_activeStrategy_protocolId_StoreCount = ghost_rebalance_activeStrategy_protocolId_StoreCount + 1;
    ghost_rebalance_activeStrategy_protocolId_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_rebalance.activeStrategy.chainSelector uint64 newValue {
    ghost_rebalance_activeStrategy_chainSelector_StoreCount = ghost_rebalance_activeStrategy_chainSelector_StoreCount + 1;
    ghost_rebalance_activeStrategy_chainSelector_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_rebalance.pendingStrategy.protocolId bytes32 newValue {
    ghost_rebalance_pendingStrategy_protocolId_StoreCount = ghost_rebalance_pendingStrategy_protocolId_StoreCount + 1;
    ghost_rebalance_pendingStrategy_protocolId_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_rebalance.pendingStrategy.chainSelector uint64 newValue {
    ghost_rebalance_pendingStrategy_chainSelector_StoreCount = ghost_rebalance_pendingStrategy_chainSelector_StoreCount + 1;
    ghost_rebalance_pendingStrategy_chainSelector_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_rebalance.lastRebalanceCompletedTimestamp uint256 newValue {
    ghost_rebalance_lastRebalanceCompletedTimestamp_StoreCount = ghost_rebalance_lastRebalanceCompletedTimestamp_StoreCount + 1;
    ghost_rebalance_lastRebalanceCompletedTimestamp_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_totalShares uint256 newValue {
    ghost_totalShares_StoreCount = ghost_totalShares_StoreCount + 1;
    ghost_totalShares_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_performanceFeeHighWaterMark uint256 newValue {
    ghost_performanceFeeHighWaterMark_StoreCount = ghost_performanceFeeHighWaterMark_StoreCount + 1;
    ghost_performanceFeeHighWaterMark_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_epochNonce uint256 newValue {
    ghost_epochNonce_StoreCount = ghost_epochNonce_StoreCount + 1;
    ghost_epochNonce_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_treasury address newValue {
    ghost_treasury_StoreCount = ghost_treasury_StoreCount + 1;
    ghost_treasury_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_initialActiveProtocolAdapterSet bool newValue {
    ghost_initialActiveProtocolAdapterSet_StoreCount = ghost_initialActiveProtocolAdapterSet_StoreCount + 1;
    ghost_initialActiveProtocolAdapterSet_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_epochs[KEY uint256 epochNonce].totalDepositAmount uint256 newValue {
    ghost_epoch_totalDepositAmount_StoreCount = ghost_epoch_totalDepositAmount_StoreCount + 1;
    ghost_epoch_totalDepositAmount_StoredKey = epochNonce;
    ghost_epoch_totalDepositAmount_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_epochs[KEY uint256 epochNonce].totalShareBurnAmount uint256 newValue {
    ghost_epoch_totalShareBurnAmount_StoreCount = ghost_epoch_totalShareBurnAmount_StoreCount + 1;
    ghost_epoch_totalShareBurnAmount_StoredKey = epochNonce;
    ghost_epoch_totalShareBurnAmount_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_epochs[KEY uint256 epochNonce].totalWithdrawClaimAmount uint256 newValue {
    ghost_epoch_totalWithdrawClaimAmount_StoreCount = ghost_epoch_totalWithdrawClaimAmount_StoreCount + 1;
    ghost_epoch_totalWithdrawClaimAmount_StoredKey = epochNonce;
    ghost_epoch_totalWithdrawClaimAmount_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_epochs[KEY uint256 epochNonce].pricePerShare uint256 newValue {
    ghost_epoch_pricePerShare_StoreCount = ghost_epoch_pricePerShare_StoreCount + 1;
    ghost_epoch_pricePerShare_StoredKey = epochNonce;
    ghost_epoch_pricePerShare_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_epochs[KEY uint256 epochNonce].remainingDepositClaimAmount uint256 newValue {
    ghost_epoch_remainingDepositClaimAmount_StoreCount = ghost_epoch_remainingDepositClaimAmount_StoreCount + 1;
    ghost_epoch_remainingDepositClaimAmount_StoredKey = epochNonce;
    ghost_epoch_remainingDepositClaimAmount_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_epochs[KEY uint256 epochNonce].remainingShareMintAmount
    uint256 newValue (uint256 oldValue) {
    ghost_epoch_remainingShareMintAmount_StoreCount = ghost_epoch_remainingShareMintAmount_StoreCount + 1;
    ghost_epoch_remainingShareMintAmount_StoredKey = epochNonce;
    ghost_epoch_remainingShareMintAmount_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_epochs[KEY uint256 epochNonce].remainingShareBurnAmount
    uint256 newValue (uint256 oldValue) {
    ghost_epoch_remainingShareBurnAmount_StoreCount = ghost_epoch_remainingShareBurnAmount_StoreCount + 1;
    ghost_epoch_remainingShareBurnAmount_StoredKey = epochNonce;
    ghost_epoch_remainingShareBurnAmount_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_epochs[KEY uint256 epochNonce].remainingWithdrawClaimAmount
    uint256 newValue (uint256 oldValue) {
    ghost_epoch_remainingWithdrawClaimAmount_StoreCount = ghost_epoch_remainingWithdrawClaimAmount_StoreCount + 1;
    ghost_epoch_remainingWithdrawClaimAmount_StoredKey = epochNonce;
    ghost_epoch_remainingWithdrawClaimAmount_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_epochs[KEY uint256 epochNonce].openedAtTimestamp uint256 newValue {
    ghost_epoch_openedAtTimestamp_StoreCount = ghost_epoch_openedAtTimestamp_StoreCount + 1;
    ghost_epoch_openedAtTimestamp_StoredKey = epochNonce;
    ghost_epoch_openedAtTimestamp_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_epochs[KEY uint256 epochNonce].status
    Types.EpochStatus newValue (Types.EpochStatus oldValue) {
    ghost_epoch_status_StoreCount = ghost_epoch_status_StoreCount + 1;
    ghost_epoch_status_StoredKey = epochNonce;
    ghost_epoch_status_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_deposits[KEY address depositor][KEY uint256 epochNonce] uint256 newValue {
    ghost_deposit_StoreCount = ghost_deposit_StoreCount + 1;
    ghost_deposit_StoredKeyDepositor = depositor;
    ghost_deposit_StoredKeyEpochNonce = epochNonce;
    ghost_deposit_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_withdraws[KEY address withdrawer][KEY uint256 epochNonce]
    uint256 newValue (uint256 oldValue) {
    ghost_withdraw_StoreCount = ghost_withdraw_StoreCount + 1;
    ghost_withdraw_StoredKeyWithdrawer = withdrawer;
    ghost_withdraw_StoredKeyEpochNonce = epochNonce;
    ghost_withdraw_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_supportedProtocol[KEY bytes32 protocolId] bool newValue {
    ghost_supportedProtocol_StoreCount = ghost_supportedProtocol_StoreCount + 1;
    ghost_supportedProtocol_StoredKey = protocolId;
    ghost_supportedProtocol_StoredValue = newValue;
}

/// ─────────────────────────── LOG HOOKS ────────────────────────────
/// LOG2 = topic0 + 1 indexed param
hook LOG2(uint offset, uint length, bytes32 t0, bytes32 t1) {
    if (t0 == EpochOpenEvent()) {
        ghost_EpochOpen_EventCount = ghost_EpochOpen_EventCount + 1;
        ghost_EpochOpen_Param_epochNonce = bytes32ToUint256(t1);
    } else if (t0 == EpochClaimableEvent()) {
        ghost_EpochClaimable_EventCount = ghost_EpochClaimable_EventCount + 1;
        ghost_EpochClaimable_Param_epochNonce = bytes32ToUint256(t1);
    } else if (t0 == TreasurySetEvent()) {
        ghost_TreasurySet_EventCount = ghost_TreasurySet_EventCount + 1;
        ghost_TreasurySet_Param_treasury = bytes32ToAddress(t1);
    } else if (t0 == PolicyEngineAttachedEvent()) {
        ghost_PolicyEngineAttached_EventCount = ghost_PolicyEngineAttached_EventCount + 1;
        ghost_PolicyEngineAttached_Param_policyEngine = bytes32ToAddress(t1);
    } else if (t0 == PolicyEngineDetachFailedEvent()) {
        ghost_PolicyEngineDetachFailed_EventCount = ghost_PolicyEngineDetachFailed_EventCount + 1;
        ghost_PolicyEngineDetachFailed_Param_policyEngine = bytes32ToAddress(t1);
    } else if (t0 == ActiveProtocolAdapterClearedEvent()) {
        ghost_ActiveProtocolAdapterCleared_EventCount = ghost_ActiveProtocolAdapterCleared_EventCount + 1;
        ghost_ActiveProtocolAdapterCleared_Param_adapter = bytes32ToAddress(t1);
    } else if (t0 == RebalanceDepositRecoveryClearedEvent()) {
        ghost_RebalanceDepositRecoveryCleared_EventCount = ghost_RebalanceDepositRecoveryCleared_EventCount + 1;
        ghost_RebalanceDepositRecoveryCleared_Param_rebalanceNonce = bytes32ToUint256(t1);
    }
}

/// LOG3 = topic0 + 2 indexed params
hook LOG3(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2) {
    if (t0 == EpochDepositExecutingEvent()) {
        ghost_EpochDepositExecuting_EventCount = ghost_EpochDepositExecuting_EventCount + 1;
        ghost_EpochDepositExecuting_Param_epochNonce = bytes32ToUint256(t1);
        ghost_EpochDepositExecuting_Param_amount = bytes32ToUint256(t2);
    } else if (t0 == EpochWithdrawExecutingEvent()) {
        ghost_EpochWithdrawExecuting_EventCount = ghost_EpochWithdrawExecuting_EventCount + 1;
        ghost_EpochWithdrawExecuting_Param_epochNonce = bytes32ToUint256(t1);
        ghost_EpochWithdrawExecuting_Param_amount = bytes32ToUint256(t2);
    } else if (t0 == ManagementFeeCollectedEvent()) {
        ghost_ManagementFeeCollected_EventCount = ghost_ManagementFeeCollected_EventCount + 1;
        ghost_ManagementFeeCollected_Param_rebalanceNonce = bytes32ToUint256(t1);
        ghost_ManagementFeeCollected_Param_feeShares = bytes32ToUint256(t2);
    } else if (t0 == EpochDepositToStrategySuccessEvent()) {
        ghost_EpochDepositToStrategySuccess_EventCount = ghost_EpochDepositToStrategySuccess_EventCount + 1;
        ghost_EpochDepositToStrategySuccess_Param_epochNonce = bytes32ToUint256(t1);
        ghost_EpochDepositToStrategySuccess_Param_amount = bytes32ToUint256(t2);
    } else if (t0 == EpochWithdrawFromStrategySuccessEvent()) {
        ghost_EpochWithdrawFromStrategySuccess_EventCount = ghost_EpochWithdrawFromStrategySuccess_EventCount + 1;
        ghost_EpochWithdrawFromStrategySuccess_Param_epochNonce = bytes32ToUint256(t1);
        ghost_EpochWithdrawFromStrategySuccess_Param_amount = bytes32ToUint256(t2);
    } else if (t0 == RebalanceWithdrawSuccessEvent()) {
        ghost_RebalanceWithdrawSuccess_EventCount = ghost_RebalanceWithdrawSuccess_EventCount + 1;
        ghost_RebalanceWithdrawSuccess_Param_rebalanceNonce = bytes32ToUint256(t1);
        ghost_RebalanceWithdrawSuccess_Param_amount = bytes32ToUint256(t2);
    } else if (t0 == RebalanceDepositSuccessEvent()) {
        ghost_RebalanceDepositSuccess_EventCount = ghost_RebalanceDepositSuccess_EventCount + 1;
        ghost_RebalanceDepositSuccess_Param_rebalanceNonce = bytes32ToUint256(t1);
        ghost_RebalanceDepositSuccess_Param_amount = bytes32ToUint256(t2);
    } else if (t0 == RebalanceDepositFailureEvent()) {
        ghost_RebalanceDepositFailure_EventCount = ghost_RebalanceDepositFailure_EventCount + 1;
        ghost_RebalanceDepositFailure_Param_rebalanceNonce = bytes32ToUint256(t1);
        ghost_RebalanceDepositFailure_Param_amount = bytes32ToUint256(t2);
    } else if (t0 == RebalanceDepositRecoveryStoredEvent()) {
        ghost_RebalanceDepositRecoveryStored_EventCount = ghost_RebalanceDepositRecoveryStored_EventCount + 1;
        ghost_RebalanceDepositRecoveryStored_Param_rebalanceNonce = bytes32ToUint256(t1);
        ghost_RebalanceDepositRecoveryStored_Param_amount = bytes32ToUint256(t2);
    } else if (t0 == InitialActiveProtocolAdapterSetEvent()) {
        ghost_InitialActiveProtocolAdapterSet_EventCount = ghost_InitialActiveProtocolAdapterSet_EventCount + 1;
        ghost_InitialActiveProtocolAdapterSet_Param_protocolId = t1;
        ghost_InitialActiveProtocolAdapterSet_Param_adapter = bytes32ToAddress(t2);
    } else if (t0 == SupportedProtocolSetEvent()) {
        ghost_SupportedProtocolSet_EventCount = ghost_SupportedProtocolSet_EventCount + 1;
        ghost_SupportedProtocolSet_Param_protocolId = t1;
        ghost_SupportedProtocolSet_Param_isSupported = bytes32ToBool(t2);
    } else if (t0 == ActiveProtocolAdapterSetEvent()) {
        ghost_ActiveProtocolAdapterSet_EventCount = ghost_ActiveProtocolAdapterSet_EventCount + 1;
        ghost_ActiveProtocolAdapterSet_Param_protocolId = t1;
        ghost_ActiveProtocolAdapterSet_Param_adapter = bytes32ToAddress(t2);
    }
}

/// LOG4 = topic0 + 3 indexed params
hook LOG4(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2, bytes32 t3) {
    if (t0 == DepositSubmittedEvent()) {
        ghost_DepositSubmitted_EventCount = ghost_DepositSubmitted_EventCount + 1;
        ghost_DepositSubmitted_Param_epochNonce = bytes32ToUint256(t1);
        ghost_DepositSubmitted_Param_depositor = bytes32ToAddress(t2);
        ghost_DepositSubmitted_Param_amount = bytes32ToUint256(t3);
    } else if (t0 == WithdrawSubmittedEvent()) {
        ghost_WithdrawSubmitted_EventCount = ghost_WithdrawSubmitted_EventCount + 1;
        ghost_WithdrawSubmitted_Param_epochNonce = bytes32ToUint256(t1);
        ghost_WithdrawSubmitted_Param_withdrawer = bytes32ToAddress(t2);
        ghost_WithdrawSubmitted_Param_shareBurnAmount = bytes32ToUint256(t3);
    } else if (t0 == DepositClaimedEvent()) {
        ghost_DepositClaimed_EventCount = ghost_DepositClaimed_EventCount + 1;
        ghost_DepositClaimed_Param_epochNonce = bytes32ToUint256(t1);
        ghost_DepositClaimed_Param_depositor = bytes32ToAddress(t2);
        ghost_DepositClaimed_Param_shareMintAmount = bytes32ToUint256(t3);
    } else if (t0 == WithdrawClaimedEvent()) {
        ghost_WithdrawClaimed_EventCount = ghost_WithdrawClaimed_EventCount + 1;
        ghost_WithdrawClaimed_Param_epochNonce = bytes32ToUint256(t1);
        ghost_WithdrawClaimed_Param_withdrawer = bytes32ToAddress(t2);
        ghost_WithdrawClaimed_Param_amount = bytes32ToUint256(t3);
    } else if (t0 == DepositCancelledEvent()) {
        ghost_DepositCancelled_EventCount = ghost_DepositCancelled_EventCount + 1;
        ghost_DepositCancelled_Param_epochNonce = bytes32ToUint256(t1);
        ghost_DepositCancelled_Param_depositor = bytes32ToAddress(t2);
        ghost_DepositCancelled_Param_amount = bytes32ToUint256(t3);
    } else if (t0 == WithdrawCancelledEvent()) {
        ghost_WithdrawCancelled_EventCount = ghost_WithdrawCancelled_EventCount + 1;
        ghost_WithdrawCancelled_Param_epochNonce = bytes32ToUint256(t1);
        ghost_WithdrawCancelled_Param_withdrawer = bytes32ToAddress(t2);
        ghost_WithdrawCancelled_Param_shareBurnAmount = bytes32ToUint256(t3);
    } else if (t0 == DepositForceCancelledEvent()) {
        ghost_DepositForceCancelled_EventCount = ghost_DepositForceCancelled_EventCount + 1;
        ghost_DepositForceCancelled_Param_epochNonce = bytes32ToUint256(t1);
        ghost_DepositForceCancelled_Param_depositor = bytes32ToAddress(t2);
        ghost_DepositForceCancelled_Param_amount = bytes32ToUint256(t3);
    } else if (t0 == EpochWithdrawAmountShortEvent()) {
        ghost_EpochWithdrawAmountShort_EventCount = ghost_EpochWithdrawAmountShort_EventCount + 1;
        ghost_EpochWithdrawAmountShort_Param_epochNonce = bytes32ToUint256(t1);
        ghost_EpochWithdrawAmountShort_Param_expectedAmount = bytes32ToUint256(t2);
        ghost_EpochWithdrawAmountShort_Param_actualAmount = bytes32ToUint256(t3);
    } else if (t0 == RebalanceInitiatedEvent()) {
        ghost_RebalanceInitiated_EventCount = ghost_RebalanceInitiated_EventCount + 1;
        ghost_RebalanceInitiated_Param_rebalanceNonce = bytes32ToUint256(t1);
        ghost_RebalanceInitiated_Param_protocolId = t2;
        ghost_RebalanceInitiated_Param_chainSelector = bytes32ToUint64(t3);
    } else if (t0 == RebalanceCompletedEvent()) {
        ghost_RebalanceCompleted_EventCount = ghost_RebalanceCompleted_EventCount + 1;
        ghost_RebalanceCompleted_Param_rebalanceNonce = bytes32ToUint256(t1);
        ghost_RebalanceCompleted_Param_newProtocolId = t2;
        ghost_RebalanceCompleted_Param_newChainSelector = bytes32ToUint64(t3);
    } else if (t0 == PerformanceFeeCollectedEvent()) {
        ghost_PerformanceFeeCollected_EventCount = ghost_PerformanceFeeCollected_EventCount + 1;
        ghost_PerformanceFeeCollected_Param_epochNonce = bytes32ToUint256(t1);
        ghost_PerformanceFeeCollected_Param_feeShares = bytes32ToUint256(t2);
        ghost_PerformanceFeeCollected_Param_settlementPricePerShare = bytes32ToUint256(t3);
    } else if (t0 == CCIPBridgedEvent()) {
        ghost_CCIPBridged_EventCount = ghost_CCIPBridged_EventCount + 1;
        ghost_CCIPBridged_Param_ccipMessageId = t1;
        ghost_CCIPBridged_Param_destinationChainSelector = bytes32ToUint64(t2);
        ghost_CCIPBridged_Param_ccipTxType = uint8ToCcipTxType(bytes32ToUint8(t3));
    } else if (t0 == CCIPReceivedEvent()) {
        ghost_CCIPReceived_EventCount = ghost_CCIPReceived_EventCount + 1;
        ghost_CCIPReceived_Param_ccipMessageId = t1;
        ghost_CCIPReceived_Param_sourceChainSelector = bytes32ToUint64(t2);
        ghost_CCIPReceived_Param_ccipTxType = uint8ToCcipTxType(bytes32ToUint8(t3));
    }
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/

/// ─────────────────── CONSTRUCTOR IMMUTABLES ──────────────────

rule CFG_001_UPGRADE_005_constructor_getShare() {
    assert getShare() == share;
}

rule constructor_getSharePrecision() {
    assert getSharePrecision() == 1000000000000000000;
}

/// ─────────────────── INITIALIZE PARENT VAULT ─────────────────

/// @notice ParentVault initialization reverts during an active non-reentrant execution
rule initialize_RevertWhen_ReentrantCall() {
    env e;
    BaseVault.InitParams params;
    address treasury;
    address policyEngineManager;
    address newPolicyEngine;
    address cancelDepositOperator;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !isInitialized(), "contract should not be initialized";
    require !isInitializing(), "contract should not be initializing";
    require defaultAdmin() == 0, "default admin should not be initialized";
    require params.defaultAdmin != 0, "default admin should not be zero";
    require params.pauser != 0, "pauser should not be zero";
    require params.unpauser != 0, "unpauser should not be zero";
    require params.configOperator != 0, "config operator should not be zero";
    require params.upgrader != 0, "upgrader should not be zero";
    require params.initialDefaultCcipGasLimit != 0, "default CCIP gas limit should not be zero";
    require treasury != 0, "treasury should not be zero";
    require policyEngineManager != 0, "policy engine manager should not be zero";
    require newPolicyEngine != 0, "policy engine should not be zero";
    require cancelDepositOperator != 0, "cancel deposit operator should not be zero";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";

    initialize@withrevert(e, params, treasury, policyEngineManager, newPolicyEngine, cancelDepositOperator);

    assert lastReverted;
}

/// @notice ParentVault initialization reverts when Initializable is already in its initializing state
rule initialize_RevertWhen_AlreadyInitializing() {
    env e;
    BaseVault.InitParams params;
    address treasury;
    address policyEngineManager;
    address newPolicyEngine;
    address cancelDepositOperator;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !isInitialized(), "contract should not be initialized";
    require defaultAdmin() == 0, "default admin should not be initialized";
    require params.defaultAdmin != 0, "default admin should not be zero";
    require params.pauser != 0, "pauser should not be zero";
    require params.unpauser != 0, "unpauser should not be zero";
    require params.configOperator != 0, "config operator should not be zero";
    require params.upgrader != 0, "upgrader should not be zero";
    require params.initialDefaultCcipGasLimit != 0, "default CCIP gas limit should not be zero";
    require treasury != 0, "treasury should not be zero";
    require policyEngineManager != 0, "policy engine manager should not be zero";
    require newPolicyEngine != 0, "policy engine should not be zero";
    require cancelDepositOperator != 0, "cancel deposit operator should not be zero";

    /// @dev revert condition being verified
    require isInitializing(), "contract should already be initializing";

    initialize@withrevert(e, params, treasury, policyEngineManager, newPolicyEngine, cancelDepositOperator);

    assert lastReverted;
}

/// @notice ParentVault initialization reverts when AccessControl already has a default admin
rule initialize_RevertWhen_DefaultAdminAlreadySet() {
    env e;
    BaseVault.InitParams params;
    address treasury;
    address policyEngineManager;
    address newPolicyEngine;
    address cancelDepositOperator;

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
    require treasury != 0, "treasury should not be zero";
    require policyEngineManager != 0, "policy engine manager should not be zero";
    require newPolicyEngine != 0, "policy engine should not be zero";
    require cancelDepositOperator != 0, "cancel deposit operator should not be zero";

    /// @dev revert condition being verified
    require defaultAdmin() != 0, "default admin should already be set";

    initialize@withrevert(e, params, treasury, policyEngineManager, newPolicyEngine, cancelDepositOperator);

    assert lastReverted;
}

/// @notice ParentVault initialization reverts when the default admin is zero
/// @dev Verifies both BaseVault's zero-address guard and Ownable's invalid-initial-owner condition
rule CFG_001_initialize_RevertWhen_DefaultAdminIsZeroAddress() {
    env e;
    BaseVault.InitParams params;
    address treasury;
    address policyEngineManager;
    address newPolicyEngine;
    address cancelDepositOperator;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !isInitialized(), "contract should not be initialized";
    require !isInitializing(), "contract should not be initializing";
    require defaultAdmin() == 0, "default admin should not be initialized";
    require params.pauser != 0, "pauser should not be zero";
    require params.unpauser != 0, "unpauser should not be zero";
    require params.configOperator != 0, "config operator should not be zero";
    require params.upgrader != 0, "upgrader should not be zero";
    require params.initialDefaultCcipGasLimit != 0, "default CCIP gas limit should not be zero";
    require treasury != 0, "treasury should not be zero";
    require policyEngineManager != 0, "policy engine manager should not be zero";
    require newPolicyEngine != 0, "policy engine should not be zero";
    require cancelDepositOperator != 0, "cancel deposit operator should not be zero";

    /// @dev revert condition being verified
    require params.defaultAdmin == 0, "default admin should be zero";

    initialize@withrevert(e, params, treasury, policyEngineManager, newPolicyEngine, cancelDepositOperator);

    assert lastReverted;
}

/// @notice ParentVault initialization reverts when the pauser is zero
rule CFG_001_initialize_RevertWhen_PauserIsZeroAddress() {
    env e;
    BaseVault.InitParams params;
    address treasury;
    address policyEngineManager;
    address newPolicyEngine;
    address cancelDepositOperator;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !isInitialized(), "contract should not be initialized";
    require !isInitializing(), "contract should not be initializing";
    require defaultAdmin() == 0, "default admin should not be initialized";
    require params.defaultAdmin != 0, "default admin should not be zero";
    require params.unpauser != 0, "unpauser should not be zero";
    require params.configOperator != 0, "config operator should not be zero";
    require params.upgrader != 0, "upgrader should not be zero";
    require params.initialDefaultCcipGasLimit != 0, "default CCIP gas limit should not be zero";
    require treasury != 0, "treasury should not be zero";
    require policyEngineManager != 0, "policy engine manager should not be zero";
    require newPolicyEngine != 0, "policy engine should not be zero";
    require cancelDepositOperator != 0, "cancel deposit operator should not be zero";

    /// @dev revert condition being verified
    require params.pauser == 0, "pauser should be zero";

    initialize@withrevert(e, params, treasury, policyEngineManager, newPolicyEngine, cancelDepositOperator);

    assert lastReverted;
}

/// @notice ParentVault initialization reverts when the unpauser is zero
rule CFG_001_initialize_RevertWhen_UnpauserIsZeroAddress() {
    env e;
    BaseVault.InitParams params;
    address treasury;
    address policyEngineManager;
    address newPolicyEngine;
    address cancelDepositOperator;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !isInitialized(), "contract should not be initialized";
    require !isInitializing(), "contract should not be initializing";
    require defaultAdmin() == 0, "default admin should not be initialized";
    require params.defaultAdmin != 0, "default admin should not be zero";
    require params.pauser != 0, "pauser should not be zero";
    require params.configOperator != 0, "config operator should not be zero";
    require params.upgrader != 0, "upgrader should not be zero";
    require params.initialDefaultCcipGasLimit != 0, "default CCIP gas limit should not be zero";
    require treasury != 0, "treasury should not be zero";
    require policyEngineManager != 0, "policy engine manager should not be zero";
    require newPolicyEngine != 0, "policy engine should not be zero";
    require cancelDepositOperator != 0, "cancel deposit operator should not be zero";

    /// @dev revert condition being verified
    require params.unpauser == 0, "unpauser should be zero";

    initialize@withrevert(e, params, treasury, policyEngineManager, newPolicyEngine, cancelDepositOperator);

    assert lastReverted;
}

/// @notice ParentVault initialization reverts when the config operator is zero
rule CFG_001_initialize_RevertWhen_ConfigOperatorIsZeroAddress() {
    env e;
    BaseVault.InitParams params;
    address treasury;
    address policyEngineManager;
    address newPolicyEngine;
    address cancelDepositOperator;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !isInitialized(), "contract should not be initialized";
    require !isInitializing(), "contract should not be initializing";
    require defaultAdmin() == 0, "default admin should not be initialized";
    require params.defaultAdmin != 0, "default admin should not be zero";
    require params.pauser != 0, "pauser should not be zero";
    require params.unpauser != 0, "unpauser should not be zero";
    require params.upgrader != 0, "upgrader should not be zero";
    require params.initialDefaultCcipGasLimit != 0, "default CCIP gas limit should not be zero";
    require treasury != 0, "treasury should not be zero";
    require policyEngineManager != 0, "policy engine manager should not be zero";
    require newPolicyEngine != 0, "policy engine should not be zero";
    require cancelDepositOperator != 0, "cancel deposit operator should not be zero";

    /// @dev revert condition being verified
    require params.configOperator == 0, "config operator should be zero";

    initialize@withrevert(e, params, treasury, policyEngineManager, newPolicyEngine, cancelDepositOperator);

    assert lastReverted;
}

/// @notice ParentVault initialization reverts when the upgrader is zero
rule CFG_001_initialize_RevertWhen_UpgraderIsZeroAddress() {
    env e;
    BaseVault.InitParams params;
    address treasury;
    address policyEngineManager;
    address newPolicyEngine;
    address cancelDepositOperator;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !isInitialized(), "contract should not be initialized";
    require !isInitializing(), "contract should not be initializing";
    require defaultAdmin() == 0, "default admin should not be initialized";
    require params.defaultAdmin != 0, "default admin should not be zero";
    require params.pauser != 0, "pauser should not be zero";
    require params.unpauser != 0, "unpauser should not be zero";
    require params.configOperator != 0, "config operator should not be zero";
    require params.initialDefaultCcipGasLimit != 0, "default CCIP gas limit should not be zero";
    require treasury != 0, "treasury should not be zero";
    require policyEngineManager != 0, "policy engine manager should not be zero";
    require newPolicyEngine != 0, "policy engine should not be zero";
    require cancelDepositOperator != 0, "cancel deposit operator should not be zero";

    /// @dev revert condition being verified
    require params.upgrader == 0, "upgrader should be zero";

    initialize@withrevert(e, params, treasury, policyEngineManager, newPolicyEngine, cancelDepositOperator);

    assert lastReverted;
}

/// @notice ParentVault initialization reverts when the initial default CCIP gas limit is zero
rule CFG_004_initialize_RevertWhen_InitialDefaultCcipGasLimitIsZero() {
    env e;
    BaseVault.InitParams params;
    address treasury;
    address policyEngineManager;
    address newPolicyEngine;
    address cancelDepositOperator;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !isInitialized(), "contract should not be initialized";
    require !isInitializing(), "contract should not be initializing";
    require defaultAdmin() == 0, "default admin should not be initialized";
    require params.defaultAdmin != 0, "default admin should not be zero";
    require params.pauser != 0, "pauser should not be zero";
    require params.unpauser != 0, "unpauser should not be zero";
    require params.configOperator != 0, "config operator should not be zero";
    require params.upgrader != 0, "upgrader should not be zero";
    require treasury != 0, "treasury should not be zero";
    require policyEngineManager != 0, "policy engine manager should not be zero";
    require newPolicyEngine != 0, "policy engine should not be zero";
    require cancelDepositOperator != 0, "cancel deposit operator should not be zero";

    /// @dev revert condition being verified
    require params.initialDefaultCcipGasLimit == 0, "default CCIP gas limit should be zero";

    initialize@withrevert(e, params, treasury, policyEngineManager, newPolicyEngine, cancelDepositOperator);

    assert lastReverted;
}

/// @notice ParentVault initialization reverts when the contract has already been initialized
/// @dev Verifies that repeated initialization leaves all vault state unchanged
rule UPGRADE_002_initialize_RevertWhen_AlreadyInitialized() {
    env e;
    BaseVault.InitParams params;
    address treasury;
    address policyEngineManager;
    address newPolicyEngine;
    address cancelDepositOperator;

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
    require treasury != 0, "treasury should not be zero";
    require policyEngineManager != 0, "policy engine manager should not be zero";
    require newPolicyEngine != 0, "policy engine should not be zero";
    require cancelDepositOperator != 0, "cancel deposit operator should not be zero";

    /// @dev revert condition being verified
    require isInitialized(), "contract should already be initialized";

    initialize@withrevert(e, params, treasury, policyEngineManager, newPolicyEngine, cancelDepositOperator);

    assert lastReverted;
}

/// @notice ParentVault initialization reverts when the treasury address is zero
/// @dev Verifies that a malformed treasury argument leaves all vault state unchanged
rule CFG_001_initialize_RevertWhen_TreasuryIsZeroAddress() {
    env e;
    BaseVault.InitParams params;
    address treasury;
    address policyEngineManager;
    address newPolicyEngine;
    address cancelDepositOperator;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !isInitialized(), "contract should not be initialized";
    require !isInitializing(), "contract should not be initializing";
    require defaultAdmin() == 0, "default admin should not be initialized";
    require params.defaultAdmin != 0, "default admin should not be zero";
    require params.pauser != 0, "pauser should not be zero";
    require params.unpauser != 0, "unpauser should not be zero";
    require params.configOperator != 0, "config operator should not be zero";
    require params.upgrader != 0, "upgrader should not be zero";
    require params.initialDefaultCcipGasLimit != 0, "default CCIP gas limit should not be zero";
    require policyEngineManager != 0, "policy engine manager should not be zero";
    require newPolicyEngine != 0, "policy engine should not be zero";
    require cancelDepositOperator != 0, "cancel deposit operator should not be zero";

    /// @dev revert condition being verified
    require treasury == 0, "treasury should be zero";

    initialize@withrevert(e, params, treasury, policyEngineManager, newPolicyEngine, cancelDepositOperator);

    assert lastReverted;
}

/// @notice ParentVault initialization reverts when the policy engine manager address is zero
/// @dev Verifies that a malformed policyEngineManager argument leaves all vault state unchanged
rule CFG_001_initialize_RevertWhen_PolicyEngineManagerIsZeroAddress() {
    env e;
    BaseVault.InitParams params;
    address treasury;
    address policyEngineManager;
    address newPolicyEngine;
    address cancelDepositOperator;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !isInitialized(), "contract should not be initialized";
    require !isInitializing(), "contract should not be initializing";
    require defaultAdmin() == 0, "default admin should not be initialized";
    require params.defaultAdmin != 0, "default admin should not be zero";
    require params.pauser != 0, "pauser should not be zero";
    require params.unpauser != 0, "unpauser should not be zero";
    require params.configOperator != 0, "config operator should not be zero";
    require params.upgrader != 0, "upgrader should not be zero";
    require params.initialDefaultCcipGasLimit != 0, "default CCIP gas limit should not be zero";
    require treasury != 0, "treasury should not be zero";
    require newPolicyEngine != 0, "policy engine should not be zero";
    require cancelDepositOperator != 0, "cancel deposit operator should not be zero";

    /// @dev revert condition being verified
    require policyEngineManager == 0, "policy engine manager should be zero";

    initialize@withrevert(e, params, treasury, policyEngineManager, newPolicyEngine, cancelDepositOperator);

    assert lastReverted;
}

/// @notice ParentVault initialization reverts when the policy engine address is zero
/// @dev Verifies that a malformed policyEngine argument leaves all vault state unchanged
rule CFG_001_initialize_RevertWhen_PolicyEngineIsZeroAddress() {
    env e;
    BaseVault.InitParams params;
    address treasury;
    address policyEngineManager;
    address newPolicyEngine;
    address cancelDepositOperator;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !isInitialized(), "contract should not be initialized";
    require !isInitializing(), "contract should not be initializing";
    require defaultAdmin() == 0, "default admin should not be initialized";
    require params.defaultAdmin != 0, "default admin should not be zero";
    require params.pauser != 0, "pauser should not be zero";
    require params.unpauser != 0, "unpauser should not be zero";
    require params.configOperator != 0, "config operator should not be zero";
    require params.upgrader != 0, "upgrader should not be zero";
    require params.initialDefaultCcipGasLimit != 0, "default CCIP gas limit should not be zero";
    require treasury != 0, "treasury should not be zero";
    require policyEngineManager != 0, "policy engine manager should not be zero";
    require cancelDepositOperator != 0, "cancel deposit operator should not be zero";

    /// @dev revert condition being verified
    require newPolicyEngine == 0, "policy engine should be zero";

    initialize@withrevert(e, params, treasury, policyEngineManager, newPolicyEngine, cancelDepositOperator);

    assert lastReverted;
}

/// @notice ParentVault initialization reverts when the cancel-deposit operator is zero
rule CFG_001_initialize_RevertWhen_CancelDepositOperatorIsZeroAddress() {
    env e;
    BaseVault.InitParams params;
    address treasury;
    address policyEngineManager;
    address newPolicyEngine;
    address cancelDepositOperator;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !isInitialized(), "contract should not be initialized";
    require !isInitializing(), "contract should not be initializing";
    require defaultAdmin() == 0, "default admin should not be initialized";
    require params.defaultAdmin != 0, "default admin should not be zero";
    require params.pauser != 0, "pauser should not be zero";
    require params.unpauser != 0, "unpauser should not be zero";
    require params.configOperator != 0, "config operator should not be zero";
    require params.upgrader != 0, "upgrader should not be zero";
    require params.initialDefaultCcipGasLimit != 0, "default CCIP gas limit should not be zero";
    require treasury != 0, "treasury should not be zero";
    require policyEngineManager != 0, "policy engine manager should not be zero";
    require newPolicyEngine != 0, "policy engine should not be zero";

    /// @dev revert condition being verified
    require cancelDepositOperator == 0, "cancel deposit operator should be zero";

    initialize@withrevert(e, params, treasury, policyEngineManager, newPolicyEngine, cancelDepositOperator);

    assert lastReverted;
}

/// @notice ParentVault initialization sets up epoch 1, rebalance nonce 1, performance fee high water
///         mark, treasury, and grants POLICY_ENGINE_MANAGER_ROLE, and attaches the policy engine
/// @dev __PolicyProtected_init attaches the policy engine as its very first attach (no prior engine),
///      so only PolicyEngineAttached fires, not PolicyEngineDetachFailed.
rule NONCE_008_UPGRADE_003_initialize_Success() {
    env e;
    BaseVault.InitParams params;
    address treasury;
    address policyEngineManager;
    address newPolicyEngine;
    address cancelDepositOperator;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !isInitialized(), "contract should not be initialized";
    require !isInitializing(), "contract should not be initializing";
    require defaultAdmin() == 0, "default admin should not be initialized";
    require params.defaultAdmin != 0, "default admin should not be zero";
    require params.pauser != 0, "pauser should not be zero";
    require params.unpauser != 0, "unpauser should not be zero";
    require params.configOperator != 0, "config operator should not be zero";
    require params.upgrader != 0, "upgrader should not be zero";
    require params.initialDefaultCcipGasLimit != 0, "default CCIP gas limit should not be zero";
    require treasury != 0, "treasury should not be zero";
    require policyEngineManager != 0, "policy engine manager should not be zero";
    require newPolicyEngine != 0, "policy engine should not be zero";
    require newPolicyEngine == policyEngine, "policy engine should be the mock policy engine";
    require getPolicyEngine() == 0, "policy engine storage should be uninitialized";
    require cancelDepositOperator != 0, "cancel deposit operator should not be zero";

    /// @dev set ghost starting values
    require ghost_PolicyEngineAttached_EventCount == 0;
    require ghost_PolicyEngineDetachFailed_EventCount == 0;
    require ghost_treasury_StoreCount == 0;
    require ghost_epochNonce_StoreCount == 0;
    require ghost_epoch_status_StoreCount == 0;
    require ghost_epoch_openedAtTimestamp_StoreCount == 0;
    require ghost_rebalance_nonce_StoreCount == 0;
    require ghost_rebalance_lastRebalanceCompletedTimestamp_StoreCount == 0;
    require ghost_performanceFeeHighWaterMark_StoreCount == 0;

    initialize@withrevert(e, params, treasury, policyEngineManager, newPolicyEngine, cancelDepositOperator);

    assert !lastReverted;
    assert isInitialized();
    assert getEpochNonce() == 1;
    assert getEpoch(1).status == Types.EpochStatus.OPEN;
    assert getEpoch(1).openedAtTimestamp == e.block.timestamp;
    assert getPerformanceFeeHighWaterMark() == getAssetPrecision();
    assert getRebalance().nonce == 1;
    assert getRebalance().lastRebalanceCompletedTimestamp == e.block.timestamp;
    assert getTreasury() == treasury;
    assert owner() == params.defaultAdmin;
    assert owner() == defaultAdmin();
    assert hasRole(POLICY_ENGINE_MANAGER_ROLE(), policyEngineManager);
    assert hasRole(CANCEL_DEPOSIT_OPERATOR_ROLE(), cancelDepositOperator);
    assert getPolicyEngine() == newPolicyEngine;
    assert ghost_PolicyEngineAttached_EventCount == 1;
    assert ghost_PolicyEngineAttached_Param_policyEngine == newPolicyEngine;
    assert ghost_PolicyEngineDetachFailed_EventCount == 0;
}

/// ─────────────── SET INITIAL ACTIVE PROTOCOL ADAPTER ──────────

/// @notice Setting the initial active protocol adapter reverts when the caller lacks DEFAULT_ADMIN_ROLE
/// @dev Verifies that an unauthorized call leaves all vault state unchanged
rule setInitialActiveProtocolAdapter_RevertWhen_CallerDoesNotHaveDEFAULT_ADMIN_ROLE() {
    env e;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !getInitialActiveProtocolAdapterSet(), "initial active protocol adapter should not already be set";
    require adapterRegistry.getAdapter(e, protocolId) == adapter, "target adapter should be registered";
    require adapter.getVault() == currentContract, "target adapter should be bound to the vault";

    /// @dev revert condition being verified
    require !hasRole(DEFAULT_ADMIN_ROLE(), e.msg.sender);

    setInitialActiveProtocolAdapter@withrevert(e, protocolId);

    assert lastReverted;
}

/// @notice Setting the initial active protocol adapter reverts when called during an active non-reentrant execution
/// @dev Verifies that a reentrant call leaves all vault state unchanged
rule setInitialActiveProtocolAdapter_RevertWhen_ReentrantCall() {
    env e;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(DEFAULT_ADMIN_ROLE(), e.msg.sender);
    require !getInitialActiveProtocolAdapterSet(), "initial active protocol adapter should not already be set";
    require adapterRegistry.getAdapter(e, protocolId) == adapter, "target adapter should be registered";
    require adapter.getVault() == currentContract, "target adapter should be bound to the vault";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";

    setInitialActiveProtocolAdapter@withrevert(e, protocolId);

    assert lastReverted;
}

/// @notice Setting the initial active protocol adapter reverts when it has already been set
/// @dev Verifies the one-time setter guard leaves all vault state unchanged
rule UPGRADE_004_setInitialActiveProtocolAdapter_RevertWhen_AlreadySet() {
    env e;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(DEFAULT_ADMIN_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require adapterRegistry.getAdapter(e, protocolId) == adapter, "target adapter should be registered";
    require adapter.getVault() == currentContract, "target adapter should be bound to the vault";

    /// @dev revert condition being verified
    require getInitialActiveProtocolAdapterSet(), "initial active protocol adapter should already be set";

    setInitialActiveProtocolAdapter@withrevert(e, protocolId);

    assert lastReverted;
}

/// @notice Setting the initial active protocol adapter reverts when the target protocol has no registered adapter
/// @dev Verifies that an unregistered protocol leaves all vault state unchanged
rule ADAPTER_002_setInitialActiveProtocolAdapter_RevertWhen_TargetAdapterNotRegistered() {
    env e;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(DEFAULT_ADMIN_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !getInitialActiveProtocolAdapterSet(), "initial active protocol adapter should not already be set";

    /// @dev revert condition being verified
    require adapterRegistry.getAdapter(e, protocolId) == 0, "target adapter should not be registered";

    setInitialActiveProtocolAdapter@withrevert(e, protocolId);

    assert lastReverted;
}

/// @notice Setting the initial active protocol adapter reverts when the registered adapter is bound to another vault
/// @dev Verifies that a misconfigured adapter registration leaves all vault state unchanged
rule ADAPTER_002_setInitialActiveProtocolAdapter_RevertWhen_TargetAdapterVaultIsInvalid() {
    env e;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(DEFAULT_ADMIN_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !getInitialActiveProtocolAdapterSet(), "initial active protocol adapter should not already be set";
    require invalidAdapter.getVault() != currentContract, "target adapter should not be bound to this vault";

    /// @dev revert condition being verified
    require adapterRegistry.getAdapter(e, protocolId) == invalidAdapter, "invalid target adapter should be registered";

    setInitialActiveProtocolAdapter@withrevert(e, protocolId);

    assert lastReverted;
}

/// @notice Setting the initial active protocol adapter registers the adapter, marks the one-time setter as
///         used, and seeds the active strategy to this chain
rule ADAPTER_002_UPGRADE_004_setInitialActiveProtocolAdapter_Success() {
    env e;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(DEFAULT_ADMIN_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !getInitialActiveProtocolAdapterSet(), "initial active protocol adapter should not already be set";
    require adapterRegistry.getAdapter(e, protocolId) == adapter, "target adapter should be registered";
    require adapter.getVault() == currentContract, "target adapter should be bound to the vault";

    /// @dev set ghost starting values
    require ghost_InitialActiveProtocolAdapterSet_EventCount == 0;
    require ghost_ActiveProtocolAdapterSet_EventCount == 0;
    require ghost_initialActiveProtocolAdapterSet_StoreCount == 0;
    require ghost_rebalance_activeStrategy_protocolId_StoreCount == 0;
    require ghost_rebalance_activeStrategy_chainSelector_StoreCount == 0;

    setInitialActiveProtocolAdapter@withrevert(e, protocolId);

    assert !lastReverted;
    assert getInitialActiveProtocolAdapterSet();
    assert getActiveProtocolAdapter() == adapter;
    assert getRebalance().activeStrategy.protocolId == protocolId;
    assert getRebalance().activeStrategy.chainSelector == getThisChainSelector();
    assert ghost_ActiveProtocolAdapterSet_EventCount == 1;
    assert ghost_ActiveProtocolAdapterSet_Param_protocolId == protocolId;
    assert ghost_ActiveProtocolAdapterSet_Param_adapter == adapter;
    assert ghost_InitialActiveProtocolAdapterSet_EventCount == 1;
    assert ghost_InitialActiveProtocolAdapterSet_Param_protocolId == protocolId;
    assert ghost_InitialActiveProtocolAdapterSet_Param_adapter == adapter;
}

/// ─────────────────────── SET TREASURY ──────────────────────────

/// @notice Setting the treasury reverts when the caller lacks CONFIG_OPERATOR_ROLE
/// @dev Verifies that an unauthorized call leaves all vault state unchanged
rule setTreasury_RevertWhen_CallerDoesNotHaveCONFIG_OPERATOR_ROLE() {
    env e;
    address treasury;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require treasury != 0, "treasury should not be zero";

    /// @dev revert condition being verified
    require !hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender);

    setTreasury@withrevert(e, treasury);

    assert lastReverted;
}

/// @notice Setting the treasury reverts when the new treasury address is zero
/// @dev Verifies that a malformed treasury argument leaves all vault state unchanged
rule setTreasury_RevertWhen_TreasuryIsZeroAddress() {
    env e;
    address treasury;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender);

    /// @dev revert condition being verified
    require treasury == 0, "treasury should be zero";

    setTreasury@withrevert(e, treasury);

    assert lastReverted;
}

/// @notice Setting the treasury updates the stored treasury address and emits TreasurySet
rule setTreasury_Success() {
    env e;
    address treasury;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender);
    require treasury != 0, "treasury should not be zero";

    /// @dev set ghost starting values
    require ghost_TreasurySet_EventCount == 0;
    require ghost_treasury_StoreCount == 0;

    setTreasury@withrevert(e, treasury);

    assert !lastReverted;
    assert getTreasury() == treasury;
    assert ghost_TreasurySet_EventCount == 1;
    assert ghost_TreasurySet_Param_treasury == treasury;
}

/// ─────────────────── SET SUPPORTED PROTOCOL ───────────────────

/// @notice Setting protocol support reverts when the caller lacks CONFIG_OPERATOR_ROLE
/// @dev Verifies that an unauthorized call leaves all vault state unchanged
rule setSupportedProtocol_RevertWhen_CallerDoesNotHaveCONFIG_OPERATOR_ROLE() {
    env e;
    bytes32 protocolId;
    bool isSupported;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require protocolId != to_bytes32(0), "protocol id should not be zero";
    require isSupported || protocolId != getRebalance().activeStrategy.protocolId,
        "should not be removing the active protocol";
    require isSupported || protocolId != getRebalance().pendingStrategy.protocolId,
        "should not be removing the pending protocol";

    /// @dev revert condition being verified
    require !hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender);

    setSupportedProtocol@withrevert(e, protocolId, isSupported);

    assert lastReverted;
}

/// @notice Setting protocol support reverts when the protocol ID is zero
/// @dev Verifies that a malformed protocol ID leaves all vault state unchanged
rule setSupportedProtocol_RevertWhen_ProtocolIdIsZero() {
    env e;
    bytes32 protocolId;
    bool isSupported;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender);

    /// @dev revert condition being verified
    require protocolId == to_bytes32(0), "protocol id should be zero";

    setSupportedProtocol@withrevert(e, protocolId, isSupported);

    assert lastReverted;
}

/// @notice Removing protocol support reverts when the protocol is only the active strategy protocol
/// @dev The separate active-and-pending rule covers the overlapping state independently of guard order.
rule setSupportedProtocol_RevertWhen_RemovingActiveProtocol() {
    env e;
    bytes32 protocolId;
    bool isSupported;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender);
    require protocolId != to_bytes32(0), "protocol id should not be zero";
    require protocolId != getRebalance().pendingStrategy.protocolId,
        "protocol id should not match the pending strategy protocol";

    /// @dev revert condition being verified
    require !isSupported, "protocol support should be disabled";
    require protocolId == getRebalance().activeStrategy.protocolId,
        "protocol id should match the active strategy protocol";

    setSupportedProtocol@withrevert(e, protocolId, isSupported);

    assert lastReverted;
}

/// @notice Removing protocol support reverts when the protocol is only the pending strategy protocol
/// @dev The separate active-and-pending rule covers the overlapping state independently of guard order.
rule setSupportedProtocol_RevertWhen_RemovingPendingProtocol() {
    env e;
    bytes32 protocolId;
    bool isSupported;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender);
    require protocolId != to_bytes32(0), "protocol id should not be zero";
    require protocolId != getRebalance().activeStrategy.protocolId,
        "protocol id should not match the active strategy protocol";

    /// @dev revert condition being verified
    require !isSupported, "protocol support should be disabled";
    require protocolId == getRebalance().pendingStrategy.protocolId,
        "protocol id should match the pending strategy protocol";

    setSupportedProtocol@withrevert(e, protocolId, isSupported);

    assert lastReverted;
}

/// @notice Enabling protocol support sets the protocol's supported flag and emits SupportedProtocolSet
/// @dev Verifies that enabling support succeeds even when the protocol is active or pending, because
///      the active/pending removal guards apply only when disabling support.
rule setSupportedProtocol_Success_WhenEnablingProtocol() {
    env e;
    bytes32 protocolId;
    bool isSupported;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender);
    require protocolId != to_bytes32(0), "protocol id should not be zero";

    /// @dev success condition being verified
    require isSupported, "protocol support should be enabled";

    /// @dev set ghost starting values
    require ghost_SupportedProtocolSet_EventCount == 0;

    setSupportedProtocol@withrevert(e, protocolId, isSupported);

    assert !lastReverted;
    assert getSupportedProtocol(protocolId);
    assert ghost_SupportedProtocolSet_EventCount == 1;
    assert ghost_SupportedProtocolSet_Param_protocolId == protocolId;
    assert ghost_SupportedProtocolSet_Param_isSupported;
}

/// @notice Disabling protocol support sets the protocol's supported flag to false and emits SupportedProtocolSet
/// @dev Verifies that disabling support succeeds only when the protocol is neither active nor pending
rule setSupportedProtocol_Success_WhenDisablingInactiveNonPendingProtocol() {
    env e;
    bytes32 protocolId;
    bool isSupported;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender);
    require protocolId != to_bytes32(0), "protocol id should not be zero";
    require protocolId != getRebalance().activeStrategy.protocolId,
        "protocol id should not match the active strategy protocol";
    require protocolId != getRebalance().pendingStrategy.protocolId,
        "protocol id should not match the pending strategy protocol";

    /// @dev success condition being verified
    require !isSupported, "protocol support should be disabled";

    /// @dev set ghost starting values
    require ghost_SupportedProtocolSet_EventCount == 0;

    setSupportedProtocol@withrevert(e, protocolId, isSupported);

    assert !lastReverted;
    assert !getSupportedProtocol(protocolId);
    assert ghost_SupportedProtocolSet_EventCount == 1;
    assert ghost_SupportedProtocolSet_Param_protocolId == protocolId;
    assert !ghost_SupportedProtocolSet_Param_isSupported;
}

/// ───────────────────── ATTACH POLICY ENGINE ───────────────────

/// @notice Attaching a policy engine reverts when the caller lacks POLICY_ENGINE_MANAGER_ROLE
/// @dev Verifies that an unauthorized call leaves all vault state unchanged
rule attachPolicyEngine_RevertWhen_CallerDoesNotHavePOLICY_ENGINE_MANAGER_ROLE() {
    env e;
    address newPolicyEngine;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require newPolicyEngine != 0, "policy engine should not be zero";
    require newPolicyEngine != currentContract, "policy engine should not be the vault";

    /// @dev revert condition being verified
    require !hasRole(POLICY_ENGINE_MANAGER_ROLE(), e.msg.sender);

    attachPolicyEngine@withrevert(e, newPolicyEngine);

    assert lastReverted;
}

/// @notice Attaching a policy engine reverts when the new policy engine address is zero
/// @dev Verifies that a malformed policy engine argument leaves all vault state unchanged
rule CFG_001_attachPolicyEngine_RevertWhen_PolicyEngineIsZeroAddress() {
    env e;
    address newPolicyEngine;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(POLICY_ENGINE_MANAGER_ROLE(), e.msg.sender);

    /// @dev revert condition being verified
    require newPolicyEngine == 0, "policy engine should be zero";

    attachPolicyEngine@withrevert(e, newPolicyEngine);

    assert lastReverted;
}

/// @notice Attaching a policy engine stores the new engine and emits PolicyEngineAttached
/// @dev Verifies the clean attach path. The mock policy engine's attach/detach calls do not revert,
///      so replacing an existing engine should not emit PolicyEngineDetachFailed.
/// @dev NOT verified: the PolicyEngineDetachFailed branch (old engine's detach() reverting). This is
///      currently unreachable because MockPolicyEngine.detach() is hardcoded to never revert.
rule attachPolicyEngine_Success() {
    env e;
    address newPolicyEngine;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(POLICY_ENGINE_MANAGER_ROLE(), e.msg.sender);
    require newPolicyEngine == policyEngine, "policy engine should be the mock policy engine";
    require newPolicyEngine != 0, "policy engine should not be zero";
    require newPolicyEngine != currentContract, "policy engine should not be the vault";

    /// @dev set ghost starting values
    require ghost_PolicyEngineAttached_EventCount == 0;
    require ghost_PolicyEngineDetachFailed_EventCount == 0;

    attachPolicyEngine@withrevert(e, newPolicyEngine);

    assert !lastReverted;
    assert getPolicyEngine() == newPolicyEngine;
    assert ghost_PolicyEngineAttached_EventCount == 1;
    assert ghost_PolicyEngineAttached_Param_policyEngine == newPolicyEngine;
    assert ghost_PolicyEngineDetachFailed_EventCount == 0;
}

/// ────────────────────── SUPPORTS INTERFACE ────────────────────

/// @notice ParentVault reports support for its expected ERC165 interfaces
/// @dev Verifies the positive supportsInterface cases: IERC165,
///      IAccessControlDefaultAdminRules, IAny2EVMMessageReceiver, and IPolicyProtected.
rule supportsInterface_Success_WhenInterfaceIsSupported() {
    bytes4 interfaceId;

    /// @dev supported interface cases being verified
    require interfaceId == erc165InterfaceId()
        || interfaceId == accessControlDefaultAdminRulesInterfaceId()
        || interfaceId == any2EVMMessageReceiverInterfaceId()
        || interfaceId == policyProtectedInterfaceId();

    assert supportsInterface(interfaceId);
}

/// @notice ParentVault reports false for unsupported ERC165 interface IDs
/// @dev Verifies the negative supportsInterface case by explicitly excluding every supported ID
rule supportsInterface_ReturnsFalse_WhenInterfaceIsNotSupported() {
    bytes4 interfaceId;

    /// @dev supported cases NOT being verified
    require interfaceId != erc165InterfaceId();
    require interfaceId != accessControlDefaultAdminRulesInterfaceId();
    require interfaceId != any2EVMMessageReceiverInterfaceId();
    require interfaceId != policyProtectedInterfaceId();

    assert !supportsInterface(interfaceId);
}

/// ───────────────────────────── OWNER ───────────────────────────

/// @notice ParentVault owner resolves to AccessControlDefaultAdminRules' current default admin
/// @dev Verifies the explicit owner() override that resolves the Ownable/AccessControl inheritance conflict
rule owner_ReturnsDefaultAdmin() {
    assert owner() == defaultAdmin();
}

/// @notice After initialization, ParentVault owner is the initializer's default admin
/// @dev Verifies that __PolicyProtected_init ownership and AccessControl default admin agree
rule owner_Success_AfterInitialize() {
    env e;
    BaseVault.InitParams params;
    address treasury;
    address policyEngineManager;
    address newPolicyEngine;
    address cancelDepositOperator;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !isInitialized(), "contract should not be initialized";
    require !isInitializing(), "contract should not be initializing";
    require defaultAdmin() == 0, "default admin should not be initialized";
    require params.defaultAdmin != 0, "default admin should not be zero";
    require params.pauser != 0, "pauser should not be zero";
    require params.unpauser != 0, "unpauser should not be zero";
    require params.configOperator != 0, "config operator should not be zero";
    require params.upgrader != 0, "upgrader should not be zero";
    require params.initialDefaultCcipGasLimit != 0, "default CCIP gas limit should not be zero";
    require treasury != 0, "treasury should not be zero";
    require policyEngineManager != 0, "policy engine manager should not be zero";
    require newPolicyEngine != 0, "policy engine should not be zero";
    require newPolicyEngine == policyEngine, "policy engine should be the mock policy engine";
    require getPolicyEngine() == 0, "policy engine storage should be uninitialized";
    require cancelDepositOperator != 0, "cancel deposit operator should not be zero";

    initialize@withrevert(e, params, treasury, policyEngineManager, newPolicyEngine, cancelDepositOperator);

    assert !lastReverted;
    assert owner() == params.defaultAdmin;
    assert owner() == defaultAdmin();
}

/// ─────────────────────────── GET TVL ──────────────────────────

/// @notice ParentVault TVL is zero when this chain has no active strategy adapter
/// @dev Verifies that the non-strategy-chain path returns zero and does not query an adapter
rule ADAPTER_003_ADAPTER_005_REBAL_008_getTVL_ReturnsZero_WhenNoActiveAdapter() {
    require getActiveProtocolAdapter() == 0, "active adapter should be unset";

    assert getTVL() == 0;
}

/// @notice ParentVault TVL includes both active adapter TVL and pending rebalance deposit recovery
/// @dev Verifies the strategy-chain path while excluding the checked-addition overflow case below
rule ADAPTER_003_ADAPTER_005_REBAL_008_REC_006_getTVL_Success_WhenActiveAdapterIsSet() {
    uint256 adapterTVL = adapter.getTVL();
    uint256 recoveryAmount = getRebalanceDepositRecovery().amount;

    /// @dev revert conditions NOT being verified
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require adapterTVL <= max_uint256 - recoveryAmount, "TVL addition should not overflow";

    assert getTVL() == adapterTVL + recoveryAmount;
}

/// @notice ParentVault TVL reverts when active adapter TVL plus rebalance recovery amount overflows
/// @dev Verifies the checked arithmetic guard in ParentVault._getTVL
rule REBAL_008_getTVL_RevertWhen_TvlAdditionOverflows() {
    env e;
    uint256 adapterTVL = adapter.getTVL();
    uint256 recoveryAmount = getRebalanceDepositRecovery().amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";

    /// @dev revert condition being verified
    require adapterTVL > max_uint256 - recoveryAmount, "TVL addition should overflow";


    getTVL@withrevert(e);

    assert lastReverted;
}

/// ─────────────────────────── DEPOSIT ───────────────────────────

/// @notice Deposit reverts when called during an active non-reentrant execution
/// @dev Verifies that a reentrant call leaves all vault state unchanged
rule deposit_RevertWhen_ReentrantCall() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !paused(), "vault should not be paused";
    require amount >= getMinDepositAmount(), "amount should meet the minimum deposit requirement";
    require getEpoch(getEpochNonce()).status == Types.EpochStatus.OPEN, "current epoch should be open";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";

    deposit@withrevert(e, amount);

    assert lastReverted;
}

/// @notice Deposit reverts when the vault is paused
/// @dev Verifies that a paused vault leaves all vault state unchanged
rule PAUSE_003_deposit_RevertWhen_Paused() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require amount >= getMinDepositAmount(), "amount should meet the minimum deposit requirement";
    require getEpoch(getEpochNonce()).status == Types.EpochStatus.OPEN, "current epoch should be open";

    /// @dev revert condition being verified
    require paused(), "vault should be paused";

    deposit@withrevert(e, amount);

    assert lastReverted;
}

/// @notice Deposit reverts when the amount is below the minimum deposit requirement
/// @dev Verifies that a malformed amount leaves all vault state unchanged. This precondition is
///      checked in ParentVaultUserEpochLib before any external call, so it is not expected to hit
///      the unresolved-external-library-call issue that affects _setActiveAdapter.
rule EPOCH_015_deposit_RevertWhen_AmountBelowMinimum() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getEpoch(getEpochNonce()).status == Types.EpochStatus.OPEN, "current epoch should be open";

    /// @dev revert condition being verified
    require amount < getMinDepositAmount(), "amount should be below the minimum deposit requirement";

    deposit@withrevert(e, amount);

    assert lastReverted;
}

rule EPOCH_005_deposit_RevertWhen_EpochNotOpen() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require amount >= getMinDepositAmount(), "amount should meet the minimum deposit requirement";

    /// @dev revert condition being verified
    require getEpoch(getEpochNonce()).status != Types.EpochStatus.OPEN, "current epoch should not be open";

    deposit@withrevert(e, amount);

    assert lastReverted;
}

/// @notice Deposit pulls the deposited amount from the depositor, accumulates the deposit and epoch
///         totals, and emits DepositSubmitted
/// @dev Delegates to ParentVaultUserEpochLib.deposit (DELEGATECALL). This is the same shape as
///      _setActiveAdapter (a public library function making a nested external call - here,
///      IERC20(asset).safeTransferFrom) - included to observe whether the same unresolved-callee
///      havoc reproduces for this call site.
rule EPOCH_005_deposit_Success() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require amount >= getMinDepositAmount(), "amount should meet the minimum deposit requirement";
    uint256 epochNonce = getEpochNonce();
    require getEpoch(epochNonce).status == Types.EpochStatus.OPEN, "current epoch should be open";
    require asset.balanceOf(e.msg.sender) >= amount, "depositor should have sufficient asset balance";
    require asset.allowance(e.msg.sender, currentContract) >= amount,
        "vault should be approved to pull the deposit amount";

    require e.msg.sender != currentContract, "depositor should not be the vault itself";

    uint256 priorDeposit = getDepositAmount(e.msg.sender, epochNonce);
    uint256 priorTotalDeposit = getEpoch(epochNonce).totalDepositAmount;
    require priorDeposit <= max_uint256 - amount, "deposit accumulator should not overflow";
    require priorTotalDeposit <= max_uint256 - amount, "epoch total deposit accumulator should not overflow";

    uint256 priorDepositorAssetBalance = asset.balanceOf(e.msg.sender);
    uint256 priorVaultAssetBalance = asset.balanceOf(currentContract);
    require priorVaultAssetBalance <= max_uint256 - amount, "vault asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_DepositSubmitted_EventCount == 0;
    require ghost_deposit_StoreCount == 0;
    require ghost_epoch_totalDepositAmount_StoreCount == 0;

    uint256 returnedEpochNonce = deposit@withrevert(e, amount);

    assert !lastReverted;
    assert returnedEpochNonce == epochNonce;
    assert getDepositAmount(e.msg.sender, epochNonce) == priorDeposit + amount;
    assert getEpoch(epochNonce).totalDepositAmount == priorTotalDeposit + amount;
    assert asset.balanceOf(e.msg.sender) == priorDepositorAssetBalance - amount;
    assert asset.balanceOf(currentContract) == priorVaultAssetBalance + amount;
    assert ghost_DepositSubmitted_EventCount == 1;
    assert ghost_DepositSubmitted_Param_epochNonce == epochNonce;
    assert ghost_DepositSubmitted_Param_depositor == e.msg.sender;
    assert ghost_DepositSubmitted_Param_amount == amount;
}

/// ─────────────────────────── WITHDRAW ──────────────────────────

/// @notice Withdraw reverts when called during an active non-reentrant execution
/// @dev Verifies that a reentrant call leaves all vault state unchanged
rule withdraw_RevertWhen_ReentrantCall() {
    env e;
    uint256 shareBurnAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !paused(), "vault should not be paused";
    require shareBurnAmount != 0, "share burn amount should not be zero";
    require getEpoch(getEpochNonce()).status == Types.EpochStatus.OPEN, "current epoch should be open";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";

    withdraw@withrevert(e, shareBurnAmount);

    assert lastReverted;
}

/// @notice Withdraw reverts when the vault is paused
/// @dev Verifies that a paused vault leaves all vault state unchanged
rule PAUSE_003_withdraw_RevertWhen_Paused() {
    env e;
    uint256 shareBurnAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require shareBurnAmount != 0, "share burn amount should not be zero";
    require getEpoch(getEpochNonce()).status == Types.EpochStatus.OPEN, "current epoch should be open";

    /// @dev revert condition being verified
    require paused(), "vault should be paused";

    withdraw@withrevert(e, shareBurnAmount);

    assert lastReverted;
}

/// @notice Withdraw reverts when the share burn amount is zero
/// @dev Verifies that a malformed amount leaves all vault state unchanged
rule EPOCH_015_withdraw_RevertWhen_ShareBurnAmountIsZero() {
    env e;
    uint256 shareBurnAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getEpoch(getEpochNonce()).status == Types.EpochStatus.OPEN, "current epoch should be open";

    /// @dev revert condition being verified
    require shareBurnAmount == 0, "share burn amount should be zero";

    withdraw@withrevert(e, shareBurnAmount);

    assert lastReverted;
}

rule EPOCH_005_withdraw_RevertWhen_EpochNotOpen() {
    env e;
    uint256 shareBurnAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require shareBurnAmount != 0, "share burn amount should not be zero";

    /// @dev revert condition being verified
    require getEpoch(getEpochNonce()).status != Types.EpochStatus.OPEN, "current epoch should not be open";

    withdraw@withrevert(e, shareBurnAmount);

    assert lastReverted;
}

/// @notice Withdraw pulls the share burn amount from the withdrawer, accumulates the withdraw and
///         epoch totals, and emits WithdrawSubmitted
rule EPOCH_005_withdraw_Success() {
    env e;
    uint256 shareBurnAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require shareBurnAmount != 0, "share burn amount should not be zero";
    require e.msg.sender != currentContract, "withdrawer should not be the vault itself";
    uint256 epochNonce = getEpochNonce();
    require getEpoch(epochNonce).status == Types.EpochStatus.OPEN, "current epoch should be open";
    require share.balanceOf(e.msg.sender) >= shareBurnAmount, "withdrawer should have sufficient share balance";
    require share.allowance(e.msg.sender, currentContract) >= shareBurnAmount,
        "vault should be approved to pull the share burn amount";

    uint256 priorWithdraw = getWithdrawShareBurnAmount(e.msg.sender, epochNonce);
    uint256 priorTotalShareBurn = getEpoch(epochNonce).totalShareBurnAmount;
    require priorWithdraw <= max_uint256 - shareBurnAmount, "withdraw accumulator should not overflow";
    require priorTotalShareBurn <= max_uint256 - shareBurnAmount,
        "epoch total share burn accumulator should not overflow";

    uint256 priorWithdrawerShareBalance = share.balanceOf(e.msg.sender);
    uint256 priorVaultShareBalance = share.balanceOf(currentContract);
    require priorVaultShareBalance <= max_uint256 - shareBurnAmount, "vault share balance should not overflow";

    /// @dev set ghost starting values
    require ghost_WithdrawSubmitted_EventCount == 0;
    require ghost_withdraw_StoreCount == 0;
    require ghost_epoch_totalShareBurnAmount_StoreCount == 0;

    uint256 returnedEpochNonce = withdraw@withrevert(e, shareBurnAmount);

    assert !lastReverted;
    assert returnedEpochNonce == epochNonce;
    assert getWithdrawShareBurnAmount(e.msg.sender, epochNonce) == priorWithdraw + shareBurnAmount;
    assert getEpoch(epochNonce).totalShareBurnAmount == priorTotalShareBurn + shareBurnAmount;
    assert share.balanceOf(e.msg.sender) == priorWithdrawerShareBalance - shareBurnAmount;
    assert share.balanceOf(currentContract) == priorVaultShareBalance + shareBurnAmount;
    assert ghost_WithdrawSubmitted_EventCount == 1;
    assert ghost_WithdrawSubmitted_Param_epochNonce == epochNonce;
    assert ghost_WithdrawSubmitted_Param_withdrawer == e.msg.sender;
    assert ghost_WithdrawSubmitted_Param_shareBurnAmount == shareBurnAmount;
}

/// ────────────────────────── CLAIM SHARES ────────────────────────

/// @notice Claiming shares reverts when called during an active non-reentrant execution
/// @dev Verifies that a reentrant call leaves all vault state unchanged
rule claimShares_RevertWhen_ReentrantCall() {
    env e;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !paused(), "vault should not be paused";
    require getEpoch(epochNonce).status == Types.EpochStatus.CLAIMABLE, "epoch should be claimable";
    require getDepositAmount(e.msg.sender, epochNonce) != 0, "depositor should have a deposit for the epoch";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";

    claimShares@withrevert(e, epochNonce);

    assert lastReverted;
}

/// @notice Claiming shares reverts when the vault is paused
/// @dev Verifies that a paused vault leaves all vault state unchanged
rule PAUSE_003_claimShares_RevertWhen_Paused() {
    env e;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getEpoch(epochNonce).status == Types.EpochStatus.CLAIMABLE, "epoch should be claimable";
    require getDepositAmount(e.msg.sender, epochNonce) != 0, "depositor should have a deposit for the epoch";

    /// @dev revert condition being verified
    require paused(), "vault should be paused";

    claimShares@withrevert(e, epochNonce);

    assert lastReverted;
}

/// @notice Claiming shares reverts when the epoch is not claimable
/// @dev Verifies that a premature claim attempt leaves all vault state unchanged
rule claimShares_RevertWhen_EpochNotClaimable() {
    env e;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getDepositAmount(e.msg.sender, epochNonce) != 0, "depositor should have a deposit for the epoch";

    /// @dev revert condition being verified
    require getEpoch(epochNonce).status != Types.EpochStatus.CLAIMABLE, "epoch should not be claimable";

    claimShares@withrevert(e, epochNonce);

    assert lastReverted;
}

/// @notice Claiming shares reverts when the caller has no deposit for the epoch
/// @dev Verifies that an unentitled claim attempt leaves all vault state unchanged
rule claimShares_RevertWhen_NoDeposit() {
    env e;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getEpoch(epochNonce).status == Types.EpochStatus.CLAIMABLE, "epoch should be claimable";

    /// @dev revert condition being verified
    require getDepositAmount(e.msg.sender, epochNonce) == 0, "depositor should not have a deposit for the epoch";

    claimShares@withrevert(e, epochNonce);

    assert lastReverted;
}

/// @notice Claiming shares mints the depositor's proportional (or fully remaining) share of the
///         epoch's minted shares, deletes their deposit entry, and emits DepositClaimed
rule EPOCH_009_claimShares_Success() {
    env e;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require e.msg.sender != currentContract, "depositor should not be the vault itself";
    require getEpoch(epochNonce).status == Types.EpochStatus.CLAIMABLE, "epoch should be claimable";

    uint256 depositAmount = getDepositAmount(e.msg.sender, epochNonce);
    require depositAmount != 0, "depositor should have a deposit for the epoch";

    uint256 remainingDepositClaimAmount = getEpoch(epochNonce).remainingDepositClaimAmount;
    uint256 remainingShareMintAmount = getEpoch(epochNonce).remainingShareMintAmount;
    require depositAmount <= remainingDepositClaimAmount, "deposit should not exceed the remaining claimable amount";
    require remainingShareMintAmount != 0, "shares should remain available to claim";

    mathint expectedShareMintAmount;
    if (depositAmount == remainingDepositClaimAmount) {
        expectedShareMintAmount = remainingShareMintAmount;
    } else {
        require remainingDepositClaimAmount != 0, "remaining deposit claim amount should not be zero";
        require depositAmount <= max_uint256 / remainingShareMintAmount,
            "proportional multiplication should not overflow";
        expectedShareMintAmount = (depositAmount * remainingShareMintAmount) / remainingDepositClaimAmount;
    }

    uint256 priorClaimantShareBalance = share.balanceOf(e.msg.sender);
    require priorClaimantShareBalance <= max_uint256 - expectedShareMintAmount,
        "claimant share balance should not overflow";
    require share.totalSupply() <= max_uint256 - expectedShareMintAmount, "share total supply should not overflow";

    /// @dev set ghost starting values
    require ghost_DepositClaimed_EventCount == 0;
    require ghost_epoch_remainingDepositClaimAmount_StoreCount == 0;
    require ghost_epoch_remainingShareMintAmount_StoreCount == 0;
    require ghost_deposit_StoreCount == 0;

    uint256 shareMintAmount = claimShares@withrevert(e, epochNonce);

    assert !lastReverted;
    assert shareMintAmount == expectedShareMintAmount;
    assert getDepositAmount(e.msg.sender, epochNonce) == 0;
    assert getEpoch(epochNonce).remainingDepositClaimAmount == remainingDepositClaimAmount - depositAmount;
    assert getEpoch(epochNonce).remainingShareMintAmount == remainingShareMintAmount - shareMintAmount;
    assert share.balanceOf(e.msg.sender) == priorClaimantShareBalance + shareMintAmount;
    assert ghost_DepositClaimed_EventCount == 1;
    assert ghost_DepositClaimed_Param_epochNonce == epochNonce;
    assert ghost_DepositClaimed_Param_depositor == e.msg.sender;
    assert ghost_DepositClaimed_Param_shareMintAmount == shareMintAmount;
}

/// ─────────────────────────── CLAIM ASSET ────────────────────────

/// @notice Claiming asset reverts when called during an active non-reentrant execution
/// @dev Verifies that a reentrant call leaves all vault state unchanged
rule claimAsset_RevertWhen_ReentrantCall() {
    env e;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !paused(), "vault should not be paused";
    require getEpoch(epochNonce).status == Types.EpochStatus.CLAIMABLE, "epoch should be claimable";
    require getWithdrawShareBurnAmount(e.msg.sender, epochNonce) != 0,
        "withdrawer should have a withdraw intent for the epoch";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";

    claimAsset@withrevert(e, epochNonce);

    assert lastReverted;
}

/// @notice Claiming asset reverts when the vault is paused
/// @dev Verifies that a paused vault leaves all vault state unchanged
rule PAUSE_003_claimAsset_RevertWhen_Paused() {
    env e;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getEpoch(epochNonce).status == Types.EpochStatus.CLAIMABLE, "epoch should be claimable";
    require getWithdrawShareBurnAmount(e.msg.sender, epochNonce) != 0,
        "withdrawer should have a withdraw intent for the epoch";

    /// @dev revert condition being verified
    require paused(), "vault should be paused";

    claimAsset@withrevert(e, epochNonce);

    assert lastReverted;
}

/// @notice Claiming asset reverts when the epoch is not claimable
/// @dev Verifies that a premature claim attempt leaves all vault state unchanged
rule claimAsset_RevertWhen_EpochNotClaimable() {
    env e;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";

    /// @dev revert condition being verified
    require getEpoch(epochNonce).status != Types.EpochStatus.CLAIMABLE, "epoch should not be claimable";

    claimAsset@withrevert(e, epochNonce);

    assert lastReverted;
}

/// @notice Claiming asset reverts when the caller has no withdraw intent for the epoch
/// @dev Verifies that an unentitled claim attempt leaves all vault state unchanged
rule claimAsset_RevertWhen_NoWithdraw() {
    env e;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getEpoch(epochNonce).status == Types.EpochStatus.CLAIMABLE, "epoch should be claimable";

    /// @dev revert condition being verified
    require getWithdrawShareBurnAmount(e.msg.sender, epochNonce) == 0,
        "withdrawer should not have a withdraw intent for the epoch";

    claimAsset@withrevert(e, epochNonce);

    assert lastReverted;
}

/// @notice Claiming asset burns the vault's corresponding shares, transfers the withdrawer's
///         proportional (or fully remaining) asset amount, deletes their withdraw entry, and emits
///         WithdrawClaimed. The formula holds even in the withdrawAmount == 0 case, where the asset
///         transfer is skipped entirely (adding/subtracting zero is a no-op).
rule EPOCH_012_claimAsset_Success() {
    env e;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require e.msg.sender != currentContract, "withdrawer should not be the vault itself";
    require getEpoch(epochNonce).status == Types.EpochStatus.CLAIMABLE, "epoch should be claimable";

    uint256 shareBurnAmount = getWithdrawShareBurnAmount(e.msg.sender, epochNonce);
    require shareBurnAmount != 0, "withdrawer should have a withdraw intent for the epoch";

    uint256 remainingShareBurnAmount = getEpoch(epochNonce).remainingShareBurnAmount;
    uint256 remainingWithdrawClaimAmount = getEpoch(epochNonce).remainingWithdrawClaimAmount;
    require shareBurnAmount <= remainingShareBurnAmount, "share burn amount should not exceed the remaining amount";

    mathint expectedWithdrawAmount;
    if (shareBurnAmount == remainingShareBurnAmount) {
        expectedWithdrawAmount = remainingWithdrawClaimAmount;
    } else {
        require remainingShareBurnAmount != 0, "remaining share burn amount should not be zero";
        require remainingWithdrawClaimAmount == 0 || shareBurnAmount <= max_uint256 / remainingWithdrawClaimAmount,
            "proportional multiplication should not overflow";
        expectedWithdrawAmount = (shareBurnAmount * remainingWithdrawClaimAmount) / remainingShareBurnAmount;
    }

    uint256 priorVaultShareBalance = share.balanceOf(currentContract);
    require priorVaultShareBalance >= shareBurnAmount, "vault should hold enough shares to burn";
    require share.totalSupply() >= shareBurnAmount, "share total supply should cover the burn";

    uint256 priorClaimantAssetBalance = asset.balanceOf(e.msg.sender);
    uint256 priorVaultAssetBalance = asset.balanceOf(currentContract);
    require priorVaultAssetBalance >= expectedWithdrawAmount, "vault should hold enough asset to pay out the claim";
    require priorClaimantAssetBalance <= max_uint256 - expectedWithdrawAmount,
        "claimant asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_WithdrawClaimed_EventCount == 0;
    require ghost_epoch_remainingShareBurnAmount_StoreCount == 0;
    require ghost_epoch_remainingWithdrawClaimAmount_StoreCount == 0;
    require ghost_withdraw_StoreCount == 0;

    uint256 withdrawAmount = claimAsset@withrevert(e, epochNonce);

    assert !lastReverted;
    assert withdrawAmount == expectedWithdrawAmount;
    assert getWithdrawShareBurnAmount(e.msg.sender, epochNonce) == 0;
    assert getEpoch(epochNonce).remainingShareBurnAmount == remainingShareBurnAmount - shareBurnAmount;
    assert getEpoch(epochNonce).remainingWithdrawClaimAmount == remainingWithdrawClaimAmount - withdrawAmount;
    assert share.balanceOf(currentContract) == priorVaultShareBalance - shareBurnAmount;
    assert asset.balanceOf(currentContract) == priorVaultAssetBalance - withdrawAmount;
    assert asset.balanceOf(e.msg.sender) == priorClaimantAssetBalance + withdrawAmount;
    assert ghost_WithdrawClaimed_EventCount == 1;
    assert ghost_WithdrawClaimed_Param_epochNonce == epochNonce;
    assert ghost_WithdrawClaimed_Param_withdrawer == e.msg.sender;
    assert ghost_WithdrawClaimed_Param_amount == withdrawAmount;
}

/// ────────────────────────── CANCEL DEPOSIT ──────────────────────

/// @notice Cancelling a deposit reverts when called during an active non-reentrant execution
/// @dev Verifies that a reentrant call leaves all vault state unchanged
rule cancelDeposit_RevertWhen_ReentrantCall() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !paused(), "vault should not be paused";
    require getEpoch(getEpochNonce()).status == Types.EpochStatus.OPEN, "current epoch should be open";
    require getDepositAmount(e.msg.sender, getEpochNonce()) != 0,
        "depositor should have a deposit for the current epoch";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";

    cancelDeposit@withrevert(e);

    assert lastReverted;
}

/// @notice Cancelling a deposit reverts when the vault is paused
/// @dev Verifies that a paused vault leaves all vault state unchanged
rule PAUSE_003_cancelDeposit_RevertWhen_Paused() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getEpoch(getEpochNonce()).status == Types.EpochStatus.OPEN, "current epoch should be open";
    require getDepositAmount(e.msg.sender, getEpochNonce()) != 0,
        "depositor should have a deposit for the current epoch";

    /// @dev revert condition being verified
    require paused(), "vault should be paused";

    cancelDeposit@withrevert(e);

    assert lastReverted;
}

/// @notice Cancelling a deposit reverts when the current epoch is not open
/// @dev Verifies that a stale cancellation attempt leaves all vault state unchanged
rule EPOCH_005_cancelDeposit_RevertWhen_EpochNotOpen() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";

    /// @dev revert condition being verified
    require getEpoch(getEpochNonce()).status != Types.EpochStatus.OPEN, "current epoch should not be open";

    cancelDeposit@withrevert(e);

    assert lastReverted;
}

/// @notice Cancelling a deposit reverts when the caller has no deposit for the current epoch
/// @dev Verifies that an unentitled cancellation attempt leaves all vault state unchanged
rule cancelDeposit_RevertWhen_NoDeposit() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getEpoch(getEpochNonce()).status == Types.EpochStatus.OPEN, "current epoch should be open";

    /// @dev revert condition being verified
    require getDepositAmount(e.msg.sender, getEpochNonce()) == 0,
        "depositor should not have a deposit for the current epoch";

    cancelDeposit@withrevert(e);

    assert lastReverted;
}

/// @notice Cancelling a deposit deletes the depositor's entry, decrements the epoch total, refunds
///         the full deposit amount, and emits DepositCancelled
rule EPOCH_006a_cancelDeposit_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require e.msg.sender != currentContract, "depositor should not be the vault itself";
    uint256 epochNonce = getEpochNonce();
    require getEpoch(epochNonce).status == Types.EpochStatus.OPEN, "current epoch should be open";

    uint256 depositAmount = getDepositAmount(e.msg.sender, epochNonce);
    require depositAmount != 0, "depositor should have a deposit for the current epoch";

    uint256 priorTotalDeposit = getEpoch(epochNonce).totalDepositAmount;
    require priorTotalDeposit >= depositAmount, "epoch total deposit should not underflow";

    uint256 priorDepositorAssetBalance = asset.balanceOf(e.msg.sender);
    uint256 priorVaultAssetBalance = asset.balanceOf(currentContract);
    require priorVaultAssetBalance >= depositAmount, "vault should hold enough asset to refund the deposit";
    require priorDepositorAssetBalance <= max_uint256 - depositAmount,
        "depositor asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_DepositCancelled_EventCount == 0;
    require ghost_deposit_StoreCount == 0;
    require ghost_epoch_totalDepositAmount_StoreCount == 0;

    cancelDeposit@withrevert(e);

    assert !lastReverted;
    assert getDepositAmount(e.msg.sender, epochNonce) == 0;
    assert getEpoch(epochNonce).totalDepositAmount == priorTotalDeposit - depositAmount;
    assert asset.balanceOf(e.msg.sender) == priorDepositorAssetBalance + depositAmount;
    assert asset.balanceOf(currentContract) == priorVaultAssetBalance - depositAmount;
    assert ghost_DepositCancelled_EventCount == 1;
    assert ghost_DepositCancelled_Param_epochNonce == epochNonce;
    assert ghost_DepositCancelled_Param_depositor == e.msg.sender;
    assert ghost_DepositCancelled_Param_amount == depositAmount;
}

/// ───────────────────── FORCE CANCEL DEPOSIT ────────────────────

rule forceCancelDeposit_RevertWhen_ReentrantCall() {
    env e;
    address user;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CANCEL_DEPOSIT_OPERATOR_ROLE(), e.msg.sender);
    require getEpoch(getEpochNonce()).status == Types.EpochStatus.OPEN, "current epoch should be open";
    require getDepositAmount(user, getEpochNonce()) != 0, "user should have a deposit";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";

    forceCancelDeposit@withrevert(e, user);

    assert lastReverted;
}

rule forceCancelDeposit_RevertWhen_CallerDoesNotHaveCANCEL_DEPOSIT_OPERATOR_ROLE() {
    env e;
    address user;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getEpoch(getEpochNonce()).status == Types.EpochStatus.OPEN, "current epoch should be open";
    require getDepositAmount(user, getEpochNonce()) != 0, "user should have a deposit";

    /// @dev revert condition being verified
    require !hasRole(CANCEL_DEPOSIT_OPERATOR_ROLE(), e.msg.sender);

    forceCancelDeposit@withrevert(e, user);

    assert lastReverted;
}

rule EPOCH_005_forceCancelDeposit_RevertWhen_EpochNotOpen() {
    env e;
    address user;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require hasRole(CANCEL_DEPOSIT_OPERATOR_ROLE(), e.msg.sender);

    /// @dev revert condition being verified
    require getEpoch(getEpochNonce()).status != Types.EpochStatus.OPEN, "current epoch should not be open";

    forceCancelDeposit@withrevert(e, user);

    assert lastReverted;
}

rule forceCancelDeposit_RevertWhen_NoDeposit() {
    env e;
    address user;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require hasRole(CANCEL_DEPOSIT_OPERATOR_ROLE(), e.msg.sender);
    require getEpoch(getEpochNonce()).status == Types.EpochStatus.OPEN, "current epoch should be open";

    /// @dev revert condition being verified
    require getDepositAmount(user, getEpochNonce()) == 0, "user should not have a deposit";

    forceCancelDeposit@withrevert(e, user);

    assert lastReverted;
}

/// @notice Force cancellation refunds the named user even while paused and does not run policy
rule EPOCH_006a_PAUSE_006_forceCancelDeposit_Success() {
    env e;
    address user;

    /// @dev success conditions being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require hasRole(CANCEL_DEPOSIT_OPERATOR_ROLE(), e.msg.sender);
    require user != currentContract, "user should not be the vault";
    uint256 epochNonce = getEpochNonce();
    require getEpoch(epochNonce).status == Types.EpochStatus.OPEN, "current epoch should be open";
    uint256 depositAmount = getDepositAmount(user, epochNonce);
    require depositAmount != 0, "user should have a deposit";
    uint256 totalDepositBefore = getEpoch(epochNonce).totalDepositAmount;
    require totalDepositBefore >= depositAmount, "epoch total deposit should not underflow";
    uint256 userBalanceBefore = asset.balanceOf(user);
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    require vaultBalanceBefore >= depositAmount, "vault should cover the refund";
    require userBalanceBefore <= max_uint256 - depositAmount, "user balance should not overflow";
    require ghost_DepositCancelled_EventCount == 0;
    require ghost_DepositForceCancelled_EventCount == 0;

    forceCancelDeposit@withrevert(e, user);

    assert !lastReverted;
    assert getDepositAmount(user, epochNonce) == 0;
    assert getEpoch(epochNonce).totalDepositAmount == totalDepositBefore - depositAmount;
    assert asset.balanceOf(user) == userBalanceBefore + depositAmount;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore - depositAmount;
    assert ghost_DepositCancelled_EventCount == 0;
    assert ghost_DepositForceCancelled_EventCount == 1;
    assert ghost_DepositForceCancelled_Param_epochNonce == epochNonce;
    assert ghost_DepositForceCancelled_Param_depositor == user;
    assert ghost_DepositForceCancelled_Param_amount == depositAmount;
}

/// ────────────────────────── CANCEL WITHDRAW ─────────────────────

/// @notice Cancelling a withdraw reverts when called during an active non-reentrant execution
/// @dev Verifies that a reentrant call leaves all vault state unchanged
rule cancelWithdraw_RevertWhen_ReentrantCall() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !paused(), "vault should not be paused";
    require getEpoch(getEpochNonce()).status == Types.EpochStatus.OPEN, "current epoch should be open";
    require getWithdrawShareBurnAmount(e.msg.sender, getEpochNonce()) != 0,
        "withdrawer should have a withdraw intent for the current epoch";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";

    cancelWithdraw@withrevert(e);

    assert lastReverted;
}

/// @notice Cancelling a withdraw reverts when the vault is paused
/// @dev Verifies that a paused vault leaves all vault state unchanged
rule PAUSE_003_cancelWithdraw_RevertWhen_Paused() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getEpoch(getEpochNonce()).status == Types.EpochStatus.OPEN, "current epoch should be open";
    require getWithdrawShareBurnAmount(e.msg.sender, getEpochNonce()) != 0,
        "withdrawer should have a withdraw intent for the current epoch";

    /// @dev revert condition being verified
    require paused(), "vault should be paused";

    cancelWithdraw@withrevert(e);

    assert lastReverted;
}

/// @notice Cancelling a withdraw reverts when the current epoch is not open
/// @dev Verifies that a stale cancellation attempt leaves all vault state unchanged
rule EPOCH_005_cancelWithdraw_RevertWhen_EpochNotOpen() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";

    /// @dev revert condition being verified
    require getEpoch(getEpochNonce()).status != Types.EpochStatus.OPEN, "current epoch should not be open";

    cancelWithdraw@withrevert(e);

    assert lastReverted;
}

/// @notice Cancelling a withdraw reverts when the caller has no withdraw intent for the current epoch
/// @dev Verifies that an unentitled cancellation attempt leaves all vault state unchanged
rule cancelWithdraw_RevertWhen_NoWithdraw() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getEpoch(getEpochNonce()).status == Types.EpochStatus.OPEN, "current epoch should be open";

    /// @dev revert condition being verified
    require getWithdrawShareBurnAmount(e.msg.sender, getEpochNonce()) == 0,
        "withdrawer should not have a withdraw intent for the current epoch";

    cancelWithdraw@withrevert(e);

    assert lastReverted;
}

/// @notice Cancelling a withdraw deletes the withdrawer's entry, decrements the epoch total, refunds
///         the full share burn amount, and emits WithdrawCancelled
rule EPOCH_006b_cancelWithdraw_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require e.msg.sender != currentContract, "withdrawer should not be the vault itself";
    uint256 epochNonce = getEpochNonce();
    require getEpoch(epochNonce).status == Types.EpochStatus.OPEN, "current epoch should be open";

    uint256 shareBurnAmount = getWithdrawShareBurnAmount(e.msg.sender, epochNonce);
    require shareBurnAmount != 0, "withdrawer should have a withdraw intent for the current epoch";

    uint256 priorTotalShareBurn = getEpoch(epochNonce).totalShareBurnAmount;
    require priorTotalShareBurn >= shareBurnAmount, "epoch total share burn should not underflow";

    uint256 priorWithdrawerShareBalance = share.balanceOf(e.msg.sender);
    uint256 priorVaultShareBalance = share.balanceOf(currentContract);
    require priorVaultShareBalance >= shareBurnAmount, "vault should hold enough shares to refund the withdraw";
    require priorWithdrawerShareBalance <= max_uint256 - shareBurnAmount,
        "withdrawer share balance should not overflow";

    /// @dev set ghost starting values
    require ghost_WithdrawCancelled_EventCount == 0;
    require ghost_withdraw_StoreCount == 0;
    require ghost_epoch_totalShareBurnAmount_StoreCount == 0;

    cancelWithdraw@withrevert(e);

    assert !lastReverted;
    assert getWithdrawShareBurnAmount(e.msg.sender, epochNonce) == 0;
    assert getEpoch(epochNonce).totalShareBurnAmount == priorTotalShareBurn - shareBurnAmount;
    assert share.balanceOf(e.msg.sender) == priorWithdrawerShareBalance + shareBurnAmount;
    assert share.balanceOf(currentContract) == priorVaultShareBalance - shareBurnAmount;
    assert ghost_WithdrawCancelled_EventCount == 1;
    assert ghost_WithdrawCancelled_Param_epochNonce == epochNonce;
    assert ghost_WithdrawCancelled_Param_withdrawer == e.msg.sender;
    assert ghost_WithdrawCancelled_Param_shareBurnAmount == shareBurnAmount;
}

/// ─────────────────────────── CCIP RECEIVE ───────────────────────

/// @notice CCIP receive reverts when the caller is not the configured CCIP router
/// @dev Verifies that an unauthorized delivery attempt leaves all vault state unchanged
rule CCIP_001_ccipReceive_RevertWhen_CallerIsNotCCIPRouter() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    address sender;

    /// @dev revert conditions NOT being verified
    require !paused(), "vault should not be paused";
    require message.sourceChainSelector == getRebalance().activeStrategy.chainSelector,
        "source chain should be the active strategy chain";
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be the registered vault";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch net withdraw";

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
    address sender;

    /// @dev revert conditions NOT being verified
    require !paused(), "vault should not be paused";
    require message.sourceChainSelector == getRebalance().activeStrategy.chainSelector,
        "source chain should be the active strategy chain";
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be the registered vault";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch net withdraw";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";

    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

rule PAUSE_003_ccipReceive_RevertWhen_Paused() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    address sender;

    /// @dev revert conditions NOT being verified
    require message.sourceChainSelector == getRebalance().activeStrategy.chainSelector,
        "source chain should be the active strategy chain";
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be registered";
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch net withdraw";

    /// @dev revert condition being verified
    require paused(), "vault should be paused";

    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

rule CCIP_001_ccipReceive_RevertWhen_SourceChainIsNotActiveStrategyChain() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    address sender;

    /// @dev revert conditions NOT being verified
    require !paused(), "vault should not be paused";
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be registered";
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch net withdraw";

    /// @dev revert condition being verified
    require message.sourceChainSelector != getRebalance().activeStrategy.chainSelector,
        "source chain should not be the active strategy chain";

    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP receive reverts when the decoded sender is not the registered vault for the source chain
/// @dev Verifies that an unauthorized cross-chain sender leaves all vault state unchanged
rule CCIP_001_ccipReceive_RevertWhen_SenderIsNotAllowed() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require message.sourceChainSelector == getRebalance().activeStrategy.chainSelector,
        "source chain should be the active strategy chain";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require message.sender == encodeAddress(sender), "message sender should encode the supplied sender";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch net withdraw";

    /// @dev revert condition being verified
    require sender != getCrosschainVault(message.sourceChainSelector), "sender should not be the registered vault";

    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP receive reverts when a zero sender is supplied for an unregistered source chain
/// @dev Verifies that an unset cross-chain vault cannot authorize the zero address
rule CCIP_001_ccipReceive_RevertWhen_SenderAndRegisteredVaultAreZero() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    address sender;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require message.sourceChainSelector == getRebalance().activeStrategy.chainSelector,
        "source chain should be the active strategy chain";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require message.sender == encodeAddress(sender), "message sender should encode the supplied sender";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch net withdraw";

    /// @dev revert condition being verified
    require sender == 0, "sender should be zero";
    require getCrosschainVault(message.sourceChainSelector) == 0, "source chain should not have a registered vault";

    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP receive reverts when the encoded sender is too short to decode as an address
/// @dev Verifies that malformed sender data leaves all vault state unchanged
rule CCIP_001_ccipReceive_RevertWhen_SenderEncodingIsMalformed() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require !paused(), "vault should not be paused";
    require message.sourceChainSelector == getRebalance().activeStrategy.chainSelector,
        "source chain should be the active strategy chain";
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch net withdraw";

    /// @dev revert condition being verified
    require message.sender.length < 32, "message sender should be too short to decode";

    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP receive reverts when any recovery operation is already pending
/// @dev Verifies that a pending recovery cannot be overwritten by a new delivery
rule REC_003_ccipReceive_RevertWhen_RecoveryAlreadyPending() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    address sender;

    /// @dev revert conditions NOT being verified
    require !paused(), "vault should not be paused";
    require message.sourceChainSelector == getRebalance().activeStrategy.chainSelector,
        "source chain should be the active strategy chain";
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be the registered vault";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch net withdraw";

    /// @dev revert condition being verified
    require getRecoveryMode() != Types.RecoveryMode.NONE, "recovery should be pending";

    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP receive reverts unless exactly one token amount is delivered
/// @dev Verifies that an invalid token-amount array leaves all vault state unchanged
rule CCIP_002_ccipReceive_RevertWhen_TokenAmountsLengthIsInvalid() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    address sender;

    /// @dev revert conditions NOT being verified
    require !paused(), "vault should not be paused";
    require message.sourceChainSelector == getRebalance().activeStrategy.chainSelector,
        "source chain should be the active strategy chain";
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be the registered vault";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch net withdraw";

    /// @dev revert condition being verified
    require message.destTokenAmounts.length != 1, "token amounts length should be invalid";

    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP receive reverts when the delivered token is not the vault asset
/// @dev Verifies that an invalid received token leaves all vault state unchanged
rule CCIP_002_ccipReceive_RevertWhen_ReceivedTokenIsInvalid() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    address sender;

    /// @dev revert conditions NOT being verified
    require !paused(), "vault should not be paused";
    require message.sourceChainSelector == getRebalance().activeStrategy.chainSelector,
        "source chain should be the active strategy chain";
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be the registered vault";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch net withdraw";

    /// @dev revert condition being verified
    require message.destTokenAmounts[0].token != getAsset(), "delivered token should not be the vault asset";

    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP receive reverts when the delivered asset amount is zero
/// @dev Verifies that a zero-value delivery leaves all vault state unchanged
rule CCIP_002_ccipReceive_RevertWhen_ReceivedAmountIsZero() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    address sender;

    /// @dev revert conditions NOT being verified
    require !paused(), "vault should not be paused";
    require message.sourceChainSelector == getRebalance().activeStrategy.chainSelector,
        "source chain should be the active strategy chain";
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be the registered vault";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch net withdraw";

    /// @dev revert condition being verified
    require message.destTokenAmounts[0].amount == 0, "delivered amount should be zero";

    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP receive reverts when the message data is too short to decode its transaction envelope
/// @dev Verifies that malformed transaction data leaves all vault state unchanged
rule CCIP_003_ccipReceive_RevertWhen_TxDataEncodingIsMalformed() {
    env e;
    Client.Any2EVMMessage message;
    uint256 singleValue;
    address sender;

    /// @dev revert conditions NOT being verified
    require !paused(), "vault should not be paused";
    require message.sourceChainSelector == getRebalance().activeStrategy.chainSelector,
        "source chain should be the active strategy chain";
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

    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP receive reverts when the encoded transaction type is outside the CcipTx enum
/// @dev Verifies that an invalid enum discriminant leaves all vault state unchanged
rule CCIP_003_ccipReceive_RevertWhen_TxTypeEncodingIsOutOfRange() {
    env e;
    Client.Any2EVMMessage message;
    uint256 rawCcipTxType;
    uint256 epochNonce;
    address sender;

    /// @dev revert conditions NOT being verified
    require !paused(), "vault should not be paused";
    require message.sourceChainSelector == getRebalance().activeStrategy.chainSelector,
        "source chain should be the active strategy chain";
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

    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP receive reverts when the transaction type is unsupported by ParentVault
/// @dev Verifies that an unsupported transaction type (e.g. EPOCH_NET_DEPOSIT, which only
///      ChildVault handles) leaves all vault state unchanged
rule CCIP_003_ccipReceive_RevertWhen_TxTypeIsInvalid() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    address sender;
    Types.CcipTx ccipTxType;

    /// @dev revert conditions NOT being verified
    require !paused(), "vault should not be paused";
    require message.sourceChainSelector == getRebalance().activeStrategy.chainSelector,
        "source chain should be the active strategy chain";
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
    require message.data == encodeCcipTxData(ccipTxType, encodeEpochNonce(epochNonce)),
        "message data should encode a generic epoch payload";

    /// @dev revert condition being verified
    require ccipTxType == Types.CcipTx.EPOCH_NET_DEPOSIT, "transaction type should be unsupported by ParentVault";

    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// ─────────────────── CCIP RECEIVE: EPOCH_NET_WITHDRAW ───────────

/// @notice CCIP epoch net withdraw reverts when its payload is too short to decode the epoch nonce
/// @dev Verifies that malformed epoch data leaves all vault state unchanged
rule CCIP_003_ccipReceive_EPOCH_NET_WITHDRAW_RevertWhen_PayloadEncodingIsMalformed() {
    env e;
    Client.Any2EVMMessage message;
    bytes data;
    address sender;

    /// @dev revert conditions NOT being verified
    require !paused(), "vault should not be paused";
    require message.sourceChainSelector == getRebalance().activeStrategy.chainSelector,
        "source chain should be the active strategy chain";
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
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, data),
        "message data should encode an epoch net withdraw";

    /// @dev revert condition being verified
    require data.length < 32, "epoch net withdraw payload should be too short to decode";

    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP epoch net withdraw reverts when the decoded epoch nonce does not match the
///         previous epoch
/// @dev Verifies that a stale or malformed callback leaves all vault state unchanged
rule CCIP_004_EPOCH_014_NONCE_012_ccipReceive_EPOCH_NET_WITHDRAW_RevertWhen_InvalidEpochNonce() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    address sender;

    /// @dev revert conditions NOT being verified
    require !paused(), "vault should not be paused";
    require message.sourceChainSelector == getRebalance().activeStrategy.chainSelector,
        "source chain should be the active strategy chain";
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
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch net withdraw";
    require getEpochNonce() >= 1, "epoch nonce should never be zero";

    /// @dev revert condition being verified
    require epochNonce != getEpochNonce() - 1, "decoded epoch nonce should not match the previous epoch";

    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP epoch net withdraw reverts when the previous epoch is not executing
/// @dev Verifies that an out-of-sequence callback leaves all vault state unchanged
rule CCIP_004_EPOCH_014_NONCE_012_ccipReceive_EPOCH_NET_WITHDRAW_RevertWhen_EpochNotExecuting() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    address sender;

    /// @dev revert conditions NOT being verified
    require !paused(), "vault should not be paused";
    require message.sourceChainSelector == getRebalance().activeStrategy.chainSelector,
        "source chain should be the active strategy chain";
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
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch net withdraw";
    require getEpochNonce() >= 1, "epoch nonce should never be zero";
    require epochNonce == getEpochNonce() - 1, "decoded epoch nonce should match the previous epoch";

    /// @dev revert condition being verified
    require getEpoch(epochNonce).status != Types.EpochStatus.EXECUTING, "previous epoch should not be executing";

    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice A successful CCIP epoch net withdraw settles the epoch's withdraw totals, marks the
///         epoch claimable, and emits EpochWithdrawAmountShort when the delivered amount falls
///         short of what withdrawers are owed
rule CCIP_003_CCIP_004_EPOCH_014_NONCE_012_ccipReceive_EPOCH_NET_WITHDRAW_Success() {
    env e;
    Client.Any2EVMMessage message;
    uint256 epochNonce;
    address sender;

    /// @dev revert conditions NOT being verified
    require !paused(), "vault should not be paused";
    require message.sourceChainSelector == getRebalance().activeStrategy.chainSelector,
        "source chain should be the active strategy chain";
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == getRouter(), "caller should be the CCIP router";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be the registered vault";
    require message.sourceChainSelector == getRebalance().activeStrategy.chainSelector,
        "source chain should be the active strategy chain";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch net withdraw";
    require decodeCcipTxType(message.data) == Types.CcipTx.EPOCH_NET_WITHDRAW,
        "decoded transaction type should be epoch net withdraw";
    require decodeCcipTxPayload(message.data) == encodeEpochNonce(epochNonce),
        "decoded payload should encode the epoch nonce";
    require getEpochNonce() >= 1, "epoch nonce should never be zero";
    require epochNonce == getEpochNonce() - 1, "decoded epoch nonce should match the previous epoch";
    require getEpoch(epochNonce).status == Types.EpochStatus.EXECUTING, "previous epoch should be executing";

    uint256 receivedAmount = message.destTokenAmounts[0].amount;
    uint256 totalDepositAmount = getEpoch(epochNonce).totalDepositAmount;
    uint256 totalWithdrawClaimAmountBefore = getEpoch(epochNonce).totalWithdrawClaimAmount;
    require totalWithdrawClaimAmountBefore >= totalDepositAmount,
        "total withdraw claim amount should not underflow against total deposit amount";
    mathint expectedWithdraw = totalWithdrawClaimAmountBefore - totalDepositAmount;
    require totalDepositAmount <= max_uint256 - receivedAmount, "total withdraw claim amount should not overflow";

    /// @dev set ghost starting values
    require ghost_EpochWithdrawAmountShort_EventCount == 0;
    require ghost_EpochClaimable_EventCount == 0;
    require ghost_epoch_totalWithdrawClaimAmount_StoreCount == 0;
    require ghost_epoch_remainingWithdrawClaimAmount_StoreCount == 0;
    require ghost_epoch_status_StoreCount == 0;
    require ghost_CCIPReceived_EventCount == 0;

    ccipReceive@withrevert(e, message);

    assert !lastReverted;
    assert getEpoch(epochNonce).totalWithdrawClaimAmount == totalDepositAmount + receivedAmount;
    assert getEpoch(epochNonce).remainingWithdrawClaimAmount == totalDepositAmount + receivedAmount;
    assert getEpoch(epochNonce).status == Types.EpochStatus.CLAIMABLE;
    assert ghost_EpochClaimable_EventCount == 1;
    assert ghost_EpochClaimable_Param_epochNonce == epochNonce;
    assert (to_mathint(receivedAmount) < expectedWithdraw) => ghost_EpochWithdrawAmountShort_EventCount == 1;
    assert (to_mathint(receivedAmount) >= expectedWithdraw) => ghost_EpochWithdrawAmountShort_EventCount == 0;
    assert ghost_EpochWithdrawAmountShort_EventCount == 1
        => ghost_EpochWithdrawAmountShort_Param_epochNonce == epochNonce;
    assert ghost_EpochWithdrawAmountShort_EventCount == 1
        => to_mathint(ghost_EpochWithdrawAmountShort_Param_expectedAmount) == expectedWithdraw;
    assert ghost_EpochWithdrawAmountShort_EventCount == 1
        => ghost_EpochWithdrawAmountShort_Param_actualAmount == receivedAmount;
    assert ghost_CCIPReceived_EventCount == 1;
    assert ghost_CCIPReceived_Param_ccipMessageId == message.messageId;
    assert ghost_CCIPReceived_Param_sourceChainSelector == message.sourceChainSelector;
    assert ghost_CCIPReceived_Param_ccipTxType == Types.CcipTx.EPOCH_NET_WITHDRAW;
}

/// ─────────────────────── CCIP RECEIVE: REBALANCE ────────────────

/// @notice ParentVault::_finalizeRebalance() should be marked virtual and overridden in the harness with internal library implementation
///         to avoid havoc issues for these rules!

/// @notice CCIP rebalance callback reverts when no rebalance is in progress
/// @dev Verifies that an unexpected callback leaves all vault state unchanged
rule CCIP_004_NONCE_013_ccipReceive_REBALANCE_RevertWhen_NoRebalanceInProgress() {
    env e;
    Client.Any2EVMMessage message;
    uint256 rebalanceNonce;
    bytes32 protocolId;
    address sender;

    /// @dev revert conditions NOT being verified
    require !paused(), "vault should not be paused";
    require message.sourceChainSelector == getRebalance().activeStrategy.chainSelector,
        "source chain should be the active strategy chain";
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
    require getRebalance().state != Types.RebalanceState.REBALANCING, "rebalance should not be in progress";

    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP rebalance callback reverts when its payload is too short to decode the nonce and
///         protocol ID
/// @dev Verifies that malformed rebalance data leaves all vault state unchanged
rule CCIP_003_ccipReceive_REBALANCE_RevertWhen_PayloadEncodingIsMalformed() {
    env e;
    Client.Any2EVMMessage message;
    bytes data;
    address sender;

    /// @dev revert conditions NOT being verified
    require !paused(), "vault should not be paused";
    require message.sourceChainSelector == getRebalance().activeStrategy.chainSelector,
        "source chain should be the active strategy chain";
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
    require getRebalance().state == Types.RebalanceState.REBALANCING, "rebalance should be in progress";

    /// @dev revert condition being verified
    require data.length < 64, "rebalance payload should be too short to decode";

    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP rebalance callback reverts when the decoded rebalance nonce does not match
/// @dev Verifies that a stale or malformed callback leaves all vault state unchanged
rule CCIP_004_NONCE_013_ccipReceive_REBALANCE_RevertWhen_InvalidRebalanceNonce() {
    env e;
    Client.Any2EVMMessage message;
    uint256 rebalanceNonce;
    bytes32 protocolId;
    address sender;

    /// @dev revert conditions NOT being verified
    require !paused(), "vault should not be paused";
    require message.sourceChainSelector == getRebalance().activeStrategy.chainSelector,
        "source chain should be the active strategy chain";
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
    require getRebalance().state == Types.RebalanceState.REBALANCING, "rebalance should be in progress";

    /// @dev revert condition being verified
    require rebalanceNonce != getRebalance().nonce, "decoded rebalance nonce should not match the current rebalance";

    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP rebalance callback reverts when the decoded protocol ID does not match the
///         pending strategy
/// @dev Verifies that a mismatched callback leaves all vault state unchanged
rule CCIP_004_NONCE_013_ccipReceive_REBALANCE_RevertWhen_InvalidPendingProtocolId() {
    env e;
    Client.Any2EVMMessage message;
    uint256 rebalanceNonce;
    bytes32 protocolId;
    address sender;

    /// @dev revert conditions NOT being verified
    require !paused(), "vault should not be paused";
    require message.sourceChainSelector == getRebalance().activeStrategy.chainSelector,
        "source chain should be the active strategy chain";
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
    require getRebalance().state == Types.RebalanceState.REBALANCING, "rebalance should be in progress";
    require rebalanceNonce == getRebalance().nonce, "decoded rebalance nonce should match the current rebalance";
    require rebalanceNonce != 0, "rebalance nonce should never be zero";
    require rebalanceNonce != max_uint256, "rebalance nonce should not overflow when finalizeRebalance increments it";

    /// @dev revert condition being verified
    require protocolId != getRebalance().pendingStrategy.protocolId,
        "decoded protocol id should not match the pending strategy";

    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP rebalance callback reverts when the target protocol adapter is not registered
/// @dev Verifies that an unknown target protocol leaves all vault state unchanged
rule REC_009_ccipReceive_REBALANCE_RevertWhen_TargetAdapterNotRegistered() {
    env e;
    Client.Any2EVMMessage message;
    uint256 rebalanceNonce;
    bytes32 protocolId;
    address sender;

    /// @dev revert conditions NOT being verified
    require !paused(), "vault should not be paused";
    require message.sourceChainSelector == getRebalance().activeStrategy.chainSelector,
        "source chain should be the active strategy chain";
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
    require getRebalance().state == Types.RebalanceState.REBALANCING, "rebalance should be in progress";
    require rebalanceNonce == getRebalance().nonce, "decoded rebalance nonce should match the current rebalance";
    require rebalanceNonce != 0, "rebalance nonce should never be zero";
    require rebalanceNonce != max_uint256, "rebalance nonce should not overflow when finalizeRebalance increments it";
    require protocolId == getRebalance().pendingStrategy.protocolId,
        "decoded protocol id should match the pending strategy";

    /// @dev revert condition being verified
    require adapterRegistry.getAdapter(e, protocolId) == 0, "target adapter should not be registered";

    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice CCIP rebalance callback reverts when the registered adapter is bound to another vault
/// @dev Verifies that a misconfigured adapter registration leaves all vault state unchanged
rule REC_009_ccipReceive_REBALANCE_RevertWhen_TargetAdapterVaultIsInvalid() {
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
    require message.sourceChainSelector == getRebalance().activeStrategy.chainSelector,
        "source chain should be the active strategy chain";
    require sender != 0, "sender should not be zero";
    require sender == getCrosschainVault(message.sourceChainSelector), "sender should be the registered vault";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.REBALANCE, encodeRebalanceData(rebalanceNonce, protocolId)),
        "message data should encode a rebalance";
    require getRebalance().state == Types.RebalanceState.REBALANCING, "rebalance should be in progress";
    require rebalanceNonce == getRebalance().nonce, "decoded rebalance nonce should match the current rebalance";
    require rebalanceNonce != 0, "rebalance nonce should never be zero";
    require rebalanceNonce != max_uint256, "rebalance nonce should not overflow when finalizeRebalance increments it";
    require protocolId == getRebalance().pendingStrategy.protocolId,
        "decoded protocol id should match the pending strategy";
    require invalidAdapter.getVault() != currentContract, "target adapter should not be bound to this vault";

    /// @dev revert condition being verified
    require adapterRegistry.getAdapter(e, protocolId) == invalidAdapter, "invalid target adapter should be registered";

    ccipReceive@withrevert(e, message);

    assert lastReverted;
}

/// @notice A successful CCIP rebalance callback sets the active adapter, deposits the delivered
///         asset, and finalizes the rebalance (activates the pending strategy, clears rebalance
///         state, and takes the zero-share management-fee path)
/// @dev Management-fee calculation and collection are verified in ParentVaultFeesLib.spec and
///      ParentVaultRebalanceLib.spec; this rule verifies ParentVault's CCIP integration wiring.
rule CCIP_003_CCIP_004_FEE_004_NONCE_011_NONCE_013_ccipReceive_REBALANCE_Success() {
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
    require message.sourceChainSelector == getRebalance().activeStrategy.chainSelector,
        "source chain should be the active strategy chain";
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
    require getRebalance().state == Types.RebalanceState.REBALANCING, "rebalance should be in progress";
    require rebalanceNonce == getRebalance().nonce, "decoded rebalance nonce should match the current rebalance";
    require rebalanceNonce != 0, "rebalance nonce should never be zero";
    require rebalanceNonce != max_uint256, "rebalance nonce should not overflow when finalizeRebalance increments it";
    require protocolId == getRebalance().pendingStrategy.protocolId,
        "decoded protocol id should match the pending strategy";
    require getRebalance().pendingStrategy.chainSelector == getThisChainSelector(),
        "pending strategy should target this chain";

    uint256 amount = message.destTokenAmounts[0].amount;
    uint64 pendingChainSelector = getRebalance().pendingStrategy.chainSelector;
    uint256 lastRebalanceCompletedTimestampBefore = getRebalance().lastRebalanceCompletedTimestamp;
    require e.block.timestamp >= lastRebalanceCompletedTimestampBefore,
        "block timestamp should not precede the last rebalance completion";
    require getTotalShares() == 0, "no management fee shares should be collected";

    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token and adapter arithmetic conditions
    require amount <= vaultBalanceBefore, "vault asset balance should cover the deposit amount";
    require adapterBalanceBefore <= max_uint256 - amount, "adapter asset balance should not overflow";
    require adapterTVLBefore <= max_uint256 - amount, "adapter TVL should not overflow";

    /// @dev set ghost starting values
    require ghost_ActiveProtocolAdapterSet_EventCount == 0;
    require ghost_RebalanceDepositSuccess_EventCount == 0;
    require ghost_RebalanceDepositFailure_EventCount == 0;
    require ghost_RebalanceDepositRecoveryStored_EventCount == 0;
    require ghost_RebalanceCompleted_EventCount == 0;
    require ghost_rebalance_state_StoreCount == 0;
    require ghost_rebalance_activeStrategy_protocolId_StoreCount == 0;
    require ghost_rebalance_activeStrategy_chainSelector_StoreCount == 0;
    require ghost_rebalance_pendingStrategy_protocolId_StoreCount == 0;
    require ghost_rebalance_pendingStrategy_chainSelector_StoreCount == 0;
    require ghost_rebalance_nonce_StoreCount == 0;
    require ghost_CCIPReceived_EventCount == 0;

    ccipReceive@withrevert(e, message);

    assert !lastReverted;
    assert getActiveProtocolAdapter() == adapter;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore - amount;
    assert asset.balanceOf(adapter) == adapterBalanceBefore + amount;
    assert adapter.getTVL() == adapterTVLBefore + amount;
    assert getRecoveryMode() == Types.RecoveryMode.NONE;
    assert getRebalance().state == Types.RebalanceState.NONE;
    assert getRebalance().activeStrategy.protocolId == protocolId;
    assert getRebalance().activeStrategy.chainSelector == pendingChainSelector;
    assert getRebalance().pendingStrategy.protocolId == to_bytes32(0);
    assert getRebalance().pendingStrategy.chainSelector == 0;
    assert getRebalance().nonce == rebalanceNonce + 1;
    assert ghost_ActiveProtocolAdapterSet_EventCount == 1;
    assert ghost_ActiveProtocolAdapterSet_Param_protocolId == protocolId;
    assert ghost_ActiveProtocolAdapterSet_Param_adapter == adapter;
    assert ghost_RebalanceDepositSuccess_EventCount == 1;
    assert ghost_RebalanceDepositSuccess_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_RebalanceDepositSuccess_Param_amount == amount;
    assert ghost_RebalanceDepositFailure_EventCount == 0;
    assert ghost_RebalanceDepositRecoveryStored_EventCount == 0;
    assert ghost_RebalanceCompleted_EventCount == 1;
    assert ghost_RebalanceCompleted_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_RebalanceCompleted_Param_newProtocolId == protocolId;
    assert ghost_RebalanceCompleted_Param_newChainSelector == pendingChainSelector;
    assert ghost_CCIPReceived_EventCount == 1;
    assert ghost_CCIPReceived_Param_ccipMessageId == message.messageId;
    assert ghost_CCIPReceived_Param_sourceChainSelector == message.sourceChainSelector;
    assert ghost_CCIPReceived_Param_ccipTxType == Types.CcipTx.REBALANCE;
}

/// @notice A CCIP rebalance callback whose strategy deposit fails sets the active adapter and
///         stores rebalance deposit recovery instead of finalizing the rebalance
rule REC_002_REC_009_ccipReceive_REBALANCE_When_DepositFails_StoresRecovery() {
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
    require message.sourceChainSelector == getRebalance().activeStrategy.chainSelector,
        "source chain should be the active strategy chain";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require message.destTokenAmounts.length == 1, "token amounts should contain one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token should be the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount should not be zero";
    require adapterRegistry.getAdapter(e, protocolId) == adapter, "adapter should be registered";
    require adapter.getVault() == currentContract, "adapter should be bound to the vault";
    require adapter != currentContract, "adapter should not be the vault";
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.REBALANCE, encodeRebalanceData(rebalanceNonce, protocolId)),
        "message data should encode a rebalance";
    require getRebalance().state == Types.RebalanceState.REBALANCING, "rebalance should be in progress";
    require rebalanceNonce == getRebalance().nonce, "decoded rebalance nonce should match the current rebalance";
    require rebalanceNonce != 0, "rebalance nonce should never be zero";
    require rebalanceNonce != max_uint256, "rebalance nonce should not overflow when finalizeRebalance increments it";
    require protocolId == getRebalance().pendingStrategy.protocolId,
        "decoded protocol id should match the pending strategy";

    uint256 amount = message.destTokenAmounts[0].amount;
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev failure mode being verified
    require adapter.depositReverts(), "adapter deposit should revert";

    /// @dev mock token arithmetic condition
    require amount <= vaultBalanceBefore, "vault asset balance should cover the deposit amount";

    /// @dev set ghost starting values
    require ghost_ActiveProtocolAdapterSet_EventCount == 0;
    require ghost_RebalanceDepositSuccess_EventCount == 0;
    require ghost_RebalanceDepositFailure_EventCount == 0;
    require ghost_RebalanceDepositRecoveryStored_EventCount == 0;
    require ghost_RebalanceCompleted_EventCount == 0;
    require ghost_rebalance_state_StoreCount == 0;
    require ghost_rebalance_nonce_StoreCount == 0;
    require ghost_CCIPReceived_EventCount == 0;

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
    assert getRebalance().state == Types.RebalanceState.REBALANCING;
    assert getRebalance().nonce == rebalanceNonce;
    assert ghost_ActiveProtocolAdapterSet_EventCount == 1;
    assert ghost_ActiveProtocolAdapterSet_Param_protocolId == protocolId;
    assert ghost_ActiveProtocolAdapterSet_Param_adapter == adapter;
    assert ghost_RebalanceDepositSuccess_EventCount == 0;
    assert ghost_RebalanceDepositFailure_EventCount == 1;
    assert ghost_RebalanceDepositFailure_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_RebalanceDepositFailure_Param_amount == amount;
    assert ghost_RebalanceDepositRecoveryStored_EventCount == 1;
    assert ghost_RebalanceDepositRecoveryStored_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_RebalanceDepositRecoveryStored_Param_amount == amount;
    assert ghost_RebalanceCompleted_EventCount == 0;
    assert ghost_CCIPReceived_EventCount == 1;
    assert ghost_CCIPReceived_Param_ccipMessageId == message.messageId;
    assert ghost_CCIPReceived_Param_sourceChainSelector == message.sourceChainSelector;
    assert ghost_CCIPReceived_Param_ccipTxType == Types.CcipTx.REBALANCE;
}

/// ───────────────────────── INITIATE REBALANCE ──────────────────

/// @notice ParentVault::_finalizeLocalToLocalRebalance() should be marked virtual and overridden in the harness with internal library implementation
///         to avoid havoc issues for initiateRebalance rules!

/// @dev ParentVaultRebalanceLib's internal validation and pure state transition rules are verified
///      in isolation in ParentVaultRebalanceLib.spec. This section verifies the ParentVault entry
///      point: access control/pause/reentrancy/recovery guards, the library validation guards as
///      surfaced through initiateRebalance, and the external-action dispatch that lives in
///      ParentVault.sol (_executeWithdraw, _setActiveAdapter/_clearActiveAdapter, _executeDeposit,
///      _ccipSend, finalizeRebalance, and events).

/// @notice Initiating a rebalance reverts when the caller lacks REBALANCE_OPERATOR_ROLE
/// @dev Verifies that an unauthorized call leaves all vault state unchanged
rule initiateRebalance_RevertWhen_CallerDoesNotHaveREBALANCE_OPERATOR_ROLE() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require getRebalance().lastRebalanceCompletedTimestamp <= max_uint256 - MIN_REBALANCE_PERIOD(),
        "minimum rebalance period addition should not overflow";
    require e.block.timestamp >= getRebalance().lastRebalanceCompletedTimestamp + MIN_REBALANCE_PERIOD(),
        "minimum rebalance period should have elapsed";
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require newStrategy.protocolId != getRebalance().activeStrategy.protocolId
        || newStrategy.chainSelector != getRebalance().activeStrategy.chainSelector,
        "new strategy should differ from the active strategy";
    require newStrategy.chainSelector == getThisChainSelector()
        || getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";
    require getEpochNonce() > 1, "at least one epoch should have completed";
    require getEpoch(assert_uint256(getEpochNonce() - 1)).status != Types.EpochStatus.EXECUTING,
        "previous epoch should not be executing";

    /// @dev revert condition being verified
    require !hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
}

/// @notice Initiating a rebalance reverts when called during an active non-reentrant execution
/// @dev Verifies that a reentrant call leaves all vault state unchanged
rule initiateRebalance_RevertWhen_ReentrantCall() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require getRebalance().lastRebalanceCompletedTimestamp <= max_uint256 - MIN_REBALANCE_PERIOD(),
        "minimum rebalance period addition should not overflow";
    require e.block.timestamp >= getRebalance().lastRebalanceCompletedTimestamp + MIN_REBALANCE_PERIOD(),
        "minimum rebalance period should have elapsed";
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require newStrategy.protocolId != getRebalance().activeStrategy.protocolId
        || newStrategy.chainSelector != getRebalance().activeStrategy.chainSelector,
        "new strategy should differ from the active strategy";
    require newStrategy.chainSelector == getThisChainSelector()
        || getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";
    require getEpochNonce() > 1, "at least one epoch should have completed";
    require getEpoch(assert_uint256(getEpochNonce() - 1)).status != Types.EpochStatus.EXECUTING,
        "previous epoch should not be executing";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
}

/// @notice Initiating a rebalance reverts when the vault is paused
/// @dev Verifies that a paused vault leaves all vault state unchanged
rule PAUSE_003_initiateRebalance_RevertWhen_Paused() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require getRebalance().lastRebalanceCompletedTimestamp <= max_uint256 - MIN_REBALANCE_PERIOD(),
        "minimum rebalance period addition should not overflow";
    require e.block.timestamp >= getRebalance().lastRebalanceCompletedTimestamp + MIN_REBALANCE_PERIOD(),
        "minimum rebalance period should have elapsed";
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require newStrategy.protocolId != getRebalance().activeStrategy.protocolId
        || newStrategy.chainSelector != getRebalance().activeStrategy.chainSelector,
        "new strategy should differ from the active strategy";
    require newStrategy.chainSelector == getThisChainSelector()
        || getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";
    require getEpochNonce() > 1, "at least one epoch should have completed";
    require getEpoch(assert_uint256(getEpochNonce() - 1)).status != Types.EpochStatus.EXECUTING,
        "previous epoch should not be executing";

    /// @dev revert condition being verified
    require paused(), "vault should be paused";

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
}

/// @notice Initiating a rebalance reverts when any recovery operation is already pending
/// @dev Verifies that a pending recovery cannot be overwritten
rule REC_003_initiateRebalance_RevertWhen_RecoveryAlreadyPending() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require getRebalance().lastRebalanceCompletedTimestamp <= max_uint256 - MIN_REBALANCE_PERIOD(),
        "minimum rebalance period addition should not overflow";
    require e.block.timestamp >= getRebalance().lastRebalanceCompletedTimestamp + MIN_REBALANCE_PERIOD(),
        "minimum rebalance period should have elapsed";
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";

    /// @dev revert condition being verified
    require getRecoveryMode() != Types.RecoveryMode.NONE, "recovery should be pending";

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
}

/// @notice Initiating a rebalance reverts when another rebalance is already in progress
/// @dev Verifies that the active rebalance guard leaves all vault state unchanged
rule REBAL_002_initiateRebalance_RevertWhen_RebalanceInProgress() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require getRebalance().lastRebalanceCompletedTimestamp <= max_uint256 - MIN_REBALANCE_PERIOD(),
        "minimum rebalance period addition should not overflow";
    require e.block.timestamp >= getRebalance().lastRebalanceCompletedTimestamp + MIN_REBALANCE_PERIOD(),
        "minimum rebalance period should have elapsed";
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";

    /// @dev revert condition being verified
    require getRebalance().state != Types.RebalanceState.NONE, "rebalance should be in progress";

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
}

rule REBAL_002_initiateRebalance_RevertWhen_RebalanceTooSoon() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require getRebalance().lastRebalanceCompletedTimestamp <= max_uint256 - MIN_REBALANCE_PERIOD(),
        "minimum rebalance period addition should not overflow";

    /// @dev revert condition being verified
    require e.block.timestamp < getRebalance().lastRebalanceCompletedTimestamp + MIN_REBALANCE_PERIOD(),
        "minimum rebalance period should not have elapsed";

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
}

/// @notice Initiating a rebalance reverts when the target strategy is already active
/// @dev Verifies the same-strategy guard exposed through the ParentVault entry point
rule REBAL_002_initiateRebalance_RevertWhen_SameStrategy() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require getRebalance().lastRebalanceCompletedTimestamp <= max_uint256 - MIN_REBALANCE_PERIOD(),
        "minimum rebalance period addition should not overflow";
    require e.block.timestamp >= getRebalance().lastRebalanceCompletedTimestamp + MIN_REBALANCE_PERIOD(),
        "minimum rebalance period should have elapsed";
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";

    /// @dev revert condition being verified
    require newStrategy.protocolId == getRebalance().activeStrategy.protocolId,
        "target protocol should match the active strategy";
    require newStrategy.chainSelector == getRebalance().activeStrategy.chainSelector,
        "target chain should match the active strategy";

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
}

/// @notice Initiating a rebalance reverts when the target chain is not registered
/// @dev Verifies the invalid-chain guard exposed through the ParentVault entry point
rule REBAL_003_initiateRebalance_RevertWhen_InvalidChainSelector() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require getRebalance().lastRebalanceCompletedTimestamp <= max_uint256 - MIN_REBALANCE_PERIOD(),
        "minimum rebalance period addition should not overflow";
    require e.block.timestamp >= getRebalance().lastRebalanceCompletedTimestamp + MIN_REBALANCE_PERIOD(),
        "minimum rebalance period should have elapsed";
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require newStrategy.protocolId != getRebalance().activeStrategy.protocolId
        || newStrategy.chainSelector != getRebalance().activeStrategy.chainSelector,
        "new strategy should differ from the active strategy";

    /// @dev revert condition being verified
    require newStrategy.chainSelector != getThisChainSelector(), "target chain should not be local";
    require getCrosschainVault(newStrategy.chainSelector) == 0, "target chain should not be supported";

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
}

/// @notice Initiating a rebalance reverts when the target protocol is unsupported
/// @dev Verifies the invalid-protocol guard exposed through the ParentVault entry point
rule REBAL_003_initiateRebalance_RevertWhen_InvalidProtocolId() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require getRebalance().lastRebalanceCompletedTimestamp <= max_uint256 - MIN_REBALANCE_PERIOD(),
        "minimum rebalance period addition should not overflow";
    require e.block.timestamp >= getRebalance().lastRebalanceCompletedTimestamp + MIN_REBALANCE_PERIOD(),
        "minimum rebalance period should have elapsed";
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require newStrategy.protocolId != getRebalance().activeStrategy.protocolId
        || newStrategy.chainSelector != getRebalance().activeStrategy.chainSelector,
        "new strategy should differ from the active strategy";
    require newStrategy.chainSelector == getThisChainSelector()
        || getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";

    /// @dev revert condition being verified
    require !getSupportedProtocol(newStrategy.protocolId), "target protocol should not be supported";

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
}

/// @notice Initiating a rebalance reverts before any epoch has completed
/// @dev Verifies the no-completed-epoch guard exposed through the ParentVault entry point
rule REBAL_010_initiateRebalance_RevertWhen_NoCompletedEpoch() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require getRebalance().lastRebalanceCompletedTimestamp <= max_uint256 - MIN_REBALANCE_PERIOD(),
        "minimum rebalance period addition should not overflow";
    require e.block.timestamp >= getRebalance().lastRebalanceCompletedTimestamp + MIN_REBALANCE_PERIOD(),
        "minimum rebalance period should have elapsed";
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require newStrategy.protocolId != getRebalance().activeStrategy.protocolId
        || newStrategy.chainSelector != getRebalance().activeStrategy.chainSelector,
        "new strategy should differ from the active strategy";
    require newStrategy.chainSelector == getThisChainSelector()
        || getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";

    /// @dev revert condition being verified
    require getEpochNonce() == 1, "no epoch should have completed";

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
}

/// @notice Initiating a rebalance reverts while the previous epoch is still executing
/// @dev Verifies the prior-executing-epoch guard exposed through the ParentVault entry point
rule initiateRebalance_RevertWhen_PreviousEpochExecuting() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require getRebalance().lastRebalanceCompletedTimestamp <= max_uint256 - MIN_REBALANCE_PERIOD(),
        "minimum rebalance period addition should not overflow";
    require e.block.timestamp >= getRebalance().lastRebalanceCompletedTimestamp + MIN_REBALANCE_PERIOD(),
        "minimum rebalance period should have elapsed";
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require newStrategy.protocolId != getRebalance().activeStrategy.protocolId
        || newStrategy.chainSelector != getRebalance().activeStrategy.chainSelector,
        "new strategy should differ from the active strategy";
    require newStrategy.chainSelector == getThisChainSelector()
        || getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";

    /// @dev revert condition being verified
    require getEpochNonce() > 1, "at least one epoch should have completed";
    require getEpoch(assert_uint256(getEpochNonce() - 1)).status == Types.EpochStatus.EXECUTING,
        "previous epoch should be executing";

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
}

/// @notice Initiating a local-source rebalance reverts when no active adapter is set
/// @dev Verifies the _executeWithdraw NoActiveAdapter path after rebalance state is tentatively written
rule REC_009_initiateRebalance_WITHDRAW_LOCAL_RevertWhen_NoActiveAdapter() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require getRebalance().lastRebalanceCompletedTimestamp <= max_uint256 - MIN_REBALANCE_PERIOD(),
        "minimum rebalance period addition should not overflow";
    require e.block.timestamp >= getRebalance().lastRebalanceCompletedTimestamp + MIN_REBALANCE_PERIOD(),
        "minimum rebalance period should have elapsed";
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require getThisChainSelector() != 0, "this chain selector should not be zero";
    require getRebalance().activeStrategy.chainSelector == getThisChainSelector(),
        "active strategy should be local";
    require newStrategy.protocolId != getRebalance().activeStrategy.protocolId
        || newStrategy.chainSelector != getRebalance().activeStrategy.chainSelector,
        "new strategy should differ from the active strategy";
    require newStrategy.chainSelector == getThisChainSelector()
        || getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";
    require getEpochNonce() > 1, "at least one epoch should have completed";
    require getEpoch(assert_uint256(getEpochNonce() - 1)).status != Types.EpochStatus.EXECUTING,
        "previous epoch should not be executing";

    /// @dev revert condition being verified
    require getActiveProtocolAdapter() == 0, "active adapter should be unset";

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
}

/// @notice Initiating a local-source rebalance reverts when withdrawing from the old adapter fails
/// @dev Verifies the _executeWithdraw revertOnFailure=true path and atomic rollback
rule REC_009_initiateRebalance_WITHDRAW_LOCAL_RevertWhen_WithdrawFails() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require adapter.getTVL() != 0, "withdrawn amount should not be zero";
    require getRebalance().lastRebalanceCompletedTimestamp <= max_uint256 - MIN_REBALANCE_PERIOD(),
        "minimum rebalance period addition should not overflow";
    require e.block.timestamp >= getRebalance().lastRebalanceCompletedTimestamp + MIN_REBALANCE_PERIOD(),
        "minimum rebalance period should have elapsed";
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require getRebalance().activeStrategy.chainSelector == getThisChainSelector(),
        "active strategy should be local";
    require newStrategy.protocolId != getRebalance().activeStrategy.protocolId
        || newStrategy.chainSelector != getRebalance().activeStrategy.chainSelector,
        "new strategy should differ from the active strategy";
    require newStrategy.chainSelector == getThisChainSelector()
        || getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";
    require getEpochNonce() > 1, "at least one epoch should have completed";
    require getEpoch(assert_uint256(getEpochNonce() - 1)).status != Types.EpochStatus.EXECUTING,
        "previous epoch should not be executing";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";

    /// @dev revert condition being verified
    require adapter.withdrawReverts(), "adapter withdraw should revert";

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
}

rule REC_009_initiateRebalance_WITHDRAW_LOCAL_RevertWhen_AmountOutIsZero() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require getRebalance().lastRebalanceCompletedTimestamp <= max_uint256 - MIN_REBALANCE_PERIOD(),
        "minimum rebalance period addition should not overflow";
    require e.block.timestamp >= getRebalance().lastRebalanceCompletedTimestamp + MIN_REBALANCE_PERIOD(),
        "minimum rebalance period should have elapsed";
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require getRebalance().activeStrategy.chainSelector == getThisChainSelector(),
        "active strategy should be local";
    require newStrategy.protocolId != getRebalance().activeStrategy.protocolId
        || newStrategy.chainSelector != getRebalance().activeStrategy.chainSelector,
        "new strategy should differ from the active strategy";
    require newStrategy.chainSelector == getThisChainSelector()
        || getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";
    require getEpochNonce() > 1, "at least one epoch should have completed";
    require getEpoch(assert_uint256(getEpochNonce() - 1)).status != Types.EpochStatus.EXECUTING,
        "previous epoch should not be executing";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require getRebalance().nonce < max_uint256, "rebalance nonce increment should not overflow";

    /// @dev revert condition being verified
    require adapter.getTVL() == 0, "adapter should return zero from max withdrawal";

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
}

/// @notice Initiating a local-to-local rebalance reverts when depositing into the new adapter fails
/// @dev Verifies the _executeDeposit revertOnFailure=true path and atomic rollback
rule REC_009_initiateRebalance_LOCAL_TO_LOCAL_RevertWhen_DepositFails() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require adapter.getTVL() != 0, "withdrawn amount should not be zero";
    require getRebalance().lastRebalanceCompletedTimestamp <= max_uint256 - MIN_REBALANCE_PERIOD(),
        "minimum rebalance period addition should not overflow";
    require e.block.timestamp >= getRebalance().lastRebalanceCompletedTimestamp + MIN_REBALANCE_PERIOD(),
        "minimum rebalance period should have elapsed";
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require getRebalance().activeStrategy.chainSelector == getThisChainSelector(),
        "active strategy should be local";
    require newStrategy.chainSelector == getThisChainSelector(), "target strategy should be local";
    require newStrategy.protocolId != getRebalance().activeStrategy.protocolId,
        "target protocol should differ from the active local strategy";
    require newStrategy.chainSelector == getThisChainSelector()
        || getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";
    require getEpochNonce() > 1, "at least one epoch should have completed";
    require getEpoch(assert_uint256(getEpochNonce() - 1)).status != Types.EpochStatus.EXECUTING,
        "previous epoch should not be executing";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require adapterRegistry.getAdapter(e, newStrategy.protocolId) == targetAdapter, "target adapter should be registered";
    require targetAdapter.getVault() == currentContract, "target adapter should be bound to this vault";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    uint256 amountOut = adapter.getTVL();
    require asset.balanceOf(adapter) >= amountOut, "adapter asset balance should cover the withdraw amount";
    require asset.balanceOf(currentContract) <= max_uint256 - amountOut,
        "vault asset balance should not overflow on withdraw";
    require getRebalance().nonce < max_uint256, "rebalance nonce increment should not overflow";

    /// @dev revert condition being verified
    require targetAdapter.depositReverts(), "target adapter deposit should revert";

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
}

/// @notice Initiating a rebalance from a remote active strategy emits RebalanceInitiated without
///         taking a local external action
/// @dev Pending-strategy state transitions are verified in ParentVaultRebalanceLib.spec.
rule NONCE_011_initiateRebalance_REMOTE_ACTIVE_Success() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require getRebalance().lastRebalanceCompletedTimestamp <= max_uint256 - MIN_REBALANCE_PERIOD(),
        "minimum rebalance period addition should not overflow";
    require e.block.timestamp >= getRebalance().lastRebalanceCompletedTimestamp + MIN_REBALANCE_PERIOD(),
        "minimum rebalance period should have elapsed";
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require getRebalance().activeStrategy.chainSelector != getThisChainSelector(),
        "active strategy should be remote";
    require newStrategy.protocolId != getRebalance().activeStrategy.protocolId
        || newStrategy.chainSelector != getRebalance().activeStrategy.chainSelector,
        "new strategy should differ from the active strategy";
    require newStrategy.chainSelector == getThisChainSelector()
        || getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";
    require getEpochNonce() > 1, "at least one epoch should have completed";
    require getEpoch(assert_uint256(getEpochNonce() - 1)).status != Types.EpochStatus.EXECUTING,
        "previous epoch should not be executing";

    uint256 rebalanceNonce = getRebalance().nonce;

    /// @dev set ghost starting values
    require ghost_RebalanceInitiated_EventCount == 0;
    require ghost_RebalanceWithdrawSuccess_EventCount == 0;
    require ghost_ActiveProtocolAdapterSet_EventCount == 0;
    require ghost_ActiveProtocolAdapterCleared_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;

    initiateRebalance@withrevert(e, newStrategy);

    assert !lastReverted;
    assert ghost_RebalanceInitiated_EventCount == 1;
    assert ghost_RebalanceInitiated_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_RebalanceInitiated_Param_chainSelector == newStrategy.chainSelector;
    assert ghost_RebalanceInitiated_Param_protocolId == newStrategy.protocolId;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 0;
    assert ghost_ActiveProtocolAdapterSet_EventCount == 0;
    assert ghost_ActiveProtocolAdapterCleared_EventCount == 0;
    assert ghost_CCIPBridged_EventCount == 0;
}

/// @notice Initiating a local-to-remote rebalance withdraws local TVL, clears the active adapter,
///         bridges the asset to the target chain, and leaves the rebalance in progress
rule NONCE_011_initiateRebalance_LOCAL_TO_REMOTE_Success() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require adapter.getTVL() != 0, "withdrawn amount should not be zero";
    require getRebalance().lastRebalanceCompletedTimestamp <= max_uint256 - MIN_REBALANCE_PERIOD(),
        "minimum rebalance period addition should not overflow";
    require e.block.timestamp >= getRebalance().lastRebalanceCompletedTimestamp + MIN_REBALANCE_PERIOD(),
        "minimum rebalance period should have elapsed";
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require getRebalance().activeStrategy.chainSelector == getThisChainSelector(),
        "active strategy should be local";
    require newStrategy.chainSelector != 0, "target chain selector should not be zero";
    require newStrategy.chainSelector != getThisChainSelector(), "target strategy should be remote";
    require newStrategy.protocolId != getRebalance().activeStrategy.protocolId
        || newStrategy.chainSelector != getRebalance().activeStrategy.chainSelector,
        "new strategy should differ from the active strategy";
    require getCrosschainVault(newStrategy.chainSelector) != 0, "destination vault should be set";
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";
    require getEpochNonce() > 1, "at least one epoch should have completed";
    require getEpoch(assert_uint256(getEpochNonce() - 1)).status != Types.EpochStatus.EXECUTING,
        "previous epoch should not be executing";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require !ccipRouter.getFeeReverts(), "router fee quote should not revert";
    require !ccipRouter.ccipSendReverts(), "router send should not revert";

    uint256 amountOut = adapter.getTVL();
    require amountOut != 0, "withdrawn amount should not be zero";
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    address router = getRouter();
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);
    uint256 linkBalanceBefore = link.balanceOf(currentContract);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);
    uint256 fee = ccipRouter.getFee();
    require adapterBalanceBefore >= amountOut, "adapter asset balance should cover the withdraw amount";
    require vaultBalanceBefore <= max_uint256 - amountOut, "vault asset balance should not overflow on withdraw";
    require routerAssetBalanceBefore <= max_uint256 - amountOut, "router asset balance should not overflow";
    require linkBalanceBefore >= fee, "vault should hold enough LINK for the CCIP fee";
    require routerLinkBalanceBefore <= max_uint256 - fee, "router LINK balance should not overflow";

    uint256 rebalanceNonce = getRebalance().nonce;

    /// @dev set ghost starting values
    require ghost_RebalanceInitiated_EventCount == 0;
    require ghost_RebalanceWithdrawSuccess_EventCount == 0;
    require ghost_ActiveProtocolAdapterCleared_EventCount == 0;
    require ghost_CCIPBridged_EventCount == 0;

    initiateRebalance@withrevert(e, newStrategy);

    assert !lastReverted;
    assert getActiveProtocolAdapter() == 0;
    assert getRebalance().state == Types.RebalanceState.REBALANCING;
    assert ghost_RebalanceInitiated_EventCount == 1;
    assert ghost_RebalanceInitiated_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_RebalanceInitiated_Param_chainSelector == newStrategy.chainSelector;
    assert ghost_RebalanceInitiated_Param_protocolId == newStrategy.protocolId;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 1;
    assert ghost_RebalanceWithdrawSuccess_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_RebalanceWithdrawSuccess_Param_amount == amountOut;
    assert ghost_ActiveProtocolAdapterCleared_EventCount == 1;
    assert ghost_ActiveProtocolAdapterCleared_Param_adapter == adapter;
    assert ghost_CCIPBridged_EventCount == 1;
    assert ghost_CCIPBridged_Param_ccipMessageId != to_bytes32(0);
    assert ghost_CCIPBridged_Param_destinationChainSelector == newStrategy.chainSelector;
    assert ghost_CCIPBridged_Param_ccipTxType == Types.CcipTx.REBALANCE;
    assert ccipRouter.getLastMessageDataHash()
        == hashBytes(encodeCcipTxData(Types.CcipTx.REBALANCE, encodeRebalanceData(rebalanceNonce, newStrategy.protocolId)));
}

/// @notice Initiating a local-to-local rebalance withdraws local TVL, switches adapters, deposits
///         into the target adapter, finalizes the rebalance, and emits the full local event sequence
/// @dev Management-fee calculation and collection are verified in ParentVaultFeesLib.spec and
///      ParentVaultRebalanceLib.spec; this rule verifies ParentVault's local integration wiring.
/// @dev Run with ParentVault.localAdapter.conf, which links the initial active-adapter storage path
///      to MockProtocolAdapter so Certora can resolve the withdrawal before the adapter switch.
rule FEE_004_NONCE_011_initiateRebalance_LOCAL_TO_LOCAL_Success() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require adapter.getTVL() != 0, "withdrawn amount should not be zero";
    require getRebalance().lastRebalanceCompletedTimestamp <= max_uint256 - MIN_REBALANCE_PERIOD(),
        "minimum rebalance period addition should not overflow";
    require e.block.timestamp >= getRebalance().lastRebalanceCompletedTimestamp + MIN_REBALANCE_PERIOD(),
        "minimum rebalance period should have elapsed";
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require getRebalance().activeStrategy.chainSelector == getThisChainSelector(),
        "active strategy should be local";
    require newStrategy.chainSelector == getThisChainSelector(), "target strategy should be local";
    require newStrategy.protocolId != getRebalance().activeStrategy.protocolId,
        "target protocol should differ from the active local strategy";
    require newStrategy.chainSelector == getThisChainSelector()
        || getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";
    require getEpochNonce() > 1, "at least one epoch should have completed";
    require getEpoch(assert_uint256(getEpochNonce() - 1)).status != Types.EpochStatus.EXECUTING,
        "previous epoch should not be executing";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require adapterRegistry.getAdapter(e, newStrategy.protocolId) == targetAdapter,
        "target adapter should be registered";
    require targetAdapter.getVault() == currentContract, "target adapter should be bound to this vault";
    require targetAdapter != adapter, "target adapter should differ from the active adapter";
    require targetAdapter != currentContract, "target adapter should not be the vault";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require !targetAdapter.depositReverts(), "target adapter deposit should not revert";

    uint256 amountOut = adapter.getTVL();
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 targetAdapterBalanceBefore = asset.balanceOf(targetAdapter);
    uint256 targetAdapterTVLBefore = targetAdapter.getTVL();
    uint256 lastRebalanceCompletedTimestampBefore = getRebalance().lastRebalanceCompletedTimestamp;
    require asset.balanceOf(adapter) >= amountOut, "adapter asset balance should cover the withdraw amount";
    require vaultBalanceBefore <= max_uint256 - amountOut, "vault asset balance should not overflow on withdraw";
    require targetAdapterBalanceBefore <= max_uint256 - amountOut,
        "target adapter asset balance should not overflow on deposit";
    require targetAdapterTVLBefore <= max_uint256 - amountOut, "target adapter TVL should not overflow";
    require e.block.timestamp >= lastRebalanceCompletedTimestampBefore,
        "block timestamp should not precede the last rebalance completion";
    require getRebalance().nonce < max_uint256, "rebalance nonce increment should not overflow";
    require getTotalShares() == 0, "management fee collection is verified in library specs";

    uint256 rebalanceNonce = getRebalance().nonce;

    /// @dev set ghost starting values
    require ghost_RebalanceInitiated_EventCount == 0;
    require ghost_RebalanceWithdrawSuccess_EventCount == 0;
    require ghost_ActiveProtocolAdapterSet_EventCount == 0;
    require ghost_RebalanceDepositSuccess_EventCount == 0;
    require ghost_RebalanceCompleted_EventCount == 0;

    initiateRebalance@withrevert(e, newStrategy);

    assert !lastReverted;
    assert getActiveProtocolAdapter() == targetAdapter;
    assert ghost_RebalanceInitiated_EventCount == 1;
    assert ghost_RebalanceInitiated_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_RebalanceInitiated_Param_chainSelector == newStrategy.chainSelector;
    assert ghost_RebalanceInitiated_Param_protocolId == newStrategy.protocolId;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 1;
    assert ghost_RebalanceWithdrawSuccess_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_RebalanceWithdrawSuccess_Param_amount == amountOut;
    assert ghost_ActiveProtocolAdapterSet_EventCount == 1;
    assert ghost_ActiveProtocolAdapterSet_Param_protocolId == newStrategy.protocolId;
    assert ghost_ActiveProtocolAdapterSet_Param_adapter == targetAdapter;
    assert ghost_RebalanceDepositSuccess_EventCount == 1;
    assert ghost_RebalanceDepositSuccess_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_RebalanceDepositSuccess_Param_amount == amountOut;
    assert ghost_RebalanceCompleted_EventCount == 1;
    assert ghost_RebalanceCompleted_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_RebalanceCompleted_Param_newProtocolId == newStrategy.protocolId;
    assert ghost_RebalanceCompleted_Param_newChainSelector == newStrategy.chainSelector;
}

/// ─────────────────────────── CLOSE EPOCH ────────────────────────

/// @dev closeEpoch's internal settlement logic (fee accounting, netFlow calculation, all the
///      arithmetic overflow guards) is exhaustively verified in isolation in
///      ParentVaultEpochLib.spec (24 rules) - this section covers the vault-level entry point:
///      access control/pause/reentrancy/recovery guards, and the external-action dispatch that
///      lives in ParentVault.sol itself (_executeDeposit/_ccipSend/_executeWithdraw/events),
///      which the library spec cannot see since the library only returns the action to take.
///      Success rules below reuse the exact simplifying preconditions from the library spec's own
///      closeEpoch_Success_* rules (bootstrap/tvl==totalShares tricks to avoid performance fee
///      collection) rather than re-deriving the fee formula.

/// @notice Closing an epoch reverts when the caller lacks EPOCH_OPERATOR_ROLE
/// @dev Verifies that an unauthorized call leaves all vault state unchanged
rule closeEpoch_RevertWhen_CallerDoesNotHaveEPOCH_OPERATOR_ROLE() {
    env e;
    uint256 tvl;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require getEpochNonce() >= 1, "epoch nonce should never be zero";
    uint256 epochNonce = getEpochNonce();
    require epochNonce == 1 || getEpoch(assert_uint256(epochNonce - 1)).status == Types.EpochStatus.CLAIMABLE,
        "previous epoch should be claimable when required";
    require getEpoch(epochNonce).status == Types.EpochStatus.OPEN, "epoch should be open";
    require getEpoch(epochNonce).openedAtTimestamp <= max_uint256 - MIN_EPOCH_PERIOD(),
        "minimum epoch period addition should not overflow";
    require e.block.timestamp >= getEpoch(epochNonce).openedAtTimestamp + MIN_EPOCH_PERIOD(),
        "minimum epoch period should have elapsed";
    require getEpoch(epochNonce).totalDepositAmount != 0 || getEpoch(epochNonce).totalShareBurnAmount != 0,
        "epoch should not be empty";

    /// @dev revert condition being verified
    require !hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);


    closeEpoch@withrevert(e, tvl);

    assert lastReverted;
}

/// @notice Closing an epoch reverts when called during an active non-reentrant execution
/// @dev Verifies that a reentrant call leaves all vault state unchanged
rule closeEpoch_RevertWhen_ReentrantCall() {
    env e;
    uint256 tvl;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require getEpochNonce() >= 1, "epoch nonce should never be zero";
    uint256 epochNonce = getEpochNonce();
    require epochNonce == 1 || getEpoch(assert_uint256(epochNonce - 1)).status == Types.EpochStatus.CLAIMABLE,
        "previous epoch should be claimable when required";
    require getEpoch(epochNonce).status == Types.EpochStatus.OPEN, "epoch should be open";
    require getEpoch(epochNonce).openedAtTimestamp <= max_uint256 - MIN_EPOCH_PERIOD(),
        "minimum epoch period addition should not overflow";
    require e.block.timestamp >= getEpoch(epochNonce).openedAtTimestamp + MIN_EPOCH_PERIOD(),
        "minimum epoch period should have elapsed";
    require getEpoch(epochNonce).totalDepositAmount != 0 || getEpoch(epochNonce).totalShareBurnAmount != 0,
        "epoch should not be empty";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";


    closeEpoch@withrevert(e, tvl);

    assert lastReverted;
}

/// @notice Closing an epoch reverts when the vault is paused
/// @dev Verifies that a paused vault leaves all vault state unchanged
rule PAUSE_003_closeEpoch_RevertWhen_Paused() {
    env e;
    uint256 tvl;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require getEpochNonce() >= 1, "epoch nonce should never be zero";
    uint256 epochNonce = getEpochNonce();
    require epochNonce == 1 || getEpoch(assert_uint256(epochNonce - 1)).status == Types.EpochStatus.CLAIMABLE,
        "previous epoch should be claimable when required";
    require getEpoch(epochNonce).status == Types.EpochStatus.OPEN, "epoch should be open";
    require getEpoch(epochNonce).openedAtTimestamp <= max_uint256 - MIN_EPOCH_PERIOD(),
        "minimum epoch period addition should not overflow";
    require e.block.timestamp >= getEpoch(epochNonce).openedAtTimestamp + MIN_EPOCH_PERIOD(),
        "minimum epoch period should have elapsed";
    require getEpoch(epochNonce).totalDepositAmount != 0 || getEpoch(epochNonce).totalShareBurnAmount != 0,
        "epoch should not be empty";

    /// @dev revert condition being verified
    require paused(), "vault should be paused";


    closeEpoch@withrevert(e, tvl);

    assert lastReverted;
}

/// @notice Closing an epoch reverts when any recovery operation is already pending
/// @dev Verifies that a pending recovery cannot be overwritten by a new epoch close. This guard is
///      ParentVault-level (s_recoveryMode) and is not visible to ParentVaultEpochLib's own rules.
rule REC_003_closeEpoch_RevertWhen_RecoveryAlreadyPending() {
    env e;
    uint256 tvl;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";

    /// @dev revert condition being verified
    require getRecoveryMode() != Types.RecoveryMode.NONE, "recovery should be pending";


    closeEpoch@withrevert(e, tvl);

    assert lastReverted;
}

/// @notice Closing a net-deposit epoch with a local strategy deposits the delivered amount into the
///         active adapter and emits EpochDepositToStrategySuccess
/// @dev Run with ParentVault.localAdapter.conf so Certora resolves the active-adapter call.
rule EPOCH_004_EPOCH_014_NONCE_010_closeEpoch_DEPOSIT_TO_LOCAL_STRATEGY_Success() {
    env e;
    uint256 tvl;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require getEpochNonce() == 2, "use the first closable post-bootstrap epoch";
    uint256 epochNonce = getEpochNonce();
    require getEpoch(1).status == Types.EpochStatus.CLAIMABLE, "previous epoch should be claimable";
    require getEpoch(epochNonce).status == Types.EpochStatus.OPEN, "epoch should be open";
    require getEpoch(epochNonce).openedAtTimestamp <= max_uint256 - MIN_EPOCH_PERIOD(),
        "minimum epoch period addition should not overflow";
    require e.block.timestamp >= getEpoch(epochNonce).openedAtTimestamp + MIN_EPOCH_PERIOD(),
        "minimum epoch period should have elapsed";

    uint256 depositAmount = getEpoch(epochNonce).totalDepositAmount;

    /// @dev Use one concrete bootstrap deposit; settlement arithmetic is verified parametrically in
    ///      ParentVaultEpochLib.spec, while this rule verifies Parent's local-deposit dispatch.
    require getSharePrecision() == 1000000000000000000, "share precision should be 1e18";
    require getAssetPrecision() == 1000000, "asset precision should be 1e6";
    require getMinDepositAmount() == 1000000, "minimum deposit should be one asset unit";
    require getTotalShares() == 0, "use bootstrap settlement";
    require getPerformanceFeeHighWaterMark() >= getSharePrecision(), "performance fee should not be collected";
    require depositAmount == 1000000, "use one minimum deposit";
    require getEpoch(epochNonce).totalShareBurnAmount == 0, "no withdrawal intent";
    require tvl == 0, "bootstrap tvl should be zero";

    /// @dev local-strategy + adapter conditions
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require adapter != currentContract, "adapter should not be the vault";
    require !adapter.depositReverts(), "adapter deposit should not revert";

    require asset.balanceOf(currentContract) == depositAmount, "vault should hold the deposit amount";
    require asset.balanceOf(adapter) == 0, "adapter asset balance should start at zero";
    require adapter.getTVL() == 0, "adapter TVL should start at zero";

    /// @dev set ghost starting values
    require ghost_EpochDepositToStrategySuccess_EventCount == 0;
    require ghost_EpochOpen_EventCount == 0;

    closeEpoch@withrevert(e, tvl);

    assert !lastReverted;
    assert getEpoch(epochNonce).status == Types.EpochStatus.CLAIMABLE;
    assert ghost_EpochDepositToStrategySuccess_EventCount == 1;
    assert ghost_EpochDepositToStrategySuccess_Param_epochNonce == epochNonce;
    assert ghost_EpochDepositToStrategySuccess_Param_amount == depositAmount;
    assert getEpochNonce() == epochNonce + 1;
    assert ghost_EpochOpen_EventCount == 1;
    assert ghost_EpochOpen_Param_epochNonce == epochNonce + 1;
}

/// @notice Closing a net-deposit epoch with a local strategy reverts atomically (no recovery) when
///         the adapter deposit fails, since closeEpoch calls _executeDeposit with revertOnFailure=true
/// @dev Run with ParentVault.localAdapter.conf so Certora resolves the active-adapter call.
rule REC_009_closeEpoch_DEPOSIT_TO_LOCAL_STRATEGY_RevertWhen_DepositFails() {
    env e;
    uint256 tvl;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require getEpochNonce() >= 1, "epoch nonce should never be zero";
    uint256 epochNonce = getEpochNonce();
    require epochNonce == 1 || getEpoch(assert_uint256(epochNonce - 1)).status == Types.EpochStatus.CLAIMABLE,
        "previous epoch should be claimable when required";
    require getEpoch(epochNonce).status == Types.EpochStatus.OPEN, "epoch should be open";
    require getEpoch(epochNonce).openedAtTimestamp <= max_uint256 - MIN_EPOCH_PERIOD(),
        "minimum epoch period addition should not overflow";
    require e.block.timestamp >= getEpoch(epochNonce).openedAtTimestamp + MIN_EPOCH_PERIOD(),
        "minimum epoch period should have elapsed";

    uint256 depositAmount = getEpoch(epochNonce).totalDepositAmount;
    /// @dev Use the concrete bootstrap arithmetic fixture from the corresponding success rule;
    ///      settlement arithmetic is verified parametrically in ParentVaultEpochLib.spec.
    require getSharePrecision() == 1000000000000000000, "share precision should be 1e18";
    require getAssetPrecision() == 1000000, "asset precision should be 1e6";
    require getMinDepositAmount() == 1000000, "minimum deposit should be one asset unit";
    require getTotalShares() == 0, "use bootstrap settlement";
    require getPerformanceFeeHighWaterMark() >= getSharePrecision(), "performance fee should not be collected";
    require depositAmount == 1000000, "use one minimum deposit";
    require getEpoch(epochNonce).totalShareBurnAmount == 0, "no withdrawal intent";
    require tvl == 0, "bootstrap tvl should be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require asset.balanceOf(currentContract) == depositAmount, "vault should hold the deposit amount";
    require asset.balanceOf(adapter) == 0, "adapter asset balance should start at zero";
    require adapter.getTVL() == 0, "adapter TVL should start at zero";

    /// @dev revert condition being verified
    require adapter.depositReverts(), "adapter deposit should revert";


    closeEpoch@withrevert(e, tvl);

    assert lastReverted;
}

/// @notice Closing a net-deposit epoch with a remote strategy bridges the delivered amount to the
///         active strategy chain via CCIP and emits CCIPBridged
/// @dev BaseVaultCcipLib.spec already exhaustively verifies the underlying send mechanics (fee
///      calculation, approvals, router success/failure) in isolation; this rule verifies that
///      closeEpoch correctly reaches and delegates to _ccipSend with the right arguments, and that
///      the resulting balance/event effects are visible through the full closeEpoch call.
rule EPOCH_004_EPOCH_014_NONCE_010_closeEpoch_SEND_DEPOSIT_TO_REMOTE_STRATEGY_Success() {
    env e;
    uint256 tvl;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require getEpochNonce() >= 1, "epoch nonce should never be zero";
    require getEpochNonce() != max_uint256, "epoch nonce should not overflow on open";
    uint256 epochNonce = getEpochNonce();
    require epochNonce == 1 || getEpoch(assert_uint256(epochNonce - 1)).status == Types.EpochStatus.CLAIMABLE,
        "previous epoch should be claimable when required";
    require getEpoch(epochNonce).status == Types.EpochStatus.OPEN, "epoch should be open";
    require getEpoch(epochNonce).openedAtTimestamp <= max_uint256 - MIN_EPOCH_PERIOD(),
        "minimum epoch period addition should not overflow";
    require e.block.timestamp >= getEpoch(epochNonce).openedAtTimestamp + MIN_EPOCH_PERIOD(),
        "minimum epoch period should have elapsed";

    uint256 depositAmount = getEpoch(epochNonce).totalDepositAmount;

    /// @dev Use a concrete bootstrap settlement; arithmetic is verified parametrically in
    ///      ParentVaultEpochLib.spec, while this rule verifies Parent's remote-send dispatch.
    require getSharePrecision() == 1000000000000000000, "share precision should be 1e18";
    require getAssetPrecision() == 1000000, "asset precision should be 1e6";
    require getMinDepositAmount() == 1000000, "minimum deposit should be one asset unit";
    require getTotalShares() == 0, "use bootstrap settlement";
    require getPerformanceFeeHighWaterMark() >= getSharePrecision(), "performance fee should not be collected";
    require depositAmount == 1000000, "use one minimum deposit";
    require getEpoch(epochNonce).totalShareBurnAmount == 0, "no withdrawal intent";
    require tvl == 0, "bootstrap tvl should be zero";

    /// @dev remote-strategy + CCIP send conditions
    require getActiveProtocolAdapter() == 0, "no active adapter on this chain (remote strategy)";
    uint64 destinationChainSelector = getRebalance().activeStrategy.chainSelector;
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
    require vaultLinkBalanceBefore == fee, "vault should hold the CCIP fee";
    require routerLinkBalanceBefore == 0, "router LINK balance should start at zero";
    require vaultAssetBalanceBefore == depositAmount, "vault should hold the bridge amount";
    require routerAssetBalanceBefore == 0, "router asset balance should start at zero";

    /// @dev set ghost starting values
    require ghost_CCIPBridged_EventCount == 0;
    require ghost_EpochDepositExecuting_EventCount == 0;
    require ghost_EpochOpen_EventCount == 0;
    require ghost_totalShares_StoreCount == 0;

    closeEpoch@withrevert(e, tvl);

    assert !lastReverted;
    assert getEpoch(epochNonce).status == Types.EpochStatus.EXECUTING;
    assert ghost_CCIPBridged_EventCount == 1;
    assert ghost_CCIPBridged_Param_ccipMessageId != to_bytes32(0);
    assert ghost_CCIPBridged_Param_destinationChainSelector == destinationChainSelector;
    assert ghost_CCIPBridged_Param_ccipTxType == Types.CcipTx.EPOCH_NET_DEPOSIT;
    assert ccipRouter.getLastMessageDataHash()
        == hashBytes(encodeCcipTxData(Types.CcipTx.EPOCH_NET_DEPOSIT, encodeEpochNonce(epochNonce)));
    assert ghost_EpochDepositExecuting_EventCount == 1;
    assert ghost_EpochDepositExecuting_Param_epochNonce == epochNonce;
    assert ghost_EpochDepositExecuting_Param_amount == depositAmount;
    assert getEpochNonce() == epochNonce + 1;
    assert ghost_EpochOpen_EventCount == 1;
    assert ghost_EpochOpen_Param_epochNonce == epochNonce + 1;
}

/// @notice Closing a net-withdraw epoch with a local strategy withdraws the net amount from the
///         active adapter, finalizes the epoch as claimable, and emits EpochWithdrawFromStrategySuccess
/// @dev Run with ParentVault.localAdapter.conf so Certora resolves the active-adapter call.
rule EPOCH_004_EPOCH_014_NONCE_010_closeEpoch_WITHDRAW_FROM_LOCAL_STRATEGY_Success() {
    env e;
    uint256 tvl;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require getEpochNonce() >= 1, "epoch nonce should never be zero";
    require getEpochNonce() != max_uint256, "epoch nonce should not overflow on open";
    uint256 epochNonce = getEpochNonce();
    require epochNonce == 1 || getEpoch(assert_uint256(epochNonce - 1)).status == Types.EpochStatus.CLAIMABLE,
        "previous epoch should be claimable when required";
    require getEpoch(epochNonce).status == Types.EpochStatus.OPEN, "epoch should be open";
    require getEpoch(epochNonce).openedAtTimestamp <= max_uint256 - MIN_EPOCH_PERIOD(),
        "minimum epoch period addition should not overflow";
    require e.block.timestamp >= getEpoch(epochNonce).openedAtTimestamp + MIN_EPOCH_PERIOD(),
        "minimum epoch period should have elapsed";

    uint256 totalShares = getTotalShares();
    uint256 shareBurnAmount = getEpoch(epochNonce).totalShareBurnAmount;

    /// @dev Use a concrete half-withdraw settlement; arithmetic is verified parametrically in
    ///      ParentVaultEpochLib.spec, while this rule verifies Parent's local-withdraw dispatch.
    require getSharePrecision() == 1000000000000000000, "share precision should be 1e18";
    require totalShares == 1000000, "use one whole asset unit of shares";
    require tvl == 1000000, "use one whole asset unit of tvl";
    require getPerformanceFeeHighWaterMark() >= getSharePrecision(), "performance fee should not be collected";
    require getEpoch(epochNonce).totalDepositAmount == 0, "no deposits should be made";
    require shareBurnAmount == 500000, "withdraw half of the outstanding shares";

    /// @dev local-strategy + adapter conditions
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require adapter != currentContract, "adapter should not be the vault";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() == shareBurnAmount, "adapter should hold the requested amount";
    require asset.balanceOf(adapter) == shareBurnAmount, "adapter asset balance should cover the withdrawal";
    require asset.balanceOf(currentContract) == 0, "vault asset balance should start at zero";

    /// @dev set ghost starting values
    require ghost_EpochWithdrawFromStrategySuccess_EventCount == 0;
    require ghost_EpochClaimable_EventCount == 0;
    require ghost_EpochOpen_EventCount == 0;
    require ghost_totalShares_StoreCount == 0;

    closeEpoch@withrevert(e, tvl);

    assert !lastReverted;
    assert getEpoch(epochNonce).status == Types.EpochStatus.CLAIMABLE;
    assert ghost_EpochWithdrawFromStrategySuccess_EventCount == 1;
    assert ghost_EpochWithdrawFromStrategySuccess_Param_epochNonce == epochNonce;
    assert ghost_EpochWithdrawFromStrategySuccess_Param_amount == shareBurnAmount;
    assert ghost_EpochClaimable_EventCount == 1;
    assert ghost_EpochClaimable_Param_epochNonce == epochNonce;
    assert getEpochNonce() == epochNonce + 1;
    assert ghost_EpochOpen_EventCount == 1;
    assert ghost_EpochOpen_Param_epochNonce == epochNonce + 1;
}

/// @notice Closing a net-withdraw epoch with a local strategy reverts atomically (no recovery) when
///         the adapter withdraw fails, since closeEpoch calls _executeWithdraw with revertOnFailure=true
/// @dev Run with ParentVault.localAdapter.conf so Certora resolves the active-adapter call.
rule REC_009_closeEpoch_WITHDRAW_FROM_LOCAL_STRATEGY_RevertWhen_WithdrawFails() {
    env e;
    uint256 tvl;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require getEpochNonce() >= 1, "epoch nonce should never be zero";
    uint256 epochNonce = getEpochNonce();
    require epochNonce == 1 || getEpoch(assert_uint256(epochNonce - 1)).status == Types.EpochStatus.CLAIMABLE,
        "previous epoch should be claimable when required";
    require getEpoch(epochNonce).status == Types.EpochStatus.OPEN, "epoch should be open";
    require getEpoch(epochNonce).openedAtTimestamp <= max_uint256 - MIN_EPOCH_PERIOD(),
        "minimum epoch period addition should not overflow";
    require e.block.timestamp >= getEpoch(epochNonce).openedAtTimestamp + MIN_EPOCH_PERIOD(),
        "minimum epoch period should have elapsed";

    uint256 totalShares = getTotalShares();
    uint256 shareBurnAmount = getEpoch(epochNonce).totalShareBurnAmount;

    /// @dev Use a concrete half-withdraw settlement; arithmetic is verified parametrically in
    ///      ParentVaultEpochLib.spec, while this rule verifies Parent's failed local-withdraw path.
    require getSharePrecision() == 1000000000000000000, "share precision should be 1e18";
    require totalShares == 1000000, "use one whole asset unit of shares";
    require tvl == 1000000, "use one whole asset unit of tvl";
    require getPerformanceFeeHighWaterMark() >= getSharePrecision(), "performance fee should not be collected";
    require getEpoch(epochNonce).totalDepositAmount == 0, "no deposits should be made";
    require shareBurnAmount == 500000, "withdraw half of the outstanding shares";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";

    /// @dev revert condition being verified
    require adapter.withdrawReverts(), "adapter withdraw should revert";

    closeEpoch@withrevert(e, tvl);

    assert lastReverted;
}

/// @notice Closing a net-withdraw epoch with a remote strategy marks the epoch executing and emits
///         EpochWithdrawExecuting, without performing any external strategy action (CRE picks this up)
rule EPOCH_004_EPOCH_014_NONCE_010_closeEpoch_WAIT_FOR_REMOTE_WITHDRAW_Success() {
    env e;
    uint256 tvl;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require getEpochNonce() >= 1, "epoch nonce should never be zero";
    require getEpochNonce() != max_uint256, "epoch nonce should not overflow on open";
    uint256 epochNonce = getEpochNonce();
    require epochNonce == 1 || getEpoch(assert_uint256(epochNonce - 1)).status == Types.EpochStatus.CLAIMABLE,
        "previous epoch should be claimable when required";
    require getEpoch(epochNonce).status == Types.EpochStatus.OPEN, "epoch should be open";
    require getEpoch(epochNonce).openedAtTimestamp <= max_uint256 - MIN_EPOCH_PERIOD(),
        "minimum epoch period addition should not overflow";
    require e.block.timestamp >= getEpoch(epochNonce).openedAtTimestamp + MIN_EPOCH_PERIOD(),
        "minimum epoch period should have elapsed";

    uint256 totalShares = getTotalShares();
    uint256 shareBurnAmount = getEpoch(epochNonce).totalShareBurnAmount;

    /// @dev Use a concrete half-withdraw settlement; arithmetic is verified parametrically in
    ///      ParentVaultEpochLib.spec, while this rule verifies Parent's remote-withdraw path.
    require getSharePrecision() == 1000000000000000000, "share precision should be 1e18";
    require totalShares == 1000000, "use one whole asset unit of shares";
    require tvl == 1000000, "use one whole asset unit of tvl";
    require getPerformanceFeeHighWaterMark() >= getSharePrecision(), "performance fee should not be collected";
    require getEpoch(epochNonce).totalDepositAmount == 0, "no deposits should be made";
    require shareBurnAmount == 500000, "withdraw half of the outstanding shares";
    require getActiveProtocolAdapter() == 0, "no active adapter on this chain (remote strategy)";

    /// @dev set ghost starting values
    require ghost_EpochWithdrawExecuting_EventCount == 0;
    require ghost_EpochOpen_EventCount == 0;

    closeEpoch@withrevert(e, tvl);

    assert !lastReverted;
    assert getEpoch(epochNonce).status == Types.EpochStatus.EXECUTING;
    assert ghost_EpochWithdrawExecuting_EventCount == 1;
    assert ghost_EpochWithdrawExecuting_Param_epochNonce == epochNonce;
    assert ghost_EpochWithdrawExecuting_Param_amount == shareBurnAmount;
    assert getEpochNonce() == epochNonce + 1;
    assert ghost_EpochOpen_EventCount == 1;
    assert ghost_EpochOpen_Param_epochNonce == epochNonce + 1;
}

/// ───────────────────── COMPLETE EPOCH DEPOSIT ───────────────────

rule completeEpochDeposit_RevertWhen_ReentrantCall() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require getEpochNonce() > 1, "an epoch should have completed";
    uint256 epochNonce = assert_uint256(getEpochNonce() - 1);
    require getEpoch(epochNonce).totalDepositAmount > getEpoch(epochNonce).totalWithdrawClaimAmount,
        "previous epoch should be a net deposit";
    require getEpoch(epochNonce).status == Types.EpochStatus.EXECUTING, "previous epoch should be executing";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";

    completeEpochDeposit@withrevert(e);

    assert lastReverted;
}

rule completeEpochDeposit_RevertWhen_CallerDoesNotHaveEPOCH_OPERATOR_ROLE() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getEpochNonce() > 1, "an epoch should have completed";
    uint256 epochNonce = assert_uint256(getEpochNonce() - 1);
    require getEpoch(epochNonce).totalDepositAmount > getEpoch(epochNonce).totalWithdrawClaimAmount,
        "previous epoch should be a net deposit";
    require getEpoch(epochNonce).status == Types.EpochStatus.EXECUTING, "previous epoch should be executing";

    /// @dev revert condition being verified
    require !hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);

    completeEpochDeposit@withrevert(e);

    assert lastReverted;
}

rule EPOCH_014_completeEpochDeposit_RevertWhen_NoCompletedEpoch() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);

    /// @dev revert condition being verified
    require getEpochNonce() == 1, "no epoch should have completed";

    completeEpochDeposit@withrevert(e);

    assert lastReverted;
}

rule EPOCH_014_completeEpochDeposit_RevertWhen_PreviousEpochIsNotNetDeposit() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require getEpochNonce() > 1, "an epoch should have completed";
    uint256 epochNonce = assert_uint256(getEpochNonce() - 1);

    /// @dev revert condition being verified
    require getEpoch(epochNonce).totalDepositAmount <= getEpoch(epochNonce).totalWithdrawClaimAmount,
        "previous epoch should not be a net deposit";

    completeEpochDeposit@withrevert(e);

    assert lastReverted;
}

rule EPOCH_014_completeEpochDeposit_RevertWhen_PreviousEpochIsNotExecuting() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require getEpochNonce() > 1, "an epoch should have completed";
    uint256 epochNonce = assert_uint256(getEpochNonce() - 1);
    require getEpoch(epochNonce).totalDepositAmount > getEpoch(epochNonce).totalWithdrawClaimAmount,
        "previous epoch should be a net deposit";

    /// @dev revert condition being verified
    require getEpoch(epochNonce).status != Types.EpochStatus.EXECUTING,
        "previous epoch should not be executing";

    completeEpochDeposit@withrevert(e);

    assert lastReverted;
}

/// @notice A confirmed remote deposit becomes claimable even while the vault is paused
rule EPOCH_014_PAUSE_006_completeEpochDeposit_Success_WhenPaused() {
    env e;

    /// @dev success conditions being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require paused(), "vault should be paused";
    require getEpochNonce() > 1, "an epoch should have completed";
    uint256 epochNonce = assert_uint256(getEpochNonce() - 1);
    require getEpoch(epochNonce).totalDepositAmount > getEpoch(epochNonce).totalWithdrawClaimAmount,
        "previous epoch should be a net deposit";
    require getEpoch(epochNonce).status == Types.EpochStatus.EXECUTING, "previous epoch should be executing";
    require ghost_EpochClaimable_EventCount == 0;

    completeEpochDeposit@withrevert(e);

    assert !lastReverted;
    assert getEpoch(epochNonce).status == Types.EpochStatus.CLAIMABLE;
    assert ghost_EpochClaimable_EventCount == 1;
    assert ghost_EpochClaimable_Param_epochNonce == epochNonce;
}

/// ────────────────────────── COMPLETE REBALANCE ──────────────────

/// @dev finalizeRebalance's internal logic (nonce increment, strategy activation, management fee
///      formula) is exhaustively verified in isolation in ParentVaultRebalanceLib.spec (5 rules,
///      including the exact RebalanceNonceOverflows / LastCompletedTimestampIsFuture edge cases
///      that surfaced as gaps in the ccipReceive rules above). This section covers the vault-level
///      entry point: access control/reentrancy/recovery guards, and one delegation-sanity revert.

/// @notice Completing a rebalance reverts when the caller lacks REBALANCE_OPERATOR_ROLE
/// @dev Verifies that an unauthorized call leaves all vault state unchanged
rule completeRebalance_RevertWhen_CallerDoesNotHaveREBALANCE_OPERATOR_ROLE() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.REBALANCING, "rebalance should be in progress";

    /// @dev revert condition being verified
    require !hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);


    completeRebalance@withrevert(e);

    assert lastReverted;
}

/// @notice Completing a rebalance reverts when called during an active non-reentrant execution
/// @dev Verifies that a reentrant call leaves all vault state unchanged
rule completeRebalance_RevertWhen_ReentrantCall() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.REBALANCING, "rebalance should be in progress";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";


    completeRebalance@withrevert(e);

    assert lastReverted;
}

/// @notice Completing a rebalance reverts when any recovery operation is already pending
/// @dev Verifies that a pending recovery cannot be overwritten. This guard is ParentVault-level
///      (s_recoveryMode) and is not visible to ParentVaultRebalanceLib's own rules.
rule REC_003_completeRebalance_RevertWhen_RecoveryAlreadyPending() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";

    /// @dev revert condition being verified
    require getRecoveryMode() != Types.RecoveryMode.NONE, "recovery should be pending";


    completeRebalance@withrevert(e);

    assert lastReverted;
}

/// @notice Completing a rebalance reverts when no rebalance is in progress
/// @dev Verifies that the vault-level entry point correctly surfaces ParentVaultRebalanceLib's
///      guard (exhaustively covered in ParentVaultRebalanceLib.spec) and leaves vault state unchanged
rule completeRebalance_RevertWhen_NoRebalanceInProgress() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";

    /// @dev revert condition being verified
    require getRebalance().state != Types.RebalanceState.REBALANCING, "rebalance should not be in progress";


    completeRebalance@withrevert(e);

    assert lastReverted;
}

/// @notice Completing a rebalance activates the pending strategy, increments the rebalance nonce,
///         and mints the management fee to the treasury when fee shares are nonzero
rule FEE_002_FEE_004_NONCE_011_PAUSE_006_completeRebalance_Success_WhenManagementFeeSharesAreCollected() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().nonce < max_uint256, "rebalance nonce increment should not overflow";
    require getRebalance().lastRebalanceCompletedTimestamp < max_uint256,
        "management fee elapsed-time witness should not overflow";
    require e.block.timestamp == getRebalance().lastRebalanceCompletedTimestamp + 1,
        "management fee elapsed time should be one second";

    uint256 rebalanceNonce = getRebalance().nonce;
    bytes32 pendingProtocolId = getRebalance().pendingStrategy.protocolId;
    uint64 pendingChainSelector = getRebalance().pendingStrategy.chainSelector;
    uint256 totalShares = 315360000;
    uint256 feeShares = 1;
    address treasury = getTreasury();
    uint256 treasuryBalanceBefore = share.balanceOf(treasury);

    /// @dev Management-fee arithmetic and collection are verified in ParentVaultFeesLib.spec and
    ///      ParentVaultRebalanceLib.spec. Use their concrete one-share witness here to verify the
    ///      Parent entry point and finalization integration.
    require getRebalance().state == Types.RebalanceState.REBALANCING, "rebalance should be in progress";
    require getTotalShares() == totalShares, "management fee should round up to one share";
    require treasuryBalanceBefore < max_uint256, "treasury share balance should not overflow";
    require share.totalSupply() < max_uint256, "share total supply should not overflow";

    /// @dev set ghost starting values
    require ghost_RebalanceCompleted_EventCount == 0;
    require ghost_ManagementFeeCollected_EventCount == 0;

    completeRebalance@withrevert(e);

    assert !lastReverted;
    assert getRebalance().nonce == rebalanceNonce + 1;
    assert getRebalance().state == Types.RebalanceState.NONE;
    assert getRebalance().activeStrategy.protocolId == pendingProtocolId;
    assert getRebalance().activeStrategy.chainSelector == pendingChainSelector;
    assert getRebalance().pendingStrategy.protocolId == to_bytes32(0);
    assert getRebalance().pendingStrategy.chainSelector == 0;
    assert getRebalance().lastRebalanceCompletedTimestamp == e.block.timestamp;
    assert getTotalShares() == totalShares + feeShares;
    assert share.balanceOf(treasury) == treasuryBalanceBefore + feeShares;
    assert ghost_RebalanceCompleted_EventCount == 1;
    assert ghost_RebalanceCompleted_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_RebalanceCompleted_Param_newProtocolId == pendingProtocolId;
    assert ghost_RebalanceCompleted_Param_newChainSelector == pendingChainSelector;
    assert ghost_ManagementFeeCollected_EventCount == 1;
    assert ghost_ManagementFeeCollected_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_ManagementFeeCollected_Param_feeShares == feeShares;
}

/// ────────────────────────── EXECUTE RECOVERY ────────────────────

/// @dev _recoverFailedRebalanceDeposit's internal logic (NoActiveAdapter/DepositFails reverts,
///      recovery clearing, balance/TVL updates) is exhaustively verified in isolation in
///      BaseVault.spec (which also runs against ParentVaultHarness) via the
///      recoverFailedRebalanceDepositInternal harness wrapper. finalizeRebalance's internal logic
///      is exhaustively verified in ParentVaultRebalanceLib.spec. This section covers the
///      vault-level entry point: the reentrancy guard, the top-level recovery-mode check, and that
///      executeRecovery correctly chains recovery completion into finalizeRebalance (which
///      recoverFailedRebalanceDepositInternal's own harness wrapper does not do).

/// @notice Executing recovery reverts when called during an active non-reentrant execution
/// @dev Verifies that a reentrant call leaves all vault state unchanged
rule executeRecovery_RevertWhen_ReentrantCall() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT,
        "rebalance deposit recovery should be pending";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";


    executeRecovery@withrevert(e);

    assert lastReverted;
}

rule PAUSE_003_REC_008_executeRecovery_RevertWhen_Paused() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT,
        "rebalance deposit recovery should be pending";

    /// @dev revert condition being verified
    require paused(), "vault should be paused";

    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice Executing recovery reverts when no recovery is pending
/// @dev Verifies that ParentVault's own top-level guard (distinct from, but consistent with,
///      _requireRebalanceDepositRecovery's own check inside _recoverFailedRebalanceDeposit) leaves
///      all vault state unchanged
rule REC_008_executeRecovery_RevertWhen_NoPendingRecovery() {
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

/// @notice Executing recovery reverts when the recovery redeposit has no active adapter to target
/// @dev Verifies that ParentVault's entry point propagates the internal recovery-redeposit revert
///      (exhaustively covered in isolation in BaseVault.spec via recoverFailedRebalanceDepositInternal)
///      instead of chaining into finalizeRebalance, leaving all vault state - including the
///      rebalance nonce and state - unchanged
rule REC_005_REC_009_executeRecovery_RevertWhen_NoActiveAdapter() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT,
        "rebalance deposit recovery should be pending";
    require !adapter.depositReverts(), "adapter deposit should not revert";

    /// @dev revert condition being verified
    require getActiveProtocolAdapter() == 0, "active adapter should not be set";


    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice Executing recovery reverts when the recovery redeposit into the active adapter fails
/// @dev Verifies that ParentVault's entry point propagates the internal recovery-redeposit revert
///      (exhaustively covered in isolation in BaseVault.spec via recoverFailedRebalanceDepositInternal)
///      instead of chaining into finalizeRebalance, leaving all vault state - including the
///      rebalance nonce and state - unchanged
rule REC_005_executeRecovery_RevertWhen_DepositFails() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT,
        "rebalance deposit recovery should be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";

    /// @dev revert condition being verified
    require adapter.depositReverts(), "adapter deposit should revert";


    executeRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice Executing recovery deposits the stored recovery amount into the active adapter, clears
///         the recovery, and finalizes the rebalance (activating the pending strategy)
rule FEE_004_NONCE_011_REC_001_REC_004_REC_007_executeRecovery_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT,
        "rebalance deposit recovery should be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.depositReverts(), "adapter deposit should not revert";
    require adapter != currentContract, "adapter should not be the vault";

    uint256 recoveryNonceBefore = getRebalanceDepositRecovery().rebalanceNonce;
    uint256 recoveryAmountBefore = getRebalanceDepositRecovery().amount;

    /// @dev Recovery-deposit token and adapter accounting is verified parametrically by
    ///      recoverFailedRebalanceDepositInternal_Success in BaseVault.spec. Use a concrete
    ///      one-asset recovery here to verify Parent's recovery-to-finalization integration.
    require recoveryAmountBefore == 1000000, "recover one whole asset unit";
    require asset.balanceOf(currentContract) == recoveryAmountBefore, "vault should cover the recovery amount";
    require asset.balanceOf(adapter) == 0, "adapter asset balance should start at zero";
    require adapter.getTVL() == 0, "adapter TVL should start at zero";

    /// @dev finalizeRebalance conditions for the no-management-fee path
    require getRebalance().nonce < max_uint256, "rebalance nonce increment should not overflow";
    require getRebalance().lastRebalanceCompletedTimestamp <= e.block.timestamp,
        "management fee elapsed time should not underflow";
    uint256 rebalanceNonce = getRebalance().nonce;
    bytes32 pendingProtocolId = getRebalance().pendingStrategy.protocolId;
    uint64 pendingChainSelector = getRebalance().pendingStrategy.chainSelector;
    require getRebalance().state == Types.RebalanceState.REBALANCING, "rebalance should be in progress";
    require getTotalShares() == 0, "no management fee shares should be collected";

    /// @dev set ghost starting values
    require ghost_RebalanceDepositRecoveryCleared_EventCount == 0;
    require ghost_RebalanceDepositSuccess_EventCount == 0;
    require ghost_RebalanceCompleted_EventCount == 0;
    require ghost_ManagementFeeCollected_EventCount == 0;

    executeRecovery@withrevert(e);

    assert !lastReverted;
    assert getRecoveryMode() == Types.RecoveryMode.NONE;
    assert getRebalanceDepositRecovery().rebalanceNonce == 0;
    assert getRebalanceDepositRecovery().amount == 0;
    assert ghost_RebalanceDepositSuccess_EventCount == 1;
    assert ghost_RebalanceDepositSuccess_Param_rebalanceNonce == recoveryNonceBefore;
    assert ghost_RebalanceDepositSuccess_Param_amount == recoveryAmountBefore;
    assert ghost_RebalanceDepositRecoveryCleared_EventCount == 1;
    assert ghost_RebalanceDepositRecoveryCleared_Param_rebalanceNonce == recoveryNonceBefore;
    assert getRebalance().nonce == rebalanceNonce + 1;
    assert getRebalance().state == Types.RebalanceState.NONE;
    assert getRebalance().activeStrategy.protocolId == pendingProtocolId;
    assert getRebalance().activeStrategy.chainSelector == pendingChainSelector;
    assert getRebalance().pendingStrategy.protocolId == to_bytes32(0);
    assert getRebalance().pendingStrategy.chainSelector == 0;
    assert getRebalance().lastRebalanceCompletedTimestamp == e.block.timestamp;
    assert ghost_RebalanceCompleted_EventCount == 1;
    assert ghost_RebalanceCompleted_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_RebalanceCompleted_Param_newProtocolId == pendingProtocolId;
    assert ghost_RebalanceCompleted_Param_newChainSelector == pendingChainSelector;
    assert ghost_ManagementFeeCollected_EventCount == 0;
}

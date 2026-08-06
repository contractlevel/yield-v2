using MockAdapterRegistry as adapterRegistry;
using MockProtocolAdapter as adapter;
using MockInvalidProtocolAdapter as invalidAdapter;
using MockUSDC as asset;
using MockLINK as link;
using MockCCIPRouter as ccipRouter;
using MockYieldcoinShare as share;
using MockPolicyEngine as policyEngine;

/// Verification of ParentVault-specific behavior
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
    function initialize(BaseVault.InitParams, address, address, address) external;
    function setInitialActiveProtocolAdapter(bytes32) external;
    function setTreasury(address) external;
    function deposit(uint256) external returns (uint256);
    function withdraw(uint256) external returns (uint256);
    function claimShares(uint256) external returns (uint256);
    function claimAsset(uint256) external returns (uint256);
    function cancelDeposit() external;
    function cancelWithdraw() external;
    function ccipReceive(Client.Any2EVMMessage) external;
    function closeEpoch(uint256) external;
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
/// @notice ParentVaultHarness/HelperHarness functions that exist only for isolated CVL testing and
///         are never callable through the real, deployed ParentVault interface
/// @dev Excluded from parametric "any method" rules/invariants below: enumerating them alongside
///      real entry points only inflates the method count and, for the state-changing ones
///      (recoverFailedRebalanceDepositInternal, executeDeposit, executeWithdraw, etc.), lets Certora
///      reach unrealistic prestates (e.g. an unconstrained s_rebalanceDepositRecovery/activeAdapter)
///      that no real caller could ever produce through ParentVault's actual entry points.
definition isHarnessHelper(method f) returns bool =
    // ParentVaultHarness internal-logic wrappers
    f.selector == sig:initializeBaseVault(BaseVault.InitParams).selector ||
    f.selector == sig:isInitialized().selector ||
    f.selector == sig:isInitializing().selector ||
    f.selector == sig:revertIfZeroAddress(address).selector ||
    f.selector == sig:revertIfZeroAmount(uint256).selector ||
    f.selector == sig:revertIfZeroChainSelector(uint64).selector ||
    f.selector == sig:storeRebalanceDepositRecovery(uint256,uint256).selector ||
    f.selector == sig:clearRebalanceDepositRecovery().selector ||
    f.selector == sig:requireRebalanceDepositRecovery().selector ||
    f.selector == sig:recoverFailedRebalanceDepositInternal().selector ||
    f.selector == sig:executeDeposit(uint256,bool).selector ||
    f.selector == sig:executeWithdraw(uint256,bool).selector ||
    f.selector == sig:handleCCIPRebalance(uint256,bytes32,uint256).selector ||
    f.selector == sig:requireNoRecovery().selector ||
    f.selector == sig:requireRecoveryMode(Types.RecoveryMode).selector ||
    f.selector == sig:authorizeUpgrade(address).selector ||
    f.selector == sig:getRecoveryRebalanceNonce().selector ||
    f.selector == sig:getRecoveryAmount().selector ||
    f.selector == sig:getRecoveryCreatedAt().selector ||
    f.selector == sig:policyProtectedInterfaceId().selector ||
    // HelperHarness generic encode/decode/introspection utilities
    f.selector == sig:reentrancyGuardEntered().selector ||
    f.selector == sig:bytes32ToAddress(bytes32).selector ||
    f.selector == sig:bytes32ToUint256(bytes32).selector ||
    f.selector == sig:bytes32ToUint8(bytes32).selector ||
    f.selector == sig:uint8ToCcipTxType(uint8).selector ||
    f.selector == sig:bytes32ToUint64(bytes32).selector ||
    f.selector == sig:bytes32ToBytes4(bytes32).selector ||
    f.selector == sig:bytes32ToBytes10(bytes32).selector ||
    f.selector == sig:bytes32ToBool(bytes32).selector ||
    f.selector == sig:bytesToAddress(bytes).selector ||
    f.selector == sig:bytesToAddressArray(bytes).selector ||
    f.selector == sig:encodeAddress(address).selector ||
    f.selector == sig:encodeEpochNonce(uint256).selector ||
    f.selector == sig:encodeRebalanceData(uint256,bytes32).selector ||
    f.selector == sig:encodeCcipTxData(Types.CcipTx,bytes).selector ||
    f.selector == sig:hashBytes(bytes).selector ||
    f.selector == sig:encodeRawCcipTxData(uint256,bytes).selector ||
    f.selector == sig:decodeCcipTxType(bytes).selector ||
    f.selector == sig:decodeCcipTxPayload(bytes).selector ||
    f.selector == sig:emptyParameters().selector ||
    f.selector == sig:erc165InterfaceId().selector ||
    f.selector == sig:accessControlDefaultAdminRulesInterfaceId().selector ||
    f.selector == sig:any2EVMMessageReceiverInterfaceId().selector ||
    // HelperHarness role-hash getters
    f.selector == sig:UPGRADER_ROLE().selector ||
    f.selector == sig:PAUSER_ROLE().selector ||
    f.selector == sig:UNPAUSER_ROLE().selector ||
    f.selector == sig:CONFIG_OPERATOR_ROLE().selector ||
    f.selector == sig:REBALANCE_OPERATOR_ROLE().selector ||
    f.selector == sig:EPOCH_OPERATOR_ROLE().selector ||
    f.selector == sig:LINK_OPERATOR_ROLE().selector ||
    f.selector == sig:DONATE_OPERATOR_ROLE().selector ||
    f.selector == sig:COMPLIANCE_OPERATOR_ROLE().selector ||
    f.selector == sig:EMERGENCY_DRAINER_ROLE().selector ||
    f.selector == sig:KEYSTONE_FORWARDER_ROLE().selector ||
    f.selector == sig:POLICY_ENGINE_MANAGER_ROLE().selector ||
    f.selector == sig:MINTER_ROLE().selector ||
    f.selector == sig:BURNER_ROLE().selector ||
    f.selector == sig:REWARDS_OPERATOR_ROLE().selector;

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

definition WithdrawCancelledEvent() returns bytes32 =
// keccak256("WithdrawCancelled(uint256,address,uint256)")
    to_bytes32(0x769d7210521411ed9ffb77cf3eacdd55cfde3d8dd5f99d7a6a908969b327b06f);

definition EpochOpenEvent() returns bytes32 =
// keccak256("EpochOpen(uint256)")
    to_bytes32(0x581f6669baee8fbb7926034742085996de6e2c904da8849660716d60148f9f3b);

definition EpochExecutingEvent() returns bytes32 =
// keccak256("EpochExecuting(uint256,uint256)")
    to_bytes32(0x30e0436ea7b69c1a8f2e5bb2b2257e44265bbf353d198f3823c1726fe558f0cd);

definition EpochClaimableEvent() returns bytes32 =
// keccak256("EpochClaimable(uint256)")
    to_bytes32(0x45d9681f238e455170e797872754deaef148c9e7836f9949104764a4f4cfae8a);

definition EpochWithdrawAmountShortEvent() returns bytes32 =
// keccak256("EpochWithdrawAmountShort(uint256,uint256,uint256)")
    to_bytes32(0x9087919bbb431a8a7241eebf12465b469fe3f4f78eeda82d3e47d41378977695);

definition RebalanceInitiatedEvent() returns bytes32 =
// keccak256("RebalanceInitiated(uint256,uint64,bytes32)")
    to_bytes32(0x504cda215d13450a995b166366ceb2adb48e0ff5c4068d0d8e4208011f32972a);

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

/// @dev IBaseVault events emitted directly from ParentVault.sol's closeEpoch. Tracked here because
///      this ParentVault call site is not covered by BaseVault.spec.
definition DepositToStrategySuccessEvent() returns bytes32 =
// keccak256("DepositToStrategySuccess(uint256,uint256)")
    to_bytes32(0x822db7c313fcf6d7b9ea5da5e0e6f3d27317446731e4016faa07a1127bb0a1c4);

definition WithdrawFromStrategySuccessEvent() returns bytes32 =
// keccak256("WithdrawFromStrategySuccess(uint256,uint256)")
    to_bytes32(0xb38981e8f1428114c35ad63ef9ab14a90a34bc12cac0782d420baab4522a659f);

/// @dev BaseVaultCcipLib event emitted directly from ParentVault.sol's closeEpoch remote-deposit
///      branch (via _ccipSend). Tracked here because this ParentVault call site is not covered by
///      BaseVault.spec.
definition CCIPBridgedEvent() returns bytes32 =
// keccak256("CCIPBridged(bytes32,uint256,uint8)")
    to_bytes32(0x39e716d942b34d57d78c584f648ec8e13b9621c6e5b1a57d18ef47a98b11b39d);

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

/// ─── Event: DepositToStrategySuccess ───────────────────────────
ghost mathint ghost_DepositToStrategySuccess_EventCount {
    init_state axiom ghost_DepositToStrategySuccess_EventCount == 0;
}
ghost uint256 ghost_DepositToStrategySuccess_Param_epochNonce {
    init_state axiom ghost_DepositToStrategySuccess_Param_epochNonce == 0;
}
ghost uint256 ghost_DepositToStrategySuccess_Param_amount {
    init_state axiom ghost_DepositToStrategySuccess_Param_amount == 0;
}

/// ─── Event: WithdrawFromStrategySuccess ────────────────────────
ghost mathint ghost_WithdrawFromStrategySuccess_EventCount {
    init_state axiom ghost_WithdrawFromStrategySuccess_EventCount == 0;
}
ghost uint256 ghost_WithdrawFromStrategySuccess_Param_epochNonce {
    init_state axiom ghost_WithdrawFromStrategySuccess_Param_epochNonce == 0;
}
ghost uint256 ghost_WithdrawFromStrategySuccess_Param_amount {
    init_state axiom ghost_WithdrawFromStrategySuccess_Param_amount == 0;
}

/// ─── Event: CCIPBridged ─────────────────────────────────────────
ghost mathint ghost_CCIPBridged_EventCount {
    init_state axiom ghost_CCIPBridged_EventCount == 0;
}
ghost bytes32 ghost_CCIPBridged_Param_ccipMessageId {
    init_state axiom ghost_CCIPBridged_Param_ccipMessageId == to_bytes32(0);
}
ghost uint256 ghost_CCIPBridged_Param_amount {
    init_state axiom ghost_CCIPBridged_Param_amount == 0;
}
ghost Types.CcipTx ghost_CCIPBridged_Param_ccipTxType {
    init_state axiom ghost_CCIPBridged_Param_ccipTxType == Types.CcipTx.EPOCH_NET_DEPOSIT;
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

/// ─── Event: EpochExecuting ────────────────────────────────────────
ghost mathint ghost_EpochExecuting_EventCount {
    init_state axiom ghost_EpochExecuting_EventCount == 0;
}
ghost uint256 ghost_EpochExecuting_Param_epochNonce {
    init_state axiom ghost_EpochExecuting_Param_epochNonce == 0;
}
ghost uint256 ghost_EpochExecuting_Param_amount {
    init_state axiom ghost_EpochExecuting_Param_amount == 0;
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
ghost uint256 ghost_PerformanceFeeCollected_Param_highWaterMark {
    init_state axiom ghost_PerformanceFeeCollected_Param_highWaterMark == 0;
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

/// ─── Ghost-sum accumulators (SOLV-001 / SOLV-003 / SHARE-001) ─────
/// @dev These mirror per-key storage fields and maintain running sums across the unbounded
///      s_epochs/s_withdraws key space, updated via the Sstore hooks below. Needed because the
///      solvency/accounting invariants in the INVARIANTS section must hold across every epoch nonce
///      and user simultaneously, not just a fixed key the way the per-function Success rules do.
ghost mapping(uint256 => uint256) ghost_epochRemainingWithdrawClaimAmount {
    init_state axiom forall uint256 epochNonce. ghost_epochRemainingWithdrawClaimAmount[epochNonce] == 0;
}
ghost mapping(uint256 => Types.EpochStatus) ghost_epochStatus {
    init_state axiom forall uint256 epochNonce. ghost_epochStatus[epochNonce] == Types.EpochStatus.NONE;
}
ghost mathint ghost_sumClaimableWithdrawObligation {
    init_state axiom ghost_sumClaimableWithdrawObligation == 0;
}
ghost mathint ghost_sumWithdrawEscrow {
    init_state axiom ghost_sumWithdrawEscrow == 0;
}
ghost mathint ghost_sumPendingShareMint {
    init_state axiom ghost_sumPendingShareMint == 0;
}
ghost mathint ghost_sumPendingShareBurn {
    init_state axiom ghost_sumPendingShareBurn == 0;
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
    /// @dev SHARE-001: running sum of shares already counted in s_totalShares but not yet minted
    ghost_sumPendingShareMint = ghost_sumPendingShareMint + newValue - oldValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_epochs[KEY uint256 epochNonce].remainingShareBurnAmount
    uint256 newValue (uint256 oldValue) {
    ghost_epoch_remainingShareBurnAmount_StoreCount = ghost_epoch_remainingShareBurnAmount_StoreCount + 1;
    ghost_epoch_remainingShareBurnAmount_StoredKey = epochNonce;
    ghost_epoch_remainingShareBurnAmount_StoredValue = newValue;
    /// @dev SHARE-001: running sum of shares already excluded from s_totalShares but not yet burned
    ghost_sumPendingShareBurn = ghost_sumPendingShareBurn + newValue - oldValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_epochs[KEY uint256 epochNonce].remainingWithdrawClaimAmount
    uint256 newValue (uint256 oldValue) {
    ghost_epoch_remainingWithdrawClaimAmount_StoreCount = ghost_epoch_remainingWithdrawClaimAmount_StoreCount + 1;
    ghost_epoch_remainingWithdrawClaimAmount_StoredKey = epochNonce;
    ghost_epoch_remainingWithdrawClaimAmount_StoredValue = newValue;
    /// @dev SOLV-001: only accumulate while this epoch is already CLAIMABLE. The closeEpoch write that
    ///      first sets this field always precedes the status write that transitions into CLAIMABLE
    ///      (see the status hook below), so ghost_epochStatus[epochNonce] still holds the pre-close
    ///      status here and this correctly skips the initial write; the status hook picks it up instead.
    if (ghost_epochStatus[epochNonce] == Types.EpochStatus.CLAIMABLE) {
        ghost_sumClaimableWithdrawObligation = ghost_sumClaimableWithdrawObligation + newValue - oldValue;
    }
    ghost_epochRemainingWithdrawClaimAmount[epochNonce] = newValue;
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
    /// @dev SOLV-001: pick up the remainingWithdrawClaimAmount that was already written earlier in
    ///      the same closeEpoch call, now that this epoch is entering/leaving CLAIMABLE
    if (newValue == Types.EpochStatus.CLAIMABLE && oldValue != Types.EpochStatus.CLAIMABLE) {
        ghost_sumClaimableWithdrawObligation =
            ghost_sumClaimableWithdrawObligation + ghost_epochRemainingWithdrawClaimAmount[epochNonce];
    } else if (oldValue == Types.EpochStatus.CLAIMABLE && newValue != Types.EpochStatus.CLAIMABLE) {
        ghost_sumClaimableWithdrawObligation =
            ghost_sumClaimableWithdrawObligation - ghost_epochRemainingWithdrawClaimAmount[epochNonce];
    }
    ghost_epochStatus[epochNonce] = newValue;
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
    /// @dev SOLV-003: running sum of shares escrowed against outstanding withdraw intents
    ghost_sumWithdrawEscrow = ghost_sumWithdrawEscrow + newValue - oldValue;
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
    if (t0 == EpochExecutingEvent()) {
        ghost_EpochExecuting_EventCount = ghost_EpochExecuting_EventCount + 1;
        ghost_EpochExecuting_Param_epochNonce = bytes32ToUint256(t1);
        ghost_EpochExecuting_Param_amount = bytes32ToUint256(t2);
    } else if (t0 == ManagementFeeCollectedEvent()) {
        ghost_ManagementFeeCollected_EventCount = ghost_ManagementFeeCollected_EventCount + 1;
        ghost_ManagementFeeCollected_Param_rebalanceNonce = bytes32ToUint256(t1);
        ghost_ManagementFeeCollected_Param_feeShares = bytes32ToUint256(t2);
    } else if (t0 == DepositToStrategySuccessEvent()) {
        ghost_DepositToStrategySuccess_EventCount = ghost_DepositToStrategySuccess_EventCount + 1;
        ghost_DepositToStrategySuccess_Param_epochNonce = bytes32ToUint256(t1);
        ghost_DepositToStrategySuccess_Param_amount = bytes32ToUint256(t2);
    } else if (t0 == WithdrawFromStrategySuccessEvent()) {
        ghost_WithdrawFromStrategySuccess_EventCount = ghost_WithdrawFromStrategySuccess_EventCount + 1;
        ghost_WithdrawFromStrategySuccess_Param_epochNonce = bytes32ToUint256(t1);
        ghost_WithdrawFromStrategySuccess_Param_amount = bytes32ToUint256(t2);
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
    } else if (t0 == EpochWithdrawAmountShortEvent()) {
        ghost_EpochWithdrawAmountShort_EventCount = ghost_EpochWithdrawAmountShort_EventCount + 1;
        ghost_EpochWithdrawAmountShort_Param_epochNonce = bytes32ToUint256(t1);
        ghost_EpochWithdrawAmountShort_Param_expectedAmount = bytes32ToUint256(t2);
        ghost_EpochWithdrawAmountShort_Param_actualAmount = bytes32ToUint256(t3);
    } else if (t0 == RebalanceInitiatedEvent()) {
        ghost_RebalanceInitiated_EventCount = ghost_RebalanceInitiated_EventCount + 1;
        ghost_RebalanceInitiated_Param_rebalanceNonce = bytes32ToUint256(t1);
        ghost_RebalanceInitiated_Param_chainSelector = bytes32ToUint64(t2);
        ghost_RebalanceInitiated_Param_protocolId = t3;
    } else if (t0 == RebalanceCompletedEvent()) {
        ghost_RebalanceCompleted_EventCount = ghost_RebalanceCompleted_EventCount + 1;
        ghost_RebalanceCompleted_Param_rebalanceNonce = bytes32ToUint256(t1);
        ghost_RebalanceCompleted_Param_newProtocolId = t2;
        ghost_RebalanceCompleted_Param_newChainSelector = bytes32ToUint64(t3);
    } else if (t0 == PerformanceFeeCollectedEvent()) {
        ghost_PerformanceFeeCollected_EventCount = ghost_PerformanceFeeCollected_EventCount + 1;
        ghost_PerformanceFeeCollected_Param_epochNonce = bytes32ToUint256(t1);
        ghost_PerformanceFeeCollected_Param_feeShares = bytes32ToUint256(t2);
        ghost_PerformanceFeeCollected_Param_highWaterMark = bytes32ToUint256(t3);
    } else if (t0 == CCIPBridgedEvent()) {
        ghost_CCIPBridged_EventCount = ghost_CCIPBridged_EventCount + 1;
        ghost_CCIPBridged_Param_ccipMessageId = t1;
        ghost_CCIPBridged_Param_amount = bytes32ToUint256(t2);
        ghost_CCIPBridged_Param_ccipTxType = uint8ToCcipTxType(bytes32ToUint8(t3));
    }
}

/*//////////////////////////////////////////////////////////////
                           INVARIANTS
//////////////////////////////////////////////////////////////*/
/// @dev BaseVault-level invariants (validParentChainSelector-equivalent, noZeroChainSelector,
///      noZeroAssetPrecision) are already covered by BaseVault.spec running against ParentVaultHarness
///      and are not duplicated here.

/// @notice ParentVault only ever stores the REBALANCE_DEPOSIT recovery mode
/// @dev Verifies s_recoveryMode is always NONE or REBALANCE_DEPOSIT on ParentVault. The other four
///      Types.RecoveryMode values (REBALANCE_WITHDRAW, EPOCH_DEPOSIT, EPOCH_WITHDRAW, CCIP_SEND) are
///      exclusively written by ChildVault-side code paths.
invariant recoveryModeIsRestrictedToRebalanceDeposit()
    getRecoveryMode() == Types.RecoveryMode.NONE || getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT
    filtered {
        f -> !isHarnessHelper(f) && f.selector != sig:upgradeToAndCall(address,bytes).selector
    }

/// @notice The epoch nonce is initialized to 1 and only ever increments
/// @dev Verifies s_epochNonce is never zero, supporting the `epochNonce - 1` arithmetic used
///      elsewhere in ParentVaultEpochLib and ParentVaultCcipLib. Guarded by getTreasury() != 0
///      (set unconditionally, and only, by initialize()) rather than isInitialized(): the harness's
///      isInitialized() reads OZ's shared _initialized version slot, which BaseVault's constructor
///      already sets to a nonzero sentinel via _disableInitializers() - so isInitialized() is true
///      immediately after construction, before ParentVault.initialize() ever runs, and before
///      s_epochNonce is actually set. getTreasury() is untouched by the constructor and only ever
///      written by initialize(), so it reliably tracks "has ParentVault's own initializer run."
/// @dev getTreasury() != 0 is only a sound "has initialize() run" signal if nothing else can flip it
///      from 0 to nonzero. In reality only initialize() can, since setTreasury() requires
///      CONFIG_OPERATOR_ROLE, which is only ever granted inside initialize() - but that fact isn't
///      part of this invariant's own predicate, so an unconstrained prestate could otherwise have an
///      account already (unrealistically) holding that role while treasury/epochNonce are still
///      unset, letting setTreasury() alone flip the guard true without epochNonce ever being set.
///      The preserved block below excludes that by requiring the guard already held in the prestate
///      for every method except initialize() itself, which is the one real 0-to-nonzero transition
///      (and sets s_epochNonce atomically in the same call).
invariant epochNonceIsNeverZero()
    getTreasury() != 0 => getEpochNonce() >= 1
    filtered {
        f -> !isHarnessHelper(f) && f.selector != sig:upgradeToAndCall(address,bytes).selector
    }
    {
        preserved {
            require getTreasury() != 0;
        }
        preserved initialize(
            BaseVault.InitParams params, address treasury, address policyEngineManager, address newPolicyEngine
        ) with (env e) {
        }
    }

/// @notice The current epoch (indexed by s_epochNonce) is always OPEN once the vault is initialized
/// @dev Verifies docs/INVARIANTS.md EPOCH-001. Guarded by getTreasury() != 0 rather than
///      isInitialized() - see epochNonceIsNeverZero above for why isInitialized() is unreliable here
///      (BaseVault's constructor already makes it true via _disableInitializers(), independent of
///      whether ParentVault.initialize() has actually run). Same preserved-block reasoning as
///      epochNonceIsNeverZero above applies here too.
invariant EPOCH_001_currentEpochIsOpen()
    getTreasury() != 0 => getEpoch(getEpochNonce()).status == Types.EpochStatus.OPEN
    filtered {
        f -> !isHarnessHelper(f) && f.selector != sig:upgradeToAndCall(address,bytes).selector
    }
    {
        preserved {
            require getTreasury() != 0;
        }
        preserved initialize(
            BaseVault.InitParams params, address treasury, address policyEngineManager, address newPolicyEngine
        ) with (env e) {
        }
    }

/// @notice Any epoch nonce beyond the current one has never been touched
/// @dev Supporting invariant for epochRemainingCountersAreZeroBeforeClose below. s_epochNonce only
///      ever increments (openNextEpoch), so in every reachable state an epoch nonce greater than the
///      current one has status NONE - but nothing states that fact on its own, so Certora's
///      unconstrained induction prestate could otherwise let a "future" epoch nonce already carry
///      leftover non-NONE status/fields from an impossible history, which openNextEpoch's plain
///      status-only write (status := OPEN, nothing else touched) would then silently inherit.
// passing
invariant epochsBeyondCurrentAreNeverTouched(uint256 otherEpochNonce)
    otherEpochNonce > getEpochNonce() => getEpoch(otherEpochNonce).status == Types.EpochStatus.NONE
    filtered {
        f -> !isHarnessHelper(f) && f.selector != sig:upgradeToAndCall(address,bytes).selector
    }
    {
        preserved initialize(
            BaseVault.InitParams params, address treasury, address policyEngineManager, address newPolicyEngine
        ) with (env e) {
            /// @dev genesis fact, not provable as an invariant: if initialize() is about to succeed,
            ///      the one-shot initializer modifier guarantees this is the first-ever call, so every
            ///      epoch is still at its Solidity zero-value default. Must be an inline require - a
            ///      conditional invariant (e.g. guarded by getTreasury() == 0) is too weak, since an
            ///      unconstrained prestate can have treasury already nonzero with initialize() still
            ///      callable.
            require getEpoch(otherEpochNonce).status == Types.EpochStatus.NONE;
        }
    }

/// @notice Before an epoch has ever closed (status NONE, never touched, or OPEN, currently
///         accepting deposits/withdraws), none of its remaining-side settlement counters have been
///         set yet
/// @dev Supporting invariant for EPOCH-008/009/011/012. closeEpoch is the only place that writes
///      remainingDepositClaimAmount/remainingShareMintAmount/remainingShareBurnAmount/
///      remainingWithdrawClaimAmount, and it always transitions status away from OPEN in the same
///      call; no function reachable while an epoch is still OPEN touches these four fields. NONE
///      must be covered too: openNextEpoch (called at the tail of every closeEpoch) transitions the
///      next epoch nonce from NONE to OPEN without touching these fields (nothing to clear in
///      reality), so without this covering NONE as well, that exact transition would be a
///      counterexample to this invariant itself. Used via requireInvariant below so the "stay
///      bounded"/"reach zero together" invariants aren't forced to consider unrealistic
///      not-yet-closed prestates where a remaining-side field is nonzero.
/// @dev closeEpoch's own preserved block additionally requires epochsBeyondCurrentAreNeverTouched:
///      without it, Certora could otherwise assume the *next* epoch nonce (s_epochNonce + 1, about
///      to be opened by openNextEpoch) already had a non-NONE status with leftover nonzero remaining
///      fields from an unreachable prestate - satisfying this invariant's own hypothesis vacuously
///      pre-call (antecedent false) - and then openNextEpoch's status-only write would flip the
///      antecedent true post-call while the stale remaining fields are still sitting there untouched.
// passing
invariant epochRemainingCountersAreZeroBeforeClose(uint256 epochNonce)
    (getEpoch(epochNonce).status == Types.EpochStatus.NONE || getEpoch(epochNonce).status == Types.EpochStatus.OPEN)
        => (
            getEpoch(epochNonce).remainingDepositClaimAmount == 0
                && getEpoch(epochNonce).remainingShareMintAmount == 0
                && getEpoch(epochNonce).remainingShareBurnAmount == 0
                && getEpoch(epochNonce).remainingWithdrawClaimAmount == 0
        )
    filtered {
        f -> !isHarnessHelper(f) && f.selector != sig:upgradeToAndCall(address,bytes).selector
    }
    {
        preserved closeEpoch(uint256 tvl) with (env e) {
            requireInvariant epochsBeyondCurrentAreNeverTouched(epochNonce);
        }
        preserved initialize(
            BaseVault.InitParams params, address treasury, address policyEngineManager, address newPolicyEngine
        ) with (env e) {
            /// @dev genesis fact, not provable as an invariant - see
            ///      epochsBeyondCurrentAreNeverTouched's initialize() preserved block above
            require getEpoch(epochNonce).status == Types.EpochStatus.NONE;
        }
    }

/// @notice An EXECUTING epoch always has an outstanding share-burn remainder
/// @dev Supporting invariant for EPOCH_012. The only transition into EXECUTING is closeEpoch's
///      remote net-withdraw branch, which requires netFlow < 0, i.e. totalWithdraw > totalDepositAmount
///      >= 0, which forces totalShareBurnAmount > 0 (totalWithdraw is derived from it) - and
///      remainingShareBurnAmount is assigned totalShareBurnAmount in that same call. No function
///      decrements remainingShareBurnAmount while EXECUTING (claimAsset requires CLAIMABLE), so the
///      remainder stays nonzero until ccipReceive's settlement transitions the epoch to CLAIMABLE.
///      Without this, EPOCH_012's induction could start from an unreachable EXECUTING prestate with
///      remainingShareBurnAmount == 0, which _handleEpochNetWithdraw's remainingWithdrawClaimAmount
///      overwrite would then turn into a false counterexample.
// @review run again
invariant executingEpochHasOutstandingShareBurn(uint256 epochNonce)
    getEpoch(epochNonce).status == Types.EpochStatus.EXECUTING => getEpoch(epochNonce).remainingShareBurnAmount != 0
    filtered {
        f -> !isHarnessHelper(f) && f.selector != sig:upgradeToAndCall(address,bytes).selector
    }

/// @notice An epoch's remaining deposit-claim amount never exceeds its total deposit amount
/// @dev Verifies docs/INVARIANTS.md EPOCH-008 (deposit side). remainingShareMintAmount is
///      intentionally not bounded here: Types.Epoch has no stored "total minted shares" field to
///      compare against, since remainingShareMintAmount is itself the total at the instant it is set
///      in closeEpoch. Its non-increase from that point on is verified by
///      epochDepositCounters_NonIncreasing below.
invariant EPOCH_008_epochDepositCountersStayBounded(uint256 epochNonce)
    getEpoch(epochNonce).remainingDepositClaimAmount <= getEpoch(epochNonce).totalDepositAmount
    filtered {
        f -> !isHarnessHelper(f) && f.selector != sig:upgradeToAndCall(address,bytes).selector
    }
    {
        preserved {
            requireInvariant epochRemainingCountersAreZeroBeforeClose(epochNonce);
        }
    }

/// @notice An epoch's deposit-claim and share-mint remainders reach zero together
/// @dev Verifies docs/INVARIANTS.md EPOCH-009. Holds because claimShares' last-claimant branch
///      assigns the exact remainder rather than a floor-divided proportional amount.
// passing
invariant EPOCH_009_epochDepositCountersReachZeroTogether(uint256 epochNonce)
    (getEpoch(epochNonce).remainingDepositClaimAmount == 0) <=> (getEpoch(epochNonce).remainingShareMintAmount == 0)
    filtered {
        f -> !isHarnessHelper(f) && f.selector != sig:upgradeToAndCall(address,bytes).selector
    }
    {
        preserved {
            requireInvariant epochRemainingCountersAreZeroBeforeClose(epochNonce);
        }
    }

/// @notice An epoch's remaining share-burn and withdraw-claim amounts never exceed their epoch totals
/// @dev Verifies docs/INVARIANTS.md EPOCH-011 (withdraw side)
// passing
invariant EPOCH_011_epochWithdrawCountersStayBounded(uint256 epochNonce)
    getEpoch(epochNonce).remainingShareBurnAmount <= getEpoch(epochNonce).totalShareBurnAmount
        && getEpoch(epochNonce).remainingWithdrawClaimAmount <= getEpoch(epochNonce).totalWithdrawClaimAmount
    filtered {
        f -> !isHarnessHelper(f) && f.selector != sig:upgradeToAndCall(address,bytes).selector
    }
    {
        preserved {
            requireInvariant epochRemainingCountersAreZeroBeforeClose(epochNonce);
        }
    }

/// @notice Once an epoch's share-burn remainder reaches zero, its withdraw-claim remainder is zero too
/// @dev Verifies docs/INVARIANTS.md EPOCH-012. One-directional per the documented DEV-006 dust
///      exception: claimAsset's last-claimant branch assigns the exact remainder, but a non-last
///      claimant's floor-divided withdraw amount may independently round to zero while the
///      share-burn remainder has not yet reached zero.
// @review run again
invariant EPOCH_012_epochWithdrawCountersReachZeroTogether(uint256 epochNonce)
    getEpoch(epochNonce).remainingShareBurnAmount == 0 => getEpoch(epochNonce).remainingWithdrawClaimAmount == 0
    filtered {
        f -> !isHarnessHelper(f) && f.selector != sig:upgradeToAndCall(address,bytes).selector
    }
    {
        preserved {
            requireInvariant epochRemainingCountersAreZeroBeforeClose(epochNonce);
            requireInvariant executingEpochHasOutstandingShareBurn(epochNonce);
        }
    }

/// @notice ParentVault's asset balance always covers the claimable withdraw obligations it has
///         already settled
/// @dev Verifies docs/INVARIANTS.md SOLV-001, scoped exactly as the doc itself scopes it: only the
///      settled (CLAIMABLE) obligation is modeled; in-flight CCIP withdraw amounts are an explicitly
///      documented future extension, not part of this claim. Relies on the ghost-sum accumulator
///      maintained by the remainingWithdrawClaimAmount/status hooks above.
/// @dev SOLV-002 (recovery must not bypass solvency) follows for free from this being a persistent
///      invariant checked as preserved by every method, including executeRecovery - no separate rule
///      is needed for it.
/// @dev Excludes msg.sender == currentContract (see SOLV-003's NatSpec below for why): donate()'s
///      safeTransferFrom(msg.sender, address(this), amount) becomes a same-account subtract-then-add
///      no-op when msg.sender is the vault itself, which only requires the vault to already hold
///      `amount` for the subtract step - an arbitrary, unconstrained pre-state value Certora is
///      otherwise free to pick as large as it likes - before _executeDeposit genuinely drains that
///      amount out to the adapter. No real caller can ever be the vault's own address here.
invariant SOLV_001_parentCoversClaimableWithdrawObligations()
    to_mathint(asset.balanceOf(currentContract)) >= ghost_sumClaimableWithdrawObligation
    filtered {
        f -> !isHarnessHelper(f) && f.selector != sig:upgradeToAndCall(address,bytes).selector
    }
    {
        preserved with (env e) {
            require e.msg.sender != currentContract;
        }
    }

/// @notice ParentVault's share balance is always fully attributable to outstanding withdraw intents
/// @dev Verifies docs/INVARIANTS.md SOLV-003. Every write to s_withdraws[user][epochNonce] (submit,
///      cancel, claim) moves the vault's share balance by the exact same delta in the same call, so
///      the ghost-sum accumulator maintained by the s_withdraws hook above stays in lockstep with the
///      real balance. Guarded by getTreasury() != 0 (see epochNonceIsNeverZero's NatSpec): before
///      ParentVault.initialize() runs, nothing reachable through ParentVault's own methods can touch
///      share balances, so the "Induction base: after constructor" checkpoint - where the linked
///      share mock's balance isn't otherwise pinned to its own genesis value - would otherwise be a
///      false counterexample rather than a real one.
/// @dev Also excludes msg.sender == currentContract: cancelWithdraw()/withdraw()/claimAsset() all
///      transfer shares to/from msg.sender, and a same-account transfer (vault calling as its own
///      "user") nets to zero on the real balance while the s_withdraws ghost still moves by the full
///      amount - an artifact of the vault being its own caller, which no real transaction can produce
///      (nothing in this codebase self-calls these entry points the way _executeDeposit's
///      this.tryDepositToAdapter does).
/// @dev Also requires getTreasury() != 0 already held in the prestate (see epochNonceIsNeverZero's
///      NatSpec for why the guard needs this): otherwise setTreasury() alone, called by an
///      unconstrained prestate's role holder, could flip the guard true without share balances ever
///      having been made consistent. initialize() is exempted as the one real transition.
// @review run again
invariant SOLV_003_shareEscrowAttributableToWithdrawIntents()
    getTreasury() != 0 => to_mathint(share.balanceOf(currentContract)) == ghost_sumWithdrawEscrow
    filtered {
        f -> !isHarnessHelper(f) && f.selector != sig:upgradeToAndCall(address,bytes).selector
    }
    {
        preserved with (env e) {
            require e.msg.sender != currentContract;
            require getTreasury() != 0;
            /// @dev fee mints (management fee via finalizeRebalance in completeRebalance/
            ///      executeRecovery/initiateRebalance/ccipReceive, performance/management fee in
            ///      closeEpoch) target getTreasury(); if the treasury were the vault itself, fee
            ///      shares would land in the vault's own balance without any withdraw intent.
            ///      No sane deployment sets the vault as its own treasury - operational assumption,
            ///      same spirit as the e.msg.sender != currentContract exclusion above.
            require getTreasury() != currentContract;
        }
        preserved initialize(
            BaseVault.InitParams params, address treasury, address policyEngineManager, address newPolicyEngine
        ) with (env e) {
            /// @dev genesis fact, not provable as an invariant - see
            ///      epochsBeyondCurrentAreNeverTouched's initialize() preserved block above. If
            ///      initialize() is about to succeed, the vault has never held shares and no
            ///      withdraw intent has ever been submitted.
            require share.balanceOf(currentContract) == 0;
            require ghost_sumWithdrawEscrow == 0;
        }
    }

/// @notice The share token's totalSupply() reconciles exactly with s_totalShares once pending
///         lazy mint/burn amounts are accounted for
/// @dev Verifies docs/INVARIANTS.md SHARE-001. s_totalShares is adjusted for a whole epoch's net
///      mint/burn atomically at closeEpoch, while the actual ERC20 mint()/burn() calls happen one
///      claimant at a time via claimShares/claimAsset. totalSupply() therefore lags s_totalShares by
///      exactly the sum of not-yet-minted shares (ghost_sumPendingShareMint) and leads it by exactly
///      the sum of not-yet-burned shares (ghost_sumPendingShareBurn). Guarded by getTreasury() != 0
///      for the same reason as SOLV-003 above.
/// @dev closeEpoch is the one place that writes remainingShareMintAmount/remainingShareBurnAmount
///      for the first time for a given epoch (same "arbitrary OPEN-state prestate" issue as
///      EPOCH-008/009/011/012 above), so its preserved block pulls in the same supporting fact for
///      whichever epoch closeEpoch is about to settle.
/// @dev Also requires getTreasury() != 0 already held in the prestate for every method except
///      initialize() - see epochNonceIsNeverZero's NatSpec for why the guard needs this.
// @review run again
invariant SHARE_001_totalSupplyReconcilesWithTotalShares()
    getTreasury() != 0 =>
        to_mathint(share.totalSupply()) == to_mathint(getTotalShares()) - ghost_sumPendingShareMint + ghost_sumPendingShareBurn
    filtered {
        f -> !isHarnessHelper(f) && f.selector != sig:upgradeToAndCall(address,bytes).selector
    }
    {
        preserved {
            require getTreasury() != 0;
        }
        preserved closeEpoch(uint256 tvl) with (env e) {
            require getTreasury() != 0;
            requireInvariant epochRemainingCountersAreZeroBeforeClose(getEpochNonce());
        }
        preserved initialize(
            BaseVault.InitParams params, address treasury, address policyEngineManager, address newPolicyEngine
        ) with (env e) {
            /// @dev genesis fact, not provable as an invariant - see
            ///      epochsBeyondCurrentAreNeverTouched's initialize() preserved block above. If
            ///      initialize() is about to succeed, no shares have ever been minted or accounted.
            require share.totalSupply() == 0;
            require getTotalShares() == 0;
            require ghost_sumPendingShareMint == 0;
            require ghost_sumPendingShareBurn == 0;
        }
    }

/*//////////////////////////////////////////////////////////////
                        PARAMETRIC RULES
//////////////////////////////////////////////////////////////*/


/// @notice The performance fee high water mark never decreases
/// @dev Verifies docs/INVARIANTS.md FEE-003. This is a parametric before/after rule rather than a
///      persistent invariant because it compares two states across one arbitrary transaction. A
///      bare rule considers a fully arbitrary "before" storage state (unlike an invariant, it is not
///      anchored to anything already proven), so without a guard, hwmBefore could be picked as an
///      unreachable garbage value exceeding i_sharePrecision, and initialize()'s unconditional
///      `s_performanceFeeHighWaterMark = i_sharePrecision` write would then look like a decrease.
///      Guarding on getTreasury() == 0 is insufficient here: that branch is vacuously satisfied
///      whenever getTreasury() != 0, so hwmBefore is still unconstrained in exactly the scenario
///      Certora would pick - a prestate where getTreasury() is already nonzero (so the guard says
///      nothing) while the unrelated `initializer` modifier's own storage still permits calling
///      initialize(). The fact that actually matters doesn't need treasury at all: if initialize()
///      is about to succeed, this must be the vault's first-ever initialization, so HWM must already
///      be at its untouched genesis value of 0 - regardless of what getTreasury() happens to read.
// @review run again
rule FEE_003_performanceFeeHighWaterMark_NeverDecreases(method f) filtered {
    f -> !isHarnessHelper(f) && f.selector != sig:upgradeToAndCall(address,bytes).selector
} {
    require f.selector == sig:initialize(BaseVault.InitParams, address, address, address).selector
        => getPerformanceFeeHighWaterMark() == 0;

    uint256 hwmBefore = getPerformanceFeeHighWaterMark();

    env e;
    calldataarg args;
    f(e, args);

    assert getPerformanceFeeHighWaterMark() >= hwmBefore;
}

/// @notice Once an epoch has closed for the first time, its remaining deposit-claim and
///         share-mint amounts never increase
/// @dev Verifies docs/INVARIANTS.md EPOCH-007, scoped to after the epoch's first close. Excludes
///      the OPEN state: closeEpoch sets remainingDepositClaimAmount/remainingShareMintAmount for
///      the first time when it settles an OPEN epoch (both fields are 0 while OPEN, since they are
///      never touched before close), which is an initial assignment, not a decrement violation.
///      Epoch nonces are never reused and status never cycles back to OPEN (EPOCH-002), so this
///      permanently and correctly narrows the rule to the post-close lifecycle.
// passing
rule EPOCH_007_epochDepositCounters_NonIncreasing(method f, uint256 epochNonce) filtered {
    f -> !isHarnessHelper(f) && f.selector != sig:upgradeToAndCall(address,bytes).selector
} {
    require getEpoch(epochNonce).status != Types.EpochStatus.OPEN;

    uint256 remainingDepositClaimBefore = getEpoch(epochNonce).remainingDepositClaimAmount;
    uint256 remainingShareMintBefore = getEpoch(epochNonce).remainingShareMintAmount;

    env e;
    calldataarg args;
    f(e, args);

    assert getEpoch(epochNonce).remainingDepositClaimAmount <= remainingDepositClaimBefore;
    assert getEpoch(epochNonce).remainingShareMintAmount <= remainingShareMintBefore;
}

/// @notice Once an epoch is CLAIMABLE, its remaining share-burn and withdraw-claim amounts never
///         increase
/// @dev Verifies docs/INVARIANTS.md EPOCH-010, scoped to the claim phase only. Excludes the
///      EXECUTING -> CLAIMABLE settlement transition: ccipReceive's _handleEpochNetWithdraw
///      overwrites remainingWithdrawClaimAmount with the actual bridged-back amount, which can
///      legitimately exceed the provisional value set at closeEpoch (the code only flags the
///      shortfall case via EpochWithdrawAmountShort; a surplus is accepted silently). That is a
///      one-time settlement rebasing, not a claim-processing regression, so it is out of scope here.
// passing
rule EPOCH_010_epochWithdrawCounters_NonIncreasing(method f, uint256 epochNonce) filtered {
    f -> !isHarnessHelper(f) && f.selector != sig:upgradeToAndCall(address,bytes).selector
} {
    require getEpoch(epochNonce).status == Types.EpochStatus.CLAIMABLE;

    uint256 remainingShareBurnBefore = getEpoch(epochNonce).remainingShareBurnAmount;
    uint256 remainingWithdrawClaimBefore = getEpoch(epochNonce).remainingWithdrawClaimAmount;

    env e;
    calldataarg args;
    f(e, args);

    assert getEpoch(epochNonce).remainingShareBurnAmount <= remainingShareBurnBefore;
    assert getEpoch(epochNonce).remainingWithdrawClaimAmount <= remainingWithdrawClaimBefore;
}

/// @notice An epoch's status only ever transitions OPEN -> EXECUTING -> CLAIMABLE or
///         OPEN -> CLAIMABLE (or NONE -> OPEN, for a brand new epoch); never backwards or sideways
/// @dev Verifies docs/INVARIANTS.md EPOCH-002. Two guards, both lessons from earlier fixes in this
///      file:
///      1. requireInvariant epochsBeyondCurrentAreNeverTouched(epochNonce) rules out an
///         unconstrained "future" epoch nonce carrying a leftover non-NONE status from an
///         unreachable prestate - the same issue epochRemainingCountersAreZeroBeforeClose's
///         closeEpoch preserved block already guards against, relevant here because openNextEpoch
///         writes status := OPEN for exactly such a nonce.
///      2. The require on initialize() rules out the analogous issue for epoch 1 specifically:
///         initialize() unconditionally sets epoch 1's status to OPEN, and without this, an
///         arbitrary prestate could have epoch 1 already at CLAIMABLE/EXECUTING before initialize()
///         ever ran, making the transition look invalid when it's actually the vault's genesis.
// passing
rule EPOCH_002_epochTransitionsAreValid(method f, uint256 epochNonce) filtered {
    f -> !isHarnessHelper(f) && f.selector != sig:upgradeToAndCall(address,bytes).selector
} {
    requireInvariant epochsBeyondCurrentAreNeverTouched(epochNonce);
    require f.selector == sig:initialize(BaseVault.InitParams, address, address, address).selector
        => getEpoch(1).status == Types.EpochStatus.NONE;

    Types.EpochStatus statusBefore = getEpoch(epochNonce).status;

    env e;
    calldataarg args;
    f(e, args);

    Types.EpochStatus statusAfter = getEpoch(epochNonce).status;

    assert statusBefore == statusAfter
        || (statusBefore == Types.EpochStatus.NONE && statusAfter == Types.EpochStatus.OPEN)
        || (statusBefore == Types.EpochStatus.OPEN && statusAfter == Types.EpochStatus.EXECUTING)
        || (statusBefore == Types.EpochStatus.OPEN && statusAfter == Types.EpochStatus.CLAIMABLE)
        || (statusBefore == Types.EpochStatus.EXECUTING && statusAfter == Types.EpochStatus.CLAIMABLE);
}


/// @notice No caller other than a depositor/withdrawer themselves can alter their own escrowed
///         deposit or withdraw entry for any epoch
/// @dev This is NOT a verification of docs/INVARIANTS.md SOLV-005. The full SOLV-005 claim (a
///      user's total entitlement across wallet shares, open/claimable deposit and withdraw state,
///      and already-claimed asset covers their contributed principal net of fees and dust) requires
///      per-epoch price-per-share conversion and fee-dilution modeling that isn't tractable as a
///      single CVL pass here - see the discussion in conversation history for why. This rule instead
///      verifies a narrower, complementary property in its own right: every function that writes
///      s_deposits[user][epochNonce] or s_withdraws[user][epochNonce] keys exclusively off
///      msg.sender, never an arbitrary address parameter, so no third party can zero, reduce, or
///      otherwise interfere with another user's escrowed entry. The owning user's own actions
///      correctly updating/clearing their entry are already covered by the per-function Success
///      rules (deposit_Success, cancelDeposit_Success, claimShares_Success, etc.) above.
// passing
rule userEpochEscrowOnlyChangedByOwner(method f, address user, uint256 epochNonce) filtered {
    f -> !isHarnessHelper(f) && f.selector != sig:upgradeToAndCall(address,bytes).selector
} {
    uint256 depositBefore = getDepositAmount(user, epochNonce);
    uint256 withdrawBefore = getWithdrawShareBurnAmount(user, epochNonce);

    env e;
    require e.msg.sender != user;
    calldataarg args;
    f(e, args);

    assert getDepositAmount(user, epochNonce) == depositBefore;
    assert getWithdrawShareBurnAmount(user, epochNonce) == withdrawBefore;
}
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

/// ─── s_epochs[epochNonce].closedAtTimestamp ──────────────────────
ghost mathint ghost_epoch_closedAtTimestamp_StoreCount {
    init_state axiom ghost_epoch_closedAtTimestamp_StoreCount == 0;
}
ghost uint256 ghost_epoch_closedAtTimestamp_StoredKey {
    init_state axiom ghost_epoch_closedAtTimestamp_StoredKey == 0;
}
ghost uint256 ghost_epoch_closedAtTimestamp_StoredValue {
    init_state axiom ghost_epoch_closedAtTimestamp_StoredValue == 0;
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

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_epochs[KEY uint256 epochNonce].closedAtTimestamp uint256 newValue {
    ghost_epoch_closedAtTimestamp_StoreCount = ghost_epoch_closedAtTimestamp_StoreCount + 1;
    ghost_epoch_closedAtTimestamp_StoredKey = epochNonce;
    ghost_epoch_closedAtTimestamp_StoredValue = newValue;
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

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/

/// ─────────────────── CONSTRUCTOR IMMUTABLES ──────────────────

rule constructor_getShare() {
    assert getShare() != 0;
}

/// ─────────────────── INITIALIZE PARENT VAULT ─────────────────

/// @notice ParentVault initialization reverts when the contract has already been initialized
/// @dev Verifies that repeated initialization leaves all vault state unchanged
rule initialize_RevertWhen_AlreadyInitialized() {
    env e;
    BaseVault.InitParams params;
    address treasury;
    address policyEngineManager;
    address newPolicyEngine;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require params.defaultAdmin != 0, "default admin should not be zero";
    require params.pauser != 0, "pauser should not be zero";
    require params.unpauser != 0, "unpauser should not be zero";
    require params.configOperator != 0, "config operator should not be zero";
    require params.emergencyReceiver != 0, "emergency receiver should not be zero";
    require params.upgrader != 0, "upgrader should not be zero";
    require params.initialDefaultCcipGasLimit != 0, "default CCIP gas limit should not be zero";
    require treasury != 0, "treasury should not be zero";
    require policyEngineManager != 0, "policy engine manager should not be zero";
    require newPolicyEngine != 0, "policy engine should not be zero";

    /// @dev revert condition being verified
    require isInitialized(), "contract should already be initialized";

    storage before = lastStorage;

    initialize@withrevert(e, params, treasury, policyEngineManager, newPolicyEngine);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice ParentVault initialization reverts when the treasury address is zero
/// @dev Verifies that a malformed treasury argument leaves all vault state unchanged
rule initialize_RevertWhen_TreasuryIsZeroAddress() {
    env e;
    BaseVault.InitParams params;
    address treasury;
    address policyEngineManager;
    address newPolicyEngine;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !isInitialized(), "contract should not be initialized";
    require !isInitializing(), "contract should not be initializing";
    require defaultAdmin() == 0, "default admin should not be initialized";
    require params.defaultAdmin != 0, "default admin should not be zero";
    require params.pauser != 0, "pauser should not be zero";
    require params.unpauser != 0, "unpauser should not be zero";
    require params.configOperator != 0, "config operator should not be zero";
    require params.emergencyReceiver != 0, "emergency receiver should not be zero";
    require params.upgrader != 0, "upgrader should not be zero";
    require params.initialDefaultCcipGasLimit != 0, "default CCIP gas limit should not be zero";
    require policyEngineManager != 0, "policy engine manager should not be zero";
    require newPolicyEngine != 0, "policy engine should not be zero";

    /// @dev revert condition being verified
    require treasury == 0, "treasury should be zero";

    storage before = lastStorage;

    initialize@withrevert(e, params, treasury, policyEngineManager, newPolicyEngine);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice ParentVault initialization reverts when the policy engine manager address is zero
/// @dev Verifies that a malformed policyEngineManager argument leaves all vault state unchanged
rule initialize_RevertWhen_PolicyEngineManagerIsZeroAddress() {
    env e;
    BaseVault.InitParams params;
    address treasury;
    address policyEngineManager;
    address newPolicyEngine;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !isInitialized(), "contract should not be initialized";
    require !isInitializing(), "contract should not be initializing";
    require defaultAdmin() == 0, "default admin should not be initialized";
    require params.defaultAdmin != 0, "default admin should not be zero";
    require params.pauser != 0, "pauser should not be zero";
    require params.unpauser != 0, "unpauser should not be zero";
    require params.configOperator != 0, "config operator should not be zero";
    require params.emergencyReceiver != 0, "emergency receiver should not be zero";
    require params.upgrader != 0, "upgrader should not be zero";
    require params.initialDefaultCcipGasLimit != 0, "default CCIP gas limit should not be zero";
    require treasury != 0, "treasury should not be zero";
    require newPolicyEngine != 0, "policy engine should not be zero";

    /// @dev revert condition being verified
    require policyEngineManager == 0, "policy engine manager should be zero";

    storage before = lastStorage;

    initialize@withrevert(e, params, treasury, policyEngineManager, newPolicyEngine);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice ParentVault initialization reverts when the policy engine address is zero
/// @dev Verifies that a malformed policyEngine argument leaves all vault state unchanged
rule initialize_RevertWhen_PolicyEngineIsZeroAddress() {
    env e;
    BaseVault.InitParams params;
    address treasury;
    address policyEngineManager;
    address newPolicyEngine;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !isInitialized(), "contract should not be initialized";
    require !isInitializing(), "contract should not be initializing";
    require defaultAdmin() == 0, "default admin should not be initialized";
    require params.defaultAdmin != 0, "default admin should not be zero";
    require params.pauser != 0, "pauser should not be zero";
    require params.unpauser != 0, "unpauser should not be zero";
    require params.configOperator != 0, "config operator should not be zero";
    require params.emergencyReceiver != 0, "emergency receiver should not be zero";
    require params.upgrader != 0, "upgrader should not be zero";
    require params.initialDefaultCcipGasLimit != 0, "default CCIP gas limit should not be zero";
    require treasury != 0, "treasury should not be zero";
    require policyEngineManager != 0, "policy engine manager should not be zero";

    /// @dev revert condition being verified
    require newPolicyEngine == 0, "policy engine should be zero";

    storage before = lastStorage;

    initialize@withrevert(e, params, treasury, policyEngineManager, newPolicyEngine);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice ParentVault initialization sets up epoch 1, rebalance nonce 1, performance fee high water
///         mark, treasury, and grants POLICY_ENGINE_MANAGER_ROLE, and attaches the policy engine
/// @dev __PolicyProtected_init attaches the policy engine as its very first attach (no prior engine),
///      so only PolicyEngineAttached fires, not PolicyEngineDetachFailed.
rule initialize_Success() {
    env e;
    BaseVault.InitParams params;
    address treasury;
    address policyEngineManager;
    address newPolicyEngine;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !isInitialized(), "contract should not be initialized";
    require !isInitializing(), "contract should not be initializing";
    require defaultAdmin() == 0, "default admin should not be initialized";
    require params.defaultAdmin != 0, "default admin should not be zero";
    require params.pauser != 0, "pauser should not be zero";
    require params.unpauser != 0, "unpauser should not be zero";
    require params.configOperator != 0, "config operator should not be zero";
    require params.emergencyReceiver != 0, "emergency receiver should not be zero";
    require params.upgrader != 0, "upgrader should not be zero";
    require params.initialDefaultCcipGasLimit != 0, "default CCIP gas limit should not be zero";
    require treasury != 0, "treasury should not be zero";
    require policyEngineManager != 0, "policy engine manager should not be zero";
    require newPolicyEngine != 0, "policy engine should not be zero";

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

    initialize@withrevert(e, params, treasury, policyEngineManager, newPolicyEngine);

    assert !lastReverted;
    assert isInitialized();
    assert getEpochNonce() == 1;
    assert getEpoch(1).status == Types.EpochStatus.OPEN;
    assert getEpoch(1).openedAtTimestamp == e.block.timestamp;
    assert getPerformanceFeeHighWaterMark() == getSharePrecision();
    assert getRebalance().nonce == 1;
    assert getRebalance().lastRebalanceCompletedTimestamp == e.block.timestamp;
    assert getTreasury() == treasury;
    assert owner() == params.defaultAdmin;
    assert owner() == defaultAdmin();
    assert hasRole(POLICY_ENGINE_MANAGER_ROLE(), policyEngineManager);
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

    storage before = lastStorage;

    setInitialActiveProtocolAdapter@withrevert(e, protocolId);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
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

    storage before = lastStorage;

    setInitialActiveProtocolAdapter@withrevert(e, protocolId);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Setting the initial active protocol adapter reverts when it has already been set
/// @dev Verifies the one-time setter guard leaves all vault state unchanged
rule setInitialActiveProtocolAdapter_RevertWhen_AlreadySet() {
    env e;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(DEFAULT_ADMIN_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";

    /// @dev revert condition being verified
    require getInitialActiveProtocolAdapterSet(), "initial active protocol adapter should already be set";

    storage before = lastStorage;

    setInitialActiveProtocolAdapter@withrevert(e, protocolId);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Setting the initial active protocol adapter reverts when the target protocol has no registered adapter
/// @dev Verifies that an unregistered protocol leaves all vault state unchanged
rule setInitialActiveProtocolAdapter_RevertWhen_TargetAdapterNotRegistered() {
    env e;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(DEFAULT_ADMIN_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !getInitialActiveProtocolAdapterSet(), "initial active protocol adapter should not already be set";

    /// @dev revert condition being verified
    require adapterRegistry.getAdapter(e, protocolId) == 0, "target adapter should not be registered";

    storage before = lastStorage;

    setInitialActiveProtocolAdapter@withrevert(e, protocolId);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Setting the initial active protocol adapter reverts when the registered adapter is bound to another vault
/// @dev Verifies that a misconfigured adapter registration leaves all vault state unchanged
rule setInitialActiveProtocolAdapter_RevertWhen_TargetAdapterVaultIsInvalid() {
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

    storage before = lastStorage;

    setInitialActiveProtocolAdapter@withrevert(e, protocolId);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Setting the initial active protocol adapter registers the adapter, marks the one-time setter as
///         used, and seeds the active strategy to this chain
rule setInitialActiveProtocolAdapter_Success() {
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

    storage before = lastStorage;

    setTreasury@withrevert(e, treasury);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
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

    storage before = lastStorage;

    setTreasury@withrevert(e, treasury);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
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

    storage before = lastStorage;

    setSupportedProtocol@withrevert(e, protocolId, isSupported);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
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

    storage before = lastStorage;

    setSupportedProtocol@withrevert(e, protocolId, isSupported);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Removing protocol support reverts when the protocol is the active strategy protocol
/// @dev Verifies that the active strategy protocol cannot be unsupported. This deliberately allows
///      the protocol to also be pending, so the overlapping active+pending state remains covered if
///      the implementation's guard order changes.
rule setSupportedProtocol_RevertWhen_RemovingActiveProtocol() {
    env e;
    bytes32 protocolId;
    bool isSupported;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender);
    require protocolId != to_bytes32(0), "protocol id should not be zero";

    /// @dev revert condition being verified
    require !isSupported, "protocol support should be disabled";
    require protocolId == getRebalance().activeStrategy.protocolId,
        "protocol id should match the active strategy protocol";

    storage before = lastStorage;

    setSupportedProtocol@withrevert(e, protocolId, isSupported);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Removing protocol support reverts when the protocol is the pending strategy protocol
/// @dev Verifies that the pending strategy protocol cannot be unsupported. This deliberately allows
///      the protocol to also be active, so the overlapping active+pending state remains covered if
///      the implementation's guard order changes.
rule setSupportedProtocol_RevertWhen_RemovingPendingProtocol() {
    env e;
    bytes32 protocolId;
    bool isSupported;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender);
    require protocolId != to_bytes32(0), "protocol id should not be zero";

    /// @dev revert condition being verified
    require !isSupported, "protocol support should be disabled";
    require protocolId == getRebalance().pendingStrategy.protocolId,
        "protocol id should match the pending strategy protocol";

    storage before = lastStorage;

    setSupportedProtocol@withrevert(e, protocolId, isSupported);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Removing protocol support reverts when the same protocol is both active and pending
/// @dev Verifies the overlapping removal guard explicitly, so future refactors that change guard
///      ordering still keep the combined state in scope.
rule setSupportedProtocol_RevertWhen_RemovingActiveAndPendingProtocol() {
    env e;
    bytes32 protocolId;
    bool isSupported;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender);
    require protocolId != to_bytes32(0), "protocol id should not be zero";

    /// @dev revert conditions being verified
    require !isSupported, "protocol support should be disabled";
    require protocolId == getRebalance().activeStrategy.protocolId,
        "protocol id should match the active strategy protocol";
    require protocolId == getRebalance().pendingStrategy.protocolId,
        "protocol id should match the pending strategy protocol";

    storage before = lastStorage;

    setSupportedProtocol@withrevert(e, protocolId, isSupported);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
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
    require newPolicyEngine == policyEngine, "policy engine should be the mock policy engine";
    require newPolicyEngine != 0, "policy engine should not be zero";
    require newPolicyEngine != currentContract, "policy engine should not be the vault";

    /// @dev revert condition being verified
    require !hasRole(POLICY_ENGINE_MANAGER_ROLE(), e.msg.sender);

    storage before = lastStorage;

    attachPolicyEngine@withrevert(e, newPolicyEngine);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Attaching a policy engine reverts when the new policy engine address is zero
/// @dev Verifies that a malformed policy engine argument leaves all vault state unchanged
rule attachPolicyEngine_RevertWhen_PolicyEngineIsZeroAddress() {
    env e;
    address newPolicyEngine;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(POLICY_ENGINE_MANAGER_ROLE(), e.msg.sender);

    /// @dev revert condition being verified
    require newPolicyEngine == 0, "policy engine should be zero";

    storage before = lastStorage;

    attachPolicyEngine@withrevert(e, newPolicyEngine);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
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

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !isInitialized(), "contract should not be initialized";
    require !isInitializing(), "contract should not be initializing";
    require defaultAdmin() == 0, "default admin should not be initialized";
    require params.defaultAdmin != 0, "default admin should not be zero";
    require params.pauser != 0, "pauser should not be zero";
    require params.unpauser != 0, "unpauser should not be zero";
    require params.configOperator != 0, "config operator should not be zero";
    require params.emergencyReceiver != 0, "emergency receiver should not be zero";
    require params.upgrader != 0, "upgrader should not be zero";
    require params.initialDefaultCcipGasLimit != 0, "default CCIP gas limit should not be zero";
    require treasury != 0, "treasury should not be zero";
    require policyEngineManager != 0, "policy engine manager should not be zero";
    require newPolicyEngine != 0, "policy engine should not be zero";

    initialize@withrevert(e, params, treasury, policyEngineManager, newPolicyEngine);

    assert !lastReverted;
    assert owner() == params.defaultAdmin;
    assert owner() == defaultAdmin();
}

/// ─────────────────────────── GET TVL ──────────────────────────

/// @notice ParentVault TVL is zero when this chain has no active strategy adapter
/// @dev Verifies that the non-strategy-chain path returns zero and does not query an adapter
rule getTVL_ReturnsZero_WhenNoActiveAdapter() {
    require getActiveProtocolAdapter() == 0, "active adapter should be unset";

    assert getTVL() == 0;
}

/// @notice ParentVault TVL includes both active adapter TVL and pending rebalance deposit recovery
/// @dev Verifies the strategy-chain path while excluding the checked-addition overflow case below
rule getTVL_Success_WhenActiveAdapterIsSet() {
    uint256 adapterTVL = adapter.getTVL();
    uint256 recoveryAmount = getRebalanceDepositRecovery().amount;

    /// @dev revert conditions NOT being verified
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require adapterTVL <= max_uint256 - recoveryAmount, "TVL addition should not overflow";

    assert getTVL() == adapterTVL + recoveryAmount;
}

/// @notice ParentVault TVL reverts when active adapter TVL plus rebalance recovery amount overflows
/// @dev Verifies the checked arithmetic guard in ParentVault._getTVL
rule getTVL_RevertWhen_TvlAdditionOverflows() {
    env e;
    uint256 adapterTVL = adapter.getTVL();
    uint256 recoveryAmount = getRebalanceDepositRecovery().amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";

    /// @dev revert condition being verified
    require adapterTVL > max_uint256 - recoveryAmount, "TVL addition should overflow";

    storage before = lastStorage;

    getTVL@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
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

    storage before = lastStorage;

    deposit@withrevert(e, amount);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Deposit reverts when the vault is paused
/// @dev Verifies that a paused vault leaves all vault state unchanged
rule deposit_RevertWhen_Paused() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require amount >= getMinDepositAmount(), "amount should meet the minimum deposit requirement";
    require getEpoch(getEpochNonce()).status == Types.EpochStatus.OPEN, "current epoch should be open";

    /// @dev revert condition being verified
    require paused(), "vault should be paused";

    storage before = lastStorage;

    deposit@withrevert(e, amount);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Deposit reverts when the amount is below the minimum deposit requirement
/// @dev Verifies that a malformed amount leaves all vault state unchanged. This precondition is
///      checked in ParentVaultUserEpochLib before any external call, so it is not expected to hit
///      the unresolved-external-library-call issue that affects _setActiveAdapter.
rule deposit_RevertWhen_AmountBelowMinimum() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getEpoch(getEpochNonce()).status == Types.EpochStatus.OPEN, "current epoch should be open";

    /// @dev revert condition being verified
    require amount < getMinDepositAmount(), "amount should be below the minimum deposit requirement";

    storage before = lastStorage;

    deposit@withrevert(e, amount);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Deposit pulls the deposited amount from the depositor, accumulates the deposit and epoch
///         totals, and emits DepositSubmitted
/// @dev Delegates to ParentVaultUserEpochLib.deposit (DELEGATECALL). This is the same shape as
///      _setActiveAdapter (a public library function making a nested external call - here,
///      IERC20(asset).safeTransferFrom) - included to observe whether the same unresolved-callee
///      havoc reproduces for this call site.
rule deposit_Success() {
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

    storage before = lastStorage;

    withdraw@withrevert(e, shareBurnAmount);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Withdraw reverts when the vault is paused
/// @dev Verifies that a paused vault leaves all vault state unchanged
rule withdraw_RevertWhen_Paused() {
    env e;
    uint256 shareBurnAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require shareBurnAmount != 0, "share burn amount should not be zero";
    require getEpoch(getEpochNonce()).status == Types.EpochStatus.OPEN, "current epoch should be open";

    /// @dev revert condition being verified
    require paused(), "vault should be paused";

    storage before = lastStorage;

    withdraw@withrevert(e, shareBurnAmount);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Withdraw reverts when the share burn amount is zero
/// @dev Verifies that a malformed amount leaves all vault state unchanged
rule withdraw_RevertWhen_ShareBurnAmountIsZero() {
    env e;
    uint256 shareBurnAmount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getEpoch(getEpochNonce()).status == Types.EpochStatus.OPEN, "current epoch should be open";

    /// @dev revert condition being verified
    require shareBurnAmount == 0, "share burn amount should be zero";

    storage before = lastStorage;

    withdraw@withrevert(e, shareBurnAmount);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Withdraw pulls the share burn amount from the withdrawer, accumulates the withdraw and
///         epoch totals, and emits WithdrawSubmitted
rule withdraw_Success() {
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

    storage before = lastStorage;

    claimShares@withrevert(e, epochNonce);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Claiming shares reverts when the vault is paused
/// @dev Verifies that a paused vault leaves all vault state unchanged
rule claimShares_RevertWhen_Paused() {
    env e;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getEpoch(epochNonce).status == Types.EpochStatus.CLAIMABLE, "epoch should be claimable";
    require getDepositAmount(e.msg.sender, epochNonce) != 0, "depositor should have a deposit for the epoch";

    /// @dev revert condition being verified
    require paused(), "vault should be paused";

    storage before = lastStorage;

    claimShares@withrevert(e, epochNonce);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
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

    /// @dev revert condition being verified
    require getEpoch(epochNonce).status != Types.EpochStatus.CLAIMABLE, "epoch should not be claimable";

    storage before = lastStorage;

    claimShares@withrevert(e, epochNonce);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
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

    storage before = lastStorage;

    claimShares@withrevert(e, epochNonce);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Claiming shares mints the depositor's proportional (or fully remaining) share of the
///         epoch's minted shares, deletes their deposit entry, and emits DepositClaimed
rule claimShares_Success() {
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

    mathint expectedShareMintAmount;
    if (depositAmount == remainingDepositClaimAmount) {
        expectedShareMintAmount = remainingShareMintAmount;
    } else {
        require remainingDepositClaimAmount != 0, "remaining deposit claim amount should not be zero";
        require remainingShareMintAmount == 0 || depositAmount <= max_uint256 / remainingShareMintAmount,
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

    storage before = lastStorage;

    claimAsset@withrevert(e, epochNonce);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Claiming asset reverts when the vault is paused
/// @dev Verifies that a paused vault leaves all vault state unchanged
rule claimAsset_RevertWhen_Paused() {
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

    storage before = lastStorage;

    claimAsset@withrevert(e, epochNonce);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
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

    storage before = lastStorage;

    claimAsset@withrevert(e, epochNonce);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
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

    storage before = lastStorage;

    claimAsset@withrevert(e, epochNonce);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Claiming asset burns the vault's corresponding shares, transfers the withdrawer's
///         proportional (or fully remaining) asset amount, deletes their withdraw entry, and emits
///         WithdrawClaimed. The formula holds even in the withdrawAmount == 0 case, where the asset
///         transfer is skipped entirely (adding/subtracting zero is a no-op).
rule claimAsset_Success() {
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

    storage before = lastStorage;

    cancelDeposit@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Cancelling a deposit reverts when the vault is paused
/// @dev Verifies that a paused vault leaves all vault state unchanged
rule cancelDeposit_RevertWhen_Paused() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getEpoch(getEpochNonce()).status == Types.EpochStatus.OPEN, "current epoch should be open";
    require getDepositAmount(e.msg.sender, getEpochNonce()) != 0,
        "depositor should have a deposit for the current epoch";

    /// @dev revert condition being verified
    require paused(), "vault should be paused";

    storage before = lastStorage;

    cancelDeposit@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Cancelling a deposit reverts when the current epoch is not open
/// @dev Verifies that a stale cancellation attempt leaves all vault state unchanged
rule cancelDeposit_RevertWhen_EpochNotOpen() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";

    /// @dev revert condition being verified
    require getEpoch(getEpochNonce()).status != Types.EpochStatus.OPEN, "current epoch should not be open";

    storage before = lastStorage;

    cancelDeposit@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
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

    storage before = lastStorage;

    cancelDeposit@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Cancelling a deposit deletes the depositor's entry, decrements the epoch total, refunds
///         the full deposit amount, and emits DepositCancelled
rule cancelDeposit_Success() {
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

    storage before = lastStorage;

    cancelWithdraw@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Cancelling a withdraw reverts when the vault is paused
/// @dev Verifies that a paused vault leaves all vault state unchanged
rule cancelWithdraw_RevertWhen_Paused() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getEpoch(getEpochNonce()).status == Types.EpochStatus.OPEN, "current epoch should be open";
    require getWithdrawShareBurnAmount(e.msg.sender, getEpochNonce()) != 0,
        "withdrawer should have a withdraw intent for the current epoch";

    /// @dev revert condition being verified
    require paused(), "vault should be paused";

    storage before = lastStorage;

    cancelWithdraw@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Cancelling a withdraw reverts when the current epoch is not open
/// @dev Verifies that a stale cancellation attempt leaves all vault state unchanged
rule cancelWithdraw_RevertWhen_EpochNotOpen() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";

    /// @dev revert condition being verified
    require getEpoch(getEpochNonce()).status != Types.EpochStatus.OPEN, "current epoch should not be open";

    storage before = lastStorage;

    cancelWithdraw@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
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

    storage before = lastStorage;

    cancelWithdraw@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Cancelling a withdraw deletes the withdrawer's entry, decrements the epoch total, refunds
///         the full share burn amount, and emits WithdrawCancelled
rule cancelWithdraw_Success() {
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
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch net withdraw";

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
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch net withdraw";

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
    require message.sender == encodeAddress(sender), "message sender should encode the supplied sender";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch net withdraw";

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
    require message.sender == encodeAddress(sender), "message sender should encode the supplied sender";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch net withdraw";

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
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch net withdraw";

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
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch net withdraw";

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
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch net withdraw";

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
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch net withdraw";

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
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch net withdraw";

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

/// @notice CCIP receive reverts when the transaction type is unsupported by ParentVault
/// @dev Verifies that an unsupported transaction type (e.g. EPOCH_NET_DEPOSIT, which only
///      ChildVault handles) leaves all vault state unchanged
rule CCIP_004_ccipReceive_RevertWhen_TxTypeIsInvalid() {
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
    require message.sender == encodeAddress(sender), "message sender should encode the registered vault";
    require message.data == encodeCcipTxData(ccipTxType, encodeEpochNonce(epochNonce)),
        "message data should encode a generic epoch payload";

    /// @dev revert condition being verified
    require ccipTxType == Types.CcipTx.EPOCH_NET_DEPOSIT, "transaction type should be unsupported by ParentVault";

    storage before = lastStorage;

    ccipReceive@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// ─────────────────── CCIP RECEIVE: EPOCH_NET_WITHDRAW ───────────

/// @notice CCIP epoch net withdraw reverts when its payload is too short to decode the epoch nonce
/// @dev Verifies that malformed epoch data leaves all vault state unchanged
rule ccipReceive_EPOCH_NET_WITHDRAW_RevertWhen_PayloadEncodingIsMalformed() {
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
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, data),
        "message data should encode an epoch net withdraw";

    /// @dev revert condition being verified
    require data.length < 32, "epoch net withdraw payload should be too short to decode";

    storage before = lastStorage;

    ccipReceive@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice CCIP epoch net withdraw reverts when the decoded epoch nonce does not match the
///         previous epoch
/// @dev Verifies that a stale or malformed callback leaves all vault state unchanged
rule ccipReceive_EPOCH_NET_WITHDRAW_RevertWhen_InvalidEpochNonce() {
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
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch net withdraw";
    require getEpochNonce() >= 1, "epoch nonce should never be zero";

    /// @dev revert condition being verified
    require epochNonce != getEpochNonce() - 1, "decoded epoch nonce should not match the previous epoch";

    storage before = lastStorage;

    ccipReceive@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice CCIP epoch net withdraw reverts when the previous epoch is not executing
/// @dev Verifies that an out-of-sequence callback leaves all vault state unchanged
rule ccipReceive_EPOCH_NET_WITHDRAW_RevertWhen_EpochNotExecuting() {
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
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch net withdraw";
    require getEpochNonce() >= 1, "epoch nonce should never be zero";
    require epochNonce == getEpochNonce() - 1, "decoded epoch nonce should match the previous epoch";

    /// @dev revert condition being verified
    require getEpoch(epochNonce).status != Types.EpochStatus.EXECUTING, "previous epoch should not be executing";

    storage before = lastStorage;

    ccipReceive@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice CCIP epoch net withdraw reverts when the epoch's recorded total withdraw claim amount
///         is less than its total deposit amount
/// @dev This is a defensive checked-arithmetic guard: closeEpoch only routes an epoch into
///      EPOCH_NET_WITHDRAW/EXECUTING when projected withdraws exceed deposits, so
///      totalWithdrawClaimAmount >= totalDepositAmount should always hold in practice. Verifies
///      that violating this invariant leaves all vault state unchanged rather than silently
///      wrapping.
rule ccipReceive_EPOCH_NET_WITHDRAW_RevertWhen_TotalWithdrawClaimAmountUnderflows() {
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
    require message.data == encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, encodeEpochNonce(epochNonce)),
        "message data should encode an epoch net withdraw";
    require getEpochNonce() >= 1, "epoch nonce should never be zero";
    require epochNonce == getEpochNonce() - 1, "decoded epoch nonce should match the previous epoch";
    require getEpoch(epochNonce).status == Types.EpochStatus.EXECUTING, "previous epoch should be executing";

    /// @dev revert condition being verified
    require getEpoch(epochNonce).totalWithdrawClaimAmount < getEpoch(epochNonce).totalDepositAmount,
        "total withdraw claim amount should underflow against total deposit amount";

    storage before = lastStorage;

    ccipReceive@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice A successful CCIP epoch net withdraw settles the epoch's withdraw totals, marks the
///         epoch claimable, and emits EpochWithdrawAmountShort when the delivered amount falls
///         short of what withdrawers are owed
rule ccipReceive_EPOCH_NET_WITHDRAW_Success() {
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
}

/// ─────────────────────── CCIP RECEIVE: REBALANCE ────────────────

/// @notice CCIP rebalance callback reverts when no rebalance is in progress
/// @dev Verifies that an unexpected callback leaves all vault state unchanged
rule ccipReceive_REBALANCE_RevertWhen_NoRebalanceInProgress() {
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
    require getRebalance().state != Types.RebalanceState.REBALANCING, "rebalance should not be in progress";

    storage before = lastStorage;

    ccipReceive@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice CCIP rebalance callback reverts when its payload is too short to decode the nonce and
///         protocol ID
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
    require getRebalance().state == Types.RebalanceState.REBALANCING, "rebalance should be in progress";

    /// @dev revert condition being verified
    require data.length < 64, "rebalance payload should be too short to decode";

    storage before = lastStorage;

    ccipReceive@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice CCIP rebalance callback reverts when the decoded rebalance nonce does not match
/// @dev Verifies that a stale or malformed callback leaves all vault state unchanged
rule ccipReceive_REBALANCE_RevertWhen_InvalidRebalanceNonce() {
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
    require getRebalance().state == Types.RebalanceState.REBALANCING, "rebalance should be in progress";

    /// @dev revert condition being verified
    require rebalanceNonce != getRebalance().nonce, "decoded rebalance nonce should not match the current rebalance";

    storage before = lastStorage;

    ccipReceive@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice CCIP rebalance callback reverts when the decoded protocol ID does not match the
///         pending strategy
/// @dev Verifies that a mismatched callback leaves all vault state unchanged
rule ccipReceive_REBALANCE_RevertWhen_InvalidPendingProtocolId() {
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
    require getRebalance().state == Types.RebalanceState.REBALANCING, "rebalance should be in progress";
    require rebalanceNonce == getRebalance().nonce, "decoded rebalance nonce should match the current rebalance";
    require rebalanceNonce != 0, "rebalance nonce should never be zero";
    require rebalanceNonce != max_uint256, "rebalance nonce should not overflow when finalizeRebalance increments it";

    /// @dev revert condition being verified
    require protocolId != getRebalance().pendingStrategy.protocolId,
        "decoded protocol id should not match the pending strategy";

    storage before = lastStorage;

    ccipReceive@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice CCIP rebalance callback reverts when the target protocol adapter is not registered
/// @dev Verifies that an unknown target protocol leaves all vault state unchanged
rule ccipReceive_REBALANCE_RevertWhen_TargetAdapterNotRegistered() {
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
    require getRebalance().state == Types.RebalanceState.REBALANCING, "rebalance should be in progress";
    require rebalanceNonce == getRebalance().nonce, "decoded rebalance nonce should match the current rebalance";
    require rebalanceNonce != 0, "rebalance nonce should never be zero";
    require rebalanceNonce != max_uint256, "rebalance nonce should not overflow when finalizeRebalance increments it";
    require protocolId == getRebalance().pendingStrategy.protocolId,
        "decoded protocol id should match the pending strategy";

    /// @dev revert condition being verified
    require adapterRegistry.getAdapter(e, protocolId) == 0, "target adapter should not be registered";

    storage before = lastStorage;

    ccipReceive@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice CCIP rebalance callback reverts when the registered adapter is bound to another vault
/// @dev Verifies that a misconfigured adapter registration leaves all vault state unchanged
rule ccipReceive_REBALANCE_RevertWhen_TargetAdapterVaultIsInvalid() {
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
    require getRebalance().state == Types.RebalanceState.REBALANCING, "rebalance should be in progress";
    require rebalanceNonce == getRebalance().nonce, "decoded rebalance nonce should match the current rebalance";
    require rebalanceNonce != 0, "rebalance nonce should never be zero";
    require rebalanceNonce != max_uint256, "rebalance nonce should not overflow when finalizeRebalance increments it";
    require protocolId == getRebalance().pendingStrategy.protocolId,
        "decoded protocol id should match the pending strategy";
    require invalidAdapter.getVault() != currentContract, "target adapter should not be bound to this vault";

    /// @dev revert condition being verified
    require adapterRegistry.getAdapter(e, protocolId) == invalidAdapter, "invalid target adapter should be registered";

    storage before = lastStorage;

    ccipReceive@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice A successful CCIP rebalance callback sets the active adapter, deposits the delivered
///         asset, and finalizes the rebalance (activates the pending strategy, clears rebalance
///         state, and conditionally mints the management fee)
/// @dev This exercises the same call graph as _setActiveAdapter (public library call with a nested
///      external call) that required the ParentVaultHarness override, plus a second nested-external
///      -call site in ParentVaultFeesLib._collectManagementFee (IShare.mint) reached via
///      ParentVaultRebalanceLib.finalizeRebalance - included to observe whether the
///      unresolved-callee havoc reproduces for the rest of the _ccipReceive call graph too.
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
    require getRebalance().state == Types.RebalanceState.REBALANCING, "rebalance should be in progress";
    require rebalanceNonce == getRebalance().nonce, "decoded rebalance nonce should match the current rebalance";
    require rebalanceNonce != 0, "rebalance nonce should never be zero";
    require rebalanceNonce != max_uint256, "rebalance nonce should not overflow when finalizeRebalance increments it";
    require protocolId == getRebalance().pendingStrategy.protocolId,
        "decoded protocol id should match the pending strategy";

    uint256 amount = message.destTokenAmounts[0].amount;
    uint64 pendingChainSelector = getRebalance().pendingStrategy.chainSelector;
    uint256 lastRebalanceCompletedTimestampBefore = getRebalance().lastRebalanceCompletedTimestamp;
    uint256 totalSharesBefore = getTotalShares();
    require e.block.timestamp >= lastRebalanceCompletedTimestampBefore,
        "block timestamp should not precede the last rebalance completion";

    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token and adapter arithmetic conditions
    require amount <= vaultBalanceBefore, "vault asset balance should cover the deposit amount";
    require adapterBalanceBefore <= max_uint256 - amount, "adapter asset balance should not overflow";
    require adapterTVLBefore <= max_uint256 - amount, "adapter TVL should not overflow";

    /// @dev model ParentVaultFeesLib's management fee formula
    mathint elapsedRaw = e.block.timestamp - lastRebalanceCompletedTimestampBefore;
    mathint elapsed = elapsedRaw > to_mathint(YEAR()) ? to_mathint(YEAR()) : elapsedRaw;
    mathint denominator = BPS_DENOMINATOR() * YEAR();
    require totalSharesBefore <= max_uint256 / MANAGEMENT_FEE_BPS(),
        "total shares fee bps multiplication should not overflow";
    mathint product = totalSharesBefore * MANAGEMENT_FEE_BPS();
    require elapsed == 0 || product <= max_uint256 / elapsed, "elapsed fee multiplication should not overflow";
    mathint numerator = product * elapsed;
    require numerator <= max_uint256 - (denominator - 1), "management fee numerator should not overflow";
    mathint feeShares = (numerator + denominator - 1) / denominator;
    uint256 priorTreasuryShareBalance = share.balanceOf(getTreasury());
    require totalSharesBefore <= max_uint256 - feeShares, "total shares should not overflow when minting the fee";
    require priorTreasuryShareBalance <= max_uint256 - feeShares, "treasury share balance should not overflow";
    require share.totalSupply() <= max_uint256 - feeShares, "share total supply should not overflow";

    /// @dev set ghost starting values
    require ghost_ActiveProtocolAdapterSet_EventCount == 0;
    require ghost_RebalanceDepositSuccess_EventCount == 0;
    require ghost_RebalanceDepositFailure_EventCount == 0;
    require ghost_RebalanceDepositRecoveryStored_EventCount == 0;
    require ghost_RebalanceCompleted_EventCount == 0;
    require ghost_ManagementFeeCollected_EventCount == 0;
    require ghost_rebalance_state_StoreCount == 0;
    require ghost_rebalance_activeStrategy_protocolId_StoreCount == 0;
    require ghost_rebalance_activeStrategy_chainSelector_StoreCount == 0;
    require ghost_rebalance_pendingStrategy_protocolId_StoreCount == 0;
    require ghost_rebalance_pendingStrategy_chainSelector_StoreCount == 0;
    require ghost_rebalance_nonce_StoreCount == 0;
    require ghost_totalShares_StoreCount == 0;

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
    assert feeShares == 0 => (getTotalShares() == totalSharesBefore && ghost_ManagementFeeCollected_EventCount == 0);
    assert feeShares != 0 => (
        to_mathint(getTotalShares()) == totalSharesBefore + feeShares
        && to_mathint(share.balanceOf(getTreasury())) == priorTreasuryShareBalance + feeShares
        && ghost_ManagementFeeCollected_EventCount == 1
        && ghost_ManagementFeeCollected_Param_rebalanceNonce == rebalanceNonce
        && to_mathint(ghost_ManagementFeeCollected_Param_feeShares) == feeShares
    );
}

/// @notice A CCIP rebalance callback whose strategy deposit fails sets the active adapter and
///         stores rebalance deposit recovery instead of finalizing the rebalance
rule ccipReceive_REBALANCE_When_DepositFails_StoresRecovery() {
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
}

/// ───────────────────────── INITIATE REBALANCE ──────────────────

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
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require newStrategy.protocolId != getRebalance().activeStrategy.protocolId
        || newStrategy.chainSelector != getRebalance().activeStrategy.chainSelector,
        "new strategy should differ from the active strategy";
    require getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";
    require getEpochNonce() > 1, "at least one epoch should have completed";
    require getEpoch(assert_uint256(getEpochNonce() - 1)).status != Types.EpochStatus.EXECUTING,
        "previous epoch should not be executing";

    /// @dev revert condition being verified
    require !hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);

    storage before = lastStorage;

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a rebalance reverts when called during an active non-reentrant execution
/// @dev Verifies that a reentrant call leaves all vault state unchanged
rule initiateRebalance_RevertWhen_ReentrantCall() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require newStrategy.protocolId != getRebalance().activeStrategy.protocolId
        || newStrategy.chainSelector != getRebalance().activeStrategy.chainSelector,
        "new strategy should differ from the active strategy";
    require getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";
    require getEpochNonce() > 1, "at least one epoch should have completed";
    require getEpoch(assert_uint256(getEpochNonce() - 1)).status != Types.EpochStatus.EXECUTING,
        "previous epoch should not be executing";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";

    storage before = lastStorage;

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a rebalance reverts when the vault is paused
/// @dev Verifies that a paused vault leaves all vault state unchanged
rule initiateRebalance_RevertWhen_Paused() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require newStrategy.protocolId != getRebalance().activeStrategy.protocolId
        || newStrategy.chainSelector != getRebalance().activeStrategy.chainSelector,
        "new strategy should differ from the active strategy";
    require getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";
    require getEpochNonce() > 1, "at least one epoch should have completed";
    require getEpoch(assert_uint256(getEpochNonce() - 1)).status != Types.EpochStatus.EXECUTING,
        "previous epoch should not be executing";

    /// @dev revert condition being verified
    require paused(), "vault should be paused";

    storage before = lastStorage;

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a rebalance reverts when any recovery operation is already pending
/// @dev Verifies that a pending recovery cannot be overwritten
rule initiateRebalance_RevertWhen_RecoveryAlreadyPending() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";

    /// @dev revert condition being verified
    require getRecoveryMode() != Types.RecoveryMode.NONE, "recovery should be pending";

    storage before = lastStorage;

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a rebalance reverts when another rebalance is already in progress
/// @dev Verifies that the active rebalance guard leaves all vault state unchanged
rule REBAL_002_initiateRebalance_RevertWhen_RebalanceInProgress() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";

    /// @dev revert condition being verified
    require getRebalance().state != Types.RebalanceState.NONE, "rebalance should be in progress";

    storage before = lastStorage;

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a rebalance reverts when the target strategy is already active
/// @dev Verifies the same-strategy guard exposed through the ParentVault entry point
rule REBAL_003_initiateRebalance_RevertWhen_SameStrategy() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
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

    storage before = lastStorage;

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a rebalance reverts when the target chain is not registered
/// @dev Verifies the invalid-chain guard exposed through the ParentVault entry point
rule initiateRebalance_RevertWhen_InvalidChainSelector() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
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
    require getCrosschainVault(newStrategy.chainSelector) == 0, "target chain should not be supported";

    storage before = lastStorage;

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a rebalance reverts when the target protocol is unsupported
/// @dev Verifies the invalid-protocol guard exposed through the ParentVault entry point
rule initiateRebalance_RevertWhen_InvalidProtocolId() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require newStrategy.protocolId != getRebalance().activeStrategy.protocolId
        || newStrategy.chainSelector != getRebalance().activeStrategy.chainSelector,
        "new strategy should differ from the active strategy";
    require getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";

    /// @dev revert condition being verified
    require !getSupportedProtocol(newStrategy.protocolId), "target protocol should not be supported";

    storage before = lastStorage;

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a rebalance reverts before any epoch has completed
/// @dev Verifies the no-completed-epoch guard exposed through the ParentVault entry point
rule initiateRebalance_RevertWhen_NoCompletedEpoch() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require newStrategy.protocolId != getRebalance().activeStrategy.protocolId
        || newStrategy.chainSelector != getRebalance().activeStrategy.chainSelector,
        "new strategy should differ from the active strategy";
    require getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";

    /// @dev revert condition being verified
    require getEpochNonce() == 1, "no epoch should have completed";

    storage before = lastStorage;

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a rebalance reverts while the previous epoch is still executing
/// @dev Verifies the prior-executing-epoch guard exposed through the ParentVault entry point
rule initiateRebalance_RevertWhen_PreviousEpochExecuting() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require newStrategy.protocolId != getRebalance().activeStrategy.protocolId
        || newStrategy.chainSelector != getRebalance().activeStrategy.chainSelector,
        "new strategy should differ from the active strategy";
    require getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";

    /// @dev revert condition being verified
    require getEpochNonce() > 1, "at least one epoch should have completed";
    require getEpoch(assert_uint256(getEpochNonce() - 1)).status == Types.EpochStatus.EXECUTING,
        "previous epoch should be executing";

    storage before = lastStorage;

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a local-source rebalance reverts when no active adapter is set
/// @dev Verifies the _executeWithdraw NoActiveAdapter path after rebalance state is tentatively written
rule initiateRebalance_WITHDRAW_LOCAL_RevertWhen_NoActiveAdapter() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
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
    require getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";
    require getEpochNonce() > 1, "at least one epoch should have completed";
    require getEpoch(assert_uint256(getEpochNonce() - 1)).status != Types.EpochStatus.EXECUTING,
        "previous epoch should not be executing";

    /// @dev revert condition being verified
    require getActiveProtocolAdapter() == 0, "active adapter should be unset";

    storage before = lastStorage;

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a local-source rebalance reverts when withdrawing from the old adapter fails
/// @dev Verifies the _executeWithdraw revertOnFailure=true path and atomic rollback
rule initiateRebalance_WITHDRAW_LOCAL_RevertWhen_WithdrawFails() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
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
    require getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";
    require getEpochNonce() > 1, "at least one epoch should have completed";
    require getEpoch(assert_uint256(getEpochNonce() - 1)).status != Types.EpochStatus.EXECUTING,
        "previous epoch should not be executing";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";

    /// @dev revert condition being verified
    require adapter.withdrawReverts(), "adapter withdraw should revert";

    storage before = lastStorage;

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a local-to-local rebalance reverts when the target adapter is not registered
/// @dev Verifies the _setActiveAdapter registration guard after the old local strategy is withdrawn
rule initiateRebalance_LOCAL_TO_LOCAL_RevertWhen_TargetAdapterNotRegistered() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
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
    require getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";
    require getEpochNonce() > 1, "at least one epoch should have completed";
    require getEpoch(assert_uint256(getEpochNonce() - 1)).status != Types.EpochStatus.EXECUTING,
        "previous epoch should not be executing";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() == 0 || asset.balanceOf(adapter) >= adapter.getTVL(),
        "adapter should be able to transfer withdrawn TVL";

    /// @dev revert condition being verified
    require adapterRegistry.getAdapter(e, newStrategy.protocolId) == 0, "target adapter should not be registered";

    storage before = lastStorage;

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a local-to-local rebalance reverts when the target adapter belongs to another vault
/// @dev Verifies the _setActiveAdapter adapter-vault guard after the old local strategy is withdrawn
rule initiateRebalance_LOCAL_TO_LOCAL_RevertWhen_TargetAdapterVaultIsInvalid() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
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
    require getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";
    require getEpochNonce() > 1, "at least one epoch should have completed";
    require getEpoch(assert_uint256(getEpochNonce() - 1)).status != Types.EpochStatus.EXECUTING,
        "previous epoch should not be executing";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() == 0 || asset.balanceOf(adapter) >= adapter.getTVL(),
        "adapter should be able to transfer withdrawn TVL";
    require invalidAdapter.getVault() != currentContract, "target adapter should not be bound to this vault";

    /// @dev revert condition being verified
    require adapterRegistry.getAdapter(e, newStrategy.protocolId) == invalidAdapter,
        "invalid target adapter should be registered";

    storage before = lastStorage;

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a local-to-local rebalance reverts when depositing into the new adapter fails
/// @dev Verifies the _executeDeposit revertOnFailure=true path and atomic rollback
rule initiateRebalance_LOCAL_TO_LOCAL_RevertWhen_DepositFails() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
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
    require getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";
    require getEpochNonce() > 1, "at least one epoch should have completed";
    require getEpoch(assert_uint256(getEpochNonce() - 1)).status != Types.EpochStatus.EXECUTING,
        "previous epoch should not be executing";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require adapterRegistry.getAdapter(e, newStrategy.protocolId) == adapter, "target adapter should be registered";
    require adapter.getVault() == currentContract, "target adapter should be bound to this vault";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    uint256 amountOut = adapter.getTVL();
    require asset.balanceOf(adapter) >= amountOut, "adapter asset balance should cover the withdraw amount";
    require asset.balanceOf(currentContract) <= max_uint256 - amountOut,
        "vault asset balance should not overflow on withdraw";

    /// @dev revert condition being verified
    require adapter.depositReverts(), "target adapter deposit should revert";

    storage before = lastStorage;

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a local-to-local rebalance reverts when finalizeRebalance would overflow the nonce
/// @dev Verifies the finalizeRebalance nonce increment through the initiateRebalance entry point
rule initiateRebalance_LOCAL_TO_LOCAL_RevertWhen_RebalanceNonceOverflows() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
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
    require getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";
    require getEpochNonce() > 1, "at least one epoch should have completed";
    require getEpoch(assert_uint256(getEpochNonce() - 1)).status != Types.EpochStatus.EXECUTING,
        "previous epoch should not be executing";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require adapterRegistry.getAdapter(e, newStrategy.protocolId) == adapter, "target adapter should be registered";
    require adapter.getVault() == currentContract, "target adapter should be bound to this vault";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require !adapter.depositReverts(), "target adapter deposit should not revert";
    uint256 amountOut = adapter.getTVL();
    require asset.balanceOf(adapter) >= amountOut, "adapter asset balance should cover the withdraw amount";
    require asset.balanceOf(currentContract) <= max_uint256 - amountOut,
        "vault asset balance should not overflow on withdraw";
    require asset.balanceOf(adapter) <= max_uint256 - amountOut,
        "adapter asset balance should not overflow on deposit";
    require getRebalance().lastRebalanceCompletedTimestamp <= e.block.timestamp,
        "management fee elapsed time should not underflow";

    /// @dev revert condition being verified
    require getRebalance().nonce == max_uint256, "rebalance nonce increment should overflow";

    storage before = lastStorage;

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a local-to-local rebalance reverts when the last completed timestamp is in the future
/// @dev Verifies the management-fee elapsed-time underflow through initiateRebalance finalization
rule initiateRebalance_LOCAL_TO_LOCAL_RevertWhen_LastCompletedTimestampIsFuture() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
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
    require getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";
    require getEpochNonce() > 1, "at least one epoch should have completed";
    require getEpoch(assert_uint256(getEpochNonce() - 1)).status != Types.EpochStatus.EXECUTING,
        "previous epoch should not be executing";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require adapterRegistry.getAdapter(e, newStrategy.protocolId) == adapter, "target adapter should be registered";
    require adapter.getVault() == currentContract, "target adapter should be bound to this vault";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require !adapter.depositReverts(), "target adapter deposit should not revert";
    uint256 amountOut = adapter.getTVL();
    require asset.balanceOf(adapter) >= amountOut, "adapter asset balance should cover the withdraw amount";
    require asset.balanceOf(currentContract) <= max_uint256 - amountOut,
        "vault asset balance should not overflow on withdraw";
    require asset.balanceOf(adapter) <= max_uint256 - amountOut,
        "adapter asset balance should not overflow on deposit";
    require getRebalance().nonce < max_uint256, "rebalance nonce increment should not overflow";

    /// @dev revert condition being verified
    require getRebalance().lastRebalanceCompletedTimestamp > e.block.timestamp,
        "last completed timestamp should be in the future";

    storage before = lastStorage;

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a local-to-local rebalance reverts when management fee bps multiplication overflows
/// @dev Verifies totalShares * MANAGEMENT_FEE_BPS through initiateRebalance finalization
rule initiateRebalance_LOCAL_TO_LOCAL_RevertWhen_ManagementFeeBpsMultiplicationOverflows() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
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
    require getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";
    require getEpochNonce() > 1, "at least one epoch should have completed";
    require getEpoch(assert_uint256(getEpochNonce() - 1)).status != Types.EpochStatus.EXECUTING,
        "previous epoch should not be executing";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require adapterRegistry.getAdapter(e, newStrategy.protocolId) == adapter, "target adapter should be registered";
    require adapter.getVault() == currentContract, "target adapter should be bound to this vault";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require !adapter.depositReverts(), "target adapter deposit should not revert";
    uint256 amountOut = adapter.getTVL();
    require asset.balanceOf(adapter) >= amountOut, "adapter asset balance should cover the withdraw amount";
    require asset.balanceOf(currentContract) <= max_uint256 - amountOut,
        "vault asset balance should not overflow on withdraw";
    require asset.balanceOf(adapter) <= max_uint256 - amountOut,
        "adapter asset balance should not overflow on deposit";
    require getRebalance().nonce < max_uint256, "rebalance nonce increment should not overflow";
    require getRebalance().lastRebalanceCompletedTimestamp <= e.block.timestamp,
        "management fee elapsed time should not underflow";

    /// @dev revert condition being verified
    require getTotalShares() > max_uint256 / MANAGEMENT_FEE_BPS(),
        "total shares fee bps multiplication should overflow";

    storage before = lastStorage;

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a local-to-local rebalance reverts when management fee elapsed multiplication overflows
/// @dev Verifies totalShares * MANAGEMENT_FEE_BPS * elapsed through initiateRebalance finalization
rule initiateRebalance_LOCAL_TO_LOCAL_RevertWhen_ManagementFeeElapsedMultiplicationOverflows() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
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
    require getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";
    require getEpochNonce() > 1, "at least one epoch should have completed";
    require getEpoch(assert_uint256(getEpochNonce() - 1)).status != Types.EpochStatus.EXECUTING,
        "previous epoch should not be executing";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require adapterRegistry.getAdapter(e, newStrategy.protocolId) == adapter, "target adapter should be registered";
    require adapter.getVault() == currentContract, "target adapter should be bound to this vault";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require !adapter.depositReverts(), "target adapter deposit should not revert";
    uint256 amountOut = adapter.getTVL();
    require asset.balanceOf(adapter) >= amountOut, "adapter asset balance should cover the withdraw amount";
    require asset.balanceOf(currentContract) <= max_uint256 - amountOut,
        "vault asset balance should not overflow on withdraw";
    require asset.balanceOf(adapter) <= max_uint256 - amountOut,
        "adapter asset balance should not overflow on deposit";
    require getRebalance().nonce < max_uint256, "rebalance nonce increment should not overflow";
    require getRebalance().lastRebalanceCompletedTimestamp <= e.block.timestamp,
        "management fee elapsed time should not underflow";

    uint256 totalShares = getTotalShares();
    mathint elapsedRaw = e.block.timestamp - getRebalance().lastRebalanceCompletedTimestamp;
    mathint elapsed = elapsedRaw > to_mathint(YEAR()) ? to_mathint(YEAR()) : elapsedRaw;
    require elapsed != 0, "elapsed time should be nonzero";
    require totalShares <= max_uint256 / MANAGEMENT_FEE_BPS(),
        "total shares fee bps multiplication should not overflow";
    mathint product = totalShares * MANAGEMENT_FEE_BPS();

    /// @dev revert condition being verified
    require product > max_uint256 / elapsed, "elapsed fee multiplication should overflow";

    storage before = lastStorage;

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a local-to-local rebalance reverts when management fee ceil numerator overflows
/// @dev Verifies the final numerator addition in ceilDiv through initiateRebalance finalization
rule initiateRebalance_LOCAL_TO_LOCAL_RevertWhen_ManagementFeeCeilNumeratorOverflows() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
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
    require getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";
    require getEpochNonce() > 1, "at least one epoch should have completed";
    require getEpoch(assert_uint256(getEpochNonce() - 1)).status != Types.EpochStatus.EXECUTING,
        "previous epoch should not be executing";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require adapterRegistry.getAdapter(e, newStrategy.protocolId) == adapter, "target adapter should be registered";
    require adapter.getVault() == currentContract, "target adapter should be bound to this vault";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require !adapter.depositReverts(), "target adapter deposit should not revert";
    uint256 amountOut = adapter.getTVL();
    require asset.balanceOf(adapter) >= amountOut, "adapter asset balance should cover the withdraw amount";
    require asset.balanceOf(currentContract) <= max_uint256 - amountOut,
        "vault asset balance should not overflow on withdraw";
    require asset.balanceOf(adapter) <= max_uint256 - amountOut,
        "adapter asset balance should not overflow on deposit";
    require getRebalance().nonce < max_uint256, "rebalance nonce increment should not overflow";
    require getRebalance().lastRebalanceCompletedTimestamp <= e.block.timestamp,
        "management fee elapsed time should not underflow";

    uint256 totalShares = getTotalShares();
    mathint elapsedRaw = e.block.timestamp - getRebalance().lastRebalanceCompletedTimestamp;
    mathint elapsed = elapsedRaw > to_mathint(YEAR()) ? to_mathint(YEAR()) : elapsedRaw;
    require totalShares <= max_uint256 / MANAGEMENT_FEE_BPS(),
        "total shares fee bps multiplication should not overflow";
    mathint product = totalShares * MANAGEMENT_FEE_BPS();
    require elapsed == 0 || product <= max_uint256 / elapsed, "elapsed fee multiplication should not overflow";
    mathint numerator = product * elapsed;
    mathint denominator = BPS_DENOMINATOR() * YEAR();

    /// @dev revert condition being verified
    require numerator > max_uint256 - (denominator - 1), "management fee numerator addition should overflow";

    storage before = lastStorage;

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a local-to-remote rebalance reverts when no destination vault is set
/// @dev Verifies the _ccipSend destination-vault guard after the old local strategy is withdrawn
rule initiateRebalance_LOCAL_TO_REMOTE_RevertWhen_DestinationVaultNotSet() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
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
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";
    require getEpochNonce() > 1, "at least one epoch should have completed";
    require getEpoch(assert_uint256(getEpochNonce() - 1)).status != Types.EpochStatus.EXECUTING,
        "previous epoch should not be executing";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() != 0, "withdrawn amount should not be zero";
    require asset.balanceOf(adapter) >= adapter.getTVL(), "adapter asset balance should cover the withdraw amount";
    require asset.balanceOf(currentContract) <= max_uint256 - adapter.getTVL(),
        "vault asset balance should not overflow on withdraw";

    /// @dev revert condition being verified
    require getCrosschainVault(newStrategy.chainSelector) == 0, "destination vault should not be set";

    storage before = lastStorage;

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a local-to-remote rebalance reverts when the target chain selector is zero
/// @dev Verifies _ccipSend's invalid destination selector guard after rebalance validation accepts the chain
rule initiateRebalance_LOCAL_TO_REMOTE_RevertWhen_DestinationChainSelectorIsZero() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";
    require getThisChainSelector() != 0, "current chain selector should not be zero";
    require getRebalance().activeStrategy.chainSelector == getThisChainSelector(),
        "active strategy should be local";
    require newStrategy.protocolId != getRebalance().activeStrategy.protocolId
        || newStrategy.chainSelector != getRebalance().activeStrategy.chainSelector,
        "new strategy should differ from the active strategy";
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";
    require getEpochNonce() > 1, "at least one epoch should have completed";
    require getEpoch(assert_uint256(getEpochNonce() - 1)).status != Types.EpochStatus.EXECUTING,
        "previous epoch should not be executing";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() != 0, "withdrawn amount should not be zero";
    require asset.balanceOf(adapter) >= adapter.getTVL(), "adapter asset balance should cover the withdraw amount";
    require asset.balanceOf(currentContract) <= max_uint256 - adapter.getTVL(),
        "vault asset balance should not overflow on withdraw";

    /// @dev revert condition being verified
    require newStrategy.chainSelector == 0, "target chain selector should be zero";
    require getCrosschainVault(newStrategy.chainSelector) != 0,
        "rebalance validation should treat the zero selector as supported";

    storage before = lastStorage;

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a local-to-remote rebalance reverts when the old local strategy withdraws zero
/// @dev Verifies _ccipSend's zero bridge amount guard after a successful zero-amount withdraw
rule initiateRebalance_LOCAL_TO_REMOTE_RevertWhen_BridgeAmountIsZero() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
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

    /// @dev revert condition being verified
    require adapter.getTVL() == 0, "withdrawn bridge amount should be zero";

    storage before = lastStorage;

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a local-to-remote rebalance reverts when the router fee quote reverts
/// @dev Verifies the _ccipSend getFee failure path and atomic rollback
rule initiateRebalance_LOCAL_TO_REMOTE_RevertWhen_RouterGetFeeReverts() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
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
    require adapter.getTVL() != 0, "withdrawn amount should not be zero";
    require asset.balanceOf(adapter) >= adapter.getTVL(), "adapter asset balance should cover the withdraw amount";
    require asset.balanceOf(currentContract) <= max_uint256 - adapter.getTVL(),
        "vault asset balance should not overflow on withdraw";

    /// @dev revert condition being verified
    require ccipRouter.getFeeReverts(), "router fee quote should revert";

    storage before = lastStorage;

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a local-to-remote rebalance reverts when router ccipSend reverts
/// @dev Verifies the _ccipSend send failure path and atomic rollback
rule initiateRebalance_LOCAL_TO_REMOTE_RevertWhen_RouterCcipSendReverts() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
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
    require adapter.getTVL() != 0, "withdrawn amount should not be zero";
    require asset.balanceOf(adapter) >= adapter.getTVL(), "adapter asset balance should cover the withdraw amount";
    require asset.balanceOf(currentContract) <= max_uint256 - adapter.getTVL(),
        "vault asset balance should not overflow on withdraw";
    require !ccipRouter.getFeeReverts(), "router fee quote should not revert";

    /// @dev revert condition being verified
    require ccipRouter.ccipSendReverts(), "router send should revert";

    storage before = lastStorage;

    initiateRebalance@withrevert(e, newStrategy);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Initiating a rebalance from a remote active strategy stores the pending strategy and emits
///         RebalanceInitiated without taking a local external action
rule initiateRebalance_REMOTE_ACTIVE_Success() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
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
    require getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";
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
    require ghost_rebalance_state_StoreCount == 0;
    require ghost_rebalance_pendingStrategy_protocolId_StoreCount == 0;
    require ghost_rebalance_pendingStrategy_chainSelector_StoreCount == 0;

    initiateRebalance@withrevert(e, newStrategy);

    assert !lastReverted;
    assert getRebalance().state == Types.RebalanceState.REBALANCING;
    assert getRebalance().pendingStrategy.protocolId == newStrategy.protocolId;
    assert getRebalance().pendingStrategy.chainSelector == newStrategy.chainSelector;
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
rule initiateRebalance_LOCAL_TO_REMOTE_Success() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
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
    uint256 linkBalanceBefore = link.balanceOf(currentContract);
    uint256 fee = ccipRouter.getFee();
    require adapterBalanceBefore >= amountOut, "adapter asset balance should cover the withdraw amount";
    require vaultBalanceBefore <= max_uint256 - amountOut, "vault asset balance should not overflow on withdraw";
    require vaultBalanceBefore + amountOut >= amountOut, "vault should hold enough asset for CCIP";
    require linkBalanceBefore >= fee, "vault should hold enough LINK for the CCIP fee";

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
    assert getRebalance().pendingStrategy.protocolId == newStrategy.protocolId;
    assert getRebalance().pendingStrategy.chainSelector == newStrategy.chainSelector;
    assert adapter.getTVL() == 0;
    assert asset.balanceOf(adapter) == adapterBalanceBefore - amountOut;
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
    assert ghost_CCIPBridged_Param_amount == amountOut;
    assert ghost_CCIPBridged_Param_ccipTxType == Types.CcipTx.REBALANCE;
}

/// @notice Initiating a local-to-local rebalance withdraws local TVL, switches adapters, deposits
///         into the target adapter, finalizes the rebalance, and emits the full local event sequence
rule initiateRebalance_LOCAL_TO_LOCAL_Success() {
    env e;
    Types.Strategy newStrategy;

    /// @dev revert conditions NOT being verified
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
    require getCrosschainVault(newStrategy.chainSelector) != 0, "target chain should be supported";
    require getSupportedProtocol(newStrategy.protocolId), "target protocol should be supported";
    require getEpochNonce() > 1, "at least one epoch should have completed";
    require getEpoch(assert_uint256(getEpochNonce() - 1)).status != Types.EpochStatus.EXECUTING,
        "previous epoch should not be executing";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require adapterRegistry.getAdapter(e, newStrategy.protocolId) == adapter, "target adapter should be registered";
    require adapter.getVault() == currentContract, "target adapter should be bound to this vault";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require !adapter.depositReverts(), "target adapter deposit should not revert";

    uint256 amountOut = adapter.getTVL();
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 lastRebalanceCompletedTimestampBefore = getRebalance().lastRebalanceCompletedTimestamp;
    uint256 totalSharesBefore = getTotalShares();
    require asset.balanceOf(adapter) >= amountOut, "adapter asset balance should cover the withdraw amount";
    require vaultBalanceBefore <= max_uint256 - amountOut, "vault asset balance should not overflow on withdraw";
    require adapterBalanceBefore <= max_uint256 - amountOut, "adapter asset balance should not overflow on deposit";
    require e.block.timestamp >= lastRebalanceCompletedTimestampBefore,
        "block timestamp should not precede the last rebalance completion";
    require getRebalance().nonce < max_uint256, "rebalance nonce increment should not overflow";

    /// @dev model ParentVaultFeesLib's management fee formula
    mathint elapsedRaw = e.block.timestamp - lastRebalanceCompletedTimestampBefore;
    mathint elapsed = elapsedRaw > to_mathint(YEAR()) ? to_mathint(YEAR()) : elapsedRaw;
    mathint denominator = BPS_DENOMINATOR() * YEAR();
    require totalSharesBefore <= max_uint256 / MANAGEMENT_FEE_BPS(),
        "total shares fee bps multiplication should not overflow";
    mathint product = totalSharesBefore * MANAGEMENT_FEE_BPS();
    require elapsed == 0 || product <= max_uint256 / elapsed, "elapsed fee multiplication should not overflow";
    mathint numerator = product * elapsed;
    require numerator <= max_uint256 - (denominator - 1), "management fee numerator should not overflow";
    mathint feeShares = (numerator + denominator - 1) / denominator;
    uint256 priorTreasuryShareBalance = share.balanceOf(getTreasury());
    require totalSharesBefore <= max_uint256 - feeShares, "total shares should not overflow when minting the fee";
    require priorTreasuryShareBalance <= max_uint256 - feeShares, "treasury share balance should not overflow";
    require share.totalSupply() <= max_uint256 - feeShares, "share total supply should not overflow";

    uint256 rebalanceNonce = getRebalance().nonce;

    /// @dev set ghost starting values
    require ghost_RebalanceInitiated_EventCount == 0;
    require ghost_RebalanceWithdrawSuccess_EventCount == 0;
    require ghost_ActiveProtocolAdapterSet_EventCount == 0;
    require ghost_RebalanceDepositSuccess_EventCount == 0;
    require ghost_RebalanceCompleted_EventCount == 0;
    require ghost_ManagementFeeCollected_EventCount == 0;

    initiateRebalance@withrevert(e, newStrategy);

    assert !lastReverted;
    assert getActiveProtocolAdapter() == adapter;
    assert getRebalance().state == Types.RebalanceState.NONE;
    assert getRebalance().activeStrategy.protocolId == newStrategy.protocolId;
    assert getRebalance().activeStrategy.chainSelector == newStrategy.chainSelector;
    assert getRebalance().pendingStrategy.protocolId == to_bytes32(0);
    assert getRebalance().pendingStrategy.chainSelector == 0;
    assert getRebalance().nonce == rebalanceNonce + 1;
    assert getRebalance().lastRebalanceCompletedTimestamp == e.block.timestamp;
    assert adapter.getTVL() == amountOut;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert ghost_RebalanceInitiated_EventCount == 1;
    assert ghost_RebalanceInitiated_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_RebalanceInitiated_Param_chainSelector == newStrategy.chainSelector;
    assert ghost_RebalanceInitiated_Param_protocolId == newStrategy.protocolId;
    assert ghost_RebalanceWithdrawSuccess_EventCount == 1;
    assert ghost_RebalanceWithdrawSuccess_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_RebalanceWithdrawSuccess_Param_amount == amountOut;
    assert ghost_ActiveProtocolAdapterSet_EventCount == 1;
    assert ghost_ActiveProtocolAdapterSet_Param_protocolId == newStrategy.protocolId;
    assert ghost_ActiveProtocolAdapterSet_Param_adapter == adapter;
    assert ghost_RebalanceDepositSuccess_EventCount == 1;
    assert ghost_RebalanceDepositSuccess_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_RebalanceDepositSuccess_Param_amount == amountOut;
    assert ghost_RebalanceCompleted_EventCount == 1;
    assert ghost_RebalanceCompleted_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_RebalanceCompleted_Param_newProtocolId == newStrategy.protocolId;
    assert ghost_RebalanceCompleted_Param_newChainSelector == newStrategy.chainSelector;
    assert feeShares == 0 => (getTotalShares() == totalSharesBefore && ghost_ManagementFeeCollected_EventCount == 0);
    assert feeShares != 0 => (
        to_mathint(getTotalShares()) == totalSharesBefore + feeShares
        && to_mathint(share.balanceOf(getTreasury())) == priorTreasuryShareBalance + feeShares
        && ghost_ManagementFeeCollected_EventCount == 1
        && ghost_ManagementFeeCollected_Param_rebalanceNonce == rebalanceNonce
        && to_mathint(ghost_ManagementFeeCollected_Param_feeShares) == feeShares
    );
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

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
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

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing an epoch reverts when the vault is paused
/// @dev Verifies that a paused vault leaves all vault state unchanged
rule closeEpoch_RevertWhen_Paused() {
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

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing an epoch reverts when any recovery operation is already pending
/// @dev Verifies that a pending recovery cannot be overwritten by a new epoch close. This guard is
///      ParentVault-level (s_recoveryMode) and is not visible to ParentVaultEpochLib's own rules.
rule closeEpoch_RevertWhen_RecoveryAlreadyPending() {
    env e;
    uint256 tvl;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";

    /// @dev revert condition being verified
    require getRecoveryMode() != Types.RecoveryMode.NONE, "recovery should be pending";

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing an epoch reverts when a rebalance is in progress
/// @dev Verifies that the vault-level entry point correctly surfaces ParentVaultEpochLib's guard
///      (exhaustively covered in ParentVaultEpochLib.spec) and leaves all vault state unchanged
rule EPOCH_003_closeEpoch_RevertWhen_RebalanceInProgress() {
    env e;
    uint256 tvl;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";

    /// @dev revert condition being verified
    require getRebalance().state != Types.RebalanceState.NONE, "rebalance should be in progress";

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing an epoch reverts when the current epoch nonce is zero
/// @dev Verifies that the ParentVault entry point surfaces the epoch nonce underflow guard
rule closeEpoch_RevertWhen_CurrentEpochNonceIsZero() {
    env e;
    uint256 tvl;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";

    /// @dev revert condition being verified
    require getEpochNonce() == 0, "epoch nonce should be zero";

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing an epoch reverts when the previous nonzero epoch is not claimable
/// @dev Verifies that ParentVault cannot close a new epoch while the prior epoch is unresolved
rule EPOCH_003_closeEpoch_RevertWhen_PreviousEpochNotClaimable() {
    env e;
    uint256 tvl;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EPOCH_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().state == Types.RebalanceState.NONE, "rebalance should not be in progress";

    /// @dev revert condition being verified
    require getEpochNonce() > 1, "previous epoch nonce should be nonzero";
    uint256 previousEpochNonce = assert_uint256(getEpochNonce() - 1);
    require getEpoch(previousEpochNonce).status != Types.EpochStatus.CLAIMABLE,
        "previous epoch should not be claimable";

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing an epoch reverts when the current epoch is not open
/// @dev Verifies the current-epoch status guard through the ParentVault entry point
rule closeEpoch_RevertWhen_EpochNotOpen() {
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

    /// @dev revert condition being verified
    require getEpoch(epochNonce).status != Types.EpochStatus.OPEN, "epoch should not be open";

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing an epoch reverts when the minimum-period timestamp addition overflows
/// @dev Verifies that openedAtTimestamp + MIN_EPOCH_PERIOD is checked atomically
rule closeEpoch_RevertWhen_EpochOpenTimestampOverflows() {
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

    /// @dev revert condition being verified
    require getEpoch(epochNonce).openedAtTimestamp > max_uint256 - MIN_EPOCH_PERIOD(),
        "minimum epoch period addition should overflow";

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing an epoch reverts when the minimum epoch period has not elapsed
/// @dev Verifies the too-short epoch guard through the ParentVault entry point
rule closeEpoch_RevertWhen_EpochTooShort() {
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

    /// @dev revert condition being verified
    require e.block.timestamp < getEpoch(epochNonce).openedAtTimestamp + MIN_EPOCH_PERIOD(),
        "minimum epoch period should not have elapsed";

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing an epoch reverts when there are no deposits and no withdraw intents
/// @dev Verifies the empty-epoch guard through the ParentVault entry point
rule closeEpoch_RevertWhen_EmptyEpoch() {
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

    /// @dev revert condition being verified
    require getEpoch(epochNonce).totalDepositAmount == 0, "total deposit amount should be zero";
    require getEpoch(epochNonce).totalShareBurnAmount == 0, "total share burn amount should be zero";

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing an epoch reverts when TVL is zero while shares are outstanding
/// @dev Verifies the ZeroTvlWithOutstandingShares branch through the ParentVault entry point
rule closeEpoch_RevertWhen_ZeroTvlWithOutstandingShares() {
    env e;

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
    require getEpoch(epochNonce).totalDepositAmount != 0 || getEpoch(epochNonce).totalShareBurnAmount != 0,
        "epoch should not be empty";

    /// @dev revert condition being verified
    require getTotalShares() != 0, "shares should be outstanding";
    uint256 tvl = 0;

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing an epoch with a zero net flow marks it claimable, mints no shares, and opens
///         the next epoch without any external strategy action
rule closeEpoch_Success_WhenNetFlowIsZero() {
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
    uint256 depositAmount = getEpoch(epochNonce).totalDepositAmount;
    uint256 shareBurnAmount = getEpoch(epochNonce).totalShareBurnAmount;

    /// @dev success conditions being verified - mirrors ParentVaultEpochLib.spec's
    ///      closeEpoch_Success_WhenNetFlowIsZero preconditions
    require getSharePrecision() != 0, "no divide by 0";
    require getMinDepositAmount() != 0, "minimum deposit amount should not be zero";
    require totalShares != 0, "shares should be outstanding";
    require totalShares <= max_uint256 / getSharePrecision(), "gross price per share should not overflow";
    require tvl == totalShares, "tvl should equal total shares for a clean price-per-share";
    require getPerformanceFeeHighWaterMark() >= getSharePrecision(), "performance fee should not be collected";
    require depositAmount != 0, "epoch should not be empty";
    require depositAmount == shareBurnAmount, "net flow should be zero";
    require depositAmount <= max_uint256 / getSharePrecision(), "share calculation should not overflow";
    require depositAmount <= max_uint256 / 2, "deposit amount should fit int256";
    require shareBurnAmount <= max_uint256 / 2, "withdraw amount should fit int256";
    require totalShares <= max_uint256 - depositAmount, "total shares addition should not overflow";
    require depositAmount <= max_uint256 / getMinDepositAmount(),
        "zero-share guard multiplication should not overflow";

    /// @dev set ghost starting values
    require ghost_EpochClaimable_EventCount == 0;
    require ghost_EpochOpen_EventCount == 0;
    require ghost_epoch_status_StoreCount == 0;
    require ghost_epochNonce_StoreCount == 0;

    closeEpoch@withrevert(e, tvl);

    assert !lastReverted;
    assert getTotalShares() == totalShares;
    assert getEpoch(epochNonce).status == Types.EpochStatus.CLAIMABLE;
    assert ghost_EpochClaimable_EventCount == 1;
    assert ghost_EpochClaimable_Param_epochNonce == epochNonce;
    assert getEpochNonce() == epochNonce + 1;
    assert getEpoch(assert_uint256(epochNonce + 1)).status == Types.EpochStatus.OPEN;
    assert getEpoch(assert_uint256(epochNonce + 1)).openedAtTimestamp == e.block.timestamp;
    assert ghost_EpochOpen_EventCount == 1;
    assert ghost_EpochOpen_Param_epochNonce == epochNonce + 1;
}

/// @notice Closing a profitable remote net-withdraw epoch reaches performance fee collection
/// @dev Verifies the ParentVault closeEpoch entry point invokes ParentVaultFeesLib and emits
///      PerformanceFeeCollected with the current epoch nonce. Detailed fee-share arithmetic, treasury
///      minting, high-water mark value, and event parameter calculations are verified in
///      ParentVaultFeesLib.spec.
rule closeEpoch_Success_WhenPerformanceFeeCollected() {
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

    uint256 sharePrecision = getSharePrecision();
    uint256 totalSharesBefore = getTotalShares();
    uint256 highWaterMarkBefore = getPerformanceFeeHighWaterMark();
    uint256 depositAmount = getEpoch(epochNonce).totalDepositAmount;
    uint256 shareBurnAmount = getEpoch(epochNonce).totalShareBurnAmount;

    /// @dev performance fee conditions being verified. Use one narrow profitable remote-withdraw
    ///      shape so ParentVault has no adapter or CCIP action after settlement.
    require sharePrecision == 1000000000000, "MockUSDC share precision path";
    require getMinDepositAmount() == 100000000, "MockUSDC minimum deposit path";
    require totalSharesBefore == sharePrecision, "total shares should equal share precision";
    require highWaterMarkBefore == sharePrecision, "high-water mark should equal share precision";
    require tvl == 2 * sharePrecision, "gross price should be exactly twice the high-water mark";
    require share.balanceOf(getTreasury()) <= max_uint256 - sharePrecision,
        "treasury share balance should not overflow";
    require share.totalSupply() <= max_uint256 - sharePrecision, "share total supply should not overflow";

    /// @dev remote net-withdraw conditions after performance fee dilution
    require depositAmount == 0, "no deposits should be made";
    require shareBurnAmount == sharePrecision, "shares should be burned";
    require getActiveProtocolAdapter() == 0, "no active adapter on this chain (remote strategy)";

    /// @dev set ghost starting values
    require ghost_PerformanceFeeCollected_EventCount == 0;
    require ghost_EpochExecuting_EventCount == 0;
    require ghost_EpochOpen_EventCount == 0;
    require ghost_totalShares_StoreCount == 0;
    require ghost_performanceFeeHighWaterMark_StoreCount == 0;

    closeEpoch@withrevert(e, tvl);

    assert !lastReverted;
    assert getPerformanceFeeHighWaterMark() > highWaterMarkBefore;
    assert getEpoch(epochNonce).status == Types.EpochStatus.EXECUTING;
    assert getEpoch(epochNonce).remainingDepositClaimAmount == depositAmount;
    assert getEpoch(epochNonce).remainingShareMintAmount == 0;
    assert getEpoch(epochNonce).remainingShareBurnAmount == shareBurnAmount;
    assert getEpoch(epochNonce).remainingWithdrawClaimAmount == getEpoch(epochNonce).totalWithdrawClaimAmount;
    assert ghost_PerformanceFeeCollected_EventCount == 1;
    assert ghost_PerformanceFeeCollected_Param_epochNonce == epochNonce;
    assert ghost_PerformanceFeeCollected_Param_feeShares != 0;
    assert ghost_PerformanceFeeCollected_Param_highWaterMark == getPerformanceFeeHighWaterMark();
    assert ghost_performanceFeeHighWaterMark_StoreCount == 1;
    assert ghost_EpochExecuting_EventCount == 1;
    assert ghost_EpochExecuting_Param_epochNonce == epochNonce;
    assert ghost_EpochExecuting_Param_amount == getEpoch(epochNonce).totalWithdrawClaimAmount;
    assert getEpochNonce() == epochNonce + 1;
    assert ghost_EpochOpen_EventCount == 1;
    assert ghost_EpochOpen_Param_epochNonce == epochNonce + 1;
}

/// @notice Closing a net-deposit epoch with a local strategy deposits the delivered amount into the
///         active adapter and emits DepositToStrategySuccess
rule closeEpoch_DEPOSIT_TO_LOCAL_STRATEGY_Success() {
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

    /// @dev success conditions being verified - mirrors closeEpoch_Success_WhenLocalNetDeposit
    require getSharePrecision() != 0, "no divide by 0";
    require getMinDepositAmount() != 0, "minimum deposit amount should not be zero";
    require getTotalShares() == 0, "bootstrap price per share path";
    require getPerformanceFeeHighWaterMark() >= getSharePrecision(), "performance fee should not be collected";
    require depositAmount != 0, "net deposit amount should be nonzero";
    require depositAmount <= max_uint256 / getSharePrecision(), "share calculation should not overflow";
    require depositAmount <= max_uint256 / 2, "deposit amount should fit int256";
    require getEpoch(epochNonce).totalShareBurnAmount == 0, "no shares should be burned";
    require depositAmount <= max_uint256 / getMinDepositAmount(),
        "zero-share guard multiplication should not overflow";
    require tvl == 0, "tvl is irrelevant on the bootstrap price-per-share path";

    /// @dev local-strategy + adapter conditions
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require adapter != currentContract, "adapter should not be the vault";
    require !adapter.depositReverts(), "adapter deposit should not revert";

    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();
    require depositAmount <= vaultBalanceBefore, "vault asset balance should cover the deposit amount";
    require adapterBalanceBefore <= max_uint256 - depositAmount, "adapter asset balance should not overflow";
    require adapterTVLBefore <= max_uint256 - depositAmount, "adapter TVL should not overflow";

    /// @dev set ghost starting values
    require ghost_DepositToStrategySuccess_EventCount == 0;
    require ghost_EpochOpen_EventCount == 0;
    require ghost_totalShares_StoreCount == 0;

    closeEpoch@withrevert(e, tvl);

    assert !lastReverted;
    assert getTotalShares() == depositAmount;
    assert getEpoch(epochNonce).status == Types.EpochStatus.CLAIMABLE;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore - depositAmount;
    assert asset.balanceOf(adapter) == adapterBalanceBefore + depositAmount;
    assert adapter.getTVL() == adapterTVLBefore + depositAmount;
    assert ghost_DepositToStrategySuccess_EventCount == 1;
    assert ghost_DepositToStrategySuccess_Param_epochNonce == epochNonce;
    assert ghost_DepositToStrategySuccess_Param_amount == depositAmount;
    assert getEpochNonce() == epochNonce + 1;
    assert ghost_EpochOpen_EventCount == 1;
    assert ghost_EpochOpen_Param_epochNonce == epochNonce + 1;
}

/// @notice Closing a net-deposit epoch with a local strategy reverts atomically (no recovery) when
///         the adapter deposit fails, since closeEpoch calls _executeDeposit with revertOnFailure=true
rule closeEpoch_DEPOSIT_TO_LOCAL_STRATEGY_RevertWhen_DepositFails() {
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
    require getSharePrecision() != 0, "no divide by 0";
    require getMinDepositAmount() != 0, "minimum deposit amount should not be zero";
    require getTotalShares() == 0, "bootstrap price per share path";
    require getPerformanceFeeHighWaterMark() >= getSharePrecision(), "performance fee should not be collected";
    require depositAmount != 0, "net deposit amount should be nonzero";
    require depositAmount <= max_uint256 / getSharePrecision(), "share calculation should not overflow";
    require depositAmount <= max_uint256 / 2, "deposit amount should fit int256";
    require getEpoch(epochNonce).totalShareBurnAmount == 0, "no shares should be burned";
    require depositAmount <= max_uint256 / getMinDepositAmount(),
        "zero-share guard multiplication should not overflow";
    require tvl == 0, "tvl is irrelevant on the bootstrap price-per-share path";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require depositAmount <= asset.balanceOf(currentContract), "vault asset balance should cover the deposit amount";

    /// @dev revert condition being verified
    require adapter.depositReverts(), "adapter deposit should revert";

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing a net-deposit epoch with a remote strategy bridges the delivered amount to the
///         active strategy chain via CCIP and emits CCIPBridged
/// @dev BaseVaultCcipLib.spec already exhaustively verifies the underlying send mechanics (fee
///      calculation, approvals, router success/failure) in isolation; this rule verifies that
///      closeEpoch correctly reaches and delegates to _ccipSend with the right arguments, and that
///      the resulting balance/event effects are visible through the full closeEpoch call.
rule closeEpoch_SEND_DEPOSIT_TO_REMOTE_STRATEGY_Success() {
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

    /// @dev success conditions being verified - mirrors closeEpoch_Success_WhenRemoteNetDeposit
    require getSharePrecision() != 0, "no divide by 0";
    require getMinDepositAmount() != 0, "minimum deposit amount should not be zero";
    require getTotalShares() == 0, "bootstrap price per share path";
    require getPerformanceFeeHighWaterMark() >= getSharePrecision(), "performance fee should not be collected";
    require depositAmount != 0, "net deposit amount should be nonzero";
    require depositAmount <= max_uint256 / getSharePrecision(), "share calculation should not overflow";
    require depositAmount <= max_uint256 / 2, "deposit amount should fit int256";
    require getEpoch(epochNonce).totalShareBurnAmount == 0, "no shares should be burned";
    require depositAmount <= max_uint256 / getMinDepositAmount(),
        "zero-share guard multiplication should not overflow";
    require tvl == 0, "tvl is irrelevant on the bootstrap price-per-share path";

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
    require fee <= vaultLinkBalanceBefore, "vault LINK balance should cover the CCIP fee";
    require routerLinkBalanceBefore <= max_uint256 - fee, "router LINK balance should not overflow";
    require depositAmount <= vaultAssetBalanceBefore, "vault asset balance should cover the bridge amount";
    require routerAssetBalanceBefore <= max_uint256 - depositAmount, "router asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_CCIPBridged_EventCount == 0;
    require ghost_EpochOpen_EventCount == 0;
    require ghost_totalShares_StoreCount == 0;

    closeEpoch@withrevert(e, tvl);

    assert !lastReverted;
    assert getTotalShares() == depositAmount;
    assert getEpoch(epochNonce).status == Types.EpochStatus.CLAIMABLE;
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore - fee;
    assert link.balanceOf(router) == routerLinkBalanceBefore + fee;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore - depositAmount;
    assert asset.balanceOf(router) == routerAssetBalanceBefore + depositAmount;
    assert ghost_CCIPBridged_EventCount == 1;
    assert ghost_CCIPBridged_Param_amount == depositAmount;
    assert ghost_CCIPBridged_Param_ccipTxType == Types.CcipTx.EPOCH_NET_DEPOSIT;
    assert getEpochNonce() == epochNonce + 1;
    assert ghost_EpochOpen_EventCount == 1;
    assert ghost_EpochOpen_Param_epochNonce == epochNonce + 1;
}

/// @notice Closing a net-deposit epoch with a remote strategy reverts atomically when the CCIP
///         router's destination vault is not registered for the active strategy chain
/// @dev Parent's _ccipSend is the atomic (non-try/catch) base implementation - unlike ChildVault,
///      ParentVault has no CCIP-send recovery mechanism, so any send failure reverts the whole call
rule closeEpoch_SEND_DEPOSIT_TO_REMOTE_STRATEGY_RevertWhen_DestinationVaultNotSet() {
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
    require getSharePrecision() != 0, "no divide by 0";
    require getMinDepositAmount() != 0, "minimum deposit amount should not be zero";
    require getTotalShares() == 0, "bootstrap price per share path";
    require getPerformanceFeeHighWaterMark() >= getSharePrecision(), "performance fee should not be collected";
    require depositAmount != 0, "net deposit amount should be nonzero";
    require depositAmount <= max_uint256 / getSharePrecision(), "share calculation should not overflow";
    require depositAmount <= max_uint256 / 2, "deposit amount should fit int256";
    require getEpoch(epochNonce).totalShareBurnAmount == 0, "no shares should be burned";
    require depositAmount <= max_uint256 / getMinDepositAmount(),
        "zero-share guard multiplication should not overflow";
    require tvl == 0, "tvl is irrelevant on the bootstrap price-per-share path";
    require getActiveProtocolAdapter() == 0, "no active adapter on this chain (remote strategy)";

    uint64 destinationChainSelector = getRebalance().activeStrategy.chainSelector;
    require destinationChainSelector != 0, "destination chain selector should not be zero";
    require destinationChainSelector != getThisChainSelector(), "destination should not be this chain";

    /// @dev revert condition being verified
    require getCrosschainVault(destinationChainSelector) == 0, "destination vault should not be registered";

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing a remote net-deposit epoch reverts when the active strategy chain selector is zero
/// @dev Verifies BaseVaultCcipLib's invalid-destination-selector branch through closeEpoch
rule closeEpoch_SEND_DEPOSIT_TO_REMOTE_STRATEGY_RevertWhen_DestinationChainSelectorIsZero() {
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
    require getSharePrecision() != 0, "no divide by 0";
    require getMinDepositAmount() != 0, "minimum deposit amount should not be zero";
    require getTotalShares() == 0, "bootstrap price per share path";
    require getPerformanceFeeHighWaterMark() >= getSharePrecision(), "performance fee should not be collected";
    require depositAmount != 0, "net deposit amount should be nonzero";
    require depositAmount <= max_uint256 / getSharePrecision(), "share calculation should not overflow";
    require depositAmount <= max_uint256 / 2, "deposit amount should fit int256";
    require getEpoch(epochNonce).totalShareBurnAmount == 0, "no shares should be burned";
    require depositAmount <= max_uint256 / getMinDepositAmount(),
        "zero-share guard multiplication should not overflow";
    require tvl == 0, "tvl is irrelevant on the bootstrap price-per-share path";
    require getActiveProtocolAdapter() == 0, "no active adapter on this chain (remote strategy)";

    /// @dev revert condition being verified
    require getRebalance().activeStrategy.chainSelector == 0, "destination chain selector should be zero";

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing a remote net-deposit epoch reverts when the active strategy chain is this chain
/// @dev Verifies BaseVaultCcipLib's self-destination selector guard through closeEpoch
rule closeEpoch_SEND_DEPOSIT_TO_REMOTE_STRATEGY_RevertWhen_DestinationChainSelectorIsThisChain() {
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
    require getSharePrecision() != 0, "no divide by 0";
    require getMinDepositAmount() != 0, "minimum deposit amount should not be zero";
    require getTotalShares() == 0, "bootstrap price per share path";
    require getPerformanceFeeHighWaterMark() >= getSharePrecision(), "performance fee should not be collected";
    require depositAmount != 0, "net deposit amount should be nonzero";
    require depositAmount <= max_uint256 / getSharePrecision(), "share calculation should not overflow";
    require depositAmount <= max_uint256 / 2, "deposit amount should fit int256";
    require getEpoch(epochNonce).totalShareBurnAmount == 0, "no shares should be burned";
    require depositAmount <= max_uint256 / getMinDepositAmount(),
        "zero-share guard multiplication should not overflow";
    require tvl == 0, "tvl is irrelevant on the bootstrap price-per-share path";
    require getActiveProtocolAdapter() == 0, "no active adapter on this chain (remote strategy)";

    /// @dev revert condition being verified
    require getRebalance().activeStrategy.chainSelector == getThisChainSelector(),
        "destination chain selector should be this chain";

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing a net-deposit epoch with a remote strategy reverts atomically when the CCIP
///         router's fee lookup fails
rule closeEpoch_SEND_DEPOSIT_TO_REMOTE_STRATEGY_RevertWhen_RouterGetFeeReverts() {
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
    require getSharePrecision() != 0, "no divide by 0";
    require getMinDepositAmount() != 0, "minimum deposit amount should not be zero";
    require getTotalShares() == 0, "bootstrap price per share path";
    require getPerformanceFeeHighWaterMark() >= getSharePrecision(), "performance fee should not be collected";
    require depositAmount != 0, "net deposit amount should be nonzero";
    require depositAmount <= max_uint256 / getSharePrecision(), "share calculation should not overflow";
    require depositAmount <= max_uint256 / 2, "deposit amount should fit int256";
    require getEpoch(epochNonce).totalShareBurnAmount == 0, "no shares should be burned";
    require depositAmount <= max_uint256 / getMinDepositAmount(),
        "zero-share guard multiplication should not overflow";
    require tvl == 0, "tvl is irrelevant on the bootstrap price-per-share path";
    require getActiveProtocolAdapter() == 0, "no active adapter on this chain (remote strategy)";

    uint64 destinationChainSelector = getRebalance().activeStrategy.chainSelector;
    require destinationChainSelector != 0, "destination chain selector should not be zero";
    require destinationChainSelector != getThisChainSelector(), "destination should not be this chain";
    require getCrosschainVault(destinationChainSelector) != 0, "destination vault should be registered";

    /// @dev revert condition being verified
    require ccipRouter.getFeeReverts(), "router fee lookup should revert";

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing a net-deposit epoch with a remote strategy reverts atomically when the CCIP
///         router's send call fails
rule closeEpoch_SEND_DEPOSIT_TO_REMOTE_STRATEGY_RevertWhen_RouterCcipSendReverts() {
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
    require getSharePrecision() != 0, "no divide by 0";
    require getMinDepositAmount() != 0, "minimum deposit amount should not be zero";
    require getTotalShares() == 0, "bootstrap price per share path";
    require getPerformanceFeeHighWaterMark() >= getSharePrecision(), "performance fee should not be collected";
    require depositAmount != 0, "net deposit amount should be nonzero";
    require depositAmount <= max_uint256 / getSharePrecision(), "share calculation should not overflow";
    require depositAmount <= max_uint256 / 2, "deposit amount should fit int256";
    require getEpoch(epochNonce).totalShareBurnAmount == 0, "no shares should be burned";
    require depositAmount <= max_uint256 / getMinDepositAmount(),
        "zero-share guard multiplication should not overflow";
    require tvl == 0, "tvl is irrelevant on the bootstrap price-per-share path";
    require getActiveProtocolAdapter() == 0, "no active adapter on this chain (remote strategy)";

    uint64 destinationChainSelector = getRebalance().activeStrategy.chainSelector;
    require destinationChainSelector != 0, "destination chain selector should not be zero";
    require destinationChainSelector != getThisChainSelector(), "destination should not be this chain";
    require getCrosschainVault(destinationChainSelector) != 0, "destination vault should be registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup should not revert";

    /// @dev revert condition being verified
    require ccipRouter.ccipSendReverts(), "router send should revert";

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing a net-withdraw epoch with a local strategy withdraws the net amount from the
///         active adapter, finalizes the epoch as claimable, and emits WithdrawFromStrategySuccess
rule closeEpoch_WITHDRAW_FROM_LOCAL_STRATEGY_Success() {
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

    /// @dev success conditions being verified - mirrors closeEpoch_Success_WhenLocalNetWithdraw
    require getSharePrecision() != 0, "no divide by 0";
    require totalShares != 0, "shares should be outstanding";
    require totalShares <= max_uint256 / getSharePrecision(), "gross price per share should not overflow";
    require tvl == totalShares, "tvl should equal total shares for a clean price-per-share";
    require getPerformanceFeeHighWaterMark() >= getSharePrecision(), "performance fee should not be collected";
    require getEpoch(epochNonce).totalDepositAmount == 0, "no deposits should be made";
    require shareBurnAmount != 0, "shares should be burned";
    require shareBurnAmount <= max_uint256 / getSharePrecision(), "withdraw calculation should not overflow";
    require shareBurnAmount <= max_uint256 / 2, "withdraw amount should fit int256";
    require totalShares >= shareBurnAmount, "total shares subtraction should not underflow";

    /// @dev local-strategy + adapter conditions
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require adapter != currentContract, "adapter should not be the vault";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter.getTVL() >= shareBurnAmount, "adapter should hold enough TVL to withdraw the net amount exactly";

    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();
    require adapterBalanceBefore >= shareBurnAmount, "adapter asset balance should cover the withdraw amount";
    require vaultBalanceBefore <= max_uint256 - shareBurnAmount, "vault asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_WithdrawFromStrategySuccess_EventCount == 0;
    require ghost_EpochClaimable_EventCount == 0;
    require ghost_EpochOpen_EventCount == 0;
    require ghost_totalShares_StoreCount == 0;

    closeEpoch@withrevert(e, tvl);

    assert !lastReverted;
    assert getTotalShares() == totalShares - shareBurnAmount;
    assert getEpoch(epochNonce).status == Types.EpochStatus.CLAIMABLE;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore + shareBurnAmount;
    assert asset.balanceOf(adapter) == adapterBalanceBefore - shareBurnAmount;
    assert adapter.getTVL() == adapterTVLBefore - shareBurnAmount;
    assert ghost_WithdrawFromStrategySuccess_EventCount == 1;
    assert ghost_WithdrawFromStrategySuccess_Param_epochNonce == epochNonce;
    assert ghost_WithdrawFromStrategySuccess_Param_amount == shareBurnAmount;
    assert ghost_EpochClaimable_EventCount == 1;
    assert ghost_EpochClaimable_Param_epochNonce == epochNonce;
    assert getEpochNonce() == epochNonce + 1;
    assert ghost_EpochOpen_EventCount == 1;
    assert ghost_EpochOpen_Param_epochNonce == epochNonce + 1;
}

/// @notice Closing a local net-withdraw epoch handles a successful short adapter withdraw
/// @dev Verifies that finalizeLocalNetWithdraw settles claims using actual amountOut, not requested amount
rule closeEpoch_WITHDRAW_FROM_LOCAL_STRATEGY_Success_WhenWithdrawReturnsLessThanRequested() {
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

    /// @dev success conditions being verified - mirrors closeEpoch_Success_WhenLocalNetWithdraw
    require getSharePrecision() != 0, "no divide by 0";
    require totalShares != 0, "shares should be outstanding";
    require totalShares <= max_uint256 / getSharePrecision(), "gross price per share should not overflow";
    require tvl == totalShares, "tvl should equal total shares for a clean price-per-share";
    require getPerformanceFeeHighWaterMark() >= getSharePrecision(), "performance fee should not be collected";
    require getEpoch(epochNonce).totalDepositAmount == 0, "no deposits should be made";
    require shareBurnAmount != 0, "shares should be burned";
    require shareBurnAmount <= max_uint256 / getSharePrecision(), "withdraw calculation should not overflow";
    require shareBurnAmount <= max_uint256 / 2, "withdraw amount should fit int256";
    require totalShares >= shareBurnAmount, "total shares subtraction should not underflow";

    /// @dev local-strategy + adapter conditions
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require adapter != currentContract, "adapter should not be the vault";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    uint256 adapterTVLBefore = adapter.getTVL();
    require adapterTVLBefore < shareBurnAmount, "adapter should return less than the requested amount";

    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    require adapterBalanceBefore >= adapterTVLBefore, "adapter asset balance should cover the amount out";
    require vaultBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_WithdrawFromStrategySuccess_EventCount == 0;
    require ghost_EpochClaimable_EventCount == 0;
    require ghost_EpochOpen_EventCount == 0;
    require ghost_totalShares_StoreCount == 0;

    closeEpoch@withrevert(e, tvl);

    assert !lastReverted;
    assert getTotalShares() == totalShares - shareBurnAmount;
    assert getEpoch(epochNonce).status == Types.EpochStatus.CLAIMABLE;
    assert getEpoch(epochNonce).totalWithdrawClaimAmount == adapterTVLBefore;
    assert getEpoch(epochNonce).remainingWithdrawClaimAmount == adapterTVLBefore;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore + adapterTVLBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore - adapterTVLBefore;
    assert adapter.getTVL() == 0;
    assert ghost_WithdrawFromStrategySuccess_EventCount == 1;
    assert ghost_WithdrawFromStrategySuccess_Param_epochNonce == epochNonce;
    assert ghost_WithdrawFromStrategySuccess_Param_amount == adapterTVLBefore;
    assert ghost_EpochClaimable_EventCount == 1;
    assert ghost_EpochClaimable_Param_epochNonce == epochNonce;
    assert getEpochNonce() == epochNonce + 1;
    assert ghost_EpochOpen_EventCount == 1;
    assert ghost_EpochOpen_Param_epochNonce == epochNonce + 1;
}

/// @notice Closing a net-withdraw epoch with a local strategy reverts atomically (no recovery) when
///         the adapter withdraw fails, since closeEpoch calls _executeWithdraw with revertOnFailure=true
rule closeEpoch_WITHDRAW_FROM_LOCAL_STRATEGY_RevertWhen_WithdrawFails() {
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
    require getSharePrecision() != 0, "no divide by 0";
    require totalShares != 0, "shares should be outstanding";
    require totalShares <= max_uint256 / getSharePrecision(), "gross price per share should not overflow";
    require tvl == totalShares, "tvl should equal total shares for a clean price-per-share";
    require getPerformanceFeeHighWaterMark() >= getSharePrecision(), "performance fee should not be collected";
    require getEpoch(epochNonce).totalDepositAmount == 0, "no deposits should be made";
    require shareBurnAmount != 0, "shares should be burned";
    require shareBurnAmount <= max_uint256 / getSharePrecision(), "withdraw calculation should not overflow";
    require shareBurnAmount <= max_uint256 / 2, "withdraw amount should fit int256";
    require totalShares >= shareBurnAmount, "total shares subtraction should not underflow";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";

    /// @dev revert condition being verified
    require adapter.withdrawReverts(), "adapter withdraw should revert";

    storage before = lastStorage;

    closeEpoch@withrevert(e, tvl);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Closing a net-withdraw epoch with a remote strategy marks the epoch executing and emits
///         EpochExecuting, without performing any external strategy action (CRE picks this up)
rule closeEpoch_WAIT_FOR_REMOTE_WITHDRAW_Success() {
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

    /// @dev success conditions being verified - mirrors closeEpoch_Success_WhenRemoteNetWithdraw
    require getSharePrecision() != 0, "no divide by 0";
    require totalShares != 0, "shares should be outstanding";
    require totalShares <= max_uint256 / getSharePrecision(), "gross price per share should not overflow";
    require tvl == totalShares, "tvl should equal total shares for a clean price-per-share";
    require getPerformanceFeeHighWaterMark() >= getSharePrecision(), "performance fee should not be collected";
    require getEpoch(epochNonce).totalDepositAmount == 0, "no deposits should be made";
    require shareBurnAmount != 0, "shares should be burned";
    require shareBurnAmount <= max_uint256 / getSharePrecision(), "withdraw calculation should not overflow";
    require shareBurnAmount <= max_uint256 / 2, "withdraw amount should fit int256";
    require totalShares >= shareBurnAmount, "total shares subtraction should not underflow";
    require getActiveProtocolAdapter() == 0, "no active adapter on this chain (remote strategy)";

    /// @dev set ghost starting values
    require ghost_EpochExecuting_EventCount == 0;
    require ghost_EpochOpen_EventCount == 0;
    require ghost_epoch_status_StoreCount == 0;
    require ghost_totalShares_StoreCount == 0;

    closeEpoch@withrevert(e, tvl);

    assert !lastReverted;
    assert getTotalShares() == totalShares - shareBurnAmount;
    assert getEpoch(epochNonce).status == Types.EpochStatus.EXECUTING;
    assert ghost_EpochExecuting_EventCount == 1;
    assert ghost_EpochExecuting_Param_epochNonce == epochNonce;
    assert ghost_EpochExecuting_Param_amount == shareBurnAmount;
    assert getEpochNonce() == epochNonce + 1;
    assert ghost_EpochOpen_EventCount == 1;
    assert ghost_EpochOpen_Param_epochNonce == epochNonce + 1;
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

    storage before = lastStorage;

    completeRebalance@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
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

    storage before = lastStorage;

    completeRebalance@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Completing a rebalance reverts when any recovery operation is already pending
/// @dev Verifies that a pending recovery cannot be overwritten. This guard is ParentVault-level
///      (s_recoveryMode) and is not visible to ParentVaultRebalanceLib's own rules.
rule completeRebalance_RevertWhen_RecoveryAlreadyPending() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";

    /// @dev revert condition being verified
    require getRecoveryMode() != Types.RecoveryMode.NONE, "recovery should be pending";

    storage before = lastStorage;

    completeRebalance@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
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

    storage before = lastStorage;

    completeRebalance@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Completing a rebalance activates the pending strategy, increments the rebalance nonce,
///         and collects no management fee when no shares are outstanding
rule completeRebalance_Success_WhenNoManagementFeeShares() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().nonce < max_uint256, "rebalance nonce increment should not overflow";
    require getRebalance().lastRebalanceCompletedTimestamp <= e.block.timestamp,
        "management fee elapsed time should not underflow";

    uint256 rebalanceNonce = getRebalance().nonce;
    bytes32 pendingProtocolId = getRebalance().pendingStrategy.protocolId;
    uint64 pendingChainSelector = getRebalance().pendingStrategy.chainSelector;

    /// @dev success conditions being verified - mirrors finalizeRebalance_Success_WhenNoManagementFeeShares
    require getRebalance().state == Types.RebalanceState.REBALANCING, "rebalance should be in progress";
    require getTotalShares() == 0, "no management fee shares should be collected";

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
    assert ghost_RebalanceCompleted_EventCount == 1;
    assert ghost_RebalanceCompleted_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_RebalanceCompleted_Param_newProtocolId == pendingProtocolId;
    assert ghost_RebalanceCompleted_Param_newChainSelector == pendingChainSelector;
    assert ghost_ManagementFeeCollected_EventCount == 0;
}

/// @notice Completing a rebalance activates the pending strategy, increments the rebalance nonce,
///         and mints the management fee to the treasury when fee shares are nonzero
rule completeRebalance_Success_WhenManagementFeeSharesAreCollected() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(REBALANCE_OPERATOR_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.NONE, "recovery should not be pending";
    require getRebalance().nonce < max_uint256, "rebalance nonce increment should not overflow";
    require getRebalance().lastRebalanceCompletedTimestamp <= e.block.timestamp,
        "management fee elapsed time should not underflow";

    uint256 rebalanceNonce = getRebalance().nonce;
    bytes32 pendingProtocolId = getRebalance().pendingStrategy.protocolId;
    uint64 pendingChainSelector = getRebalance().pendingStrategy.chainSelector;
    uint256 totalShares = getTotalShares();
    address treasury = getTreasury();

    /// @dev success conditions being verified - mirrors
    ///      finalizeRebalance_Success_WhenManagementFeeSharesAreCollected
    require getRebalance().state == Types.RebalanceState.REBALANCING, "rebalance should be in progress";
    mathint elapsed = e.block.timestamp - getRebalance().lastRebalanceCompletedTimestamp;
    require elapsed <= YEAR(), "elapsed time should be capped";
    require elapsed != 0, "elapsed time should be nonzero";
    require totalShares <= max_uint256 / MANAGEMENT_FEE_BPS(),
        "total shares fee bps multiplication should not overflow";
    require totalShares * MANAGEMENT_FEE_BPS() <= max_uint256 / elapsed,
        "elapsed fee multiplication should not overflow";
    mathint denominator = BPS_DENOMINATOR() * YEAR();
    mathint numerator = totalShares * MANAGEMENT_FEE_BPS() * elapsed;
    require numerator <= max_uint256 - (denominator - 1), "ceil numerator addition should not overflow";
    mathint feeShares = (numerator + denominator - 1) / denominator;
    require feeShares != 0, "fee shares should be nonzero";
    require totalShares <= max_uint256 - feeShares, "total shares addition should not overflow";
    uint256 treasuryBalanceBefore = share.balanceOf(treasury);
    require treasuryBalanceBefore <= max_uint256 - feeShares, "treasury share balance should not overflow";
    require share.totalSupply() <= max_uint256 - feeShares, "share total supply should not overflow";

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
    assert to_mathint(getTotalShares()) == totalShares + feeShares;
    assert to_mathint(share.balanceOf(treasury)) == treasuryBalanceBefore + feeShares;
    assert ghost_RebalanceCompleted_EventCount == 1;
    assert ghost_RebalanceCompleted_Param_rebalanceNonce == rebalanceNonce;
    assert ghost_RebalanceCompleted_Param_newProtocolId == pendingProtocolId;
    assert ghost_RebalanceCompleted_Param_newChainSelector == pendingChainSelector;
    assert ghost_ManagementFeeCollected_EventCount == 1;
    assert ghost_ManagementFeeCollected_Param_rebalanceNonce == rebalanceNonce;
    assert to_mathint(ghost_ManagementFeeCollected_Param_feeShares) == feeShares;
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
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT,
        "rebalance deposit recovery should be pending";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";

    storage before = lastStorage;

    executeRecovery@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Executing recovery reverts when no recovery is pending
/// @dev Verifies that ParentVault's own top-level guard (distinct from, but consistent with,
///      _requireRebalanceDepositRecovery's own check inside _recoverFailedRebalanceDeposit) leaves
///      all vault state unchanged
rule executeRecovery_RevertWhen_NoPendingRecovery() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";

    /// @dev revert condition being verified
    require getRecoveryMode() == Types.RecoveryMode.NONE, "no recovery should be pending";

    storage before = lastStorage;

    executeRecovery@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Executing recovery reverts when the recovery redeposit has no active adapter to target
/// @dev Verifies that ParentVault's entry point propagates the internal recovery-redeposit revert
///      (exhaustively covered in isolation in BaseVault.spec via recoverFailedRebalanceDepositInternal)
///      instead of chaining into finalizeRebalance, leaving all vault state - including the
///      rebalance nonce and state - unchanged
rule executeRecovery_RevertWhen_NoActiveAdapter() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT,
        "rebalance deposit recovery should be pending";
    require !adapter.depositReverts(), "adapter deposit should not revert";

    /// @dev revert condition being verified
    require getActiveProtocolAdapter() == 0, "active adapter should not be set";

    storage before = lastStorage;

    executeRecovery@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Executing recovery reverts when the recovery redeposit into the active adapter fails
/// @dev Verifies that ParentVault's entry point propagates the internal recovery-redeposit revert
///      (exhaustively covered in isolation in BaseVault.spec via recoverFailedRebalanceDepositInternal)
///      instead of chaining into finalizeRebalance, leaving all vault state - including the
///      rebalance nonce and state - unchanged
rule executeRecovery_RevertWhen_DepositFails() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT,
        "rebalance deposit recovery should be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";

    /// @dev revert condition being verified
    require adapter.depositReverts(), "adapter deposit should revert";

    storage before = lastStorage;

    executeRecovery@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Executing recovery deposits the stored recovery amount into the active adapter, clears
///         the recovery, and finalizes the rebalance (activating the pending strategy)
rule executeRecovery_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    require getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT,
        "rebalance deposit recovery should be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.depositReverts(), "adapter deposit should not revert";
    require adapter != currentContract, "adapter should not be the vault";

    uint256 recoveryNonceBefore = getRebalanceDepositRecovery().rebalanceNonce;
    uint256 recoveryAmountBefore = getRebalanceDepositRecovery().amount;
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token and adapter arithmetic conditions
    require recoveryAmountBefore <= vaultBalanceBefore, "vault asset balance should cover the recovery amount";
    require adapterBalanceBefore <= max_uint256 - recoveryAmountBefore, "adapter asset balance should not overflow";
    require adapterTVLBefore <= max_uint256 - recoveryAmountBefore, "adapter TVL should not overflow";

    /// @dev finalizeRebalance conditions - mirrors completeRebalance_Success_WhenNoManagementFeeShares
    require getRebalance().nonce < max_uint256, "rebalance nonce increment should not overflow";
    require getRebalance().lastRebalanceCompletedTimestamp <= e.block.timestamp,
        "management fee elapsed time should not underflow";
    uint256 rebalanceNonce = getRebalance().nonce;
    bytes32 pendingProtocolId = getRebalance().pendingStrategy.protocolId;
    uint64 pendingChainSelector = getRebalance().pendingStrategy.chainSelector;
    require getRebalance().state == Types.RebalanceState.REBALANCING, "rebalance should be in progress";
    require getTotalShares() == 0, "no management fee shares should be collected"; // @review assumption. we should account for fee collection

    /// @dev set ghost starting values
    require ghost_RebalanceDepositRecoveryCleared_EventCount == 0;
    require ghost_RebalanceDepositSuccess_EventCount == 0;
    require ghost_RebalanceCompleted_EventCount == 0;
    require ghost_ManagementFeeCollected_EventCount == 0;

    executeRecovery@withrevert(e);

    assert !lastReverted;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore - recoveryAmountBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore + recoveryAmountBefore;
    assert adapter.getTVL() == adapterTVLBefore + recoveryAmountBefore;
    assert getRecoveryMode() == Types.RecoveryMode.NONE;
    assert getRebalanceDepositRecovery().rebalanceNonce == 0;
    assert getRebalanceDepositRecovery().amount == 0;
    assert getRebalanceDepositRecovery().createdAt == 0;
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

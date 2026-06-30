using MockAdapterRegistry as adapterRegistry;
using MockProtocolAdapter as adapter;
using MockInvalidProtocolAdapter as invalidAdapter;
using MockUSDC as asset;
using MockLINK as link;

/// Verification of BaseVault shared behavior
/// @author @contractlevel
/// @notice Run against both ParentVaultHarness and ChildVaultHarness via two confs.

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    /*//////////////////////////////////////////////////////////////
                        HARNESS INTERNAL WRAPPERS
    //////////////////////////////////////////////////////////////*/
    function clearRebalanceDepositRecovery() external envfree;
    function requireRebalanceDepositRecovery() external returns (Types.RebalanceDepositRecovery) envfree;
    function recoverFailedRebalanceDepositInternal() external returns (uint256, uint256);
    function storeRebalanceDepositRecovery(uint256, uint256) external;
    function executeDeposit(uint256, bool) external returns (bool);
    function executeWithdraw(uint256, bool) external returns (bool, uint256);
    function handleCCIPRebalance(uint256, bytes32, uint256) external returns (bool);
    function revertIfZeroAddress(address) external;
    function revertIfZeroAmount(uint256) external;
    function revertIfZeroChainSelector(uint64) external;
    function requireNoRecovery() external;
    function requireRecoveryMode(Types.RecoveryMode) external;
    function authorizeUpgrade(address) external;
    function initializeBaseVault(BaseVault.InitParams) external;

    /*//////////////////////////////////////////////////////////////
                        RECOVERY FIELD GETTERS (harness)
    //////////////////////////////////////////////////////////////*/
    function getRecoveryRebalanceNonce() external returns (uint256) envfree;
    function getRecoveryAmount() external returns (uint256) envfree;
    function getRecoveryCreatedAt() external returns (uint256) envfree;
    function reentrancyGuardEntered() external returns (bool) envfree;
    function isInitialized() external returns (bool) envfree;
    function isInitializing() external returns (bool) envfree;

    /*//////////////////////////////////////////////////////////////
                            ENVFREE GETTERS
    //////////////////////////////////////////////////////////////*/
    function asset.balanceOf(address) external returns (uint256) envfree;
    function link.balanceOf(address) external returns (uint256) envfree;
    function adapter.getTVL() external returns (uint256) envfree;
    function adapter.getVault() external returns (address) envfree;
    function invalidAdapter.getVault() external returns (address) envfree;
    function adapter.depositReverts() external returns (bool) envfree;
    function adapter.withdrawReverts() external returns (bool) envfree;
    function adapter.setTVL(uint256) external;
    function hasRole(bytes32, address) external returns (bool) envfree;
    function paused() external returns (bool) envfree;
    function owner() external returns (address) envfree;
    function defaultAdmin() external returns (address) envfree;
    function getTVL() external returns (uint256) envfree;
    function supportsInterface(bytes4) external returns (bool) envfree;

    function getLink() external returns (address) envfree;
    function getAsset() external returns (address) envfree;
    function getAssetPrecision() external returns (uint256) envfree;
    function getThisChainSelector() external returns (uint64) envfree;
    function getAdapterRegistry() external returns (address) envfree;
    function getRouter() external returns (address) envfree;

    function getCrosschainVault(uint64) external returns (address) envfree;
    function getCcipGasLimit(uint64) external returns (uint256) envfree;
    function getDefaultCcipGasLimit() external returns (uint256) envfree;
    function getEmergencyReceiver() external returns (address) envfree;
    function getPausedAt() external returns (uint256) envfree;
    function getActiveProtocolAdapter() external returns (address) envfree;
    function getRecoveryMode() external returns (Types.RecoveryMode) envfree;

    /*//////////////////////////////////////////////////////////////
                      ROLE CONSTANTS (envfree via HelperHarness)
    //////////////////////////////////////////////////////////////*/
    function PAUSER_ROLE() external returns (bytes32) envfree;
    function UNPAUSER_ROLE() external returns (bytes32) envfree;
    function CONFIG_OPERATOR_ROLE() external returns (bytes32) envfree;
    function LINK_OPERATOR_ROLE() external returns (bytes32) envfree;
    function DONATE_OPERATOR_ROLE() external returns (bytes32) envfree;
    function EMERGENCY_DRAINER_ROLE() external returns (bytes32) envfree;
    function UPGRADER_ROLE() external returns (bytes32) envfree;

    /// @dev HelperHarness bytes32→* conversion used in LOG hooks
    function bytes32ToAddress(bytes32) external returns (address) envfree;
    function bytes32ToUint256(bytes32) external returns (uint256) envfree;
    function bytes32ToUint64(bytes32) external returns (uint64) envfree;

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

    function _.proxiableUUID() external => DISPATCHER(true);

    function _.decimals() external => DISPATCHER(true);
}

/*//////////////////////////////////////////////////////////////
                         DEFINITIONS
//////////////////////////////////////////////////////////////*/
definition PausedEvent() returns bytes32 =
// keccak256("Paused(address)")
    to_bytes32(0x62e78cea01bee320cd4e420270b5ea74000d11b0c9f74754ebdbfc544b05a258);

definition UnpausedEvent() returns bytes32 =
// keccak256("Unpaused(address)")
    to_bytes32(0x5db9ee0a495bf2e6ff9c91a7834c1ba4fdd244a5e8aa4e537bd38aeae4b073aa);

definition CrosschainVaultSetEvent() returns bytes32 =
// keccak256("CrosschainVaultSet(uint64,address)")
    to_bytes32(0x3dccebf0a32bc354f5dd3a785d9e2fc60792658c98848621290182785297b308);

definition CcipGasLimitSetEvent() returns bytes32 =
// keccak256("CcipGasLimitSet(uint64,uint256)")
    to_bytes32(0x390168a45e17c8f0ae322f9da9c220ea70ec5979bab8a6e0bec54f426ba2d390);

definition DefaultCcipGasLimitSetEvent() returns bytes32 =
// keccak256("DefaultCcipGasLimitSet(uint256)")
    to_bytes32(0xa28a825dc81451cace7e1074e39ddef702d1f349df63ca5fb8ed608cdc36f8ce);

definition EmergencyReceiverSetEvent() returns bytes32 =
// keccak256("EmergencyReceiverSet(address)")
    to_bytes32(0x6593318d596caeffa78d1e99d1438920e5fe28734e4cd9eb3004cfd281600b5a);

definition LinkWithdrawnEvent() returns bytes32 =
// keccak256("LinkWithdrawn(address,uint256)")
    to_bytes32(0xcb1436249a1dd8cf93362c28d79a4e20dc54398b6c49e30316e8396e72a584b0);

definition DonationEvent() returns bytes32 =
// keccak256("Donation(address,uint256)")
    to_bytes32(0x5d8bc849764969eb1bcc6d0a2f55999d0167c1ccec240a4f39cf664ca9c4148e);

definition EmergencyDrainExecutedEvent() returns bytes32 =
// keccak256("EmergencyDrainExecuted(address,uint256)")
    to_bytes32(0x517a6dbf5feae7fb9be64537a8c6dd21b71279ae57631e471cf6667919ec971a);

definition ActiveProtocolAdapterSetEvent() returns bytes32 =
// keccak256("ActiveProtocolAdapterSet(bytes32,address)")
    to_bytes32(0xf3628f0443ba881ea4c9543ca1d28250e78f2e019fffe8a8e722378625dcf598);

definition ActiveProtocolAdapterClearedEvent() returns bytes32 =
// keccak256("ActiveProtocolAdapterCleared(address)")
    to_bytes32(0x965689b74a63affbd22afb2528d6f7c11a4d1d2850b0f0cc8f647992386bf04f);

definition RebalanceDepositRecoveryStoredEvent() returns bytes32 =
// keccak256("RebalanceDepositRecoveryStored(uint256,uint256)")
    to_bytes32(0x4bbae92bb9743ae03720831d3ae066b9d8f88479d38633dac2ca5e8109b83894);

definition RebalanceDepositRecoveryClearedEvent() returns bytes32 =
// keccak256("RebalanceDepositRecoveryCleared(uint256)")
    to_bytes32(0xfd0affe04f47c983df51f211349e202dc404654e6851f1ad16dc04aa5c683e6f);

definition DepositToStrategySuccessEvent() returns bytes32 =
// keccak256("DepositToStrategySuccess(uint256,uint256)")
    to_bytes32(0x822db7c313fcf6d7b9ea5da5e0e6f3d27317446731e4016faa07a1127bb0a1c4);

definition WithdrawFromStrategySuccessEvent() returns bytes32 =
// keccak256("WithdrawFromStrategySuccess(uint256,uint256)")
    to_bytes32(0xb38981e8f1428114c35ad63ef9ab14a90a34bc12cac0782d420baab4522a659f);

/// Deferred to ChildVault.spec — infrastructure only, no active rules here
definition RebalanceDepositSuccessEvent() returns bytes32 =
// keccak256("RebalanceDepositSuccess(uint256,uint256)")
    to_bytes32(0x2db49c393972e05db516ff3191339f00472c21c0c8a0dba6cdc7fdcc60cc0f7f);

definition RebalanceDepositFailureEvent() returns bytes32 =
// keccak256("RebalanceDepositFailure(uint256,uint256)")
    to_bytes32(0xaf33555f3c66bb0a023d6b759e182afe00eb0b37fa2bbb17ad7d1f7618eb0e7c);

definition RebalanceWithdrawSuccessEvent() returns bytes32 =
// keccak256("RebalanceWithdrawSuccess(uint256,uint256)")
    to_bytes32(0xbda9c2bb85185244245a5c12fdd1e1107c46dc54a6d54d015bccf78aec5a8668);

/// RecoveryMode enum values — match Solidity enum type for getRecoveryMode() comparisons
definition RECOVERY_NONE()              returns Types.RecoveryMode = Types.RecoveryMode.NONE;
definition RECOVERY_REBALANCE_DEPOSIT() returns Types.RecoveryMode = Types.RecoveryMode.REBALANCE_DEPOSIT;

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
/// ─── s_defaultCcipGasLimit ───────────────────────────────────
ghost mathint ghost_defaultCcipGasLimit_StoreCount { init_state axiom ghost_defaultCcipGasLimit_StoreCount == 0; }
ghost uint256  ghost_defaultCcipGasLimit_StoredValue { init_state axiom ghost_defaultCcipGasLimit_StoredValue == 0; }

/// ─── s_ccipGasLimits[chainSelector] ─────────────────────────
ghost mathint ghost_ccipGasLimits_StoreCount { init_state axiom ghost_ccipGasLimits_StoreCount == 0; }
ghost uint64   ghost_ccipGasLimits_StoredKey   { init_state axiom ghost_ccipGasLimits_StoredKey == 0; }
ghost uint256  ghost_ccipGasLimits_StoredValue { init_state axiom ghost_ccipGasLimits_StoredValue == 0; }

/// ─── s_crosschainVaults[chainSelector] ──────────────────────
ghost mathint ghost_crosschainVaults_StoreCount { init_state axiom ghost_crosschainVaults_StoreCount == 0; }
ghost uint64   ghost_crosschainVaults_StoredKey   { init_state axiom ghost_crosschainVaults_StoredKey == 0; }
ghost address  ghost_crosschainVaults_StoredValue { init_state axiom ghost_crosschainVaults_StoredValue == 0; }

/// ─── s_activeProtocolAdapter ─────────────────────────────────
ghost mathint ghost_activeProtocolAdapter_StoreCount { init_state axiom ghost_activeProtocolAdapter_StoreCount == 0; }
ghost address  ghost_activeProtocolAdapter_StoredValue { init_state axiom ghost_activeProtocolAdapter_StoredValue == 0; }

/// ─── s_pausedAt ──────────────────────────────────────────────
ghost mathint ghost_pausedAt_StoreCount { init_state axiom ghost_pausedAt_StoreCount == 0; }
ghost uint96   ghost_pausedAt_StoredValue { init_state axiom ghost_pausedAt_StoredValue == 0; }

/// ─── s_emergencyReceiver ─────────────────────────────────────
ghost mathint ghost_emergencyReceiver_StoreCount { init_state axiom ghost_emergencyReceiver_StoreCount == 0; }
ghost address  ghost_emergencyReceiver_StoredValue { init_state axiom ghost_emergencyReceiver_StoredValue == 0; }

/// ─── s_recoveryMode ──────────────────────────────────────────
ghost mathint           ghost_recoveryMode_StoreCount { init_state axiom ghost_recoveryMode_StoreCount == 0; }
ghost Types.RecoveryMode ghost_recoveryMode_StoredValue { init_state axiom ghost_recoveryMode_StoredValue == Types.RecoveryMode.NONE; }

/// ─── s_rebalanceDepositRecovery.rebalanceNonce ───────────────
ghost mathint ghost_rebalanceDepositRecovery_nonce_StoreCount { init_state axiom ghost_rebalanceDepositRecovery_nonce_StoreCount == 0; }
ghost uint256  ghost_rebalanceDepositRecovery_nonce_StoredValue { init_state axiom ghost_rebalanceDepositRecovery_nonce_StoredValue == 0; }

/// ─── s_rebalanceDepositRecovery.amount ───────────────────────
ghost mathint ghost_rebalanceDepositRecovery_amount_StoreCount { init_state axiom ghost_rebalanceDepositRecovery_amount_StoreCount == 0; }
ghost uint256  ghost_rebalanceDepositRecovery_amount_StoredValue { init_state axiom ghost_rebalanceDepositRecovery_amount_StoredValue == 0; }

/// ─── s_rebalanceDepositRecovery.createdAt ────────────────────
ghost mathint ghost_rebalanceDepositRecovery_createdAt_StoreCount { init_state axiom ghost_rebalanceDepositRecovery_createdAt_StoreCount == 0; }
ghost uint256  ghost_rebalanceDepositRecovery_createdAt_StoredValue { init_state axiom ghost_rebalanceDepositRecovery_createdAt_StoredValue == 0; }

/// ─── Event: Paused ───────────────────────────────────────────
ghost mathint ghost_Paused_EventCount { init_state axiom ghost_Paused_EventCount == 0; }

/// ─── Event: Unpaused ─────────────────────────────────────────
ghost mathint ghost_Unpaused_EventCount { init_state axiom ghost_Unpaused_EventCount == 0; }

/// ─── Event: CrosschainVaultSet ───────────────────────────────
ghost mathint ghost_CrosschainVaultSet_EventCount { init_state axiom ghost_CrosschainVaultSet_EventCount == 0; }
ghost uint64  ghost_CrosschainVaultSet_Param_chainSelector { init_state axiom ghost_CrosschainVaultSet_Param_chainSelector == 0; }
ghost address ghost_CrosschainVaultSet_Param_vault { init_state axiom ghost_CrosschainVaultSet_Param_vault == 0; }

/// ─── Event: CcipGasLimitSet ──────────────────────────────────
ghost mathint ghost_CcipGasLimitSet_EventCount { init_state axiom ghost_CcipGasLimitSet_EventCount == 0; }
ghost uint64  ghost_CcipGasLimitSet_Param_chainSelector { init_state axiom ghost_CcipGasLimitSet_Param_chainSelector == 0; }
ghost uint256 ghost_CcipGasLimitSet_Param_gasLimit { init_state axiom ghost_CcipGasLimitSet_Param_gasLimit == 0; }

/// ─── Event: DefaultCcipGasLimitSet ───────────────────────────
ghost mathint ghost_DefaultCcipGasLimitSet_EventCount { init_state axiom ghost_DefaultCcipGasLimitSet_EventCount == 0; }
ghost uint256 ghost_DefaultCcipGasLimitSet_Param_gasLimit { init_state axiom ghost_DefaultCcipGasLimitSet_Param_gasLimit == 0; }

/// ─── Event: EmergencyReceiverSet ─────────────────────────────
ghost mathint ghost_EmergencyReceiverSet_EventCount { init_state axiom ghost_EmergencyReceiverSet_EventCount == 0; }
ghost address ghost_EmergencyReceiverSet_Param_receiver { init_state axiom ghost_EmergencyReceiverSet_Param_receiver == 0; }

/// ─── Event: LinkWithdrawn ────────────────────────────────────
ghost mathint ghost_LinkWithdrawn_EventCount { init_state axiom ghost_LinkWithdrawn_EventCount == 0; }
ghost address ghost_LinkWithdrawn_Param_operator { init_state axiom ghost_LinkWithdrawn_Param_operator == 0; }
ghost uint256 ghost_LinkWithdrawn_Param_amount { init_state axiom ghost_LinkWithdrawn_Param_amount == 0; }

/// ─── Event: Donation ─────────────────────────────────────────
ghost mathint ghost_Donation_EventCount { init_state axiom ghost_Donation_EventCount == 0; }
ghost address ghost_Donation_Param_donor { init_state axiom ghost_Donation_Param_donor == 0; }
ghost uint256 ghost_Donation_Param_amount { init_state axiom ghost_Donation_Param_amount == 0; }

/// ─── Event: EmergencyDrainExecuted ───────────────────────────
ghost mathint ghost_EmergencyDrainExecuted_EventCount { init_state axiom ghost_EmergencyDrainExecuted_EventCount == 0; }
ghost address ghost_EmergencyDrainExecuted_Param_receiver { init_state axiom ghost_EmergencyDrainExecuted_Param_receiver == 0; }
ghost uint256 ghost_EmergencyDrainExecuted_Param_amount { init_state axiom ghost_EmergencyDrainExecuted_Param_amount == 0; }

/// ─── Event: ActiveProtocolAdapterSet ─────────────────────────
ghost mathint ghost_ActiveProtocolAdapterSet_EventCount { init_state axiom ghost_ActiveProtocolAdapterSet_EventCount == 0; }
ghost bytes32 ghost_ActiveProtocolAdapterSet_Param_protocolId { init_state axiom ghost_ActiveProtocolAdapterSet_Param_protocolId == to_bytes32(0); }
ghost address ghost_ActiveProtocolAdapterSet_Param_adapter { init_state axiom ghost_ActiveProtocolAdapterSet_Param_adapter == 0; }

/// ─── Event: ActiveProtocolAdapterCleared ─────────────────────
ghost mathint ghost_ActiveProtocolAdapterCleared_EventCount { init_state axiom ghost_ActiveProtocolAdapterCleared_EventCount == 0; }
ghost address ghost_ActiveProtocolAdapterCleared_Param_adapter { init_state axiom ghost_ActiveProtocolAdapterCleared_Param_adapter == 0; }

/// ─── Event: RebalanceDepositRecoveryStored ───────────────────
ghost mathint ghost_RebalanceDepositRecoveryStored_EventCount { init_state axiom ghost_RebalanceDepositRecoveryStored_EventCount == 0; }
ghost uint256 ghost_RebalanceDepositRecoveryStored_Param_nonce { init_state axiom ghost_RebalanceDepositRecoveryStored_Param_nonce == 0; }
ghost uint256 ghost_RebalanceDepositRecoveryStored_Param_amount { init_state axiom ghost_RebalanceDepositRecoveryStored_Param_amount == 0; }

/// ─── Event: RebalanceDepositRecoveryCleared ──────────────────
ghost mathint ghost_RebalanceDepositRecoveryCleared_EventCount { init_state axiom ghost_RebalanceDepositRecoveryCleared_EventCount == 0; }
ghost uint256 ghost_RebalanceDepositRecoveryCleared_Param_nonce { init_state axiom ghost_RebalanceDepositRecoveryCleared_Param_nonce == 0; }

/// ─── Event: DepositToStrategySuccess ─────────────────────────
ghost mathint ghost_DepositToStrategySuccess_EventCount { init_state axiom ghost_DepositToStrategySuccess_EventCount == 0; }
ghost uint256 ghost_DepositToStrategySuccess_Param_epochNonce { init_state axiom ghost_DepositToStrategySuccess_Param_epochNonce == 0; }
ghost uint256 ghost_DepositToStrategySuccess_Param_amount { init_state axiom ghost_DepositToStrategySuccess_Param_amount == 0; }

/// ─── Event: WithdrawFromStrategySuccess ──────────────────────
ghost mathint ghost_WithdrawFromStrategySuccess_EventCount { init_state axiom ghost_WithdrawFromStrategySuccess_EventCount == 0; }
ghost uint256 ghost_WithdrawFromStrategySuccess_Param_epochNonce { init_state axiom ghost_WithdrawFromStrategySuccess_Param_epochNonce == 0; }

/// ─── Event: RebalanceDepositSuccess events ────────────────────────────────
ghost mathint ghost_RebalanceDepositSuccess_EventCount { init_state axiom ghost_RebalanceDepositSuccess_EventCount == 0; }
ghost uint256 ghost_RebalanceDepositSuccess_Param_nonce { init_state axiom ghost_RebalanceDepositSuccess_Param_nonce == 0; }
ghost uint256 ghost_RebalanceDepositSuccess_Param_amount { init_state axiom ghost_RebalanceDepositSuccess_Param_amount == 0; }

/// ─── Event: RebalanceDepositFailure events ────────────────────────────────
ghost mathint ghost_RebalanceDepositFailure_EventCount { init_state axiom ghost_RebalanceDepositFailure_EventCount == 0; }
ghost uint256 ghost_RebalanceDepositFailure_Param_nonce { init_state axiom ghost_RebalanceDepositFailure_Param_nonce == 0; }
ghost uint256 ghost_RebalanceDepositFailure_Param_amount { init_state axiom ghost_RebalanceDepositFailure_Param_amount == 0; }

/// ─── Event: RebalanceWithdrawSuccess ─────────────────────────
ghost mathint ghost_RebalanceWithdrawSuccess_EventCount { init_state axiom ghost_RebalanceWithdrawSuccess_EventCount == 0; }

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/
/// ─── Storage Sstore hooks (ERC-7201 BaseVault namespace) ─────

hook Sstore currentContract.ext_yieldcoin_storage_BaseVault.s_defaultCcipGasLimit uint256 newValue {
    ghost_defaultCcipGasLimit_StoreCount = ghost_defaultCcipGasLimit_StoreCount + 1;
    ghost_defaultCcipGasLimit_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_BaseVault.s_ccipGasLimits[KEY uint64 k] uint256 newValue {
    ghost_ccipGasLimits_StoreCount = ghost_ccipGasLimits_StoreCount + 1;
    ghost_ccipGasLimits_StoredValue = newValue;
    ghost_ccipGasLimits_StoredKey = k;
}

hook Sstore currentContract.ext_yieldcoin_storage_BaseVault.s_crosschainVaults[KEY uint64 k] address newValue {
    ghost_crosschainVaults_StoreCount = ghost_crosschainVaults_StoreCount + 1;
    ghost_crosschainVaults_StoredValue = newValue;
    ghost_crosschainVaults_StoredKey = k;
}

hook Sstore currentContract.ext_yieldcoin_storage_BaseVault.s_activeProtocolAdapter address newValue {
    ghost_activeProtocolAdapter_StoreCount = ghost_activeProtocolAdapter_StoreCount + 1;
    ghost_activeProtocolAdapter_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_BaseVault.s_pausedAt uint96 newValue {
    ghost_pausedAt_StoreCount = ghost_pausedAt_StoreCount + 1;
    ghost_pausedAt_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_BaseVault.s_emergencyReceiver address newValue {
    ghost_emergencyReceiver_StoreCount = ghost_emergencyReceiver_StoreCount + 1;
    ghost_emergencyReceiver_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_BaseVault.s_recoveryMode Types.RecoveryMode newValue {
    ghost_recoveryMode_StoreCount = ghost_recoveryMode_StoreCount + 1;
    ghost_recoveryMode_StoredValue = newValue;
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

/// ─── LOG hooks ───────────────────────────────────────────────

hook LOG1(uint offset, uint length, bytes32 t0) {
    if (t0 == PausedEvent()) {
        ghost_Paused_EventCount = ghost_Paused_EventCount + 1;
    }
    if (t0 == UnpausedEvent()) {
        ghost_Unpaused_EventCount = ghost_Unpaused_EventCount + 1;
    }
}

/// LOG2 — topic0 + 1 indexed param
hook LOG2(uint offset, uint length, bytes32 t0, bytes32 t1) {
    if (t0 == DefaultCcipGasLimitSetEvent()) {
        ghost_DefaultCcipGasLimitSet_EventCount = ghost_DefaultCcipGasLimitSet_EventCount + 1;
        ghost_DefaultCcipGasLimitSet_Param_gasLimit = bytes32ToUint256(t1);
    }
    if (t0 == EmergencyReceiverSetEvent()) {
        ghost_EmergencyReceiverSet_EventCount = ghost_EmergencyReceiverSet_EventCount + 1;
        ghost_EmergencyReceiverSet_Param_receiver = bytes32ToAddress(t1);
    }
    if (t0 == ActiveProtocolAdapterClearedEvent()) {
        ghost_ActiveProtocolAdapterCleared_EventCount = ghost_ActiveProtocolAdapterCleared_EventCount + 1;
        ghost_ActiveProtocolAdapterCleared_Param_adapter = bytes32ToAddress(t1);
    }
    if (t0 == RebalanceDepositRecoveryClearedEvent()) {
        ghost_RebalanceDepositRecoveryCleared_EventCount = ghost_RebalanceDepositRecoveryCleared_EventCount + 1;
        ghost_RebalanceDepositRecoveryCleared_Param_nonce = bytes32ToUint256(t1);
    }
}

/// LOG3 — topic0 + 2 indexed params
hook LOG3(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2) {
    if (t0 == CrosschainVaultSetEvent()) {
        ghost_CrosschainVaultSet_EventCount = ghost_CrosschainVaultSet_EventCount + 1;
        ghost_CrosschainVaultSet_Param_chainSelector = bytes32ToUint64(t1);
        ghost_CrosschainVaultSet_Param_vault = bytes32ToAddress(t2);
    }
    if (t0 == CcipGasLimitSetEvent()) {
        ghost_CcipGasLimitSet_EventCount = ghost_CcipGasLimitSet_EventCount + 1;
        ghost_CcipGasLimitSet_Param_chainSelector = bytes32ToUint64(t1);
        ghost_CcipGasLimitSet_Param_gasLimit = bytes32ToUint256(t2);
    }
    if (t0 == LinkWithdrawnEvent()) {
        ghost_LinkWithdrawn_EventCount = ghost_LinkWithdrawn_EventCount + 1;
        ghost_LinkWithdrawn_Param_operator = bytes32ToAddress(t1);
        ghost_LinkWithdrawn_Param_amount = bytes32ToUint256(t2);
    }
    if (t0 == DonationEvent()) {
        ghost_Donation_EventCount = ghost_Donation_EventCount + 1;
        ghost_Donation_Param_donor = bytes32ToAddress(t1);
        ghost_Donation_Param_amount = bytes32ToUint256(t2);
    }
    if (t0 == EmergencyDrainExecutedEvent()) {
        ghost_EmergencyDrainExecuted_EventCount = ghost_EmergencyDrainExecuted_EventCount + 1;
        ghost_EmergencyDrainExecuted_Param_receiver = bytes32ToAddress(t1);
        ghost_EmergencyDrainExecuted_Param_amount = bytes32ToUint256(t2);
    }
    if (t0 == ActiveProtocolAdapterSetEvent()) {
        ghost_ActiveProtocolAdapterSet_EventCount = ghost_ActiveProtocolAdapterSet_EventCount + 1;
        ghost_ActiveProtocolAdapterSet_Param_protocolId = t1;
        ghost_ActiveProtocolAdapterSet_Param_adapter = bytes32ToAddress(t2);
    }
    if (t0 == RebalanceDepositRecoveryStoredEvent()) {
        ghost_RebalanceDepositRecoveryStored_EventCount = ghost_RebalanceDepositRecoveryStored_EventCount + 1;
        ghost_RebalanceDepositRecoveryStored_Param_nonce = bytes32ToUint256(t1);
        ghost_RebalanceDepositRecoveryStored_Param_amount = bytes32ToUint256(t2);
    }
    if (t0 == DepositToStrategySuccessEvent()) {
        ghost_DepositToStrategySuccess_EventCount = ghost_DepositToStrategySuccess_EventCount + 1;
        ghost_DepositToStrategySuccess_Param_epochNonce = bytes32ToUint256(t1);
        ghost_DepositToStrategySuccess_Param_amount = bytes32ToUint256(t2);
    }
    if (t0 == WithdrawFromStrategySuccessEvent()) {
        ghost_WithdrawFromStrategySuccess_EventCount = ghost_WithdrawFromStrategySuccess_EventCount + 1;
        ghost_WithdrawFromStrategySuccess_Param_epochNonce = bytes32ToUint256(t1);
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
    if (t0 == RebalanceWithdrawSuccessEvent()) {
        ghost_RebalanceWithdrawSuccess_EventCount = ghost_RebalanceWithdrawSuccess_EventCount + 1;
    }
}

/*//////////////////////////////////////////////////////////////
                           INVARIANTS
//////////////////////////////////////////////////////////////*/
/// @dev filtered: upgradeToAndCall to stop delegatecall havocing immutable state
invariant noZeroChainSelector()
    currentContract.i_thisChainSelector != 0
    filtered { f -> f.selector != sig:upgradeToAndCall(address,bytes).selector }

/// @dev filtered: upgradeToAndCall to stop delegatecall havocing immutable state
invariant noZeroAssetPrecision(env e)
    asset.decimals(e) > 0 => currentContract.i_assetPrecision != 0
    filtered { f -> f.selector != sig:upgradeToAndCall(address,bytes).selector }

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/

/// ─────────────────── CONSTRUCTOR IMMUTABLES ──────────────────

rule constructor_getLink() {
    assert getLink() != 0;
}

rule constructor_getAsset() {
    assert getAsset() != 0;
}

rule constructor_getAdapterRegistry() {
    assert getAdapterRegistry() != 0;
}

rule constructor_getRouter() {
    assert getRouter() != 0;
}

/// ─────────────────── INITIALIZE BASE VAULT ───────────────────

/// @notice BaseVault initialization reverts when the default admin is the zero address
/// @dev Verifies that initialization is rolled back and mutable BaseVault configuration remains unchanged
rule initializeBaseVault_RevertWhen_DefaultAdminIsZeroAddress() {
    env e;
    BaseVault.InitParams params;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !isInitialized(), "contract should not be initialized";
    require !isInitializing(), "contract should not be initializing";
    require params.pauser != 0, "pauser should not be zero";
    require params.unpauser != 0, "unpauser should not be zero";
    require params.configOperator != 0, "config operator should not be zero";
    require params.emergencyReceiver != 0, "emergency receiver should not be zero";
    require params.upgrader != 0, "upgrader should not be zero";
    require params.initialDefaultCcipGasLimit != 0, "default CCIP gas limit should not be zero";
    require defaultAdmin() == 0, "default admin should not be initialized";

    /// @dev revert condition being verified
    require params.defaultAdmin == 0, "default admin should be zero";

    storage before = lastStorage;

    initializeBaseVault@withrevert(e, params);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice BaseVault initialization reverts when the pauser is the zero address
/// @dev Verifies that initialization is rolled back and mutable BaseVault configuration remains unchanged
rule initializeBaseVault_RevertWhen_PauserIsZeroAddress() {
    env e;
    BaseVault.InitParams params;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !isInitialized(), "contract should not be initialized";
    require !isInitializing(), "contract should not be initializing";
    require params.defaultAdmin != 0, "default admin should not be zero";
    require params.unpauser != 0, "unpauser should not be zero";
    require params.configOperator != 0, "config operator should not be zero";
    require params.emergencyReceiver != 0, "emergency receiver should not be zero";
    require params.upgrader != 0, "upgrader should not be zero";
    require params.initialDefaultCcipGasLimit != 0, "default CCIP gas limit should not be zero";
    require defaultAdmin() == 0, "default admin should not be initialized";

    /// @dev revert condition being verified
    require params.pauser == 0, "pauser should be zero";

    storage before = lastStorage;

    initializeBaseVault@withrevert(e, params);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice BaseVault initialization reverts when the unpauser is the zero address
/// @dev Verifies that initialization is rolled back and mutable BaseVault configuration remains unchanged
rule initializeBaseVault_RevertWhen_UnpauserIsZeroAddress() {
    env e;
    BaseVault.InitParams params;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !isInitialized(), "contract should not be initialized";
    require !isInitializing(), "contract should not be initializing";
    require params.defaultAdmin != 0, "default admin should not be zero";
    require params.pauser != 0, "pauser should not be zero";
    require params.configOperator != 0, "config operator should not be zero";
    require params.emergencyReceiver != 0, "emergency receiver should not be zero";
    require params.upgrader != 0, "upgrader should not be zero";
    require params.initialDefaultCcipGasLimit != 0, "default CCIP gas limit should not be zero";
    require defaultAdmin() == 0, "default admin should not be initialized";

    /// @dev revert condition being verified
    require params.unpauser == 0, "unpauser should be zero";

    storage before = lastStorage;

    initializeBaseVault@withrevert(e, params);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice BaseVault initialization reverts when the config operator is the zero address
/// @dev Verifies that initialization is rolled back and mutable BaseVault configuration remains unchanged
rule initializeBaseVault_RevertWhen_ConfigOperatorIsZeroAddress() {
    env e;
    BaseVault.InitParams params;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !isInitialized(), "contract should not be initialized";
    require !isInitializing(), "contract should not be initializing";
    require params.defaultAdmin != 0, "default admin should not be zero";
    require params.pauser != 0, "pauser should not be zero";
    require params.unpauser != 0, "unpauser should not be zero";
    require params.emergencyReceiver != 0, "emergency receiver should not be zero";
    require params.upgrader != 0, "upgrader should not be zero";
    require params.initialDefaultCcipGasLimit != 0, "default CCIP gas limit should not be zero";
    require defaultAdmin() == 0, "default admin should not be initialized";

    /// @dev revert condition being verified
    require params.configOperator == 0, "config operator should be zero";

    storage before = lastStorage;

    initializeBaseVault@withrevert(e, params);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice BaseVault initialization reverts when the emergency receiver is the zero address
/// @dev Verifies that initialization is rolled back and mutable BaseVault configuration remains unchanged
rule initializeBaseVault_RevertWhen_EmergencyReceiverIsZeroAddress() {
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
    require params.emergencyReceiver == 0, "emergency receiver should be zero";

    storage before = lastStorage;

    initializeBaseVault@withrevert(e, params);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice BaseVault initialization reverts when the upgrader is the zero address
/// @dev Verifies that initialization is rolled back and mutable BaseVault configuration remains unchanged
rule initializeBaseVault_RevertWhen_UpgraderIsZeroAddress() {
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
    require params.emergencyReceiver != 0, "emergency receiver should not be zero";
    require params.initialDefaultCcipGasLimit != 0, "default CCIP gas limit should not be zero";
    require defaultAdmin() == 0, "default admin should not be initialized";

    /// @dev revert condition being verified
    require params.upgrader == 0, "upgrader should be zero";

    storage before = lastStorage;

    initializeBaseVault@withrevert(e, params);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice BaseVault initialization reverts when the initial default CCIP gas limit is zero
/// @dev Verifies that initialization is rolled back and mutable BaseVault configuration remains unchanged
rule initializeBaseVault_RevertWhen_InitialDefaultCcipGasLimitIsZero() {
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
    require params.emergencyReceiver != 0, "emergency receiver should not be zero";
    require params.upgrader != 0, "upgrader should not be zero";
    require defaultAdmin() == 0, "default admin should not be initialized";

    /// @dev revert condition being verified
    require params.initialDefaultCcipGasLimit == 0, "default CCIP gas limit should be zero";

    storage before = lastStorage;

    initializeBaseVault@withrevert(e, params);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice BaseVault initialization reverts when the contract has already been initialized
/// @dev Verifies that repeated initialization leaves all vault state unchanged
rule initializeBaseVault_RevertWhen_AlreadyInitialized() {
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

    initializeBaseVault@withrevert(e, params);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice BaseVault initialization sets mutable configuration and grants all initial roles
/// @dev Verifies initialization state, role assignments, storage writes, and unpaused recovery-free defaults
rule initializeBaseVault_Success() {
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
    require params.emergencyReceiver != 0, "emergency receiver should not be zero";
    require params.upgrader != 0, "upgrader should not be zero";
    require params.initialDefaultCcipGasLimit != 0, "default CCIP gas limit should not be zero";
    require defaultAdmin() == 0, "default admin should not be initialized";
    require getEmergencyReceiver() == 0, "emergency receiver should not be initialized";
    require getDefaultCcipGasLimit() == 0, "default CCIP gas limit should not be initialized";
    require !paused(), "vault should not be paused";
    require getRecoveryMode() == RECOVERY_NONE(), "recovery should not be pending";
    require !hasRole(to_bytes32(0), params.defaultAdmin), "default admin role should not be granted";
    require !hasRole(PAUSER_ROLE(), params.pauser), "pauser role should not be granted";
    require !hasRole(UNPAUSER_ROLE(), params.unpauser), "unpauser role should not be granted";
    require !hasRole(CONFIG_OPERATOR_ROLE(), params.configOperator), "config operator role should not be granted";
    require !hasRole(UPGRADER_ROLE(), params.upgrader), "upgrader role should not be granted";

    /// @dev set ghost starting values
    require ghost_emergencyReceiver_StoreCount == 0;
    require ghost_defaultCcipGasLimit_StoreCount == 0;

    initializeBaseVault@withrevert(e, params);

    assert !lastReverted;
    assert isInitialized();
    assert !isInitializing();
    assert !paused();
    assert getRecoveryMode() == RECOVERY_NONE();
    assert getEmergencyReceiver() == params.emergencyReceiver;
    assert getDefaultCcipGasLimit() == params.initialDefaultCcipGasLimit;
    assert defaultAdmin() == params.defaultAdmin;
    assert hasRole(to_bytes32(0), params.defaultAdmin);
    assert hasRole(PAUSER_ROLE(), params.pauser);
    assert hasRole(UNPAUSER_ROLE(), params.unpauser);
    assert hasRole(CONFIG_OPERATOR_ROLE(), params.configOperator);
    assert hasRole(UPGRADER_ROLE(), params.upgrader);
    assert ghost_emergencyReceiver_StoreCount == 1;
    assert ghost_emergencyReceiver_StoredValue == params.emergencyReceiver;
    assert ghost_defaultCcipGasLimit_StoreCount == 1;
    assert ghost_defaultCcipGasLimit_StoredValue == params.initialDefaultCcipGasLimit;
}

/// ─────────────────── PAUSE ───────────────────────────────────

rule pause_RevertWhen_CallerDoesNotHavePAUSER_ROLE() {
    env e;
    
    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !paused(), "should not be paused";

    /// @dev revert condition being verified
    require !hasRole(PAUSER_ROLE(), e.msg.sender);

    /// @dev set ghost starting values
    require ghost_Paused_EventCount == 0;
    require ghost_pausedAt_StoreCount == 0;

    pause@withrevert(e);

    assert lastReverted;
    assert ghost_Paused_EventCount == 0;
    assert ghost_pausedAt_StoreCount == 0;
}

rule pause_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0;
    require hasRole(PAUSER_ROLE(), e.msg.sender);
    require !paused();

    /// @dev set ghost starting values
    require ghost_Paused_EventCount == 0;
    require ghost_pausedAt_StoreCount == 0;

    pause@withrevert(e);

    assert !lastReverted;
    assert paused();
    assert getPausedAt() == require_uint96(e.block.timestamp);
    assert ghost_Paused_EventCount == 1;
    assert ghost_pausedAt_StoreCount == 1;
    assert ghost_pausedAt_StoredValue == require_uint96(e.block.timestamp);
}

/// ─────────────────── UNPAUSE ─────────────────────────────────

rule unpause_RevertWhen_CallerDoesNotHaveUNPAUSER_ROLE() {
    env e;
    
    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require paused(), "should be paused";

    /// @dev revert condition being verified
    require !hasRole(UNPAUSER_ROLE(), e.msg.sender);

    /// @dev set ghost starting values
    require ghost_Unpaused_EventCount == 0;

    unpause@withrevert(e);

    assert lastReverted;
    assert ghost_Unpaused_EventCount == 0;
}

rule unpause_Success() {
    env e;
    
     /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require paused(), "should be paused";
    require hasRole(UNPAUSER_ROLE(), e.msg.sender);

    /// @dev set ghost starting values
    require ghost_Unpaused_EventCount == 0;
    require ghost_pausedAt_StoreCount == 0;

    unpause@withrevert(e);

    assert !lastReverted;
    assert !paused();
    assert getPausedAt() == 0;
    assert ghost_Unpaused_EventCount == 1;
    assert ghost_pausedAt_StoreCount == 1;
    assert ghost_pausedAt_StoredValue == 0;
}

/// ─────────────────── SET EMERGENCY RECEIVER ──────────────────

rule setEmergencyReceiver_RevertWhen_CallerDoesNotHaveCONFIG_OPERATOR_ROLE() {
    env e;
    address receiver;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require receiver != 0, "receiver should not be zero address";

    /// @dev revert condition being verified
    require !hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender);

    /// @dev set ghost starting values
    require ghost_EmergencyReceiverSet_EventCount == 0;
    require ghost_emergencyReceiver_StoreCount == 0;

    setEmergencyReceiver@withrevert(e, receiver);

    assert lastReverted;
    assert ghost_EmergencyReceiverSet_EventCount == 0;
    assert ghost_emergencyReceiver_StoreCount == 0;
}

rule setEmergencyReceiver_RevertWhen_ReceiverIsZeroAddress() {
    env e;
    address receiver;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender);

    /// @dev revert condition being verified
    require receiver == 0, "receiver should be zero address";

    /// @dev set ghost starting values
    require ghost_EmergencyReceiverSet_EventCount == 0;
    require ghost_emergencyReceiver_StoreCount == 0;

    setEmergencyReceiver@withrevert(e, receiver);

    assert lastReverted;
    assert ghost_EmergencyReceiverSet_EventCount == 0;
    assert ghost_emergencyReceiver_StoreCount == 0;
}

rule setEmergencyReceiver_Success() {
    env e;
    address receiver;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender);
    require receiver != 0, "receiver should not be zero address";

    /// @dev set ghost starting values
    require ghost_EmergencyReceiverSet_EventCount == 0;
    require ghost_emergencyReceiver_StoreCount == 0;

    setEmergencyReceiver@withrevert(e, receiver);

    assert !lastReverted;
    assert getEmergencyReceiver() == receiver;
    assert ghost_EmergencyReceiverSet_EventCount == 1;
    assert ghost_EmergencyReceiverSet_Param_receiver == receiver;
    assert ghost_emergencyReceiver_StoreCount == 1;
    assert ghost_emergencyReceiver_StoredValue == receiver;
}

/// ─────────────────── SET DEFAULT CCIP GAS LIMIT ──────────────

rule setDefaultCcipGasLimit_RevertWhen_CallerDoesNotHaveCONFIG_OPERATOR_ROLE() {
    env e;
    uint256 gasLimit;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require gasLimit != 0, "gas limit should not be zero";

    /// @dev revert condition being verified
    require !hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender);

    /// @dev set ghost starting values
    require ghost_DefaultCcipGasLimitSet_EventCount == 0;
    require ghost_defaultCcipGasLimit_StoreCount == 0;

    setDefaultCcipGasLimit@withrevert(e, gasLimit);

    assert lastReverted;
    assert ghost_DefaultCcipGasLimitSet_EventCount == 0;
    assert ghost_defaultCcipGasLimit_StoreCount == 0;
}

rule setDefaultCcipGasLimit_RevertWhen_GasLimitIsZero() {
    env e;
    uint256 gasLimit;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender);

    /// @dev revert condition being verified
    require gasLimit == 0, "gas limit should be zero";

    /// @dev set ghost starting values
    require ghost_DefaultCcipGasLimitSet_EventCount == 0;
    require ghost_defaultCcipGasLimit_StoreCount == 0;

    setDefaultCcipGasLimit@withrevert(e, gasLimit);

    assert lastReverted;
    assert ghost_DefaultCcipGasLimitSet_EventCount == 0;
    assert ghost_defaultCcipGasLimit_StoreCount == 0;
}

rule setDefaultCcipGasLimit_Success() {
    env e;
    uint256 gasLimit;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender);
    require gasLimit != 0, "gas limit should not be zero";

    /// @dev set ghost starting values
    require ghost_DefaultCcipGasLimitSet_EventCount == 0;
    require ghost_defaultCcipGasLimit_StoreCount == 0;

    setDefaultCcipGasLimit@withrevert(e, gasLimit);

    assert !lastReverted;
    assert getDefaultCcipGasLimit() == gasLimit;
    assert ghost_DefaultCcipGasLimitSet_EventCount == 1;
    assert ghost_DefaultCcipGasLimitSet_Param_gasLimit == gasLimit;
    assert ghost_defaultCcipGasLimit_StoreCount == 1;
    assert ghost_defaultCcipGasLimit_StoredValue == gasLimit;
}

/// ─────────────────── SET CCIP GAS LIMIT ──────────────────────

rule setCcipGasLimit_RevertWhen_CallerDoesNotHaveCONFIG_OPERATOR_ROLE() {
    env e;
    uint64 chainSelector;
    uint256 gasLimit;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require chainSelector != 0, "chain selector should not be zero";

    /// @dev revert condition being verified
    require !hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender);

    /// @dev set ghost starting values
    require ghost_CcipGasLimitSet_EventCount == 0;
    require ghost_ccipGasLimits_StoreCount == 0;

    setCcipGasLimit@withrevert(e, chainSelector, gasLimit);

    assert lastReverted;
    assert ghost_CcipGasLimitSet_EventCount == 0;
    assert ghost_ccipGasLimits_StoreCount == 0;
}

rule setCcipGasLimit_RevertWhen_ChainSelectorIsZero() {
    env e;
    uint64 chainSelector;
    uint256 gasLimit;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender);

    /// @dev revert condition being verified
    require chainSelector == 0, "chain selector should be zero";

    /// @dev set ghost starting values
    require ghost_CcipGasLimitSet_EventCount == 0;
    require ghost_ccipGasLimits_StoreCount == 0;

    setCcipGasLimit@withrevert(e, chainSelector, gasLimit);

    assert lastReverted;
    assert ghost_CcipGasLimitSet_EventCount == 0;
    assert ghost_ccipGasLimits_StoreCount == 0;
}

rule setCcipGasLimit_Success() {
    env e;
    uint64 chainSelector;
    /// gasLimit=0 is valid — clears the per-chain gas limit override
    uint256 gasLimit;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender);
    require chainSelector != 0, "chain selector should not be zero";

    /// @dev set ghost starting values
    require ghost_CcipGasLimitSet_EventCount == 0;
    require ghost_ccipGasLimits_StoreCount == 0;

    setCcipGasLimit@withrevert(e, chainSelector, gasLimit);

    assert !lastReverted;
    assert getCcipGasLimit(chainSelector) == gasLimit;
    assert ghost_CcipGasLimitSet_EventCount == 1;
    assert ghost_CcipGasLimitSet_Param_chainSelector == chainSelector;
    assert ghost_CcipGasLimitSet_Param_gasLimit == gasLimit;
    assert ghost_ccipGasLimits_StoreCount == 1;
    assert ghost_ccipGasLimits_StoredKey == chainSelector;
    assert ghost_ccipGasLimits_StoredValue == gasLimit;
}

/// ─────────────────── SET CROSSCHAIN VAULTS ───────────────────

rule setCrosschainVaults_RevertWhen_CallerDoesNotHaveCONFIG_OPERATOR_ROLE() {
    env e;
    uint64[] chainSelectors;
    address[] vaults;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require chainSelectors.length == 1, "chain selectors should contain one element";
    require vaults.length == 1, "vaults should contain one element";
    require chainSelectors[0] != 0, "chain selector should not be zero";
    require vaults[0] <= max_uint160, "vault should be a canonical address";

    /// @dev revert condition being verified
    require !hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender);

    /// @dev set ghost starting values
    require ghost_CrosschainVaultSet_EventCount == 0;
    require ghost_crosschainVaults_StoreCount == 0;

    setCrosschainVaults@withrevert(e, chainSelectors, vaults);

    assert lastReverted;
    assert ghost_CrosschainVaultSet_EventCount == 0;
    assert ghost_crosschainVaults_StoreCount == 0;
}

rule setCrosschainVaults_RevertWhen_ArrayLengthsDoNotMatch() {
    env e;
    uint64[] chainSelectors;
    address[] vaults;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender);
    require chainSelectors.length != 0, "chain selectors should not be empty";

    /// @dev revert condition being verified
    require chainSelectors.length != vaults.length, "array lengths should not match";

    /// @dev set ghost starting values
    require ghost_CrosschainVaultSet_EventCount == 0;
    require ghost_crosschainVaults_StoreCount == 0;

    setCrosschainVaults@withrevert(e, chainSelectors, vaults);

    assert lastReverted;
    assert ghost_CrosschainVaultSet_EventCount == 0;
    assert ghost_crosschainVaults_StoreCount == 0;
}

/// @notice Setting crosschain vaults reverts when the input arrays are empty
/// @dev Verifies that no crosschain vault is stored and no event is emitted
rule setCrosschainVaults_RevertWhen_InputIsEmpty() {
    env e;
    uint64[] chainSelectors;
    address[] vaults;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender);
    require chainSelectors.length == vaults.length, "array lengths should match";

    /// @dev revert condition being verified
    require chainSelectors.length == 0, "chain selectors should be empty";

    /// @dev set ghost starting values
    require ghost_CrosschainVaultSet_EventCount == 0;
    require ghost_crosschainVaults_StoreCount == 0;

    setCrosschainVaults@withrevert(e, chainSelectors, vaults);

    assert lastReverted;
    assert ghost_CrosschainVaultSet_EventCount == 0;
    assert ghost_crosschainVaults_StoreCount == 0;
}

rule setCrosschainVaults_RevertWhen_ChainSelectorIsZero() {
    env e;
    uint64[] chainSelectors;
    address[] vaults;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender);
    require chainSelectors.length == 1, "chain selectors should contain one element";
    require vaults.length == 1, "vaults should contain one element";
    require vaults[0] <= max_uint160, "vault should be a canonical address";

    /// @dev revert condition being verified
    require chainSelectors[0] == 0, "chain selector should be zero";

    /// @dev set ghost starting values
    require ghost_CrosschainVaultSet_EventCount == 0;
    require ghost_crosschainVaults_StoreCount == 0;

    setCrosschainVaults@withrevert(e, chainSelectors, vaults);

    assert lastReverted;
    assert ghost_CrosschainVaultSet_EventCount == 0;
    assert ghost_crosschainVaults_StoreCount == 0;
}

rule setCrosschainVaults_Success() {
    env e;
    uint64[] chainSelectors;
    /// vaults[0]=address(0) is valid — removes the crosschain vault entry
    address[] vaults;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender);
    require chainSelectors.length == 1, "chain selectors should contain one element";
    require vaults.length == 1, "vaults should contain one element";
    require chainSelectors[0] != 0, "chain selector should not be zero";
    require vaults[0] <= max_uint160, "vault should be a canonical address";

    /// @dev set ghost starting values
    require ghost_CrosschainVaultSet_EventCount == 0;
    require ghost_crosschainVaults_StoreCount == 0;

    setCrosschainVaults@withrevert(e, chainSelectors, vaults);

    assert !lastReverted;
    assert getCrosschainVault(chainSelectors[0]) == vaults[0];
    assert ghost_CrosschainVaultSet_EventCount == 1;
    assert ghost_CrosschainVaultSet_Param_chainSelector == chainSelectors[0];
    assert ghost_CrosschainVaultSet_Param_vault == vaults[0];
    assert ghost_crosschainVaults_StoreCount == 1;
    assert ghost_crosschainVaults_StoredKey == chainSelectors[0];
    assert ghost_crosschainVaults_StoredValue == vaults[0];
}

/// ─────────────────── WITHDRAW LINK ───────────────────────────

rule withdrawLink_RevertWhen_CallerDoesNotHaveLINK_OPERATOR_ROLE() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require amount != 0, "amount should not be zero";

    /// @dev revert condition being verified
    require !hasRole(LINK_OPERATOR_ROLE(), e.msg.sender);

    /// @dev set ghost starting values
    require ghost_LinkWithdrawn_EventCount == 0;

    withdrawLink@withrevert(e, amount);

    assert lastReverted;
    assert ghost_LinkWithdrawn_EventCount == 0;
}

rule withdrawLink_RevertWhen_AmountIsZero() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(LINK_OPERATOR_ROLE(), e.msg.sender);

    /// @dev revert condition being verified
    require amount == 0, "amount should be zero";

    /// @dev set ghost starting values
    require ghost_LinkWithdrawn_EventCount == 0;

    withdrawLink@withrevert(e, amount);

    assert lastReverted;
    assert ghost_LinkWithdrawn_EventCount == 0;
}

rule withdrawLink_Success() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(LINK_OPERATOR_ROLE(), e.msg.sender);
    require amount != 0, "amount should not be zero";
    require e.msg.sender != currentContract, "operator should not be the vault";

    /// @dev mock token arithmetic conditions
    uint256 vaultBalanceBefore = link.balanceOf(currentContract);
    uint256 operatorBalanceBefore = link.balanceOf(e.msg.sender);
    require amount <= vaultBalanceBefore, "vault LINK balance should not underflow";
    require operatorBalanceBefore <= max_uint256 - amount, "operator LINK balance should not overflow";

    /// @dev set ghost starting values
    require ghost_LinkWithdrawn_EventCount == 0;

    withdrawLink@withrevert(e, amount);

    assert !lastReverted;
    assert link.balanceOf(currentContract) == vaultBalanceBefore - amount;
    assert link.balanceOf(e.msg.sender) == operatorBalanceBefore + amount;
    assert ghost_LinkWithdrawn_EventCount == 1;
    assert ghost_LinkWithdrawn_Param_operator == e.msg.sender;
    assert ghost_LinkWithdrawn_Param_amount == amount;
}

/// ─────────────────── DONATE ──────────────────────────────────

rule donate_RevertWhen_CallerDoesNotHaveDONATE_OPERATOR_ROLE() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require amount != 0, "amount should not be zero";
    require getActiveProtocolAdapter() != 0, "active adapter should not be zero";
    require !adapter.depositReverts();
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";

    /// @dev revert condition being verified
    require !hasRole(DONATE_OPERATOR_ROLE(), e.msg.sender);

    /// @dev set ghost starting values
    require ghost_Donation_EventCount == 0;

    donate@withrevert(e, amount);

    assert lastReverted;
    assert ghost_Donation_EventCount == 0;
}

rule donate_RevertWhen_AmountIsZero() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(DONATE_OPERATOR_ROLE(), e.msg.sender);
    require getActiveProtocolAdapter() != 0, "active adapter should not be zero";
    require !adapter.depositReverts();
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";

    /// @dev revert condition being verified
    require amount == 0, "amount should be zero";

    /// @dev set ghost starting values
    require ghost_Donation_EventCount == 0;

    donate@withrevert(e, amount);

    assert lastReverted;
    assert ghost_Donation_EventCount == 0;
}

rule donate_RevertWhen_NoActiveAdapter() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(DONATE_OPERATOR_ROLE(), e.msg.sender);
    require amount != 0, "amount should not be zero";
    require !adapter.depositReverts();
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";

    /// @dev revert condition being verified
    require getActiveProtocolAdapter() == 0, "active adapter should be zero";

    /// @dev set ghost starting values
    require ghost_Donation_EventCount == 0;

    donate@withrevert(e, amount);

    assert lastReverted;
    assert ghost_Donation_EventCount == 0;
}

rule donate_RevertWhen_ReentrantCall() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(DONATE_OPERATOR_ROLE(), e.msg.sender);
    require amount != 0, "amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.depositReverts();

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";

    /// @dev set ghost starting values
    require ghost_Donation_EventCount == 0;

    donate@withrevert(e, amount);

    assert lastReverted;
    assert ghost_Donation_EventCount == 0;
}

rule donate_RevertWhen_DepositFails() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(DONATE_OPERATOR_ROLE(), e.msg.sender);
    require amount != 0, "amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";

    /// @dev revert condition being verified
    require adapter.depositReverts();

    /// @dev set ghost starting values
    require ghost_Donation_EventCount == 0;

    donate@withrevert(e, amount);

    assert lastReverted;
    assert ghost_Donation_EventCount == 0;
}

rule donate_Success() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(DONATE_OPERATOR_ROLE(), e.msg.sender);
    require amount != 0, "amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.depositReverts();
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    
    uint256 preTVL = adapter.getTVL();
    require preTVL <= max_uint256 - amount, "adapter TVL should not overflow";

    /// @dev set ghost starting values
    require ghost_Donation_EventCount == 0;

    donate@withrevert(e, amount);

    assert !lastReverted;
    assert adapter.getTVL() == preTVL + amount;
    assert ghost_Donation_EventCount == 1;
    assert ghost_Donation_Param_donor == e.msg.sender;
    assert ghost_Donation_Param_amount == amount;
}

/// donate does NOT require whenNotPaused — succeeds even when paused
rule donate_Success_WhenPaused() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(DONATE_OPERATOR_ROLE(), e.msg.sender);
    require amount != 0, "amount should not be zero";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.depositReverts();
    require paused(), "should be paused";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";

    uint256 preTVL = adapter.getTVL();
    require preTVL <= max_uint256 - amount, "adapter TVL should not overflow";

    /// @dev set ghost starting values
    require ghost_Donation_EventCount == 0;

    donate@withrevert(e, amount);

    assert !lastReverted;
    assert paused();
    assert adapter.getTVL() == preTVL + amount;
    assert ghost_Donation_EventCount == 1;
    assert ghost_Donation_Param_donor == e.msg.sender;
    assert ghost_Donation_Param_amount == amount;
}

/// ─────────────────── EMERGENCY DRAIN ─────────────────────────

rule emergencyDrain_RevertWhen_CallerDoesNotHaveEMERGENCY_DRAINER_ROLE() {
    env e;
    bool revertOnFailure;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require paused(), "should be paused";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    uint256 pausedAt = getPausedAt();
    require e.block.timestamp >= pausedAt, "timestamp should not precede pause";
    require e.block.timestamp - pausedAt >= 86400, "emergency drain delay should be met";

    /// @dev revert condition being verified
    require !hasRole(EMERGENCY_DRAINER_ROLE(), e.msg.sender);

    /// @dev set ghost starting values
    require ghost_EmergencyDrainExecuted_EventCount == 0;

    emergencyDrain@withrevert(e, revertOnFailure);

    assert lastReverted;
    assert ghost_EmergencyDrainExecuted_EventCount == 0;
}

rule emergencyDrain_RevertWhen_NotPaused() {
    env e;
    bool revertOnFailure;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EMERGENCY_DRAINER_ROLE(), e.msg.sender);
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";

    /// @dev revert condition being verified
    require !paused(), "should not be paused";

    /// @dev set ghost starting values
    require ghost_EmergencyDrainExecuted_EventCount == 0;

    emergencyDrain@withrevert(e, revertOnFailure);

    assert lastReverted;
    assert ghost_EmergencyDrainExecuted_EventCount == 0;
}

rule emergencyDrain_RevertWhen_ReentrantCall() {
    env e;
    bool revertOnFailure;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EMERGENCY_DRAINER_ROLE(), e.msg.sender);
    require paused(), "should be paused";
    uint256 pausedAt = getPausedAt();
    require e.block.timestamp >= pausedAt, "timestamp should not precede pause";
    require e.block.timestamp - pausedAt >= 86400, "emergency drain delay should be met";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard should be entered";

    /// @dev set ghost starting values
    require ghost_EmergencyDrainExecuted_EventCount == 0;

    emergencyDrain@withrevert(e, revertOnFailure);

    assert lastReverted;
    assert ghost_EmergencyDrainExecuted_EventCount == 0;
}

/// EMERGENCY_DRAIN_DELAY = 1 days = 86400 seconds
rule emergencyDrain_RevertWhen_DelayNotMet() {
    env e;
    bool revertOnFailure;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EMERGENCY_DRAINER_ROLE(), e.msg.sender);
    require paused(), "should be paused";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    uint256 pausedAt = getPausedAt();
    require e.block.timestamp >= pausedAt, "timestamp should not precede pause";

    /// @dev revert condition being verified
    require e.block.timestamp - pausedAt < 86400, "emergency drain delay should not be met";

    /// @dev set ghost starting values
    require ghost_EmergencyDrainExecuted_EventCount == 0;

    emergencyDrain@withrevert(e, revertOnFailure);

    assert lastReverted;
    assert ghost_EmergencyDrainExecuted_EventCount == 0;
}

rule emergencyDrain_RevertWhen_WithdrawFailsAndRevertOnFailureIsTrue() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EMERGENCY_DRAINER_ROLE(), e.msg.sender);
    require paused(), "should be paused";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    uint256 pausedAt = getPausedAt();
    require e.block.timestamp >= pausedAt, "timestamp should not precede pause";
    require e.block.timestamp - pausedAt >= 86400, "emergency drain delay should be met";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require getTVL() > 0, "TVL should be greater than zero";

    /// @dev revert conditions being verified
    bool revertOnFailure = true;
    require adapter.withdrawReverts(), "strategy withdraw should revert";

    /// @dev set ghost starting values
    require ghost_EmergencyDrainExecuted_EventCount == 0;

    emergencyDrain@withrevert(e, revertOnFailure);

    assert lastReverted;
    assert ghost_EmergencyDrainExecuted_EventCount == 0;
}

rule emergencyDrain_Success_WhenTVLIsZero() {
    env e;
    bool revertOnFailure;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EMERGENCY_DRAINER_ROLE(), e.msg.sender);
    require paused(), "should be paused";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    uint256 pausedAt = getPausedAt();
    require e.block.timestamp >= pausedAt, "timestamp should not precede pause";
    require e.block.timestamp - pausedAt >= 86400, "emergency drain delay should be met";
    require getTVL() == 0, "TVL should be zero";
    address emergencyReceiver = getEmergencyReceiver();
    require emergencyReceiver != currentContract, "emergency receiver should not be the vault";
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 receiverBalanceBefore = asset.balanceOf(emergencyReceiver);
    require receiverBalanceBefore <= max_uint256 - vaultBalanceBefore, "receiver asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_EmergencyDrainExecuted_EventCount == 0;

    emergencyDrain@withrevert(e, revertOnFailure);

    assert !lastReverted;
    assert asset.balanceOf(currentContract) == 0;
    assert asset.balanceOf(emergencyReceiver) == receiverBalanceBefore + vaultBalanceBefore;
    assert ghost_EmergencyDrainExecuted_EventCount == 1;
    assert ghost_EmergencyDrainExecuted_Param_receiver == emergencyReceiver;
    assert ghost_EmergencyDrainExecuted_Param_amount == vaultBalanceBefore;
}

rule emergencyDrain_Success_WhenWithdrawFailsAndRevertOnFailureIsFalse() {
    env e;
    bool revertOnFailure;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EMERGENCY_DRAINER_ROLE(), e.msg.sender);
    require paused(), "should be paused";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    uint256 pausedAt = getPausedAt();
    require e.block.timestamp >= pausedAt, "timestamp should not precede pause";
    require e.block.timestamp - pausedAt >= 86400, "emergency drain delay should be met";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require getTVL() > 0, "TVL should be greater than zero";
    require adapter.withdrawReverts(), "strategy withdraw should revert";
    require !revertOnFailure, "should not revert on withdraw failure";
    address emergencyReceiver = getEmergencyReceiver();
    require emergencyReceiver != currentContract, "emergency receiver should not be the vault";
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 receiverBalanceBefore = asset.balanceOf(emergencyReceiver);
    require receiverBalanceBefore <= max_uint256 - vaultBalanceBefore, "receiver asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_EmergencyDrainExecuted_EventCount == 0;

    emergencyDrain@withrevert(e, revertOnFailure);

    assert !lastReverted;
    assert asset.balanceOf(currentContract) == 0;
    assert asset.balanceOf(emergencyReceiver) == receiverBalanceBefore + vaultBalanceBefore;
    assert ghost_EmergencyDrainExecuted_EventCount == 1;
    assert ghost_EmergencyDrainExecuted_Param_receiver == emergencyReceiver;
    assert ghost_EmergencyDrainExecuted_Param_amount == vaultBalanceBefore;
}

rule emergencyDrain_Success_WhenWithdrawSucceeds() {
    env e;
    bool revertOnFailure;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(EMERGENCY_DRAINER_ROLE(), e.msg.sender);
    require paused(), "should be paused";
    require !reentrancyGuardEntered(), "reentrancy guard should not be entered";
    uint256 pausedAt = getPausedAt();
    require e.block.timestamp >= pausedAt, "timestamp should not precede pause";
    require e.block.timestamp - pausedAt >= 86400, "emergency drain delay should be met";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require getTVL() > 0, "TVL should be greater than zero";
    require !adapter.withdrawReverts(), "strategy withdraw should not revert";
    address emergencyReceiver = getEmergencyReceiver();
    require emergencyReceiver != currentContract, "emergency receiver should not be the vault";
    require emergencyReceiver != adapter, "emergency receiver should not be the adapter";
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterTVLBefore = adapter.getTVL();
    require adapterTVLBefore <= asset.balanceOf(adapter), "adapter asset balance should cover its TVL";
    require vaultBalanceBefore <= max_uint256 - adapterTVLBefore, "vault asset balance should not overflow";
    mathint drainedAmount = vaultBalanceBefore + adapterTVLBefore;
    uint256 receiverBalanceBefore = asset.balanceOf(emergencyReceiver);
    require receiverBalanceBefore <= max_uint256 - drainedAmount, "receiver asset balance should not overflow";

    /// @dev set ghost starting values
    require ghost_EmergencyDrainExecuted_EventCount == 0;

    emergencyDrain@withrevert(e, revertOnFailure);

    assert !lastReverted;
    assert adapter.getTVL() == 0;
    assert asset.balanceOf(currentContract) == 0;
    assert asset.balanceOf(emergencyReceiver) == receiverBalanceBefore + drainedAmount;
    assert ghost_EmergencyDrainExecuted_EventCount == 1;
    assert ghost_EmergencyDrainExecuted_Param_receiver == emergencyReceiver;
    assert ghost_EmergencyDrainExecuted_Param_amount == drainedAmount;
}

/// ─────────────────── TRY DEPOSIT TO ADAPTER ──────────────────

rule tryDepositToAdapter_RevertWhen_CallerIsNotSelf() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !adapter.depositReverts(), "adapter deposit should not revert";

    /// @dev revert condition being verified
    require e.msg.sender != currentContract;

    tryDepositToAdapter@withrevert(e, adapter, amount);

    assert lastReverted;
}

rule tryDepositToAdapter_RevertWhen_AdapterDepositReverts() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == currentContract;

    /// @dev revert condition being verified
    require adapter.depositReverts(), "adapter deposit should revert";

    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    tryDepositToAdapter@withrevert(e, adapter, amount);

    assert lastReverted;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
}

rule tryDepositToAdapter_Success() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require e.msg.sender == currentContract;
    require !adapter.depositReverts(), "adapter deposit should not revert";
    require adapter != currentContract, "adapter should not be the vault";

    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();
    require amount <= vaultBalanceBefore, "vault asset balance should not underflow";
    require adapterBalanceBefore <= max_uint256 - amount, "adapter asset balance should not overflow";
    require adapterTVLBefore <= max_uint256 - amount, "adapter TVL should not overflow";

    tryDepositToAdapter@withrevert(e, adapter, amount);

    assert !lastReverted;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore - amount;
    assert asset.balanceOf(adapter) == adapterBalanceBefore + amount;
    assert adapter.getTVL() == adapterTVLBefore + amount;
}

/// ─────────────────── STORE REBALANCE DEPOSIT RECOVERY ────────

/// @notice Storing recovery state reverts when another recovery is already pending
/// @dev Verifies that the existing recovery state is unchanged and no event is emitted
rule storeRebalanceDepositRecovery_RevertWhen_RecoveryAlreadyPending() {
    env e;
    uint256 rebalanceNonce;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require amount != 0, "amount should not be zero";

    /// @dev revert condition being verified
    require getRecoveryMode() != RECOVERY_NONE(), "recovery should already be pending";

    Types.RecoveryMode recoveryModeBefore = getRecoveryMode();
    uint256 recoveryNonceBefore = getRecoveryRebalanceNonce();
    uint256 recoveryAmountBefore = getRecoveryAmount();
    uint256 recoveryCreatedAtBefore = getRecoveryCreatedAt();

    /// @dev set ghost starting values
    require ghost_RebalanceDepositRecoveryStored_EventCount == 0;
    require ghost_rebalanceDepositRecovery_nonce_StoreCount == 0;
    require ghost_rebalanceDepositRecovery_amount_StoreCount == 0;
    require ghost_rebalanceDepositRecovery_createdAt_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;

    storeRebalanceDepositRecovery@withrevert(e, rebalanceNonce, amount);

    assert lastReverted;
    assert getRecoveryMode() == recoveryModeBefore;
    assert getRecoveryRebalanceNonce() == recoveryNonceBefore;
    assert getRecoveryAmount() == recoveryAmountBefore;
    assert getRecoveryCreatedAt() == recoveryCreatedAtBefore;
    assert ghost_RebalanceDepositRecoveryStored_EventCount == 0;
    assert ghost_rebalanceDepositRecovery_nonce_StoreCount == 0;
    assert ghost_rebalanceDepositRecovery_amount_StoreCount == 0;
    assert ghost_rebalanceDepositRecovery_createdAt_StoreCount == 0;
    assert ghost_recoveryMode_StoreCount == 0;
}

/// @notice Storing recovery state reverts when the recovery amount is zero
/// @dev Verifies that recovery state remains empty and no event is emitted
rule storeRebalanceDepositRecovery_RevertWhen_AmountIsZero() {
    env e;
    uint256 rebalanceNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getRecoveryMode() == RECOVERY_NONE(), "recovery should not be pending";

    /// @dev revert condition being verified
    uint256 amount = 0;

    uint256 recoveryNonceBefore = getRecoveryRebalanceNonce();
    uint256 recoveryAmountBefore = getRecoveryAmount();
    uint256 recoveryCreatedAtBefore = getRecoveryCreatedAt();

    /// @dev set ghost starting values
    require ghost_RebalanceDepositRecoveryStored_EventCount == 0;
    require ghost_rebalanceDepositRecovery_nonce_StoreCount == 0;
    require ghost_rebalanceDepositRecovery_amount_StoreCount == 0;
    require ghost_rebalanceDepositRecovery_createdAt_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;

    storeRebalanceDepositRecovery@withrevert(e, rebalanceNonce, amount);

    assert lastReverted;
    assert getRecoveryMode() == RECOVERY_NONE();
    assert getRecoveryRebalanceNonce() == recoveryNonceBefore;
    assert getRecoveryAmount() == recoveryAmountBefore;
    assert getRecoveryCreatedAt() == recoveryCreatedAtBefore;
    assert ghost_RebalanceDepositRecoveryStored_EventCount == 0;
    assert ghost_rebalanceDepositRecovery_nonce_StoreCount == 0;
    assert ghost_rebalanceDepositRecovery_amount_StoreCount == 0;
    assert ghost_rebalanceDepositRecovery_createdAt_StoreCount == 0;
    assert ghost_recoveryMode_StoreCount == 0;
}

/// @notice A nonzero rebalance deposit recovery is stored when no recovery is pending
/// @dev Verifies the recovery fields, recovery mode, storage writes, and emitted event
rule storeRebalanceDepositRecovery_Success() {
    env e;
    uint256 rebalanceNonce;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require amount != 0, "amount should not be zero";
    require getRecoveryMode() == RECOVERY_NONE(), "recovery should not be pending";

    /// @dev set ghost starting values
    require ghost_RebalanceDepositRecoveryStored_EventCount == 0;
    require ghost_rebalanceDepositRecovery_nonce_StoreCount == 0;
    require ghost_rebalanceDepositRecovery_amount_StoreCount == 0;
    require ghost_rebalanceDepositRecovery_createdAt_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;

    storeRebalanceDepositRecovery@withrevert(e, rebalanceNonce, amount);

    assert !lastReverted;
    assert getRecoveryMode() == RECOVERY_REBALANCE_DEPOSIT();
    assert getRecoveryRebalanceNonce() == rebalanceNonce;
    assert getRecoveryAmount() == amount;
    assert getRecoveryCreatedAt() == e.block.timestamp;
    assert ghost_RebalanceDepositRecoveryStored_EventCount == 1;
    assert ghost_RebalanceDepositRecoveryStored_Param_nonce == rebalanceNonce;
    assert ghost_RebalanceDepositRecoveryStored_Param_amount == amount;
    assert ghost_rebalanceDepositRecovery_nonce_StoreCount == 1;
    assert ghost_rebalanceDepositRecovery_nonce_StoredValue == rebalanceNonce;
    assert ghost_rebalanceDepositRecovery_amount_StoreCount == 1;
    assert ghost_rebalanceDepositRecovery_amount_StoredValue == amount;
    assert ghost_rebalanceDepositRecovery_createdAt_StoreCount == 1;
    assert ghost_rebalanceDepositRecovery_createdAt_StoredValue == e.block.timestamp;
    assert ghost_recoveryMode_StoreCount == 1;
    assert ghost_recoveryMode_StoredValue == Types.RecoveryMode.REBALANCE_DEPOSIT;
}

/// ─────────────────── CLEAR REBALANCE DEPOSIT RECOVERY ────────

/// @notice Clearing rebalance deposit recovery reverts unless that recovery mode is active
/// @dev Verifies that the existing recovery state is unchanged and no event is emitted
rule clearRebalanceDepositRecovery_RevertWhen_NoPendingRecovery() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";

    /// @dev revert condition being verified
    require getRecoveryMode() != RECOVERY_REBALANCE_DEPOSIT(), "rebalance deposit recovery should not be pending";

    Types.RecoveryMode recoveryModeBefore = getRecoveryMode();
    uint256 recoveryNonceBefore = getRecoveryRebalanceNonce();
    uint256 recoveryAmountBefore = getRecoveryAmount();
    uint256 recoveryCreatedAtBefore = getRecoveryCreatedAt();

    /// @dev set ghost starting values
    require ghost_RebalanceDepositRecoveryCleared_EventCount == 0;
    require ghost_rebalanceDepositRecovery_nonce_StoreCount == 0;
    require ghost_rebalanceDepositRecovery_amount_StoreCount == 0;
    require ghost_rebalanceDepositRecovery_createdAt_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;

    clearRebalanceDepositRecovery@withrevert(e);

    assert lastReverted;
    assert getRecoveryMode() == recoveryModeBefore;
    assert getRecoveryRebalanceNonce() == recoveryNonceBefore;
    assert getRecoveryAmount() == recoveryAmountBefore;
    assert getRecoveryCreatedAt() == recoveryCreatedAtBefore;
    assert ghost_RebalanceDepositRecoveryCleared_EventCount == 0;
    assert ghost_rebalanceDepositRecovery_nonce_StoreCount == 0;
    assert ghost_rebalanceDepositRecovery_amount_StoreCount == 0;
    assert ghost_rebalanceDepositRecovery_createdAt_StoreCount == 0;
    assert ghost_recoveryMode_StoreCount == 0;
}

/// @notice Clearing an active rebalance deposit recovery deletes its state
/// @dev Verifies the recovery fields, recovery mode, storage writes, and emitted event
rule clearRebalanceDepositRecovery_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getRecoveryMode() == RECOVERY_REBALANCE_DEPOSIT(), "rebalance deposit recovery should be pending";

    uint256 recoveryNonceBefore = getRecoveryRebalanceNonce();

    /// @dev set ghost starting values
    require ghost_RebalanceDepositRecoveryCleared_EventCount == 0;
    require ghost_rebalanceDepositRecovery_nonce_StoreCount == 0;
    require ghost_rebalanceDepositRecovery_amount_StoreCount == 0;
    require ghost_rebalanceDepositRecovery_createdAt_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;

    clearRebalanceDepositRecovery@withrevert(e);

    assert !lastReverted;
    assert getRecoveryMode() == RECOVERY_NONE();
    assert getRecoveryRebalanceNonce() == 0;
    assert getRecoveryAmount() == 0;
    assert getRecoveryCreatedAt() == 0;
    assert ghost_RebalanceDepositRecoveryCleared_EventCount == 1;
    assert ghost_RebalanceDepositRecoveryCleared_Param_nonce == recoveryNonceBefore;
    assert ghost_rebalanceDepositRecovery_nonce_StoreCount == 1;
    assert ghost_rebalanceDepositRecovery_nonce_StoredValue == 0;
    assert ghost_rebalanceDepositRecovery_amount_StoreCount == 1;
    assert ghost_rebalanceDepositRecovery_amount_StoredValue == 0;
    assert ghost_rebalanceDepositRecovery_createdAt_StoreCount == 1;
    assert ghost_rebalanceDepositRecovery_createdAt_StoredValue == 0;
    assert ghost_recoveryMode_StoreCount == 1;
    assert ghost_recoveryMode_StoredValue == Types.RecoveryMode.NONE;
}

/// ─────────────────── REQUIRE REBALANCE DEPOSIT RECOVERY ─────

/// @notice Requiring rebalance deposit recovery reverts unless that recovery mode is active
/// @dev Verifies that recovery validation does not modify vault storage
rule requireRebalanceDepositRecovery_RevertWhen_NoPendingRecovery() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";

    /// @dev revert condition being verified
    require getRecoveryMode() != RECOVERY_REBALANCE_DEPOSIT(), "rebalance deposit recovery should not be pending";

    storage before = lastStorage;

    requireRebalanceDepositRecovery@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Requiring active rebalance deposit recovery returns the stored recovery record
/// @dev Verifies all returned fields and that recovery validation does not modify vault storage
rule requireRebalanceDepositRecovery_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getRecoveryMode() == RECOVERY_REBALANCE_DEPOSIT(), "rebalance deposit recovery should be pending";

    uint256 expectedNonce = getRecoveryRebalanceNonce();
    uint256 expectedAmount = getRecoveryAmount();
    uint256 expectedCreatedAt = getRecoveryCreatedAt();
    storage before = lastStorage;

    Types.RebalanceDepositRecovery recovery = requireRebalanceDepositRecovery@withrevert(e);

    assert !lastReverted;
    assert recovery.rebalanceNonce == expectedNonce;
    assert recovery.amount == expectedAmount;
    assert recovery.createdAt == expectedCreatedAt;
    assert before[currentContract] == lastStorage[currentContract];
}

/// ─────────────────── RECOVER FAILED REBALANCE DEPOSIT ───────

/// @notice Recovering a failed rebalance deposit reverts unless that recovery mode is active
/// @dev Verifies that recovery state, balances, TVL, and events remain unchanged
rule recoverFailedRebalanceDepositInternal_RevertWhen_NoPendingRecovery() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.depositReverts(), "adapter deposit should not revert";

    /// @dev revert condition being verified
    require getRecoveryMode() != RECOVERY_REBALANCE_DEPOSIT(), "rebalance deposit recovery should not be pending";

    storage before = lastStorage;
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev set ghost starting values
    require ghost_RebalanceDepositRecoveryCleared_EventCount == 0;
    require ghost_RebalanceDepositSuccess_EventCount == 0;

    recoverFailedRebalanceDepositInternal@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_RebalanceDepositRecoveryCleared_EventCount == 0;
    assert ghost_RebalanceDepositSuccess_EventCount == 0;
}

/// @notice Recovering a failed rebalance deposit reverts when no active adapter is set
/// @dev Verifies that recovery state, balances, TVL, and events remain unchanged
rule recoverFailedRebalanceDepositInternal_RevertWhen_NoActiveAdapter() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getRecoveryMode() == RECOVERY_REBALANCE_DEPOSIT(), "rebalance deposit recovery should be pending";
    require !adapter.depositReverts(), "adapter deposit should not revert";

    /// @dev revert condition being verified
    require getActiveProtocolAdapter() == 0, "active adapter should not be set";

    storage before = lastStorage;
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev set ghost starting values
    require ghost_RebalanceDepositRecoveryCleared_EventCount == 0;
    require ghost_RebalanceDepositSuccess_EventCount == 0;

    recoverFailedRebalanceDepositInternal@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_RebalanceDepositRecoveryCleared_EventCount == 0;
    assert ghost_RebalanceDepositSuccess_EventCount == 0;
}

/// @notice Recovering a failed rebalance deposit reverts when the adapter deposit fails
/// @dev Verifies atomic rollback of recovery state, balances, TVL, and events
rule recoverFailedRebalanceDepositInternal_RevertWhen_DepositFails() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getRecoveryMode() == RECOVERY_REBALANCE_DEPOSIT(), "rebalance deposit recovery should be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";

    /// @dev revert condition being verified
    require adapter.depositReverts(), "adapter deposit should revert";

    storage before = lastStorage;
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev set ghost starting values
    require ghost_RebalanceDepositRecoveryCleared_EventCount == 0;
    require ghost_RebalanceDepositSuccess_EventCount == 0;

    recoverFailedRebalanceDepositInternal@withrevert(e);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_RebalanceDepositRecoveryCleared_EventCount == 0;
    assert ghost_RebalanceDepositSuccess_EventCount == 0;
}

/// @notice Recovering a failed rebalance deposit deposits the stored amount and clears recovery
/// @dev Verifies return values, balances, TVL, recovery deletion, storage writes, and events
rule recoverFailedRebalanceDepositInternal_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getRecoveryMode() == RECOVERY_REBALANCE_DEPOSIT(), "rebalance deposit recovery should be pending";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.depositReverts(), "adapter deposit should not revert";
    require adapter != currentContract, "adapter should not be the vault";

    uint256 recoveryNonceBefore = getRecoveryRebalanceNonce();
    uint256 recoveryAmountBefore = getRecoveryAmount();
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token and adapter arithmetic conditions
    require recoveryAmountBefore <= vaultBalanceBefore, "vault asset balance should cover the recovery amount";
    require adapterBalanceBefore <= max_uint256 - recoveryAmountBefore, "adapter asset balance should not overflow";
    require adapterTVLBefore <= max_uint256 - recoveryAmountBefore, "adapter TVL should not overflow";

    /// @dev set ghost starting values
    require ghost_RebalanceDepositRecoveryCleared_EventCount == 0;
    require ghost_RebalanceDepositSuccess_EventCount == 0;
    require ghost_rebalanceDepositRecovery_nonce_StoreCount == 0;
    require ghost_rebalanceDepositRecovery_amount_StoreCount == 0;
    require ghost_rebalanceDepositRecovery_createdAt_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;

    uint256 returnedNonce;
    uint256 returnedAmount;
    (returnedNonce, returnedAmount) = recoverFailedRebalanceDepositInternal@withrevert(e);

    assert !lastReverted;
    assert returnedNonce == recoveryNonceBefore;
    assert returnedAmount == recoveryAmountBefore;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore - recoveryAmountBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore + recoveryAmountBefore;
    assert adapter.getTVL() == adapterTVLBefore + recoveryAmountBefore;
    assert getRecoveryMode() == RECOVERY_NONE();
    assert getRecoveryRebalanceNonce() == 0;
    assert getRecoveryAmount() == 0;
    assert getRecoveryCreatedAt() == 0;
    assert ghost_RebalanceDepositRecoveryCleared_EventCount == 1;
    assert ghost_RebalanceDepositRecoveryCleared_Param_nonce == recoveryNonceBefore;
    assert ghost_RebalanceDepositSuccess_EventCount == 1;
    assert ghost_RebalanceDepositSuccess_Param_nonce == recoveryNonceBefore;
    assert ghost_RebalanceDepositSuccess_Param_amount == recoveryAmountBefore;
    assert ghost_rebalanceDepositRecovery_nonce_StoreCount == 1;
    assert ghost_rebalanceDepositRecovery_nonce_StoredValue == 0;
    assert ghost_rebalanceDepositRecovery_amount_StoreCount == 1;
    assert ghost_rebalanceDepositRecovery_amount_StoredValue == 0;
    assert ghost_rebalanceDepositRecovery_createdAt_StoreCount == 1;
    assert ghost_rebalanceDepositRecovery_createdAt_StoredValue == 0;
    assert ghost_recoveryMode_StoreCount == 1;
    assert ghost_recoveryMode_StoredValue == Types.RecoveryMode.NONE;
}

/// ─────────────────── AUTHORIZE UPGRADE ─────────────────────

/// @notice Upgrade authorization reverts when the caller does not have UPGRADER_ROLE
/// @dev Verifies the BaseVault authorization hook independently of UUPS proxy context
rule authorizeUpgrade_RevertWhen_CallerDoesNotHaveUPGRADER_ROLE() {
    env e;
    address newImplementation;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";

    /// @dev revert condition being verified
    require !hasRole(UPGRADER_ROLE(), e.msg.sender);

    authorizeUpgrade@withrevert(e, newImplementation);
    assert lastReverted;
}

/// @notice Upgrade authorization succeeds when the caller has UPGRADER_ROLE
/// @dev The authorization hook validates only the caller and does not modify vault storage
rule authorizeUpgrade_Success() {
    env e;
    address newImplementation;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require hasRole(UPGRADER_ROLE(), e.msg.sender);

    storage before = lastStorage;

    authorizeUpgrade@withrevert(e, newImplementation);

    assert !lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// ─────────────────── EXECUTE DEPOSIT ─────────────────────

/// @notice Executing a deposit reverts when no active strategy adapter is set
/// @dev Verifies that no asset balances or adapter TVL change
rule executeDeposit_RevertWhen_NoActiveAdapter() {
    env e;
    uint256 amount;
    bool revertOnFailure;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !adapter.depositReverts();

    /// @dev revert condition being verified
    require getActiveProtocolAdapter() == 0, "active adapter should not be set";

    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    executeDeposit@withrevert(e, amount, revertOnFailure);

    assert lastReverted;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
}

/// @notice Executing a deposit reverts when the adapter deposit fails and failure must revert
/// @dev Verifies that the failed external self-call rolls back all balance and TVL changes
rule executeDeposit_RevertWhen_DepositFailsWithRevertOnFailure() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";

    /// @dev revert conditions being verified
    bool revertOnFailure = true;
    require adapter.depositReverts(), "adapter deposit should revert";

    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    executeDeposit@withrevert(e, amount, revertOnFailure);

    assert lastReverted;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
}

/// @notice A failed deposit returns false when failure is not configured to revert
/// @dev Verifies that the failed external self-call rolls back all balance and TVL changes
rule executeDeposit_FailureReturnsFalseWhen_RevertOnFailureIsFalse() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";

    /// @dev failure conditions being verified
    bool revertOnFailure = false;
    require adapter.depositReverts(), "adapter deposit should revert";

    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    bool success = executeDeposit@withrevert(e, amount, revertOnFailure);

    assert !lastReverted;
    assert !success;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
}

/// @notice Executing a successful deposit returns true and transfers assets into the active adapter
/// @dev Verifies exact vault balance, adapter balance, and adapter TVL changes
rule executeDeposit_Success() {
    env e;
    uint256 amount;
    bool revertOnFailure;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.depositReverts(), "adapter deposit should not revert";
    require adapter != currentContract, "adapter should not be the vault";

    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev mock token and adapter arithmetic conditions
    require amount <= vaultBalanceBefore, "vault asset balance should cover the deposit amount";
    require adapterBalanceBefore <= max_uint256 - amount, "adapter asset balance should not overflow";
    require adapterTVLBefore <= max_uint256 - amount, "adapter TVL should not overflow";

    bool success = executeDeposit@withrevert(e, amount, revertOnFailure);

    assert !lastReverted;
    assert success;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore - amount;
    assert asset.balanceOf(adapter) == adapterBalanceBefore + amount;
    assert adapter.getTVL() == adapterTVLBefore + amount;
}

/// ─────────────────── EXECUTE WITHDRAW ──────────────────

/// @notice Executing a withdraw reverts when no active strategy adapter is set
/// @dev Verifies that no asset balances or adapter TVL change
rule executeWithdraw_RevertWhen_NoActiveAdapter() {
    env e;
    uint256 amount;
    bool revertOnFailure;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require !adapter.withdrawReverts();

    /// @dev revert condition being verified
    require getActiveProtocolAdapter() == 0, "active adapter should not be set";

    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    executeWithdraw@withrevert(e, amount, revertOnFailure);

    assert lastReverted;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
}

/// @notice Executing a withdraw reverts when the adapter withdraw fails and failure must revert
/// @dev Verifies that the failed adapter call leaves all balances and TVL unchanged
rule executeWithdraw_RevertWhen_WithdrawFailsWithRevertOnFailure() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";

    /// @dev revert conditions being verified
    bool revertOnFailure = true;
    require adapter.withdrawReverts(), "adapter withdraw should revert";

    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    executeWithdraw@withrevert(e, amount, revertOnFailure);

    assert lastReverted;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
}

/// @notice A failed withdrawal returns false and zero when failure is not configured to revert
/// @dev Verifies that the failed adapter call leaves all balances and TVL unchanged
rule executeWithdraw_FailureReturnsFalseWhen_RevertOnFailureIsFalse() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";

    /// @dev failure conditions being verified
    bool revertOnFailure = false;
    require adapter.withdrawReverts(), "adapter withdraw should revert";

    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    bool success;
    uint256 amountOut;
    (success, amountOut) = executeWithdraw@withrevert(e, amount, revertOnFailure);

    assert !lastReverted;
    assert !success;
    assert amountOut == 0;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
}

/// @notice Executing a successful withdraw returns true and the amount withdrawn by the adapter
/// @dev Verifies exact vault balance, adapter balance, and adapter TVL changes
rule executeWithdraw_Success() {
    env e;
    uint256 amount;
    bool revertOnFailure;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require getActiveProtocolAdapter() == adapter, "active adapter should be the protocol adapter";
    require !adapter.withdrawReverts(), "adapter withdraw should not revert";
    require adapter != currentContract, "adapter should not be the vault";

    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();
    uint256 expectedAmountOut = amount > adapterTVLBefore ? adapterTVLBefore : amount;

    /// @dev mock token arithmetic conditions
    require expectedAmountOut <= adapterBalanceBefore, "adapter asset balance should cover the amount withdrawn";
    require vaultBalanceBefore <= max_uint256 - expectedAmountOut, "vault asset balance should not overflow";

    bool success;
    uint256 amountOut;
    (success, amountOut) = executeWithdraw@withrevert(e, amount, revertOnFailure);

    assert !lastReverted;
    assert success;
    assert amountOut == expectedAmountOut;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore + expectedAmountOut;
    assert asset.balanceOf(adapter) == adapterBalanceBefore - expectedAmountOut;
    assert adapter.getTVL() == adapterTVLBefore - expectedAmountOut;
}

/// ─────────────────── HANDLE CCIP REBALANCE ──────────────────

/// @notice Handling a CCIP rebalance reverts when no adapter is registered for the protocol
/// @dev Verifies that vault state, balances, adapter TVL, and rebalance events remain unchanged
rule handleCCIPRebalance_RevertWhen_AdapterNotRegistered() {
    env e;
    uint256 rebalanceNonce;
    bytes32 protocolId;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";

    /// @dev revert condition being verified
    require adapterRegistry.getAdapter(e, protocolId) == 0, "adapter should not be registered";

    storage before = lastStorage;
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev set ghost starting values
    require ghost_ActiveProtocolAdapterSet_EventCount == 0;
    require ghost_RebalanceDepositSuccess_EventCount == 0;
    require ghost_RebalanceDepositFailure_EventCount == 0;
    require ghost_RebalanceDepositRecoveryStored_EventCount == 0;
    require ghost_activeProtocolAdapter_StoreCount == 0;

    handleCCIPRebalance@withrevert(e, rebalanceNonce, protocolId, amount);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_ActiveProtocolAdapterSet_EventCount == 0;
    assert ghost_RebalanceDepositSuccess_EventCount == 0;
    assert ghost_RebalanceDepositFailure_EventCount == 0;
    assert ghost_RebalanceDepositRecoveryStored_EventCount == 0;
    assert ghost_activeProtocolAdapter_StoreCount == 0;
}

/// @notice Handling a CCIP rebalance reverts when the registered adapter belongs to another vault
/// @dev Verifies that vault state, balances, adapter TVL, and rebalance events remain unchanged
rule handleCCIPRebalance_RevertWhen_AdapterVaultIsInvalid() {
    env e;
    uint256 rebalanceNonce;
    bytes32 protocolId;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require adapterRegistry.getAdapter(e, protocolId) == invalidAdapter;

    /// @dev revert condition being verified
    require invalidAdapter.getVault() != currentContract, "adapter vault should be invalid";

    storage before = lastStorage;
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev set ghost starting values
    require ghost_ActiveProtocolAdapterSet_EventCount == 0;
    require ghost_RebalanceDepositSuccess_EventCount == 0;
    require ghost_RebalanceDepositFailure_EventCount == 0;
    require ghost_RebalanceDepositRecoveryStored_EventCount == 0;
    require ghost_activeProtocolAdapter_StoreCount == 0;

    handleCCIPRebalance@withrevert(e, rebalanceNonce, protocolId, amount);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_ActiveProtocolAdapterSet_EventCount == 0;
    assert ghost_RebalanceDepositSuccess_EventCount == 0;
    assert ghost_RebalanceDepositFailure_EventCount == 0;
    assert ghost_RebalanceDepositRecoveryStored_EventCount == 0;
    assert ghost_activeProtocolAdapter_StoreCount == 0;
}

/// @notice Handling a CCIP rebalance reverts when a zero-amount deposit fails
/// @dev Recovery storage rejects the zero amount and rolls back adapter selection and all events
rule handleCCIPRebalance_RevertWhen_FailedDepositAmountIsZero() {
    env e;
    uint256 rebalanceNonce;
    bytes32 protocolId;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require adapterRegistry.getAdapter(e, protocolId) == adapter;
    require adapter.getVault() == currentContract, "adapter should be bound to the vault";
    require adapter.depositReverts(), "adapter deposit should revert";
    require getRecoveryMode() == RECOVERY_NONE(), "recovery should not be pending";

    /// @dev revert condition being verified
    uint256 amount = 0;

    storage before = lastStorage;
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev set ghost starting values
    require ghost_ActiveProtocolAdapterSet_EventCount == 0;
    require ghost_RebalanceDepositSuccess_EventCount == 0;
    require ghost_RebalanceDepositFailure_EventCount == 0;
    require ghost_RebalanceDepositRecoveryStored_EventCount == 0;

    handleCCIPRebalance@withrevert(e, rebalanceNonce, protocolId, amount);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_ActiveProtocolAdapterSet_EventCount == 0;
    assert ghost_RebalanceDepositSuccess_EventCount == 0;
    assert ghost_RebalanceDepositFailure_EventCount == 0;
    assert ghost_RebalanceDepositRecoveryStored_EventCount == 0;
}

/// @notice Handling a CCIP rebalance reverts when a failed deposit conflicts with pending recovery
/// @dev Recovery storage rejects the conflict and rolls back adapter selection and all events
rule handleCCIPRebalance_RevertWhen_RecoveryAlreadyPending() {
    env e;
    uint256 rebalanceNonce;
    bytes32 protocolId;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require adapterRegistry.getAdapter(e, protocolId) == adapter;
    require adapter.getVault() == currentContract, "adapter should be bound to the vault";
    require adapter.depositReverts(), "adapter deposit should revert";
    require amount != 0, "amount should not be zero";

    /// @dev revert condition being verified
    require getRecoveryMode() != RECOVERY_NONE(), "recovery should already be pending";

    storage before = lastStorage;
    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

    /// @dev set ghost starting values
    require ghost_ActiveProtocolAdapterSet_EventCount == 0;
    require ghost_RebalanceDepositSuccess_EventCount == 0;
    require ghost_RebalanceDepositFailure_EventCount == 0;
    require ghost_RebalanceDepositRecoveryStored_EventCount == 0;

    handleCCIPRebalance@withrevert(e, rebalanceNonce, protocolId, amount);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert ghost_ActiveProtocolAdapterSet_EventCount == 0;
    assert ghost_RebalanceDepositSuccess_EventCount == 0;
    assert ghost_RebalanceDepositFailure_EventCount == 0;
    assert ghost_RebalanceDepositRecoveryStored_EventCount == 0;
}

/// @notice A successful CCIP rebalance selects the adapter and deposits the bridged asset
/// @dev Verifies return value, balances, TVL, recovery preservation, storage writes, and events
rule handleCCIPRebalance_Success() {
    env e;
    uint256 rebalanceNonce;
    bytes32 protocolId;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require adapterRegistry.getAdapter(e, protocolId) == adapter;
    require adapter.getVault() == currentContract, "adapter should be bound to the vault";
    require !adapter.depositReverts(), "adapter deposit should not revert";
    require adapter != currentContract, "adapter should not be the vault";

    Types.RecoveryMode recoveryModeBefore = getRecoveryMode();
    uint256 recoveryNonceBefore = getRecoveryRebalanceNonce();
    uint256 recoveryAmountBefore = getRecoveryAmount();
    uint256 recoveryCreatedAtBefore = getRecoveryCreatedAt();
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
    require ghost_activeProtocolAdapter_StoreCount == 0;
    require ghost_recoveryMode_StoreCount == 0;
    require ghost_rebalanceDepositRecovery_nonce_StoreCount == 0;
    require ghost_rebalanceDepositRecovery_amount_StoreCount == 0;
    require ghost_rebalanceDepositRecovery_createdAt_StoreCount == 0;

    bool success = handleCCIPRebalance@withrevert(e, rebalanceNonce, protocolId, amount);

    assert !lastReverted;
    assert success;
    assert getActiveProtocolAdapter() == adapter;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore - amount;
    assert asset.balanceOf(adapter) == adapterBalanceBefore + amount;
    assert adapter.getTVL() == adapterTVLBefore + amount;
    assert getRecoveryMode() == recoveryModeBefore;
    assert getRecoveryRebalanceNonce() == recoveryNonceBefore;
    assert getRecoveryAmount() == recoveryAmountBefore;
    assert getRecoveryCreatedAt() == recoveryCreatedAtBefore;
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

/// @notice A failed CCIP rebalance deposit stores recovery and returns false
/// @dev Verifies unchanged balances and TVL, recovery state, storage writes, and failure events
rule handleCCIPRebalance_FailedDepositStoresRecovery() {
    env e;
    uint256 rebalanceNonce;
    bytes32 protocolId;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require adapterRegistry.getAdapter(e, protocolId) == adapter;
    require adapter.getVault() == currentContract, "adapter should be bound to the vault";
    require adapter.depositReverts(), "adapter deposit should revert";
    require amount != 0, "amount should not be zero";
    require getRecoveryMode() == RECOVERY_NONE(), "recovery should not be pending";

    uint256 vaultBalanceBefore = asset.balanceOf(currentContract);
    uint256 adapterBalanceBefore = asset.balanceOf(adapter);
    uint256 adapterTVLBefore = adapter.getTVL();

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

    bool success = handleCCIPRebalance@withrevert(e, rebalanceNonce, protocolId, amount);

    assert !lastReverted;
    assert !success;
    assert getActiveProtocolAdapter() == adapter;
    assert asset.balanceOf(currentContract) == vaultBalanceBefore;
    assert asset.balanceOf(adapter) == adapterBalanceBefore;
    assert adapter.getTVL() == adapterTVLBefore;
    assert getRecoveryMode() == RECOVERY_REBALANCE_DEPOSIT();
    assert getRecoveryRebalanceNonce() == rebalanceNonce;
    assert getRecoveryAmount() == amount;
    assert getRecoveryCreatedAt() == e.block.timestamp;
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
    assert ghost_recoveryMode_StoreCount == 1;
    assert ghost_recoveryMode_StoredValue == Types.RecoveryMode.REBALANCE_DEPOSIT;
    assert ghost_rebalanceDepositRecovery_nonce_StoreCount == 1;
    assert ghost_rebalanceDepositRecovery_nonce_StoredValue == rebalanceNonce;
    assert ghost_rebalanceDepositRecovery_amount_StoreCount == 1;
    assert ghost_rebalanceDepositRecovery_amount_StoredValue == amount;
    assert ghost_rebalanceDepositRecovery_createdAt_StoreCount == 1;
    assert ghost_rebalanceDepositRecovery_createdAt_StoredValue == e.block.timestamp;
}

/// ─────────────────── REVERT IF ZERO ADDRESS ──────────────────

/// @notice Address validation reverts when the supplied address is zero
rule revertIfZeroAddress_RevertWhen_AddressIsZero() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";

    revertIfZeroAddress@withrevert(e, 0);
    assert lastReverted;
}

/// ─────────────────── REVERT IF ZERO AMOUNT ──────────────────

/// @notice Amount validation reverts when the supplied amount is zero
rule revertIfZeroAmount_RevertWhen_AmountIsZero() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";

    revertIfZeroAmount@withrevert(e, 0);
    assert lastReverted;
}

/// ─────────────────── REVERT IF ZERO CHAIN SELECTOR ──────────────────

/// @notice Chain selector validation reverts when the supplied selector is zero
rule revertIfZeroChainSelector_RevertWhen_ChainSelectorIsZero() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";

    revertIfZeroChainSelector@withrevert(e, 0);
    assert lastReverted;
}

/// ─────────────────── REQUIRE NO RECOVERY ──────────────────

/// @notice No-recovery validation reverts when any recovery mode is active
rule requireNoRecovery_RevertWhen_RecoveryIsPending() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";

    /// @dev revert condition being verified
    require getRecoveryMode() != RECOVERY_NONE(), "recovery should be pending";

    requireNoRecovery@withrevert(e);

    assert lastReverted;
}

/// @notice No-recovery validation succeeds when no recovery mode is active
/// @dev Verifies that successful recovery validation does not modify vault storage
rule requireNoRecovery_SuccessWhen_NoRecoveryIsPending() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";

    /// @dev success condition being verified
    require getRecoveryMode() == RECOVERY_NONE(), "recovery should not be pending";

    storage before = lastStorage;

    requireNoRecovery@withrevert(e);

    assert !lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// ─────────────────── REQUIRE RECOVERY MODE ──────────────────

/// @notice Recovery-mode validation reverts when the active mode does not match the expected mode
rule requireRecoveryMode_RevertWhen_RecoveryModeDoesNotMatch() {
    env e;
    Types.RecoveryMode expected;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";

    /// @dev revert condition being verified
    require getRecoveryMode() != expected, "active recovery mode should not match the expected mode";

    requireRecoveryMode@withrevert(e, expected);

    assert lastReverted;
}

/// @notice Recovery-mode validation succeeds when the active mode matches the expected mode
/// @dev Verifies that successful recovery validation does not modify vault storage
rule requireRecoveryMode_SuccessWhen_RecoveryModeMatches() {
    env e;
    Types.RecoveryMode expected;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";

    /// @dev success condition being verified
    require getRecoveryMode() == expected, "active recovery mode should match the expected mode";

    storage before = lastStorage;

    requireRecoveryMode@withrevert(e, expected);

    assert !lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}


// /// ─────────────────── SUPPORTS INTERFACE ──────────────────────

// @review this is ai slop, we can make helpers in HelperHarness for returning bytes4 literals. but we should defer assertions to parent/child specs because they use different implementations
// /// For any bytes4 id that the contract does NOT explicitly support,
// /// supportsInterface must return false.  CVL cannot write bytes4 literals,
// /// so we check the contrapositive: if supportsInterface returns true,
// /// Certora must be able to construct a concrete id — if it can't the rule passes.
// rule supportsInterface_ReturnsFalse_ForUnknownInterface() {
//     bytes4 id;
//     bool result = supportsInterface(id);
//     /// Satisfy: result == false is reachable (not always-true)
//     satisfy !result;
// }

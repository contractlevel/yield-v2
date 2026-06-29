// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {CCIPReceiver, IAny2EVMMessageReceiver} from "@chainlink/contracts-ccip/contracts/applications/CCIPReceiver.sol";

import {
    AccessControlDefaultAdminRulesUpgradeable,
    IAccessControlDefaultAdminRules
} from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlDefaultAdminRulesUpgradeable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {
    ReentrancyGuardTransientUpgradeable
} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardTransientUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {BaseVaultStore} from "./BaseVaultStore.sol";
import {BaseVaultCcipLib} from "../libraries/BaseVaultCcipLib.sol";
import {BaseVaultStrategyLib} from "../libraries/BaseVaultStrategyLib.sol";
import {Roles} from "../libraries/Roles.sol";
import {Types} from "../libraries/Types.sol";
import {IBaseVault} from "../interfaces/IBaseVault.sol";
import {IProtocolAdapter} from "../interfaces/IProtocolAdapter.sol";

/// @title Yieldcoin v2 BaseVault
/// @author @contractlevel
/// @notice Base contract for Parent and Child Vaults in Yieldcoin v2
abstract contract BaseVault is
    BaseVaultStore,
    PausableUpgradeable,
    AccessControlDefaultAdminRulesUpgradeable,
    ReentrancyGuardTransientUpgradeable,
    UUPSUpgradeable,
    CCIPReceiver,
    IBaseVault
{
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Initial default admin role transfer delay. Deploy scripts use the deployer as a temporary admin
    ///      and immediately begin handoff to the configured default admin.
    uint48 internal constant INITIAL_DEFAULT_ADMIN_ROLE_TRANSFER_DELAY = 0;
    /// @dev Delay for emergency draining
    uint256 internal constant EMERGENCY_DRAIN_DELAY = 1 days;

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLE
    //////////////////////////////////////////////////////////////*/
    /// @dev CCIP selector for this chain
    uint64 internal immutable i_thisChainSelector;
    /// @dev Chainlink LINK token
    address internal immutable i_link;
    /// @dev The underlying asset managed by the vault
    address internal immutable i_asset;
    /// @dev Precision factor for the underlying asset (10 ** decimals())
    uint256 internal immutable i_assetPrecision;
    /// @dev Registry contract for strategy protocol adapters
    address internal immutable i_adapterRegistry;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Modifier to only allow messages from allowed crosschain vaults
    /// @param sender The address of the sender
    /// @param srcChainSelector The CCIP selector of the chain
    modifier onlyAllowedSender(address sender, uint64 srcChainSelector) {
        _onlyAllowedSender(sender, srcChainSelector);
        _;
    }

    /// @notice Internal function to only allow messages from allowed crosschain vaults
    /// @param sender The address of the sender
    /// @param srcChainSelector The CCIP selector of the chain
    /// @dev Precondition: Sender must be the crosschain vault for the source chain selector
    function _onlyAllowedSender(address sender, uint64 srcChainSelector) internal view {
        BaseVaultCcipLib.onlyAllowedSender(_baseVaultStorage(), sender, srcChainSelector);
    }

    /// @notice Reverts when a required address input is zero
    /// @param value The address to validate
    function _revertIfZeroAddress(address value) internal pure {
        if (value == address(0)) revert BaseVault__NoZeroAddress();
    }

    /// @notice Reverts when a required amount input is zero
    /// @param value The amount to validate
    function _revertIfZeroAmount(uint256 value) internal pure {
        if (value == 0) revert BaseVault__NoZeroAmount();
    }

    /// @notice Reverts when a required chain selector input is zero
    /// @param value The chain selector to validate
    function _revertIfZeroChainSelector(uint64 value) internal pure {
        if (value == 0) revert BaseVault__NoZeroChainSelector();
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @notice Parameters to initialize immutable contract values in the constructor.
    /// @param link The address of the Chainlink LINK token
    /// @param asset The address of the underlying asset token
    /// @param ccipRouter The address of the CCIP router
    /// @param adapterRegistry The address of the Yieldcoin v2 AdapterRegistry
    /// @param thisChainSelector The CCIP selector for this chain
    struct ConstructorParams {
        address link;
        address asset;
        address ccipRouter;
        address adapterRegistry;
        uint64 thisChainSelector;
    }

    /// @notice Parameters to initialize mutable proxy state.
    /// @param defaultAdmin The address of the default admin for setting roles - trusted actor in the system
    /// @param pauser The address of the pauser for pausing the vault - trusted actor in the system
    /// @param unpauser The address of the unpauser for unpausing the vault - trusted actor in the system
    /// @param configOperator The address of the config operator for setters - trusted actor in the system
    /// @param emergencyReceiver The address that receives the underlying asset during emergency drain
    /// @param initialDefaultCcipGasLimit The initial s_defaultCcipGasLimit
    /// @param upgrader The address authorized to upgrade the vault implementation through UUPS
    struct InitParams {
        address defaultAdmin;
        address pauser;
        address unpauser;
        address configOperator;
        address emergencyReceiver;
        uint256 initialDefaultCcipGasLimit;
        address upgrader;
    }

    /// @notice Initializes implementation-level immutable configuration and disables implementation initializers.
    /// @param params Constructor parameters for values that are baked into the implementation bytecode
    /// @dev Precondition: required immutable address params must not be the zero address
    /// @dev Precondition: params.thisChainSelector must not be zero
    constructor(ConstructorParams memory params) CCIPReceiver(params.ccipRouter) {
        _revertIfZeroAddress(params.link);
        _revertIfZeroAddress(params.asset);
        _revertIfZeroAddress(params.ccipRouter);
        _revertIfZeroAddress(params.adapterRegistry);
        _revertIfZeroChainSelector(params.thisChainSelector);

        i_thisChainSelector = params.thisChainSelector;
        i_link = params.link;
        i_asset = params.asset;
        i_assetPrecision = 10 ** IERC20Metadata(params.asset).decimals();
        i_adapterRegistry = params.adapterRegistry;
        _disableInitializers();
    }

    /// @notice Initializes BaseVault mutable proxy state.
    /// @param params Initializer parameters for roles and mutable vault configuration
    /// @notice Grants PAUSER_ROLE to params.pauser.
    /// @notice Grants UNPAUSER_ROLE to params.unpauser.
    /// @notice Grants CONFIG_OPERATOR_ROLE to params.configOperator.
    /// @notice Grants UPGRADER_ROLE to params.upgrader.
    /// @dev Precondition: required address params must not be the zero address
    /// @dev Precondition: params.initialDefaultCcipGasLimit must not be zero
    function __BaseVault_init(InitParams memory params) internal onlyInitializing {
        _revertIfZeroAddress(params.defaultAdmin);
        _revertIfZeroAddress(params.pauser);
        _revertIfZeroAddress(params.unpauser);
        _revertIfZeroAddress(params.configOperator);
        _revertIfZeroAddress(params.emergencyReceiver);
        _revertIfZeroAddress(params.upgrader);
        _revertIfZeroAmount(params.initialDefaultCcipGasLimit);

        __Pausable_init();
        __AccessControlDefaultAdminRules_init(INITIAL_DEFAULT_ADMIN_ROLE_TRANSFER_DELAY, params.defaultAdmin);
        __ReentrancyGuardTransient_init();
        __UUPSUpgradeable_init();

        BaseVaultStorage storage $ = _baseVaultStorage();
        $.s_emergencyReceiver = params.emergencyReceiver;
        $.s_defaultCcipGasLimit = params.initialDefaultCcipGasLimit;
        _grantRole(Roles.PAUSER_ROLE, params.pauser);
        _grantRole(Roles.UNPAUSER_ROLE, params.unpauser);
        _grantRole(Roles.CONFIG_OPERATOR_ROLE, params.configOperator);
        _grantRole(Roles.UPGRADER_ROLE, params.upgrader);
    }

    /*//////////////////////////////////////////////////////////////
                                  CCIP
    //////////////////////////////////////////////////////////////*/
    /// @notice Bridges asset to a destination chain
    /// @param bridgeAmount The amount of asset to bridge
    /// @param destinationChainSelector The CCIP selector of the destination chain
    /// @param ccipTxType The type of CCIP transaction
    /// @param txData abi.encode(epochNonce) for epoch net deposit/withdraw, or abi.encode(rebalanceNonce, newStrategy.protocolId) for rebalance
    /// @dev Precondition: bridgeAmount must be more than 0
    /// @dev Precondition: destinationChainSelector must be non-zero
    /// @dev Precondition: destinationChainSelector must not equal the current chain selector
    /// @dev Precondition: destinationChainSelector must be a valid, registered crosschain vault
    function _ccipSend(
        uint256 bridgeAmount,
        uint64 destinationChainSelector,
        Types.CcipTx ccipTxType,
        bytes memory txData
    ) internal virtual {
        BaseVaultCcipLib.send(
            _baseVaultStorage(),
            bridgeAmount,
            destinationChainSelector,
            ccipTxType,
            txData,
            i_asset,
            i_link,
            i_ccipRouter,
            i_thisChainSelector
        );
    }

    /// @notice Handles the CCIP rebalance message
    /// @notice This will be implemented by all vaults.
    ///         The previous strategy chain sends a CCIP rebalance to this new strategy chain.
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param protocolId The protocol ID of the new strategy on this chain
    /// @param amount The amount of USDC to rebalance(deposit) into the new strategy on this chain
    function _handleCCIPRebalance(uint256 rebalanceNonce, bytes32 protocolId, uint256 amount)
        internal
        returns (bool success)
    {
        _setActiveAdapter(protocolId);
        success = _executeDeposit(amount, false);
        if (success) {
            emit RebalanceDepositSuccess(rebalanceNonce, amount);
        } else {
            _storeRebalanceDepositRecovery(rebalanceNonce, amount);
            emit RebalanceDepositFailure(rebalanceNonce, amount);
        }
    }

    /*//////////////////////////////////////////////////////////////
                         STRATEGY INTERACTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Executes a deposit to the active strategy
    /// @param amount The amount to deposit
    /// @param revertOnFailure Indicates whether the call should revert if the deposit to strategy fails or not
    /// @return success Whether the deposit succeeded or not
    /// @notice This function uses a trycatch to handle cases where the deposit to strategy fails
    function _executeDeposit(uint256 amount, bool revertOnFailure) internal returns (bool success) {
        address activeAdapter = _baseVaultStorage().s_activeProtocolAdapter;
        if (activeAdapter == address(0)) revert BaseVault__NoActiveAdapter();
        try this.tryDepositToAdapter(activeAdapter, amount) {
            success = true;
        } catch {
            if (revertOnFailure) revert BaseVault__DepositFailed(amount);
            success = false;
        }
    }

    /// @notice Called by _executeDeposit for explicit recovery
    /// @param adapter The active strategy adapter
    /// @param amount The amount to deposit into the adapter
    /// @dev Precondition: caller must be this vault
    function tryDepositToAdapter(address adapter, uint256 amount) external {
        if (msg.sender != address(this)) revert BaseVault__OnlySelf();

        IERC20(i_asset).safeTransfer(adapter, amount);
        IProtocolAdapter(adapter).deposit(amount);
    }

    /// @notice Executes a withdraw from the active strategy
    /// @param amount The amount to withdraw
    /// @param revertOnFailure Indicates whether the call should revert if the withdraw from strategy fails or not
    /// @return success Whether the withdraw succeeded or not
    /// @return amountOut The amount withdrawn. This will be 0 if revertOnFailure is false and the withdraw failed
    /// @notice This function uses a trycatch to handle cases where the withdraw from strategy fails
    function _executeWithdraw(uint256 amount, bool revertOnFailure) internal returns (bool success, uint256 amountOut) {
        address activeAdapter = _baseVaultStorage().s_activeProtocolAdapter;
        if (activeAdapter == address(0)) revert BaseVault__NoActiveAdapter();
        try IProtocolAdapter(activeAdapter).withdraw(amount) returns (uint256 actual) {
            success = true;
            amountOut = actual;
        } catch {
            if (revertOnFailure) revert BaseVault__WithdrawFailed(amount);
            success = false;
            amountOut = 0;
        }
    }

    /// @notice Sets the active strategy protocol adapter
    /// @param protocolId The protocol ID of the strategy
    /// @return adapter The address of the active strategy protocol adapter
    /// @dev Precondition: the protocol ID must have a registered adapter
    /// @dev Precondition: the registered adapter must be bound to this vault
    function _setActiveAdapter(bytes32 protocolId) internal returns (address adapter) {
        adapter =
            BaseVaultStrategyLib.setActiveAdapter(_baseVaultStorage(), protocolId, i_adapterRegistry, address(this));
    }

    /// @notice Clears the active strategy protocol adapter for this chain
    /// @dev Precondition: this chain is no longer the active strategy chain
    function _clearActiveAdapter() internal {
        BaseVaultStrategyLib.clearActiveAdapter(_baseVaultStorage());
    }

    /*//////////////////////////////////////////////////////////////
                               RECOVERY
    //////////////////////////////////////////////////////////////*/
    /// @notice Recovery function for storing a failed rebalance deposit
    /// @notice This is called when a rebalance attempts to deposit into a new strategy and fails
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param amount The amount that should have been rebalanced into the new strategy
    /// @dev Stores the rebalance nonce, amount, and block timestamp in one pending slot
    /// @dev Emits RebalanceDepositRecoveryStored event
    /// @dev Precondition: no recovery state must currently exist
    /// @dev Precondition: amount should not be zero
    function _storeRebalanceDepositRecovery(uint256 rebalanceNonce, uint256 amount) internal {
        //slither-disable-next-line incorrect-equality
        if (amount == 0) revert BaseVault__ZeroRecoveryAmount();
        _requireNoRecovery();

        _baseVaultStorage().s_rebalanceDepositRecovery = Types.RebalanceDepositRecovery({
            rebalanceNonce: rebalanceNonce, amount: amount, createdAt: block.timestamp
        });
        _baseVaultStorage().s_recoveryMode = Types.RecoveryMode.REBALANCE_DEPOSIT;
        emit RebalanceDepositRecoveryStored(rebalanceNonce, amount);
    }

    /// @notice Recovery function for clearing a failed rebalance deposit that was previously stored
    /// @notice This is called when a previously failed rebalance deposit succeeds
    /// @dev Precondition: Failed rebalance deposit should exist
    /// @dev Deletes the recovery state
    /// @dev Emites RebalanceDepositRecoveryCleared event
    function _clearRebalanceDepositRecovery() internal {
        _requireRecoveryMode(Types.RecoveryMode.REBALANCE_DEPOSIT);
        uint256 rebalanceNonce = _baseVaultStorage().s_rebalanceDepositRecovery.rebalanceNonce;

        delete _baseVaultStorage().s_rebalanceDepositRecovery;
        _baseVaultStorage().s_recoveryMode = Types.RecoveryMode.NONE;
        emit RebalanceDepositRecoveryCleared(rebalanceNonce);
    }

    /// @notice Checks for an existing rebalance deposit recovery
    /// @dev Precondition: A rebalance deposit recovery must exist
    /// @param recovery Types.RebalanceDepositRecovery
    function _requireRebalanceDepositRecovery() internal view returns (Types.RebalanceDepositRecovery memory recovery) {
        _requireRecoveryMode(Types.RecoveryMode.REBALANCE_DEPOSIT);
        recovery = _baseVaultStorage().s_rebalanceDepositRecovery;
    }

    /// @notice Reverts if any recovery state is pending
    function _requireNoRecovery() internal view {
        if (_baseVaultStorage().s_recoveryMode != Types.RecoveryMode.NONE) revert BaseVault__RecoveryAlreadyPending();
    }

    /// @notice Reverts if the active recovery mode does not match the expected mode
    /// @param expected The recovery mode required by the caller
    function _requireRecoveryMode(Types.RecoveryMode expected) internal view {
        if (_baseVaultStorage().s_recoveryMode != expected) revert BaseVault__NoPendingRecovery();
    }

    /// @notice Inherited and implemented by ParentVault and ChildVault
    /// @dev Precondition: rebalance deposit recovery state must exist
    /// @dev Precondition: active strategy adapter must be set
    /// @dev Precondition: the deposit into the strategy must be successful
    /// @notice The ChildVault overrides this and implements the internal _recoverFailedRebalanceDeposit
    /// @notice The ParentVault overrides this, implements the internal _recoverFailedRebalanceDeposit, and then finalizes the rebalance
    function recoverFailedRebalanceDeposit() external virtual;

    /// @dev Precondition: rebalance deposit recovery state must exist
    /// @dev Precondition: active strategy adapter must be set
    /// @dev Precondition: the deposit into the strategy must be successful
    /// @return rebalanceNonce the nonce of the recovered rebalance deposit
    /// @return amount the amount of the underlying asset rebalanced/deposited into the new strategy
    function _recoverFailedRebalanceDeposit() internal returns (uint256 rebalanceNonce, uint256 amount) {
        Types.RebalanceDepositRecovery memory recovery = _requireRebalanceDepositRecovery();
        rebalanceNonce = recovery.rebalanceNonce;

        _executeDeposit(recovery.amount, true);
        _clearRebalanceDepositRecovery();

        emit RebalanceDepositSuccess(rebalanceNonce, recovery.amount);
        amount = recovery.amount;
    }

    /// @dev Precondition: Caller must have the EMERGENCY_DRAINER_ROLE
    /// @dev Precondition: must be paused
    /// @dev Precondition: Vault must have been paused for at least EMERGENCY_DRAIN_DELAY
    /// @dev Precondition: must not be reentered
    /// @dev Withdraws all underlying asset from the vault to the emergency receiver
    /// @param revertOnFailure Whether to revert if the withdraw from strategy fails
    /// @notice If the vault has the TVL, it will be withdrawn from the strategy and transferred to the emergency receiver
    function emergencyDrain(bool revertOnFailure)
        external
        nonReentrant
        onlyRole(Roles.EMERGENCY_DRAINER_ROLE)
        whenPaused
    {
        //slither-disable-next-line timestamp
        if (block.timestamp - _baseVaultStorage().s_pausedAt < EMERGENCY_DRAIN_DELAY) {
            revert BaseVault__EmergencyDrainDelayNotMet();
        }

        if (_getTVL() > 0) _executeWithdraw(type(uint256).max, revertOnFailure);

        uint256 balance = IERC20(i_asset).balanceOf(address(this));
        address emergencyReceiver = _baseVaultStorage().s_emergencyReceiver;
        IERC20(i_asset).safeTransfer(emergencyReceiver, balance);
        emit EmergencyDrainExecuted(emergencyReceiver, balance);
    }

    /// @notice Donates the underlying asset to the active strategy without minting shares or creating a claim
    /// @param amount The amount of USDC to donate
    /// @dev This is a privileged recovery/recapitalization operation and intentionally allowed while paused.
    /// @dev Precondition: Caller must have the DONATE_OPERATOR_ROLE
    /// @dev Precondition: amount must be more than 0
    /// @dev Precondition: the strategy deposit operation must succeed
    /// @dev Precondition: the call must not be reentered
    /// @notice First-depositor captures full donation when `s_totalShares == 0` due to bootstrap pricing ignoring existing TVL
    ///         Donations should not be made before the first deposit.
    /// @notice This is an operator emergency function that can destroy the system if used improperly.
    function donate(uint256 amount) external nonReentrant onlyRole(Roles.DONATE_OPERATOR_ROLE) {
        if (amount == 0) revert BaseVault__NoZeroAmount();

        IERC20(i_asset).safeTransferFrom(msg.sender, address(this), amount);
        _executeDeposit(amount, true);

        emit Donation(msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Gets the Yieldcoin TVL if this chain is the active strategy chain
    ///         Returns 0 if this chain is not the active strategy chain
    /// @return tvl The Yieldcoin TVL
    /// @notice This needs to be overridden and implemented differently in Parent and Child Vaults to account for epoch netdeposit fails on Child
    /// @notice Returns 0 if the TVL is in transit over CCIP. This should not be read onchain when Parent state is REBALANCING
    function _getTVL() internal view virtual returns (uint256 tvl);

    /*//////////////////////////////////////////////////////////////
                             CONFIG SETTERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Pauses the vault
    /// @dev Precondition: Caller must have the PAUSER_ROLE
    /// @dev Precondition: Vault must not be paused
    /// @dev Sets the timestamp when the vault was paused
    function pause() external onlyRole(Roles.PAUSER_ROLE) {
        _pause();
        _baseVaultStorage().s_pausedAt = uint96(block.timestamp);
    }

    /// @notice Unpauses the vault
    /// @dev Precondition: Caller must have the UNPAUSER_ROLE
    /// @dev Precondition: Vault must be paused
    /// @dev Deletes the timestamp when the vault was paused
    function unpause() external onlyRole(Roles.UNPAUSER_ROLE) {
        _unpause();
        delete _baseVaultStorage().s_pausedAt;
    }

    /// @notice Sets the crosschain vaults
    /// @param chainSelectors The CCIP selectors of the chains
    /// @param vaults The addresses of the crosschain vaults
    /// @dev Precondition: Caller must have the CONFIG_OPERATOR_ROLE
    /// @dev Precondition: chainSelectors must not be empty
    /// @dev Precondition: chainSelectors and vaults must have the same length
    /// @dev Precondition: each chain selector must not be zero
    /// @dev Sets the crosschain vaults
    /// @dev Emits the CrosschainVaultSet event
    /// @notice Set a vault to address(0) to remove the crosschain vault for that chain selector
    /// @notice This can orphan in-flight CCIP messages. Operator should ensure there are no active crosschain rebalance or epoch operations in progress.
    function setCrosschainVaults(uint64[] calldata chainSelectors, address[] calldata vaults)
        external
        onlyRole(Roles.CONFIG_OPERATOR_ROLE)
    {
        if (chainSelectors.length == 0) revert BaseVault__EmptyInput();
        if (chainSelectors.length != vaults.length) revert BaseVault__InvalidInputLengths();
        for (uint256 i; i < chainSelectors.length; ++i) {
            _revertIfZeroChainSelector(chainSelectors[i]);
            _baseVaultStorage().s_crosschainVaults[chainSelectors[i]] = vaults[i];
            emit CrosschainVaultSet(chainSelectors[i], vaults[i]);
        }
    }

    /// @notice Sets the CCIP gas limit for a given chain selector
    /// @param chainSelector The CCIP selector of the chain
    /// @param gasLimit The CCIP gas limit. Set to 0 to clear the per-chain override and use the default gas limit.
    /// @dev Precondition: Caller must have the CONFIG_OPERATOR_ROLE
    /// @dev Precondition: chainSelector must not be zero
    /// @dev Sets the CCIP gas limit
    /// @dev Emits the CcipGasLimitSet event
    function setCcipGasLimit(uint64 chainSelector, uint256 gasLimit) external onlyRole(Roles.CONFIG_OPERATOR_ROLE) {
        _revertIfZeroChainSelector(chainSelector);
        _baseVaultStorage().s_ccipGasLimits[chainSelector] = gasLimit;
        emit CcipGasLimitSet(chainSelector, gasLimit);
    }

    /// @notice Sets the default CCIP gas limit
    /// @notice If a chain doesn't have a specific CCIP gas limit set, the default CCIP gas limit will be used.
    /// @param gasLimit The CCIP gas limit
    /// @dev Precondition: Caller must have the CONFIG_OPERATOR_ROLE
    /// @dev Precondition: gasLimit must not be zero
    /// @dev Sets the default CCIP gas limit
    /// @dev Emits the DefaultCcipGasLimitSet event
    function setDefaultCcipGasLimit(uint256 gasLimit) external onlyRole(Roles.CONFIG_OPERATOR_ROLE) {
        _revertIfZeroAmount(gasLimit);
        _baseVaultStorage().s_defaultCcipGasLimit = gasLimit;
        emit DefaultCcipGasLimitSet(gasLimit);
    }

    /// @notice Sets the emergency receiver
    /// @param emergencyReceiver The address that receives USDC during emergency drain
    /// @dev Precondition: Caller must have the CONFIG_OPERATOR_ROLE
    /// @dev Precondition: emergencyReceiver must not be the zero address
    /// @dev Emits the EmergencyReceiverSet event
    function setEmergencyReceiver(address emergencyReceiver) external onlyRole(Roles.CONFIG_OPERATOR_ROLE) {
        _revertIfZeroAddress(emergencyReceiver);
        _baseVaultStorage().s_emergencyReceiver = emergencyReceiver;
        emit EmergencyReceiverSet(emergencyReceiver);
    }

    /*//////////////////////////////////////////////////////////////
                             LINK OPERATOR
    //////////////////////////////////////////////////////////////*/
    /// @notice Withdraws LINK from the vault
    /// @param amount The amount of LINK to withdraw
    /// @dev Precondition: Caller must have the LINK_OPERATOR_ROLE
    /// @dev Precondition: Amount must be greater than 0
    /// @dev Withdraws LINK from the vault to the caller
    function withdrawLink(uint256 amount) external onlyRole(Roles.LINK_OPERATOR_ROLE) {
        if (amount == 0) revert BaseVault__NoZeroAmount();
        IERC20(i_link).safeTransfer(msg.sender, amount);
        emit LinkWithdrawn(msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Gets the LINK token
    /// @return link The address of the LINK token
    function getLink() external view returns (address link) {
        link = i_link;
    }

    /// @notice Gets the underlying asset token
    /// @return asset The address of the underlying asset token
    function getAsset() external view returns (address asset) {
        asset = i_asset;
    }

    /// @notice Gets the underlying asset precision factor
    /// @return assetPrecision 10 ** asset.decimals()
    function getAssetPrecision() external view returns (uint256 assetPrecision) {
        assetPrecision = i_assetPrecision;
    }

    /// @notice Gets the CCIP selector for this chain
    /// @return thisChainSelector The CCIP selector for this chain
    function getThisChainSelector() external view returns (uint64 thisChainSelector) {
        thisChainSelector = i_thisChainSelector;
    }

    /// @notice Gets the adapter registry
    /// @return adapterRegistry The address of the adapter registry
    function getAdapterRegistry() external view returns (address adapterRegistry) {
        adapterRegistry = i_adapterRegistry;
    }

    /// @notice Gets the crosschain vault address for a given chain selector
    /// @param chainSelector The CCIP selector of the chain
    /// @return vault The address of the crosschain vault
    function getCrosschainVault(uint64 chainSelector) external view returns (address vault) {
        vault = _baseVaultStorage().s_crosschainVaults[chainSelector];
    }

    /// @notice Gets the CCIP gas limit for a given chain selector
    /// @param chainSelector The CCIP selector of the chain
    /// @return gasLimit The CCIP gas limit for the chain selector
    function getCcipGasLimit(uint64 chainSelector) external view returns (uint256 gasLimit) {
        gasLimit = _baseVaultStorage().s_ccipGasLimits[chainSelector];
    }

    /// @notice Gets the default CCIP gas limit
    /// @return defaultCcipGasLimit The default CCIP gas limit
    function getDefaultCcipGasLimit() external view returns (uint256 defaultCcipGasLimit) {
        defaultCcipGasLimit = _baseVaultStorage().s_defaultCcipGasLimit;
    }

    /// @notice Gets the emergency receiver
    /// @return emergencyReceiver The address that receives the underlying asset during emergency drain
    function getEmergencyReceiver() external view returns (address emergencyReceiver) {
        emergencyReceiver = _baseVaultStorage().s_emergencyReceiver;
    }

    /// @notice Gets the timestamp when the vault was paused
    /// @return pausedAt The timestamp when the vault was paused
    /// @dev Returns 0 if the vault is not paused
    function getPausedAt() external view returns (uint256 pausedAt) {
        pausedAt = _baseVaultStorage().s_pausedAt;
    }

    /// @notice Returns the active strategy protocol adapter
    /// @return activeProtocolAdapter The address of the active strategy protocol adapter
    function getActiveProtocolAdapter() external view returns (address activeProtocolAdapter) {
        activeProtocolAdapter = _baseVaultStorage().s_activeProtocolAdapter;
    }

    /// @notice Gets the TVL of the vault
    /// @return tvl The TVL of the vault
    /// @dev Strategy chain will return tvl, non-strategy chain will return 0
    /// @notice Returns 0 if the TVL is in transit over CCIP. This should not be read onchain when Parent state is REBALANCING
    function getTVL() external view returns (uint256 tvl) {
        tvl = _getTVL();
    }

    /// @notice Gets the pending rebalance deposit recovery
    /// @return recovery Types.RebalanceDepositRecovery struct includes:
    ///         uint256 rebalanceNonce - the nonce of the rebalance
    ///         uint256 amount - the amount that needs to be rebalanced/deposited into the new strategy
    ///         uint256 createdAt - block.timestamp the recovery state was stored
    function getRebalanceDepositRecovery() external view returns (Types.RebalanceDepositRecovery memory recovery) {
        recovery = _baseVaultStorage().s_rebalanceDepositRecovery;
    }

    /// @notice Gets the active recovery mode
    /// @return recoveryMode The active recovery mode, or NONE when no recovery is active
    function getRecoveryMode() external view returns (Types.RecoveryMode recoveryMode) {
        recoveryMode = _baseVaultStorage().s_recoveryMode;
    }

    /*//////////////////////////////////////////////////////////////
                                OVERRIDE
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IERC165
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    /// @dev Authorizes UUPS implementation upgrades.
    function _authorizeUpgrade(address) internal override onlyRole(Roles.UPGRADER_ROLE) {}

    /// @dev Overrides CCIPReceiver and AccessControlDefaultAdminRulesUpgradeable
    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        override(CCIPReceiver, AccessControlDefaultAdminRulesUpgradeable)
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IAccessControlDefaultAdminRules).interfaceId
            || interfaceId == type(IAny2EVMMessageReceiver).interfaceId;
    }
}

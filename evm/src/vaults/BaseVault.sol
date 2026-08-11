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
import {BaseVaultCcipLib} from "../libraries/vaults/BaseVaultCcipLib.sol";
import {BaseVaultConfigLib} from "../libraries/vaults/BaseVaultConfigLib.sol";
import {BaseVaultStrategyLib} from "../libraries/vaults/BaseVaultStrategyLib.sol";
import {Roles} from "../libraries/Roles.sol";
import {Types} from "../libraries/Types.sol";
import {IBaseVault} from "../interfaces/vaults/IBaseVault.sol";
import {IProtocolAdapter} from "../interfaces/adapters/IProtocolAdapter.sol";

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
    /// @notice Validates that the CCIP message sender is the registered crosschain vault for the source chain
    /// @param sender The decoded address of the CCIP sender
    /// @param srcChainSelector The CCIP selector of the source chain
    /// @dev Reverts if no crosschain vault is registered for srcChainSelector
    /// @dev Reverts if sender is not the registered crosschain vault
    modifier onlyAllowedSender(address sender, uint64 srcChainSelector) {
        _onlyAllowedSender(sender, srcChainSelector);
        _;
    }

    /// @notice Validates that the CCIP message sender is the registered crosschain vault for the source chain
    /// @param sender The decoded address of the CCIP sender
    /// @param srcChainSelector The CCIP selector of the source chain
    /// @dev Reverts if no crosschain vault is registered for srcChainSelector
    /// @dev Reverts if sender is not the registered crosschain vault
    function _onlyAllowedSender(address sender, uint64 srcChainSelector) internal view virtual {
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
    /// @notice Parameters used to initialize immutable contract values
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

    /// @notice Parameters used to initialize mutable proxy state
    /// @param defaultAdmin The address of the default admin for setting roles - trusted actor in the system
    /// @param pauser The address of the pauser for pausing the vault - trusted actor in the system
    /// @param unpauser The address of the unpauser for unpausing the vault - trusted actor in the system
    /// @param configOperator The address of the config operator for setters - trusted actor in the system
    /// @param initialDefaultCcipGasLimit The initial default CCIP gas limit
    /// @param upgrader The address authorized to upgrade the vault implementation through UUPS
    struct InitParams {
        address defaultAdmin;
        address pauser;
        address unpauser;
        address configOperator;
        uint256 initialDefaultCcipGasLimit;
        address upgrader;
    }

    /// @notice Initializes immutable configuration and disables implementation initializers
    /// @param params Constructor parameters for values that are baked into the implementation bytecode
    /// @dev Reverts if params.link is the zero address
    /// @dev Reverts if params.asset is the zero address
    /// @dev Reverts if params.ccipRouter is the zero address
    /// @dev Reverts if params.adapterRegistry is the zero address
    /// @dev Reverts if params.thisChainSelector is zero
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

    /// @notice Initializes BaseVault mutable proxy state
    /// @param params Initializer parameters for roles and mutable vault configuration
    /// @dev Sets params.defaultAdmin as the initial DEFAULT_ADMIN_ROLE holder
    /// @dev Grants PAUSER_ROLE to params.pauser
    /// @dev Grants UNPAUSER_ROLE to params.unpauser
    /// @dev Grants CONFIG_OPERATOR_ROLE to params.configOperator
    /// @dev Grants UPGRADER_ROLE to params.upgrader
    /// @dev Reverts if any role-holder address is the zero address
    /// @dev Reverts if params.initialDefaultCcipGasLimit is zero
    /// @dev Reverts if called outside an initializing context
    //slither-disable-next-line naming-convention
    function __BaseVault_init(InitParams memory params) internal onlyInitializing {
        _revertIfZeroAddress(params.defaultAdmin);
        _revertIfZeroAddress(params.pauser);
        _revertIfZeroAddress(params.unpauser);
        _revertIfZeroAddress(params.configOperator);
        _revertIfZeroAddress(params.upgrader);
        _revertIfZeroAmount(params.initialDefaultCcipGasLimit);

        __Pausable_init();
        __AccessControlDefaultAdminRules_init(INITIAL_DEFAULT_ADMIN_ROLE_TRANSFER_DELAY, params.defaultAdmin);
        __ReentrancyGuardTransient_init();
        __UUPSUpgradeable_init();

        _baseVaultStorage().s_defaultCcipGasLimit = params.initialDefaultCcipGasLimit;
        _grantRole(Roles.PAUSER_ROLE, params.pauser);
        _grantRole(Roles.UNPAUSER_ROLE, params.unpauser);
        _grantRole(Roles.CONFIG_OPERATOR_ROLE, params.configOperator);
        _grantRole(Roles.UPGRADER_ROLE, params.upgrader);
    }

    /*//////////////////////////////////////////////////////////////
                                  CCIP
    //////////////////////////////////////////////////////////////*/
    /// @notice Sends underlying asset and operation data to a registered crosschain vault through CCIP
    /// @param bridgeAmount The amount of underlying asset to bridge
    /// @param destinationChainSelector The CCIP selector of the destination chain
    /// @param ccipTxType The type of CCIP transaction
    /// @param nonce The epoch nonce (EPOCH_NET_DEPOSIT/EPOCH_NET_WITHDRAW) or rebalance nonce (REBALANCE)
    /// @param protocolId The target strategy protocol ID; only meaningful when ccipTxType is REBALANCE
    /// @dev Reverts if bridgeAmount is zero
    /// @dev Reverts if destinationChainSelector is zero
    /// @dev Reverts if destinationChainSelector identifies this chain
    /// @dev Reverts if no crosschain vault is registered for destinationChainSelector
    /// @dev Requires the vault to hold enough underlying asset and LINK for the transfer and CCIP fee
    function _ccipSend(
        uint256 bridgeAmount,
        uint64 destinationChainSelector,
        Types.CcipTx ccipTxType,
        uint256 nonce,
        bytes32 protocolId
    ) internal virtual {
        BaseVaultCcipLib.send(
            _baseVaultStorage(),
            bridgeAmount,
            destinationChainSelector,
            ccipTxType,
            nonce,
            protocolId,
            i_asset,
            i_link,
            i_ccipRouter,
            i_thisChainSelector
        );
    }

    /// @notice Handles the CCIP rebalance message
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param protocolId The protocol ID of the new strategy on this chain
    /// @param amount The amount of underlying asset to deposit into the new strategy on this chain
    /// @return success Whether the deposit into the new strategy succeeded
    /// @dev Called from both ParentVault and ChildVault's `_ccipReceive` when the previous strategy chain
    ///      sends a CCIP rebalance to this new strategy chain.
    /// @dev The active adapter is set before deposit. If deposit fails, it points to the new
    ///      adapter while the rebalance remains incomplete and deposit recovery is pending.
    function _handleCCIPRebalance(uint256 rebalanceNonce, bytes32 protocolId, uint256 amount)
        internal
        returns (bool success)
    {
        address adapter = _setActiveAdapter(protocolId);
        success = _handleCCIPRebalanceDeposit(rebalanceNonce, amount, adapter);
    }

    /// @notice Deposits a received CCIP rebalance amount into the active strategy or stores recovery on failure.
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param amount The amount of underlying asset to deposit into the active strategy
    /// @param adapter The active strategy adapter, already known from _setActiveAdapter
    /// @return success Whether the deposit into the active strategy succeeded
    /// @dev Stores rebalance deposit recovery state and returns false if the adapter deposit fails
    function _handleCCIPRebalanceDeposit(uint256 rebalanceNonce, uint256 amount, address adapter)
        internal
        returns (bool success)
    {
        success = _executeDeposit(amount, false, adapter);
        if (success) {
            emit RebalanceDepositSuccess(rebalanceNonce, amount);
        } else {
            _storeRebalanceDepositRecovery(_baseVaultStorage(), rebalanceNonce, amount);
            emit RebalanceDepositFailure(rebalanceNonce, amount);
        }
    }

    /*//////////////////////////////////////////////////////////////
                         STRATEGY INTERACTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Executes a deposit to the active strategy
    /// @param amount The amount to deposit
    /// @param revertOnFailure Whether to revert if the strategy deposit fails
    /// @param activeAdapter The active strategy adapter
    /// @return success Whether the deposit succeeded
    /// @dev Reverts if activeAdapter is the zero address
    /// @dev Reverts if the adapter call fails and revertOnFailure is true
    /// @dev Returns false if the adapter call fails and revertOnFailure is false
    function _executeDeposit(uint256 amount, bool revertOnFailure, address activeAdapter)
        internal
        returns (bool success)
    {
        if (activeAdapter == address(0)) revert BaseVault__NoActiveAdapter();
        try this.tryDepositToAdapter(activeAdapter, amount) {
            success = true;
        } catch {
            if (revertOnFailure) revert BaseVault__DepositFailed(amount);
            success = false;
        }
    }

    /// @notice Transfers underlying asset to an adapter and invokes its deposit function
    /// @param adapter The active strategy adapter
    /// @param amount The amount to deposit into the adapter
    /// @dev Reverts if the caller is not this vault
    /// @dev Reverts if the underlying-asset transfer or adapter deposit fails
    function tryDepositToAdapter(address adapter, uint256 amount) external {
        if (msg.sender != address(this)) revert BaseVault__OnlySelf();

        IERC20(i_asset).safeTransfer(adapter, amount);
        IProtocolAdapter(adapter).deposit(amount);
    }

    /// @notice Executes a withdraw from the active strategy
    /// @param amount The amount to withdraw
    /// @param revertOnFailure Whether to revert if the strategy withdrawal fails
    /// @param activeAdapter The active strategy adapter
    /// @return success Whether the withdrawal succeeded
    /// @return amountOut The amount withdrawn, or zero if the withdrawal fails without reverting
    /// @dev Reverts if activeAdapter is the zero address
    /// @dev Reverts if the adapter call fails and revertOnFailure is true
    /// @dev Returns false and zero if the adapter call fails and revertOnFailure is false
    function _executeWithdraw(uint256 amount, bool revertOnFailure, address activeAdapter)
        internal
        returns (bool success, uint256 amountOut)
    {
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
    /// @dev Reverts if protocolId has no registered adapter
    /// @dev Reverts if the registered adapter is bound to a different vault
    function _setActiveAdapter(bytes32 protocolId) internal virtual returns (address adapter) {
        adapter =
            BaseVaultStrategyLib.setActiveAdapter(_baseVaultStorage(), protocolId, i_adapterRegistry, address(this));
    }

    /// @notice Clears the active strategy protocol adapter for this chain, given a known adapter
    /// @param adapter The active strategy adapter being cleared, already known by the caller
    function _clearActiveAdapter(address adapter) internal virtual {
        BaseVaultStrategyLib.clearActiveAdapter(_baseVaultStorage(), adapter);
    }

    /*//////////////////////////////////////////////////////////////
                               RECOVERY
    //////////////////////////////////////////////////////////////*/
    /// @notice Executes the active recovery mode, reverting if no recovery is pending
    /// @dev Permissionless because the operation and all inputs are fixed by stored recovery state
    /// @dev Reverts if no recovery mode is active
    /// @dev Reverts if the vault is paused
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the active recovery requires a strategy adapter that is not set
    /// @dev Reverts if the active recovery requires a local target adapter that is not registered
    /// @dev Reverts if the registered local target adapter is bound to another vault
    /// @dev Reverts if the active recovery requires an unregistered crosschain vault
    /// @dev Reverts if a strategy withdrawal used by the active recovery returns zero assets
    /// @dev Requires any strategy, token, and CCIP interactions used by the active recovery to succeed
    function executeRecovery() external virtual;

    /// @notice Reverts if any recovery state is pending
    /// @param $ BaseVault namespaced storage
    /// @dev Reverts if a recovery mode is active
    function _requireNoRecovery(BaseVaultStorage storage $) internal view {
        if ($.s_recoveryMode != Types.RecoveryMode.NONE) revert BaseVault__RecoveryAlreadyPending();
    }

    // --- REBALANCE DEPOSIT RECOVERY --- //

    /// @notice Stores recovery state for a failed rebalance deposit
    /// @param $ BaseVault namespaced storage
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param amount The amount that should have been rebalanced into the new strategy
    /// @dev The caller must ensure amount is nonzero and no other recovery mode is active
    function _storeRebalanceDepositRecovery(BaseVaultStorage storage $, uint256 rebalanceNonce, uint256 amount)
        internal
    {
        $.s_rebalanceDepositRecovery = Types.RebalanceDepositRecovery({rebalanceNonce: rebalanceNonce, amount: amount});
        $.s_recoveryMode = Types.RecoveryMode.REBALANCE_DEPOSIT;
        emit RebalanceDepositRecoveryStored(rebalanceNonce, amount);
    }

    /// @notice Retries a previously failed rebalance deposit into the active strategy
    /// @param $ BaseVault namespaced storage
    /// @return rebalanceNonce The nonce of the recovered rebalance deposit
    /// @return amount The amount of underlying asset deposited into the new strategy
    /// @dev Reverts if the active strategy adapter is not set
    /// @dev Reverts if the strategy deposit fails
    /// @dev The caller must ensure rebalance deposit recovery is active
    function _recoverFailedRebalanceDeposit(BaseVaultStorage storage $)
        internal
        returns (uint256 rebalanceNonce, uint256 amount)
    {
        Types.RebalanceDepositRecovery memory recovery = $.s_rebalanceDepositRecovery;
        rebalanceNonce = recovery.rebalanceNonce;
        amount = recovery.amount;

        _executeDeposit(amount, true, $.s_activeProtocolAdapter);
        _clearRebalanceDepositRecovery($, rebalanceNonce);

        emit RebalanceDepositSuccess(rebalanceNonce, amount);
    }

    /// @notice Clears recovery state for a failed rebalance deposit
    /// @param $ BaseVault namespaced storage
    /// @param rebalanceNonce The nonce of the rebalance deposit recovery being cleared, already known by the caller
    function _clearRebalanceDepositRecovery(BaseVaultStorage storage $, uint256 rebalanceNonce) internal {
        delete $.s_rebalanceDepositRecovery;
        $.s_recoveryMode = Types.RecoveryMode.NONE;
        emit RebalanceDepositRecoveryCleared(rebalanceNonce);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns this vault's accounted underlying-asset value
    /// @return tvl The active strategy position plus applicable vault-held recovery assets
    /// @dev Returns zero when this vault has neither an active strategy position nor applicable recovery assets
    /// @dev Overridden by ParentVault and ChildVault to account for their respective state
    /// @dev Returns zero while the active position is in transit through CCIP
    function _getTVL() internal view virtual returns (uint256 tvl);

    /*//////////////////////////////////////////////////////////////
                             CONFIG SETTERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Pauses the contract
    /// @dev Reverts if the caller does not have PAUSER_ROLE
    /// @dev Reverts if the contract is already paused
    function pause() external onlyRole(Roles.PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpauses the contract
    /// @dev Reverts if the caller does not have UNPAUSER_ROLE
    /// @dev Reverts if the contract is not paused
    function unpause() external onlyRole(Roles.UNPAUSER_ROLE) {
        _unpause();
    }

    /// @notice Sets or removes the crosschain vault registered for each supplied chain selector
    /// @param chainSelectors The CCIP selectors of the remote chains
    /// @param vaults The vault addresses, using address(0) to remove a registration
    /// @dev Reverts if the caller does not have CONFIG_OPERATOR_ROLE
    /// @dev Reverts if chainSelectors is empty
    /// @dev Reverts if chainSelectors and vaults have different lengths
    /// @dev Reverts if any chain selector is zero
    /// @dev Changing or removing a registration can orphan an in-flight CCIP message from the prior vault
    function setCrosschainVaults(uint64[] calldata chainSelectors, address[] calldata vaults)
        external
        virtual
        onlyRole(Roles.CONFIG_OPERATOR_ROLE)
    {
        BaseVaultConfigLib.setCrosschainVaults(_baseVaultStorage(), chainSelectors, vaults);
    }

    /// @notice Sets the CCIP gas limit for a given chain selector
    /// @param chainSelector The CCIP selector of the chain
    /// @param gasLimit The CCIP gas limit, or zero to clear the override and use the default
    /// @dev Reverts if the caller does not have CONFIG_OPERATOR_ROLE
    /// @dev Reverts if chainSelector is zero
    function setCcipGasLimit(uint64 chainSelector, uint256 gasLimit)
        external
        virtual
        onlyRole(Roles.CONFIG_OPERATOR_ROLE)
    {
        BaseVaultConfigLib.setCcipGasLimit(_baseVaultStorage(), chainSelector, gasLimit);
    }

    /// @notice Sets the default CCIP gas limit
    /// @param gasLimit The default CCIP gas limit
    /// @dev Used when a destination chain has no nonzero per-chain gas-limit override
    /// @dev Reverts if the caller does not have CONFIG_OPERATOR_ROLE
    /// @dev Reverts if gasLimit is zero
    function setDefaultCcipGasLimit(uint256 gasLimit) external virtual onlyRole(Roles.CONFIG_OPERATOR_ROLE) {
        BaseVaultConfigLib.setDefaultCcipGasLimit(_baseVaultStorage(), gasLimit);
    }

    /*//////////////////////////////////////////////////////////////
                             LINK OPERATOR
    //////////////////////////////////////////////////////////////*/
    /// @notice Withdraws LINK from the vault to the caller
    /// @param amount The amount of LINK to withdraw
    /// @dev Reverts if the caller does not have LINK_OPERATOR_ROLE
    /// @dev Reverts if amount is zero
    function withdrawLink(uint256 amount) external onlyRole(Roles.LINK_OPERATOR_ROLE) {
        _revertIfZeroAmount(amount);
        IERC20(i_link).safeTransfer(msg.sender, amount);
        emit LinkWithdrawn(msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns the LINK token
    /// @return link The address of the LINK token
    function getLink() external view returns (address link) {
        link = i_link;
    }

    /// @notice Returns the underlying asset token
    /// @return asset The address of the underlying asset token
    function getAsset() external view returns (address asset) {
        asset = i_asset;
    }

    /// @notice Returns the underlying asset precision factor
    /// @return assetPrecision 10 ** asset.decimals()
    function getAssetPrecision() external view returns (uint256 assetPrecision) {
        assetPrecision = i_assetPrecision;
    }

    /// @notice Returns the CCIP selector for this chain
    /// @return thisChainSelector The CCIP selector for this chain
    function getThisChainSelector() external view returns (uint64 thisChainSelector) {
        thisChainSelector = i_thisChainSelector;
    }

    /// @notice Returns the adapter registry
    /// @return adapterRegistry The address of the adapter registry
    function getAdapterRegistry() external view returns (address adapterRegistry) {
        adapterRegistry = i_adapterRegistry;
    }

    /// @notice Returns the crosschain vault address registered for a chain selector
    /// @param chainSelector The CCIP selector of the chain
    /// @return vault The registered crosschain vault address, or address(0) if none is registered
    function getCrosschainVault(uint64 chainSelector) external view returns (address vault) {
        vault = _baseVaultStorage().s_crosschainVaults[chainSelector];
    }

    /// @notice Returns the configured CCIP gas-limit override for a chain selector
    /// @param chainSelector The CCIP selector of the chain
    /// @return gasLimit The per-chain override, or zero when no override is configured
    function getCcipGasLimit(uint64 chainSelector) external view returns (uint256 gasLimit) {
        gasLimit = _baseVaultStorage().s_ccipGasLimits[chainSelector];
    }

    /// @notice Returns the default CCIP gas limit
    /// @return defaultCcipGasLimit The default CCIP gas limit
    function getDefaultCcipGasLimit() external view returns (uint256 defaultCcipGasLimit) {
        defaultCcipGasLimit = _baseVaultStorage().s_defaultCcipGasLimit;
    }

    /// @notice Returns the active strategy protocol adapter
    /// @return activeProtocolAdapter The address of the active strategy protocol adapter
    /// @dev Do not use the adapter directly as the vault's canonical TVL source; use getTVL()
    function getActiveProtocolAdapter() external view returns (address activeProtocolAdapter) {
        activeProtocolAdapter = _baseVaultStorage().s_activeProtocolAdapter;
    }

    /// @notice Returns this vault's accounted underlying-asset value
    /// @return tvl The active strategy position plus applicable vault-held recovery assets
    /// @dev Returns zero when this vault has neither an active strategy position nor applicable recovery assets
    function getTVL() external view returns (uint256 tvl) {
        tvl = _getTVL();
    }

    /// @notice Returns the pending rebalance deposit recovery state
    /// @return recovery Types.RebalanceDepositRecovery struct includes:
    ///         uint256 rebalanceNonce - the nonce of the failed rebalance deposit
    ///         uint256 amount - the amount of underlying asset to retry depositing
    function getRebalanceDepositRecovery() external view returns (Types.RebalanceDepositRecovery memory recovery) {
        recovery = _baseVaultStorage().s_rebalanceDepositRecovery;
    }

    /// @notice Returns the active recovery mode
    /// @return recoveryMode The active recovery mode, or NONE when no recovery is active
    function getRecoveryMode() external view returns (Types.RecoveryMode recoveryMode) {
        recoveryMode = _baseVaultStorage().s_recoveryMode;
    }

    /*//////////////////////////////////////////////////////////////
                                OVERRIDE
    //////////////////////////////////////////////////////////////*/
    /// @notice Authorizes a UUPS implementation upgrade
    /// @dev Reverts if the caller does not have UPGRADER_ROLE
    function _authorizeUpgrade(address) internal override onlyRole(Roles.UPGRADER_ROLE) {}

    /// @notice Returns whether this contract implements the given interface ID
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @return Whether this contract implements `interfaceId`
    /// @dev Overrides CCIPReceiver and AccessControlDefaultAdminRulesUpgradeable. Supports IERC165,
    ///      IAccessControlDefaultAdminRules, and IAny2EVMMessageReceiver interface IDs.
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

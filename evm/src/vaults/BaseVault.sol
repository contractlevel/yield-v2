// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {CCIPReceiver, IAny2EVMMessageReceiver} from "@chainlink/contracts-ccip/contracts/applications/CCIPReceiver.sol";
import {IRouterClient, Client} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";

import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {
    AccessControlDefaultAdminRules,
    IAccessControlDefaultAdminRules
} from "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Roles} from "../libraries/Roles.sol";
import {Types} from "../libraries/Types.sol";
import {IBaseVault} from "../interfaces/IBaseVault.sol";
import {IAdapterRegistry} from "../interfaces/IAdapterRegistry.sol";
import {IProtocolAdapter} from "../interfaces/IProtocolAdapter.sol";

/// @title Yieldcoin v2 BaseVault
/// @author @contractlevel
/// @notice Base contract for Parent and Child Vaults in Yieldcoin v2
abstract contract BaseVault is Pausable, AccessControlDefaultAdminRules, ReentrancyGuard, CCIPReceiver, IBaseVault {
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
    /// @dev USDC token
    address internal immutable i_usdc;
    /// @dev Registry contract for strategy protocol adapters
    address internal immutable i_adapterRegistry;

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/
    // @review order of state variables
    /// @dev Default CCIP gas limit
    uint256 internal s_defaultCcipGasLimit;
    /// @dev Mapping of chain selectors to CCIP gas limits
    mapping(uint64 chainSelector => uint256 gasLimit) s_ccipGasLimits;
    /// @dev Mapping of chain selectors to crosschain vault addresses - also trusted CCIP senders allow list
    /// @notice The Parent chain should include itself as a trusted CCIP sender and set its own vault address
    mapping(uint64 chainSelector => address vault) internal s_crosschainVaults;

    /// @dev Active strategy protocol adapter for this chain. If this is address(0), this chain is NOT the active strategy chain
    //slither-disable-next-line uninitialized-state
    address internal s_activeProtocolAdapter;

    /// @dev Timestamp when the vault was paused. Deleted when the vault is unpaused.
    /// @notice This is used for emergency recovery modes.
    uint256 internal s_pausedAt;
    /// @dev Recovery state for failed rebalance deposit operations. This can exist on Parent or Child.
    mapping(uint256 rebalanceNonce => Types.AmountRecovery recovery) internal s_rebalanceDepositRecovery;

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
        if (sender != s_crosschainVaults[srcChainSelector]) {
            revert BaseVault__InvalidSender(sender, srcChainSelector);
        }
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @notice Parameters to initialize the contract in the constructor.
    /// @param link The address of the Chainlink LINK token
    /// @param usdc The address of the USDC token
    /// @param ccipRouter The address of the CCIP router
    /// @param defaultAdmin The address of the default admin for setting roles - trusted actor in the system
    /// @param pauser The address of the pauser for pausing the vault - trusted actor in the system
    /// @param unpauser The address of the unpauser for unpausing the vault - trusted actor in the system
    /// @param configOperator The address of the config operator for setters - trusted actor in the system
    /// @param adapterRegistry The address of the Yieldcoin v2 AdapterRegistry
    /// @param thisChainSelector The CCIP selector for this chain
    struct ConstructorParams {
        address link;
        address usdc;
        address ccipRouter;
        address defaultAdmin;
        address pauser;
        address unpauser;
        address configOperator;
        address adapterRegistry;
        uint64 thisChainSelector;
    }

    /// @param params Constructor parameters
    /// @notice Grants PAUSER_ROLE to params.pauser
    /// @notice Grants UNPAUSER_ROLE to params.unpauser
    /// @notice Grants CONFIG_OPERATOR_ROLE to params.configOperator
    constructor(ConstructorParams memory params)
        CCIPReceiver(params.ccipRouter)
        AccessControlDefaultAdminRules(INITIAL_DEFAULT_ADMIN_ROLE_TRANSFER_DELAY, params.defaultAdmin)
    {
        i_thisChainSelector = params.thisChainSelector;
        i_link = params.link;
        i_usdc = params.usdc;
        i_adapterRegistry = params.adapterRegistry;
        _grantRole(Roles.PAUSER_ROLE, params.pauser);
        _grantRole(Roles.UNPAUSER_ROLE, params.unpauser);
        _grantRole(Roles.CONFIG_OPERATOR_ROLE, params.configOperator);
    }

    /*//////////////////////////////////////////////////////////////
                                  CCIP
    //////////////////////////////////////////////////////////////*/
    /// @notice Bridges USDC to a destination chain
    /// @param bridgeAmount The amount of USDC to bridge
    /// @param destinationChainSelector The CCIP selector of the destination chain
    /// @param ccipTxType The type of CCIP transaction
    /// @param txData abi.encode(epochNonce) for deposit/withdraw, or abi.encode(rebalanceNonce, newStrategy.protocolId) for rebalance
    /// @dev Precondition: Destination chain selector must be a valid crosschain vault
    function _ccipSend(
        uint256 bridgeAmount,
        uint64 destinationChainSelector,
        Types.CcipTx ccipTxType,
        bytes memory txData
    ) internal {
        /// @dev Get the vault address for receiving the message
        address vault = s_crosschainVaults[destinationChainSelector];
        /// @dev Get the CCIP gas limit for the strategy chain
        uint256 gasLimit = _getCcipGasLimit(destinationChainSelector);

        /// @dev Build the CCIP message data
        bytes memory data = abi.encode(ccipTxType, txData);

        /// @dev Build the token amounts
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: i_usdc, amount: bridgeAmount});

        /// @dev Build the CCIP message
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(vault),
            data: data,
            tokenAmounts: tokenAmounts,
            extraArgs: Client._argsToBytes(
                Client.GenericExtraArgsV2({gasLimit: gasLimit, allowOutOfOrderExecution: true})
            ),
            feeToken: i_link
        });

        uint256 fee = IRouterClient(i_ccipRouter).getFee(destinationChainSelector, message);
        IERC20(i_link).safeIncreaseAllowance(i_ccipRouter, fee);
        IERC20(i_usdc).safeIncreaseAllowance(i_ccipRouter, bridgeAmount);
        bytes32 ccipMessageId = IRouterClient(i_ccipRouter).ccipSend(destinationChainSelector, message);
        /**
         * event CCIPMessageSent(
         * uint64 indexed destChainSelector,
         * address indexed sender,
         * bytes32 indexed messageId,
         */
        emit CCIPBridged(ccipMessageId, bridgeAmount, ccipTxType);
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

    /// @notice Validates that a CCIP message delivered the vault's configured USDC token and returns the delivered amount
    /// @param message The CCIP message received from the router
    /// @return amount The amount of USDC delivered by CCIP
    /// @dev Precondition: the received token must be i_usdc
    function _validateReceivedTokenAndGetAmount(Client.Any2EVMMessage memory message)
        internal
        view
        returns (uint256 amount)
    {
        uint256 tokenAmountsLength = message.destTokenAmounts.length;
        if (tokenAmountsLength != 1) revert BaseVault__InvalidTokenAmountsLength(tokenAmountsLength, 1);

        Client.EVMTokenAmount memory tokenAmount = message.destTokenAmounts[0];
        if (tokenAmount.token != i_usdc) revert BaseVault__InvalidReceivedToken(tokenAmount.token, i_usdc);
        amount = tokenAmount.amount;
        if (amount == 0) revert BaseVault__NoZeroAmount();
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
        address activeAdapter = s_activeProtocolAdapter;
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

        IERC20(i_usdc).safeTransfer(adapter, amount);
        IProtocolAdapter(adapter).deposit(amount);
    }

    /// @notice Executes a withdraw from the active strategy
    /// @param amount The amount to withdraw
    /// @param revertOnFailure Indicates whether the call should revert if the withdraw from strategy fails or not
    /// @return amountOut The amount withdrawn. This will be 0 if revertOnFailure is false and the withdraw failed
    /// @notice This function uses a trycatch to handle cases where the withdraw from strategy fails
    function _executeWithdraw(uint256 amount, bool revertOnFailure) internal returns (uint256 amountOut) {
        address activeAdapter = s_activeProtocolAdapter;
        if (activeAdapter == address(0)) revert BaseVault__NoActiveAdapter();
        try IProtocolAdapter(activeAdapter).withdraw(amount) returns (uint256 actual) {
            amountOut = actual;
        } catch {
            if (revertOnFailure) revert BaseVault__WithdrawFailed(amount);
            amountOut = 0;
        }
    }

    // @review do we want to pass a bool for revertOnFailure?
    /// @notice Executes a rebalance by attempting to withdraw from the old strategy with _executeWithdraw. If that was successful, then attempts to rebalance with _rebalanceToNewStrategy
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param newStrategy The new strategy to rebalance to
    /// @return amountRebalanced The amount rebalanced
    /// @notice This function uses a trycatch to handle cases where the withdraw from the old strategy failed
    function _executeRebalance(uint256 rebalanceNonce, Types.Strategy memory newStrategy)
        internal
        returns (uint256 amountRebalanced)
    {
        amountRebalanced = _executeWithdraw(type(uint256).max, false);
        if (amountRebalanced > 0) {
            emit RebalanceWithdrawSuccess(rebalanceNonce, amountRebalanced);
            _rebalanceToNewStrategy(rebalanceNonce, amountRebalanced, newStrategy);
        } else {
            emit RebalanceWithdrawFailure(rebalanceNonce);
        }
    }

    /// @notice Rebalances the TVL to the new strategy
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param tvlToRebalance The TVL amount to rebalance
    /// @param newStrategy The new strategy to rebalance to
    /// @notice Handles a local rebalance on this chain or a crosschain rebalance to the new strategy chain
    function _rebalanceToNewStrategy(uint256 rebalanceNonce, uint256 tvlToRebalance, Types.Strategy memory newStrategy)
        internal
    {
        //slither-disable-next-line incorrect-equality
        if (newStrategy.chainSelector == i_thisChainSelector) {
            _setActiveAdapter(newStrategy.protocolId);

            bool success = _executeDeposit(tvlToRebalance, false);
            if (success) {
                emit RebalanceDepositSuccess(rebalanceNonce, tvlToRebalance);
            } else {
                _storeRebalanceDepositRecovery(rebalanceNonce, tvlToRebalance);
                emit RebalanceDepositFailure(rebalanceNonce, tvlToRebalance);
            }
        } else {
            s_activeProtocolAdapter = address(0);
            _ccipSend(
                tvlToRebalance,
                newStrategy.chainSelector,
                Types.CcipTx.REBALANCE,
                abi.encode(rebalanceNonce, newStrategy.protocolId)
            );
        }
    }

    /// @notice Sets the active strategy protocol adapter
    /// @param protocolId The protocol ID of the strategy
    /// @return adapter The address of the active strategy protocol adapter
    function _setActiveAdapter(bytes32 protocolId) internal returns (address adapter) {
        adapter = IAdapterRegistry(i_adapterRegistry).getAdapter(protocolId);
        if (adapter == address(0)) revert BaseVault__NoAdapterRegistered(protocolId);
        s_activeProtocolAdapter = adapter;
    }

    /*//////////////////////////////////////////////////////////////
                                RECOVERY
    //////////////////////////////////////////////////////////////*/
    /// @notice Recovery function for storing a failed rebalance deposit
    /// @notice This is called when a rebalance attempts to deposit into a new strategy and fails
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param amount The amount that should have been rebalanced into the new strategy
    /// @dev Maps the amount and the block.timestamp to the rebalance nonce
    /// @dev Emits RebalanceDepositRecoveryStored event
    /// @dev Precondition: Stored recovery should not already exist for the rebalance nonce
    /// @dev Precondition: amount should not be zero
    function _storeRebalanceDepositRecovery(uint256 rebalanceNonce, uint256 amount) internal {
        //slither-disable-next-line incorrect-equality
        if (amount == 0) revert BaseVault__ZeroRecoveryAmount();
        if (s_rebalanceDepositRecovery[rebalanceNonce].amount != 0) revert BaseVault__RecoveryAlreadyPending();

        s_rebalanceDepositRecovery[rebalanceNonce] = Types.AmountRecovery({amount: amount, createdAt: block.timestamp});
        emit RebalanceDepositRecoveryStored(rebalanceNonce, amount);
    }

    /// @notice Recovery function for clearing a failed rebalance deposit that was previously stored
    /// @notice This is called when a previously failed rebalance deposit succeeds
    /// @param rebalanceNonce The nonce of the rebalance
    /// @dev Precondition: Failed rebalance deposit should exist
    /// @dev Deletes the recovery state for the rebalance nonce
    /// @dev Emites RebalanceDepositRecoveryCleared event
    function _clearRebalanceDepositRecovery(uint256 rebalanceNonce) internal {
        //slither-disable-next-line incorrect-equality
        if (s_rebalanceDepositRecovery[rebalanceNonce].amount == 0) revert BaseVault__NoPendingRecovery();

        delete s_rebalanceDepositRecovery[rebalanceNonce];
        emit RebalanceDepositRecoveryCleared(rebalanceNonce);
    }

    // @review if this is even needed
    function _requireRebalanceDepositRecovery(uint256 rebalanceNonce)
        internal
        view
        returns (Types.AmountRecovery memory recovery)
    {
        recovery = s_rebalanceDepositRecovery[rebalanceNonce];
        //slither-disable-next-line incorrect-equality
        if (recovery.amount == 0) revert BaseVault__NoPendingRecovery();
    }

    /// @notice Inherited and implemented by ParentVault and ChildVault
    /// @param rebalanceNonce The nonce of the rebalance
    // @review continue natspec
    function recoverFailedRebalanceDeposit(uint256 rebalanceNonce) external virtual;

    function _recoverFailedRebalanceDeposit(uint256 rebalanceNonce) internal returns (uint256 amount) {
        Types.AmountRecovery memory recovery = _requireRebalanceDepositRecovery(rebalanceNonce);

        _executeDeposit(recovery.amount, true);
        _clearRebalanceDepositRecovery(rebalanceNonce);

        emit RebalanceDepositSuccess(rebalanceNonce, recovery.amount);
        return recovery.amount;
    }

    /// @dev Precondition: Caller must have the EMERGENCY_DRAINER_ROLE
    /// @dev Precondition: Vault must have been paused for at least EMERGENCY_DRAIN_DELAY
    /// @dev Withdraws all USDC from the vault to the emergency drainer
    /// @param revertOnFailure Whether to revert if the withdraw from strategy fails
    /// @notice If the vault has the TVL, it will be withdrawn from the strategy and transferred to the emergency drainer
    function emergencyDrain(bool revertOnFailure) external onlyRole(Roles.EMERGENCY_DRAINER_ROLE) {
        //slither-disable-next-line timestamp
        if (block.timestamp - s_pausedAt < EMERGENCY_DRAIN_DELAY) revert BaseVault__EmergencyDrainDelayNotMet();

        if (_getTVL() > 0) _executeWithdraw(type(uint256).max, revertOnFailure);

        uint256 balance = IERC20(i_usdc).balanceOf(address(this));
        IERC20(i_usdc).safeTransfer(msg.sender, balance); // @review instead of sending to msg.sender, send to a specific address?
        emit EmergencyDrainExecuted(msg.sender, balance);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Gets the CCIP gas limit for a given chain selector
    /// @param chainSelector The CCIP selector of the chain
    /// @return gasLimit The CCIP gas limit
    function _getCcipGasLimit(uint64 chainSelector) internal view returns (uint256) {
        uint256 gasLimit = s_ccipGasLimits[chainSelector];
        return gasLimit != 0 ? gasLimit : s_defaultCcipGasLimit;
    }

    /// @notice Gets the Yieldcoin TVL if this chain is the active strategy chain
    ///         Returns 0 if this chain is not the active strategy chain
    /// @return tvl The Yieldcoin TVL
    function _getTVL() internal view returns (uint256 tvl) {
        address activeProtocolAdapter = s_activeProtocolAdapter;
        // @review order of these, which one is used more often?
        if (activeProtocolAdapter == address(0)) tvl = 0;
        else tvl = IProtocolAdapter(activeProtocolAdapter).getTVL();
    }

    /*//////////////////////////////////////////////////////////////
                             CONFIG SETTERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Pauses the vault
    /// @dev Precondition: Caller must have the PAUSER_ROLE
    /// @dev Precondition: Vault must not be paused
    /// @dev Sets the timestamp when the vault was paused
    function pause() external onlyRole(Roles.PAUSER_ROLE) {
        _pause();
        s_pausedAt = block.timestamp;
    }

    /// @notice Unpauses the vault
    /// @dev Precondition: Caller must have the UNPAUSER_ROLE
    /// @dev Precondition: Vault must be paused
    /// @dev Deletes the timestamp when the vault was paused
    function unpause() external onlyRole(Roles.UNPAUSER_ROLE) {
        _unpause();
        delete s_pausedAt;
    }

    /// @notice Sets the crosschain vaults
    /// @param chainSelectors The CCIP selectors of the chains
    /// @param vaults The addresses of the crosschain vaults
    /// @dev Precondition: Caller must have the CONFIG_OPERATOR_ROLE
    /// @dev Precondition: chainSelectors and vaults must have the same length
    /// @dev Sets the crosschain vaults
    /// @dev Emits the CrosschainVaultSet event
    function setCrosschainVaults(uint64[] calldata chainSelectors, address[] calldata vaults)
        external
        onlyRole(Roles.CONFIG_OPERATOR_ROLE)
    {
        if (chainSelectors.length != vaults.length) revert BaseVault__InvalidInputLengths();
        for (uint256 i; i < chainSelectors.length; ++i) {
            s_crosschainVaults[chainSelectors[i]] = vaults[i];
            emit CrosschainVaultSet(chainSelectors[i], vaults[i]);
        }
    }

    /// @notice Sets the CCIP gas limit for a given chain selector
    /// @param chainSelector The CCIP selector of the chain
    /// @param gasLimit The CCIP gas limit
    /// @dev Precondition: Caller must have the CONFIG_OPERATOR_ROLE
    /// @dev Sets the CCIP gas limit
    /// @dev Emits the CcipGasLimitSet event
    function setCcipGasLimit(uint64 chainSelector, uint256 gasLimit) external onlyRole(Roles.CONFIG_OPERATOR_ROLE) {
        s_ccipGasLimits[chainSelector] = gasLimit;
        emit CcipGasLimitSet(chainSelector, gasLimit);
    }

    /// @notice Sets the default CCIP gas limit
    /// @notice If a chain doesn't have a specific CCIP gas limit set, the default CCIP gas limit will be used.
    /// @param gasLimit The CCIP gas limit
    /// @dev Precondition: Caller must have the CONFIG_OPERATOR_ROLE
    /// @dev Sets the default CCIP gas limit
    /// @dev Emits the DefaultCcipGasLimitSet event
    function setDefaultCcipGasLimit(uint256 gasLimit) external onlyRole(Roles.CONFIG_OPERATOR_ROLE) {
        s_defaultCcipGasLimit = gasLimit;
        emit DefaultCcipGasLimitSet(gasLimit);
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

    /// @notice Gets the USDC token
    /// @return usdc The address of the USDC token
    function getUsdc() external view returns (address usdc) {
        usdc = i_usdc;
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
        vault = s_crosschainVaults[chainSelector];
    }

    /// @notice Gets the CCIP gas limit for a given chain selector
    /// @param chainSelector The CCIP selector of the chain
    /// @return gasLimit The CCIP gas limit for the chain selector
    function getCcipGasLimit(uint64 chainSelector) external view returns (uint256 gasLimit) {
        gasLimit = s_ccipGasLimits[chainSelector];
    }

    /// @notice Gets the default CCIP gas limit
    /// @return defaultCcipGasLimit The default CCIP gas limit
    function getDefaultCcipGasLimit() external view returns (uint256 defaultCcipGasLimit) {
        defaultCcipGasLimit = s_defaultCcipGasLimit;
    }

    /// @notice Gets the timestamp when the vault was paused
    /// @return pausedAt The timestamp when the vault was paused
    /// @dev Returns 0 if the vault is not paused
    function getPausedAt() external view returns (uint256 pausedAt) {
        pausedAt = s_pausedAt;
    }

    /// @notice Returns the active strategy protocol adapter
    /// @return activeProtocolAdapter The address of the active strategy protocol adapter
    function getActiveProtocolAdapter() external view returns (address activeProtocolAdapter) {
        activeProtocolAdapter = s_activeProtocolAdapter;
    }

    /// @notice Gets the TVL of the vault
    /// @return tvl The TVL of the vault
    /// @dev Strategy chain will return tvl, non-strategy chain will return 0
    function getTVL() external view returns (uint256 tvl) {
        tvl = _getTVL();
    }

    /// @notice Gets the Types.AmountRecovery for a rebalanceNonce
    /// @param rebalanceNonce The nonce of the rebalance
    /// @return recovery Types.AmountRecovery struct includes:
    ///         uint256 amount - the amount that needs to be rebalanced/deposited into the new strategy
    ///         uint256 createdAt - block.timestamp the recovery state was stored
    function getRebalanceDepositRecovery(uint256 rebalanceNonce)
        external
        view
        returns (Types.AmountRecovery memory recovery)
    {
        recovery = s_rebalanceDepositRecovery[rebalanceNonce];
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
    /// @dev Overrides CCIPReceiver and AccessControlDefaultAdminRules
    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        override(CCIPReceiver, AccessControlDefaultAdminRules)
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IAccessControlDefaultAdminRules).interfaceId
            || interfaceId == type(IAny2EVMMessageReceiver).interfaceId;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

// import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
// import {IERC677Receiver} from "@chainlink/contracts/src/v0.8/shared/interfaces/IERC677Receiver.sol";
import {CCIPReceiver, IAny2EVMMessageReceiver} from "@chainlink/contracts-ccip/applications/CCIPReceiver.sol";
import {IRouterClient, Client} from "@chainlink/contracts-ccip/interfaces/IRouterClient.sol";
import {PolicyProtected, IPolicyProtected, Ownable} from "@chainlink/policy-management/core/PolicyProtected.sol";

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
abstract contract BaseVault is
    Pausable,
    AccessControlDefaultAdminRules,
    ReentrancyGuard,
    CCIPReceiver,
    PolicyProtected,
    IBaseVault
{
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Constant for the initial default admin role transfer delay
    uint48 internal constant INITIAL_DEFAULT_ADMIN_ROLE_TRANSFER_DELAY = 259200 seconds; // 3 days

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
    /// @dev Yieldcoin (YIELD) share token
    address internal immutable i_share;
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
    /// @dev WorkflowRouter routes CRE reports to this contract
    address internal s_workflowRouter;

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
    /// @param share The address of the Yieldcoin share token. This is the Vault Share CCT.
    /// @param ccipRouter The address of the CCIP router
    /// @param defaultAdmin The address of the default admin for setting roles - trusted actor in the system
    /// @param pauser The address of the pauser for pausing the vault - trusted actor in the system
    /// @param unpauser The address of the unpauser for unpausing the vault - trusted actor in the system
    /// @param configOperator The address of the config operator for setters - trusted actor in the system
    /// @param complianceOperator The address of the compliance operator for policy management - trusted actor in the system
    /// @param policyEngine The address of the Yieldcoin v2 PolicyEngine
    /// @param adapterRegistry The address of the Yieldcoin v2 AdapterRegistry
    /// @param thisChainSelector The CCIP selector for this chain
    struct ConstructorParams {
        address link;
        address usdc;
        address share;
        address ccipRouter;
        address defaultAdmin;
        address pauser;
        address unpauser;
        address configOperator;
        address complianceOperator;
        address policyEngine;
        address adapterRegistry;
        uint64 thisChainSelector;
    }

    /// @param params Constructor parameters
    constructor(ConstructorParams memory params)
        CCIPReceiver(params.ccipRouter)
        AccessControlDefaultAdminRules(INITIAL_DEFAULT_ADMIN_ROLE_TRANSFER_DELAY, params.defaultAdmin)
        PolicyProtected(params.complianceOperator, params.policyEngine)
    {
        i_thisChainSelector = params.thisChainSelector;
        i_link = params.link;
        i_usdc = params.usdc;
        i_share = params.share;
        i_adapterRegistry = params.adapterRegistry;
        _grantRole(Roles.PAUSER_ROLE, params.pauser);
        _grantRole(Roles.UNPAUSER_ROLE, params.unpauser);
        _grantRole(Roles.CONFIG_OPERATOR_ROLE, params.configOperator);
        _grantRole(Roles.COMPLIANCE_OPERATOR_ROLE, params.complianceOperator);
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
        emit USDCBridged(ccipMessageId, bridgeAmount, ccipTxType); // @review event name
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
    function _executeDeposit(uint256 amount, bool revertOnFailure) internal returns (bool success) {
        address activeAdapter = s_activeProtocolAdapter;
        if (activeAdapter == address(0)) revert BaseVault__NoActiveAdapter();
        try IProtocolAdapter(activeAdapter).deposit(amount) {
            success = true;
        } catch {
            if (revertOnFailure) revert BaseVault__DepositFailed(amount);
            success = false;
        }
    }

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
    function _storeRebalanceDepositRecovery(uint256 rebalanceNonce, uint256 amount) internal {
        if (amount == 0) revert BaseVault__ZeroRecoveryAmount();
        if (s_rebalanceDepositRecovery[rebalanceNonce].amount != 0) revert BaseVault__RecoveryAlreadyPending();

        s_rebalanceDepositRecovery[rebalanceNonce] = Types.AmountRecovery({amount: amount, createdAt: block.timestamp});
        emit RebalanceDepositRecoveryStored(rebalanceNonce, amount);
    }

    function _clearRebalanceDepositRecovery(uint256 rebalanceNonce) internal {
        if (s_rebalanceDepositRecovery[rebalanceNonce].amount == 0) revert BaseVault__NoPendingRecovery();

        delete s_rebalanceDepositRecovery[rebalanceNonce];
        emit RebalanceDepositRecoveryCleared(rebalanceNonce);
    }

    function _requireRebalanceDepositRecovery(uint256 rebalanceNonce)
        internal
        view
        returns (Types.AmountRecovery memory recovery)
    {
        recovery = s_rebalanceDepositRecovery[rebalanceNonce];
        if (recovery.amount == 0) revert BaseVault__NoPendingRecovery();
    }

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
    /// @notice Sets the workflow router
    /// @param workflowRouter The address of the workflow router
    /// @dev Precondition: Caller must have the CONFIG_OPERATOR_ROLE
    //slither-disable-next-line missing-zero-check
    function setWorkflowRouter(address workflowRouter) external onlyRole(Roles.CONFIG_OPERATOR_ROLE) {
        s_workflowRouter = workflowRouter;
        emit WorkflowRouterSet(workflowRouter);
    }

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

    /// @notice Gets the Yieldcoin share token
    /// @return share The address of the Yieldcoin share token
    function getShare() external view returns (address share) {
        share = i_share;
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

    /// @notice Gets the workflow router
    /// @return workflowRouter The address of the workflow router
    function getWorkflowRouter() external view returns (address workflowRouter) {
        workflowRouter = s_workflowRouter;
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
    /// @dev Precondition: Active protocol adapter must not be the zero address - that means this chain is the active strategy chain
    function getTVL() external view returns (uint256 tvl) {
        tvl = _getTVL();
    }

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
    /// @notice Resolves the owner() conflict between Ownable (via PolicyProtected) and
    ///         AccessControlDefaultAdminRules. Returns the default admin address.
    function owner() public view override(Ownable, AccessControlDefaultAdminRules) returns (address) {
        return AccessControlDefaultAdminRules.owner();
    }

    /// @notice Attaches a policy engine. Restricted to COMPLIANCE_OPERATOR_ROLE instead of
    ///         Ownable's onlyOwner, so policy management is governed independently of the default admin.
    function attachPolicyEngine(address policyEngine) external override onlyRole(Roles.COMPLIANCE_OPERATOR_ROLE) {
        _attachPolicyEngine(policyEngine);
    }

    // @review inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(CCIPReceiver, AccessControlDefaultAdminRules, PolicyProtected)
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IAccessControlDefaultAdminRules).interfaceId
            || interfaceId == type(IAny2EVMMessageReceiver).interfaceId
            || interfaceId == type(IPolicyProtected).interfaceId;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IPauseable} from "./IPauseable.sol";
import {Types} from "../libraries/Types.sol";

/// @title Yieldcoin v2 BaseVault Interface
/// @author @contractlevel
/// @notice Interface for the Yieldcoin v2 BaseVault
interface IBaseVault is IPauseable {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @dev Thrown when a zero amount is provided
    error BaseVault__NoZeroAmount();
    /// @dev Thrown when the emergency drain delay has not been met
    error BaseVault__EmergencyDrainDelayNotMet();

    /// @dev Thrown when the input array lengths do not match
    error BaseVault__InvalidInputLengths();

    /// @dev Thrown when the active protocol adapter is the zero address
    error BaseVault__NoActiveAdapter();
    /// @dev Thrown when an external self-call helper is called by any address other than this contract
    error BaseVault__OnlySelf();
    /// @dev Thrown when a strategy adapter deposit fails in a synchronous path
    /// @param amount The amount of USDC that failed to deposit
    error BaseVault__DepositFailed(uint256 amount);
    /// @dev Thrown when a strategy adapter withdraw fails in a synchronous path
    /// @param amount The amount of USDC that failed to withdraw
    error BaseVault__WithdrawFailed(uint256 amount);
    /// @dev Thrown when the adapter is not registered
    /// @param protocolId The ID of the protocol
    error BaseVault__NoAdapterRegistered(bytes32 protocolId);

    /// @dev Thrown when the sender is not the crosschain vault
    /// @param sender The address of the sender
    /// @param srcChainSelector The CCIP selector of the chain
    error BaseVault__InvalidSender(address sender, uint64 srcChainSelector);
    /// @dev Thrown when there is no pending recovery for the requested operation
    error BaseVault__NoPendingRecovery();
    /// @dev Thrown when a conflicting recovery record already exists
    error BaseVault__RecoveryAlreadyPending();
    /// @dev Thrown when a recovery amount is zero
    error BaseVault__ZeroRecoveryAmount();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a deposit to the strategy is successful
    /// @param epochNonce The nonce of the epoch
    /// @param amount The amount of USDC deposited
    event DepositToStrategySuccess(uint256 indexed epochNonce, uint256 indexed amount);
    /// @notice Emitted when a deposit to the strategy fails
    /// @param epochNonce The nonce of the epoch
    /// @param amount The amount of USDC deposited
    event DepositToStrategyFailure(uint256 indexed epochNonce, uint256 indexed amount);
    /// @notice Emitted when a withdraw from the strategy is successful
    /// @param epochNonce The nonce of the epoch
    /// @param amount The amount of USDC withdrawn
    event WithdrawFromStrategySuccess(uint256 indexed epochNonce, uint256 indexed amount);
    /// @notice Emitted when a withdraw from the strategy fails
    /// @param epochNonce The nonce of the epoch
    /// @param amount The amount of USDC withdrawn
    event WithdrawFromStrategyFailure(uint256 indexed epochNonce, uint256 indexed amount);

    /// @notice Emitted when a rebalance deposit to the new strategy is successful
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param amount The amount of USDC rebalanced into the new strategy
    event RebalanceDepositSuccess(uint256 indexed rebalanceNonce, uint256 indexed amount);
    /// @notice Emitted when a rebalance deposit to the new strategy fails
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param amount The amount of USDC that failed to rebalance into the new strategy
    event RebalanceDepositFailure(uint256 indexed rebalanceNonce, uint256 indexed amount);
    /// @notice Emitted when a rebalance withdraw from the old strategy is successful
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param amount The amount of USDC withdrawn from the old strategy
    event RebalanceWithdrawSuccess(uint256 indexed rebalanceNonce, uint256 indexed amount);
    /// @notice Emitted when a rebalance withdraw from the old strategy fails
    /// @param rebalanceNonce The nonce of the rebalance
    event RebalanceWithdrawFailure(uint256 indexed rebalanceNonce);

    /// @notice Emitted when USDC is bridged to a destination chain
    /// @param ccipMessageId The ID of the CCIP message
    /// @param amount The amount of USDC bridged
    /// @param ccipTxType The type of CCIP transaction
    event USDCBridged(bytes32 indexed ccipMessageId, uint256 indexed amount, Types.CcipTx indexed ccipTxType);

    /// @notice Emitted when the crosschain vaults are set by a CONFIG_OPERATOR
    /// @param chainSelector The CCIP selectors of the chain
    /// @param vault The addresses of the crosschain vault
    event CrosschainVaultSet(uint64 indexed chainSelector, address indexed vault);
    /// @notice Emitted when the CCIP gas limit is set by a CONFIG_OPERATOR
    /// @param chainSelector The CCIP selector of the chain
    /// @param gasLimit The gas limit for the CCIP send
    event CcipGasLimitSet(uint64 indexed chainSelector, uint256 indexed gasLimit);
    /// @notice Emitted when the default CCIP gas limit is set by a CONFIG_OPERATOR
    /// @param gasLimit The gas limit for the default CCIP send
    event DefaultCcipGasLimitSet(uint256 indexed gasLimit);

    /// @notice Emitted when LINK is withdrawn by a LINK_OPERATOR
    /// @param operator The address of the LINK operator
    /// @param amount The amount of LINK withdrawn
    event LinkWithdrawn(address indexed operator, uint256 indexed amount);
    /// @notice Emitted when an emergency drain is executed by an EMERGENCY_DRAINER
    /// @param drainer The address of the emergency drainer
    /// @param amount The amount of USDC drained
    event EmergencyDrainExecuted(address indexed drainer, uint256 indexed amount);
    /// @notice Emitted when failed rebalance deposit recovery state is stored
    /// @param rebalanceNonce The nonce of the failed rebalance deposit
    /// @param amount The amount of USDC to retry depositing
    event RebalanceDepositRecoveryStored(uint256 indexed rebalanceNonce, uint256 indexed amount);
    /// @notice Emitted when failed rebalance deposit recovery state is cleared
    /// @param rebalanceNonce The nonce of the recovered rebalance deposit
    event RebalanceDepositRecoveryCleared(uint256 indexed rebalanceNonce);

    /*//////////////////////////////////////////////////////////////
                               RECOVERY
    //////////////////////////////////////////////////////////////*/
    // @review add natspec for all functions
    function emergencyDrain(bool revertOnFailure) external;

    /*//////////////////////////////////////////////////////////////
                           CONFIG SETTERS
    //////////////////////////////////////////////////////////////*/
    function setCrosschainVaults(uint64[] calldata chainSelectors, address[] calldata vaults) external;
    function setCcipGasLimit(uint64 chainSelector, uint256 gasLimit) external;
    function setDefaultCcipGasLimit(uint256 gasLimit) external;

    /*//////////////////////////////////////////////////////////////
                            LINK OPERATOR
    //////////////////////////////////////////////////////////////*/
    function withdrawLink(uint256 amount) external;

    /*//////////////////////////////////////////////////////////////
                               GETTERS
    //////////////////////////////////////////////////////////////*/
    function getLink() external view returns (address link);
    function getUsdc() external view returns (address usdc);
    function getThisChainSelector() external view returns (uint64 thisChainSelector);
    function getAdapterRegistry() external view returns (address adapterRegistry);
    function getCrosschainVault(uint64 chainSelector) external view returns (address vault);
    function getCcipGasLimit(uint64 chainSelector) external view returns (uint256 gasLimit);
    function getDefaultCcipGasLimit() external view returns (uint256 defaultCcipGasLimit);
    function getPausedAt() external view returns (uint256 pausedAt);
    function getActiveProtocolAdapter() external view returns (address activeProtocolAdapter);
    function getTVL() external view returns (uint256 tvl);
    function getRebalanceDepositRecovery(uint256 rebalanceNonce)
        external
        view
        returns (Types.AmountRecovery memory recovery);
}

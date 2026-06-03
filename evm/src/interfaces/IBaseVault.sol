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
    /// @dev Thrown when the zero address is provided
    error BaseVault__NoZeroAddress();
    /// @dev Thrown when the emergency drain delay has not been met
    error BaseVault__EmergencyDrainDelayNotMet();

    /// @dev Thrown when the input array lengths do not match
    error BaseVault__InvalidInputLengths();
    /// @dev Thrown when a CCIP message delivers an unexpected number of token amounts
    /// @param receivedLength The number of token amounts delivered by CCIP
    /// @param expectedLength The expected number of token amounts
    error BaseVault__InvalidTokenAmountsLength(uint256 receivedLength, uint256 expectedLength);

    /// @dev Thrown when CCIP receive in Parent and Child Vault receives an invalid tx type
    error BaseVault__InvalidTxType(Types.CcipTx ccipTxType);

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
    /// @dev Thrown when a CCIP message does not deliver the vault's configured USDC token
    /// @param receivedToken The token address delivered by CCIP
    /// @param expectedToken The vault's configured USDC token
    error BaseVault__InvalidReceivedToken(address receivedToken, address expectedToken);
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

    /// @notice Emitted when a CCIP transfer is sent to a destination chain
    /// @param ccipMessageId The ID of the CCIP message
    /// @param amount The amount of USDC bridged
    /// @param ccipTxType The type of CCIP transaction
    event CCIPBridged(bytes32 indexed ccipMessageId, uint256 indexed amount, Types.CcipTx indexed ccipTxType);

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
    /// @notice Emitted when an emergency drain transfers USDC to the emergency receiver
    /// @param emergencyReceiver The address of the emergency receiver
    /// @param amount The amount of USDC drained
    event EmergencyDrainExecuted(address indexed emergencyReceiver, uint256 indexed amount);
    /// @notice Emitted when the emergency receiver is set by a CONFIG_OPERATOR
    /// @param emergencyReceiver The address of the emergency receiver
    event EmergencyReceiverSet(address indexed emergencyReceiver);
    /// @notice Emitted when failed rebalance deposit recovery state is stored
    /// @param rebalanceNonce The nonce of the failed rebalance deposit
    /// @param amount The amount of USDC to retry depositing
    event RebalanceDepositRecoveryStored(uint256 indexed rebalanceNonce, uint256 indexed amount);
    /// @notice Emitted when failed rebalance deposit recovery state is cleared
    /// @param rebalanceNonce The nonce of the recovered rebalance deposit
    event RebalanceDepositRecoveryCleared(uint256 indexed rebalanceNonce);
    /// @notice Emitted when USDC is donated to the active strategy without minting shares
    /// @param donor The address that donated USDC
    /// @param amount The amount of USDC donated
    event Donation(address indexed donor, uint256 indexed amount);

    /*//////////////////////////////////////////////////////////////
                               DONATION
    //////////////////////////////////////////////////////////////*/
    /// @notice Donates USDC to the active strategy without minting shares or creating a claim
    /// @param amount The amount of USDC to donate
    /// @dev Precondition: Caller must have the DONATE_OPERATOR_ROLE
    /// @dev Precondition: This vault must be on the active strategy chain
    /// @dev Precondition: Deposit into the active strategy must succeed
    function donate(uint256 amount) external;

    /*//////////////////////////////////////////////////////////////
                               RECOVERY
    //////////////////////////////////////////////////////////////*/
    /// @dev Precondition: Caller must have the EMERGENCY_DRAINER_ROLE
    /// @dev Precondition: Vault must have been paused for at least EMERGENCY_DRAIN_DELAY
    /// @dev Withdraws all USDC from the vault to the emergency receiver
    /// @param revertOnFailure Whether to revert if the withdraw from strategy fails
    /// @notice If the vault has the TVL, it will be withdrawn from the strategy and transferred to the emergency receiver
    function emergencyDrain(bool revertOnFailure) external;

    /*//////////////////////////////////////////////////////////////
                           CONFIG SETTERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets the crosschain vaults
    /// @param chainSelectors The CCIP selectors of the chains
    /// @param vaults The addresses of the crosschain vaults
    /// @dev Precondition: Caller must have the CONFIG_OPERATOR_ROLE
    /// @dev Precondition: chainSelectors and vaults must have the same length
    /// @dev Sets the crosschain vaults
    /// @dev Emits the CrosschainVaultSet event
    function setCrosschainVaults(uint64[] calldata chainSelectors, address[] calldata vaults) external;
    /// @notice Sets the CCIP gas limit for a given chain selector
    /// @param chainSelector The CCIP selector of the chain
    /// @param gasLimit The CCIP gas limit
    /// @dev Precondition: Caller must have the CONFIG_OPERATOR_ROLE
    /// @dev Sets the CCIP gas limit
    /// @dev Emits the CcipGasLimitSet event
    function setCcipGasLimit(uint64 chainSelector, uint256 gasLimit) external;
    /// @notice Sets the default CCIP gas limit
    /// @notice If a chain doesn't have a specific CCIP gas limit set, the default CCIP gas limit will be used.
    /// @param gasLimit The CCIP gas limit
    /// @dev Precondition: Caller must have the CONFIG_OPERATOR_ROLE
    /// @dev Sets the default CCIP gas limit
    /// @dev Emits the DefaultCcipGasLimitSet event
    function setDefaultCcipGasLimit(uint256 gasLimit) external;
    /// @notice Sets the emergency receiver
    /// @param emergencyReceiver The address that receives USDC during emergency drain
    /// @dev Precondition: Caller must have the CONFIG_OPERATOR_ROLE
    /// @dev Precondition: emergencyReceiver must not be the zero address
    /// @dev Emits the EmergencyReceiverSet event
    function setEmergencyReceiver(address emergencyReceiver) external;

    /*//////////////////////////////////////////////////////////////
                            LINK OPERATOR
    //////////////////////////////////////////////////////////////*/
    /// @notice Withdraws LINK from the vault
    /// @param amount The amount of LINK to withdraw
    /// @dev Precondition: Caller must have the LINK_OPERATOR_ROLE
    /// @dev Precondition: Amount must be greater than 0
    /// @dev Withdraws LINK from the vault to the caller
    function withdrawLink(uint256 amount) external;

    /*//////////////////////////////////////////////////////////////
                               GETTERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Gets the LINK token
    /// @return link The address of the LINK token
    function getLink() external view returns (address link);
    /// @notice Gets the USDC token
    /// @return usdc The address of the USDC token
    function getUsdc() external view returns (address usdc);
    /// @notice Gets the CCIP selector for this chain
    /// @return thisChainSelector The CCIP selector for this chain
    function getThisChainSelector() external view returns (uint64 thisChainSelector);
    /// @notice Gets the adapter registry
    /// @return adapterRegistry The address of the adapter registry
    function getAdapterRegistry() external view returns (address adapterRegistry);
    /// @notice Gets the crosschain vault address for a given chain selector
    /// @param chainSelector The CCIP selector of the chain
    /// @return vault The address of the crosschain vault
    function getCrosschainVault(uint64 chainSelector) external view returns (address vault);
    /// @notice Gets the CCIP gas limit for a given chain selector
    /// @param chainSelector The CCIP selector of the chain
    /// @return gasLimit The CCIP gas limit for the chain selector
    function getCcipGasLimit(uint64 chainSelector) external view returns (uint256 gasLimit);
    /// @notice Gets the default CCIP gas limit
    /// @return defaultCcipGasLimit The default CCIP gas limit
    function getDefaultCcipGasLimit() external view returns (uint256 defaultCcipGasLimit);
    /// @notice Gets the emergency receiver
    /// @return emergencyReceiver The address that receives USDC during emergency drain
    function getEmergencyReceiver() external view returns (address emergencyReceiver);
    /// @notice Gets the timestamp when the vault was paused
    /// @return pausedAt The timestamp when the vault was paused
    /// @dev Returns 0 if the vault is not paused
    function getPausedAt() external view returns (uint256 pausedAt);
    /// @notice Returns the active strategy protocol adapter
    /// @return activeProtocolAdapter The address of the active strategy protocol adapter
    function getActiveProtocolAdapter() external view returns (address activeProtocolAdapter);
    /// @notice Gets the TVL of the vault
    /// @return tvl The TVL of the vault
    /// @dev Strategy chain will return tvl, non-strategy chain will return 0
    function getTVL() external view returns (uint256 tvl);
    /// @notice Gets the pending rebalance deposit recovery
    /// @return recovery Types.RebalanceDepositRecovery struct includes:
    ///         uint256 rebalanceNonce - the nonce of the rebalance
    ///         uint256 amount - the amount that needs to be rebalanced/deposited into the new strategy
    ///         uint256 createdAt - block.timestamp the recovery state was stored
    function getRebalanceDepositRecovery() external view returns (Types.RebalanceDepositRecovery memory recovery);
}

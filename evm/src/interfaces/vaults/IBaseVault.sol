// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IPauseable} from "../common/IPauseable.sol";
import {Types} from "../../libraries/Types.sol";

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
    /// @dev Thrown when the zero chain selector is provided
    error BaseVault__NoZeroChainSelector();
    /// @dev Thrown when an input array is empty
    error BaseVault__EmptyInput();
    /// @dev Thrown when the input array lengths do not match
    error BaseVault__InvalidInputLengths();
    /// @dev Thrown when a CCIP message delivers an unexpected number of token amounts
    /// @param receivedLength The number of token amounts delivered by CCIP
    /// @param expectedLength The expected number of token amounts
    error BaseVault__InvalidTokenAmountsLength(uint256 receivedLength, uint256 expectedLength);

    /// @dev Thrown when CCIP receive in Parent and Child Vault receives an invalid tx type
    /// @param ccipTxType The unrecognized CCIP transaction type decoded from the message
    error BaseVault__InvalidTxType(Types.CcipTx ccipTxType);

    /// @dev Thrown when the active protocol adapter is the zero address
    error BaseVault__NoActiveAdapter();
    /// @dev Thrown when an external self-call helper is called by any address other than this contract
    error BaseVault__OnlySelf();
    /// @dev Thrown when a strategy adapter deposit fails in a synchronous path
    /// @param amount The amount of asset that failed to deposit
    error BaseVault__DepositFailed(uint256 amount);
    /// @dev Thrown when a strategy adapter withdraw fails in a synchronous path
    /// @param amount The amount of asset that failed to withdraw
    error BaseVault__WithdrawFailed(uint256 amount);
    /// @dev Thrown when the adapter is not registered
    /// @param protocolId The ID of the protocol
    error BaseVault__NoAdapterRegistered(bytes32 protocolId);
    /// @dev Thrown when a registered adapter is bound to a different vault
    /// @param adapter The registered adapter address
    /// @param actualVault The vault address reported by the adapter
    /// @param expectedVault The vault address expected by this vault
    error BaseVault__InvalidAdapterVault(address adapter, address actualVault, address expectedVault);

    /// @dev Thrown when the sender is not the crosschain vault
    /// @param sender The address of the sender
    /// @param srcChainSelector The CCIP selector of the chain
    error BaseVault__InvalidSender(address sender, uint64 srcChainSelector);
    /// @dev Thrown when a CCIP message originates from an unexpected source chain
    /// @param sourceChainSelector The source chain selector supplied by CCIP
    /// @param expectedSourceChainSelector The source chain selector expected by the receiving vault
    error BaseVault__InvalidSourceChainSelector(uint64 sourceChainSelector, uint64 expectedSourceChainSelector);
    /// @dev Thrown when the destination chain selector is zero or equals the current chain selector
    /// @param destinationChainSelector The invalid destination chain selector
    error BaseVault__InvalidDestinationChainSelector(uint64 destinationChainSelector);
    /// @dev Thrown when no crosschain vault is registered for the destination chain selector
    /// @param destinationChainSelector The destination chain selector with no registered vault
    error BaseVault__DestinationVaultNotSet(uint64 destinationChainSelector);
    /// @dev Thrown when a CCIP message does not deliver the vault's configured asset token
    /// @param receivedToken The token address delivered by CCIP
    /// @param expectedToken The vault's configured asset token
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
    /// @param amount The amount of asset deposited
    event EpochDepositToStrategySuccess(uint256 indexed epochNonce, uint256 indexed amount);
    /// @notice Emitted when a withdraw from the strategy is successful
    /// @param epochNonce The nonce of the epoch
    /// @param amount The amount of asset withdrawn
    event EpochWithdrawFromStrategySuccess(uint256 indexed epochNonce, uint256 indexed amount);

    /// @notice Emitted when a rebalance deposit to the new strategy is successful
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param amount The amount of asset rebalanced into the new strategy
    event RebalanceDepositSuccess(uint256 indexed rebalanceNonce, uint256 indexed amount);
    /// @notice Emitted when a rebalance deposit to the new strategy fails
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param amount The amount of asset that failed to rebalance into the new strategy
    event RebalanceDepositFailure(uint256 indexed rebalanceNonce, uint256 indexed amount);
    /// @notice Emitted when a rebalance withdraw from the old strategy is successful
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param amount The amount of asset withdrawn from the old strategy
    event RebalanceWithdrawSuccess(uint256 indexed rebalanceNonce, uint256 indexed amount);
    /// @notice Emitted when the active protocol adapter is set
    /// @param protocolId The protocol ID of the active strategy
    /// @param adapter The active protocol adapter
    event ActiveProtocolAdapterSet(bytes32 indexed protocolId, address indexed adapter);
    /// @notice Emitted when the active protocol adapter is cleared
    /// @param adapter The previously active protocol adapter
    event ActiveProtocolAdapterCleared(address indexed adapter);

    /// @notice Emitted when a CCIP transfer is sent to a destination chain
    /// @param ccipMessageId The ID of the CCIP message
    /// @param destinationChainSelector The CCIP selector of the destination chain
    /// @param ccipTxType The type of CCIP transaction
    event CCIPBridged(
        bytes32 indexed ccipMessageId, uint64 indexed destinationChainSelector, Types.CcipTx indexed ccipTxType
    );
    /// @notice Emitted when a CCIP transfer is received and handled
    /// @param ccipMessageId The ID of the CCIP message
    /// @param sourceChainSelector The CCIP selector of the source chain
    /// @param ccipTxType The type of CCIP transaction
    event CCIPReceived(
        bytes32 indexed ccipMessageId, uint64 indexed sourceChainSelector, Types.CcipTx indexed ccipTxType
    );

    /// @notice Emitted when the crosschain vault for a chain selector is set or removed
    /// @param chainSelector The CCIP selector of the remote chain
    /// @param vault The registered vault address, or address(0) if the registration was removed
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
    /// @notice Emitted when failed rebalance deposit recovery state is stored
    /// @param rebalanceNonce The nonce of the failed rebalance deposit
    /// @param amount The amount of asset to retry depositing
    event RebalanceDepositRecoveryStored(uint256 indexed rebalanceNonce, uint256 indexed amount);
    /// @notice Emitted when failed rebalance deposit recovery state is cleared
    /// @param rebalanceNonce The nonce of the recovered rebalance deposit
    event RebalanceDepositRecoveryCleared(uint256 indexed rebalanceNonce);
    /*//////////////////////////////////////////////////////////////
                               RECOVERY
    //////////////////////////////////////////////////////////////*/
    /// @notice Executes the active recovery mode, reverting if no recovery is pending
    /// @dev Permissionless because the operation and all inputs are fixed by stored recovery state
    /// @dev Reverts if no recovery mode is active
    /// @dev Reverts if the vault is paused
    /// @dev Reverts if the call is reentered
    function executeRecovery() external;

    /*//////////////////////////////////////////////////////////////
                           CONFIG SETTERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets or removes the crosschain vault registered for each supplied chain selector
    /// @param chainSelectors The CCIP selectors of the remote chains
    /// @param vaults The vault addresses, using address(0) to remove a registration
    /// @dev Reverts if the caller does not have CONFIG_OPERATOR_ROLE
    /// @dev Reverts if chainSelectors is empty
    /// @dev Reverts if chainSelectors and vaults have different lengths
    /// @dev Reverts if any chain selector is zero
    /// @dev Changing or removing a registration can orphan an in-flight CCIP message from the prior vault
    function setCrosschainVaults(uint64[] calldata chainSelectors, address[] calldata vaults) external;
    /// @notice Sets the CCIP gas limit for a given chain selector
    /// @param chainSelector The CCIP selector of the chain
    /// @param gasLimit The CCIP gas limit, or zero to clear the override and use the default
    /// @dev Reverts if the caller does not have CONFIG_OPERATOR_ROLE
    /// @dev Reverts if chainSelector is zero
    function setCcipGasLimit(uint64 chainSelector, uint256 gasLimit) external;
    /// @notice Sets the default CCIP gas limit
    /// @param gasLimit The default CCIP gas limit
    /// @dev Used when a destination chain has no nonzero per-chain gas-limit override
    /// @dev Reverts if the caller does not have CONFIG_OPERATOR_ROLE
    /// @dev Reverts if gasLimit is zero
    function setDefaultCcipGasLimit(uint256 gasLimit) external;
    /*//////////////////////////////////////////////////////////////
                            LINK OPERATOR
    //////////////////////////////////////////////////////////////*/
    /// @notice Withdraws LINK from the vault to the caller
    /// @param amount The amount of LINK to withdraw
    /// @dev Reverts if the caller does not have LINK_OPERATOR_ROLE
    /// @dev Reverts if amount is zero
    function withdrawLink(uint256 amount) external;

    /*//////////////////////////////////////////////////////////////
                               GETTERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns the LINK token
    /// @return link The address of the LINK token
    function getLink() external view returns (address link);
    /// @notice Returns the underlying asset token
    /// @return asset The address of the underlying asset token
    function getAsset() external view returns (address asset);
    /// @notice Returns the underlying asset precision factor
    /// @return assetPrecision 10 ** asset.decimals()
    function getAssetPrecision() external view returns (uint256 assetPrecision);
    /// @notice Returns the CCIP selector for this chain
    /// @return thisChainSelector The CCIP selector for this chain
    function getThisChainSelector() external view returns (uint64 thisChainSelector);
    /// @notice Returns the adapter registry
    /// @return adapterRegistry The address of the adapter registry
    function getAdapterRegistry() external view returns (address adapterRegistry);
    /// @notice Returns the crosschain vault address registered for a chain selector
    /// @param chainSelector The CCIP selector of the chain
    /// @return vault The registered crosschain vault address, or address(0) if none is registered
    function getCrosschainVault(uint64 chainSelector) external view returns (address vault);
    /// @notice Returns the effective CCIP gas limit for a chain selector
    /// @param chainSelector The CCIP selector of the chain
    /// @return gasLimit The per-chain override when nonzero, otherwise the default CCIP gas limit
    function getCcipGasLimit(uint64 chainSelector) external view returns (uint256 gasLimit);
    /// @notice Returns the default CCIP gas limit
    /// @return defaultCcipGasLimit The default CCIP gas limit
    function getDefaultCcipGasLimit() external view returns (uint256 defaultCcipGasLimit);
    /// @notice Returns the active strategy protocol adapter
    /// @return activeProtocolAdapter The address of the active strategy protocol adapter
    /// @dev Do not use the adapter directly as the vault's canonical TVL source; use getTVL()
    function getActiveProtocolAdapter() external view returns (address activeProtocolAdapter);
    /// @notice Returns the underlying-asset value of this vault's active strategy position
    /// @return tvl The active position value, or zero when this vault is not on the active strategy chain
    function getTVL() external view returns (uint256 tvl);
    /// @notice Returns the pending rebalance deposit recovery state
    /// @return recovery Types.RebalanceDepositRecovery struct includes:
    ///         uint256 rebalanceNonce - the nonce of the failed rebalance deposit
    ///         uint256 amount - the amount of underlying asset to retry depositing
    function getRebalanceDepositRecovery() external view returns (Types.RebalanceDepositRecovery memory recovery);
    /// @notice Returns the active recovery mode
    /// @return recoveryMode The active recovery mode, or NONE when no recovery is active
    function getRecoveryMode() external view returns (Types.RecoveryMode recoveryMode);
}

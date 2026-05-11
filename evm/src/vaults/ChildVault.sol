// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseVault} from "./BaseVault.sol";

import {IChildVault} from "../interfaces/IChildVault.sol";
import {Types} from "../libraries/Types.sol";
import {Roles} from "../libraries/Roles.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Client} from "@chainlink/contracts-ccip/interfaces/IRouterClient.sol";

/// @title Yieldcoin v2 ChildVault
/// @author @contractlevel
/// @notice ChildVault is a contract that inherits from BaseVault. It's used to interact with Strategy protocols and communicate with the Parent and other ChildVaults across chains.
contract ChildVault is BaseVault, IChildVault {
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                              IMMUTABLE
    //////////////////////////////////////////////////////////////*/
    /// @dev CCIP selector for the parent chain
    uint64 internal immutable i_parentChainSelector;

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/
    /// @dev Recovery state for failed epoch deposit operations
    mapping(uint256 epochNonce => Types.AmountRecovery recovery) internal s_epochDepositRecovery;
    /// @dev Recovery state for failed epoch withdraw operations
    mapping(uint256 epochNonce => Types.AmountRecovery recovery) internal s_epochWithdrawRecovery;
    /// @dev Recovery state for failed rebalance withdraw operations
    mapping(uint256 rebalanceNonce => Types.RebalanceWithdrawRecovery recovery) internal s_rebalanceWithdrawRecovery;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @param params Base Vault Constructor parameters
    /// @param parentChainSelector CCIP selector for the parent chain
    constructor(BaseVault.ConstructorParams memory params, uint64 parentChainSelector) BaseVault(params) {
        i_parentChainSelector = parentChainSelector;
    }

    /*//////////////////////////////////////////////////////////////
                                  CCIP
    //////////////////////////////////////////////////////////////*/
    /// @notice Receives CCIP messages
    /// @param message Any2EVMMessage.
    /// @dev Precondition: the message must be sent by an allowed sender (a crosschain vault mapped to an allowed source chain selector)
    function _ccipReceive(Client.Any2EVMMessage memory message)
        internal
        override
        nonReentrant
        onlyAllowedSender(abi.decode(message.sender, (address)), message.sourceChainSelector)
    {
        /// @dev data decodes to a uint256 epochNonce for deposits/withdraws and a (uint256 rebalanceNonce, bytes32 protocolId) for rebalances
        (Types.CcipTx ccipTxType, bytes memory data) = abi.decode(message.data, (Types.CcipTx, bytes));

        if (ccipTxType == Types.CcipTx.DEPOSIT) {
            uint256 epochNonce = abi.decode(data, (uint256));
            _handleCCIPDeposit(epochNonce, message.destTokenAmounts[0].amount);
        }
        /// @dev see BaseVault::_handleCCIPRebalance
        if (ccipTxType == Types.CcipTx.REBALANCE) {
            (uint256 rebalanceNonce, bytes32 protocolId) = abi.decode(data, (uint256, bytes32));
            _handleCCIPRebalance(rebalanceNonce, protocolId, message.destTokenAmounts[0].amount);
        }
    }

    /// @notice Handles the CCIP deposit message
    /// @notice This will only be implemented in the ChildVault.
    ///         The ParentVault sends a CCIP deposit to the active strategy chain when an epoch's net flow is positive. (more deposits than withdraws)
    /// @param epochNonce The nonce of the epoch
    /// @param amount The amount of USDC that was bridged to deposit into the active strategy on this child chain
    function _handleCCIPDeposit(uint256 epochNonce, uint256 amount) internal {
        bool success = _executeDeposit(amount, false);
        if (success) {
            emit DepositToStrategySuccess(epochNonce, amount);
        } else {
            _storeEpochDepositRecovery(epochNonce, amount);
            emit DepositToStrategyFailure(epochNonce, amount);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                  CRE
    //////////////////////////////////////////////////////////////*/
    /// @notice Executes the epoch withdraw from a strategy
    /// @notice This is called by the WorkflowRouter when net flow is negative (more withdraws than deposits)
    /// @param epochNonce The nonce of the epoch
    /// @param amount The amount of USDC that was withdrawn from the active strategy
    /// @dev Precondition: Caller must have the EPOCH_OPERATOR_ROLE
    function executeEpochWithdraw(uint256 epochNonce, uint256 amount) external onlyRole(Roles.EPOCH_OPERATOR_ROLE) {
        uint256 amountOut = _executeWithdraw(amount, false);
        if (amountOut > 0) {
            emit WithdrawFromStrategySuccess(epochNonce, amountOut);
            _ccipSend(amountOut, i_parentChainSelector, Types.CcipTx.WITHDRAW, abi.encode(epochNonce));
        } else {
            _storeEpochWithdrawRecovery(epochNonce, amount);
            emit WithdrawFromStrategyFailure(epochNonce, amount);
        }
    }

    /// @notice This is called by the WorkflowRouter
    /// @notice Withdraws the entire tvl from the active strategy protocol adapter and sends it to the new strategy
    // @review whether this should be in the BaseVault. An external version of this function (ie this) shouldn't because if a rebalance needs to be executed on the parent, this is what happens:
    /// - CRE workflow writes to parent
    /// - if parent == strategy: _executeWithdraw and _rebalanceToNewStrategy
    /// - if parent != strategy: CRE workflow writes to strategy (ie THIS call)
    function executeRebalance(uint256 rebalanceNonce, Types.Strategy memory newStrategy)
        external
        onlyRole(Roles.REBALANCE_OPERATOR_ROLE)
    {
        uint256 amountRebalanced = _executeRebalance(rebalanceNonce, newStrategy);
        if (amountRebalanced == 0) {
            _storeRebalanceWithdrawRecovery(rebalanceNonce, newStrategy);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                RECOVERY
    //////////////////////////////////////////////////////////////*/
    /// @notice Stores recovery state for a failed epoch deposit
    /// @param epochNonce The epoch nonce of the failed deposit
    /// @param amount The amount of USDC to retry depositing
    /// @dev Precondition: amount must not be zero
    /// @dev Precondition: epoch deposit recovery state must not already exist for the epoch
    /// @dev Precondition: epoch withdraw recovery state must not already exist for the epoch
    function _storeEpochDepositRecovery(uint256 epochNonce, uint256 amount) internal {
        if (amount == 0) revert BaseVault__ZeroRecoveryAmount();
        if (s_epochDepositRecovery[epochNonce].amount != 0) revert BaseVault__RecoveryAlreadyPending();
        if (s_epochWithdrawRecovery[epochNonce].amount != 0) revert BaseVault__RecoveryAlreadyPending();

        s_epochDepositRecovery[epochNonce] = Types.AmountRecovery({amount: amount, createdAt: block.timestamp});
        emit EpochDepositRecoveryStored(epochNonce, amount);
    }

    /// @notice Clears recovery state for a failed epoch deposit
    /// @param epochNonce The epoch nonce of the recovered deposit
    /// @dev Precondition: epoch deposit recovery state must exist
    function _clearEpochDepositRecovery(uint256 epochNonce) internal {
        if (s_epochDepositRecovery[epochNonce].amount == 0) revert BaseVault__NoPendingRecovery();

        delete s_epochDepositRecovery[epochNonce];
        emit EpochDepositRecoveryCleared(epochNonce);
    }

    /// @notice Requires and returns failed epoch deposit recovery state
    /// @param epochNonce The epoch nonce to query
    /// @return recovery The stored epoch deposit recovery state
    /// @dev Precondition: epoch deposit recovery state must exist
    function _requireEpochDepositRecovery(uint256 epochNonce)
        internal
        view
        returns (Types.AmountRecovery memory recovery)
    {
        recovery = s_epochDepositRecovery[epochNonce];
        if (recovery.amount == 0) revert BaseVault__NoPendingRecovery();
    }

    /// @notice Stores recovery state for a failed epoch withdraw
    /// @param epochNonce The epoch nonce of the failed withdraw
    /// @param amount The amount of USDC to retry withdrawing
    /// @dev Precondition: amount must not be zero
    /// @dev Precondition: epoch withdraw recovery state must not already exist for the epoch
    /// @dev Precondition: epoch deposit recovery state must not already exist for the epoch
    function _storeEpochWithdrawRecovery(uint256 epochNonce, uint256 amount) internal {
        if (amount == 0) revert BaseVault__ZeroRecoveryAmount();
        if (s_epochWithdrawRecovery[epochNonce].amount != 0) revert BaseVault__RecoveryAlreadyPending();
        if (s_epochDepositRecovery[epochNonce].amount != 0) revert BaseVault__RecoveryAlreadyPending();

        s_epochWithdrawRecovery[epochNonce] = Types.AmountRecovery({amount: amount, createdAt: block.timestamp});
        emit EpochWithdrawRecoveryStored(epochNonce, amount);
    }

    /// @notice Clears recovery state for a failed epoch withdraw
    /// @param epochNonce The epoch nonce of the recovered withdraw
    /// @dev Precondition: epoch withdraw recovery state must exist
    function _clearEpochWithdrawRecovery(uint256 epochNonce) internal {
        if (s_epochWithdrawRecovery[epochNonce].amount == 0) revert BaseVault__NoPendingRecovery();

        delete s_epochWithdrawRecovery[epochNonce];
        emit EpochWithdrawRecoveryCleared(epochNonce);
    }

    /// @notice Requires and returns failed epoch withdraw recovery state
    /// @param epochNonce The epoch nonce to query
    /// @return recovery The stored epoch withdraw recovery state
    /// @dev Precondition: epoch withdraw recovery state must exist
    function _requireEpochWithdrawRecovery(uint256 epochNonce)
        internal
        view
        returns (Types.AmountRecovery memory recovery)
    {
        recovery = s_epochWithdrawRecovery[epochNonce];
        if (recovery.amount == 0) revert BaseVault__NoPendingRecovery();
    }

    /// @notice Stores recovery state for a failed rebalance withdraw
    /// @param rebalanceNonce The rebalance nonce of the failed withdraw
    /// @param strategy The target strategy to continue the rebalance into after withdraw succeeds
    /// @dev Precondition: strategy chain selector must not be zero
    /// @dev Precondition: rebalance withdraw recovery state must not already exist for the rebalance
    function _storeRebalanceWithdrawRecovery(uint256 rebalanceNonce, Types.Strategy memory strategy) internal {
        if (strategy.chainSelector == 0) revert ChildVault__InvalidRecoveryStrategy();
        if (s_rebalanceWithdrawRecovery[rebalanceNonce].strategy.chainSelector != 0) {
            revert BaseVault__RecoveryAlreadyPending();
        }

        s_rebalanceWithdrawRecovery[rebalanceNonce] =
            Types.RebalanceWithdrawRecovery({strategy: strategy, createdAt: block.timestamp});
        emit RebalanceWithdrawRecoveryStored(rebalanceNonce, strategy.protocolId, strategy.chainSelector);
    }

    /// @notice Clears recovery state for a failed rebalance withdraw
    /// @param rebalanceNonce The rebalance nonce of the recovered withdraw
    /// @dev Precondition: rebalance withdraw recovery state must exist
    function _clearRebalanceWithdrawRecovery(uint256 rebalanceNonce) internal {
        if (s_rebalanceWithdrawRecovery[rebalanceNonce].strategy.chainSelector == 0) {
            revert BaseVault__NoPendingRecovery();
        }

        delete s_rebalanceWithdrawRecovery[rebalanceNonce];
        emit RebalanceWithdrawRecoveryCleared(rebalanceNonce);
    }

    /// @notice Requires and returns failed rebalance withdraw recovery state
    /// @param rebalanceNonce The rebalance nonce to query
    /// @return recovery The stored rebalance withdraw recovery state
    /// @dev Precondition: rebalance withdraw recovery state must exist
    function _requireRebalanceWithdrawRecovery(uint256 rebalanceNonce)
        internal
        view
        returns (Types.RebalanceWithdrawRecovery memory recovery)
    {
        recovery = s_rebalanceWithdrawRecovery[rebalanceNonce];
        if (recovery.strategy.chainSelector == 0) revert BaseVault__NoPendingRecovery();
    }

    /// @notice Recovers a failed epoch deposit into the active Child strategy
    /// @param epochNonce The epoch nonce of the failed deposit
    /// @dev Precondition: epoch deposit recovery state must exist
    /// @dev Precondition: active strategy adapter must be set
    function recoverFailedEpochDeposit(uint256 epochNonce) external {
        Types.AmountRecovery memory recovery = _requireEpochDepositRecovery(epochNonce);

        _executeDeposit(recovery.amount, true);
        _clearEpochDepositRecovery(epochNonce);

        emit DepositToStrategySuccess(epochNonce, recovery.amount);
    }

    /// @notice Recovers a failed epoch withdraw from the active Child strategy
    /// @param epochNonce The epoch nonce of the failed withdraw
    /// @dev Precondition: epoch withdraw recovery state must exist
    /// @dev Precondition: active strategy adapter must be set
    function recoverFailedEpochWithdraw(uint256 epochNonce) external {
        Types.AmountRecovery memory recovery = _requireEpochWithdrawRecovery(epochNonce);

        uint256 amountOut = _executeWithdraw(recovery.amount, true);
        if (amountOut == 0) revert BaseVault__ZeroRecoveryAmount();

        _clearEpochWithdrawRecovery(epochNonce);
        emit WithdrawFromStrategySuccess(epochNonce, amountOut);
        _ccipSend(amountOut, i_parentChainSelector, Types.CcipTx.WITHDRAW, abi.encode(epochNonce));
    }

    /// @notice Recovers a failed rebalance withdraw from the active Child strategy
    /// @param rebalanceNonce The nonce of the failed rebalance withdraw
    /// @dev Precondition: rebalance withdraw recovery state must exist
    /// @dev Precondition: active strategy adapter must be set
    function recoverFailedRebalanceWithdraw(uint256 rebalanceNonce) external {
        Types.RebalanceWithdrawRecovery memory recovery = _requireRebalanceWithdrawRecovery(rebalanceNonce);

        uint256 amountRebalanced = _executeWithdraw(type(uint256).max, true);
        if (amountRebalanced == 0) revert BaseVault__ZeroRecoveryAmount();

        _clearRebalanceWithdrawRecovery(rebalanceNonce);
        emit RebalanceWithdrawSuccess(rebalanceNonce, amountRebalanced);
        _rebalanceToNewStrategy(rebalanceNonce, amountRebalanced, recovery.strategy);
    }

    /// @notice Recovers a failed rebalance deposit into the active Child strategy
    /// @param rebalanceNonce The nonce of the failed rebalance deposit
    /// @dev Precondition: rebalance deposit recovery state must exist
    /// @dev Precondition: active strategy adapter must be set
    function recoverFailedRebalanceDeposit(uint256 rebalanceNonce) external override(BaseVault, IChildVault) {
        _recoverFailedRebalanceDeposit(rebalanceNonce);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Gets the CCIP selector for the parent chain
    /// @return parentChainSelector The CCIP selector for the parent chain
    function getParentChainSelector() external view returns (uint64 parentChainSelector) {
        parentChainSelector = i_parentChainSelector;
    }

    /// @notice Gets failed epoch deposit recovery state
    /// @param epochNonce The epoch nonce to query
    /// @return recovery The stored epoch deposit recovery state
    function getEpochDepositRecovery(uint256 epochNonce) external view returns (Types.AmountRecovery memory recovery) {
        recovery = s_epochDepositRecovery[epochNonce];
    }

    /// @notice Gets failed epoch withdraw recovery state
    /// @param epochNonce The epoch nonce to query
    /// @return recovery The stored epoch withdraw recovery state
    function getEpochWithdrawRecovery(uint256 epochNonce) external view returns (Types.AmountRecovery memory recovery) {
        recovery = s_epochWithdrawRecovery[epochNonce];
    }

    /// @notice Gets failed rebalance withdraw recovery state
    /// @param rebalanceNonce The rebalance nonce to query
    /// @return recovery The stored rebalance withdraw recovery state
    function getRebalanceWithdrawRecovery(uint256 rebalanceNonce)
        external
        view
        returns (Types.RebalanceWithdrawRecovery memory recovery)
    {
        recovery = s_rebalanceWithdrawRecovery[rebalanceNonce];
    }
}

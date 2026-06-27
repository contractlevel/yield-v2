// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseVault} from "./BaseVault.sol";
import {ChildVaultStore} from "./ChildVaultStore.sol";

import {IChildVault} from "../interfaces/IChildVault.sol";
import {Types} from "../libraries/Types.sol";
import {Roles} from "../libraries/Roles.sol";
import {IProtocolAdapter} from "../interfaces/IProtocolAdapter.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Client} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";

/// @title Yieldcoin v2 ChildVault
/// @author @contractlevel
/// @notice ChildVault is a contract that inherits from BaseVault. It's used to interact with Strategy protocols and communicate with the Parent and other ChildVaults across chains.
contract ChildVault is BaseVault, ChildVaultStore, IChildVault {
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
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @notice Initializes implementation-level immutable configuration for the ChildVault.
    /// @param params BaseVault constructor parameters for values baked into the implementation bytecode
    /// @param parentChainSelector CCIP selector for the parent chain
    /// @dev Precondition: parentChainSelector must not be zero
    /// @dev Precondition: parentChainSelector must not equal params.thisChainSelector
    constructor(BaseVault.ConstructorParams memory params, uint64 parentChainSelector) BaseVault(params) {
        _revertIfZeroChainSelector(parentChainSelector);
        if (parentChainSelector == params.thisChainSelector) revert ChildVault__InvalidParentChainSelector();
        i_parentChainSelector = parentChainSelector;
    }

    /// @notice Initializes ChildVault mutable proxy state.
    /// @param params BaseVault initializer parameters for roles and mutable vault configuration
    function initialize(BaseVault.InitParams memory params) external initializer {
        __BaseVault_init(params);
    }

    /*//////////////////////////////////////////////////////////////
                                  CCIP
    //////////////////////////////////////////////////////////////*/
    /// @notice Receives CCIP messages
    /// @param message Any2EVMMessage.
    /// @dev Precondition: the call must not be reentered
    /// @dev Precondition: the message must be sent by an allowed sender (a crosschain vault mapped to an allowed source chain selector)
    /// @dev Precondition: there must not be an existent recovery mode
    /// @dev Precondition: the received token must be i_asset
    /// @dev Precondition: there should only be 1 token sent
    /// @dev Precondition: the amount of token receive must be more than 0
    /// @dev Precondition: the received tx type must be supported: EPOCH_NET_DEPOSIT or REBALANCE
    function _ccipReceive(Client.Any2EVMMessage memory message)
        internal
        override
        nonReentrant
        onlyAllowedSender(abi.decode(message.sender, (address)), message.sourceChainSelector)
    {
        _requireNoRecovery();
        uint256 receivedAmount = _validateReceivedTokenAndGetAmount(message);

        /// @dev data decodes to a uint256 epochNonce for epoch net deposits/withdraws and a (uint256 rebalanceNonce, bytes32 protocolId) for rebalances
        (Types.CcipTx ccipTxType, bytes memory data) = abi.decode(message.data, (Types.CcipTx, bytes));

        if (ccipTxType == Types.CcipTx.EPOCH_NET_DEPOSIT) {
            uint256 epochNonce = abi.decode(data, (uint256));
            _handleCCIPDeposit(epochNonce, receivedAmount);
        }
        /// @dev see BaseVault::_handleCCIPRebalance
        else if (ccipTxType == Types.CcipTx.REBALANCE) {
            (uint256 rebalanceNonce, bytes32 protocolId) = abi.decode(data, (uint256, bytes32));
            _handleCCIPRebalance(rebalanceNonce, protocolId, receivedAmount);
        } else {
            revert BaseVault__InvalidTxType(ccipTxType);
        }
    }

    /// @notice Handles the CCIP deposit message
    /// @notice This will only be implemented in the ChildVault.
    ///         The ParentVault sends a CCIP deposit to the active strategy chain when an epoch's net flow is positive. (more deposits than withdraws)
    /// @param epochNonce The nonce of the epoch
    /// @param amount The amount of asset that was bridged to deposit into the active strategy on this child chain
    function _handleCCIPDeposit(uint256 epochNonce, uint256 amount) internal {
        bool success = _executeDeposit(amount, false);
        if (success) {
            emit DepositToStrategySuccess(epochNonce, amount);
        } else {
            _storeEpochDepositRecovery(epochNonce, amount);
            emit DepositToStrategyFailure(epochNonce, amount);
        }
    }

    /// @notice Sends a ChildVault CCIP message and stores recovery state on failure
    /// @notice Overrides BaseVault::_ccipSend to use a try/catch. (Parent failures use atomic revert)
    /// @param bridgeAmount The amount of asset to bridge
    /// @param destinationChainSelector The CCIP selector of the destination chain
    /// @param ccipTxType The type of CCIP transaction
    /// @param txData abi.encode(epochNonce) for epoch net deposit/withdraw, or abi.encode(rebalanceNonce, newStrategy.protocolId) for rebalance
    /// @dev Precondition: no recovery state must currently exist
    function _ccipSend(
        uint256 bridgeAmount,
        uint64 destinationChainSelector,
        Types.CcipTx ccipTxType,
        bytes memory txData
    ) internal override {
        _requireNoRecovery();
        _validateCcipSend(bridgeAmount, destinationChainSelector);

        try this.tryCcipSend(bridgeAmount, destinationChainSelector, ccipTxType, txData) {}
        catch {
            _childVaultStorage().s_ccipSendRecovery = Types.CcipSendRecovery({
                ccipTxType: ccipTxType,
                amount: bridgeAmount,
                destinationChainSelector: destinationChainSelector,
                txData: txData,
                createdAt: block.timestamp
            });
            _baseVaultStorage().s_recoveryMode = Types.RecoveryMode.CCIP_SEND;
            emit CcipSendRecoveryStored(ccipTxType, destinationChainSelector, bridgeAmount);
        }
    }

    /// @notice Executes a CCIP send through an external self-call boundary for ChildVault try/catch recovery
    /// @dev Precondition: caller must be this vault
    /// @param bridgeAmount The amount of asset to bridge
    /// @param destinationChainSelector The CCIP selector of the destination chain
    /// @param ccipTxType The type of CCIP transaction
    /// @param txData abi.encode(epochNonce) for epoch net deposit/withdraw, or abi.encode(rebalanceNonce, newStrategy.protocolId) for rebalance
    function tryCcipSend(
        uint256 bridgeAmount,
        uint64 destinationChainSelector,
        Types.CcipTx ccipTxType,
        bytes calldata txData
    ) external {
        if (msg.sender != address(this)) revert ChildVault__OnlySelf();
        _executeCcipSend(bridgeAmount, destinationChainSelector, ccipTxType, txData);
    }

    /*//////////////////////////////////////////////////////////////
                                  CRE
    //////////////////////////////////////////////////////////////*/
    /// @notice Executes the epoch withdraw from a strategy
    /// @notice This is called by the WorkflowRouter when net flow is negative (more withdraws than deposits)
    /// @param epochNonce The nonce of the epoch
    /// @param amount The amount of asset that was withdrawn from the active strategy
    /// @dev Precondition: Caller must have the EPOCH_OPERATOR_ROLE
    function executeEpochWithdraw(uint256 epochNonce, uint256 amount)
        external
        nonReentrant
        onlyRole(Roles.EPOCH_OPERATOR_ROLE)
    {
        _requireNoRecovery();
        _revertIfZeroAmount(amount);

        (bool success, uint256 amountOut) = _executeWithdraw(amount, false);
        if (success) {
            if (amountOut == 0) revert ChildVault__ZeroAmountOut();
            emit WithdrawFromStrategySuccess(epochNonce, amountOut);
            _ccipSend(amountOut, i_parentChainSelector, Types.CcipTx.EPOCH_NET_WITHDRAW, abi.encode(epochNonce));
        } else {
            _storeEpochWithdrawRecovery(epochNonce, amount);
            emit WithdrawFromStrategyFailure(epochNonce, amount);
        }
    }

    /// @notice This is called by the WorkflowRouter
    /// @notice Withdraws the entire tvl from the active strategy protocol adapter and sends it to the new strategy
    /// @notice This function shouldn't be in BaseVault because if a rebalance needs to be executed on the parent, this is what happens:
    /// - CRE workflow writes to parent
    /// - if parent == strategy: _executeWithdraw and _rebalanceToNewStrategy
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param newStrategy The new strategy to rebalance to
    /// @dev Precondition: caller must have the REBALANCE_OPERATOR_ROLE
    /// @dev Precondition: call must not be reentered
    /// @dev Precondition: there must be no existent recovery mode
    function executeRebalance(uint256 rebalanceNonce, Types.Strategy memory newStrategy)
        external
        nonReentrant
        onlyRole(Roles.REBALANCE_OPERATOR_ROLE)
    {
        _requireNoRecovery();

        (bool success,) = _executeRebalance(rebalanceNonce, newStrategy);
        if (!success) {
            _storeRebalanceWithdrawRecovery(rebalanceNonce, newStrategy);
        }
    }

    /// @notice Executes a rebalance by attempting to withdraw from the old strategy with _executeWithdraw. If that was successful, then attempts to rebalance with _rebalanceToNewStrategy
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param newStrategy The new strategy to rebalance to
    /// @return success Whether the withdraw from the old strategy succeeded or not
    /// @return amountRebalanced The amount rebalanced
    /// @notice This function uses a trycatch to handle cases where the withdraw from the old strategy failed
    function _executeRebalance(uint256 rebalanceNonce, Types.Strategy memory newStrategy)
        internal
        returns (bool success, uint256 amountRebalanced)
    {
        (success, amountRebalanced) = _executeWithdraw(type(uint256).max, false);
        if (success) {
            if (amountRebalanced == 0) revert ChildVault__ZeroAmountOut();
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
            _clearActiveAdapter();
            _ccipSend(
                tvlToRebalance,
                newStrategy.chainSelector,
                Types.CcipTx.REBALANCE,
                abi.encode(rebalanceNonce, newStrategy.protocolId)
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                                RECOVERY
    //////////////////////////////////////////////////////////////*/
    /// @notice Stores recovery state for a failed epoch deposit
    /// @param epochNonce The epoch nonce of the failed deposit
    /// @param amount The amount of asset to retry depositing
    /// @dev Precondition: amount must not be zero
    /// @dev Precondition: no recovery state must currently exist
    function _storeEpochDepositRecovery(uint256 epochNonce, uint256 amount) internal {
        if (amount == 0) revert BaseVault__ZeroRecoveryAmount();
        _requireNoRecovery();

        _childVaultStorage().s_epochDepositRecovery =
            Types.EpochRecovery({epochNonce: epochNonce, amount: amount, createdAt: block.timestamp});
        _baseVaultStorage().s_recoveryMode = Types.RecoveryMode.EPOCH_DEPOSIT;
        emit EpochDepositRecoveryStored(epochNonce, amount);
    }

    /// @notice Clears recovery state for a failed epoch deposit
    /// @dev Precondition: epoch deposit recovery state must exist
    function _clearEpochDepositRecovery() internal {
        _requireRecoveryMode(Types.RecoveryMode.EPOCH_DEPOSIT);
        uint256 epochNonce = _childVaultStorage().s_epochDepositRecovery.epochNonce;

        delete _childVaultStorage().s_epochDepositRecovery;
        _baseVaultStorage().s_recoveryMode = Types.RecoveryMode.NONE;
        emit EpochDepositRecoveryCleared(epochNonce);
    }

    /// @notice Requires and returns failed epoch deposit recovery state
    /// @return recovery The stored epoch deposit recovery state
    /// @dev Precondition: epoch deposit recovery state must exist
    function _requireEpochDepositRecovery() internal view returns (Types.EpochRecovery memory recovery) {
        _requireRecoveryMode(Types.RecoveryMode.EPOCH_DEPOSIT);
        recovery = _childVaultStorage().s_epochDepositRecovery;
    }

    /// @notice Stores recovery state for a failed epoch withdraw
    /// @param epochNonce The epoch nonce of the failed withdraw
    /// @param amount The amount of asset to retry withdrawing
    /// @dev Precondition: amount must not be zero
    /// @dev Precondition: no recovery state must currently exist
    function _storeEpochWithdrawRecovery(uint256 epochNonce, uint256 amount) internal {
        //slither-disable-next-line incorrect-equality
        if (amount == 0) revert BaseVault__ZeroRecoveryAmount();
        _requireNoRecovery();

        _childVaultStorage().s_epochWithdrawRecovery =
            Types.EpochRecovery({epochNonce: epochNonce, amount: amount, createdAt: block.timestamp});
        _baseVaultStorage().s_recoveryMode = Types.RecoveryMode.EPOCH_WITHDRAW;
        emit EpochWithdrawRecoveryStored(epochNonce, amount);
    }

    /// @notice Clears recovery state for a failed epoch withdraw
    /// @dev Precondition: epoch withdraw recovery state must exist
    function _clearEpochWithdrawRecovery() internal {
        _requireRecoveryMode(Types.RecoveryMode.EPOCH_WITHDRAW);
        uint256 epochNonce = _childVaultStorage().s_epochWithdrawRecovery.epochNonce;

        delete _childVaultStorage().s_epochWithdrawRecovery;
        _baseVaultStorage().s_recoveryMode = Types.RecoveryMode.NONE;
        emit EpochWithdrawRecoveryCleared(epochNonce);
    }

    /// @notice Requires and returns failed epoch withdraw recovery state
    /// @return recovery The stored epoch withdraw recovery state
    /// @dev Precondition: epoch withdraw recovery state must exist
    function _requireEpochWithdrawRecovery() internal view returns (Types.EpochRecovery memory recovery) {
        _requireRecoveryMode(Types.RecoveryMode.EPOCH_WITHDRAW);
        recovery = _childVaultStorage().s_epochWithdrawRecovery;
    }

    /// @notice Stores recovery state for a failed rebalance withdraw
    /// @param rebalanceNonce The rebalance nonce of the failed withdraw
    /// @param strategy The target strategy to continue the rebalance into after withdraw succeeds
    /// @dev Precondition: strategy chain selector must not be zero
    /// @dev Precondition: no recovery state must currently exist
    function _storeRebalanceWithdrawRecovery(uint256 rebalanceNonce, Types.Strategy memory strategy) internal {
        //slither-disable-next-line incorrect-equality
        if (strategy.chainSelector == 0) revert ChildVault__InvalidRecoveryStrategy();
        _requireNoRecovery();

        _childVaultStorage().s_rebalanceWithdrawRecovery = Types.RebalanceWithdrawRecovery({
            rebalanceNonce: rebalanceNonce, strategy: strategy, createdAt: block.timestamp
        });
        _baseVaultStorage().s_recoveryMode = Types.RecoveryMode.REBALANCE_WITHDRAW;
        emit RebalanceWithdrawRecoveryStored(rebalanceNonce, strategy.protocolId, strategy.chainSelector);
    }

    /// @notice Clears recovery state for a failed rebalance withdraw
    /// @dev Precondition: rebalance withdraw recovery state must exist
    function _clearRebalanceWithdrawRecovery() internal {
        _requireRecoveryMode(Types.RecoveryMode.REBALANCE_WITHDRAW);
        uint256 rebalanceNonce = _childVaultStorage().s_rebalanceWithdrawRecovery.rebalanceNonce;

        delete _childVaultStorage().s_rebalanceWithdrawRecovery;
        _baseVaultStorage().s_recoveryMode = Types.RecoveryMode.NONE;
        emit RebalanceWithdrawRecoveryCleared(rebalanceNonce);
    }

    /// @notice Requires and returns failed rebalance withdraw recovery state
    /// @return recovery The stored rebalance withdraw recovery state
    /// @dev Precondition: rebalance withdraw recovery state must exist
    function _requireRebalanceWithdrawRecovery()
        internal
        view
        returns (Types.RebalanceWithdrawRecovery memory recovery)
    {
        _requireRecoveryMode(Types.RecoveryMode.REBALANCE_WITHDRAW);
        recovery = _childVaultStorage().s_rebalanceWithdrawRecovery;
    }

    /// @notice Recovers a failed epoch deposit into the active Child strategy
    /// @dev Precondition: epoch deposit recovery state must exist
    /// @dev Precondition: active strategy adapter must be set
    /// @dev Precondition: function must not be reentered
    function recoverFailedEpochDeposit() external nonReentrant {
        Types.EpochRecovery memory recovery = _requireEpochDepositRecovery();
        uint256 epochNonce = recovery.epochNonce;

        _executeDeposit(recovery.amount, true);
        _clearEpochDepositRecovery();

        emit DepositToStrategySuccess(epochNonce, recovery.amount);
    }

    /// @notice Recovers a failed epoch withdraw from the active Child strategy
    /// @dev Precondition: epoch withdraw recovery state must exist
    /// @dev Precondition: active strategy adapter must be set
    /// @dev Precondition: function must not be reentered
    function recoverFailedEpochWithdraw() external nonReentrant {
        Types.EpochRecovery memory recovery = _requireEpochWithdrawRecovery();
        uint256 epochNonce = recovery.epochNonce;

        (, uint256 amountOut) = _executeWithdraw(recovery.amount, true);
        //slither-disable-next-line incorrect-equality
        if (amountOut == 0) revert BaseVault__ZeroRecoveryAmount();

        _clearEpochWithdrawRecovery();
        emit WithdrawFromStrategySuccess(epochNonce, amountOut);
        _ccipSend(amountOut, i_parentChainSelector, Types.CcipTx.EPOCH_NET_WITHDRAW, abi.encode(epochNonce));
    }

    /// @notice Recovers a failed rebalance withdraw from the active Child strategy
    /// @dev Precondition: rebalance withdraw recovery state must exist
    /// @dev Precondition: active strategy adapter must be set
    /// @dev Precondition: function must not be reentered
    function recoverFailedRebalanceWithdraw() external nonReentrant {
        Types.RebalanceWithdrawRecovery memory recovery = _requireRebalanceWithdrawRecovery();
        uint256 rebalanceNonce = recovery.rebalanceNonce;

        (, uint256 amountRebalanced) = _executeWithdraw(type(uint256).max, true);
        //slither-disable-next-line incorrect-equality
        if (amountRebalanced == 0) revert BaseVault__ZeroRecoveryAmount();

        _clearRebalanceWithdrawRecovery();
        emit RebalanceWithdrawSuccess(rebalanceNonce, amountRebalanced);
        _rebalanceToNewStrategy(rebalanceNonce, amountRebalanced, recovery.strategy);
    }

    /// @notice Recovers a failed rebalance deposit into the active Child strategy
    /// @dev Precondition: rebalance deposit recovery state must exist
    /// @dev Precondition: active strategy adapter must be set
    /// @dev Precondition: function must not be reentered
    function recoverFailedRebalanceDeposit() external override(BaseVault, IChildVault) nonReentrant {
        _recoverFailedRebalanceDeposit();
    }

    /// @notice Retries a failed ChildVault CCIP send
    /// @dev Precondition: CCIP send recovery state must exist
    /// @dev Precondition: function must not be reentered
    function recoverFailedCcipSend() external nonReentrant {
        _requireRecoveryMode(Types.RecoveryMode.CCIP_SEND);
        Types.CcipSendRecovery memory recovery = _childVaultStorage().s_ccipSendRecovery;

        // Clear before retry; if _executeCcipSend reverts, EVM atomicity restores this recovery state.
        delete _childVaultStorage().s_ccipSendRecovery;
        _baseVaultStorage().s_recoveryMode = Types.RecoveryMode.NONE;
        emit CcipSendRecoveryCleared(recovery.ccipTxType, recovery.destinationChainSelector, recovery.amount);

        _executeCcipSend(recovery.amount, recovery.destinationChainSelector, recovery.ccipTxType, recovery.txData);
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
    /// @return recovery The stored epoch deposit recovery state
    function getEpochDepositRecovery() external view returns (Types.EpochRecovery memory recovery) {
        recovery = _childVaultStorage().s_epochDepositRecovery;
    }

    /// @notice Gets failed epoch withdraw recovery state
    /// @return recovery The stored epoch withdraw recovery state
    function getEpochWithdrawRecovery() external view returns (Types.EpochRecovery memory recovery) {
        recovery = _childVaultStorage().s_epochWithdrawRecovery;
    }

    /// @notice Gets failed rebalance withdraw recovery state
    /// @return recovery The stored rebalance withdraw recovery state
    function getRebalanceWithdrawRecovery() external view returns (Types.RebalanceWithdrawRecovery memory recovery) {
        recovery = _childVaultStorage().s_rebalanceWithdrawRecovery;
    }

    /// @notice Gets failed CCIP send recovery state
    /// @return recovery The stored CCIP send recovery state
    function getCcipSendRecovery() external view returns (Types.CcipSendRecovery memory recovery) {
        recovery = _childVaultStorage().s_ccipSendRecovery;
    }

    /*//////////////////////////////////////////////////////////////
                                OVERRIDE
    //////////////////////////////////////////////////////////////*/
    /// @notice Gets the Yieldcoin TVL if this chain is the active strategy chain
    ///         Returns 0 if this chain is not the active strategy chain
    /// @return tvl The Yieldcoin TVL
    /// @notice The Child Vault implementation includes s_epochDepositRecovery.amount
    /// @notice Returns 0 if the TVL is in transit over CCIP. This should not be read onchain when Parent state is REBALANCING
    function _getTVL() internal view override returns (uint256 tvl) {
        address activeAdapter = _baseVaultStorage().s_activeProtocolAdapter;
        if (activeAdapter == address(0)) return 0;
        tvl = IProtocolAdapter(activeAdapter).getTVL() + _childVaultStorage().s_epochDepositRecovery.amount
            + _baseVaultStorage().s_rebalanceDepositRecovery.amount + _childVaultStorage().s_ccipSendRecovery.amount;
    }
}

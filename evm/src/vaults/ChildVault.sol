// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseVault} from "./BaseVault.sol";
import {ChildVaultStore} from "./ChildVaultStore.sol";

import {IBaseVault} from "../interfaces/IBaseVault.sol";
import {IChildVault} from "../interfaces/IChildVault.sol";
import {BaseVaultCcipLib} from "../libraries/BaseVaultCcipLib.sol";
import {BaseVaultStrategyLib} from "../libraries/BaseVaultStrategyLib.sol";
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
        _disableInitializers();
    }

    /// @notice Initializes ChildVault mutable proxy state.
    /// @param params BaseVault initializer parameters for roles and mutable vault configuration
    function initialize(BaseVault.InitParams memory params) external nonReentrant initializer {
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
        BaseVaultStorage storage $_baseVault = _baseVaultStorage();
        _requireNoRecovery($_baseVault);
        uint256 receivedAmount = BaseVaultCcipLib._validateReceivedTokenAndGetAmount(message, i_asset);

        /// @dev data decodes to a uint256 epochNonce for epoch net deposits/withdraws and a (uint256 rebalanceNonce, bytes32 protocolId) for rebalances
        (Types.CcipTx ccipTxType, bytes memory data) = abi.decode(message.data, (Types.CcipTx, bytes));

        if (ccipTxType == Types.CcipTx.EPOCH_NET_DEPOSIT) {
            uint256 epochNonce = abi.decode(data, (uint256));
            _handleCCIPDeposit(epochNonce, receivedAmount, $_baseVault);
        }
        /// @dev see BaseVault::_handleCCIPRebalance
        else if (ccipTxType == Types.CcipTx.REBALANCE) {
            (uint256 rebalanceNonce, bytes32 protocolId) = abi.decode(data, (uint256, bytes32));
            _handleCCIPRebalance(rebalanceNonce, protocolId, receivedAmount);
        } else {
            revert BaseVault__InvalidTxType(ccipTxType);
        }
    }

    /// @notice Handles the CCIP EPOCH_NET_DEPOSIT deposit message
    /// @notice This will only be implemented in the ChildVault.
    ///         The ParentVault sends a CCIP deposit to the active strategy chain when an epoch's net flow is positive. (more deposits than withdraws)
    /// @param epochNonce The nonce of the epoch
    /// @param amount The amount of asset that was bridged to deposit into the active strategy on this child chain
    function _handleCCIPDeposit(uint256 epochNonce, uint256 amount, BaseVaultStorage storage $_baseVault) internal {
        bool success = _executeDeposit(amount, false, $_baseVault.s_activeProtocolAdapter);
        if (success) {
            emit DepositToStrategySuccess(epochNonce, amount);
        } else {
            _storeEpochDepositRecovery($_baseVault, epochNonce, amount);
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
        BaseVaultStorage storage $_baseVault = _baseVaultStorage();
        _requireNoRecovery($_baseVault);
        BaseVaultCcipLib._validateCcipSend($_baseVault, bridgeAmount, destinationChainSelector, i_thisChainSelector);

        try this.tryCcipSend(bridgeAmount, destinationChainSelector, ccipTxType, txData) {}
        catch {
            _storeCcipSendRecovery($_baseVault, bridgeAmount, destinationChainSelector, ccipTxType, txData);
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
        BaseVaultCcipLib._send(
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
        BaseVaultStorage storage $_baseVault = _baseVaultStorage();
        _requireNoRecovery($_baseVault);
        _revertIfZeroAmount(amount);

        (bool success, uint256 amountOut) = _executeWithdraw(amount, false, $_baseVault.s_activeProtocolAdapter);
        if (success) {
            if (amountOut == 0) revert ChildVault__ZeroAmountOut();
            emit WithdrawFromStrategySuccess(epochNonce, amountOut);
            _ccipSend(amountOut, i_parentChainSelector, Types.CcipTx.EPOCH_NET_WITHDRAW, abi.encode(epochNonce));
        } else {
            _storeEpochWithdrawRecovery($_baseVault, epochNonce, amount);
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
        BaseVaultStorage storage $_baseVault = _baseVaultStorage();
        _requireNoRecovery($_baseVault);

        (bool success,) = _executeRebalance(rebalanceNonce, newStrategy);
        if (!success) {
            _storeRebalanceWithdrawRecovery($_baseVault, rebalanceNonce, newStrategy);
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
        address activeAdapter = _baseVaultStorage().s_activeProtocolAdapter;
        (success, amountRebalanced) = _executeWithdraw(type(uint256).max, false, activeAdapter);
        if (success) {
            if (amountRebalanced == 0) revert ChildVault__ZeroAmountOut();
            emit RebalanceWithdrawSuccess(rebalanceNonce, amountRebalanced);
            _rebalanceToNewStrategy(rebalanceNonce, amountRebalanced, newStrategy, activeAdapter);
        } else {
            emit RebalanceWithdrawFailure(rebalanceNonce);
        }
    }

    /// @notice Rebalances the TVL to the new strategy
    /// @param rebalanceNonce The nonce of the rebalance
    /// @param tvlToRebalance The TVL amount to rebalance
    /// @param newStrategy The new strategy to rebalance to
    /// @param oldAdapter The previously-active strategy adapter, already known by the caller
    /// @notice Handles a local rebalance on this chain or a crosschain rebalance to the new strategy chain
    function _rebalanceToNewStrategy(
        uint256 rebalanceNonce,
        uint256 tvlToRebalance,
        Types.Strategy memory newStrategy,
        address oldAdapter
    ) internal {
        //slither-disable-next-line incorrect-equality
        if (newStrategy.chainSelector == i_thisChainSelector) {
            address newAdapter = _setActiveAdapter(newStrategy.protocolId);

            bool success = _executeDeposit(tvlToRebalance, false, newAdapter);
            if (success) {
                emit RebalanceDepositSuccess(rebalanceNonce, tvlToRebalance);
            } else {
                _storeRebalanceDepositRecovery(_baseVaultStorage(), rebalanceNonce, tvlToRebalance);
                emit RebalanceDepositFailure(rebalanceNonce, tvlToRebalance);
            }
        } else {
            _clearActiveAdapter(oldAdapter);
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
    /// @dev Precondition: the protocol ID must have a registered adapter
    /// @dev Precondition: the registered adapter must be bound to this vault
    /// @dev ChildVault has enough bytecode headroom to inline the library implementation,
    ///      which also avoids unresolved external library calls in ChildVault verification.
    function _setActiveAdapter(bytes32 protocolId) internal override returns (address adapter) {
        adapter =
            BaseVaultStrategyLib._setActiveAdapter(_baseVaultStorage(), protocolId, i_adapterRegistry, address(this));
    }

    /*//////////////////////////////////////////////////////////////
                                RECOVERY
    //////////////////////////////////////////////////////////////*/
    /// @notice Executes the active recovery mode, reverting if no recovery is pending
    /// @dev Precondition: a recovery mode must be active (not NONE)
    /// @dev Precondition: function must not be reentered
    function executeRecovery() external override(BaseVault, IBaseVault) nonReentrant {
        BaseVaultStorage storage $_baseVault = _baseVaultStorage();
        Types.RecoveryMode mode = $_baseVault.s_recoveryMode;
        if (mode == Types.RecoveryMode.NONE) revert BaseVault__NoPendingRecovery();

        if (mode == Types.RecoveryMode.REBALANCE_DEPOSIT) {
            _recoverFailedRebalanceDeposit($_baseVault);
        } else if (mode == Types.RecoveryMode.EPOCH_DEPOSIT) {
            _recoverFailedEpochDeposit(_childVaultStorage(), $_baseVault);
        } else if (mode == Types.RecoveryMode.EPOCH_WITHDRAW) {
            _recoverFailedEpochWithdraw(_childVaultStorage(), $_baseVault);
        } else if (mode == Types.RecoveryMode.REBALANCE_WITHDRAW) {
            _recoverFailedRebalanceWithdraw(_childVaultStorage(), $_baseVault);
        } else if (mode == Types.RecoveryMode.CCIP_SEND) {
            _recoverFailedCcipSend($_baseVault);
        }
    }

    // --- EPOCH DEPOSIT RECOVERY --- //

    /// @notice Stores recovery state for a failed epoch deposit
    /// @param $_baseVault BaseVaultStorage
    /// @param epochNonce The epoch nonce of the failed deposit
    /// @param amount The amount of asset to retry depositing
    /// @dev Precondition: amount must not be zero
    /// @dev Precondition: no recovery state must currently exist
    function _storeEpochDepositRecovery(BaseVaultStorage storage $_baseVault, uint256 epochNonce, uint256 amount)
        internal
    {
        if (amount == 0) revert BaseVault__ZeroRecoveryAmount();
        _requireNoRecovery($_baseVault);
        _childVaultStorage().s_epochDepositRecovery = Types.EpochRecovery({epochNonce: epochNonce, amount: amount});
        $_baseVault.s_recoveryMode = Types.RecoveryMode.EPOCH_DEPOSIT;
        emit EpochDepositRecoveryStored(epochNonce, amount);
    }

    /// @notice Recovers a failed epoch deposit tx
    /// @param $ ChildVaultStorage
    /// @param $_baseVault BaseVaultStorage
    function _recoverFailedEpochDeposit(ChildVaultStorage storage $, BaseVaultStorage storage $_baseVault) internal {
        Types.EpochRecovery memory recovery = $.s_epochDepositRecovery;
        uint256 epochNonce = recovery.epochNonce;

        _executeDeposit(recovery.amount, true, $_baseVault.s_activeProtocolAdapter);
        _clearEpochDepositRecovery($, $_baseVault);

        emit DepositToStrategySuccess(epochNonce, recovery.amount);
    }

    /// @notice Clears recovery state for a failed epoch deposit
    function _clearEpochDepositRecovery(ChildVaultStorage storage $, BaseVaultStorage storage $_baseVault) internal {
        uint256 epochNonce = $.s_epochDepositRecovery.epochNonce;
        delete $.s_epochDepositRecovery;
        $_baseVault.s_recoveryMode = Types.RecoveryMode.NONE;
        emit EpochDepositRecoveryCleared(epochNonce);
    }

    // --- EPOCH WITHDRAW RECOVERY --- //

    /// @notice Stores recovery state for a failed epoch withdraw
    /// @param $_baseVault BaseVaultStorage
    /// @param epochNonce The epoch nonce of the failed withdraw
    /// @param amount The amount of asset to retry withdrawing
    /// @dev Precondition: amount must not be zero
    /// @dev Precondition: no recovery state must currently exist
    function _storeEpochWithdrawRecovery(BaseVaultStorage storage $_baseVault, uint256 epochNonce, uint256 amount)
        internal
    {
        //slither-disable-next-line incorrect-equality
        if (amount == 0) revert BaseVault__ZeroRecoveryAmount();
        _requireNoRecovery($_baseVault);
        _childVaultStorage().s_epochWithdrawRecovery = Types.EpochRecovery({epochNonce: epochNonce, amount: amount});
        $_baseVault.s_recoveryMode = Types.RecoveryMode.EPOCH_WITHDRAW;
        emit EpochWithdrawRecoveryStored(epochNonce, amount);
    }

    /// @notice Recovers a failed epoch withdraw tx
    /// @param $ ChildVaultStorage
    /// @param $_baseVault BaseVaultStorage
    /// @dev Precondition: amountOut from strategy withdraw must not be 0
    function _recoverFailedEpochWithdraw(ChildVaultStorage storage $, BaseVaultStorage storage $_baseVault) internal {
        Types.EpochRecovery memory recovery = $.s_epochWithdrawRecovery;
        uint256 epochNonce = recovery.epochNonce;

        (, uint256 amountOut) = _executeWithdraw(recovery.amount, true, $_baseVault.s_activeProtocolAdapter);
        //slither-disable-next-line incorrect-equality
        if (amountOut == 0) revert BaseVault__ZeroRecoveryAmount();

        _clearEpochWithdrawRecovery($, $_baseVault);
        emit WithdrawFromStrategySuccess(epochNonce, amountOut);
        _ccipSend(amountOut, i_parentChainSelector, Types.CcipTx.EPOCH_NET_WITHDRAW, abi.encode(epochNonce));
    }

    /// @notice Clears recovery state for a failed epoch withdraw
    function _clearEpochWithdrawRecovery(ChildVaultStorage storage $, BaseVaultStorage storage $_baseVault) internal {
        uint256 epochNonce = $.s_epochWithdrawRecovery.epochNonce;
        delete $.s_epochWithdrawRecovery;
        $_baseVault.s_recoveryMode = Types.RecoveryMode.NONE;
        emit EpochWithdrawRecoveryCleared(epochNonce);
    }

    // --- REBALANCE WITHDRAW RECOVERY --- //

    /// @notice Stores recovery state for a failed rebalance withdraw
    /// @param $_baseVault BaseVaultStorage
    /// @param rebalanceNonce The rebalance nonce of the failed withdraw
    /// @param strategy The target strategy to continue the rebalance into after withdraw succeeds
    /// @dev Precondition: strategy chain selector must not be zero
    /// @dev Precondition: no recovery state must currently exist
    function _storeRebalanceWithdrawRecovery(
        BaseVaultStorage storage $_baseVault,
        uint256 rebalanceNonce,
        Types.Strategy memory strategy
    ) internal {
        //slither-disable-next-line incorrect-equality
        if (strategy.chainSelector == 0) revert ChildVault__InvalidRecoveryStrategy();
        _requireNoRecovery($_baseVault);
        _childVaultStorage().s_rebalanceWithdrawRecovery =
            Types.RebalanceWithdrawRecovery({rebalanceNonce: rebalanceNonce, strategy: strategy});
        $_baseVault.s_recoveryMode = Types.RecoveryMode.REBALANCE_WITHDRAW;
        emit RebalanceWithdrawRecoveryStored(rebalanceNonce, strategy.protocolId, strategy.chainSelector);
    }

    /// @notice Recovers a failed rebalance withdraw tx
    /// @param $ ChildVaultStorage
    /// @param $_baseVault BaseVaultStorage
    function _recoverFailedRebalanceWithdraw(ChildVaultStorage storage $, BaseVaultStorage storage $_baseVault)
        internal
    {
        Types.RebalanceWithdrawRecovery memory recovery = $.s_rebalanceWithdrawRecovery;
        uint256 rebalanceNonce = recovery.rebalanceNonce;

        address activeAdapter = $_baseVault.s_activeProtocolAdapter;
        (, uint256 amountRebalanced) = _executeWithdraw(type(uint256).max, true, activeAdapter);
        //slither-disable-next-line incorrect-equality
        if (amountRebalanced == 0) revert BaseVault__ZeroRecoveryAmount();

        _clearRebalanceWithdrawRecovery($, $_baseVault);
        emit RebalanceWithdrawSuccess(rebalanceNonce, amountRebalanced);
        _rebalanceToNewStrategy(rebalanceNonce, amountRebalanced, recovery.strategy, activeAdapter);
    }

    /// @notice Clears recovery state for a failed rebalance withdraw
    function _clearRebalanceWithdrawRecovery(ChildVaultStorage storage $, BaseVaultStorage storage $_baseVault)
        internal
    {
        uint256 rebalanceNonce = $.s_rebalanceWithdrawRecovery.rebalanceNonce;
        delete $.s_rebalanceWithdrawRecovery;
        $_baseVault.s_recoveryMode = Types.RecoveryMode.NONE;
        emit RebalanceWithdrawRecoveryCleared(rebalanceNonce);
    }

    // --- CCIP SEND RECOVERY --- //

    /// @notice Stores recovery state for a failed CCIP send
    /// @param $_baseVault BaseVaultStorage
    /// @param bridgeAmount The amount of asset that was being bridged
    /// @param destinationChainSelector The CCIP selector of the destination chain
    /// @param ccipTxType The type of CCIP transaction
    /// @param txData abi.encode(epochNonce) for epoch net deposit/withdraw, or abi.encode(rebalanceNonce, newStrategy.protocolId) for rebalance
    /// @dev Precondition: no recovery state must currently exist
    function _storeCcipSendRecovery(
        BaseVaultStorage storage $_baseVault,
        uint256 bridgeAmount,
        uint64 destinationChainSelector,
        Types.CcipTx ccipTxType,
        bytes memory txData
    ) internal {
        _requireNoRecovery($_baseVault);

        uint256 nonce;
        bytes32 protocolId;
        // @review gas optimization: we'd have to pass nonce and protocolId to _ccipSend, refactoring Base/Parent too
        if (ccipTxType == Types.CcipTx.REBALANCE) {
            (nonce, protocolId) = abi.decode(txData, (uint256, bytes32));
        } else {
            nonce = abi.decode(txData, (uint256));
        }
        _childVaultStorage().s_ccipSendRecovery = Types.CcipSendRecovery({
            ccipTxType: ccipTxType,
            amount: bridgeAmount,
            destinationChainSelector: destinationChainSelector,
            nonce: nonce,
            protocolId: protocolId
        });
        $_baseVault.s_recoveryMode = Types.RecoveryMode.CCIP_SEND;
        emit CcipSendRecoveryStored(ccipTxType, destinationChainSelector, bridgeAmount);
    }

    /// @notice Recovers a failed CCIP send by retrying it
    /// @param $_baseVault BaseVaultStorage
    function _recoverFailedCcipSend(BaseVaultStorage storage $_baseVault) internal {
        // Clear before retry; if CCIP send reverts, EVM atomicity restores this recovery state.
        Types.CcipSendRecovery memory recovery = _clearCcipSendRecovery(_childVaultStorage(), $_baseVault);

        BaseVaultCcipLib._send(
            $_baseVault,
            recovery.amount,
            recovery.destinationChainSelector,
            recovery.ccipTxType,
            _encodeCcipTxPayload(recovery),
            i_asset,
            i_link,
            i_ccipRouter,
            i_thisChainSelector
        );
    }

    /// @notice Clears recovery state for a failed CCIP send
    /// @param $ ChildVaultStorage for Child Recovery state
    /// @param $_baseVault BaseVaultStorage for recovery mode
    /// @return recovery The cleared CCIP send recovery state
    function _clearCcipSendRecovery(ChildVaultStorage storage $, BaseVaultStorage storage $_baseVault)
        internal
        returns (Types.CcipSendRecovery memory recovery)
    {
        recovery = $.s_ccipSendRecovery;
        delete $.s_ccipSendRecovery;
        $_baseVault.s_recoveryMode = Types.RecoveryMode.NONE;
        emit CcipSendRecoveryCleared(recovery.ccipTxType, recovery.destinationChainSelector, recovery.amount);
    }

    /// @notice Rebuilds the CCIP send payload from stored recovery fields for retry
    /// @param recovery The cleared CCIP send recovery state
    /// @return data abi.encode(recovery.nonce) for epoch net deposit/withdraw, or abi.encode(recovery.nonce, recovery.protocolId) for rebalance
    function _encodeCcipTxPayload(Types.CcipSendRecovery memory recovery) internal pure returns (bytes memory data) {
        data = recovery.ccipTxType == Types.CcipTx.REBALANCE
            ? abi.encode(recovery.nonce, recovery.protocolId)
            : abi.encode(recovery.nonce);
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
        BaseVaultStorage storage $_baseVault = _baseVaultStorage();
        ChildVaultStorage storage $ = _childVaultStorage();

        address activeAdapter = $_baseVault.s_activeProtocolAdapter;
        if (activeAdapter != address(0)) {
            tvl = IProtocolAdapter(activeAdapter).getTVL() + $.s_epochDepositRecovery.amount
                + $_baseVault.s_rebalanceDepositRecovery.amount + $.s_ccipSendRecovery.amount;
        } else {
            tvl = 0;
        }
    }
}

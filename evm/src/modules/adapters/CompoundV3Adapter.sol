// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {ProtocolAdapter} from "../ProtocolAdapter.sol";
import {ICompoundV3Adapter} from "../../interfaces/adapters/ICompoundV3Adapter.sol";
import {IComet} from "../../interfaces/external/IComet.sol";
import {ICometRewards} from "../../interfaces/external/ICometRewards.sol";
import {Roles} from "../../libraries/Roles.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

/// @title Yieldcoin v2 Compound v3 Adapter
/// @author @contractlevel
/// @notice Adapter for the Compound v3 protocol
contract CompoundV3Adapter is ProtocolAdapter, ICompoundV3Adapter {
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @notice The address of the Compound V3 pool
    address internal immutable i_comet;
    /// @notice The address of the Compound V3 rewards contract
    address internal immutable i_cometRewards;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @param vault The address of the Yieldcoin v2 Vault
    /// @param comet The address of the Compound V3 pool
    /// @param cometRewards The address of the Compound V3 rewards contract
    /// @dev Precondition: comet must not be the zero address
    /// @dev Precondition: cometRewards must not be the zero address
    /// @dev Precondition: comet's base token must equal the vault's asset
    constructor(address vault, address comet, address cometRewards) ProtocolAdapter(vault) {
        _revertIfZeroAddress(comet);
        _revertIfZeroAddress(cometRewards);
        _revertIfAssetMismatch(IComet(comet).baseToken(), i_asset);

        i_comet = comet;
        i_cometRewards = cometRewards;
    }

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Deposits the underlying asset to the Compound V3 pool
    /// @param amount The amount of asset to deposit
    /// @dev Deposits the asset to the Compound V3 pool
    /// @dev Precondition: caller must be the Yieldcoin v2 Vault
    function deposit(uint256 amount) external nonReentrant onlyVault {
        emit Deposit(amount);

        uint256 tvlBefore = _getTVL();
        IERC20(i_asset).forceApprove(i_comet, amount);
        IComet(i_comet).supply(i_asset, amount);
        uint256 tvlAfter = _getTVL();

        _revertIfIncompleteDeposit(tvlBefore, tvlAfter, amount);
    }

    /// @notice Withdraws the underlying asset from the Compound V3 pool
    /// @param amount The amount of asset to withdraw (use type(uint256).max to withdraw all)
    /// @return actualWithdrawnAmount The actual withdrawn amount
    /// @dev Transfers the actual withdrawn amount to the Yieldcoin v2 Vault
    /// @dev Prevents borrowing by ensuring amount <= TVL when not using MAX sentinel
    /// @dev Precondition: caller must be the Yieldcoin v2 Vault
    /// @notice We handle 2 withdraw scenarios:
    /// 1. Epoch Withdraw - when the amount is a specific amount
    /// 2. Rebalance Withdraw - when the amount is type(uint256).max
    function withdraw(uint256 amount) external nonReentrant onlyVault returns (uint256 actualWithdrawnAmount) {
        /// @dev get balance before withdraw to calculate actual withdrawn amount
        uint256 balanceBefore = IERC20(i_asset).balanceOf(address(this));

        uint256 tvl = _getTVL();

        /// @dev Scenario 1: Epoch Withdraw - when the amount is a specific amount
        if (amount != type(uint256).max) {
            /// @dev accidental borrow prevention
            _revertIfEpochWithdrawAmountExceedsTVL(amount, tvl);

            IComet(i_comet).withdraw(i_asset, amount);

            /// @dev calculate actual amount received from withdrawing
            uint256 balanceAfter = IERC20(i_asset).balanceOf(address(this));
            actualWithdrawnAmount = balanceAfter - balanceBefore;
            if (actualWithdrawnAmount < amount) revert ProtocolAdapter__IncorrectWithdrawAmount();
        }
        /// @dev Scenario 2: Rebalance Withdraw - when the amount is type(uint256).max
        else {
            IComet(i_comet).withdraw(i_asset, amount);

            /// @dev calculate actual amount received from withdrawing
            uint256 balanceAfter = IERC20(i_asset).balanceOf(address(this));
            actualWithdrawnAmount = balanceAfter - balanceBefore;

            if (actualWithdrawnAmount < tvl) revert ProtocolAdapter__IncorrectWithdrawAmount();
        }

        emit Withdraw(actualWithdrawnAmount);
        IERC20(i_asset).safeTransfer(i_vault, actualWithdrawnAmount);
    }

    /// @notice Claims any rewards from the Comet Rewards contract
    /// @param to The address to receive the claimed rewards
    /// @dev Precondition: caller must have REWARDS_OPERATOR_ROLE on the vault
    /// @dev Precondition: to must not be zero address
    function claimRewards(address to) external {
        if (!IAccessControl(i_vault).hasRole(Roles.REWARDS_OPERATOR_ROLE, msg.sender)) {
            revert CompoundV3Adapter__CallerNotRewardsOperator();
        }
        _revertIfZeroAddress(to);
        emit RewardsClaimed(to);
        ICometRewards(i_cometRewards).claimTo(i_comet, address(this), to, true);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Internal function to get total value
    /// @return tvl The total value of the asset in the Compound V3 pool
    function _getTVL() internal view returns (uint256 tvl) {
        tvl = IComet(i_comet).balanceOf(address(this));
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Gets the total value of the asset in the Compound V3 pool
    /// @return tvl The total value of the asset in the Compound V3 pool
    /// @notice This is used for getting the TVL of the Yieldcoin v2 system, if this is the active protocol adapter
    function getTVL() external view returns (uint256 tvl) {
        tvl = _getTVL();
    }

    /// @notice Gets the Compound V3 pool address
    /// @return comet The Compound V3 pool address
    function getProtocolPool() external view returns (address comet) {
        return i_comet;
    }

    /// @notice Gets the Compound V3 rewards contract address
    /// @return cometRewards The Compound V3 rewards contract address
    function getCometRewards() external view returns (address cometRewards) {
        return i_cometRewards;
    }
}

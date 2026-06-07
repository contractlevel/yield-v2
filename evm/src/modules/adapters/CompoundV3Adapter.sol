// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {ProtocolAdapter} from "../ProtocolAdapter.sol";
import {IComet} from "../../interfaces/IComet.sol";
import {ICometRewards} from "../../interfaces/ICometRewards.sol";
import {Roles} from "../../libraries/Roles.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

/// @title Yieldcoin v2 Compound v3 Adapter
/// @author @contractlevel
/// @notice Adapter for the Compound v3 protocol
contract CompoundV3Adapter is ProtocolAdapter {
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @dev Thrown when the actual withdrawn amount is less than the amount requested
    error CompoundV3Adapter__IncorrectWithdrawAmount();
    /// @dev Thrown when the `amount` for an epoch withdraw exceeds the TVL
    error CompoundV3Adapter__WithdrawAmountExceedsTotalValue();
    /// @dev Thrown when zero address passed as param
    error CompoundV3Adapter__NoZeroAddress();
    /// @dev Thrown when the caller does not have REWARDS_OPERATOR_ROLE on the vault
    error CompoundV3Adapter__CallerNotRewardsOperator();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Emitted when rewards are claimed
    event RewardsClaimed(address indexed to);

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
    /// @param usdc The address of the USDC token
    /// @param comet The address of the Compound V3 pool
    /// @param cometRewards The address of the Compound V3 rewards contract
    //slither-disable-next-line missing-zero-check
    constructor(address vault, address usdc, address comet, address cometRewards) ProtocolAdapter(vault, usdc) {
        i_comet = comet;
        i_cometRewards = cometRewards;
    }

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Deposits USDC to the Compound V3 pool
    /// @param amount The amount of USDC to deposit
    /// @dev Deposits the USDC to the Compound V3 pool
    function deposit(uint256 amount) external nonReentrant onlyVault {
        emit Deposit(amount);

        IERC20(i_usdc).safeIncreaseAllowance(i_comet, amount);
        IComet(i_comet).supply(i_usdc, amount);
    }

    /// @notice Withdraws USDC from the Compound V3 pool
    /// @param amount The amount of USDC to withdraw (use type(uint256).max to withdraw all)
    /// @return actualWithdrawnAmount The actual withdrawn amount
    /// @dev Transfers the actual withdrawn amount to the yield peer
    /// @dev Prevents borrowing by ensuring amount <= balance when not using MAX sentinel
    /// @dev Precondition: caller must be the Yieldcoin v2 Vault
    /// @notice We handle 2 withdraw scenarios:
    /// 1. Epoch Withdraw - when the amount is a specific amount
    /// 2. Rebalance Withdraw - when the amount is type(uint256).max
    function withdraw(uint256 amount) external nonReentrant onlyVault returns (uint256 actualWithdrawnAmount) {
        /// @dev get balance before withdraw to calculate actual withdrawn amount
        uint256 balanceBefore = IERC20(i_usdc).balanceOf(address(this));

        uint256 tvl = _getTVL();

        /// @dev Scenario 1: Epoch Withdraw - when the amount is a specific amount
        if (amount != type(uint256).max) {
            /// @dev accidental borrow prevention
            if (amount > tvl) revert CompoundV3Adapter__WithdrawAmountExceedsTotalValue();

            IComet(i_comet).withdraw(i_usdc, amount);

            /// @dev calculate actual amount received from withdrawing
            uint256 balanceAfter = IERC20(i_usdc).balanceOf(address(this));
            actualWithdrawnAmount = balanceAfter - balanceBefore;
            if (actualWithdrawnAmount < amount) revert CompoundV3Adapter__IncorrectWithdrawAmount();
        }
        /// @dev Scenario 2: Rebalance Withdraw - when the amount is type(uint256).max
        else {
            IComet(i_comet).withdraw(i_usdc, amount);

            /// @dev calculate actual amount received from withdrawing
            uint256 balanceAfter = IERC20(i_usdc).balanceOf(address(this));
            actualWithdrawnAmount = balanceAfter - balanceBefore;

            if (actualWithdrawnAmount < tvl) revert CompoundV3Adapter__IncorrectWithdrawAmount();
        }

        emit Withdraw(actualWithdrawnAmount);
        IERC20(i_usdc).safeTransfer(i_vault, actualWithdrawnAmount);
    }

    /// @notice Claims any rewards from the Comet Rewards contract
    /// @param to The address to receive the claimed rewards
    /// @dev Precondition: caller must have REWARDS_OPERATOR_ROLE on the vault
    /// @dev Precondition: to must not be zero address
    function claimRewards(address to) external {
        if (!IAccessControl(i_vault).hasRole(Roles.REWARDS_OPERATOR_ROLE, msg.sender)) {
            revert CompoundV3Adapter__CallerNotRewardsOperator();
        }
        if (to == address(0)) revert CompoundV3Adapter__NoZeroAddress();
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

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
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @dev The address of the Compound v3 pool
    address internal immutable i_comet;
    /// @dev The address of the Compound v3 rewards contract
    address internal immutable i_cometRewards;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @param vault The address of the Yieldcoin v2 Vault
    /// @param comet The address of the Compound v3 pool
    /// @param cometRewards The address of the Compound v3 rewards contract
    /// @dev Reverts if vault is the zero address
    /// @dev Reverts if comet is the zero address
    /// @dev Reverts if cometRewards is the zero address
    /// @dev Reverts if Comet's base token does not equal the vault's underlying asset
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
    /// @notice Deposits the underlying asset into the configured protocol position
    /// @param amount The amount of underlying asset to deposit
    /// @dev Reverts if the caller is not the Yieldcoin v2 Vault
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if the protocol reports a lower position value after the deposit
    /// @dev Reverts if the protocol credits less than amount beyond the permitted rounding tolerance
    function deposit(uint256 amount) external nonReentrant onlyVault {
        emit Deposit(amount);

        uint256 tvlBefore = _getTVL();
        IERC20(i_asset).forceApprove(i_comet, amount);
        IComet(i_comet).supply(i_asset, amount);
        uint256 tvlAfter = _getTVL();

        _revertIfIncompleteDeposit(tvlBefore, tvlAfter, amount);
    }

    /// @notice Withdraws the underlying asset from the configured protocol position and transfers it to the vault
    /// @param amount The amount of underlying asset to withdraw, or type(uint256).max to withdraw the entire position
    /// @return actualWithdrawnAmount The actual amount of underlying asset withdrawn
    /// @dev Handles two withdrawal scenarios:
    ///      1. Epoch withdrawal - when amount is a specific amount
    ///      2. Rebalance withdrawal - when amount is type(uint256).max
    /// @dev A specific withdrawal cannot borrow because amount must not exceed the adapter's position value;
    ///      Compound treats type(uint256).max as a full withdrawal of the supplied base-asset balance
    /// @dev Reverts if the caller is not the Yieldcoin v2 Vault
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if a specific withdrawal amount exceeds the adapter's position value
    /// @dev Reverts if the protocol returns zero assets
    /// @dev Reverts if the protocol returns less than the expected amount beyond the permitted rounding tolerance
    function withdraw(uint256 amount) external nonReentrant onlyVault returns (uint256 actualWithdrawnAmount) {
        // Get balance before withdrawal to calculate the actual withdrawn amount
        uint256 balanceBefore = IERC20(i_asset).balanceOf(address(this));

        uint256 tvl = _getTVL();

        // Scenario 1: Epoch withdrawal - when the amount is a specific amount
        if (amount != type(uint256).max) {
            // Prevent an accidental borrow
            _revertIfEpochWithdrawAmountExceedsTVL(amount, tvl);

            IComet(i_comet).withdraw(i_asset, amount);

            // Calculate the actual amount received from the withdrawal
            uint256 balanceAfter = IERC20(i_asset).balanceOf(address(this));
            actualWithdrawnAmount = balanceAfter - balanceBefore;
            _revertIfIncompleteWithdraw(amount, actualWithdrawnAmount);
        }
        // Scenario 2: Rebalance withdrawal - when the amount is type(uint256).max
        else {
            IComet(i_comet).withdraw(i_asset, amount);

            // Calculate the actual amount received from the withdrawal
            uint256 balanceAfter = IERC20(i_asset).balanceOf(address(this));
            actualWithdrawnAmount = balanceAfter - balanceBefore;

            _revertIfIncompleteWithdraw(tvl, actualWithdrawnAmount);
        }

        emit Withdraw(actualWithdrawnAmount);
        IERC20(i_asset).safeTransfer(i_vault, actualWithdrawnAmount);
    }

    /// @notice Claims rewards accrued by the adapter's Comet position and sends them to a recipient
    /// @param to The address to receive the claimed rewards
    /// @dev Reverts if the caller does not have REWARDS_OPERATOR_ROLE on the vault
    /// @dev Reverts if to is the zero address
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
    /// @notice Returns the underlying-asset value of the adapter's Compound v3 position
    /// @return tvl The value of the adapter's position denominated in the underlying asset
    function _getTVL() internal view returns (uint256 tvl) {
        tvl = IComet(i_comet).balanceOf(address(this));
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns the underlying-asset value of the adapter's protocol position
    /// @return tvl The value of the adapter's position denominated in the underlying asset
    function getTVL() external view returns (uint256 tvl) {
        tvl = _getTVL();
    }

    /// @notice Returns the address of the protocol pool
    /// @return pool The Compound v3 pool address
    function getProtocolPool() external view returns (address pool) {
        pool = i_comet;
    }

    /// @notice Returns the Compound v3 rewards contract address
    /// @return cometRewards The Compound v3 rewards contract address
    function getCometRewards() external view returns (address cometRewards) {
        return i_cometRewards;
    }
}

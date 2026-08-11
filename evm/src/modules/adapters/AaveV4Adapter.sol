// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {ProtocolAdapter} from "../ProtocolAdapter.sol";
import {IAaveV4Adapter} from "../../interfaces/adapters/IAaveV4Adapter.sol";
import {IAaveV4Spoke} from "../../interfaces/external/IAaveV4Spoke.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Yieldcoin v2 Aave v4 Adapter
/// @author @contractlevel
/// @notice Adapter for the Aave v4 protocol
contract AaveV4Adapter is ProtocolAdapter, IAaveV4Adapter {
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLE
    //////////////////////////////////////////////////////////////*/
    /// @dev The address of the Aave v4 Spoke
    address internal immutable i_spoke;
    /// @dev The Aave v4 reserve ID for the underlying asset on the Spoke
    uint256 internal immutable i_reserveId;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @param vault The address of the Yieldcoin v2 Vault
    /// @param spoke The address of the Aave v4 Spoke
    /// @dev Reverts if vault is the zero address
    /// @dev Reverts if spoke is the zero address
    /// @dev Reverts if the vault's underlying asset is not listed on the Aave v4 Spoke
    /// @dev Reverts if the vault's underlying asset is listed more than once on the Aave v4 Spoke
    constructor(address vault, address spoke) ProtocolAdapter(vault) {
        _revertIfZeroAddress(spoke);
        i_spoke = spoke;
        i_reserveId = _getReserveId(spoke, i_asset);
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
        IERC20(i_asset).forceApprove(i_spoke, amount);
        //slither-disable-next-line unused-return
        IAaveV4Spoke(i_spoke).supply(i_reserveId, amount, address(this));
        uint256 tvlAfter = _getTVL();

        _revertIfIncompleteDeposit(tvlBefore, tvlAfter, amount);
    }

    /// @notice Withdraws the underlying asset from the configured protocol position and transfers it to the vault
    /// @param amount The amount of underlying asset to withdraw, or type(uint256).max to withdraw the entire position
    /// @return actualWithdrawnAmount The actual amount of underlying asset withdrawn
    /// @dev Handles two withdrawal scenarios:
    ///      1. Epoch withdrawal - when amount is a specific amount
    ///      2. Rebalance withdrawal - when amount is type(uint256).max
    /// @dev Reverts if the caller is not the Yieldcoin v2 Vault
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if a specific withdrawal amount exceeds the adapter's position value
    /// @dev Reverts if the protocol returns zero assets
    /// @dev Reverts if the protocol returns less than the expected amount beyond the permitted rounding tolerance
    function withdraw(uint256 amount) external nonReentrant onlyVault returns (uint256 actualWithdrawnAmount) {
        // Scenario 1: Epoch withdrawal - when the amount is a specific amount
        if (amount != type(uint256).max) {
            _revertIfEpochWithdrawAmountExceedsTVL(amount, _getTVL());

            //slither-disable-next-line unused-return
            (, actualWithdrawnAmount) = IAaveV4Spoke(i_spoke).withdraw(i_reserveId, amount, address(this));
            _revertIfIncompleteWithdraw(amount, actualWithdrawnAmount);
        }
        // Scenario 2: Rebalance withdrawal - when the amount is type(uint256).max
        else {
            uint256 tvl = _getTVL();

            //slither-disable-next-line unused-return
            (, actualWithdrawnAmount) = IAaveV4Spoke(i_spoke).withdraw(i_reserveId, amount, address(this));

            _revertIfIncompleteWithdraw(tvl, actualWithdrawnAmount);
        }
        emit Withdraw(actualWithdrawnAmount);
        IERC20(i_asset).safeTransfer(i_vault, actualWithdrawnAmount);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns the underlying-asset value of the adapter's Aave v4 position
    /// @return tvl The value of the adapter's position denominated in the underlying asset
    function _getTVL() internal view returns (uint256 tvl) {
        tvl = IAaveV4Spoke(i_spoke).getUserSuppliedAssets(i_reserveId, address(this));
    }

    /// @notice Returns the reserve ID for an underlying token on an Aave v4 Spoke
    /// @param spoke The address of the Aave v4 Spoke
    /// @param underlying The address of the underlying token
    /// @return reserveId The Aave v4 reserve ID
    /// @dev Reverts if underlying is listed as more than one reserve
    /// @dev Reverts if underlying is not listed as a reserve
    function _getReserveId(address spoke, address underlying) internal view returns (uint256 reserveId) {
        IAaveV4Spoke aaveV4Spoke = IAaveV4Spoke(spoke);
        uint256 reserveCount = aaveV4Spoke.getReserveCount();
        //slither-disable-next-line uninitialized-local
        bool found;

        for (uint256 i; i < reserveCount; ++i) {
            if (aaveV4Spoke.getReserve(i).underlying != underlying) continue;
            if (found) revert AaveV4Adapter__DuplicateReserveFound();

            found = true;
            reserveId = i;
        }

        if (!found) revert ProtocolAdapter__AssetMismatch();
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
    /// @return pool The address of the Aave v4 Spoke
    function getProtocolPool() external view returns (address pool) {
        pool = i_spoke;
    }

    /// @notice Returns the Aave v4 reserve ID for the underlying asset on the Spoke
    /// @return reserveId The Aave v4 reserve ID
    function getReserveId() external view returns (uint256 reserveId) {
        reserveId = i_reserveId;
    }
}

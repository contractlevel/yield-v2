// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {ProtocolAdapter} from "../ProtocolAdapter.sol";
import {IAaveV3Adapter} from "../../interfaces/adapters/IAaveV3Adapter.sol";
import {IPoolAddressesProvider} from "@aave/v3-origin/src/contracts/interfaces/IPoolAddressesProvider.sol";
import {IPool} from "@aave/v3-origin/src/contracts/interfaces/IPool.sol";
import {DataTypes} from "@aave/v3-origin/src/contracts/protocol/libraries/types/DataTypes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Yieldcoin v2 Aave v3 Adapter
/// @author @contractlevel
/// @notice Adapter for the Aave v3 protocol
contract AaveV3Adapter is ProtocolAdapter, IAaveV3Adapter {
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLE
    //////////////////////////////////////////////////////////////*/
    /// @dev The address of the Aave v3 pool addresses provider
    address internal immutable i_poolAddressesProvider;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @param vault The address of the Yieldcoin v2 Vault
    /// @param poolAddressesProvider The address of the Aave v3 pool addresses provider
    /// @dev Reverts if vault is the zero address
    /// @dev Reverts if poolAddressesProvider is the zero address
    /// @dev Reverts if the vault's underlying asset is not listed on the current Aave v3 pool
    constructor(address vault, address poolAddressesProvider) ProtocolAdapter(vault) {
        _revertIfZeroAddress(poolAddressesProvider);

        address pool = IPoolAddressesProvider(poolAddressesProvider).getPool();
        if (IPool(pool).getReserveData(i_asset).aTokenAddress == address(0)) {
            revert ProtocolAdapter__AssetMismatch();
        }

        i_poolAddressesProvider = poolAddressesProvider;
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

        address pool = _getAavePool();
        uint256 tvlBefore = _getTVL(pool);
        IERC20(i_asset).forceApprove(pool, amount);
        IPool(pool).supply(i_asset, amount, address(this), 0);
        uint256 tvlAfter = _getTVL(pool);

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
        address pool = _getAavePool();

        /// @dev Scenario 1: Epoch Withdraw - when the amount is a specific amount
        if (amount != type(uint256).max) {
            _revertIfEpochWithdrawAmountExceedsTVL(amount, _getTVL(pool));

            actualWithdrawnAmount = IPool(pool).withdraw(i_asset, amount, address(this));
            _revertIfIncompleteWithdraw(amount, actualWithdrawnAmount);
        }
        /// @dev Scenario 2: Rebalance Withdraw - when the amount is type(uint256).max
        else {
            uint256 tvl = _getTVL(pool);

            actualWithdrawnAmount = IPool(pool).withdraw(i_asset, amount, address(this));

            _revertIfIncompleteWithdraw(tvl, actualWithdrawnAmount);
        }
        emit Withdraw(actualWithdrawnAmount);
        IERC20(i_asset).safeTransfer(i_vault, actualWithdrawnAmount);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns the current Aave v3 pool address
    /// @return pool The current Aave v3 pool address
    function _getAavePool() internal view returns (address pool) {
        pool = IPoolAddressesProvider(i_poolAddressesProvider).getPool();
    }

    /// @notice Returns the underlying-asset value of the adapter's Aave v3 position
    /// @param pool The current Aave v3 pool address
    /// @return tvl The value of the adapter's position denominated in the underlying asset
    /// @dev The aToken balance can slightly overstate the withdrawable value, bounded by Aave's treasury fee rate
    function _getTVL(address pool) internal view returns (uint256 tvl) {
        DataTypes.ReserveDataLegacy memory reserveData = IPool(pool).getReserveData(i_asset);
        address aTokenAddress = reserveData.aTokenAddress;
        tvl = IERC20(aTokenAddress).balanceOf(address(this));
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns the underlying-asset value of the adapter's protocol position
    /// @return tvl The value of the adapter's position denominated in the underlying asset
    function getTVL() external view returns (uint256 tvl) {
        address pool = _getAavePool();
        tvl = _getTVL(pool);
    }

    /// @notice Returns the address of the protocol pool
    /// @return pool The address of the current Aave v3 pool
    function getProtocolPool() external view returns (address pool) {
        pool = _getAavePool();
    }

    /// @notice Returns the address of the Aave v3 pool addresses provider
    /// @return poolAddressesProvider The address of the Aave v3 pool addresses provider
    function getPoolAddressesProvider() external view returns (address poolAddressesProvider) {
        poolAddressesProvider = i_poolAddressesProvider;
    }
}

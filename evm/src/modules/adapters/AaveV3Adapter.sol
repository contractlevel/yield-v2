// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {ProtocolAdapter} from "../ProtocolAdapter.sol";
import {IPoolAddressesProvider} from "@aave/v3-origin/src/contracts/interfaces/IPoolAddressesProvider.sol";
import {IPool} from "@aave/v3-origin/src/contracts/interfaces/IPool.sol";
import {DataTypes} from "@aave/v3-origin/src/contracts/protocol/libraries/types/DataTypes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Yieldcoin v2 Aave v3 Adapter
/// @author @contractlevel
/// @notice Adapter for the Aave v3 protocol
contract AaveV3Adapter is ProtocolAdapter {
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @dev Thrown when the actual withdrawn amount is less than the amount requested
    error AaveV3Adapter__IncorrectWithdrawAmount();

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLE
    //////////////////////////////////////////////////////////////*/
    /// @notice The address of the Aave V3 pool addresses provider
    address internal immutable i_poolAddressesProvider;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @param vault The address of the Yieldcoin v2 Vault
    /// @param asset The address of the underlying asset token
    /// @param poolAddressesProvider The address of the Aave V3 pool addresses provider
    /// @dev Precondition: poolAddressesProvider must not be the zero address
    constructor(address vault, address asset, address poolAddressesProvider) ProtocolAdapter(vault, asset) {
        _revertIfZeroAddress(poolAddressesProvider);
        i_poolAddressesProvider = poolAddressesProvider;
    }

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Deposits the underlying asset to the Aave V3 pool
    /// @param amount The amount of asset to deposit
    /// @dev Deposits the asset to the Aave V3 pool
    /// @dev Precondition: caller must be the Yieldcoin v2 Vault
    function deposit(uint256 amount) external nonReentrant onlyVault {
        emit Deposit(amount);

        address pool = _getAavePool();
        IERC20(i_asset).forceApprove(pool, amount);
        IPool(pool).supply(i_asset, amount, address(this), 0);
    }

    /// @notice Withdraws the underlying asset from the Aave V3 pool
    /// @param amount The amount of asset to withdraw (use type(uint256).max to withdraw all)
    /// @return actualWithdrawnAmount The actual withdrawn amount
    /// @dev Transfers the actual withdrawn amount to the Yieldcoin v2 Vault
    /// @dev Precondition: caller must be the Yieldcoin v2 Vault
    /// @notice We handle 2 withdraw scenarios:
    /// 1. Epoch Withdraw - when the amount is a specific amount
    /// 2. Rebalance Withdraw - when the amount is type(uint256).max
    function withdraw(uint256 amount) external nonReentrant onlyVault returns (uint256 actualWithdrawnAmount) {
        address pool = _getAavePool();

        /// @dev Scenario 1: Epoch Withdraw - when the amount is a specific amount
        if (amount != type(uint256).max) {
            actualWithdrawnAmount = IPool(pool).withdraw(i_asset, amount, address(this));
            /// @dev Precondition: the actual withdrawn amount must not be less than the requested amount
            if (actualWithdrawnAmount < amount) revert AaveV3Adapter__IncorrectWithdrawAmount();
        }
        /// @dev Scenario 2: Rebalance Withdraw - when the amount is type(uint256).max
        else {
            uint256 tvl = _getTVL(pool);

            actualWithdrawnAmount = IPool(pool).withdraw(i_asset, amount, address(this));

            /// @dev Precondition: the actual withdrawn amount must not be less than the TVL
            if (actualWithdrawnAmount < tvl) revert AaveV3Adapter__IncorrectWithdrawAmount();
        }
        emit Withdraw(actualWithdrawnAmount);
        IERC20(i_asset).safeTransfer(i_vault, actualWithdrawnAmount);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Gets the Aave V3 pool address
    /// @return pool The Aave V3 pool address
    function _getAavePool() internal view returns (address pool) {
        pool = IPoolAddressesProvider(i_poolAddressesProvider).getPool();
    }

    /// @notice Gets the TVL in the Aave V3 pool
    /// @param pool The Aave V3 pool address. Fetched from _getAavePool()
    /// @return tvl The TVL of the Aave V3 pool
    /// @notice Reading aToken balance can slightly overstate available value. Bounded by Aave treasury fee rate (approximately 2-4 bps of TVL).
    function _getTVL(address pool) internal view returns (uint256 tvl) {
        DataTypes.ReserveDataLegacy memory reserveData = IPool(pool).getReserveData(i_asset);
        address aTokenAddress = reserveData.aTokenAddress;
        tvl = IERC20(aTokenAddress).balanceOf(address(this));
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Gets the TVL in the Aave V3 pool
    /// @return tvl The TVL of the Aave V3 pool
    /// @notice This is used for getting the TVL of the Yieldcoin v2 system, if this is the active protocol adapter
    function getTVL() external view returns (uint256 tvl) {
        address pool = _getAavePool();
        tvl = _getTVL(pool);
    }

    /// @notice Gets the address of the Aave V3 pool
    /// @return pool The address of the Aave V3 pool
    function getProtocolPool() external view returns (address pool) {
        pool = _getAavePool();
    }

    /// @notice Gets the address of the Aave V3 pool addresses provider
    /// @return poolAddressesProvider The address of the Aave V3 pool addresses provider
    function getPoolAddressesProvider() external view returns (address poolAddressesProvider) {
        poolAddressesProvider = i_poolAddressesProvider;
    }
}

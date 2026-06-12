// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {ProtocolAdapter} from "../ProtocolAdapter.sol";
import {IAaveV4Spoke} from "../../interfaces/IAaveV4Spoke.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Yieldcoin v2 Aave v4 Adapter
/// @author @contractlevel
/// @notice Adapter for the Aave v4 protocol
contract AaveV4Adapter is ProtocolAdapter {
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @dev Thrown when the actual withdrawn amount is less than the amount requested
    error AaveV4Adapter__IncorrectWithdrawAmount();
    /// @dev Thrown when the actual deposited amount is less than the amount supplied
    error AaveV4Adapter__IncompleteDeposit();
    /// @dev Thrown when the configured asset token is not listed as a reserve on the Spoke
    error AaveV4Adapter__ReserveNotFound();
    /// @dev Thrown when the configured asset token is listed more than once on the Spoke
    error AaveV4Adapter__DuplicateReserveFound();

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLE
    //////////////////////////////////////////////////////////////*/
    /// @notice The address of the Aave v4 Spoke
    address internal immutable i_spoke;
    /// @notice The Aave v4 reserve id for the underlying asset on the Spoke
    uint256 internal immutable i_reserveId;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @param vault The address of the Yieldcoin v2 Vault
    /// @param asset The address of the underlying asset token
    /// @param spoke The address of the Aave v4 Spoke
    /// @dev Precondition: spoke must not be the zero address
    constructor(address vault, address asset, address spoke) ProtocolAdapter(vault, asset) {
        _revertIfZeroAddress(spoke);
        i_spoke = spoke;
        i_reserveId = _getReserveId(spoke, asset);
    }

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Deposits the underlying asset to the Aave v4 Spoke
    /// @param amount The amount of asset to deposit
    /// @dev Deposits the asset into the adapter's own Aave v4 position
    /// @dev Precondition: caller must be the Yieldcoin v2 Vault
    function deposit(uint256 amount) external nonReentrant onlyVault {
        emit Deposit(amount);

        IERC20(i_asset).forceApprove(i_spoke, amount);
        //slither-disable-next-line unused-return
        (, uint256 suppliedAmount) = IAaveV4Spoke(i_spoke).supply(i_reserveId, amount, address(this));
        if (suppliedAmount < amount) revert AaveV4Adapter__IncompleteDeposit();
    }

    /// @notice Withdraws the underlying asset from the Aave v4 Spoke
    /// @param amount The amount of asset to withdraw (use type(uint256).max to withdraw all)
    /// @return actualWithdrawnAmount The actual withdrawn amount
    /// @dev Transfers the actual withdrawn amount to the Yieldcoin v2 Vault
    /// @dev Precondition: caller must be the Yieldcoin v2 Vault
    /// @notice We handle 2 withdraw scenarios:
    /// 1. Epoch Withdraw - when the amount is a specific amount
    /// 2. Rebalance Withdraw - when the amount is type(uint256).max
    function withdraw(uint256 amount) external nonReentrant onlyVault returns (uint256 actualWithdrawnAmount) {
        /// @dev Scenario 1: Epoch Withdraw - when the amount is a specific amount
        if (amount != type(uint256).max) {
            //slither-disable-next-line unused-return
            (, actualWithdrawnAmount) = IAaveV4Spoke(i_spoke).withdraw(i_reserveId, amount, address(this));
            /// @dev Precondition: the actual withdrawn amount must not be less than the requested amount
            if (actualWithdrawnAmount < amount) revert AaveV4Adapter__IncorrectWithdrawAmount();
        }
        /// @dev Scenario 2: Rebalance Withdraw - when the amount is type(uint256).max
        else {
            uint256 tvl = _getTVL();

            //slither-disable-next-line unused-return
            (, actualWithdrawnAmount) = IAaveV4Spoke(i_spoke).withdraw(i_reserveId, amount, address(this));

            /// @dev Precondition: the actual withdrawn amount must not be less than the TVL
            if (actualWithdrawnAmount < tvl) revert AaveV4Adapter__IncorrectWithdrawAmount();
        }
        emit Withdraw(actualWithdrawnAmount);
        IERC20(i_asset).safeTransfer(i_vault, actualWithdrawnAmount);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Gets the TVL in the Aave v4 Spoke
    /// @return tvl The TVL of the Aave v4 position
    function _getTVL() internal view returns (uint256 tvl) {
        tvl = IAaveV4Spoke(i_spoke).getUserSuppliedAssets(i_reserveId, address(this));
    }

    /// @notice Gets the reserve id for an underlying token on an Aave v4 Spoke
    /// @param spoke The address of the Aave v4 Spoke
    /// @param underlying The address of the underlying token
    /// @return reserveId The Aave v4 reserve id
    function _getReserveId(address spoke, address underlying) internal view returns (uint256 reserveId) {
        IAaveV4Spoke aaveV4Spoke = IAaveV4Spoke(spoke);
        uint256 reserveCount = aaveV4Spoke.getReserveCount();
        bool found;

        for (uint256 i = 0; i < reserveCount; ++i) {
            if (aaveV4Spoke.getReserve(i).underlying != underlying) continue;
            if (found) revert AaveV4Adapter__DuplicateReserveFound();

            found = true;
            reserveId = i;
        }

        if (!found) revert AaveV4Adapter__ReserveNotFound();
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Gets the TVL in the Aave v4 Spoke
    /// @return tvl The TVL of the Aave v4 position
    /// @notice This is used for getting the TVL of the Yieldcoin v2 system, if this is the active protocol adapter
    function getTVL() external view returns (uint256 tvl) {
        tvl = _getTVL();
    }

    /// @notice Gets the address of the Aave v4 Spoke
    /// @return pool The address of the Aave v4 Spoke
    function getProtocolPool() external view returns (address pool) {
        pool = i_spoke;
    }

    /// @notice Gets the Aave v4 reserve id for the underlying asset on the Spoke
    /// @return reserveId The Aave v4 reserve id
    function getReserveId() external view returns (uint256 reserveId) {
        reserveId = i_reserveId;
    }
}

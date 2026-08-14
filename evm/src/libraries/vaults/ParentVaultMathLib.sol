// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

/// @title Yieldcoin v2 ParentVault math library
/// @author @contractlevel
/// @notice Shared full-precision math helpers for ParentVault accounting
library ParentVaultMathLib {
    /// @notice Computes x * y / denominator with full-precision intermediate multiplication, rounding down
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @param denominator The divisor
    /// @return result The quotient rounded down
    /// @dev Reverts if denominator is zero or the result overflows uint256
    function _mulDivDown(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        result = FixedPointMathLib.fullMulDiv(x, y, denominator);
    }

    /// @notice Computes x * y / denominator with full-precision intermediate multiplication, rounding up
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @param denominator The divisor
    /// @return result The quotient rounded up
    /// @dev Reverts if denominator is zero or the result overflows uint256
    function _mulDivUp(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        result = FixedPointMathLib.fullMulDivUp(x, y, denominator);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

// Formal-verification fallback:
// import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/// @title Yieldcoin v2 ParentVault math library
/// @author @contractlevel
/// @notice Shared full-precision math helpers for ParentVault accounting.
library ParentVaultMathLib {
    function _mulDivDown(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        result = FixedPointMathLib.fullMulDiv(x, y, denominator);
        // OZ equivalent: result = Math.mulDiv(x, y, denominator);
    }

    function _mulDivUp(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        result = FixedPointMathLib.fullMulDivUp(x, y, denominator);
        // OZ equivalent: result = Math.mulDiv(x, y, denominator, Math.Rounding.Ceil);
    }
}

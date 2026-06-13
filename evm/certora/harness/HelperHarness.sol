// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

/// @title HelperHarness
/// @author @contractlevel
/// @notice Helper functions to use 
contract HelperHarness {
    function bytes32ToAddress(bytes32 b) external returns (address) {
        return address(uint160(uint256(b)));
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Test} from "forge-std/Test.sol";

import {OffsetFirstManagementFee} from "../../script/interactions/OffsetFirstManagementFee.s.sol";

contract OffsetFirstManagementFeeTest is Test {
    OffsetFirstManagementFee internal script;

    function setUp() external {
        script = new OffsetFirstManagementFee();
    }

    function test_CalculateDonation_OffsetsCurrentDilution() external view {
        assertEq(script.calculateDonation(150_038_011), 103_793);
    }

    function test_CalculateDonation_RoundsUpToAssetPrecision() external view {
        assertEq(script.calculateDonation(1), 1);
    }
}

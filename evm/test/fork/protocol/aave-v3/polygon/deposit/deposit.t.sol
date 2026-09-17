// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseAaveV3ForkTest} from "../../BaseAaveV3ForkTest.t.sol";

contract Polygon_AaveV3DepositForkTest is BaseAaveV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectPolygonFork();
    }

    function test_Polygon_aaveV3_deposit_RevertWhen_CallerIsNotVault() external {
        _assertAaveV3DepositRevertsWhenCallerIsNotVault(polygonChild.aaveV3Adapter);
    }

    function test_Polygon_aaveV3_deposit_Success() external {
        _assertAaveV3DepositSucceeds(polygonChild.aaveV3Adapter, address(polygonChild.vault), polygonChild.asset);
    }
}

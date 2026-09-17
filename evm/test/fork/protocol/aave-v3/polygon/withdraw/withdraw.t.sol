// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseAaveV3ForkTest} from "../../BaseAaveV3ForkTest.t.sol";

contract Polygon_AaveV3WithdrawForkTest is BaseAaveV3ForkTest {
    function setUp() public override {
        super.setUp();
        _selectPolygonFork();
    }

    function test_Polygon_aaveV3_withdraw_RevertWhen_CallerIsNotVault() external {
        _assertAaveV3WithdrawRevertsWhenCallerIsNotVault(polygonChild.aaveV3Adapter);
    }

    function test_Polygon_aaveV3_withdraw_Success_EpochWithdraw() external {
        _assertAaveV3EpochWithdrawSucceeds(polygonChild.aaveV3Adapter, address(polygonChild.vault), polygonChild.asset);
    }

    function test_Polygon_aaveV3_withdraw_Success_RebalanceWithdraw() external {
        _assertAaveV3RebalanceWithdrawSucceeds(
            polygonChild.aaveV3Adapter, address(polygonChild.vault), polygonChild.asset
        );
    }
}

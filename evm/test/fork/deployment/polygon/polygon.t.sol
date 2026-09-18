// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseForkDeploymentTest} from "../BaseForkDeploymentTest.t.sol";

contract Polygon_DeploymentForkTest is BaseForkDeploymentTest {
    function setUp() public override {
        super.setUp();
        _selectPolygonFork();
    }

    function test_Polygon_deployment_ConfiguresChild() external view {
        _assertChildForkDeployment(polygonChild, polygonConfig, polygonForkDeployer);
    }
}

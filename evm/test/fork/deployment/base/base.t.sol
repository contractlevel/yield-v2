// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseForkDeploymentTest} from "../BaseForkDeploymentTest.t.sol";

contract Base_DeploymentForkTest is BaseForkDeploymentTest {
    function setUp() public override {
        super.setUp();
        _selectBaseFork();
    }

    function test_Base_deployment_ConfiguresChild() external view {
        _assertChildForkDeployment(baseChild, baseConfig, baseForkDeployer);
    }
}

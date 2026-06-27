// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseForkDeploymentTest} from "../BaseForkDeploymentTest.t.sol";

contract Optimism_DeploymentForkTest is BaseForkDeploymentTest {
    function setUp() public override {
        super.setUp();
        _selectOptimismFork();
    }

    function test_Optimism_deployment_ConfiguresChild() external view {
        _assertChildForkDeployment(optimismChild, optimismConfig, optimismForkDeployer);
    }
}

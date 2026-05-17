// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseForkDeploymentTest} from "../BaseForkDeploymentTest.t.sol";

contract Avalanche_DeploymentForkTest is BaseForkDeploymentTest {
    function setUp() public override {
        super.setUp();
        _selectAvalancheFork();
    }

    function test_Avalanche_deployment_ConfiguresChild() external view {
        _assertChildForkDeployment(avalancheChild, avalancheConfig, avalancheForkDeployer);
    }
}

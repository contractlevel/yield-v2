// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseForkDeploymentTest} from "../BaseForkDeploymentTest.t.sol";

contract Ethereum_DeploymentForkTest is BaseForkDeploymentTest {
    function setUp() public override {
        super.setUp();
        _selectEthereumFork();
    }

    function test_Ethereum_deployment_ConfiguresChild() external view {
        _assertChildForkDeployment(ethereumChild, ethereumConfig, ethereumForkDeployer);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseForkDeploymentTest} from "../BaseForkDeploymentTest.t.sol";

contract Arbitrum_DeploymentForkTest is BaseForkDeploymentTest {
    function setUp() public override {
        super.setUp();
        _selectArbitrumFork();
    }

    function test_Arbitrum_deployment_ConfiguresParent() external view {
        _assertParentForkDeployment();
    }

    function test_Arbitrum_deployment_ConfiguresCrosschainVaults() external view {
        _assertParentForkCrosschainVaults();
    }
}

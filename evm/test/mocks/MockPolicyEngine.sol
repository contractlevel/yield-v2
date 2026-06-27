// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IPolicyEngine} from "@chainlink/policy-management/interfaces/IPolicyEngine.sol";

contract MockPolicyEngine is IPolicyEngine {
    function attach() external override {}
    function detach() external override {}
    function run(Payload calldata) external override {}

    function typeAndVersion() external pure override returns (string memory) {
        return "MockPolicyEngine 1.0.0";
    }

    function check(Payload calldata) external view override {}
    function setExtractor(bytes4, address) external override {}
    function setExtractors(bytes4[] calldata, address) external override {}

    function getExtractor(bytes4) external pure override returns (address) {
        return address(0);
    }
    function setPolicyMapper(address, address) external override {}

    function getPolicyMapper(address) external pure override returns (address) {
        return address(0);
    }
    function addPolicy(address, bytes4, address, bytes32[] calldata) external override {}
    function addPolicyAt(address, bytes4, address, bytes32[] calldata, uint256) external override {}
    function removePolicy(address, bytes4, address) external override {}

    function getPolicies(address, bytes4) external pure override returns (address[] memory) {
        return new address[](0);
    }
    function setPolicyConfiguration(address, uint256, bytes4, bytes calldata) external override {}

    function getPolicyConfigVersion(address) external pure override returns (uint256) {
        return 0;
    }
    function setDefaultPolicyAllow(bool) external override {}
    function setTargetDefaultPolicyAllow(address, bool) external override {}
    function upgradePolicy(address, address, bytes calldata) external override {}
}

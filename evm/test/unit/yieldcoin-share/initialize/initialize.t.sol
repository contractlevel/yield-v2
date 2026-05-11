// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {YieldcoinShare} from "../../../../src/token/YieldcoinShare.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract YieldcoinShare_InitializeUnitTest is BaseUnitTest {
    function test_YieldcoinShare_initialize_Success_SetsMetadata() external view {
        assertEq(s_yieldcoin.name(), "Yieldcoin");
        assertEq(s_yieldcoin.symbol(), "YIELD");
        assertEq(s_yieldcoin.decimals(), 18);
    }

    function test_YieldcoinShare_initialize_Success_SetsPolicyEngine() external view {
        assertEq(s_yieldcoin.getPolicyEngine(), address(s_mockPolicyEngine));
    }

    function test_YieldcoinShare_initialize_Success_SetsCCIPAdmin() external view {
        assertEq(s_yieldcoin.getCCIPAdmin(), i_configOperator);
    }

    function test_YieldcoinShare_initialize_Success_EmitsCCIPAdminTransferred() external {
        YieldcoinShare yieldcoinImpl = new YieldcoinShare();

        vm.recordLogs();
        ERC1967Proxy yieldcoinProxy = new ERC1967Proxy(
            address(yieldcoinImpl),
            abi.encodeWithSelector(YieldcoinShare.initialize.selector, address(s_mockPolicyEngine), i_configOperator)
        );

        Vm.Log memory log =
            _assertEmittedBy(keccak256("CCIPAdminTransferred(address,address)"), address(yieldcoinProxy));
        assertEq(address(uint160(uint256(log.topics[1]))), address(0));
        assertEq(address(uint160(uint256(log.topics[2]))), i_configOperator);
    }
}

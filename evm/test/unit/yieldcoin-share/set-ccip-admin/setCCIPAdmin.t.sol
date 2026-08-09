// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {YieldcoinShare} from "../../../../src/token/YieldcoinShare.sol";

contract YieldcoinShare_SetCCIPAdminUnitTest is BaseUnitTest {
    address internal immutable i_newCcipAdmin = makeAddr("newCcipAdmin");

    function test_YieldcoinShare_TOKEN_001_setCCIPAdmin_RevertWhen_NewAdminIsZeroAddress() external {
        vm.expectRevert(YieldcoinShare.YieldcoinShare__NoZeroAddress.selector);
        s_yieldcoin.setCCIPAdmin(address(0));
    }

    function test_YieldcoinShare_TOKEN_001_setCCIPAdmin_Success_SetsCCIPAdmin() external {
        s_yieldcoin.setCCIPAdmin(i_newCcipAdmin);

        assertEq(s_yieldcoin.getCCIPAdmin(), i_newCcipAdmin);
    }

    function test_YieldcoinShare_TOKEN_001_setCCIPAdmin_Success_EmitsCCIPAdminTransferred() external {
        vm.recordLogs();
        s_yieldcoin.setCCIPAdmin(i_newCcipAdmin);

        Vm.Log memory log = _assertEmittedBy(keccak256("CCIPAdminTransferred(address,address)"), address(s_yieldcoin));
        assertEq(address(uint160(uint256(log.topics[1]))), i_configOperator);
        assertEq(address(uint160(uint256(log.topics[2]))), i_newCcipAdmin);
    }
}

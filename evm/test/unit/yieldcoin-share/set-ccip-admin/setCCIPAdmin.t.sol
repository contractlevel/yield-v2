// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

contract YieldcoinShare_SetCCIPAdminUnitTest is BaseUnitTest {
    address internal immutable i_newCcipAdmin = makeAddr("newCcipAdmin");

    function test_YieldcoinShare_setCCIPAdmin_Success_SetsCCIPAdmin() external {
        s_yieldcoin.setCCIPAdmin(i_newCcipAdmin);

        assertEq(s_yieldcoin.getCCIPAdmin(), i_newCcipAdmin);
    }

    function test_YieldcoinShare_setCCIPAdmin_Success_EmitsCCIPAdminTransferred() external {
        vm.recordLogs();
        s_yieldcoin.setCCIPAdmin(i_newCcipAdmin);

        Vm.Log memory log = _assertEmittedBy(keccak256("CCIPAdminTransferred(address,address)"), address(s_yieldcoin));
        assertEq(address(uint160(uint256(log.topics[1]))), i_configOperator);
        assertEq(address(uint160(uint256(log.topics[2]))), i_newCcipAdmin);
    }
}

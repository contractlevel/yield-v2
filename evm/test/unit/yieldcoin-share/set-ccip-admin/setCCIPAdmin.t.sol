// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {IShare} from "../../../../src/interfaces/token/IShare.sol";
import {YieldcoinShare} from "../../../../src/token/YieldcoinShare.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract YieldcoinShare_SetCCIPAdminUnitTest is BaseUnitTest {
    address internal immutable i_newCcipAdmin = makeAddr("newCcipAdmin");

    function setUp() public {
        _changePrank(i_configOperator);
    }

    function test_YieldcoinShare_setCCIPAdmin_RevertWhen_CallerLacksConfigOperatorRole() external {
        _changePrank(i_nonOwner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.CONFIG_OPERATOR_ROLE
            )
        );
        s_yieldcoin.setCCIPAdmin(i_newCcipAdmin);
    }

    function test_YieldcoinShare_TOKEN_001_setCCIPAdmin_RevertWhen_NewAdminIsZeroAddress() external {
        vm.expectRevert(IShare.YieldcoinShare__NoZeroAddress.selector);
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

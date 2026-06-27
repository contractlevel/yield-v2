// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {BaseVault, IBaseVault} from "../../../../src/vaults/BaseVault.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

abstract contract BaseVault_WithdrawLinkUnitTest is BaseUnitTest {
    BaseVault internal s_vault;

    uint256 internal constant LINK_AMOUNT = 1 ether;

    function _setUpVault() internal {
        _changePrank(i_owner);
        s_vault.grantRole(Roles.LINK_OPERATOR_ROLE, i_linkOperator);
        deal(address(s_mockLink), address(s_vault), LINK_AMOUNT);
        _changePrank(i_linkOperator);
    }

    function test_BaseVault_withdrawLink_RevertWhen_CallerDoesNotHaveLINK_OPERATOR_ROLE()
        external
        whenCallerIsNotAdmin
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.LINK_OPERATOR_ROLE
            )
        );
        s_vault.withdrawLink(LINK_AMOUNT);
    }

    function test_BaseVault_withdrawLink_RevertWhen_AmountIsZero() external {
        vm.expectRevert(IBaseVault.BaseVault__NoZeroAmount.selector);
        s_vault.withdrawLink(0);
    }

    function test_BaseVault_withdrawLink_Success() external {
        vm.recordLogs();
        s_vault.withdrawLink(LINK_AMOUNT);

        assertEq(s_mockLink.balanceOf(i_linkOperator), LINK_AMOUNT);
        assertEq(s_mockLink.balanceOf(address(s_vault)), 0);

        Vm.Log memory log = _assertEmittedBy(keccak256("LinkWithdrawn(address,uint256)"), address(s_vault));
        assertEq(address(uint160(uint256(log.topics[1]))), i_linkOperator);
        assertEq(uint256(log.topics[2]), LINK_AMOUNT);
    }
}

contract ParentVault_WithdrawLinkUnitTest is BaseVault_WithdrawLinkUnitTest {
    function setUp() public {
        s_vault = s_parentVault;
        _setUpVault();
    }
}

contract ChildVault_WithdrawLinkUnitTest is BaseVault_WithdrawLinkUnitTest {
    function setUp() public {
        s_vault = s_childVault;
        _setUpVault();
    }
}

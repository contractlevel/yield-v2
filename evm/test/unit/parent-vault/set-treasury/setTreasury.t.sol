// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {IBaseVault} from "../../../../src/interfaces/IBaseVault.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract ParentVault_SetTreasuryUnitTest is BaseUnitTest {
    address internal immutable i_newTreasury = makeAddr("newTreasury");

    function setUp() public {
        _changePrank(i_configOperator);
    }

    function test_ParentVault_setTreasury_RevertWhen_CallerDoesNotHaveCONFIG_OPERATOR_ROLE()
        external
        whenCallerIsNotAdmin
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.CONFIG_OPERATOR_ROLE
            )
        );
        s_parentVault.setTreasury(i_newTreasury);
    }

    function test_ParentVault_setTreasury_RevertWhen_TreasuryIsZeroAddress() external {
        vm.expectRevert(IBaseVault.BaseVault__NoZeroAddress.selector);
        s_parentVault.setTreasury(address(0));
    }

    function test_ParentVault_setTreasury_Success() external {
        vm.recordLogs();

        s_parentVault.setTreasury(i_newTreasury);

        Vm.Log memory log = _assertEmittedBy(keccak256("TreasurySet(address)"), address(s_parentVault));
        assertEq(address(uint160(uint256(log.topics[1]))), i_newTreasury);
        assertEq(s_parentVault.getTreasury(), i_newTreasury);
    }
}

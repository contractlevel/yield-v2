// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {BaseVault, IBaseVault} from "../../../../src/vaults/BaseVault.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

abstract contract BaseVault_SetEmergencyReceiverUnitTest is BaseUnitTest {
    BaseVault internal s_vault;

    address internal immutable i_newEmergencyReceiver = makeAddr("newEmergencyReceiver");

    function test_BaseVault_setEmergencyReceiver_RevertWhen_CallerDoesNotHaveCONFIG_OPERATOR_ROLE() external {
        _changePrank(i_nonOwner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.CONFIG_OPERATOR_ROLE
            )
        );
        s_vault.setEmergencyReceiver(i_newEmergencyReceiver);
    }

    function test_BaseVault_setEmergencyReceiver_RevertWhen_EmergencyReceiverIsZeroAddress() external {
        vm.expectRevert(IBaseVault.BaseVault__NoZeroAddress.selector);
        s_vault.setEmergencyReceiver(address(0));
    }

    function test_BaseVault_setEmergencyReceiver_Success() external {
        vm.recordLogs();
        s_vault.setEmergencyReceiver(i_newEmergencyReceiver);

        Vm.Log memory log = _assertEmittedBy(keccak256("EmergencyReceiverSet(address)"), address(s_vault));
        assertEq(address(uint160(uint256(log.topics[1]))), i_newEmergencyReceiver);
        assertEq(s_vault.getEmergencyReceiver(), i_newEmergencyReceiver);
    }
}

contract ParentVault_SetEmergencyReceiverUnitTest is BaseVault_SetEmergencyReceiverUnitTest {
    function setUp() public {
        s_vault = s_parentVault;
        _changePrank(i_configOperator);
    }
}

contract ChildVault_SetEmergencyReceiverUnitTest is BaseVault_SetEmergencyReceiverUnitTest {
    function setUp() public {
        s_vault = s_childVault;
        _changePrank(i_configOperator);
    }
}

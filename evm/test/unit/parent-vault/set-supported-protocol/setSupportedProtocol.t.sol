// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {Roles} from "../../../../src/libraries/Roles.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract ParentVault_SetSupportedProtocolUnitTest is BaseUnitTest {
    bytes32 internal constant NEW_PROTOCOL_ID = keccak256("new-protocol");

    function setUp() public {
        _changePrank(i_configOperator);
    }

    function test_ParentVault_setSupportedProtocol_RevertWhen_CallerDoesNotHaveCONFIG_OPERATOR_ROLE()
        external
        whenCallerIsNotAdmin
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.CONFIG_OPERATOR_ROLE
            )
        );
        s_parentVault.setSupportedProtocol(NEW_PROTOCOL_ID, true);
    }

    function test_ParentVault_setSupportedProtocol_Success_SetsSupportedTrue() external {
        s_parentVault.setSupportedProtocol(NEW_PROTOCOL_ID, true);

        assertTrue(s_parentVault.getSupportedProtocol(NEW_PROTOCOL_ID));
    }

    function test_ParentVault_setSupportedProtocol_Success_SetsSupportedFalse() external {
        s_parentVault.setSupportedProtocol(AAVE_V3_PROTOCOL_ID, false);

        assertFalse(s_parentVault.getSupportedProtocol(AAVE_V3_PROTOCOL_ID));
    }

    function test_ParentVault_setSupportedProtocol_Success_EmitsSupportedProtocolSet() external {
        vm.recordLogs();

        s_parentVault.setSupportedProtocol(NEW_PROTOCOL_ID, true);

        Vm.Log memory log = _assertEmittedBy(keccak256("SupportedProtocolSet(bytes32,bool)"), address(s_parentVault));
        assertEq(log.topics[1], NEW_PROTOCOL_ID);
        assertEq(uint256(log.topics[2]), 1);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {BaseVault} from "../../../../src/vaults/BaseVault.sol";
import {MockPolicyEngine} from "../../../mocks/MockPolicyEngine.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

abstract contract BaseVault_AttachPolicyEngineUnitTest is BaseUnitTest {
    BaseVault internal s_vault;

    MockPolicyEngine internal s_newMockPolicyEngine;

    function test_BaseVault_attachPolicyEngine_RevertWhen_CallerDoesNotHaveCOMPLIANCE_OPERATOR_ROLE()
        external
        whenCallerIsNotAdmin
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.COMPLIANCE_OPERATOR_ROLE
            )
        );
        s_vault.attachPolicyEngine(address(s_newMockPolicyEngine));
    }

    function test_BaseVault_attachPolicyEngine_Success() external {
        vm.recordLogs();
        s_vault.attachPolicyEngine(address(s_newMockPolicyEngine));

        Vm.Log memory log = _assertEmittedBy(keccak256("PolicyEngineAttached(address)"), address(s_vault));
        assertEq(address(uint160(uint256(log.topics[1]))), address(s_newMockPolicyEngine));
        assertEq(s_vault.getPolicyEngine(), address(s_newMockPolicyEngine));
    }
}

contract ParentVault_AttachPolicyEngineUnitTest is BaseVault_AttachPolicyEngineUnitTest {
    function setUp() public {
        s_newMockPolicyEngine = new MockPolicyEngine();
        s_vault = s_parentVault;
        _changePrank(i_complianceOperator);
    }
}

contract ChildVault_AttachPolicyEngineUnitTest is BaseVault_AttachPolicyEngineUnitTest {
    function setUp() public {
        s_newMockPolicyEngine = new MockPolicyEngine();
        s_vault = s_childVault;
        _changePrank(i_complianceOperator);
    }
}

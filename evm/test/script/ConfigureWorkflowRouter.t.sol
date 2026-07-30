// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Test} from "forge-std/Test.sol";

import {ConfigureWorkflowRouter} from "../../script/interactions/ConfigureWorkflowRouter.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {WorkflowRouter} from "../../src/modules/WorkflowRouter.sol";
import {IWorkflowRouter} from "../../src/interfaces/modules/IWorkflowRouter.sol";
import {IParentVault} from "../../src/interfaces/vaults/IParentVault.sol";
import {IChildVault} from "../../src/interfaces/vaults/IChildVault.sol";

contract ConfigureWorkflowRouterTest is Test {
    bytes32 internal constant WORKFLOW_ID = keccak256("workflow-id");
    bytes10 internal constant WORKFLOW_NAME = bytes10("67d6954c97");
    address internal constant WORKFLOW_OWNER = address(0xA11CE);
    address internal constant VAULT = address(0xBEEF);

    ConfigureWorkflowRouter internal script;
    WorkflowRouter internal router;
    HelperConfig.CREConfig internal creConfig;

    function setUp() external {
        script = new ConfigureWorkflowRouter();
        router = new WorkflowRouter(
            WorkflowRouter.ConstructorParams({
                initialDelay: 0,
                defaultAdmin: address(this),
                pauser: address(this),
                unpauser: address(this),
                configOperator: address(script),
                keystoneForwarder: address(1),
                vault: VAULT
            })
        );
        creConfig = HelperConfig.CREConfig({
            keystoneForwarder: address(1),
            workflowId: WORKFLOW_ID,
            workflowName: WORKFLOW_NAME,
            workflowOwner: WORKFLOW_OWNER
        });
    }

    function test_configure_parent() external {
        script.configure(router, VAULT, creConfig, true);

        _assertMetadata();
        assertTrue(router.getAllowlistedWorkflowSelector(WORKFLOW_ID, IParentVault.closeEpoch.selector));
        assertTrue(router.getAllowlistedWorkflowSelector(WORKFLOW_ID, IParentVault.initiateRebalance.selector));
        assertTrue(router.getAllowlistedWorkflowSelector(WORKFLOW_ID, IParentVault.completeRebalance.selector));
        assertFalse(router.getAllowlistedWorkflowSelector(WORKFLOW_ID, IChildVault.executeRebalance.selector));
    }

    function test_configure_child() external {
        script.configure(router, VAULT, creConfig, false);

        _assertMetadata();
        assertTrue(router.getAllowlistedWorkflowSelector(WORKFLOW_ID, IChildVault.executeEpochWithdraw.selector));
        assertTrue(router.getAllowlistedWorkflowSelector(WORKFLOW_ID, IChildVault.executeRebalance.selector));
        assertFalse(router.getAllowlistedWorkflowSelector(WORKFLOW_ID, IParentVault.closeEpoch.selector));
    }

    function test_configure_isIdempotent() external {
        script.configure(router, VAULT, creConfig, true);
        uint256 generation = router.getWorkflowGeneration(WORKFLOW_ID);

        script.configure(router, VAULT, creConfig, true);

        assertEq(router.getWorkflowGeneration(WORKFLOW_ID), generation);
        _assertMetadata();
    }

    function test_configure_revertsOnVaultMismatch() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                ConfigureWorkflowRouter.ConfigureWorkflowRouter__VaultMismatch.selector, address(2), VAULT
            )
        );
        script.configure(router, address(2), creConfig, true);
    }

    function test_configure_revertsOnZeroValues() external {
        vm.expectRevert(ConfigureWorkflowRouter.ConfigureWorkflowRouter__ZeroRouter.selector);
        script.configure(IWorkflowRouter(address(0)), VAULT, creConfig, true);

        vm.expectRevert(ConfigureWorkflowRouter.ConfigureWorkflowRouter__ZeroVault.selector);
        script.configure(router, address(0), creConfig, true);

        HelperConfig.CREConfig memory invalid = creConfig;
        invalid.workflowId = bytes32(0);
        vm.expectRevert(ConfigureWorkflowRouter.ConfigureWorkflowRouter__ZeroWorkflowId.selector);
        script.configure(router, VAULT, invalid, true);

        invalid = creConfig;
        invalid.workflowName = bytes10(0);
        vm.expectRevert(ConfigureWorkflowRouter.ConfigureWorkflowRouter__ZeroWorkflowName.selector);
        script.configure(router, VAULT, invalid, true);

        invalid = creConfig;
        invalid.workflowOwner = address(0);
        vm.expectRevert(ConfigureWorkflowRouter.ConfigureWorkflowRouter__ZeroWorkflowOwner.selector);
        script.configure(router, VAULT, invalid, true);
    }

    function test_workflowSelectors() external view {
        bytes4[] memory parentSelectors = script.workflowSelectors(true);
        assertEq(parentSelectors.length, 3);
        assertEq(parentSelectors[0], IParentVault.closeEpoch.selector);
        assertEq(parentSelectors[1], IParentVault.initiateRebalance.selector);
        assertEq(parentSelectors[2], IParentVault.completeRebalance.selector);

        bytes4[] memory childSelectors = script.workflowSelectors(false);
        assertEq(childSelectors.length, 2);
        assertEq(childSelectors[0], IChildVault.executeEpochWithdraw.selector);
        assertEq(childSelectors[1], IChildVault.executeRebalance.selector);
    }

    function _assertMetadata() private view {
        IWorkflowRouter.WorkflowMetadata memory metadata = router.getWorkflowMetadata(WORKFLOW_ID);
        assertEq(metadata.name, WORKFLOW_NAME);
        assertEq(metadata.owner, WORKFLOW_OWNER);
    }
}

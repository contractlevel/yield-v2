// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Test} from "forge-std/Test.sol";

import {RemoveRetiredProductionWorkflows} from "../../script/interactions/RemoveRetiredProductionWorkflows.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {WorkflowRouter} from "../../src/modules/WorkflowRouter.sol";
import {IWorkflowRouter} from "../../src/interfaces/modules/IWorkflowRouter.sol";
import {IParentVault} from "../../src/interfaces/vaults/IParentVault.sol";
import {Roles} from "../../src/libraries/Roles.sol";

contract RemoveRetiredProductionWorkflowsTest is Test {
    bytes32 internal constant CURRENT_WORKFLOW_ID = keccak256("current-workflow-id");
    bytes10 internal constant WORKFLOW_NAME = bytes10("ea912058cd");
    address internal constant WORKFLOW_OWNER = address(0xA11CE);

    RemoveRetiredProductionWorkflows internal script;
    WorkflowRouter internal router;
    HelperConfig.CREConfig internal currentWorkflow;

    function setUp() external {
        script = new RemoveRetiredProductionWorkflows();
        RemoveRetiredProductionWorkflowsVaultMock vault = new RemoveRetiredProductionWorkflowsVaultMock();
        router = new WorkflowRouter(
            WorkflowRouter.ConstructorParams({
                initialDelay: 0,
                defaultAdmin: address(this),
                pauser: address(this),
                unpauser: address(this),
                configOperator: address(this),
                keystoneForwarder: address(1),
                vault: address(vault)
            })
        );
        currentWorkflow = HelperConfig.CREConfig({
            keystoneForwarder: address(1),
            workflowId: CURRENT_WORKFLOW_ID,
            workflowName: WORKFLOW_NAME,
            workflowOwner: WORKFLOW_OWNER
        });

        router.setWorkflowMetadata(CURRENT_WORKFLOW_ID, WORKFLOW_NAME, WORKFLOW_OWNER);
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = IParentVault.closeEpoch.selector;
        router.setWorkflowSelectors(CURRENT_WORKFLOW_ID, selectors, true);

        bytes32[3] memory retiredWorkflowIds = script.retiredWorkflows();
        for (uint256 i; i < retiredWorkflowIds.length; ++i) {
            router.setWorkflowMetadata(retiredWorkflowIds[i], WORKFLOW_NAME, WORKFLOW_OWNER);
            router.setWorkflowSelectors(retiredWorkflowIds[i], selectors, true);
        }

        router.grantRole(Roles.CONFIG_OPERATOR_ROLE, address(script));
    }

    function test_removeRetiredWorkflows_removesRetiredWorkflowsAndPreservesCurrentWorkflow() external {
        script.removeRetiredWorkflows(router, currentWorkflow);

        bytes32[3] memory retiredWorkflowIds = script.retiredWorkflows();
        for (uint256 i; i < retiredWorkflowIds.length; ++i) {
            IWorkflowRouter.WorkflowMetadata memory retiredMetadata = router.getWorkflowMetadata(retiredWorkflowIds[i]);
            assertEq(retiredMetadata.owner, address(0));
            assertEq(retiredMetadata.name, bytes10(0));
            assertFalse(router.getAllowlistedWorkflowSelector(retiredWorkflowIds[i], IParentVault.closeEpoch.selector));
        }

        IWorkflowRouter.WorkflowMetadata memory currentMetadata = router.getWorkflowMetadata(CURRENT_WORKFLOW_ID);
        assertEq(currentMetadata.owner, WORKFLOW_OWNER);
        assertEq(currentMetadata.name, WORKFLOW_NAME);
        assertTrue(router.getAllowlistedWorkflowSelector(CURRENT_WORKFLOW_ID, IParentVault.closeEpoch.selector));
    }

    function test_removeRetiredWorkflows_isIdempotent() external {
        script.removeRetiredWorkflows(router, currentWorkflow);
        script.removeRetiredWorkflows(router, currentWorkflow);
    }

    function test_removeRetiredWorkflows_revertsWhenCurrentWorkflowDoesNotMatch() external {
        currentWorkflow.workflowId = keccak256("unexpected-workflow-id");

        vm.expectRevert(
            RemoveRetiredProductionWorkflows.RemoveRetiredProductionWorkflows__CurrentWorkflowMismatch.selector
        );
        script.removeRetiredWorkflows(router, currentWorkflow);
    }
}

contract RemoveRetiredProductionWorkflowsVaultMock {
    function getThisChainSelector() external pure returns (uint64) {
        return 1;
    }
}

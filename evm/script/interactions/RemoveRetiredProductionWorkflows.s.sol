// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Script} from "forge-std/Script.sol";

import {HelperConfig} from "../HelperConfig.s.sol";
import {IWorkflowRouter} from "../../src/interfaces/modules/IWorkflowRouter.sol";

/// @notice Removes retired production workflow IDs from a mainnet WorkflowRouter
contract RemoveRetiredProductionWorkflows is Script {
    error RemoveRetiredProductionWorkflows__UnsupportedChain(uint256 chainId);
    error RemoveRetiredProductionWorkflows__CurrentWorkflowMismatch();
    error RemoveRetiredProductionWorkflows__RetiredWorkflowStillRegistered(bytes32 workflowId);

    bytes32 internal constant FIRST_RETIRED_WORKFLOW_ID =
        0x00d676aeb1c76877a05fb279b56e16dbd5a95bbc21820eca204629b97c964b76;
    bytes32 internal constant SECOND_RETIRED_WORKFLOW_ID =
        0x001f8a890b0e0073a7467b8dd111687c29f04ec8a99bdc5764172287c3b0083e;

    function run() external {
        if (!_isSupportedMainnet(block.chainid)) {
            revert RemoveRetiredProductionWorkflows__UnsupportedChain(block.chainid);
        }

        HelperConfig.NetworkConfig memory config = new HelperConfig().getActiveNetworkConfig();

        vm.startBroadcast(msg.sender);
        removeRetiredWorkflows(IWorkflowRouter(config.deployed.workflowRouter), config.cre);
        vm.stopBroadcast();
    }

    function removeRetiredWorkflows(IWorkflowRouter router, HelperConfig.CREConfig memory currentWorkflow) public {
        _verifyCurrentWorkflow(router, currentWorkflow);

        bytes32[2] memory retiredWorkflowIds = retiredWorkflows();
        for (uint256 i; i < retiredWorkflowIds.length; ++i) {
            bytes32 workflowId = retiredWorkflowIds[i];
            IWorkflowRouter.WorkflowMetadata memory metadata = router.getWorkflowMetadata(workflowId);
            if (metadata.owner != address(0)) {
                router.setWorkflowMetadata(workflowId, bytes10(0), address(0));
            }

            metadata = router.getWorkflowMetadata(workflowId);
            if (metadata.owner != address(0) || metadata.name != bytes10(0)) {
                revert RemoveRetiredProductionWorkflows__RetiredWorkflowStillRegistered(workflowId);
            }
        }

        _verifyCurrentWorkflow(router, currentWorkflow);
    }

    function retiredWorkflows() public pure returns (bytes32[2] memory workflowIds) {
        workflowIds = [FIRST_RETIRED_WORKFLOW_ID, SECOND_RETIRED_WORKFLOW_ID];
    }

    function _verifyCurrentWorkflow(IWorkflowRouter router, HelperConfig.CREConfig memory currentWorkflow)
        private
        view
    {
        IWorkflowRouter.WorkflowMetadata memory metadata = router.getWorkflowMetadata(currentWorkflow.workflowId);
        if (metadata.owner != currentWorkflow.workflowOwner || metadata.name != currentWorkflow.workflowName) {
            revert RemoveRetiredProductionWorkflows__CurrentWorkflowMismatch();
        }
    }

    function _isSupportedMainnet(uint256 chainId) private pure returns (bool) {
        return
            chainId == 1 || chainId == 10 || chainId == 137 || chainId == 8453 || chainId == 42_161 || chainId == 43_114;
    }
}

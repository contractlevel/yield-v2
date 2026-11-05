// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Script} from "forge-std/Script.sol";

import {HelperConfig} from "../HelperConfig.s.sol";
import {IWorkflowRouter} from "../../src/interfaces/modules/IWorkflowRouter.sol";
import {IParentVault} from "../../src/interfaces/vaults/IParentVault.sol";
import {IChildVault} from "../../src/interfaces/vaults/IChildVault.sol";

contract ConfigureWorkflowRouter is Script {
    error ConfigureWorkflowRouter__ZeroRouter();
    error ConfigureWorkflowRouter__ZeroVault();
    error ConfigureWorkflowRouter__ZeroWorkflowId();
    error ConfigureWorkflowRouter__ZeroWorkflowName();
    error ConfigureWorkflowRouter__ZeroWorkflowOwner();
    error ConfigureWorkflowRouter__VaultMismatch(address expected, address actual);
    error ConfigureWorkflowRouter__MetadataMismatch();
    error ConfigureWorkflowRouter__SelectorNotAllowlisted(bytes4 selector);
    error ConfigureWorkflowRouter__RetiredWorkflowStillRegistered();

    bytes32 internal constant RETIRED_PRODUCTION_WORKFLOW_ID =
        0x00530c56f1679de74f7aef49bbcb30e6f50c5ab46e272a9959c979d9c94152e8;

    function run() external {
        HelperConfig.NetworkConfig memory config = new HelperConfig().getActiveNetworkConfig();
        bool isParent = config.ccip.thisChainSelector == config.ccip.parentChainSelector;

        vm.startBroadcast(msg.sender);
        IWorkflowRouter router = IWorkflowRouter(config.deployed.workflowRouter);
        configure(router, config.deployed.vaultProxy, config.cre, isParent);
        if (_isSupportedMainnet(block.chainid)) retireWorkflow(router, RETIRED_PRODUCTION_WORKFLOW_ID);
        vm.stopBroadcast();
    }

    function configure(
        IWorkflowRouter router,
        address expectedVault,
        HelperConfig.CREConfig memory creConfig,
        bool isParent
    ) public {
        _validateConfig(address(router), expectedVault, creConfig);

        address actualVault = router.getVault();
        if (actualVault != expectedVault) {
            revert ConfigureWorkflowRouter__VaultMismatch(expectedVault, actualVault);
        }

        IWorkflowRouter.WorkflowMetadata memory metadata = router.getWorkflowMetadata(creConfig.workflowId);
        if (metadata.name != creConfig.workflowName || metadata.owner != creConfig.workflowOwner) {
            router.setWorkflowMetadata(creConfig.workflowId, creConfig.workflowName, creConfig.workflowOwner);
        }

        bytes4[] memory selectors = workflowSelectors(isParent);
        router.setWorkflowSelectors(creConfig.workflowId, selectors, true);

        _verifyConfig(router, creConfig, selectors);
    }

    function workflowSelectors(bool isParent) public pure returns (bytes4[] memory selectors) {
        if (isParent) {
            selectors = new bytes4[](4);
            selectors[0] = IParentVault.closeEpoch.selector;
            selectors[1] = IParentVault.completeEpochDeposit.selector;
            selectors[2] = IParentVault.initiateRebalance.selector;
            selectors[3] = IParentVault.completeRebalance.selector;
        } else {
            selectors = new bytes4[](2);
            selectors[0] = IChildVault.executeEpochWithdraw.selector;
            selectors[1] = IChildVault.executeRebalance.selector;
        }
    }

    function retireWorkflow(IWorkflowRouter router, bytes32 workflowId) public {
        IWorkflowRouter.WorkflowMetadata memory metadata = router.getWorkflowMetadata(workflowId);
        if (metadata.owner != address(0)) router.setWorkflowMetadata(workflowId, bytes10(0), address(0));

        metadata = router.getWorkflowMetadata(workflowId);
        if (metadata.name != bytes10(0) || metadata.owner != address(0)) {
            revert ConfigureWorkflowRouter__RetiredWorkflowStillRegistered();
        }
    }

    function _validateConfig(address router, address vault, HelperConfig.CREConfig memory creConfig) private pure {
        if (router == address(0)) revert ConfigureWorkflowRouter__ZeroRouter();
        if (vault == address(0)) revert ConfigureWorkflowRouter__ZeroVault();
        if (creConfig.workflowId == bytes32(0)) revert ConfigureWorkflowRouter__ZeroWorkflowId();
        if (creConfig.workflowName == bytes10(0)) revert ConfigureWorkflowRouter__ZeroWorkflowName();
        if (creConfig.workflowOwner == address(0)) revert ConfigureWorkflowRouter__ZeroWorkflowOwner();
    }

    function _verifyConfig(IWorkflowRouter router, HelperConfig.CREConfig memory creConfig, bytes4[] memory selectors)
        private
        view
    {
        IWorkflowRouter.WorkflowMetadata memory metadata = router.getWorkflowMetadata(creConfig.workflowId);
        if (metadata.name != creConfig.workflowName || metadata.owner != creConfig.workflowOwner) {
            revert ConfigureWorkflowRouter__MetadataMismatch();
        }

        for (uint256 i; i < selectors.length; ++i) {
            if (!router.getAllowlistedWorkflowSelector(creConfig.workflowId, selectors[i])) {
                revert ConfigureWorkflowRouter__SelectorNotAllowlisted(selectors[i]);
            }
        }
    }

    function _isSupportedMainnet(uint256 chainId) private pure returns (bool) {
        return
            chainId == 1 || chainId == 10 || chainId == 137 || chainId == 8453 || chainId == 42_161 || chainId == 43_114;
    }
}

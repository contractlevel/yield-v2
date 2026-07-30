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

    function run() external {
        HelperConfig.NetworkConfig memory config = new HelperConfig().getActiveNetworkConfig();
        bool isParent = config.ccip.thisChainSelector == config.ccip.parentChainSelector;

        vm.startBroadcast(msg.sender);
        configure(IWorkflowRouter(config.deployed.workflowRouter), config.deployed.vaultProxy, config.cre, isParent);
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
            selectors = new bytes4[](3);
            selectors[0] = IParentVault.closeEpoch.selector;
            selectors[1] = IParentVault.initiateRebalance.selector;
            selectors[2] = IParentVault.completeRebalance.selector;
        } else {
            selectors = new bytes4[](2);
            selectors[0] = IChildVault.executeEpochWithdraw.selector;
            selectors[1] = IChildVault.executeRebalance.selector;
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
}

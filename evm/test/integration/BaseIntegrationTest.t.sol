// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseDeploymentTest} from "../BaseDeploymentTest.t.sol";
import {StdStorage, stdStorage} from "forge-std/StdStorage.sol";

import {DeployParent} from "../../script/deploy/DeployParent.s.sol";
import {DeployChild} from "../../script/deploy/DeployChild.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

import {BaseVault} from "../../src/vaults/BaseVault.sol";
import {ParentVault} from "../../src/vaults/ParentVault.sol";
import {ChildVault} from "../../src/vaults/ChildVault.sol";
import {AdapterRegistry} from "../../src/modules/AdapterRegistry.sol";
import {AaveV3Adapter} from "../../src/modules/adapters/AaveV3Adapter.sol";
import {AaveV4Adapter} from "../../src/modules/adapters/AaveV4Adapter.sol";
import {CompoundV3Adapter} from "../../src/modules/adapters/CompoundV3Adapter.sol";
import {WorkflowRouter} from "../../src/modules/WorkflowRouter.sol";
import {YieldcoinShare} from "../../src/token/YieldcoinShare.sol";
import {IProtocolAdapter} from "../../src/interfaces/IProtocolAdapter.sol";
import {Roles} from "../../src/libraries/Roles.sol";
import {Types} from "../../src/libraries/Types.sol";

import {MockAaveV3Pool} from "../mocks/MockAaveV3Pool.sol";
import {MockAaveV3PoolAddressesProvider} from "../mocks/MockAaveV3PoolAddressesProvider.sol";
import {MockAaveV4Spoke} from "../mocks/MockAaveV4Spoke.sol";
import {MockComet} from "../mocks/MockComet.sol";
import {MockUSDC} from "../mocks/MockUSDC.sol";
import {CCIPLocalSimulator, IRouterClient, LinkToken} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {MockCCIPRouter} from "@chainlink/local/test/mocks/MockRouter.sol";

import {CredentialRegistry} from "@chainlink/cross-chain-identity/CredentialRegistry.sol";
import {IdentityRegistry} from "@chainlink/cross-chain-identity/IdentityRegistry.sol";
import {
    CredentialRegistryIdentityValidatorPolicy
} from "@chainlink/cross-chain-identity/CredentialRegistryIdentityValidatorPolicy.sol";
import {PolicyEngine} from "@chainlink/policy-management/core/PolicyEngine.sol";
import {IPolicyEngine} from "@chainlink/policy-management/interfaces/IPolicyEngine.sol";
import {OnlyAuthorizedSenderPolicy} from "@chainlink/policy-management/policies/OnlyAuthorizedSenderPolicy.sol";
import {RoleBasedAccessControlPolicy} from "@chainlink/policy-management/policies/RoleBasedAccessControlPolicy.sol";

import {
    CredentialRegistryAccountListValidatorPolicy
} from "../../src/modules/policies/CredentialRegistryAccountListValidatorPolicy.sol";
import {TerminalAllowPolicy} from "../../src/modules/policies/TerminalAllowPolicy.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract BaseIntegrationTest is BaseDeploymentTest {
    using stdStorage for StdStorage;

    struct LocalTopology {
        CCIPLocalSimulator ccipLocalSimulator;
        MockCCIPRouter mockCcipRouter;
        LinkToken link;
        MockUSDC usdc;
    }

    LocalTopology internal local;

    function _deployLocalParentChildTopology() internal {
        local.ccipLocalSimulator = new CCIPLocalSimulator();
        (, IRouterClient sourceRouter,,, LinkToken linkToken,,) = local.ccipLocalSimulator.configuration();
        local.mockCcipRouter = MockCCIPRouter(address(sourceRouter));
        local.link = linkToken;
        local.usdc = new MockUSDC();

        MockAaveV3Pool parentAaveV3Pool = new MockAaveV3Pool();
        MockAaveV3Pool childAaveV3Pool = new MockAaveV3Pool();
        MockAaveV3PoolAddressesProvider parentAaveV3PoolAddressesProvider =
            new MockAaveV3PoolAddressesProvider(address(parentAaveV3Pool));
        MockAaveV3PoolAddressesProvider childAaveV3PoolAddressesProvider =
            new MockAaveV3PoolAddressesProvider(address(childAaveV3Pool));
        MockAaveV4Spoke parentAaveV4Spoke = new MockAaveV4Spoke(address(local.usdc));
        MockAaveV4Spoke childAaveV4Spoke = new MockAaveV4Spoke(address(local.usdc));
        MockComet parentComet = new MockComet();
        MockComet childComet = new MockComet();

        HelperConfig.NetworkConfig memory parentConfig = _localConfig(
            address(parentAaveV3PoolAddressesProvider),
            address(parentAaveV4Spoke),
            address(parentComet),
            PARENT_CHAIN_SELECTOR
        );
        HelperConfig.NetworkConfig memory childConfig = _localConfig(
            address(childAaveV3PoolAddressesProvider),
            address(childAaveV4Spoke),
            address(childComet),
            CHILD_CHAIN_SELECTOR
        );
        networkConfig = parentConfig;

        DeployParent parentDeployer = new DeployParent();
        DeployParent.Deployment memory parentDeployment =
            parentDeployer.deployWithConfig(parentConfig, address(parentDeployer));
        parent = _parentFromDeployment(parentDeployment);

        DeployChild childDeployer = new DeployChild();
        DeployChild.Deployment memory childDeployment =
            childDeployer.deployWithConfig(childConfig, address(childDeployer));
        child = _childFromDeployment(childDeployment);

        _setCrosschainVault(parent.vault, CHILD_CHAIN_SELECTOR, address(child.vault));
        _setCrosschainVault(child.vault, PARENT_CHAIN_SELECTOR, address(parent.vault));
        local.mockCcipRouter.setPeerToChainSelector(address(parent.vault), PARENT_CHAIN_SELECTOR);
        local.mockCcipRouter.setPeerToChainSelector(address(child.vault), CHILD_CHAIN_SELECTOR);
        _assertLocalParentChildTopologySplit();
        _labelParentIntegrationContracts();
        _labelChildIntegrationContracts();
    }

    function _deployLocalParentTwoChildTopology() internal {
        local.ccipLocalSimulator = new CCIPLocalSimulator();
        (, IRouterClient sourceRouter,,, LinkToken linkToken,,) = local.ccipLocalSimulator.configuration();
        local.mockCcipRouter = MockCCIPRouter(address(sourceRouter));
        local.link = linkToken;
        local.usdc = new MockUSDC();

        MockAaveV3Pool parentAaveV3Pool = new MockAaveV3Pool();
        MockAaveV3Pool childAaveV3Pool = new MockAaveV3Pool();
        MockAaveV3Pool remoteChildAaveV3Pool = new MockAaveV3Pool();
        MockAaveV3PoolAddressesProvider parentAaveV3PoolAddressesProvider =
            new MockAaveV3PoolAddressesProvider(address(parentAaveV3Pool));
        MockAaveV3PoolAddressesProvider childAaveV3PoolAddressesProvider =
            new MockAaveV3PoolAddressesProvider(address(childAaveV3Pool));
        MockAaveV3PoolAddressesProvider remoteChildAaveV3PoolAddressesProvider =
            new MockAaveV3PoolAddressesProvider(address(remoteChildAaveV3Pool));
        MockAaveV4Spoke parentAaveV4Spoke = new MockAaveV4Spoke(address(local.usdc));
        MockAaveV4Spoke childAaveV4Spoke = new MockAaveV4Spoke(address(local.usdc));
        MockAaveV4Spoke remoteChildAaveV4Spoke = new MockAaveV4Spoke(address(local.usdc));
        MockComet parentComet = new MockComet();
        MockComet childComet = new MockComet();
        MockComet remoteChildComet = new MockComet();

        HelperConfig.NetworkConfig memory parentConfig = _localConfig(
            address(parentAaveV3PoolAddressesProvider),
            address(parentAaveV4Spoke),
            address(parentComet),
            PARENT_CHAIN_SELECTOR
        );
        HelperConfig.NetworkConfig memory childConfig = _localConfig(
            address(childAaveV3PoolAddressesProvider),
            address(childAaveV4Spoke),
            address(childComet),
            CHILD_CHAIN_SELECTOR
        );
        HelperConfig.NetworkConfig memory remoteChildConfig = _localConfig(
            address(remoteChildAaveV3PoolAddressesProvider),
            address(remoteChildAaveV4Spoke),
            address(remoteChildComet),
            REMOTE_CHILD_CHAIN_SELECTOR
        );
        networkConfig = parentConfig;

        DeployParent parentDeployer = new DeployParent();
        DeployParent.Deployment memory parentDeployment =
            parentDeployer.deployWithConfig(parentConfig, address(parentDeployer));
        parent = _parentFromDeployment(parentDeployment);

        DeployChild childDeployer = new DeployChild();
        DeployChild.Deployment memory childDeployment =
            childDeployer.deployWithConfig(childConfig, address(childDeployer));
        child = _childFromDeployment(childDeployment);

        DeployChild remoteChildDeployer = new DeployChild();
        DeployChild.Deployment memory remoteChildDeployment =
            remoteChildDeployer.deployWithConfig(remoteChildConfig, address(remoteChildDeployer));
        remoteChild = _childFromDeployment(remoteChildDeployment);

        _setCrosschainVault(parent.vault, CHILD_CHAIN_SELECTOR, address(child.vault));
        _setCrosschainVault(parent.vault, REMOTE_CHILD_CHAIN_SELECTOR, address(remoteChild.vault));
        _setCrosschainVault(child.vault, PARENT_CHAIN_SELECTOR, address(parent.vault));
        _setCrosschainVault(child.vault, REMOTE_CHILD_CHAIN_SELECTOR, address(remoteChild.vault));
        _setCrosschainVault(remoteChild.vault, PARENT_CHAIN_SELECTOR, address(parent.vault));
        _setCrosschainVault(remoteChild.vault, CHILD_CHAIN_SELECTOR, address(child.vault));

        local.mockCcipRouter.setPeerToChainSelector(address(parent.vault), PARENT_CHAIN_SELECTOR);
        local.mockCcipRouter.setPeerToChainSelector(address(child.vault), CHILD_CHAIN_SELECTOR);
        local.mockCcipRouter.setPeerToChainSelector(address(remoteChild.vault), REMOTE_CHILD_CHAIN_SELECTOR);

        _assertLocalParentTwoChildTopologySplit();
        _labelParentIntegrationContracts();
        _labelChildIntegrationContracts();
        _labelRemoteChildIntegrationContracts();
    }

    function _localConfig(
        address aaveV3PoolAddressesProvider,
        address aaveV4Spoke,
        address compoundV3Comet,
        uint64 thisChainSelector
    ) internal view returns (HelperConfig.NetworkConfig memory config) {
        config = networkConfig;
        config.tokens.link = address(local.link);
        config.tokens.usdc = address(local.usdc);
        config.protocols.aaveV3PoolAddressesProvider = aaveV3PoolAddressesProvider;
        config.protocols.aaveV4Spoke = aaveV4Spoke;
        config.protocols.compoundV3Comet = compoundV3Comet;
        config.ccip.router = address(local.mockCcipRouter);
        config.ccip.thisChainSelector = thisChainSelector;
        config.ccip.parentChainSelector = PARENT_CHAIN_SELECTOR;
    }

    function _assertLocalParentChildTopologySplit() internal view {
        assertEq(parent.aaveV3Adapter.getPoolAddressesProvider(), parent.aaveV3PoolAddressesProvider);
        assertEq(child.aaveV3Adapter.getPoolAddressesProvider(), child.aaveV3PoolAddressesProvider);
        assertNotEq(parent.aaveV3Adapter.getProtocolPool(), child.aaveV3Adapter.getProtocolPool());

        assertEq(parent.aaveV4Adapter.getProtocolPool(), parent.aaveV4Spoke);
        assertEq(child.aaveV4Adapter.getProtocolPool(), child.aaveV4Spoke);
        assertNotEq(parent.aaveV4Adapter.getProtocolPool(), child.aaveV4Adapter.getProtocolPool());

        assertEq(parent.compoundV3Adapter.getProtocolPool(), parent.compoundV3Comet);
        assertEq(child.compoundV3Adapter.getProtocolPool(), child.compoundV3Comet);
        assertNotEq(parent.compoundV3Adapter.getProtocolPool(), child.compoundV3Adapter.getProtocolPool());
    }

    function _assertLocalParentTwoChildTopologySplit() internal view {
        _assertLocalParentChildTopologySplit();
        assertEq(remoteChild.aaveV3Adapter.getPoolAddressesProvider(), remoteChild.aaveV3PoolAddressesProvider);
        assertNotEq(parent.aaveV3Adapter.getProtocolPool(), remoteChild.aaveV3Adapter.getProtocolPool());
        assertNotEq(child.aaveV3Adapter.getProtocolPool(), remoteChild.aaveV3Adapter.getProtocolPool());

        assertEq(remoteChild.aaveV4Adapter.getProtocolPool(), remoteChild.aaveV4Spoke);
        assertNotEq(parent.aaveV4Adapter.getProtocolPool(), remoteChild.aaveV4Adapter.getProtocolPool());
        assertNotEq(child.aaveV4Adapter.getProtocolPool(), remoteChild.aaveV4Adapter.getProtocolPool());

        assertEq(remoteChild.compoundV3Adapter.getProtocolPool(), remoteChild.compoundV3Comet);
        assertNotEq(parent.compoundV3Adapter.getProtocolPool(), remoteChild.compoundV3Adapter.getProtocolPool());
        assertNotEq(child.compoundV3Adapter.getProtocolPool(), remoteChild.compoundV3Adapter.getProtocolPool());
    }

    function _expectPolicyRevert() internal {
        vm.expectPartialRevert(IPolicyEngine.PolicyRunRejected.selector);
    }

    function _registerKyc(address account) internal {
        bytes32 ccid = keccak256(abi.encodePacked(account));

        _changePrank(networkConfig.kycProvider);
        parent.identityRegistry.registerIdentity(ccid, account, "");
        parent.credentialRegistry.registerCredential(ccid, KYC_CREDENTIAL, 0, "", "");
    }

    function _revokeKyc(address account) internal {
        bytes32 ccid = keccak256(abi.encodePacked(account));

        _changePrank(networkConfig.kycProvider);
        parent.credentialRegistry.removeCredential(ccid, KYC_CREDENTIAL, "");
    }

    function _fundAndApproveUsdc(address account, uint256 amount) internal {
        deal(parent.vault.getAsset(), account, amount);
        _changePrank(account);
        IERC20(parent.vault.getAsset()).approve(address(parent.vault), amount);
    }

    function _mintShares(address account, uint256 amount) internal {
        _changePrank(address(parent.vault));
        parent.share.mint(account, amount);
    }

    function _approveShares(address owner, address spender, uint256 amount) internal {
        _changePrank(owner);
        parent.share.approve(spender, amount);
    }

    function _setParentRemoteStrategyToChild(bytes32 protocolId) internal {
        stdstore.target(address(parent.vault)).sig("getActiveProtocolAdapter()").checked_write(address(0));
        stdstore.target(address(parent.vault)).sig("getRebalance()").depth(2).checked_write(protocolId);
        stdstore.target(address(parent.vault)).sig("getRebalance()").depth(3).checked_write(CHILD_CHAIN_SELECTOR);
    }

    function _warpPastMinEpoch() internal {
        vm.warp(block.timestamp + MIN_EPOCH_PERIOD + 1);
    }

    function _configureWorkflow(
        WorkflowRouter router,
        bytes32 workflowId,
        bytes10 workflowName,
        address workflowOwner,
        bytes4[] memory selectors
    ) internal {
        _changePrank(networkConfig.roles.configOperator);
        router.setWorkflowMetadata(workflowId, workflowName, workflowOwner);
        router.setWorkflowSelectors(workflowId, selectors, true);
    }

    function _callWorkflowRouter(
        WorkflowRouter router,
        bytes32 workflowId,
        bytes10 workflowName,
        address workflowOwner,
        bytes memory report
    ) internal {
        _changePrank(networkConfig.cre.keystoneForwarder);
        router.onReport(_buildMetadata(workflowId, workflowName, workflowOwner), report);
    }

    function _configureCloseEpochWorkflow(
        WorkflowRouter router,
        bytes32 workflowId,
        bytes10 workflowName,
        address workflowOwner
    ) internal {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = ParentVault.closeEpoch.selector;
        _configureWorkflow(router, workflowId, workflowName, workflowOwner, selectors);
    }

    function _configureExecuteEpochWithdrawWorkflow(
        WorkflowRouter router,
        bytes32 workflowId,
        bytes10 workflowName,
        address workflowOwner
    ) internal {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = ChildVault.executeEpochWithdraw.selector;
        _configureWorkflow(router, workflowId, workflowName, workflowOwner, selectors);
    }

    function _configureInitiateRebalanceWorkflow(
        WorkflowRouter router,
        bytes32 workflowId,
        bytes10 workflowName,
        address workflowOwner
    ) internal {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = ParentVault.initiateRebalance.selector;
        _configureWorkflow(router, workflowId, workflowName, workflowOwner, selectors);
    }

    function _configureCompleteRebalanceWorkflow(
        WorkflowRouter router,
        bytes32 workflowId,
        bytes10 workflowName,
        address workflowOwner
    ) internal {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = ParentVault.completeRebalance.selector;
        _configureWorkflow(router, workflowId, workflowName, workflowOwner, selectors);
    }

    function _configureExecuteRebalanceWorkflow(
        WorkflowRouter router,
        bytes32 workflowId,
        bytes10 workflowName,
        address workflowOwner
    ) internal {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = ChildVault.executeRebalance.selector;
        _configureWorkflow(router, workflowId, workflowName, workflowOwner, selectors);
    }

    function _closeEpochThroughWorkflow(
        WorkflowRouter router,
        bytes32 workflowId,
        bytes10 workflowName,
        address workflowOwner,
        uint256 tvl
    ) internal {
        _callWorkflowRouter(
            router,
            workflowId,
            workflowName,
            workflowOwner,
            abi.encodeWithSelector(ParentVault.closeEpoch.selector, tvl)
        );
    }

    function _executeEpochWithdrawThroughWorkflow(
        WorkflowRouter router,
        bytes32 workflowId,
        bytes10 workflowName,
        address workflowOwner,
        uint256 epochNonce,
        uint256 amount
    ) internal {
        _callWorkflowRouter(
            router,
            workflowId,
            workflowName,
            workflowOwner,
            abi.encodeWithSelector(ChildVault.executeEpochWithdraw.selector, epochNonce, amount)
        );
    }

    function _initiateRebalanceThroughWorkflow(
        WorkflowRouter router,
        bytes32 workflowId,
        bytes10 workflowName,
        address workflowOwner,
        Types.Strategy memory newStrategy
    ) internal {
        _callWorkflowRouter(
            router,
            workflowId,
            workflowName,
            workflowOwner,
            abi.encodeWithSelector(ParentVault.initiateRebalance.selector, newStrategy)
        );
    }

    function _completeRebalanceThroughWorkflow(
        WorkflowRouter router,
        bytes32 workflowId,
        bytes10 workflowName,
        address workflowOwner
    ) internal {
        _callWorkflowRouter(
            router,
            workflowId,
            workflowName,
            workflowOwner,
            abi.encodeWithSelector(ParentVault.completeRebalance.selector)
        );
    }

    function _executeRebalanceThroughWorkflow(
        WorkflowRouter router,
        bytes32 workflowId,
        bytes10 workflowName,
        address workflowOwner,
        uint256 rebalanceNonce,
        Types.Strategy memory newStrategy
    ) internal {
        _callWorkflowRouter(
            router,
            workflowId,
            workflowName,
            workflowOwner,
            abi.encodeWithSelector(ChildVault.executeRebalance.selector, rebalanceNonce, newStrategy)
        );
    }

    function _parentStrategy(bytes32 protocolId) internal pure returns (Types.Strategy memory strategy) {
        strategy = Types.Strategy({protocolId: protocolId, chainSelector: PARENT_CHAIN_SELECTOR});
    }

    function _childStrategy(bytes32 protocolId) internal pure returns (Types.Strategy memory strategy) {
        strategy = Types.Strategy({protocolId: protocolId, chainSelector: CHILD_CHAIN_SELECTOR});
    }

    function _remoteChildStrategy(bytes32 protocolId) internal pure returns (Types.Strategy memory strategy) {
        strategy = Types.Strategy({protocolId: protocolId, chainSelector: REMOTE_CHILD_CHAIN_SELECTOR});
    }

    function _seedParentLocalTvl(uint256 depositAmount) internal {
        _registerKyc(i_depositor);
        _fundAndApproveUsdc(i_depositor, depositAmount);

        _changePrank(i_depositor);
        parent.vault.deposit(depositAmount);

        _configureCloseEpochWorkflow(
            parent.workflowRouter, keccak256("seed-parent-local-tvl"), bytes10("closeEpoch"), i_owner
        );
        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(
            parent.workflowRouter, keccak256("seed-parent-local-tvl"), bytes10("closeEpoch"), i_owner, 0
        );

        _changePrank(i_depositor);
        parent.vault.claimShares(1);
    }

    function _seedChildLocalTvl(uint256 depositAmount) internal {
        _registerKyc(i_depositor);
        _fundAndApproveUsdc(i_depositor, depositAmount);

        _changePrank(i_depositor);
        parent.vault.deposit(depositAmount);

        _configureCloseEpochWorkflow(
            parent.workflowRouter, keccak256("seed-child-local-tvl"), bytes10("closeEpoch"), i_owner
        );
        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(
            parent.workflowRouter, keccak256("seed-child-local-tvl"), bytes10("closeEpoch"), i_owner, 0
        );

        _changePrank(i_depositor);
        parent.vault.claimShares(1);
    }

    function _setChildActiveAdapter(bytes32 protocolId) internal {
        address adapter = child.adapterRegistry.getAdapter(protocolId);
        stdstore.target(address(child.vault)).sig("getActiveProtocolAdapter()").checked_write(adapter);
    }

    function _setRemoteChildActiveAdapter(bytes32 protocolId) internal {
        address adapter = remoteChild.adapterRegistry.getAdapter(protocolId);
        stdstore.target(address(remoteChild.vault)).sig("getActiveProtocolAdapter()").checked_write(adapter);
    }

    function _assertPolicyPair(address target, bytes4 selector, address firstPolicy) internal view {
        address[] memory policies = parent.policyEngine.getPolicies(target, selector);
        assertEq(policies.length, 2);
        assertEq(policies[0], firstPolicy);
        assertEq(policies[1], address(parent.terminalAllow));
    }

    function _assertParentVaultKycPolicy(bytes4 selector) internal view {
        _assertPolicyPair(address(parent.vault), selector, address(parent.vaultKycPolicy));
    }

    function _assertShareKycPolicy(bytes4 selector) internal view {
        _assertPolicyPair(address(parent.share), selector, address(parent.shareKycPolicy));
    }

    function _assertShareRbacPolicy(bytes4 selector, bytes32 role, address account) internal view {
        _assertPolicyPair(address(parent.share), selector, address(parent.shareSupplyPolicy));
        assertTrue(parent.shareSupplyPolicy.hasAllowedRole(selector, account));
        assertTrue(parent.shareSupplyPolicy.hasRole(role, account));
    }

    function _setDefaultCcipGasLimits() internal {
        _changePrank(networkConfig.roles.configOperator);
        parent.vault.setDefaultCcipGasLimit(DEFAULT_CCIP_GAS_LIMIT);
        child.vault.setDefaultCcipGasLimit(DEFAULT_CCIP_GAS_LIMIT);
        if (address(remoteChild.vault) != address(0)) remoteChild.vault.setDefaultCcipGasLimit(DEFAULT_CCIP_GAS_LIMIT);
    }

    function test_baseIntegrationTest() public virtual {}
}

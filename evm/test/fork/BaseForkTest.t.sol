// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseDeploymentTest} from "../BaseDeploymentTest.t.sol";

import {DeployParent} from "../../script/deploy/DeployParent.s.sol";
import {DeployChild} from "../../script/deploy/DeployChild.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

import {CCIPLocalSimulatorFork, Register} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";

abstract contract BaseForkTest is BaseDeploymentTest {
    /// @dev used in protocol adapter fork tests
    uint256 internal constant WITHDRAW_AMOUNT = DEPOSIT_AMOUNT;

    struct ForkChain {
        uint256 forkId;
        uint256 chainId;
        uint64 chainSelector;
        HelperConfig.NetworkConfig config;
        Child deployment;
    }

    CCIPLocalSimulatorFork internal ccipLocalSimulatorFork;

    uint256 internal arbitrumFork;
    uint256 internal baseFork;
    uint256 internal ethereumFork;
    uint256 internal avalancheFork;
    uint256 internal optimismFork;

    HelperConfig.NetworkConfig internal arbitrumConfig;
    HelperConfig.NetworkConfig internal baseConfig;
    HelperConfig.NetworkConfig internal ethereumConfig;
    HelperConfig.NetworkConfig internal avalancheConfig;
    HelperConfig.NetworkConfig internal optimismConfig;

    address internal parentForkDeployer;
    address internal baseForkDeployer;
    address internal ethereumForkDeployer;
    address internal avalancheForkDeployer;
    address internal optimismForkDeployer;

    Child internal baseChild;
    Child internal ethereumChild;
    Child internal avalancheChild;
    Child internal optimismChild;

    function setUp() public virtual override {
        _createForks();

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));

        _deployForkTopology();
    }

    function _createForks() internal {
        arbitrumFork = vm.createSelectFork(vm.envString("ARBITRUM_MAINNET_RPC_URL"), ARBITRUM_FORK_BLOCK);
        baseFork = vm.createFork(vm.envString("BASE_MAINNET_RPC_URL"), BASE_FORK_BLOCK);
        ethereumFork = vm.createFork(vm.envString("ETHEREUM_MAINNET_RPC_URL"), ETHEREUM_FORK_BLOCK);
        avalancheFork = vm.createFork(vm.envString("AVALANCHE_MAINNET_RPC_URL"), AVALANCHE_FORK_BLOCK);
        optimismFork = vm.createFork(vm.envString("OPTIMISM_MAINNET_RPC_URL"), OPTIMISM_FORK_BLOCK);
    }

    function _deployForkTopology() internal {
        HelperConfig configHelper = new HelperConfig();

        _selectArbitrumFork();
        arbitrumConfig = configHelper.getArbitrumConfig();
        baseConfig = configHelper.getBaseConfig();
        ethereumConfig = configHelper.getEthereumConfig();
        avalancheConfig = configHelper.getAvalancheConfig();
        optimismConfig = configHelper.getOptimismConfig();
        _setForkNetworkDetails(arbitrumConfig);
        _setForkNetworkDetails(baseConfig);
        _setForkNetworkDetails(ethereumConfig);
        _setForkNetworkDetails(avalancheConfig);
        _setForkNetworkDetails(optimismConfig);
        networkConfig = arbitrumConfig;
        _assertNetworkDetails(arbitrumConfig);

        DeployParent parentDeployer = new DeployParent();
        parentForkDeployer = address(parentDeployer);
        parent = _parentFromDeployment(parentDeployer.deployWithConfig(arbitrumConfig, parentForkDeployer));
        _makeParentPersistent(parent);
        _labelParentIntegrationContracts();

        (baseChild, baseForkDeployer) = _deployForkChild(baseFork, baseConfig);
        (ethereumChild, ethereumForkDeployer) = _deployForkChild(ethereumFork, ethereumConfig);
        (avalancheChild, avalancheForkDeployer) = _deployForkChild(avalancheFork, avalancheConfig);
        (optimismChild, optimismForkDeployer) = _deployForkChild(optimismFork, optimismConfig);

        _configureForkCrosschainVaults();
    }

    function _deployForkChild(uint256 forkId, HelperConfig.NetworkConfig memory config)
        internal
        returns (Child memory forkChild, address forkDeployer)
    {
        vm.selectFork(forkId);
        networkConfig = config;
        _assertNetworkDetails(config);

        DeployChild childDeployer = new DeployChild();
        forkDeployer = address(childDeployer);
        forkChild = _childFromDeployment(childDeployer.deployWithConfig(config, forkDeployer));
        _makeChildPersistent(forkChild);
    }

    function _makeParentPersistent(Parent memory forkParent) internal {
        vm.makePersistent(address(forkParent.adapterRegistry));
        vm.makePersistent(address(forkParent.shareImpl));
        vm.makePersistent(address(forkParent.share));
        vm.makePersistent(address(forkParent.vaultImpl));
        vm.makePersistent(address(forkParent.vault));
        vm.makePersistent(address(forkParent.workflowRouter));
        vm.makePersistent(address(forkParent.policyEngine));
        vm.makePersistent(address(forkParent.identityRegistry));
        vm.makePersistent(address(forkParent.credentialRegistry));
        vm.makePersistent(address(forkParent.vaultKycPolicy));
        vm.makePersistent(address(forkParent.shareKycPolicy));
        vm.makePersistent(address(forkParent.shareSupplyPolicy));
        vm.makePersistent(address(forkParent.providerPolicy));
        vm.makePersistent(address(forkParent.terminalAllow));
        if (address(forkParent.aaveV3Adapter) != address(0)) vm.makePersistent(address(forkParent.aaveV3Adapter));
        if (address(forkParent.aaveV4Adapter) != address(0)) vm.makePersistent(address(forkParent.aaveV4Adapter));
        if (address(forkParent.compoundV3Adapter) != address(0)) {
            vm.makePersistent(address(forkParent.compoundV3Adapter));
        }
    }

    function _makeChildPersistent(Child memory forkChild) internal {
        vm.makePersistent(address(forkChild.adapterRegistry));
        vm.makePersistent(address(forkChild.vaultImpl));
        vm.makePersistent(address(forkChild.vault));
        vm.makePersistent(address(forkChild.workflowRouter));
        if (address(forkChild.aaveV3Adapter) != address(0)) vm.makePersistent(address(forkChild.aaveV3Adapter));
        if (address(forkChild.aaveV4Adapter) != address(0)) vm.makePersistent(address(forkChild.aaveV4Adapter));
        if (address(forkChild.compoundV3Adapter) != address(0)) {
            vm.makePersistent(address(forkChild.compoundV3Adapter));
        }
    }

    function _configureForkCrosschainVaults() internal {
        _selectArbitrumFork();
        networkConfig = arbitrumConfig;
        _setCrosschainVault(parent.vault, baseConfig.ccip.thisChainSelector, address(baseChild.vault));
        _setCrosschainVault(parent.vault, ethereumConfig.ccip.thisChainSelector, address(ethereumChild.vault));
        _setCrosschainVault(parent.vault, avalancheConfig.ccip.thisChainSelector, address(avalancheChild.vault));
        _setCrosschainVault(parent.vault, optimismConfig.ccip.thisChainSelector, address(optimismChild.vault));

        _configureChildCrosschainVault(baseFork, baseConfig, baseChild);
        _configureChildCrosschainVault(ethereumFork, ethereumConfig, ethereumChild);
        _configureChildCrosschainVault(avalancheFork, avalancheConfig, avalancheChild);
        _configureChildCrosschainVault(optimismFork, optimismConfig, optimismChild);
    }

    function _configureChildCrosschainVault(
        uint256 forkId,
        HelperConfig.NetworkConfig memory config,
        Child memory forkChild
    ) internal {
        vm.selectFork(forkId);
        networkConfig = config;
        _setCrosschainVault(forkChild.vault, arbitrumConfig.ccip.thisChainSelector, address(parent.vault));
    }

    function _assertNetworkDetails(HelperConfig.NetworkConfig memory config) internal view {
        Register.NetworkDetails memory details = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        assertEq(details.chainSelector, config.ccip.thisChainSelector);
        assertEq(details.routerAddress, config.ccip.router);
        assertEq(details.linkAddress, config.tokens.link);
    }

    function _setForkNetworkDetails(HelperConfig.NetworkConfig memory config) internal {
        ccipLocalSimulatorFork.setNetworkDetails(
            _chainIdFromSelector(config.ccip.thisChainSelector),
            Register.NetworkDetails({
                chainSelector: config.ccip.thisChainSelector,
                routerAddress: config.ccip.router,
                linkAddress: config.tokens.link,
                wrappedNativeAddress: address(0),
                ccipBnMAddress: address(0),
                ccipLnMAddress: address(0),
                rmnProxyAddress: address(0),
                registryModuleOwnerCustomAddress: address(0),
                tokenAdminRegistryAddress: address(0)
            })
        );
    }

    function _chainIdFromSelector(uint64 chainSelector) internal pure returns (uint256) {
        if (chainSelector == 4949039107694359620) return ARBITRUM_CHAIN_ID;
        if (chainSelector == 15971525489660198786) return BASE_CHAIN_ID;
        if (chainSelector == 5009297550715157269) return ETHEREUM_CHAIN_ID;
        if (chainSelector == 6433500567565415381) return AVALANCHE_CHAIN_ID;
        if (chainSelector == 3734403246176062136) return OPTIMISM_CHAIN_ID;
        revert("BaseForkTest: unknown chain selector");
    }

    function _selectArbitrumFork() internal {
        vm.selectFork(arbitrumFork);
        networkConfig = arbitrumConfig;
    }

    function _selectBaseFork() internal {
        vm.selectFork(baseFork);
        networkConfig = baseConfig;
        child = baseChild;
    }

    function _selectEthereumFork() internal {
        vm.selectFork(ethereumFork);
        networkConfig = ethereumConfig;
        child = ethereumChild;
    }

    function _selectAvalancheFork() internal {
        vm.selectFork(avalancheFork);
        networkConfig = avalancheConfig;
        child = avalancheChild;
    }

    function _selectOptimismFork() internal {
        vm.selectFork(optimismFork);
        networkConfig = optimismConfig;
        child = optimismChild;
    }

    function _routeFromActiveForkTo(uint256 forkId) internal {
        ccipLocalSimulatorFork.switchChainAndRouteMessage(forkId);
    }

    function _routeFromActiveForkTo(uint256[] memory forkIds) internal {
        ccipLocalSimulatorFork.switchChainAndRouteMessage(forkIds);
    }

    function test_baseForkTest() public virtual {}
}

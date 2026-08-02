// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseSetup} from "@chimera/BaseSetup.sol";
import {BaseIntegrationTest} from "../../integration/BaseIntegrationTest.t.sol";
import {MockAToken} from "../../mocks/MockAToken.sol";
import {MockAaveV3Pool} from "../../mocks/MockAaveV3Pool.sol";
import {MockAaveV4Spoke} from "../../mocks/MockAaveV4Spoke.sol";
import {MockComet} from "../../mocks/MockComet.sol";
import {MockUSDC} from "../../mocks/MockUSDC.sol";
import {Types} from "../../../src/libraries/Types.sol";
import {BaseVault} from "../../../src/vaults/BaseVault.sol";

abstract contract Setup is BaseSetup, BaseIntegrationTest {
    bytes32 internal constant CLOSE_EPOCH_WORKFLOW_ID = keccak256("invariant-close-epoch");
    bytes32 internal constant INITIATE_REBALANCE_WORKFLOW_ID = keccak256("invariant-initiate-rebalance");
    bytes32 internal constant EXECUTE_REBALANCE_WORKFLOW_ID = keccak256("invariant-execute-rebalance");
    bytes32 internal constant COMPLETE_REBALANCE_WORKFLOW_ID = keccak256("invariant-complete-rebalance");
    bytes32 internal constant EXECUTE_EPOCH_WITHDRAW_WORKFLOW_ID = keccak256("invariant-execute-epoch-withdraw");
    bytes10 internal constant CLOSE_EPOCH_WORKFLOW_NAME = bytes10("closeEpoch");
    bytes10 internal constant INITIATE_REBALANCE_WORKFLOW_NAME = bytes10("rebalance");
    bytes10 internal constant EXECUTE_REBALANCE_WORKFLOW_NAME = bytes10("execRb");
    bytes10 internal constant COMPLETE_REBALANCE_WORKFLOW_NAME = bytes10("completeRb");
    bytes10 internal constant EXECUTE_EPOCH_WITHDRAW_WORKFLOW_NAME = bytes10("epochDraw");

    uint256 internal constant MAX_DEPOSIT_AMOUNT = 1_000_000 * 1e6;
    uint256 internal constant INVARIANT_PROTOCOL_USDC_LIQUIDITY = type(uint128).max;

    function setup() internal virtual override {
        super.setUp();

        _deployLocalParentTwoChildTopology();
        _assertInitialInvariantState();
        _configureCloseEpochWorkflow(parent.workflowRouter, CLOSE_EPOCH_WORKFLOW_ID, CLOSE_EPOCH_WORKFLOW_NAME, i_owner);
        _configureInitiateRebalanceWorkflow(
            parent.workflowRouter, INITIATE_REBALANCE_WORKFLOW_ID, INITIATE_REBALANCE_WORKFLOW_NAME, i_owner
        );
        _configureExecuteRebalanceWorkflow(
            child.workflowRouter, EXECUTE_REBALANCE_WORKFLOW_ID, EXECUTE_REBALANCE_WORKFLOW_NAME, i_owner
        );
        _configureExecuteEpochWithdrawWorkflow(
            child.workflowRouter, EXECUTE_EPOCH_WITHDRAW_WORKFLOW_ID, EXECUTE_EPOCH_WITHDRAW_WORKFLOW_NAME, i_owner
        );
        _configureExecuteRebalanceWorkflow(
            remoteChild.workflowRouter, EXECUTE_REBALANCE_WORKFLOW_ID, EXECUTE_REBALANCE_WORKFLOW_NAME, i_owner
        );
        _configureExecuteEpochWithdrawWorkflow(
            remoteChild.workflowRouter,
            EXECUTE_EPOCH_WITHDRAW_WORKFLOW_ID,
            EXECUTE_EPOCH_WITHDRAW_WORKFLOW_NAME,
            i_owner
        );
        _configureCompleteRebalanceWorkflow(
            parent.workflowRouter, COMPLETE_REBALANCE_WORKFLOW_ID, COMPLETE_REBALANCE_WORKFLOW_NAME, i_owner
        );
        _setDefaultCcipGasLimits();

        _setupInvariantProtocolLiquidity();
        _setupInvariantActors();
    }

    function _assertInitialInvariantState() internal view {
        require(child.vault.getLastHandledEpochNonce() == 0, "NONCE-001: child epoch nonce not zero");
        require(child.vault.getLastHandledRebalanceNonce() == 0, "NONCE-001: child rebalance nonce not zero");
        require(remoteChild.vault.getLastHandledEpochNonce() == 0, "NONCE-001: remote epoch nonce not zero");
        require(remoteChild.vault.getLastHandledRebalanceNonce() == 0, "NONCE-001: remote rebalance nonce not zero");

        Types.Epoch memory epoch = parent.vault.getEpoch(1);
        Types.Rebalance memory rebalance = parent.vault.getRebalance();
        require(parent.vault.getEpochNonce() == 1, "NONCE-008/UPGRADE-003: initial epoch nonce mismatch");
        require(rebalance.nonce == 1, "NONCE-008/UPGRADE-003: initial rebalance nonce mismatch");
        require(epoch.status == Types.EpochStatus.OPEN, "UPGRADE-003: initial epoch is not open");
        require(epoch.openedAtTimestamp != 0, "UPGRADE-003: initial epoch timestamp missing");
        require(rebalance.state == Types.RebalanceState.NONE, "UPGRADE-003: initial rebalance state mismatch");
        require(rebalance.lastRebalanceCompletedTimestamp != 0, "UPGRADE-003: rebalance timestamp missing");
        require(
            parent.vault.getPerformanceFeeHighWaterMark() == ASSET_PRECISION,
            "UPGRADE-003: initial high-water mark mismatch"
        );
        require(parent.vault.getTotalShares() == 0, "UPGRADE-003: initial shares not zero");
        require(parent.vault.getRecoveryMode() == Types.RecoveryMode.NONE, "UPGRADE-003: initial recovery active");

        _assertVaultImmutableConfiguration(parent.vault, parent.vaultImpl, address(parent.adapterRegistry));
        _assertVaultImmutableConfiguration(child.vault, child.vaultImpl, address(child.adapterRegistry));
        _assertVaultImmutableConfiguration(
            remoteChild.vault, remoteChild.vaultImpl, address(remoteChild.adapterRegistry)
        );
        require(parent.vault.getShare() == address(parent.share), "UPGRADE-005: parent share mismatch");
        require(
            child.vault.getParentChainSelector() == PARENT_CHAIN_SELECTOR, "UPGRADE-005: child parent selector mismatch"
        );
        require(
            remoteChild.vault.getParentChainSelector() == PARENT_CHAIN_SELECTOR,
            "UPGRADE-005: remote child parent selector mismatch"
        );
        require(parent.workflowRouter.getVault() == address(parent.vault), "UPGRADE-005: parent router mismatch");
        require(child.workflowRouter.getVault() == address(child.vault), "UPGRADE-005: child router mismatch");
        require(
            remoteChild.workflowRouter.getVault() == address(remoteChild.vault),
            "UPGRADE-005: remote child router mismatch"
        );
    }

    function _assertVaultImmutableConfiguration(BaseVault proxy, BaseVault implementation, address registry)
        internal
        view
    {
        require(proxy.getAsset() == implementation.getAsset(), "UPGRADE-005: implementation asset mismatch");
        require(proxy.getLink() == implementation.getLink(), "UPGRADE-005: implementation LINK mismatch");
        require(proxy.getRouter() == implementation.getRouter(), "UPGRADE-005: implementation router mismatch");
        require(
            proxy.getThisChainSelector() == implementation.getThisChainSelector(),
            "UPGRADE-005: implementation chain selector mismatch"
        );
        require(proxy.getAdapterRegistry() == registry, "UPGRADE-005: proxy registry mismatch");
        require(
            proxy.getAdapterRegistry() == implementation.getAdapterRegistry(),
            "UPGRADE-005: implementation registry mismatch"
        );
    }

    function _setupInvariantActors() internal virtual {}

    function _boundToRange(uint256 value, uint256 min, uint256 max) internal pure returns (uint256) {
        if (value < min || value > max) return min + (value % (max - min + 1));
        return value;
    }

    function _setupInvariantProtocolLiquidity() internal {
        _setupProtocolLiquidity(
            parent.aaveV3Adapter.getProtocolPool(),
            parent.aaveV4Adapter.getProtocolPool(),
            parent.compoundV3Adapter.getProtocolPool()
        );
        _setupProtocolLiquidity(
            child.aaveV3Adapter.getProtocolPool(),
            child.aaveV4Adapter.getProtocolPool(),
            child.compoundV3Adapter.getProtocolPool()
        );
        _setupProtocolLiquidity(
            remoteChild.aaveV3Adapter.getProtocolPool(),
            remoteChild.aaveV4Adapter.getProtocolPool(),
            remoteChild.compoundV3Adapter.getProtocolPool()
        );
    }

    function _setupProtocolLiquidity(address aaveV3Pool, address aaveV4Spoke, address comet) internal {
        MockUSDC usdc = MockUSDC(parent.vault.getAsset());
        MockAToken aToken = new MockAToken();

        usdc.mint(aaveV3Pool, INVARIANT_PROTOCOL_USDC_LIQUIDITY);
        usdc.mint(aaveV4Spoke, INVARIANT_PROTOCOL_USDC_LIQUIDITY);
        usdc.mint(comet, INVARIANT_PROTOCOL_USDC_LIQUIDITY);

        MockAaveV3Pool(aaveV3Pool).setATokenAddress(address(usdc), address(aToken));
    }

    function _setActiveStrategyWithdrawReturn(uint256 amount) internal {
        Types.Strategy memory activeStrategy = parent.vault.getRebalance().activeStrategy;

        if (activeStrategy.chainSelector == PARENT_CHAIN_SELECTOR) {
            _setParentActiveProtocolWithdrawReturn(amount);
        } else if (activeStrategy.chainSelector == CHILD_CHAIN_SELECTOR) {
            _setChildActiveProtocolWithdrawReturn(amount);
        } else if (activeStrategy.chainSelector == REMOTE_CHILD_CHAIN_SELECTOR) {
            _setRemoteChildActiveProtocolWithdrawReturn(amount);
        }
    }

    function _setParentActiveProtocolWithdrawReturn(uint256 amount) internal {
        _setProtocolWithdrawReturn(
            parent.vault.getActiveProtocolAdapter(),
            address(parent.aaveV3Adapter),
            address(parent.aaveV4Adapter),
            address(parent.compoundV3Adapter),
            parent.aaveV3Adapter.getProtocolPool(),
            parent.aaveV4Adapter.getProtocolPool(),
            parent.compoundV3Adapter.getProtocolPool(),
            amount
        );
    }

    function _setChildActiveProtocolWithdrawReturn(uint256 amount) internal {
        _setProtocolWithdrawReturn(
            child.vault.getActiveProtocolAdapter(),
            address(child.aaveV3Adapter),
            address(child.aaveV4Adapter),
            address(child.compoundV3Adapter),
            child.aaveV3Adapter.getProtocolPool(),
            child.aaveV4Adapter.getProtocolPool(),
            child.compoundV3Adapter.getProtocolPool(),
            amount
        );
    }

    function _setRemoteChildActiveProtocolWithdrawReturn(uint256 amount) internal {
        _setProtocolWithdrawReturn(
            remoteChild.vault.getActiveProtocolAdapter(),
            address(remoteChild.aaveV3Adapter),
            address(remoteChild.aaveV4Adapter),
            address(remoteChild.compoundV3Adapter),
            remoteChild.aaveV3Adapter.getProtocolPool(),
            remoteChild.aaveV4Adapter.getProtocolPool(),
            remoteChild.compoundV3Adapter.getProtocolPool(),
            amount
        );
    }

    function _setProtocolWithdrawReturn(
        address activeAdapter,
        address aaveV3Adapter,
        address aaveV4Adapter,
        address compoundV3Adapter,
        address aaveV3Pool,
        address aaveV4Spoke,
        address comet,
        uint256 amount
    ) internal {
        if (activeAdapter == aaveV3Adapter) {
            MockAaveV3Pool(aaveV3Pool).setWithdrawReturn(amount);
        } else if (activeAdapter == aaveV4Adapter) {
            MockAaveV4Spoke(aaveV4Spoke).setWithdrawReturn(amount);
        } else if (activeAdapter == compoundV3Adapter) {
            MockComet(comet).setWithdrawReturn(amount);
        }
    }

    function _activeStrategyTvl() internal view returns (uint256) {
        uint64 chainSelector = parent.vault.getRebalance().activeStrategy.chainSelector;

        if (chainSelector == PARENT_CHAIN_SELECTOR) return parent.vault.getTVL();
        if (chainSelector == CHILD_CHAIN_SELECTOR) return child.vault.getTVL();
        if (chainSelector == REMOTE_CHILD_CHAIN_SELECTOR) return remoteChild.vault.getTVL();

        return 0;
    }

    function _activeVault() internal view returns (BaseVault) {
        uint64 chainSelector = parent.vault.getRebalance().activeStrategy.chainSelector;

        if (chainSelector == PARENT_CHAIN_SELECTOR) return parent.vault;
        if (chainSelector == CHILD_CHAIN_SELECTOR) return child.vault;
        if (chainSelector == REMOTE_CHILD_CHAIN_SELECTOR) return remoteChild.vault;

        return parent.vault;
    }
}

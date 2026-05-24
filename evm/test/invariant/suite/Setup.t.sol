// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseSetup} from "@chimera/BaseSetup.sol";
import {BaseIntegrationTest} from "../../integration/BaseIntegrationTest.t.sol";
import {MockAToken} from "../../mocks/MockAToken.sol";
import {MockAaveV3Pool} from "../../mocks/MockAaveV3Pool.sol";
import {MockAaveV4Spoke} from "../../mocks/MockAaveV4Spoke.sol";
import {MockComet} from "../../mocks/MockComet.sol";
import {MockUSDC} from "../../mocks/MockUSDC.sol";

abstract contract Setup is BaseSetup, BaseIntegrationTest {
    bytes32 internal constant CLOSE_EPOCH_WORKFLOW_ID = keccak256("invariant-close-epoch");
    bytes10 internal constant CLOSE_EPOCH_WORKFLOW_NAME = bytes10("closeEpoch");

    uint256 internal constant MAX_DEPOSIT_AMOUNT = 1_000_000 * 1e6;
    uint256 internal constant INVARIANT_PROTOCOL_USDC_LIQUIDITY = type(uint128).max;

    function setup() internal virtual override {
        super.setUp();

        _deployLocalParentTwoChildTopology();
        _configureCloseEpochWorkflow(parent.workflowRouter, CLOSE_EPOCH_WORKFLOW_ID, CLOSE_EPOCH_WORKFLOW_NAME, i_owner);
        _setDefaultCcipGasLimits();

        _setupInvariantProtocolLiquidity();
        _setupInvariantActors();
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
        MockUSDC usdc = MockUSDC(parent.vault.getUsdc());
        MockAToken aToken = new MockAToken();

        usdc.mint(aaveV3Pool, INVARIANT_PROTOCOL_USDC_LIQUIDITY);
        usdc.mint(aaveV4Spoke, INVARIANT_PROTOCOL_USDC_LIQUIDITY);
        usdc.mint(comet, INVARIANT_PROTOCOL_USDC_LIQUIDITY);

        MockAaveV3Pool(aaveV3Pool).setATokenAddress(address(aToken));
        MockAaveV3Pool(aaveV3Pool).setUpdatesATokenBalance(true);
    }

    function _setParentActiveProtocolExpectedWithdraw(uint256 amount) internal {
        address activeAdapter = parent.vault.getActiveProtocolAdapter();

        if (activeAdapter == address(parent.aaveV3Adapter)) {
            MockAaveV3Pool(parent.aaveV3Adapter.getProtocolPool()).setExpectedWithdrawAmount(amount);
        } else if (activeAdapter == address(parent.aaveV4Adapter)) {
            MockAaveV4Spoke(parent.aaveV4Adapter.getProtocolPool()).setExpectedWithdrawAmount(amount);
        } else if (activeAdapter == address(parent.compoundV3Adapter)) {
            MockComet(parent.compoundV3Adapter.getProtocolPool()).setExpectedWithdrawAmount(amount);
        }
    }

    function _activeStrategyTvl() internal view returns (uint256) {
        uint64 chainSelector = parent.vault.getRebalance().activeStrategy.chainSelector;

        if (chainSelector == PARENT_CHAIN_SELECTOR) return parent.vault.getTVL();
        if (chainSelector == CHILD_CHAIN_SELECTOR) return child.vault.getTVL();
        if (chainSelector == REMOTE_CHILD_CHAIN_SELECTOR) return remoteChild.vault.getTVL();

        return 0;
    }
}

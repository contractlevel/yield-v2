// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseCcipForkTest} from "../../BaseCcipForkTest.t.sol";
import {Types} from "../../../../../src/libraries/Types.sol";

contract ChildDeposit_CcipForkTest is BaseCcipForkTest {
    bytes32 private constant CLOSE_WORKFLOW_ID = keccak256("ccip-fork-child-deposit-close");

    function setUp() public override {
        super.setUp();
        _selectBaseFork();
        _configureCloseEpochWorkflow(CLOSE_WORKFLOW_ID);
        _setParentRemoteStrategyToArbitrum();
        _setArbitrumChildActiveAdapterToAaveV3();
    }

    function test_CcipFork_epochChildDeposit_RoutesUsdcToChildStrategy() external {
        _selectBaseFork();

        _fundAndApproveParentUsdc(i_depositor, DEPOSIT_AMOUNT);

        _changePrank(i_depositor);
        parent.vault.deposit(DEPOSIT_AMOUNT);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(CLOSE_WORKFLOW_ID, 0);

        _selectBaseFork();
        _setArbitrumChildActiveAdapterToAaveV3();
        _selectBaseFork();
        _routeUsdcMessageTo(arbitrumFork);

        _selectBaseFork();
        assertEq(uint256(parent.vault.getEpoch(1).status), uint256(Types.EpochStatus.EXECUTING));
        _completeEpochDepositThroughWorkflow(CLOSE_WORKFLOW_ID, 1, DEPOSIT_AMOUNT);
        assertEq(uint256(parent.vault.getEpoch(1).status), uint256(Types.EpochStatus.CLAIMABLE));
        assertEq(parent.vault.getEpochNonce(), 2);

        _selectArbitrumFork();
        assertApproxEqAbs(arbitrumChild.aaveV3Adapter.getTVL(), DEPOSIT_AMOUNT, PROTOCOL_FORK_TOLERANCE);
        assertEq(arbitrumChild.vault.getActiveProtocolAdapter(), address(arbitrumChild.aaveV3Adapter));
    }

    function test_CcipFork_epochChildDeposit_RoutesUsdcToPolygonStrategy() external {
        _setParentRemoteStrategyToPolygon();
        _setPolygonChildActiveAdapterToAaveV3();
        _selectBaseFork();

        _fundAndApproveParentUsdc(i_depositor, DEPOSIT_AMOUNT);

        _changePrank(i_depositor);
        parent.vault.deposit(DEPOSIT_AMOUNT);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(CLOSE_WORKFLOW_ID, 0);

        _selectBaseFork();
        _setPolygonChildActiveAdapterToAaveV3();
        _selectBaseFork();
        _routeUsdcMessageTo(polygonFork);

        _selectBaseFork();
        assertEq(uint256(parent.vault.getEpoch(1).status), uint256(Types.EpochStatus.EXECUTING));
        _completeEpochDepositThroughWorkflow(CLOSE_WORKFLOW_ID, 1, DEPOSIT_AMOUNT);
        assertEq(uint256(parent.vault.getEpoch(1).status), uint256(Types.EpochStatus.CLAIMABLE));
        assertEq(parent.vault.getEpochNonce(), 2);

        _selectPolygonFork();
        assertApproxEqAbs(polygonChild.aaveV3Adapter.getTVL(), DEPOSIT_AMOUNT, PROTOCOL_FORK_TOLERANCE);
        assertEq(polygonChild.vault.getActiveProtocolAdapter(), address(polygonChild.aaveV3Adapter));
    }
}

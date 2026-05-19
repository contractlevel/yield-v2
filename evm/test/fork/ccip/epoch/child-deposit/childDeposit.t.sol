// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseCcipForkTest} from "../../BaseCcipForkTest.t.sol";
import {Types} from "../../../../../src/libraries/Types.sol";

contract ChildDeposit_CcipForkTest is BaseCcipForkTest {
    bytes32 private constant CLOSE_WORKFLOW_ID = keccak256("ccip-fork-child-deposit-close");

    function setUp() public override {
        super.setUp();
        _selectArbitrumFork();
        _configureCloseEpochWorkflow(CLOSE_WORKFLOW_ID);
        _setParentRemoteStrategyToBase();
        _setBaseChildActiveAdapterToAaveV3();
    }

    function test_CcipFork_epochChildDeposit_RoutesUsdcToChildStrategy() external {
        _selectArbitrumFork();
        (uint256 netDepositAmount,) = parent.vault.getNetAmountAndOperationFee(DEPOSIT_AMOUNT);

        _registerKyc(i_depositor);
        _fundAndApproveParentUsdc(i_depositor, DEPOSIT_AMOUNT);

        _changePrank(i_depositor);
        parent.vault.deposit(DEPOSIT_AMOUNT);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(CLOSE_WORKFLOW_ID, 1, 0);

        _selectArbitrumFork();
        _setBaseChildActiveAdapterToAaveV3();
        _selectArbitrumFork();
        _routeUsdcMessageTo(baseFork);

        _selectArbitrumFork();
        assertEq(uint256(parent.vault.getEpoch(1).status), uint256(Types.EpochStatus.CLAIMABLE));
        assertEq(parent.vault.getEpochNonce(), 2);

        _selectBaseFork();
        assertApproxEqAbs(baseChild.aaveV3Adapter.getTVL(), netDepositAmount, PROTOCOL_FORK_TOLERANCE);
        assertEq(baseChild.vault.getActiveProtocolAdapter(), address(baseChild.aaveV3Adapter));
    }
}

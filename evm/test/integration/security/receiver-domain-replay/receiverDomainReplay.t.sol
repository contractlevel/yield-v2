// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseIntegrationTest} from "../../BaseIntegrationTest.t.sol";

import {ParentVault} from "../../../../src/vaults/ParentVault.sol";
import {Types} from "../../../../src/libraries/Types.sol";
import {KeystoneForwarder} from "@chainlink/contracts/cre/src/v1/KeystoneForwarder.sol";
import {IRouter} from "@chainlink/contracts/cre/src/v1/interfaces/IRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ReceiverDomainReplayTest is BaseIntegrationTest {
    bytes32 private constant CLOSE_ID = keccak256("h02-close");
    bytes32 private constant INIT_ID = keccak256("h02-init");
    bytes32 private constant COMPLETE_ID = keccak256("h02-complete");
    bytes32 private constant CHILD_EPOCH_ID = keccak256("h02-shared-child");
    bytes32 private constant CHILD_REBALANCE_ID = keccak256("h02-rebalance");
    bytes10 private constant CLOSE_NAME = bytes10("h02close");
    bytes10 private constant INIT_NAME = bytes10("h02init");
    bytes10 private constant COMPLETE_NAME = bytes10("h02done");
    bytes10 private constant CHILD_EPOCH_NAME = bytes10("h02child");
    bytes10 private constant CHILD_REBALANCE_NAME = bytes10("h02reb");

    bytes32 private constant WORKFLOW_EXECUTION_ID = keccak256("h02-execution");
    bytes2 private constant REPORT_ID = 0x0001;
    uint32 private constant DON_ID = 1;
    uint32 private constant CONFIG_VERSION = 1;
    uint256 private constant SIGNER_1_PK = 0xA11CE;
    uint256 private constant SIGNER_2_PK = 0xB0B;
    uint256 private constant SIGNER_3_PK = 0xCAFE;
    uint256 private constant SIGNER_4_PK = 0xD00D;

    struct Replay {
        uint256 nonce;
        uint256 amount;
        uint256 destinationTvl;
        bytes rawReport;
        bytes reportContext;
        bytes[] signatures;
    }

    KeystoneForwarder private s_forwarder;

    function setUp() public override {
        super.setUp();
        vm.stopPrank();
        s_forwarder = new KeystoneForwarder();
        networkConfig.cre.keystoneForwarder = address(s_forwarder);
        _configureSigners();

        _deployLocalParentTwoChildTopology();
        _setDefaultCcipGasLimits();
        _configureCloseEpochWorkflow(parent.workflowRouter, CLOSE_ID, CLOSE_NAME, i_owner);
        _configureInitiateRebalanceWorkflow(parent.workflowRouter, INIT_ID, INIT_NAME, i_owner);
        _configureCompleteRebalanceWorkflow(parent.workflowRouter, COMPLETE_ID, COMPLETE_NAME, i_owner);
        _configureExecuteEpochWithdrawWorkflow(child.workflowRouter, CHILD_EPOCH_ID, CHILD_EPOCH_NAME, i_owner);
        _configureExecuteEpochWithdrawWorkflow(remoteChild.workflowRouter, CHILD_EPOCH_ID, CHILD_EPOCH_NAME, i_owner);
        _configureExecuteRebalanceWorkflow(child.workflowRouter, CHILD_REBALANCE_ID, CHILD_REBALANCE_NAME, i_owner);
        _configureExecuteRebalanceWorkflow(
            remoteChild.workflowRouter, CHILD_REBALANCE_ID, CHILD_REBALANCE_NAME, i_owner
        );
    }

    function test_ReceiverDomainReplay_RedirectedReportCannotDrainActivatedChild() external {
        Replay memory replay = _reachReplayState(1_000_000e6, 1_000);
        uint256 attackerBefore = IERC20(parent.asset).balanceOf(i_nonOwner);

        _replayToDestination(replay);

        IRouter.TransmissionInfo memory redirected =
            s_forwarder.getTransmissionInfo(address(remoteChild.workflowRouter), WORKFLOW_EXECUTION_ID, REPORT_ID);
        assertEq(uint256(redirected.state), uint256(IRouter.TransmissionState.FAILED));
        assertFalse(redirected.success, "report must be bound to its intended receiver");
        assertEq(remoteChild.aaveV4Adapter.getTVL(), replay.destinationTvl);
        assertEq(uint256(remoteChild.vault.getRecoveryMode()), uint256(Types.RecoveryMode.NONE));
        assertEq(remoteChild.vault.getCcipSendRecovery().amount, 0);
        assertEq(IERC20(parent.asset).balanceOf(i_nonOwner), attackerBefore);
    }

    function testFuzz_ReceiverDomainReplay_RedirectedReportCannotDisplaceSignedAmount(
        uint256 principal,
        uint256 withdrawBps
    ) external {
        principal = bound(principal, 10_000e6, 5_000_000e6);
        withdrawBps = bound(withdrawBps, 2, 4_000);
        Replay memory replay = _reachReplayState(principal, withdrawBps);
        _replayToDestination(replay);

        assertEq(remoteChild.aaveV4Adapter.getTVL(), replay.destinationTvl);
        assertEq(uint256(remoteChild.vault.getRecoveryMode()), uint256(Types.RecoveryMode.NONE));
    }

    function test_ReceiverDomainReplay_RedirectedRebalanceCannotDrainActivatedChild() external {
        _fundAndApproveUsdc(i_depositor, 1_000_000e6);
        _changePrank(i_depositor);
        parent.vault.deposit(1_000_000e6);
        _warpPastMinEpoch();
        _close(0);
        _changePrank(i_depositor);
        parent.vault.claimShares(1);

        vm.warp(block.timestamp + MIN_REBALANCE_PERIOD + 1);
        _initiate(_childStrategy(AAVE_V3_PROTOCOL_ID));
        _complete();

        vm.warp(block.timestamp + MIN_REBALANCE_PERIOD + 1);
        Types.Strategy memory destination = _remoteChildStrategy(AAVE_V4_PROTOCOL_ID);
        _initiate(destination);

        bytes memory intendedCall = abi.encodeWithSelector(child.vault.executeRebalance.selector, 2, destination);
        bytes memory intendedReport =
            abi.encodePacked(CHILD_CHAIN_SELECTOR, address(child.workflowRouter), block.timestamp, intendedCall);
        (bytes memory rawReport, bytes memory reportContext, bytes[] memory signatures) =
            _signedReport(CHILD_REBALANCE_ID, CHILD_REBALANCE_NAME, intendedReport);

        vm.stopPrank();
        vm.prank(makeAddr("honestCRETransmitter"));
        s_forwarder.report{gas: 3_000_000}(address(child.workflowRouter), rawReport, reportContext, signatures);
        assertTrue(
            s_forwarder.getTransmissionInfo(address(child.workflowRouter), WORKFLOW_EXECUTION_ID, REPORT_ID).success,
            "intended rebalance report must execute normally"
        );
        _complete();

        uint256 destinationTvl = remoteChild.vault.getTVL();
        uint256 attackerBefore = IERC20(parent.asset).balanceOf(i_nonOwner);
        vm.stopPrank();
        vm.prank(i_nonOwner);
        s_forwarder.report{gas: 3_000_000}(address(remoteChild.workflowRouter), rawReport, reportContext, signatures);

        IRouter.TransmissionInfo memory redirected =
            s_forwarder.getTransmissionInfo(address(remoteChild.workflowRouter), WORKFLOW_EXECUTION_ID, REPORT_ID);
        assertEq(uint256(redirected.state), uint256(IRouter.TransmissionState.FAILED));
        assertFalse(redirected.success, "rebalance report must be bound to its intended receiver");
        assertEq(remoteChild.vault.getTVL(), destinationTvl);
        assertEq(uint256(remoteChild.vault.getRecoveryMode()), uint256(Types.RecoveryMode.NONE));
        assertEq(IERC20(parent.asset).balanceOf(i_nonOwner), attackerBefore);
    }

    function _reachReplayState(uint256 principal, uint256 withdrawBps) private returns (Replay memory replay) {
        _fundAndApproveUsdc(i_depositor, principal);
        _changePrank(i_depositor);
        parent.vault.deposit(principal);
        _warpPastMinEpoch();
        _close(0);
        _changePrank(i_depositor);
        parent.vault.claimShares(1);

        vm.warp(block.timestamp + MIN_REBALANCE_PERIOD + 1);
        _initiate(_childStrategy(AAVE_V3_PROTOCOL_ID));
        _complete();

        uint256 sharesToWithdraw = parent.share.balanceOf(i_depositor) * withdrawBps / 10_000;
        _approveShares(i_depositor, address(parent.vault), sharesToWithdraw);
        _changePrank(i_depositor);
        parent.vault.withdraw(sharesToWithdraw);
        _warpPastMinEpoch();
        _close(child.vault.getTVL());

        replay.nonce = 2;
        replay.amount = parent.vault.getEpoch(replay.nonce).totalWithdrawClaimAmount;
        bytes memory intendedCall =
            abi.encodeWithSelector(child.vault.executeEpochWithdraw.selector, replay.nonce, replay.amount);
        bytes memory intendedReport =
            abi.encodePacked(CHILD_CHAIN_SELECTOR, address(child.workflowRouter), block.timestamp, intendedCall);
        (replay.rawReport, replay.reportContext, replay.signatures) =
            _signedReport(CHILD_EPOCH_ID, CHILD_EPOCH_NAME, intendedReport);

        vm.stopPrank();
        vm.prank(makeAddr("honestCRETransmitter"));
        s_forwarder.report{gas: 3_000_000}(
            address(child.workflowRouter), replay.rawReport, replay.reportContext, replay.signatures
        );
        assertTrue(
            s_forwarder.getTransmissionInfo(address(child.workflowRouter), WORKFLOW_EXECUTION_ID, REPORT_ID).success,
            "intended report must execute normally"
        );
        assertEq(uint256(parent.vault.getEpoch(replay.nonce).status), uint256(Types.EpochStatus.CLAIMABLE));

        vm.warp(block.timestamp + MIN_REBALANCE_PERIOD + 1);
        _initiate(_remoteChildStrategy(AAVE_V4_PROTOCOL_ID));
        _executeRebalanceThroughWorkflow(
            child.workflowRouter,
            CHILD_REBALANCE_ID,
            CHILD_REBALANCE_NAME,
            i_owner,
            2,
            _remoteChildStrategy(AAVE_V4_PROTOCOL_ID)
        );
        _complete();

        assertEq(remoteChild.vault.getLastHandledEpochNonce(), 0);
        replay.destinationTvl = remoteChild.vault.getTVL();
        assertGt(replay.destinationTvl, replay.amount);
    }

    function _replayToDestination(Replay memory replay) private {
        vm.stopPrank();
        vm.prank(i_nonOwner);
        s_forwarder.report{gas: 3_000_000}(
            address(remoteChild.workflowRouter), replay.rawReport, replay.reportContext, replay.signatures
        );
    }

    function _configureSigners() private {
        address[] memory signers = new address[](4);
        signers[0] = vm.addr(SIGNER_1_PK);
        signers[1] = vm.addr(SIGNER_2_PK);
        signers[2] = vm.addr(SIGNER_3_PK);
        signers[3] = vm.addr(SIGNER_4_PK);
        s_forwarder.setConfig(DON_ID, CONFIG_VERSION, 1, signers);
    }

    function _signedReport(bytes32 workflowId, bytes10 workflowName, bytes memory callData)
        private
        view
        returns (bytes memory rawReport, bytes memory reportContext, bytes[] memory signatures)
    {
        rawReport = abi.encodePacked(
            uint8(1),
            WORKFLOW_EXECUTION_ID,
            uint32(block.timestamp),
            DON_ID,
            CONFIG_VERSION,
            workflowId,
            workflowName,
            i_owner,
            REPORT_ID,
            callData
        );
        reportContext = new bytes(96);
        bytes32 digest = keccak256(abi.encodePacked(keccak256(rawReport), reportContext));
        signatures = new bytes[](2);
        signatures[0] = _sign(SIGNER_1_PK, digest);
        signatures[1] = _sign(SIGNER_2_PK, digest);
    }

    function _sign(uint256 privateKey, bytes32 digest) private pure returns (bytes memory signature) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        signature = abi.encodePacked(r, s, bytes1(v - 27));
    }

    function _close(uint256 tvl) private {
        _closeEpochThroughWorkflow(parent.workflowRouter, CLOSE_ID, CLOSE_NAME, i_owner, tvl);
    }

    function _initiate(Types.Strategy memory strategy) private {
        _callWorkflowRouter(
            parent.workflowRouter,
            INIT_ID,
            INIT_NAME,
            i_owner,
            abi.encodeWithSelector(ParentVault.initiateRebalance.selector, parent.vault.getRebalance().nonce, strategy)
        );
    }

    function _complete() private {
        _completeRebalanceThroughWorkflow(parent.workflowRouter, COMPLETE_ID, COMPLETE_NAME, i_owner);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseIntegrationTest} from "../../BaseIntegrationTest.t.sol";

import {Types} from "../../../../src/libraries/Types.sol";

import {Client, IRouterClient} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
import {IAny2EVMMessageReceiver} from "@chainlink/contracts-ccip/contracts/interfaces/IAny2EVMMessageReceiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Vm} from "forge-std/Vm.sol";

contract FeeChargingCcipRouter is IRouterClient {
    IERC20 internal immutable i_asset;
    uint64 internal immutable i_sourceChainSelector;
    uint16 internal immutable i_feeBps;

    constructor(IERC20 asset, uint64 sourceChainSelector, uint16 feeBps) {
        i_asset = asset;
        i_sourceChainSelector = sourceChainSelector;
        i_feeBps = feeBps;
    }

    function getFee(uint64, Client.EVM2AnyMessage memory) external pure returns (uint256) {
        return 0;
    }

    function isChainSupported(uint64) external pure returns (bool) {
        return true;
    }

    function ccipSend(uint64, Client.EVM2AnyMessage calldata message) external payable returns (bytes32 messageId) {
        uint256 sourceAmount = message.tokenAmounts[0].amount;
        uint256 actualDepositAmount = sourceAmount - sourceAmount * i_feeBps / 10_000;
        address receiver = abi.decode(message.receiver, (address));

        i_asset.transferFrom(msg.sender, address(this), sourceAmount);
        i_asset.transfer(receiver, actualDepositAmount);

        messageId = keccak256(abi.encode(msg.sender, receiver, sourceAmount, actualDepositAmount));
        Client.EVMTokenAmount[] memory delivered = new Client.EVMTokenAmount[](1);
        delivered[0] = Client.EVMTokenAmount({token: address(i_asset), amount: actualDepositAmount});
        IAny2EVMMessageReceiver(receiver)
            .ccipReceive(
                Client.Any2EVMMessage({
                    messageId: messageId,
                    sourceChainSelector: i_sourceChainSelector,
                    sender: abi.encode(msg.sender),
                    data: message.data,
                    destTokenAmounts: delivered
                })
            );
    }
}

contract CcipDepositReconciliationIntegrationTest is BaseIntegrationTest {
    bytes32 private constant WORKFLOW_ID = keccak256("ccip-deposit-reconciliation");
    bytes10 private constant WORKFLOW_NAME = bytes10("closeEpoch");
    uint16 private constant FEE_BPS = 100;

    function setUp() public override {
        super.setUp();
        _deployLocalParentChildTopology();
        _configureCloseEpochWorkflow(parent.workflowRouter, WORKFLOW_ID, WORKFLOW_NAME, i_owner);
        _setParentRemoteStrategyToChild(AAVE_V3_PROTOCOL_ID);
        _setChildActiveAdapter(AAVE_V3_PROTOCOL_ID);
        _setDefaultCcipGasLimits();

        FeeChargingCcipRouter implementation =
            new FeeChargingCcipRouter(IERC20(parent.asset), PARENT_CHAIN_SELECTOR, FEE_BPS);
        vm.etch(address(local.mockCcipRouter), address(implementation).code);
    }

    function test_CcipDepositReconciliation_UsesPostCcipChildEventAmount() external {
        uint256 actualDepositAmount = DEPOSIT_AMOUNT - DEPOSIT_AMOUNT * FEE_BPS / 10_000;
        uint256 feeAmount = DEPOSIT_AMOUNT - actualDepositAmount;
        address childPool = child.aaveV3Adapter.getProtocolPool();

        _fundAndApproveUsdc(i_depositor, DEPOSIT_AMOUNT);
        _changePrank(i_depositor);
        parent.vault.deposit(DEPOSIT_AMOUNT);

        _warpPastMinEpoch();
        vm.recordLogs();
        _closeEpochThroughWorkflow(parent.workflowRouter, WORKFLOW_ID, WORKFLOW_NAME, i_owner, 0);
        Vm.Log[] memory closeLogs = vm.getRecordedLogs();
        Vm.Log memory successLog = _assertEmittedBy(
            closeLogs, keccak256("EpochDepositToStrategySuccess(uint256,uint256)"), address(child.vault)
        );
        uint256 reportedDepositAmount = uint256(successLog.topics[2]);

        assertEq(reportedDepositAmount, actualDepositAmount);
        assertEq(IERC20(parent.asset).balanceOf(address(local.mockCcipRouter)), feeAmount);
        assertEq(IERC20(parent.asset).balanceOf(childPool), actualDepositAmount);
        assertEq(uint256(parent.vault.getEpoch(1).status), uint256(Types.EpochStatus.EXECUTING));

        _completeEpochDepositThroughWorkflow(
            parent.workflowRouter,
            WORKFLOW_ID,
            WORKFLOW_NAME,
            i_owner,
            uint256(successLog.topics[1]),
            reportedDepositAmount
        );

        uint256 expectedShares = YIELD_PRECISION * actualDepositAmount / DEPOSIT_AMOUNT;
        assertEq(parent.vault.getEpoch(1).remainingShareMintAmount, expectedShares);
        assertEq(parent.vault.getTotalShares(), expectedShares);
        assertEq(uint256(parent.vault.getEpoch(1).status), uint256(Types.EpochStatus.CLAIMABLE));

        _changePrank(i_depositor);
        parent.vault.claimShares(1);
        assertEq(parent.share.balanceOf(i_depositor), expectedShares);
    }
}

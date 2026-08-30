// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseForkTest} from "../BaseForkTest.t.sol";
import {StdStorage, stdStorage} from "forge-std/StdStorage.sol";

import {WorkflowRouter} from "../../../src/modules/WorkflowRouter.sol";
import {ParentVault} from "../../../src/vaults/ParentVault.sol";
import {ChildVault} from "../../../src/vaults/ChildVault.sol";
import {Types} from "../../../src/libraries/Types.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMessageTransmitterFork {
    function owner() external view returns (address);
    function updateAttesterManager(address newAttesterManager) external;
    function enableAttester(address newAttester) external;
    function setSignatureThreshold(uint256 newSignatureThreshold) external;
}

abstract contract BaseCcipForkTest is BaseForkTest {
    uint256 internal constant REMOTE_WITHDRAW_AMOUNT = 100 * ASSET_PRECISION;
    using stdStorage for StdStorage;

    uint256 internal constant CCIP_LINK_AMOUNT = 1_000 ether;
    uint256 internal constant CCTP_ATTESTER_COUNT = 4;
    uint256 internal constant FORK_CCIP_GAS_LIMIT = 5_000_000;

    bytes10 internal constant CLOSE_EPOCH_WORKFLOW_NAME = bytes10("closeEpoch");
    bytes10 internal constant EXECUTE_WITHDRAW_WORKFLOW_NAME = bytes10("epochDraw");
    bytes10 internal constant INITIATE_REBALANCE_WORKFLOW_NAME = bytes10("rebalance");
    bytes10 internal constant EXECUTE_REBALANCE_WORKFLOW_NAME = bytes10("execRb");
    bytes10 internal constant COMPLETE_REBALANCE_WORKFLOW_NAME = bytes10("completeRb");

    address internal constant ARBITRUM_CCTP_MESSAGE_TRANSMITTER = 0xC30362313FBBA5cf9163F0bb16a0e01f01A896ca;
    address internal constant BASE_CCTP_MESSAGE_TRANSMITTER = 0xAD09780d193884d503182aD4588450C416D6F9D4;
    address internal constant ETHEREUM_CCTP_MESSAGE_TRANSMITTER = 0x0a992d191DEeC32aFe36203Ad87D7d289a738F81;
    address internal constant AVALANCHE_CCTP_MESSAGE_TRANSMITTER = 0x8186359aF5F57FbB40c6b14A588d2A59C0C29880;
    address internal constant OPTIMISM_CCTP_MESSAGE_TRANSMITTER = 0x4D41f22c5a0e5c74090899E5a8Fb597a8842b3e8;

    address[] internal attesters;
    uint256[] internal attesterPks;

    function setUp() public virtual override {
        super.setUp();
        _setCctpAttesters();
        _fundCcipLink();
        _setForkCcipGasLimits();
        _configureChildToChildVaults();
    }

    function _setCctpAttesters() internal {
        attesters = new address[](CCTP_ATTESTER_COUNT);
        attesterPks = new uint256[](CCTP_ATTESTER_COUNT);

        for (uint256 i; i < CCTP_ATTESTER_COUNT; ++i) {
            (attesters[i], attesterPks[i]) = makeAddrAndKey(string.concat("attester", vm.toString(i)));
        }

        _configureCctpAttesters(arbitrumFork, ARBITRUM_CCTP_MESSAGE_TRANSMITTER);
        _configureCctpAttesters(baseFork, BASE_CCTP_MESSAGE_TRANSMITTER);
        _configureCctpAttesters(ethereumFork, ETHEREUM_CCTP_MESSAGE_TRANSMITTER);
        _configureCctpAttesters(avalancheFork, AVALANCHE_CCTP_MESSAGE_TRANSMITTER);
        _configureCctpAttesters(optimismFork, OPTIMISM_CCTP_MESSAGE_TRANSMITTER);

        vm.stopPrank();
    }

    function _configureCctpAttesters(uint256 forkId, address transmitter) internal {
        vm.selectFork(forkId);

        IMessageTransmitterFork messageTransmitter = IMessageTransmitterFork(transmitter);
        _changePrank(messageTransmitter.owner());
        messageTransmitter.updateAttesterManager(attesters[0]);

        _changePrank(attesters[0]);
        for (uint256 i; i < attesters.length; ++i) {
            messageTransmitter.enableAttester(attesters[i]);
        }
        messageTransmitter.setSignatureThreshold(attesters.length);
    }

    function _fundCcipLink() internal {
        _selectArbitrumFork();
        deal(parent.link, address(parent.vault), CCIP_LINK_AMOUNT);

        _selectBaseFork();
        deal(child.link, address(child.vault), CCIP_LINK_AMOUNT);

        _selectEthereumFork();
        deal(child.link, address(child.vault), CCIP_LINK_AMOUNT);

        _selectAvalancheFork();
        deal(child.link, address(child.vault), CCIP_LINK_AMOUNT);

        _selectOptimismFork();
        deal(child.link, address(child.vault), CCIP_LINK_AMOUNT);
    }

    function _setForkCcipGasLimits() internal {
        _selectArbitrumFork();
        _setCcipGasLimit(parent.vault, baseConfig.ccip.thisChainSelector, FORK_CCIP_GAS_LIMIT);
        _setCcipGasLimit(parent.vault, ethereumConfig.ccip.thisChainSelector, FORK_CCIP_GAS_LIMIT);

        _selectBaseFork();
        _setCcipGasLimit(baseChild.vault, arbitrumConfig.ccip.thisChainSelector, FORK_CCIP_GAS_LIMIT);
        _setCcipGasLimit(baseChild.vault, ethereumConfig.ccip.thisChainSelector, FORK_CCIP_GAS_LIMIT);

        _selectEthereumFork();
        _setCcipGasLimit(ethereumChild.vault, arbitrumConfig.ccip.thisChainSelector, FORK_CCIP_GAS_LIMIT);
        _setCcipGasLimit(ethereumChild.vault, baseConfig.ccip.thisChainSelector, FORK_CCIP_GAS_LIMIT);
    }

    function _setCcipGasLimit(ChildVault vault, uint64 chainSelector, uint256 gasLimit) internal {
        _changePrank(networkConfig.roles.configOperator);
        vault.setCcipGasLimit(chainSelector, gasLimit);
    }

    function _setCcipGasLimit(ParentVault vault, uint64 chainSelector, uint256 gasLimit) internal {
        _changePrank(networkConfig.roles.configOperator);
        vault.setCcipGasLimit(chainSelector, gasLimit);
    }

    function _configureChildToChildVaults() internal {
        _selectBaseFork();
        _setCrosschainVault(baseChild.vault, ethereumConfig.ccip.thisChainSelector, address(ethereumChild.vault));

        _selectEthereumFork();
        _setCrosschainVault(ethereumChild.vault, baseConfig.ccip.thisChainSelector, address(baseChild.vault));
    }

    function _routeUsdcMessageTo(uint256 forkId) internal {
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(forkId, attesters, attesterPks);
    }

    function _fundAndApproveParentUsdc(address account, uint256 amount) internal {
        _selectArbitrumFork();
        deal(parent.asset, account, amount);
        _changePrank(account);
        IERC20(parent.asset).approve(address(parent.vault), amount);
    }

    function _approveShares(address owner, uint256 amount) internal {
        _selectArbitrumFork();
        _changePrank(owner);
        parent.share.approve(address(parent.vault), amount);
    }

    function _warpPastMinEpoch() internal {
        vm.warp(block.timestamp + MIN_EPOCH_PERIOD + 1);
    }

    function _configureCloseEpochWorkflow(bytes32 workflowId) internal {
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = ParentVault.closeEpoch.selector;
        selectors[1] = ParentVault.completeEpochDeposit.selector;
        _configureWorkflow(parent.workflowRouter, workflowId, CLOSE_EPOCH_WORKFLOW_NAME, i_owner, selectors);
    }

    function _configureExecuteEpochWithdrawWorkflow(WorkflowRouter router, bytes32 workflowId) internal {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = ChildVault.executeEpochWithdraw.selector;
        _configureWorkflow(router, workflowId, EXECUTE_WITHDRAW_WORKFLOW_NAME, i_owner, selectors);
    }

    function _configureInitiateRebalanceWorkflow(bytes32 workflowId) internal {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = ParentVault.initiateRebalance.selector;
        _configureWorkflow(parent.workflowRouter, workflowId, INITIATE_REBALANCE_WORKFLOW_NAME, i_owner, selectors);
    }

    function _configureCompleteRebalanceWorkflow(bytes32 workflowId) internal {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = ParentVault.completeRebalance.selector;
        _configureWorkflow(parent.workflowRouter, workflowId, COMPLETE_REBALANCE_WORKFLOW_NAME, i_owner, selectors);
    }

    function _configureExecuteRebalanceWorkflow(WorkflowRouter router, bytes32 workflowId) internal {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = ChildVault.executeRebalance.selector;
        _configureWorkflow(router, workflowId, EXECUTE_REBALANCE_WORKFLOW_NAME, i_owner, selectors);
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
        router.onReport(
            _buildMetadata(workflowId, workflowName, workflowOwner),
            abi.encodePacked(router.getThisChainSelector(), address(router), block.timestamp, report)
        );
    }

    function _closeEpochThroughWorkflow(bytes32 workflowId, uint256 tvl) internal {
        _selectArbitrumFork();
        _callWorkflowRouter(
            parent.workflowRouter,
            workflowId,
            CLOSE_EPOCH_WORKFLOW_NAME,
            i_owner,
            abi.encodeWithSelector(ParentVault.closeEpoch.selector, parent.vault.getEpochNonce(), tvl)
        );
    }

    function _completeEpochDepositThroughWorkflow(bytes32 workflowId, uint256 epochNonce, uint256 actualDepositAmount)
        internal
    {
        _selectArbitrumFork();
        _callWorkflowRouter(
            parent.workflowRouter,
            workflowId,
            CLOSE_EPOCH_WORKFLOW_NAME,
            i_owner,
            abi.encodeWithSelector(ParentVault.completeEpochDeposit.selector, epochNonce, actualDepositAmount)
        );
    }

    function _executeEpochWithdrawThroughWorkflow(
        WorkflowRouter router,
        bytes32 workflowId,
        uint256 epochNonce,
        uint256 amount
    ) internal {
        _callWorkflowRouter(
            router,
            workflowId,
            EXECUTE_WITHDRAW_WORKFLOW_NAME,
            i_owner,
            abi.encodeWithSelector(ChildVault.executeEpochWithdraw.selector, epochNonce, amount)
        );
    }

    function _initiateRebalanceThroughWorkflow(bytes32 workflowId, Types.Strategy memory newStrategy) internal {
        _selectArbitrumFork();
        _markParentFirstEpochCompleted();
        _markParentRebalanceCooldownElapsed();
        _callWorkflowRouter(
            parent.workflowRouter,
            workflowId,
            INITIATE_REBALANCE_WORKFLOW_NAME,
            i_owner,
            abi.encodeWithSelector(
                ParentVault.initiateRebalance.selector, parent.vault.getRebalance().nonce, newStrategy
            )
        );
    }

    function _markParentFirstEpochCompleted() internal {
        if (parent.vault.getEpochNonce() == 1) {
            stdstore.target(address(parent.vault)).sig("getEpochNonce()").checked_write(2);
        }
    }

    /// @dev Ensures MIN_REBALANCE_PERIOD has elapsed since the last rebalance completed, regardless of
    ///      how much wall-clock time the preceding test actions actually advanced.
    function _markParentRebalanceCooldownElapsed() internal {
        stdstore.target(address(parent.vault)).sig("getRebalance()").depth(6).checked_write(uint256(0));
    }

    function _completeRebalanceThroughWorkflow(bytes32 workflowId) internal {
        _selectArbitrumFork();
        _callWorkflowRouter(
            parent.workflowRouter,
            workflowId,
            COMPLETE_REBALANCE_WORKFLOW_NAME,
            i_owner,
            abi.encodeWithSelector(ParentVault.completeRebalance.selector, parent.vault.getRebalance().nonce)
        );
    }

    function _executeRebalanceThroughWorkflow(
        WorkflowRouter router,
        bytes32 workflowId,
        uint256 rebalanceNonce,
        Types.Strategy memory newStrategy
    ) internal {
        _callWorkflowRouter(
            router,
            workflowId,
            EXECUTE_REBALANCE_WORKFLOW_NAME,
            i_owner,
            abi.encodeWithSelector(ChildVault.executeRebalance.selector, rebalanceNonce, newStrategy)
        );
    }

    function _parentAaveV3Strategy() internal view returns (Types.Strategy memory strategy) {
        strategy =
            Types.Strategy({protocolId: AAVE_V3_PROTOCOL_ID, chainSelector: arbitrumConfig.ccip.thisChainSelector});
    }

    function _baseAaveV3Strategy() internal view returns (Types.Strategy memory strategy) {
        strategy = Types.Strategy({protocolId: AAVE_V3_PROTOCOL_ID, chainSelector: baseConfig.ccip.thisChainSelector});
    }

    function _ethereumAaveV3Strategy() internal view returns (Types.Strategy memory strategy) {
        strategy =
            Types.Strategy({protocolId: AAVE_V3_PROTOCOL_ID, chainSelector: ethereumConfig.ccip.thisChainSelector});
    }

    function _setParentRemoteStrategyToBase() internal {
        _selectArbitrumFork();
        stdstore.enable_packed_slots().target(address(parent.vault)).sig("getActiveProtocolAdapter()")
            .checked_write(address(0));
        stdstore.target(address(parent.vault)).sig("getRebalance()").depth(2).checked_write(AAVE_V3_PROTOCOL_ID);
        stdstore.target(address(parent.vault)).sig("getRebalance()").depth(3)
            .checked_write(baseConfig.ccip.thisChainSelector);
    }

    function _setBaseChildActiveAdapterToAaveV3() internal {
        _selectBaseFork();
        stdstore.enable_packed_slots().target(address(baseChild.vault)).sig("getActiveProtocolAdapter()")
            .checked_write(address(baseChild.aaveV3Adapter));
        assertEq(baseChild.vault.getActiveProtocolAdapter(), address(baseChild.aaveV3Adapter));
    }

    function _setEthereumChildActiveAdapterToAaveV3() internal {
        _selectEthereumFork();
        stdstore.enable_packed_slots().target(address(ethereumChild.vault)).sig("getActiveProtocolAdapter()")
            .checked_write(address(ethereumChild.aaveV3Adapter));
        assertEq(ethereumChild.vault.getActiveProtocolAdapter(), address(ethereumChild.aaveV3Adapter));
    }

    function _seedParentAaveV3Tvl(uint256 amount) internal {
        _selectArbitrumFork();
        deal(parent.asset, address(parent.aaveV3Adapter), amount);
        _changePrank(address(parent.vault));
        parent.aaveV3Adapter.deposit(amount);
    }

    function _seedBaseChildAaveV3Tvl(uint256 amount) internal {
        _selectBaseFork();
        deal(baseChild.asset, address(baseChild.aaveV3Adapter), amount);
        _changePrank(address(baseChild.vault));
        baseChild.aaveV3Adapter.deposit(amount);
    }

    function _depositAndClaimParentShares(bytes32 workflowId) internal returns (uint256 shareAmount) {
        _selectArbitrumFork();

        _fundAndApproveParentUsdc(i_depositor, REMOTE_WITHDRAW_AMOUNT);

        _changePrank(i_depositor);
        parent.vault.deposit(REMOTE_WITHDRAW_AMOUNT);

        _warpPastMinEpoch();
        _closeEpochThroughWorkflow(workflowId, 0);
        _setBaseChildActiveAdapterToAaveV3();
        _selectArbitrumFork();
        _routeUsdcMessageTo(baseFork);

        _completeEpochDepositThroughWorkflow(workflowId, 1, REMOTE_WITHDRAW_AMOUNT);
        _changePrank(i_depositor);
        parent.vault.claimShares(1);

        shareAmount = REMOTE_WITHDRAW_AMOUNT * YIELD_PRECISION / ASSET_PRECISION;
    }

    function test_baseCcipForkTest() public virtual {}
}

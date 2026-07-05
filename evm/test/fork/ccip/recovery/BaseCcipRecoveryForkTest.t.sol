// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseCcipForkTest} from "../BaseCcipForkTest.t.sol";
import {AdapterRegistry} from "../../../../src/modules/AdapterRegistry.sol";
import {Types} from "../../../../src/libraries/Types.sol";
import {RevertingProtocolAdapter} from "../../../mocks/RevertingProtocolAdapter.sol";
import {StdStorage, stdStorage} from "forge-std/StdStorage.sol";

abstract contract BaseCcipRecoveryForkTest is BaseCcipForkTest {
    using stdStorage for StdStorage;

    RevertingProtocolAdapter internal parentFailingAdapter;
    RevertingProtocolAdapter internal baseFailingAdapter;

    function setUp() public virtual override {
        super.setUp();
        _deployFailingAdapters();
    }

    function _deployFailingAdapters() internal {
        _selectArbitrumFork();
        parentFailingAdapter = new RevertingProtocolAdapter(address(parent.vault), parent.asset);

        _selectBaseFork();
        baseFailingAdapter = new RevertingProtocolAdapter(address(baseChild.vault), baseChild.asset);
    }

    function _setParentActiveAdapterToAaveV3() internal {
        _selectArbitrumFork();
        stdstore.enable_packed_slots().target(address(parent.vault)).sig("getActiveProtocolAdapter()")
            .checked_write(address(parent.aaveV3Adapter));
        assertEq(parent.vault.getActiveProtocolAdapter(), address(parent.aaveV3Adapter));
    }

    function _setParentActiveAdapterToFailingAdapter() internal {
        _selectArbitrumFork();
        stdstore.enable_packed_slots().target(address(parent.vault)).sig("getActiveProtocolAdapter()")
            .checked_write(address(parentFailingAdapter));
        assertEq(parent.vault.getActiveProtocolAdapter(), address(parentFailingAdapter));
    }

    function _setBaseChildActiveAdapterToFailingAdapter() internal {
        _selectBaseFork();
        stdstore.enable_packed_slots().target(address(baseChild.vault)).sig("getActiveProtocolAdapter()")
            .checked_write(address(baseFailingAdapter));
        assertEq(baseChild.vault.getActiveProtocolAdapter(), address(baseFailingAdapter));
    }

    function _setParentAaveV3RegistryAdapter(address adapter) internal {
        _selectArbitrumFork();
        _setRegistryAdapter(parent.adapterRegistry, AAVE_V3_PROTOCOL_ID, adapter);
    }

    function _setBaseAaveV3RegistryAdapter(address adapter) internal {
        _selectBaseFork();
        _setRegistryAdapter(baseChild.adapterRegistry, AAVE_V3_PROTOCOL_ID, adapter);
    }

    function _setRegistryAdapter(AdapterRegistry registry, bytes32 protocolId, address adapter) internal {
        _changePrank(networkConfig.roles.configOperator);
        registry.setAdapter(protocolId, adapter);
        assertEq(registry.getAdapter(protocolId), adapter);
    }

    function _restoreParentAaveV3Adapter() internal {
        _setParentAaveV3RegistryAdapter(address(parent.aaveV3Adapter));
        _setParentActiveAdapterToAaveV3();
    }

    function _restoreBaseAaveV3Adapter() internal {
        _setBaseAaveV3RegistryAdapter(address(baseChild.aaveV3Adapter));
        _setBaseChildActiveAdapterToAaveV3();
    }

    function _prepareParentToBaseRouting() internal {
        _setParentRemoteStrategyToBase();
        _restoreBaseAaveV3Adapter();
        _selectArbitrumFork();
    }

    function _prepareBaseToParentRouting() internal {
        _selectBaseFork();
        _setCrosschainVault(baseChild.vault, arbitrumConfig.ccip.thisChainSelector, address(parent.vault));
        _selectArbitrumFork();
        _setCrosschainVault(parent.vault, baseConfig.ccip.thisChainSelector, address(baseChild.vault));
        _restoreParentAaveV3Adapter();
        _selectBaseFork();
    }

    function _routeUsdcMessageFromActiveForkTo(uint256 destinationForkId) internal {
        _routeUsdcMessageTo(destinationForkId);
    }

    function _assertEpochRecovery(Types.EpochRecovery memory recovery, uint256 epochNonce, uint256 amount)
        internal
        view
    {
        assertEq(recovery.epochNonce, epochNonce);
        assertEq(recovery.amount, amount);
        assertEq(recovery.createdAt, block.timestamp);
    }

    function _assertEpochRecoveryCleared(Types.EpochRecovery memory recovery) internal pure {
        assertEq(recovery.epochNonce, 0);
        assertEq(recovery.amount, 0);
        assertEq(recovery.createdAt, 0);
    }

    function _assertRebalanceDepositRecovery(
        Types.RebalanceDepositRecovery memory recovery,
        uint256 rebalanceNonce,
        uint256 amount
    ) internal view {
        assertEq(recovery.rebalanceNonce, rebalanceNonce);
        assertEq(recovery.amount, amount);
        assertEq(recovery.createdAt, block.timestamp);
    }

    function _assertRebalanceDepositRecoveryCleared(Types.RebalanceDepositRecovery memory recovery) internal pure {
        assertEq(recovery.rebalanceNonce, 0);
        assertEq(recovery.amount, 0);
        assertEq(recovery.createdAt, 0);
    }

    function _assertRebalanceWithdrawRecovery(
        Types.RebalanceWithdrawRecovery memory recovery,
        uint256 rebalanceNonce,
        bytes32 protocolId,
        uint64 chainSelector
    ) internal view {
        assertEq(recovery.rebalanceNonce, rebalanceNonce);
        assertEq(recovery.strategy.protocolId, protocolId);
        assertEq(recovery.strategy.chainSelector, chainSelector);
        assertEq(recovery.createdAt, block.timestamp);
    }

    function _assertRebalanceWithdrawRecoveryCleared(Types.RebalanceWithdrawRecovery memory recovery) internal pure {
        assertEq(recovery.rebalanceNonce, 0);
        assertEq(recovery.strategy.protocolId, bytes32(0));
        assertEq(recovery.strategy.chainSelector, 0);
        assertEq(recovery.createdAt, 0);
    }

    function _assertCcipSendRecovery(
        Types.CcipSendRecovery memory recovery,
        Types.CcipTx ccipTxType,
        uint64 destinationChainSelector,
        uint256 amount,
        uint256 nonce,
        bytes32 protocolId
    ) internal view {
        assertEq(uint256(recovery.ccipTxType), uint256(ccipTxType));
        assertEq(recovery.destinationChainSelector, destinationChainSelector);
        assertEq(recovery.amount, amount);
        assertEq(recovery.nonce, nonce);
        assertEq(recovery.protocolId, protocolId);
        assertEq(recovery.createdAt, block.timestamp);
    }

    function _assertCcipSendRecoveryCleared(Types.CcipSendRecovery memory recovery) internal pure {
        assertEq(uint256(recovery.ccipTxType), 0);
        assertEq(recovery.destinationChainSelector, 0);
        assertEq(recovery.amount, 0);
        assertEq(recovery.nonce, 0);
        assertEq(recovery.protocolId, bytes32(0));
        assertEq(recovery.createdAt, 0);
    }

    function _assertCompletedRebalance(bytes32 protocolId, uint64 chainSelector) internal {
        vm.selectFork(arbitrumFork);
        Types.Rebalance memory rebalance = parent.vault.getRebalance();
        assertEq(uint256(rebalance.state), uint256(Types.RebalanceState.NONE));
        assertEq(rebalance.nonce, 2);
        assertEq(rebalance.activeStrategy.protocolId, protocolId);
        assertEq(rebalance.activeStrategy.chainSelector, chainSelector);
        assertEq(rebalance.pendingStrategy.protocolId, bytes32(0));
        assertEq(rebalance.pendingStrategy.chainSelector, 0);
    }

    function test_baseCcipRecoveryForkTest() public virtual {}
}

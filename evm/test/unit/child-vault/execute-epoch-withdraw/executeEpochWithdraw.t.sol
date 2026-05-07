// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {IBaseVault} from "../../../../src/interfaces/IBaseVault.sol";
import {Types} from "../../../../src/libraries/Types.sol";

contract ChildVault_ExecuteEpochWithdrawUnitTest is BaseUnitTest {
    uint256 internal constant EPOCH_NONCE = 1;
    uint256 internal constant WITHDRAW_AMOUNT = 100 * 1e6;

    function setUp() public {
        _setChildActiveAdapter(address(s_mockProtocolAdapter));
        _setChildCrosschainVault(PARENT_CHAIN_SELECTOR, address(s_parentVault));
        deal(address(s_mockUsdc), address(s_childVault), WITHDRAW_AMOUNT);
        _changePrank(i_epochOperator);
    }

    function test_ChildVault_executeEpochWithdraw_RevertWhen_CallerDoesNotHaveEPOCH_OPERATOR_ROLE() public {
        _changePrank(i_nonOwner);
        vm.expectRevert();
        s_childVault.executeEpochWithdraw(EPOCH_NONCE, WITHDRAW_AMOUNT);
    }

    function test_ChildVault_executeEpochWithdraw_RevertWhen_NoActiveAdapter() public {
        _clearChildActiveAdapter();

        vm.expectRevert(IBaseVault.BaseVault__NoActiveAdapter.selector);
        s_childVault.executeEpochWithdraw(EPOCH_NONCE, WITHDRAW_AMOUNT);
    }

    function test_ChildVault_executeEpochWithdraw_Success_WithdrawsFromAdapter() public {
        s_childVault.executeEpochWithdraw(EPOCH_NONCE, WITHDRAW_AMOUNT);

        assertEq(s_mockProtocolAdapter.getWithdrawCalls(), 1);
        assertEq(s_mockProtocolAdapter.getLastWithdrawAmount(), WITHDRAW_AMOUNT);
    }

    function test_ChildVault_executeEpochWithdraw_Success_BridgesToParent() public {
        uint256 routerBefore = s_mockUsdc.balanceOf(address(s_mockCcipRouter));

        s_childVault.executeEpochWithdraw(EPOCH_NONCE, WITHDRAW_AMOUNT);

        assertEq(s_mockUsdc.balanceOf(address(s_mockCcipRouter)), routerBefore + WITHDRAW_AMOUNT);
    }

    function test_ChildVault_executeEpochWithdraw_Success_EmitsWithdrawFromStrategySuccess() public {
        vm.recordLogs();
        s_childVault.executeEpochWithdraw(EPOCH_NONCE, WITHDRAW_AMOUNT);

        Vm.Log memory log =
            _assertEmittedBy(keccak256("WithdrawFromStrategySuccess(uint256,uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), EPOCH_NONCE);
        assertEq(uint256(log.topics[2]), WITHDRAW_AMOUNT);
    }

    function test_ChildVault_executeEpochWithdraw_Success_EmitsUSDCBridged() public {
        vm.recordLogs();
        s_childVault.executeEpochWithdraw(EPOCH_NONCE, WITHDRAW_AMOUNT);

        Vm.Log memory log = _assertEmittedBy(keccak256("USDCBridged(bytes32,uint256,uint8)"), address(s_childVault));
        assertEq(uint256(log.topics[2]), WITHDRAW_AMOUNT);
        assertEq(uint256(log.topics[3]), uint256(Types.CcipTx.WITHDRAW));
    }

    function test_ChildVault_executeEpochWithdraw_WhenAdapterReverts_EmitsFailureWithoutBridging() public {
        s_mockProtocolAdapter.setWithdrawReverts(true);
        uint256 routerBefore = s_mockUsdc.balanceOf(address(s_mockCcipRouter));

        vm.recordLogs();
        s_childVault.executeEpochWithdraw(EPOCH_NONCE, WITHDRAW_AMOUNT);

        _assertEmittedBy(keccak256("WithdrawFromStrategyFailure(uint256,uint256)"), address(s_childVault));
        assertEq(s_mockUsdc.balanceOf(address(s_mockCcipRouter)), routerBefore);
    }

    function test_ChildVault_executeEpochWithdraw_WhenAdapterReverts_StoresEpochWithdrawRecovery() public {
        s_mockProtocolAdapter.setWithdrawReverts(true);

        s_childVault.executeEpochWithdraw(EPOCH_NONCE, WITHDRAW_AMOUNT);

        Types.AmountRecovery memory recovery = s_childVault.getEpochWithdrawRecovery(EPOCH_NONCE);
        assertEq(recovery.amount, WITHDRAW_AMOUNT);
        assertEq(recovery.createdAt, block.timestamp);
    }

    function test_ChildVault_executeEpochWithdraw_WhenAdapterReverts_EmitsEpochWithdrawRecoveryStored() public {
        s_mockProtocolAdapter.setWithdrawReverts(true);

        vm.recordLogs();
        _changePrank(i_epochOperator);
        s_childVault.executeEpochWithdraw(EPOCH_NONCE, WITHDRAW_AMOUNT);

        Vm.Log memory log =
            _assertEmittedBy(keccak256("EpochWithdrawRecoveryStored(uint256,uint256)"), address(s_childVault));
        assertEq(uint256(log.topics[1]), EPOCH_NONCE);
        assertEq(uint256(log.topics[2]), WITHDRAW_AMOUNT);
    }

    function test_ChildVault_executeEpochWithdraw_WhenAdapterReturnsZero_StoresEpochWithdrawRecovery() public {
        s_mockProtocolAdapter.setWithdrawReturnAmount(0);

        s_childVault.executeEpochWithdraw(EPOCH_NONCE, WITHDRAW_AMOUNT);

        Types.AmountRecovery memory recovery = s_childVault.getEpochWithdrawRecovery(EPOCH_NONCE);
        assertEq(recovery.amount, WITHDRAW_AMOUNT);
        assertEq(recovery.createdAt, block.timestamp);
    }

    function test_ChildVault_executeEpochWithdraw_WhenEpochWithdrawRecoveryAlreadyExists_Reverts() public {
        s_mockProtocolAdapter.setWithdrawReverts(true);

        s_childVault.executeEpochWithdraw(EPOCH_NONCE, WITHDRAW_AMOUNT);

        vm.expectRevert(IBaseVault.BaseVault__RecoveryAlreadyPending.selector);
        s_childVault.executeEpochWithdraw(EPOCH_NONCE, WITHDRAW_AMOUNT);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseAaveV4AdapterUnitTest, Vm} from "../BaseAaveV4AdapterUnitTest.t.sol";

import {IProtocolAdapter} from "../../../../src/interfaces/adapters/IProtocolAdapter.sol";
import {IAaveV4Adapter} from "../../../../src/interfaces/adapters/IAaveV4Adapter.sol";
import {MockAaveV4Spoke} from "../../../mocks/MockAaveV4Spoke.sol";
import {MockAaveV4Hub} from "../../../mocks/MockAaveV4Hub.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AaveV4Adapter_DepositUnitTest is BaseAaveV4AdapterUnitTest {
    uint256 internal constant PARTIAL_DEPOSIT_AMOUNT = DEPOSIT_AMOUNT / 2;
    uint256 internal constant TOLERANCE_SHORTFALL_AMOUNT = DEPOSIT_AMOUNT - 100;
    uint256 internal constant EXCESSIVE_SHORTFALL_AMOUNT = DEPOSIT_AMOUNT - 101;
    uint256 internal constant EXCESS_CREDIT_AMOUNT = DEPOSIT_AMOUNT + 1;

    function setUp() public {
        deal(address(s_mockUsdc), address(s_aaveV4Adapter), DEPOSIT_AMOUNT);
        _changePrank(address(s_parentVault));
    }

    function test_AaveV4Adapter_deposit_RevertWhen_CallerIsNotVault() external {
        _changePrank(i_nonOwner);
        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__OnlyVault.selector);
        s_aaveV4Adapter.deposit(DEPOSIT_AMOUNT);
    }

    function test_AaveV4Adapter_deposit_RevertWhen_AmountIsZero() external {
        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__NoZeroAmount.selector);
        s_aaveV4Adapter.deposit(0);
    }

    function test_AaveV4Adapter_deposit_BuffersWhen_AaveCannotMintShares() external {
        s_mockAaveV4Spoke.setMinimumPreviewAmount(2);

        vm.recordLogs();
        s_aaveV4Adapter.deposit(1);

        Vm.Log memory log = _assertEmittedBy(keccak256("DepositBuffered(uint256,uint256)"), address(s_aaveV4Adapter));
        assertEq(uint256(log.topics[1]), 1);
        assertEq(uint256(log.topics[2]), 1);
        assertEq(s_aaveV4Adapter.getBufferedAssets(), 1);
        assertEq(s_aaveV4Adapter.getTVL(), 1);
        assertEq(IERC20(address(s_mockUsdc)).allowance(address(s_aaveV4Adapter), address(s_mockAaveV4Spoke)), 0);
        assertEq(s_mockAaveV4Spoke.getSupplyCallCount(), 0);
    }

    function test_AaveV4Adapter_deposit_SuppliesAndClearsAccumulatedBuffer() external {
        s_mockAaveV4Spoke.setMinimumPreviewAmount(2);
        s_aaveV4Adapter.deposit(1);

        s_aaveV4Adapter.deposit(1);

        assertEq(s_aaveV4Adapter.getBufferedAssets(), 0);
        assertEq(s_aaveV4Adapter.getTVL(), 2);
        assertEq(s_mockUsdc.balanceOf(address(s_mockAaveV4Spoke)), 2);
    }

    function test_AaveV4Adapter_deposit_BuffersWhen_PreviewIsNonzeroButSupplyReturnsInvalidShares() external {
        s_mockAaveV4Spoke.setMinimumSupplyAmount(2);

        s_aaveV4Adapter.deposit(1);

        assertEq(s_aaveV4Adapter.getBufferedAssets(), 1);
        assertEq(IERC20(address(s_mockUsdc)).allowance(address(s_aaveV4Adapter), address(s_mockAaveV4Spoke)), 0);
    }

    function test_AaveV4Adapter_deposit_BuffersAtLimit() external {
        s_mockAaveV4Spoke.setMinimumPreviewAmount(51);

        s_aaveV4Adapter.deposit(50);

        assertEq(s_aaveV4Adapter.getBufferedAssets(), 50);
        assertEq(s_mockAaveV4Spoke.getSupplyCallCount(), 0);
    }

    function test_AaveV4Adapter_deposit_RevertWhen_PreviewedBufferWouldExceedLimit() external {
        s_mockAaveV4Spoke.setMinimumPreviewAmount(52);

        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__BufferedAssetsLimitExceeded.selector);
        s_aaveV4Adapter.deposit(51);

        assertEq(s_aaveV4Adapter.getBufferedAssets(), 0);
    }

    function test_AaveV4Adapter_deposit_RevertWhen_CaughtBufferWouldExceedLimit() external {
        s_mockAaveV4Spoke.setMinimumSupplyAmount(52);

        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__BufferedAssetsLimitExceeded.selector);
        s_aaveV4Adapter.deposit(51);

        assertEq(s_aaveV4Adapter.getBufferedAssets(), 0);
    }

    function test_AaveV4Adapter_deposit_BubblesUnrelatedSupplyError() external {
        s_mockAaveV4Spoke.setSupplyReverts(true);

        vm.expectRevert(abi.encodeWithSelector(MockAaveV4Spoke.MockAaveV4Spoke__SupplyReverts.selector, uint256(1)));
        s_aaveV4Adapter.deposit(1);
    }

    function test_AaveV4Adapter_deposit_BubblesPreviewErrorWithoutBuffering() external {
        s_mockAaveV4Spoke.setPreviewReverts(true);

        vm.expectRevert(abi.encodeWithSelector(MockAaveV4Hub.MockAaveV4Hub__PreviewReverts.selector, uint256(1)));
        s_aaveV4Adapter.deposit(1);

        assertEq(s_aaveV4Adapter.getBufferedAssets(), 0);
        assertEq(IERC20(address(s_mockUsdc)).allowance(address(s_aaveV4Adapter), address(s_mockAaveV4Spoke)), 0);
        assertEq(s_mockAaveV4Spoke.getSupplyCallCount(), 0);
    }

    function test_AaveV4Adapter_getTVL_ExcludesUntrackedTokenDonations() external {
        deal(address(s_mockUsdc), address(s_aaveV4Adapter), DEPOSIT_AMOUNT + 1);

        s_aaveV4Adapter.deposit(DEPOSIT_AMOUNT);

        assertEq(s_mockUsdc.balanceOf(address(s_aaveV4Adapter)), 1);
        assertEq(s_aaveV4Adapter.getTVL(), DEPOSIT_AMOUNT);
    }

    function test_AaveV4Adapter_deposit_RevertWhen_AllowanceCannotBeCleared() external {
        s_mockAaveV4Spoke.setMinimumSupplyAmount(2);
        vm.mockCallRevert(
            address(s_mockUsdc),
            abi.encodeWithSelector(IERC20.approve.selector, address(s_mockAaveV4Spoke), 0),
            abi.encodeWithSelector(IAaveV4Adapter.InvalidShares.selector)
        );

        vm.expectRevert();
        s_aaveV4Adapter.deposit(1);

        assertEq(s_aaveV4Adapter.getBufferedAssets(), 0);
    }

    function test_AaveV4Adapter_deposit_RevertWhen_DepositAmountIsLessThanRequested() external {
        s_mockAaveV4Spoke.setSupplyCreditAmount(PARTIAL_DEPOSIT_AMOUNT);

        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__IncompleteDeposit.selector);
        s_aaveV4Adapter.deposit(DEPOSIT_AMOUNT);
    }

    function test_AaveV4Adapter_deposit_RevertWhen_TVLDecreases() external {
        s_mockAaveV4Spoke.setUserSuppliedAssets(0, address(s_aaveV4Adapter), DEPOSIT_AMOUNT);
        s_mockAaveV4Spoke.setSupplyTVLDecreaseAmount(1);

        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__TVLDecreasedOnDeposit.selector);
        s_aaveV4Adapter.deposit(DEPOSIT_AMOUNT);
    }

    function test_AaveV4Adapter_deposit_RevertWhen_CreditedShortfallExceedsRoundingTolerance() external {
        s_mockAaveV4Spoke.setSupplyCreditAmount(EXCESSIVE_SHORTFALL_AMOUNT);

        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__IncompleteDeposit.selector);
        s_aaveV4Adapter.deposit(DEPOSIT_AMOUNT);
    }

    function test_AaveV4Adapter_deposit_SucceedsWhen_CreditedAmountIsWithinRoundingTolerance() external {
        s_mockAaveV4Spoke.setSupplyCreditAmount(TOLERANCE_SHORTFALL_AMOUNT);

        s_aaveV4Adapter.deposit(DEPOSIT_AMOUNT);

        assertEq(s_aaveV4Adapter.getTVL(), TOLERANCE_SHORTFALL_AMOUNT);
    }

    function test_AaveV4Adapter_deposit_SucceedsWhen_CreditedAmountExceedsRequestedAmount() external {
        s_mockAaveV4Spoke.setSupplyCreditAmount(EXCESS_CREDIT_AMOUNT);

        s_aaveV4Adapter.deposit(DEPOSIT_AMOUNT);

        assertEq(s_aaveV4Adapter.getTVL(), EXCESS_CREDIT_AMOUNT);
    }

    function test_AaveV4Adapter_deposit_Success() external {
        vm.recordLogs();
        s_aaveV4Adapter.deposit(DEPOSIT_AMOUNT);

        Vm.Log memory log = _assertEmittedBy(keccak256("Deposit(uint256)"), address(s_aaveV4Adapter));
        assertEq(uint256(log.topics[1]), DEPOSIT_AMOUNT);
        assertEq(s_mockUsdc.balanceOf(address(s_mockAaveV4Spoke)), DEPOSIT_AMOUNT);
        assertEq(s_aaveV4Adapter.getTVL(), DEPOSIT_AMOUNT);
    }
}

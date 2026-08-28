// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseAaveV3AdapterUnitTest, Vm} from "../BaseAaveV3AdapterUnitTest.t.sol";

import {IProtocolAdapter} from "../../../../src/interfaces/adapters/IProtocolAdapter.sol";
import {MockAaveV3Pool} from "../../../mocks/MockAaveV3Pool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AaveV3Adapter_DepositUnitTest is BaseAaveV3AdapterUnitTest {
    uint256 internal constant PARTIAL_DEPOSIT_AMOUNT = DEPOSIT_AMOUNT / 2;
    uint256 internal constant TOLERANCE_SHORTFALL_AMOUNT = DEPOSIT_AMOUNT - 100;
    uint256 internal constant EXCESSIVE_SHORTFALL_AMOUNT = DEPOSIT_AMOUNT - 101;
    uint256 internal constant EXCESS_CREDIT_AMOUNT = DEPOSIT_AMOUNT + 1;

    function setUp() public {
        deal(address(s_mockUsdc), address(s_aaveV3Adapter), DEPOSIT_AMOUNT);
        _changePrank(address(s_parentVault));
    }

    function test_AaveV3Adapter_deposit_RevertWhen_CallerIsNotVault() external {
        _changePrank(i_nonOwner);
        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__OnlyVault.selector);
        s_aaveV3Adapter.deposit(DEPOSIT_AMOUNT);
    }

    function test_AaveV3Adapter_deposit_RevertWhen_AmountIsZero() external {
        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__NoZeroAmount.selector);
        s_aaveV3Adapter.deposit(0);
    }

    function test_AaveV3Adapter_deposit_BuffersWhen_AaveCannotMintScaledUnits() external {
        s_mockAaveV3Pool.setNormalizedIncome(2e27);

        vm.recordLogs();
        s_aaveV3Adapter.deposit(1);

        Vm.Log memory log = _assertEmittedBy(keccak256("DepositBuffered(uint256,uint256)"), address(s_aaveV3Adapter));
        assertEq(uint256(log.topics[1]), 1);
        assertEq(uint256(log.topics[2]), 1);
        assertEq(s_aaveV3Adapter.getBufferedAssets(), 1);
        assertEq(s_aaveV3Adapter.getTVL(), 1);
        assertEq(IERC20(address(s_mockUsdc)).allowance(address(s_aaveV3Adapter), address(s_mockAaveV3Pool)), 0);
        assertEq(s_mockAaveV3Pool.getSupplyCallCount(), 0);
    }

    function test_AaveV3Adapter_deposit_BuffersWhen_FloorIsZeroButHalfUpWouldBeNonzero() external {
        s_mockAaveV3Pool.setNormalizedIncome(15e26);

        s_aaveV3Adapter.deposit(1);

        assertEq(s_aaveV3Adapter.getBufferedAssets(), 1);
        assertEq(s_mockAaveV3Pool.getSupplyCallCount(), 0);
    }

    function test_AaveV3Adapter_deposit_BubblesInvalidAmountWhen_PreviewIsNonzero() external {
        s_mockAaveV3Pool.setMinimumSupplyAmount(2);
        s_mockAaveV3Pool.setUseDeployedDustError(true);

        vm.expectRevert(MockAaveV3Pool.InvalidAmount.selector);
        s_aaveV3Adapter.deposit(1);
    }

    function test_AaveV3Adapter_deposit_BubblesInvalidMintAmountWhen_PreviewIsNonzero() external {
        s_mockAaveV3Pool.setMinimumSupplyAmount(2);

        vm.expectRevert(MockAaveV3Pool.InvalidMintAmount.selector);
        s_aaveV3Adapter.deposit(1);
    }

    function test_AaveV3Adapter_deposit_SuppliesAndClearsAccumulatedBuffer() external {
        s_mockAaveV3Pool.setNormalizedIncome(2e27);
        s_aaveV3Adapter.deposit(1);

        s_aaveV3Adapter.deposit(1);

        assertEq(s_aaveV3Adapter.getBufferedAssets(), 0);
        assertEq(s_aaveV3Adapter.getTVL(), 2);
        assertEq(s_mockUsdc.balanceOf(address(s_mockAaveV3Pool)), 2);
    }

    function test_AaveV3Adapter_deposit_BuffersAtLimit() external {
        s_mockAaveV3Pool.setNormalizedIncome(51e27);

        s_aaveV3Adapter.deposit(50);

        assertEq(s_aaveV3Adapter.getBufferedAssets(), 50);
        assertEq(s_mockAaveV3Pool.getSupplyCallCount(), 0);
    }

    function test_AaveV3Adapter_deposit_RevertWhen_BufferWouldExceedLimit() external {
        s_mockAaveV3Pool.setNormalizedIncome(52e27);

        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__BufferedAssetsLimitExceeded.selector);
        s_aaveV3Adapter.deposit(51);

        assertEq(s_aaveV3Adapter.getBufferedAssets(), 0);
    }

    function test_AaveV3Adapter_deposit_BubblesUnrelatedSupplyError() external {
        s_mockAaveV3Pool.setSupplyReverts(true);

        vm.expectRevert(abi.encodeWithSelector(MockAaveV3Pool.MockAaveV3Pool__SupplyReverts.selector, uint256(1)));
        s_aaveV3Adapter.deposit(1);
    }

    function test_AaveV3Adapter_deposit_BubblesNormalizedIncomeErrorWithoutBuffering() external {
        s_mockAaveV3Pool.setNormalizedIncomeReverts(true);

        vm.expectRevert(abi.encodeWithSelector(MockAaveV3Pool.MockAaveV3Pool__NormalizedIncomeReverts.selector, 42));
        s_aaveV3Adapter.deposit(1);

        assertEq(s_aaveV3Adapter.getBufferedAssets(), 0);
        assertEq(IERC20(address(s_mockUsdc)).allowance(address(s_aaveV3Adapter), address(s_mockAaveV3Pool)), 0);
        assertEq(s_mockAaveV3Pool.getSupplyCallCount(), 0);
    }

    function test_AaveV3Adapter_getTVL_ExcludesUntrackedTokenDonations() external {
        deal(address(s_mockUsdc), address(s_aaveV3Adapter), DEPOSIT_AMOUNT + 1);

        s_aaveV3Adapter.deposit(DEPOSIT_AMOUNT);

        assertEq(s_mockUsdc.balanceOf(address(s_aaveV3Adapter)), 1);
        assertEq(s_aaveV3Adapter.getTVL(), DEPOSIT_AMOUNT);
    }

    function test_AaveV3Adapter_deposit_RevertWhen_DepositAmountIsLessThanRequested() external {
        s_mockAaveV3Pool.setSupplyCreditAmount(PARTIAL_DEPOSIT_AMOUNT);

        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__IncompleteDeposit.selector);
        s_aaveV3Adapter.deposit(DEPOSIT_AMOUNT);
    }

    function test_AaveV3Adapter_deposit_RevertWhen_TVLDecreases() external {
        s_mockAToken.mint(address(s_aaveV3Adapter), DEPOSIT_AMOUNT);
        s_mockAaveV3Pool.setSupplyTVLDecreaseAmount(1);

        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__TVLDecreasedOnDeposit.selector);
        s_aaveV3Adapter.deposit(DEPOSIT_AMOUNT);
    }

    function test_AaveV3Adapter_deposit_RevertWhen_CreditedShortfallExceedsRoundingTolerance() external {
        s_mockAaveV3Pool.setSupplyCreditAmount(EXCESSIVE_SHORTFALL_AMOUNT);

        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__IncompleteDeposit.selector);
        s_aaveV3Adapter.deposit(DEPOSIT_AMOUNT);
    }

    function test_AaveV3Adapter_deposit_SucceedsWhen_CreditedAmountIsWithinRoundingTolerance() external {
        s_mockAaveV3Pool.setSupplyCreditAmount(TOLERANCE_SHORTFALL_AMOUNT);

        s_aaveV3Adapter.deposit(DEPOSIT_AMOUNT);

        assertEq(s_aaveV3Adapter.getTVL(), TOLERANCE_SHORTFALL_AMOUNT);
    }

    function test_AaveV3Adapter_deposit_SucceedsWhen_CreditedAmountExceedsRequestedAmount() external {
        s_mockAaveV3Pool.setSupplyCreditAmount(EXCESS_CREDIT_AMOUNT);

        s_aaveV3Adapter.deposit(DEPOSIT_AMOUNT);

        assertEq(s_aaveV3Adapter.getTVL(), EXCESS_CREDIT_AMOUNT);
    }

    function test_AaveV3Adapter_deposit_Success() external {
        vm.recordLogs();
        s_aaveV3Adapter.deposit(DEPOSIT_AMOUNT);

        Vm.Log memory log = _assertEmittedBy(keccak256("Deposit(uint256)"), address(s_aaveV3Adapter));
        assertEq(uint256(log.topics[1]), DEPOSIT_AMOUNT);
        assertEq(s_mockUsdc.balanceOf(address(s_mockAaveV3Pool)), DEPOSIT_AMOUNT);
    }
}

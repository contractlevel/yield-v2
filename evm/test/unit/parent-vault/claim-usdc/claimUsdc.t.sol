// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";
import {StdStorage, stdStorage} from "forge-std/StdStorage.sol";

import {IParentVault} from "../../../../src/interfaces/IParentVault.sol";

contract ParentVault_ClaimUsdcUnitTest is BaseUnitTest {
    using stdStorage for StdStorage;

    // At bootstrap (pricePerShare = SHARE_PRECISION), usdcOut = shareBurnAmount
    uint256 internal constant SHARE_BURN_AMOUNT = 100 * 1e6;
    uint256 internal constant LARGE_DEPOSIT_AMOUNT = 1000 * 1e6;
    uint256 internal constant EXPECTED_USDC = SHARE_BURN_AMOUNT; // 100e6 USDC

    function setUp() public {
        // Mint shares to withdrawer via the vault (which holds MINTER_ROLE)
        _changePrank(address(s_parentVault));
        s_yieldcoin.mint(i_withdrawer, SHARE_BURN_AMOUNT);

        // Deposit enough USDC so netFlow > 0 → epoch closes to CLAIMABLE without CCIP
        deal(address(s_mockUsdc), i_depositor, LARGE_DEPOSIT_AMOUNT);
        _changePrank(i_depositor);
        s_mockUsdc.approve(address(s_parentVault), type(uint256).max);
        s_parentVault.deposit(LARGE_DEPOSIT_AMOUNT);

        // Submit withdraw intent
        _changePrank(i_withdrawer);
        s_yieldcoin.approve(address(s_parentVault), type(uint256).max);
        s_parentVault.withdraw(SHARE_BURN_AMOUNT);

        // Advance time past minimum epoch period and close epoch 1
        vm.warp(block.timestamp + MIN_EPOCH_PERIOD + 1);
        _changePrank(i_epochOperator);
        s_parentVault.closeEpoch(1, 0);
        // pricePerShare = SHARE_PRECISION (bootstrap, totalShares was 0)
        // netFlow = LARGE_DEPOSIT_AMOUNT - SHARE_BURN_AMOUNT > 0 → CLAIMABLE, epoch 2 opened

        _changePrank(i_withdrawer);
    }

    function test_ParentVault_claimUsdc_RevertWhen_Paused() public givenContractIsPaused(address(s_parentVault)) {
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        s_parentVault.claimUsdc(1);
    }

    function test_ParentVault_claimUsdc_RevertWhen_EpochNotClaimable() public {
        // Epoch 2 is OPEN after setUp, not CLAIMABLE
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__EpochNotClaimable.selector, 2));
        s_parentVault.claimUsdc(2);
    }

    function test_ParentVault_claimUsdc_RevertWhen_NoWithdraw() public {
        _changePrank(i_nonOwner);
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__NoWithdraw.selector, i_nonOwner, 1));
        s_parentVault.claimUsdc(1);
    }

    function test_ParentVault_claimUsdc_Success_TransfersUsdc() public {
        (uint256 netAmount, uint256 fee) = s_parentVault.getNetAmountAndOperationFee(EXPECTED_USDC);
        uint256 withdrawerBefore = s_mockUsdc.balanceOf(i_withdrawer);
        uint256 treasuryBefore = s_mockUsdc.balanceOf(i_treasury);
        s_parentVault.claimUsdc(1);
        assertEq(s_mockUsdc.balanceOf(i_withdrawer), withdrawerBefore + netAmount);
        assertEq(s_mockUsdc.balanceOf(i_treasury), treasuryBefore + fee);
    }

    function test_ParentVault_claimUsdc_Success_BurnsShares() public {
        uint256 supplyBefore = s_yieldcoin.totalSupply();
        s_parentVault.claimUsdc(1);
        assertEq(s_yieldcoin.totalSupply(), supplyBefore - SHARE_BURN_AMOUNT);
    }

    function test_ParentVault_claimUsdc_Success_DeletesWithdrawMapping() public {
        s_parentVault.claimUsdc(1);
        assertEq(s_parentVault.getWithdrawShareBurnAmount(i_withdrawer, 1), 0);
    }

    function test_ParentVault_claimUsdc_Success_ReturnsUsdcWithdrawAmount() public {
        uint256 usdcWithdrawAmount = s_parentVault.claimUsdc(1);
        assertEq(usdcWithdrawAmount, EXPECTED_USDC);
    }

    function test_ParentVault_claimUsdc_Success_UsesTotalWithdrawClaimAmount() public {
        uint256 adjustedWithdrawClaimAmount = EXPECTED_USDC - 1;
        stdstore.target(address(s_parentVault)).sig("getEpoch(uint256)").with_key(1).depth(2)
            .checked_write(adjustedWithdrawClaimAmount);

        uint256 usdcWithdrawAmount = s_parentVault.claimUsdc(1);

        assertEq(usdcWithdrawAmount, adjustedWithdrawClaimAmount);
    }

    function test_ParentVault_claimUsdc_Success_EmitsWithdrawClaimed() public {
        (uint256 netAmount,) = s_parentVault.getNetAmountAndOperationFee(EXPECTED_USDC);
        vm.recordLogs();
        s_parentVault.claimUsdc(1);
        Vm.Log memory log =
            _assertEmittedBy(keccak256("WithdrawClaimed(uint256,address,uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), 1);
        assertEq(address(uint160(uint256(log.topics[2]))), i_withdrawer);
        assertEq(uint256(log.topics[3]), netAmount);
    }

    function test_ParentVault_claimUsdc_Success_EmitsWithdrawFeeCollected() public {
        (, uint256 fee) = s_parentVault.getNetAmountAndOperationFee(EXPECTED_USDC);
        vm.recordLogs();
        s_parentVault.claimUsdc(1);
        Vm.Log memory log =
            _assertEmittedBy(keccak256("WithdrawFeeCollected(uint256,address,uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), 1);
        assertEq(address(uint160(uint256(log.topics[2]))), i_withdrawer);
        assertEq(uint256(log.topics[3]), fee);
    }
}

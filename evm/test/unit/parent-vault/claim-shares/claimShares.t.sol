// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {IParentVault} from "../../../../src/interfaces/IParentVault.sol";

contract ParentVault_ClaimSharesUnitTest is BaseUnitTest {
    // At bootstrap (pricePerShare = SHARE_PRECISION), shares minted = USDC deposited
    uint256 internal constant DEPOSIT_AMOUNT = MIN_DEPOSIT_AMOUNT;
    uint256 internal s_expectedShares;

    function setUp() public {
        // Fund and deposit
        deal(address(s_mockUsdc), i_depositor, DEPOSIT_AMOUNT);
        _changePrank(i_depositor);
        s_mockUsdc.approve(address(s_parentVault), type(uint256).max);
        s_parentVault.deposit(DEPOSIT_AMOUNT);

        // Advance time past minimum epoch period and close epoch 1
        vm.warp(block.timestamp + MIN_EPOCH_PERIOD + 1);
        _changePrank(i_epochOperator);
        s_parentVault.closeEpoch(1, 0);
        // Epoch 1 → CLAIMABLE (netFlow = DEPOSIT_AMOUNT > 0), epoch 2 opened

        (s_expectedShares,) = s_parentVault.getNetAmountAndOperationFee(DEPOSIT_AMOUNT);

        _changePrank(i_depositor);
    }

    function test_ParentVault_claimShares_RevertWhen_Paused() public givenContractIsPaused(address(s_parentVault)) {
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        s_parentVault.claimShares(1);
    }

    function test_ParentVault_claimShares_RevertWhen_EpochNotClaimable() public {
        // Epoch 2 is OPEN after setUp, not CLAIMABLE
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__EpochNotClaimable.selector, 2));
        s_parentVault.claimShares(2);
    }

    function test_ParentVault_claimShares_RevertWhen_NoDeposit() public {
        _changePrank(i_nonOwner);
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__NoDeposit.selector, i_nonOwner, 1));
        s_parentVault.claimShares(1);
    }

    function test_ParentVault_claimShares_Success_MintsShares() public {
        s_parentVault.claimShares(1);
        assertEq(s_yieldcoin.balanceOf(i_depositor), s_expectedShares);
    }

    function test_ParentVault_claimShares_Success_DeletesDepositMapping() public {
        s_parentVault.claimShares(1);
        assertEq(s_parentVault.getDepositAmount(i_depositor, 1), 0);
    }

    function test_ParentVault_claimShares_Success_ReturnsShareMintAmount() public {
        uint256 shareMintAmount = s_parentVault.claimShares(1);
        assertEq(shareMintAmount, s_expectedShares);
    }

    function test_ParentVault_claimShares_Success_EmitsDepositClaimed() public {
        vm.recordLogs();
        s_parentVault.claimShares(1);
        Vm.Log memory log =
            _assertEmittedBy(keccak256("DepositClaimed(uint256,address,uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), 1);
        assertEq(address(uint160(uint256(log.topics[2]))), i_depositor);
        assertEq(uint256(log.topics[3]), s_expectedShares);
    }
}

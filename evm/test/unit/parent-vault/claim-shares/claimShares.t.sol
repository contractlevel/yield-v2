// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {IParentVault} from "../../../../src/interfaces/IParentVault.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";
import {BaseVault} from "../../../../src/vaults/BaseVault.sol";
import {ParentVault} from "../../../../src/vaults/ParentVault.sol";

contract ParentVault_ClaimSharesUnitTest is BaseUnitTest {
    // At bootstrap (pricePerShare = SHARE_PRECISION), shares minted = USDC deposited
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
        s_parentVault.closeEpoch(0);
        // Epoch 1 → CLAIMABLE (netFlow = DEPOSIT_AMOUNT > 0), epoch 2 opened

        s_expectedShares = DEPOSIT_AMOUNT;

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

    function test_ParentVault_claimShares_Success_SingleClaimantZeroesRemainingCounters() public {
        s_parentVault.claimShares(1);

        assertEq(s_parentVault.getEpoch(1).remainingDepositClaimAmount, 0);
        assertEq(s_parentVault.getEpoch(1).remainingShareMintAmount, 0);
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

    function test_ParentVault_claimShares_Success_DistributesRoundingRemainderToPoolExhaustingClaimant() public {
        _deployFreshParentVault();

        uint256 firstDeposit = 100 * 1e6;
        uint256 secondDeposit = 100 * 1e6;
        uint256 thirdDeposit = 101 * 1e6;
        uint256 totalDeposit = firstDeposit + secondDeposit + thirdDeposit;
        uint256 totalShares = 1_000 * 1e6;
        uint256 tvl = 2_000 * 1e6;
        uint256 pricePerShare = 2 * SHARE_PRECISION;
        uint256 expectedTotalMinted = totalDeposit * SHARE_PRECISION / pricePerShare;
        uint256 expectedFirstMint = firstDeposit * expectedTotalMinted / totalDeposit;
        uint256 expectedSecondMint = secondDeposit * (expectedTotalMinted - expectedFirstMint)
            / (totalDeposit - firstDeposit);
        uint256 expectedThirdMint = expectedTotalMinted - expectedFirstMint - expectedSecondMint;

        _setParentTotalShares(totalShares);
        _setParentPerformanceFeeHighWaterMark(pricePerShare);
        _submitDeposit(i_depositor, firstDeposit);
        _submitDeposit(i_recipient1, secondDeposit);
        _submitDeposit(i_recipient2, thirdDeposit);
        _closeEpoch(tvl);

        _changePrank(i_depositor);
        uint256 firstMint = s_parentVault.claimShares(1);
        _changePrank(i_recipient1);
        uint256 secondMint = s_parentVault.claimShares(1);
        _changePrank(i_recipient2);
        uint256 thirdMint = s_parentVault.claimShares(1);

        assertEq(firstMint, expectedFirstMint);
        assertEq(secondMint, expectedSecondMint);
        assertEq(thirdMint, expectedThirdMint);
        assertEq(firstMint + secondMint + thirdMint, expectedTotalMinted);
        assertEq(s_parentVault.getEpoch(1).remainingDepositClaimAmount, 0);
        assertEq(s_parentVault.getEpoch(1).remainingShareMintAmount, 0);
    }

    function test_ParentVault_claimShares_WhenWithdrawOnlyEpoch_DepositSideRemainingCountersAreZero() public {
        _deployFreshParentVault();

        uint256 shareBurnAmount = 100 * 1e6;
        uint256 tvl = shareBurnAmount;
        _setParentTotalShares(shareBurnAmount);
        _setParentPerformanceFeeHighWaterMark(SHARE_PRECISION);
        _submitWithdraw(i_withdrawer, shareBurnAmount);
        _closeEpoch(tvl);

        assertEq(s_parentVault.getEpoch(1).remainingDepositClaimAmount, 0);
        assertEq(s_parentVault.getEpoch(1).remainingShareMintAmount, 0);
    }

    function test_ParentVault_claimShares_Success_RemainingCountersAreIsolatedAcrossSequentialEpochs() public {
        _deployFreshParentVault();

        uint256 firstDeposit = 100 * 1e6;
        uint256 secondDeposit = 100 * 1e6;
        uint256 thirdDeposit = 101 * 1e6;
        uint256 epochOneTotalDeposit = firstDeposit + secondDeposit + thirdDeposit;
        uint256 totalShares = 1_000 * 1e6;
        uint256 tvl = 2_000 * 1e6;
        uint256 pricePerShare = 2 * SHARE_PRECISION;
        uint256 epochOneTotalMinted = epochOneTotalDeposit * SHARE_PRECISION / pricePerShare;
        uint256 firstMint = firstDeposit * epochOneTotalMinted / epochOneTotalDeposit;

        _setParentTotalShares(totalShares);
        _setParentPerformanceFeeHighWaterMark(pricePerShare);
        _submitDeposit(i_depositor, firstDeposit);
        _submitDeposit(i_recipient1, secondDeposit);
        _submitDeposit(i_recipient2, thirdDeposit);
        _closeEpoch(tvl);

        _changePrank(i_depositor);
        s_parentVault.claimShares(1);

        _submitDeposit(i_depositor, DEPOSIT_AMOUNT);
        _closeEpoch(0);

        assertEq(s_parentVault.getEpoch(1).remainingDepositClaimAmount, secondDeposit + thirdDeposit);
        assertEq(s_parentVault.getEpoch(1).remainingShareMintAmount, epochOneTotalMinted - firstMint);
        assertEq(s_parentVault.getEpoch(2).remainingDepositClaimAmount, DEPOSIT_AMOUNT);
        assertEq(s_parentVault.getEpoch(2).remainingShareMintAmount, DEPOSIT_AMOUNT);

        _changePrank(i_recipient1);
        s_parentVault.claimShares(1);
        _changePrank(i_recipient2);
        s_parentVault.claimShares(1);

        assertEq(s_parentVault.getEpoch(1).remainingDepositClaimAmount, 0);
        assertEq(s_parentVault.getEpoch(1).remainingShareMintAmount, 0);
        assertEq(s_parentVault.getEpoch(2).remainingDepositClaimAmount, DEPOSIT_AMOUNT);
        assertEq(s_parentVault.getEpoch(2).remainingShareMintAmount, DEPOSIT_AMOUNT);
    }

    function _deployFreshParentVault() internal {
        _changePrank(i_owner);
        BaseVault.ConstructorParams memory params = _baseVaultParams(PARENT_CHAIN_SELECTOR);
        s_parentVault = new ParentVault(
            params, i_treasury, address(s_yieldcoin), i_policyEngineManager, address(s_mockPolicyEngine)
        );
        s_parentVault.setInitialActiveProtocolAdapter(AAVE_V3_PROTOCOL_ID);
        s_parentVault.grantRole(Roles.EPOCH_OPERATOR_ROLE, i_epochOperator);
    }

    function _submitDeposit(address depositor, uint256 amount) internal {
        deal(address(s_mockUsdc), depositor, amount);
        _changePrank(depositor);
        s_mockUsdc.approve(address(s_parentVault), amount);
        s_parentVault.deposit(amount);
    }

    function _submitWithdraw(address withdrawer, uint256 amount) internal {
        _changePrank(address(s_parentVault));
        s_yieldcoin.mint(withdrawer, amount);
        _changePrank(withdrawer);
        s_yieldcoin.approve(address(s_parentVault), amount);
        s_parentVault.withdraw(amount);
    }

    function _closeEpoch(uint256 tvl) internal {
        vm.warp(block.timestamp + MIN_EPOCH_PERIOD + 1);
        _changePrank(i_epochOperator);
        s_parentVault.closeEpoch(tvl);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";
import {StdStorage, stdStorage} from "forge-std/StdStorage.sol";

import {IParentVault} from "../../../../src/interfaces/vaults/IParentVault.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";
import {BaseVault} from "../../../../src/vaults/BaseVault.sol";
import {ParentVault} from "../../../../src/vaults/ParentVault.sol";

contract ParentVault_ClaimAssetUnitTest is BaseUnitTest {
    using stdStorage for StdStorage;

    // At bootstrap (pricePerShare = SHARE_PRECISION), assetOut = shareBurnAmount
    uint256 internal constant SHARE_BURN_AMOUNT = 100 * 1e6;
    uint256 internal constant LARGE_DEPOSIT_AMOUNT = 1000 * 1e6;
    uint256 internal constant EXPECTED_ASSET = SHARE_BURN_AMOUNT; // 100e6 asset

    function setUp() public {
        // Mint shares to withdrawer via the vault (which holds MINTER_ROLE)
        _changePrank(address(s_parentVault));
        s_yieldcoin.mint(i_withdrawer, SHARE_BURN_AMOUNT);

        // Deposit enough asset so netFlow > 0 → epoch closes to CLAIMABLE without CCIP
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
        s_parentVault.closeEpoch(0);
        // pricePerShare = SHARE_PRECISION (bootstrap, totalShares was 0)
        // netFlow = LARGE_DEPOSIT_AMOUNT - SHARE_BURN_AMOUNT > 0 → CLAIMABLE, epoch 2 opened

        _changePrank(i_withdrawer);
    }

    function test_ParentVault_claimAsset_RevertWhen_Paused() public givenContractIsPaused(address(s_parentVault)) {
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        s_parentVault.claimAsset(1);
    }

    function test_ParentVault_claimAsset_RevertWhen_EpochNotClaimable() public {
        // Epoch 2 is OPEN after setUp, not CLAIMABLE
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__EpochNotClaimable.selector, 2));
        s_parentVault.claimAsset(2);
    }

    function test_ParentVault_claimAsset_RevertWhen_NoWithdraw() public {
        _changePrank(i_nonOwner);
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__NoWithdraw.selector, i_nonOwner, 1));
        s_parentVault.claimAsset(1);
    }

    function test_ParentVault_claimAsset_Success_TransfersAsset() public {
        uint256 withdrawerBefore = s_mockUsdc.balanceOf(i_withdrawer);
        s_parentVault.claimAsset(1);
        assertEq(s_mockUsdc.balanceOf(i_withdrawer), withdrawerBefore + EXPECTED_ASSET);
    }

    function test_ParentVault_claimAsset_Success_BurnsShares() public {
        uint256 supplyBefore = s_yieldcoin.totalSupply();
        s_parentVault.claimAsset(1);
        assertEq(s_yieldcoin.totalSupply(), supplyBefore - SHARE_BURN_AMOUNT);
    }

    function test_ParentVault_claimAsset_Success_SingleClaimantZeroesRemainingCounters() public {
        s_parentVault.claimAsset(1);

        assertEq(s_parentVault.getEpoch(1).remainingShareBurnAmount, 0);
        assertEq(s_parentVault.getEpoch(1).remainingWithdrawClaimAmount, 0);
    }

    function test_ParentVault_claimAsset_Success_DeletesWithdrawMapping() public {
        s_parentVault.claimAsset(1);
        assertEq(s_parentVault.getWithdrawShareBurnAmount(i_withdrawer, 1), 0);
    }

    function test_ParentVault_claimAsset_Success_ReturnsWithdrawAmount() public {
        uint256 withdrawAmount = s_parentVault.claimAsset(1);
        assertEq(withdrawAmount, EXPECTED_ASSET);
    }

    function test_ParentVault_claimAsset_Success_UsesTotalWithdrawClaimAmount() public {
        uint256 adjustedWithdrawClaimAmount = EXPECTED_ASSET - 1;
        stdstore.target(address(s_parentVault)).sig("getEpoch(uint256)").with_key(1).depth(2)
            .checked_write(adjustedWithdrawClaimAmount);
        stdstore.target(address(s_parentVault)).sig("getEpoch(uint256)").with_key(1).depth(7)
            .checked_write(adjustedWithdrawClaimAmount);

        uint256 withdrawAmount = s_parentVault.claimAsset(1);

        assertEq(withdrawAmount, adjustedWithdrawClaimAmount);
    }

    function test_ParentVault_claimAsset_Success_EmitsWithdrawClaimed() public {
        vm.recordLogs();
        s_parentVault.claimAsset(1);
        Vm.Log memory log =
            _assertEmittedBy(keccak256("WithdrawClaimed(uint256,address,uint256)"), address(s_parentVault));
        assertEq(uint256(log.topics[1]), 1);
        assertEq(address(uint160(uint256(log.topics[2]))), i_withdrawer);
        assertEq(uint256(log.topics[3]), EXPECTED_ASSET);
    }

    function test_ParentVault_claimAsset_Success_DistributesRoundingRemainderToPoolExhaustingClaimant() public {
        _deployFreshParentVault();

        uint256 firstBurn = 100 * 1e6;
        uint256 secondBurn = 100 * 1e6;
        uint256 thirdBurn = 101 * 1e6;
        uint256 totalBurn = firstBurn + secondBurn + thirdBurn;
        uint256 totalShares = 1_000 * 1e6;
        uint256 tvl = 2_000 * 1e6;
        uint256 adjustedWithdrawClaimAmount = 601 * 1e6;
        uint256 expectedFirstAsset = firstBurn * adjustedWithdrawClaimAmount / totalBurn;
        uint256 expectedSecondAsset =
            secondBurn * (adjustedWithdrawClaimAmount - expectedFirstAsset) / (totalBurn - firstBurn);
        uint256 expectedThirdAsset = adjustedWithdrawClaimAmount - expectedFirstAsset - expectedSecondAsset;

        _setParentTotalShares(totalShares);
        _setParentPerformanceFeeHighWaterMark(2 * SHARE_PRECISION);
        _submitWithdraw(i_withdrawer, firstBurn);
        _submitWithdraw(i_recipient1, secondBurn);
        _submitWithdraw(i_recipient2, thirdBurn);
        s_mockProtocolAdapter.setWithdrawReturnAmount(adjustedWithdrawClaimAmount);
        _closeEpoch(tvl);
        deal(address(s_mockUsdc), address(s_parentVault), adjustedWithdrawClaimAmount);

        _changePrank(i_withdrawer);
        uint256 firstAsset = s_parentVault.claimAsset(1);
        _changePrank(i_recipient1);
        uint256 secondAsset = s_parentVault.claimAsset(1);
        _changePrank(i_recipient2);
        uint256 thirdAsset = s_parentVault.claimAsset(1);

        assertEq(firstAsset, expectedFirstAsset);
        assertEq(secondAsset, expectedSecondAsset);
        assertEq(thirdAsset, expectedThirdAsset);
        assertEq(firstAsset + secondAsset + thirdAsset, adjustedWithdrawClaimAmount);
        assertEq(s_parentVault.getEpoch(1).remainingShareBurnAmount, 0);
        assertEq(s_parentVault.getEpoch(1).remainingWithdrawClaimAmount, 0);
    }

    function test_ParentVault_claimAsset_Success_RoundsDustClaimDownAndBurnsSharesWithoutTransferringAsset() public {
        _deployFreshParentVault();

        uint256 dustShareBurnAmount = 1;
        uint256 totalShares = 100 * 1e6;
        uint256 tvl = totalShares - 1;

        _setParentTotalShares(totalShares);
        _submitWithdraw(i_withdrawer, dustShareBurnAmount);
        _closeEpoch(tvl);

        uint256 withdrawerAssetBefore = s_mockUsdc.balanceOf(i_withdrawer);
        uint256 supplyBefore = s_yieldcoin.totalSupply();

        _changePrank(i_withdrawer);
        vm.recordLogs();
        uint256 withdrawAmount = s_parentVault.claimAsset(1);
        Vm.Log[] memory logs = vm.getRecordedLogs();

        assertEq(withdrawAmount, 0);
        assertEq(s_mockUsdc.balanceOf(i_withdrawer), withdrawerAssetBefore);
        assertEq(s_yieldcoin.totalSupply(), supplyBefore - dustShareBurnAmount);
        assertEq(s_parentVault.getWithdrawShareBurnAmount(i_withdrawer, 1), 0);
        assertEq(s_parentVault.getEpoch(1).remainingShareBurnAmount, 0);
        assertEq(s_parentVault.getEpoch(1).remainingWithdrawClaimAmount, 0);

        bytes32 transferSig = keccak256("Transfer(address,address,uint256)");
        for (uint256 i; i < logs.length; ++i) {
            bool isZeroAssetTransfer = logs[i].emitter == address(s_mockUsdc) && logs[i].topics[0] == transferSig
                && address(uint160(uint256(logs[i].topics[1]))) == address(s_parentVault)
                && address(uint160(uint256(logs[i].topics[2]))) == i_withdrawer
                && abi.decode(logs[i].data, (uint256)) == 0;
            assertFalse(isZeroAssetTransfer);
        }
    }

    function test_ParentVault_claimAsset_WhenDepositOnlyEpoch_WithdrawSideRemainingCountersAreZero() public {
        _deployFreshParentVault();

        _submitDeposit(i_depositor, DEPOSIT_AMOUNT);
        _closeEpoch(0);

        assertEq(s_parentVault.getEpoch(1).remainingShareBurnAmount, 0);
        assertEq(s_parentVault.getEpoch(1).remainingWithdrawClaimAmount, 0);
    }

    function _deployFreshParentVault() internal {
        _changePrank(i_owner);
        BaseVault.ConstructorParams memory params = _baseVaultParams(PARENT_CHAIN_SELECTOR);
        s_parentVault = _deployParentVaultProxy(params);
        s_mockProtocolAdapter.setVault(address(s_parentVault));
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

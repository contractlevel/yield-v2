// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";
import {IBaseVault} from "../../../../src/interfaces/vaults/IBaseVault.sol";
import {IParentVault} from "../../../../src/interfaces/vaults/IParentVault.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";
import {BaseVault} from "../../../../src/vaults/BaseVault.sol";

contract ParentVault_ClaimAssetForUnitTest is BaseUnitTest {
    uint256 internal constant SHARE_BURN_AMOUNT = 100 * YIELD_PRECISION;
    uint256 internal constant DEPOSIT = 1000 * ASSET_PRECISION;
    uint256 internal constant EXPECTED_ASSET = 100 * ASSET_PRECISION;

    function setUp() public {
        deal(address(s_mockUsdc), i_withdrawer, DEPOSIT);
        _changePrank(i_withdrawer);
        s_mockUsdc.approve(address(s_parentVault), DEPOSIT);
        s_parentVault.deposit(DEPOSIT);
        _closeEpoch(0);
        s_parentVault.claimShares(1);
        s_yieldcoin.approve(address(s_parentVault), SHARE_BURN_AMOUNT);
        s_parentVault.withdraw(SHARE_BURN_AMOUNT);
        _closeEpoch(DEPOSIT);
        deal(address(s_mockUsdc), address(s_parentVault), EXPECTED_ASSET);
        _changePrank(i_nonOwner);
    }

    function test_ParentVault_claimAssetFor_RevertWhen_Paused() public givenContractIsPaused(address(s_parentVault)) {
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        s_parentVault.claimAssetFor(i_withdrawer, 2);
    }

    function test_ParentVault_claimAssetFor_RevertWhen_UserIsZeroAddress() public {
        vm.expectRevert(IBaseVault.BaseVault__NoZeroAddress.selector);
        s_parentVault.claimAssetFor(address(0), 2);
    }

    function test_ParentVault_claimAssetFor_RevertWhen_EpochNotClaimable() public {
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__EpochNotClaimable.selector, 3));
        s_parentVault.claimAssetFor(i_withdrawer, 3);
    }

    function test_ParentVault_claimAssetFor_RevertWhen_UserHasNoWithdraw() public {
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__NoWithdraw.selector, i_recipient1, 2));
        s_parentVault.claimAssetFor(i_recipient1, 2);
    }

    function test_ParentVault_claimAssetFor_Success_IsPermissionlessAndTransfersOnlyToUser() public {
        uint256 callerBefore = s_mockUsdc.balanceOf(i_nonOwner);
        uint256 userBefore = s_mockUsdc.balanceOf(i_withdrawer);
        uint256 supplyBefore = s_yieldcoin.totalSupply();

        uint256 withdrawAmount = s_parentVault.claimAssetFor(i_withdrawer, 2);

        assertEq(withdrawAmount, EXPECTED_ASSET);
        assertEq(s_mockUsdc.balanceOf(i_nonOwner), callerBefore);
        assertEq(s_mockUsdc.balanceOf(i_withdrawer), userBefore + EXPECTED_ASSET);
        assertEq(s_yieldcoin.totalSupply(), supplyBefore - SHARE_BURN_AMOUNT);
        assertEq(s_parentVault.getWithdrawShareBurnAmount(i_withdrawer, 2), 0);
        assertEq(s_parentVault.getEpoch(2).remainingShareBurnAmount, 0);
        assertEq(s_parentVault.getEpoch(2).remainingWithdrawClaimAmount, 0);
    }

    function test_ParentVault_claimAssetFor_Success_EmitsUser() public {
        vm.recordLogs();
        s_parentVault.claimAssetFor(i_withdrawer, 2);
        Vm.Log memory log =
            _assertEmittedBy(keccak256("WithdrawClaimed(uint256,address,uint256)"), address(s_parentVault));
        assertEq(address(uint160(uint256(log.topics[2]))), i_withdrawer);
        assertEq(uint256(log.topics[3]), EXPECTED_ASSET);
    }

    function testFuzz_ParentVault_claimAssetFor_MixedClaimOrderPreservesRounding(uint8 orderSeed) public {
        _deployFreshParentVault();

        address[] memory users = _orderedUsers(orderSeed);
        uint256[3] memory burns = [uint256(100 * YIELD_PRECISION), 100 * YIELD_PRECISION, 101 * YIELD_PRECISION];
        uint256 totalShares = 1_000 * YIELD_PRECISION;
        uint256 tvl = 2_000 * ASSET_PRECISION;
        uint256 totalWithdrawAmount = 601 * ASSET_PRECISION;

        _setParentTotalShares(totalShares);
        for (uint256 i; i < users.length; ++i) {
            _submitWithdraw(users[i], burns[_userIndex(users[i])]);
        }
        s_mockProtocolAdapter.setWithdrawReturnAmount(totalWithdrawAmount);
        _closeEpoch(tvl);
        deal(address(s_mockUsdc), address(s_parentVault), totalWithdrawAmount);

        uint256 totalClaimed;
        for (uint256 i; i < users.length; ++i) {
            address user = users[i];
            uint256 shareBurnAmount = s_parentVault.getWithdrawShareBurnAmount(user, 1);
            uint256 remainingBurn = s_parentVault.getEpoch(1).remainingShareBurnAmount;
            uint256 remainingAsset = s_parentVault.getEpoch(1).remainingWithdrawClaimAmount;
            uint256 expected =
                shareBurnAmount == remainingBurn ? remainingAsset : shareBurnAmount * remainingAsset / remainingBurn;

            uint256 claimed;
            if (i % 2 == 0) {
                _changePrank(i_nonOwner);
                claimed = s_parentVault.claimAssetFor(user, 1);
            } else {
                _changePrank(user);
                claimed = s_parentVault.claimAsset(1);
            }
            assertEq(claimed, expected);
            totalClaimed += claimed;
        }

        assertEq(totalClaimed, totalWithdrawAmount);
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

    function _submitWithdraw(address user, uint256 amount) internal {
        _changePrank(address(s_parentVault));
        s_yieldcoin.mint(user, amount);
        _changePrank(user);
        s_yieldcoin.approve(address(s_parentVault), amount);
        s_parentVault.withdraw(amount);
    }

    function _orderedUsers(uint8 seed) internal view returns (address[] memory users) {
        users = new address[](3);
        users[0] = i_withdrawer;
        users[1] = i_recipient1;
        users[2] = i_recipient2;
        uint256 first = uint256(seed) % 3;
        (users[0], users[first]) = (users[first], users[0]);
        uint256 second = 1 + (uint256(seed) / 3) % 2;
        (users[1], users[second]) = (users[second], users[1]);
    }

    function _userIndex(address user) internal view returns (uint256) {
        if (user == i_withdrawer) return 0;
        if (user == i_recipient1) return 1;
        return 2;
    }

    function _closeEpoch(uint256 tvl) internal {
        vm.warp(block.timestamp + MIN_EPOCH_PERIOD + 1);
        _changePrank(i_epochOperator);
        s_parentVault.closeEpoch(tvl);
        _changePrank(i_withdrawer);
    }
}

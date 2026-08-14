// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";
import {IBaseVault} from "../../../../src/interfaces/vaults/IBaseVault.sol";
import {IParentVault} from "../../../../src/interfaces/vaults/IParentVault.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";
import {BaseVault} from "../../../../src/vaults/BaseVault.sol";

contract ParentVault_ClaimSharesForUnitTest is BaseUnitTest {
    uint256 internal s_expectedShares;

    function setUp() public {
        deal(address(s_mockUsdc), i_depositor, DEPOSIT_AMOUNT);
        _changePrank(i_depositor);
        s_mockUsdc.approve(address(s_parentVault), DEPOSIT_AMOUNT);
        s_parentVault.deposit(DEPOSIT_AMOUNT);
        vm.warp(block.timestamp + MIN_EPOCH_PERIOD + 1);
        _changePrank(i_epochOperator);
        s_parentVault.closeEpoch(s_parentVault.getEpochNonce(), 0);
        s_expectedShares = DEPOSIT_AMOUNT * YIELD_PRECISION / ASSET_PRECISION;
        _changePrank(i_nonOwner);
    }

    function test_ParentVault_claimSharesFor_RevertWhen_Paused() public givenContractIsPaused(address(s_parentVault)) {
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        s_parentVault.claimSharesFor(i_depositor, 1);
    }

    function test_ParentVault_claimSharesFor_RevertWhen_UserIsZeroAddress() public {
        vm.expectRevert(IBaseVault.BaseVault__NoZeroAddress.selector);
        s_parentVault.claimSharesFor(address(0), 1);
    }

    function test_ParentVault_claimSharesFor_RevertWhen_EpochNotClaimable() public {
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__EpochNotClaimable.selector, 2));
        s_parentVault.claimSharesFor(i_depositor, 2);
    }

    function test_ParentVault_claimSharesFor_RevertWhen_UserHasNoDeposit() public {
        vm.expectRevert(abi.encodeWithSelector(IParentVault.ParentVault__NoDeposit.selector, i_recipient1, 1));
        s_parentVault.claimSharesFor(i_recipient1, 1);
    }

    function test_ParentVault_claimSharesFor_Success_IsPermissionlessAndMintsOnlyToUser() public {
        uint256 callerBefore = s_yieldcoin.balanceOf(i_nonOwner);
        uint256 shareMintAmount = s_parentVault.claimSharesFor(i_depositor, 1);

        assertEq(shareMintAmount, s_expectedShares);
        assertEq(s_yieldcoin.balanceOf(i_nonOwner), callerBefore);
        assertEq(s_yieldcoin.balanceOf(i_depositor), s_expectedShares);
        assertEq(s_parentVault.getDepositAmount(i_depositor, 1), 0);
        assertEq(s_parentVault.getEpoch(1).remainingDepositClaimAmount, 0);
        assertEq(s_parentVault.getEpoch(1).remainingShareMintAmount, 0);
    }

    function test_ParentVault_claimSharesFor_Success_EmitsUser() public {
        vm.recordLogs();
        s_parentVault.claimSharesFor(i_depositor, 1);
        Vm.Log memory log =
            _assertEmittedBy(keccak256("DepositClaimed(uint256,address,uint256)"), address(s_parentVault));
        assertEq(address(uint160(uint256(log.topics[2]))), i_depositor);
        assertEq(uint256(log.topics[3]), s_expectedShares);
    }

    function testFuzz_ParentVault_claimSharesFor_MixedClaimOrderPreservesRounding(uint8 orderSeed) public {
        _deployFreshParentVault();

        address[] memory users = _orderedUsers(orderSeed);
        uint256[3] memory deposits = [uint256(100 * ASSET_PRECISION), 100 * ASSET_PRECISION, 101 * ASSET_PRECISION];
        uint256 totalDeposit = deposits[0] + deposits[1] + deposits[2];
        uint256 totalShares = 1_000 * YIELD_PRECISION;
        uint256 tvl = 2_000 * ASSET_PRECISION;
        uint256 totalMintAmount = totalDeposit * totalShares / tvl;

        _setParentTotalShares(totalShares);
        for (uint256 i; i < users.length; ++i) {
            _submitDeposit(users[i], deposits[_userIndex(users[i])]);
        }
        _closeEpoch(tvl);

        uint256 totalClaimed;
        for (uint256 i; i < users.length; ++i) {
            address user = users[i];
            uint256 depositAmount = s_parentVault.getDepositAmount(user, 1);
            uint256 remainingDeposit = s_parentVault.getEpoch(1).remainingDepositClaimAmount;
            uint256 remainingShares = s_parentVault.getEpoch(1).remainingShareMintAmount;
            uint256 expected = depositAmount == remainingDeposit
                ? remainingShares
                : depositAmount * remainingShares / remainingDeposit;

            uint256 claimed;
            if (i % 2 == 0) {
                _changePrank(i_nonOwner);
                claimed = s_parentVault.claimSharesFor(user, 1);
            } else {
                _changePrank(user);
                claimed = s_parentVault.claimShares(1);
            }
            assertEq(claimed, expected);
            totalClaimed += claimed;
        }

        assertEq(totalClaimed, totalMintAmount);
        assertEq(s_parentVault.getEpoch(1).remainingDepositClaimAmount, 0);
        assertEq(s_parentVault.getEpoch(1).remainingShareMintAmount, 0);
    }

    function _deployFreshParentVault() internal {
        _changePrank(i_owner);
        BaseVault.ConstructorParams memory params = _baseVaultParams(PARENT_CHAIN_SELECTOR);
        s_parentVault = _deployParentVaultProxy(params);
        s_mockProtocolAdapter.setVault(address(s_parentVault));
        s_parentVault.setInitialActiveProtocolAdapter(AAVE_V3_PROTOCOL_ID);
        s_parentVault.grantRole(Roles.EPOCH_OPERATOR_ROLE, i_epochOperator);
    }

    function _submitDeposit(address user, uint256 amount) internal {
        deal(address(s_mockUsdc), user, amount);
        _changePrank(user);
        s_mockUsdc.approve(address(s_parentVault), amount);
        s_parentVault.deposit(amount);
    }

    function _closeEpoch(uint256 tvl) internal {
        vm.warp(block.timestamp + MIN_EPOCH_PERIOD + 1);
        _changePrank(i_epochOperator);
        s_parentVault.closeEpoch(s_parentVault.getEpochNonce(), tvl);
    }

    function _orderedUsers(uint8 seed) internal view returns (address[] memory users) {
        users = new address[](3);
        users[0] = i_depositor;
        users[1] = i_recipient1;
        users[2] = i_recipient2;
        uint256 first = uint256(seed) % 3;
        (users[0], users[first]) = (users[first], users[0]);
        uint256 second = 1 + (uint256(seed) / 3) % 2;
        (users[1], users[second]) = (users[second], users[1]);
    }

    function _userIndex(address user) internal view returns (uint256) {
        if (user == i_depositor) return 0;
        if (user == i_recipient1) return 1;
        return 2;
    }
}

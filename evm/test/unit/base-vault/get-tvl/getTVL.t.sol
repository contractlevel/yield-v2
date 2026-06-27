// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";
import {StdStorage, stdStorage} from "forge-std/StdStorage.sol";

import {BaseVault, IBaseVault} from "../../../../src/vaults/BaseVault.sol";

abstract contract BaseVault_GetTVLUnitTest is BaseUnitTest {
    using stdStorage for StdStorage;

    BaseVault internal s_vault;

    uint256 internal constant TVL = 1_000 * 1e6;
    uint256 internal constant RECOVERY_AMOUNT = 250 * 1e6;

    function test_BaseVault_getTVL_ReturnsZeroWhen_NoActiveAdapter() external {
        _clearActiveAdapter();

        assertEq(s_vault.getTVL(), 0);
    }

    function test_BaseVault_getTVL_Success() external {
        _setActiveAdapter();
        s_mockProtocolAdapter.setTVL(TVL);

        assertEq(s_vault.getTVL(), TVL);
    }

    function test_BaseVault_getTVL_ReturnsRebalanceDepositRecovery_WhenAdapterTVLIsZero() external {
        _setActiveAdapter();
        _setRebalanceDepositRecoveryAmount(RECOVERY_AMOUNT);

        assertEq(s_vault.getTVL(), RECOVERY_AMOUNT);
    }

    function test_BaseVault_getTVL_ReturnsAdapterTVLPlusRebalanceDepositRecovery_WhenBothExist() external {
        _setActiveAdapter();
        s_mockProtocolAdapter.setTVL(TVL);
        _setRebalanceDepositRecoveryAmount(RECOVERY_AMOUNT);

        assertEq(s_vault.getTVL(), TVL + RECOVERY_AMOUNT);
    }

    function _setActiveAdapter() internal virtual;
    function _clearActiveAdapter() internal virtual;

    function _setRebalanceDepositRecoveryAmount(uint256 amount) internal {
        stdstore.target(address(s_vault)).sig("getRebalanceDepositRecovery()").depth(1).checked_write(amount);
    }
}

contract ParentVault_GetTVLUnitTest is BaseVault_GetTVLUnitTest {
    function setUp() public {
        s_vault = s_parentVault;
    }

    function _setActiveAdapter() internal override {}

    function _clearActiveAdapter() internal override {
        _clearParentActiveAdapter();
    }
}

contract ChildVault_GetTVLUnitTest is BaseVault_GetTVLUnitTest {
    using stdStorage for StdStorage;

    function setUp() public {
        s_vault = s_childVault;
    }

    function _setActiveAdapter() internal override {
        _setChildActiveAdapter(address(s_mockProtocolAdapter));
    }

    function _clearActiveAdapter() internal override {}

    function test_ChildVault_getTVL_ReturnsAdapterTVLPlusEpochDepositRecovery() external {
        _setActiveAdapter();
        s_mockProtocolAdapter.setTVL(TVL);
        _setEpochDepositRecoveryAmount(RECOVERY_AMOUNT);

        assertEq(s_vault.getTVL(), TVL + RECOVERY_AMOUNT);
    }

    function test_ChildVault_getTVL_ReturnsEpochDepositRecovery_WhenAdapterTVLIsZero() external {
        _setActiveAdapter();
        _setEpochDepositRecoveryAmount(RECOVERY_AMOUNT);

        assertEq(s_vault.getTVL(), RECOVERY_AMOUNT);
    }

    function _setEpochDepositRecoveryAmount(uint256 amount) internal {
        stdstore.target(address(s_childVault)).sig("getEpochDepositRecovery()").depth(1).checked_write(amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {BaseVault} from "../../../../src/vaults/BaseVault.sol";
import {ParentVault} from "../../../../src/vaults/ParentVault.sol";
import {ChildVault} from "../../../../src/vaults/ChildVault.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";
import {Types} from "../../../../src/libraries/Types.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {StdStorage, stdStorage} from "forge-std/StdStorage.sol";

contract ParentVaultV2 is ParentVault {
    constructor(BaseVault.ConstructorParams memory params, address share) ParentVault(params, share) {}

    function upgradeTestVersion() external pure returns (uint256) {
        return 2;
    }
}

contract ChildVaultV2 is ChildVault {
    constructor(BaseVault.ConstructorParams memory params, uint64 parentChainSelector)
        ChildVault(params, parentChainSelector)
    {}

    function upgradeTestVersion() external pure returns (uint256) {
        return 2;
    }
}

abstract contract BaseVault_UpgradeToAndCallUnitTest is BaseUnitTest {
    function _deployImplementation() internal virtual returns (address);

    function _getProxy() internal virtual returns (BaseVault);

    function _callInitializeOnProxy(BaseVault proxy) internal virtual;

    function test_BaseVault_upgradeToAndCall_Success() external {
        address newImpl = _deployImplementation();

        _changePrank(i_upgrader);
        _getProxy().upgradeToAndCall(newImpl, "");
    }

    function test_BaseVault_upgradeToAndCall_Success_PreservesState() external {
        BaseVault proxy = _getProxy();
        uint256 defaultCcipGasLimitBefore = proxy.getDefaultCcipGasLimit();
        bool hasPauserRole = proxy.hasRole(Roles.PAUSER_ROLE, i_pauser);
        bool hasUpgraderRole = proxy.hasRole(Roles.UPGRADER_ROLE, i_upgrader);
        bool hasDefaultAdminRole = proxy.hasRole(Roles.DEFAULT_ADMIN_ROLE, i_owner);

        address newImpl = _deployImplementation();
        _changePrank(i_upgrader);
        proxy.upgradeToAndCall(newImpl, "");

        assertEq(proxy.getDefaultCcipGasLimit(), defaultCcipGasLimitBefore);
        assertEq(proxy.hasRole(Roles.PAUSER_ROLE, i_pauser), hasPauserRole);
        assertEq(proxy.hasRole(Roles.UPGRADER_ROLE, i_upgrader), hasUpgraderRole);
        assertEq(proxy.hasRole(Roles.DEFAULT_ADMIN_ROLE, i_owner), hasDefaultAdminRole);
    }

    function test_BaseVault_upgradeToAndCall_RevertWhen_CallerDoesNotHaveUPGRADER_ROLE() external {
        address newImpl = _deployImplementation();

        _changePrank(i_nonOwner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.UPGRADER_ROLE
            )
        );
        _getProxy().upgradeToAndCall(newImpl, "");
    }

    function test_BaseVault_upgradeToAndCall_RevertWhen_CalledOnImplementation() external {
        address implementation = _deployImplementation();
        address newImpl = _deployImplementation();

        vm.expectRevert(UUPSUpgradeable.UUPSUnauthorizedCallContext.selector);
        BaseVault(payable(implementation)).upgradeToAndCall(newImpl, "");
    }

    function test_BaseVault_upgradeToAndCall_RevertWhen_ReinitializeAfterUpgrade() external {
        address newImpl = _deployImplementation();
        _changePrank(i_upgrader);
        _getProxy().upgradeToAndCall(newImpl, "");

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        _callInitializeOnProxy(_getProxy());
    }
}

contract ParentVault_BaseVaultUpgradeToAndCallUnitTest is BaseVault_UpgradeToAndCallUnitTest {
    using stdStorage for StdStorage;

    function _deployImplementation() internal override returns (address) {
        return address(new ParentVaultV2(_baseVaultParams(PARENT_CHAIN_SELECTOR), address(s_yieldcoin)));
    }

    function _getProxy() internal view override returns (BaseVault) {
        return s_parentVault;
    }

    function _callInitializeOnProxy(BaseVault proxy) internal override {
        ParentVault(address(proxy))
            .initialize(
                _baseVaultInitParams(),
                i_treasury,
                i_policyEngineManager,
                address(s_mockPolicyEngine),
                i_cancelDepositOperator
            );
    }

    function test_ParentVault_UPGRADE_007_upgradeToAndCall_Success_PreservesLifecycleState() external {
        uint256 epochNonce = 1;
        uint256 totalShares = 11_000e18;
        uint256 highWaterMark = 2e6;
        uint256 recoveryNonce = 13;
        uint256 recoveryAmount = 17e6;

        _setParentEpochStatus(epochNonce, Types.EpochStatus.EXECUTING);
        _setParentTotalShares(totalShares);
        _setParentPerformanceFeeHighWaterMark(highWaterMark);
        _setParentPendingRebalance(COMPOUND_V3_PROTOCOL_ID, CHILD_CHAIN_SELECTOR);
        _setParentLastRebalanceCompletedTimestamp(19);
        stdstore.target(address(s_parentVault)).sig("getRebalanceDepositRecovery()").depth(0)
            .checked_write(recoveryNonce);
        stdstore.target(address(s_parentVault)).sig("getRebalanceDepositRecovery()").depth(1)
            .checked_write(recoveryAmount);
        _setParentRecoveryMode(Types.RecoveryMode.REBALANCE_DEPOSIT);

        Types.Epoch memory epochBefore = s_parentVault.getEpoch(epochNonce);
        Types.Rebalance memory rebalanceBefore = s_parentVault.getRebalance();
        Types.RebalanceDepositRecovery memory recoveryBefore = s_parentVault.getRebalanceDepositRecovery();

        address newImpl = _deployImplementation();
        _changePrank(i_upgrader);
        s_parentVault.upgradeToAndCall(newImpl, "");

        assertEq(ParentVaultV2(address(s_parentVault)).upgradeTestVersion(), 2);
        assertEq(s_parentVault.getEpochNonce(), epochNonce);
        assertEq(s_parentVault.getTotalShares(), totalShares);
        assertEq(s_parentVault.getPerformanceFeeHighWaterMark(), highWaterMark);
        assertEq(keccak256(abi.encode(s_parentVault.getEpoch(epochNonce))), keccak256(abi.encode(epochBefore)));
        assertEq(keccak256(abi.encode(s_parentVault.getRebalance())), keccak256(abi.encode(rebalanceBefore)));
        assertEq(uint256(s_parentVault.getRecoveryMode()), uint256(Types.RecoveryMode.REBALANCE_DEPOSIT));
        assertEq(
            keccak256(abi.encode(s_parentVault.getRebalanceDepositRecovery())), keccak256(abi.encode(recoveryBefore))
        );
    }
}

contract ChildVault_BaseVaultUpgradeToAndCallUnitTest is BaseVault_UpgradeToAndCallUnitTest {
    using stdStorage for StdStorage;

    function _deployImplementation() internal override returns (address) {
        return address(new ChildVaultV2(_baseVaultParams(CHILD_CHAIN_SELECTOR), PARENT_CHAIN_SELECTOR));
    }

    function _getProxy() internal view override returns (BaseVault) {
        return s_childVault;
    }

    function _callInitializeOnProxy(BaseVault proxy) internal override {
        ChildVault(address(proxy)).initialize(_baseVaultInitParams());
    }

    function test_ChildVault_UPGRADE_007_upgradeToAndCall_Success_PreservesNonceAndRecoveryState() external {
        uint256 epochNonce = 23;
        uint256 rebalanceNonce = 29;
        uint256 recoveryAmount = 31e6;

        stdstore.target(address(s_childVault)).sig("getLastHandledEpochNonce()").checked_write(epochNonce);
        stdstore.target(address(s_childVault)).sig("getLastHandledRebalanceNonce()").checked_write(rebalanceNonce);
        stdstore.target(address(s_childVault)).sig("getEpochDepositRecovery()").depth(0).checked_write(epochNonce);
        stdstore.target(address(s_childVault)).sig("getEpochDepositRecovery()").depth(1).checked_write(recoveryAmount);
        stdstore.enable_packed_slots().target(address(s_childVault)).sig("getRecoveryMode()")
            .checked_write(uint256(Types.RecoveryMode.EPOCH_DEPOSIT));
        Types.EpochRecovery memory recoveryBefore = s_childVault.getEpochDepositRecovery();

        address newImpl = _deployImplementation();
        _changePrank(i_upgrader);
        s_childVault.upgradeToAndCall(newImpl, "");

        assertEq(ChildVaultV2(address(s_childVault)).upgradeTestVersion(), 2);
        assertEq(s_childVault.getLastHandledEpochNonce(), epochNonce);
        assertEq(s_childVault.getLastHandledRebalanceNonce(), rebalanceNonce);
        assertEq(uint256(s_childVault.getRecoveryMode()), uint256(Types.RecoveryMode.EPOCH_DEPOSIT));
        assertEq(keccak256(abi.encode(s_childVault.getEpochDepositRecovery())), keccak256(abi.encode(recoveryBefore)));
    }
}

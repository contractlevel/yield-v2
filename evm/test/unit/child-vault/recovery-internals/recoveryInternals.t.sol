// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {IBaseVault} from "../../../../src/interfaces/IBaseVault.sol";
import {IChildVault} from "../../../../src/interfaces/IChildVault.sol";
import {BaseVault} from "../../../../src/vaults/BaseVault.sol";
import {ChildVault} from "../../../../src/vaults/ChildVault.sol";
import {Types} from "../../../../src/libraries/Types.sol";

contract ChildVaultRecoveryInternalsHarness is ChildVault {
    constructor(BaseVault.ConstructorParams memory params, uint64 parentChainSelector)
        ChildVault(params, parentChainSelector)
    {}

    function exposed_storeRebalanceDepositRecovery(uint256 rebalanceNonce, uint256 amount) external {
        _storeRebalanceDepositRecovery(rebalanceNonce, amount);
    }

    function exposed_clearRebalanceDepositRecovery() external {
        _clearRebalanceDepositRecovery();
    }

    function exposed_storeEpochDepositRecovery(uint256 epochNonce, uint256 amount) external {
        _storeEpochDepositRecovery(epochNonce, amount);
    }

    function exposed_clearEpochDepositRecovery() external {
        _clearEpochDepositRecovery();
    }

    function exposed_storeEpochWithdrawRecovery(uint256 epochNonce, uint256 amount) external {
        _storeEpochWithdrawRecovery(epochNonce, amount);
    }

    function exposed_clearEpochWithdrawRecovery() external {
        _clearEpochWithdrawRecovery();
    }

    function exposed_storeRebalanceWithdrawRecovery(uint256 rebalanceNonce, Types.Strategy memory strategy) external {
        _storeRebalanceWithdrawRecovery(rebalanceNonce, strategy);
    }

    function exposed_clearRebalanceWithdrawRecovery() external {
        _clearRebalanceWithdrawRecovery();
    }
}

contract ChildVault_RecoveryInternalsUnitTest is BaseUnitTest {
    uint256 internal constant EPOCH_NONCE = 1;
    uint256 internal constant REBALANCE_NONCE = 1;
    uint256 internal constant RECOVERY_AMOUNT = 500 * 1e6;

    ChildVaultRecoveryInternalsHarness internal s_harness;

    function setUp() public {
        s_harness = new ChildVaultRecoveryInternalsHarness(_childVaultParams(), PARENT_CHAIN_SELECTOR);
    }

    function test_ChildVault_recoveryInternals_StoreRebalanceDepositRecovery_RevertWhen_AmountIsZero() public {
        vm.expectRevert(IBaseVault.BaseVault__ZeroRecoveryAmount.selector);
        s_harness.exposed_storeRebalanceDepositRecovery(REBALANCE_NONCE, 0);
    }

    function test_ChildVault_recoveryInternals_ClearRebalanceDepositRecovery_RevertWhen_NoPendingRecovery() public {
        vm.expectRevert(IBaseVault.BaseVault__NoPendingRecovery.selector);
        s_harness.exposed_clearRebalanceDepositRecovery();
    }

    function test_ChildVault_recoveryInternals_StoreRebalanceDepositRecovery_RevertWhen_RecoveryStateAlreadyExists()
        public
    {
        s_harness.exposed_storeRebalanceDepositRecovery(REBALANCE_NONCE, RECOVERY_AMOUNT);

        vm.expectRevert(IBaseVault.BaseVault__RecoveryAlreadyPending.selector);
        s_harness.exposed_storeRebalanceDepositRecovery(REBALANCE_NONCE + 1, RECOVERY_AMOUNT);
    }

    function test_ChildVault_recoveryInternals_StoreEpochDepositRecovery_RevertWhen_AmountIsZero() public {
        vm.expectRevert(IBaseVault.BaseVault__ZeroRecoveryAmount.selector);
        s_harness.exposed_storeEpochDepositRecovery(EPOCH_NONCE, 0);
    }

    function test_ChildVault_recoveryInternals_StoreEpochDepositRecovery_RevertWhen_EpochWithdrawRecoveryExists()
        public
    {
        s_harness.exposed_storeEpochWithdrawRecovery(EPOCH_NONCE, RECOVERY_AMOUNT);

        vm.expectRevert(IBaseVault.BaseVault__RecoveryAlreadyPending.selector);
        s_harness.exposed_storeEpochDepositRecovery(EPOCH_NONCE, RECOVERY_AMOUNT);
    }

    function test_ChildVault_recoveryInternals_StoreEpochDepositRecovery_RevertWhen_RecoveryStateAlreadyExists()
        public
    {
        s_harness.exposed_storeEpochDepositRecovery(EPOCH_NONCE, RECOVERY_AMOUNT);

        vm.expectRevert(IBaseVault.BaseVault__RecoveryAlreadyPending.selector);
        s_harness.exposed_storeEpochDepositRecovery(EPOCH_NONCE + 1, RECOVERY_AMOUNT);
    }

    function test_ChildVault_recoveryInternals_ClearEpochDepositRecovery_RevertWhen_NoPendingRecovery() public {
        vm.expectRevert(IBaseVault.BaseVault__NoPendingRecovery.selector);
        s_harness.exposed_clearEpochDepositRecovery();
    }

    function test_ChildVault_recoveryInternals_StoreEpochWithdrawRecovery_RevertWhen_AmountIsZero() public {
        vm.expectRevert(IBaseVault.BaseVault__ZeroRecoveryAmount.selector);
        s_harness.exposed_storeEpochWithdrawRecovery(EPOCH_NONCE, 0);
    }

    function test_ChildVault_recoveryInternals_StoreEpochWithdrawRecovery_RevertWhen_EpochDepositRecoveryExists()
        public
    {
        s_harness.exposed_storeEpochDepositRecovery(EPOCH_NONCE, RECOVERY_AMOUNT);

        vm.expectRevert(IBaseVault.BaseVault__RecoveryAlreadyPending.selector);
        s_harness.exposed_storeEpochWithdrawRecovery(EPOCH_NONCE, RECOVERY_AMOUNT);
    }

    function test_ChildVault_recoveryInternals_StoreEpochWithdrawRecovery_RevertWhen_RecoveryStateAlreadyExists()
        public
    {
        s_harness.exposed_storeEpochWithdrawRecovery(EPOCH_NONCE, RECOVERY_AMOUNT);

        vm.expectRevert(IBaseVault.BaseVault__RecoveryAlreadyPending.selector);
        s_harness.exposed_storeEpochWithdrawRecovery(EPOCH_NONCE + 1, RECOVERY_AMOUNT);
    }

    function test_ChildVault_recoveryInternals_ClearEpochWithdrawRecovery_RevertWhen_NoPendingRecovery() public {
        vm.expectRevert(IBaseVault.BaseVault__NoPendingRecovery.selector);
        s_harness.exposed_clearEpochWithdrawRecovery();
    }

    function test_ChildVault_recoveryInternals_StoreRebalanceWithdrawRecovery_RevertWhen_StrategyChainSelectorIsZero()
        public
    {
        Types.Strategy memory strategy = Types.Strategy({protocolId: AAVE_V3_PROTOCOL_ID, chainSelector: 0});

        vm.expectRevert(IChildVault.ChildVault__InvalidRecoveryStrategy.selector);
        s_harness.exposed_storeRebalanceWithdrawRecovery(REBALANCE_NONCE, strategy);
    }

    function test_ChildVault_recoveryInternals_ClearRebalanceWithdrawRecovery_RevertWhen_NoPendingRecovery() public {
        vm.expectRevert(IBaseVault.BaseVault__NoPendingRecovery.selector);
        s_harness.exposed_clearRebalanceWithdrawRecovery();
    }

    function test_ChildVault_recoveryInternals_StoreRebalanceWithdrawRecovery_RevertWhen_RecoveryStateAlreadyExists()
        public
    {
        Types.Strategy memory strategy =
            Types.Strategy({protocolId: AAVE_V3_PROTOCOL_ID, chainSelector: CHILD_CHAIN_SELECTOR});
        s_harness.exposed_storeRebalanceWithdrawRecovery(REBALANCE_NONCE, strategy);

        vm.expectRevert(IBaseVault.BaseVault__RecoveryAlreadyPending.selector);
        s_harness.exposed_storeRebalanceWithdrawRecovery(REBALANCE_NONCE + 1, strategy);
    }

    function _childVaultParams() internal view returns (BaseVault.ConstructorParams memory params) {
        params = BaseVault.ConstructorParams({
            link: address(s_mockLink),
            usdc: address(s_mockUsdc),
            ccipRouter: address(s_mockCcipRouter),
            defaultAdmin: address(i_owner),
            pauser: address(i_pauser),
            unpauser: address(i_unpauser),
            configOperator: address(i_configOperator),
            adapterRegistry: address(s_adapterRegistry),
            thisChainSelector: CHILD_CHAIN_SELECTOR
        });
    }
}

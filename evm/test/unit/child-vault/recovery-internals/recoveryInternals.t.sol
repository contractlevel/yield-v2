// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {IChildVault} from "../../../../src/interfaces/IChildVault.sol";
import {BaseVault} from "../../../../src/vaults/BaseVault.sol";
import {ChildVault} from "../../../../src/vaults/ChildVault.sol";
import {Types} from "../../../../src/libraries/Types.sol";

contract ChildVaultRecoveryInternalsHarness is ChildVault {
    constructor(BaseVault.ConstructorParams memory params, uint64 parentChainSelector)
        ChildVault(params, parentChainSelector)
    {}

    function exposed_storeRebalanceWithdrawRecovery(uint256 rebalanceNonce, Types.Strategy memory strategy) external {
        _storeRebalanceWithdrawRecovery(_baseVaultStorage(), rebalanceNonce, strategy);
    }
}

contract ChildVault_RecoveryInternalsUnitTest is BaseUnitTest {
    uint256 internal constant REBALANCE_NONCE = 1;

    ChildVaultRecoveryInternalsHarness internal s_harness;

    function setUp() public {
        s_harness = new ChildVaultRecoveryInternalsHarness(_childVaultParams(), PARENT_CHAIN_SELECTOR);
    }

    function test_ChildVault_recoveryInternals_StoreRebalanceWithdrawRecovery_RevertWhen_StrategyChainSelectorIsZero()
        public
    {
        Types.Strategy memory strategy = Types.Strategy({protocolId: AAVE_V3_PROTOCOL_ID, chainSelector: 0});

        vm.expectRevert(IChildVault.ChildVault__InvalidRecoveryStrategy.selector);
        s_harness.exposed_storeRebalanceWithdrawRecovery(REBALANCE_NONCE, strategy);
    }

    function _childVaultParams() internal view returns (BaseVault.ConstructorParams memory params) {
        params = BaseVault.ConstructorParams({
            link: address(s_mockLink),
            asset: address(s_mockUsdc),
            ccipRouter: address(s_mockCcipRouter),
            adapterRegistry: address(s_adapterRegistry),
            thisChainSelector: CHILD_CHAIN_SELECTOR
        });
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest, Vm} from "../BaseUnitTest.t.sol";

import {CompoundV3Adapter} from "../../../src/modules/adapters/CompoundV3Adapter.sol";
import {MockComet} from "../../mocks/MockComet.sol";
import {MockCometRewards} from "../../mocks/MockCometRewards.sol";

abstract contract BaseCompoundV3AdapterUnitTest is BaseUnitTest {
    MockComet internal s_mockComet;
    MockCometRewards internal s_mockCometRewards;
    CompoundV3Adapter internal s_compoundV3Adapter;

    constructor() {
        s_mockComet = new MockComet(address(s_mockUsdc));
        s_mockCometRewards = new MockCometRewards();
        // Distinct from the vault's underlying asset (s_mockUsdc) and the Comet market itself, matching real
        // Compound v3 deployments where the reward token (e.g. COMP) is never the base asset.
        s_mockCometRewards.setRewardToken(address(s_mockLink));
        s_compoundV3Adapter =
            new CompoundV3Adapter(address(s_parentVault), address(s_mockComet), address(s_mockCometRewards));

        vm.label(address(s_mockComet), "MockComet");
        vm.label(address(s_mockCometRewards), "MockCometRewards");
        vm.label(address(s_compoundV3Adapter), "CompoundV3Adapter");
    }

    /// @notice Empty test function to ignore file in coverage report
    function test_baseTest() public virtual override {}
}

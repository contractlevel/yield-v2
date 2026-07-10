// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseCompoundV3AdapterUnitTest} from "../BaseCompoundV3AdapterUnitTest.t.sol";
import {CompoundV3Adapter} from "../../../../src/modules/adapters/CompoundV3Adapter.sol";
import {IProtocolAdapter} from "../../../../src/interfaces/IProtocolAdapter.sol";
import {MockComet} from "../../../mocks/MockComet.sol";

contract CompoundV3Adapter_ConstructorUnitTest is BaseCompoundV3AdapterUnitTest {
    function test_CompoundV3Adapter_constructor_SetsComet() public view {
        assertEq(s_compoundV3Adapter.getVault(), address(s_parentVault));
        assertEq(s_compoundV3Adapter.getAsset(), address(s_mockUsdc));
        assertEq(s_compoundV3Adapter.getProtocolPool(), address(s_mockComet));
        assertEq(s_compoundV3Adapter.getCometRewards(), address(s_mockCometRewards));
        assertEq(s_compoundV3Adapter.getTVL(), 0);
    }

    function test_CompoundV3Adapter_constructor_RevertWhen_VaultIsZeroAddress() public {
        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__NoZeroAddress.selector);
        new CompoundV3Adapter(address(0), address(s_mockComet), address(s_mockCometRewards));
    }

    function test_CompoundV3Adapter_constructor_RevertWhen_CometIsZeroAddress() public {
        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__NoZeroAddress.selector);
        new CompoundV3Adapter(address(s_parentVault), address(0), address(s_mockCometRewards));
    }

    function test_CompoundV3Adapter_constructor_RevertWhen_CometRewardsIsZeroAddress() public {
        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__NoZeroAddress.selector);
        new CompoundV3Adapter(address(s_parentVault), address(s_mockComet), address(0));
    }

    function test_CompoundV3Adapter_constructor_RevertWhen_AssetMismatch() external {
        MockComet mismatchedComet = new MockComet(address(1));

        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__AssetMismatch.selector);
        new CompoundV3Adapter(address(s_parentVault), address(mismatchedComet), address(s_mockCometRewards));
    }
}

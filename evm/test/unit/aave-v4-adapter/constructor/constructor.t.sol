// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseAaveV4AdapterUnitTest} from "../BaseAaveV4AdapterUnitTest.t.sol";
import {AaveV4Adapter} from "../../../../src/modules/adapters/AaveV4Adapter.sol";
import {IProtocolAdapter} from "../../../../src/interfaces/IProtocolAdapter.sol";
import {MockAaveV4Spoke} from "../../../mocks/MockAaveV4Spoke.sol";

contract AaveV4Adapter_ConstructorUnitTest is BaseAaveV4AdapterUnitTest {
    function test_AaveV4Adapter_constructor_SetsSpokeAndDiscoveredReserveId() public view {
        assertEq(s_aaveV4Adapter.getProtocolPool(), address(s_mockAaveV4Spoke));
        assertEq(s_aaveV4Adapter.getReserveId(), 0);
        assertEq(s_aaveV4Adapter.getTVL(), 0);
    }

    function test_AaveV4Adapter_constructor_RevertWhen_VaultIsZeroAddress() public {
        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__NoZeroAddress.selector);
        new AaveV4Adapter(address(0), address(s_mockAaveV4Spoke));
    }

    function test_AaveV4Adapter_constructor_RevertWhen_SpokeIsZeroAddress() public {
        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__NoZeroAddress.selector);
        new AaveV4Adapter(address(s_parentVault), address(0));
    }

    function test_AaveV4Adapter_constructor_RevertWhen_ReserveNotFound() external {
        MockAaveV4Spoke mockAaveV4Spoke = new MockAaveV4Spoke(address(1));

        vm.expectRevert(AaveV4Adapter.AaveV4Adapter__ReserveNotFound.selector);
        new AaveV4Adapter(address(s_parentVault), address(mockAaveV4Spoke));
    }

    function test_AaveV4Adapter_constructor_RevertWhen_DuplicateReserveFound() external {
        s_mockAaveV4Spoke.addReserve(address(s_mockUsdc));

        vm.expectRevert(AaveV4Adapter.AaveV4Adapter__DuplicateReserveFound.selector);
        new AaveV4Adapter(address(s_parentVault), address(s_mockAaveV4Spoke));
    }
}

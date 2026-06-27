// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {IAdapterRegistry} from "../../../../src/interfaces/IAdapterRegistry.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract AdapterRegistry_SetAdapterUnitTest is BaseUnitTest {
    address internal immutable i_adapter = makeAddr("adapter");

    function setUp() public {
        _changePrank(i_configOperator);
    }

    function test_AdapterRegistry_setAdapter_RevertWhen_CallerDoesNotHaveCONFIG_OPERATOR_ROLE()
        external
        whenCallerIsNotAdmin
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.CONFIG_OPERATOR_ROLE
            )
        );
        s_adapterRegistry.setAdapter(AAVE_V3_PROTOCOL_ID, i_adapter);
    }

    function test_AdapterRegistry_setAdapter_RevertWhen_ProtocolIdIsZero() external {
        vm.expectRevert(IAdapterRegistry.AdapterRegistry__NoZeroProtocolId.selector);
        s_adapterRegistry.setAdapter(bytes32(0), i_adapter);
    }

    function test_AdapterRegistry_setAdapter_Success() external {
        vm.recordLogs();
        s_adapterRegistry.setAdapter(AAVE_V3_PROTOCOL_ID, i_adapter);

        Vm.Log memory log = _assertEmittedBy(keccak256("AdapterSet(bytes32,address)"), address(s_adapterRegistry));
        assertEq(log.topics[1], AAVE_V3_PROTOCOL_ID);
        assertEq(address(uint160(uint256(log.topics[2]))), i_adapter);
        assertEq(s_adapterRegistry.getAdapter(AAVE_V3_PROTOCOL_ID), i_adapter);
    }

    function test_AdapterRegistry_setAdapter_Success_WhenAdapterIsZeroAddress_RemovesAdapter() external {
        s_adapterRegistry.setAdapter(AAVE_V3_PROTOCOL_ID, i_adapter);

        vm.recordLogs();
        s_adapterRegistry.setAdapter(AAVE_V3_PROTOCOL_ID, address(0));

        Vm.Log memory log = _assertEmittedBy(keccak256("AdapterSet(bytes32,address)"), address(s_adapterRegistry));
        assertEq(log.topics[1], AAVE_V3_PROTOCOL_ID);
        assertEq(address(uint160(uint256(log.topics[2]))), address(0));
        assertEq(s_adapterRegistry.getAdapter(AAVE_V3_PROTOCOL_ID), address(0));
    }
}

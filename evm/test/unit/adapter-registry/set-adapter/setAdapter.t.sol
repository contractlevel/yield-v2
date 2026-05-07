// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract AdapterRegistry_SetAdapterUnitTest is BaseUnitTest {
    address internal immutable i_adapter = makeAddr("adapter");

    function setUp() public {
        _changePrank(i_owner);
    }

    function test_AdapterRegistry_setAdapter_RevertWhen_CallerIsNotOwner() external whenCallerIsNotAdmin {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, i_nonOwner));
        s_adapterRegistry.setAdapter(AAVE_V3_PROTOCOL_ID, i_adapter);
    }

    function test_AdapterRegistry_setAdapter_Success() external {
        vm.recordLogs();
        s_adapterRegistry.setAdapter(AAVE_V3_PROTOCOL_ID, i_adapter);

        Vm.Log memory log = _assertEmittedBy(keccak256("AdapterSet(bytes32,address)"), address(s_adapterRegistry));
        assertEq(log.topics[1], AAVE_V3_PROTOCOL_ID);
        assertEq(address(uint160(uint256(log.topics[2]))), i_adapter);
        assertEq(s_adapterRegistry.getAdapter(AAVE_V3_PROTOCOL_ID), i_adapter);
    }
}

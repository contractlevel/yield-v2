// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {ParentVault} from "../../../../src/vaults/ParentVault.sol";
import {IBaseVault} from "../../../../src/interfaces/IBaseVault.sol";
import {IParentVault} from "../../../../src/interfaces/IParentVault.sol";

contract ParentVault_SetInitialActiveProtocolAdapterUnitTest is BaseUnitTest {
    ParentVault internal s_uninitializedParentVault;

    function setUp() public {
        _changePrank(i_owner);
        s_uninitializedParentVault = _deployParentVaultProxy(_baseVaultParams(PARENT_CHAIN_SELECTOR));
        s_mockProtocolAdapter.setVault(address(s_uninitializedParentVault));
    }

    function test_ParentVault_setInitialActiveProtocolAdapter_RevertWhen_CallerDoesNotHaveDEFAULT_ADMIN_ROLE()
        external
        whenCallerIsNotAdmin
    {
        vm.expectRevert();
        s_uninitializedParentVault.setInitialActiveProtocolAdapter(AAVE_V3_PROTOCOL_ID);
    }

    function test_ParentVault_setInitialActiveProtocolAdapter_RevertWhen_NoAdapterRegistered() external {
        bytes32 unknownProtocolId = keccak256("UNKNOWN_PROTOCOL");

        vm.expectRevert(abi.encodeWithSelector(IBaseVault.BaseVault__NoAdapterRegistered.selector, unknownProtocolId));
        s_uninitializedParentVault.setInitialActiveProtocolAdapter(unknownProtocolId);
    }

    function test_ParentVault_setInitialActiveProtocolAdapter_RevertWhen_AdapterBoundToDifferentVault() external {
        s_mockProtocolAdapter.setVault(address(s_parentVault));

        vm.expectRevert(
            abi.encodeWithSelector(
                IBaseVault.BaseVault__InvalidAdapterVault.selector,
                address(s_mockProtocolAdapter),
                address(s_parentVault),
                address(s_uninitializedParentVault)
            )
        );
        s_uninitializedParentVault.setInitialActiveProtocolAdapter(AAVE_V3_PROTOCOL_ID);
    }

    function test_ParentVault_setInitialActiveProtocolAdapter_RevertWhen_AlreadySet() external {
        s_uninitializedParentVault.setInitialActiveProtocolAdapter(AAVE_V3_PROTOCOL_ID);

        vm.expectRevert(IParentVault.ParentVault__InitialActiveProtocolAdapterAlreadySet.selector);
        s_uninitializedParentVault.setInitialActiveProtocolAdapter(AAVE_V3_PROTOCOL_ID);
    }

    function test_ParentVault_setInitialActiveProtocolAdapter_Success() external {
        s_uninitializedParentVault.setInitialActiveProtocolAdapter(AAVE_V3_PROTOCOL_ID);
        assertEq(s_uninitializedParentVault.getInitialActiveProtocolAdapterSet(), true);
        assertEq(s_uninitializedParentVault.getActiveProtocolAdapter(), address(s_mockProtocolAdapter));
        assertEq(s_uninitializedParentVault.getRebalance().activeStrategy.protocolId, AAVE_V3_PROTOCOL_ID);
        assertEq(s_uninitializedParentVault.getRebalance().activeStrategy.chainSelector, PARENT_CHAIN_SELECTOR);
    }

    function test_ParentVault_setInitialActiveProtocolAdapter_Success_EmitsInitialActiveProtocolAdapterSetEvent()
        external
    {
        vm.recordLogs();

        s_uninitializedParentVault.setInitialActiveProtocolAdapter(AAVE_V3_PROTOCOL_ID);

        Vm.Log memory log = _assertEmittedBy(
            keccak256("InitialActiveProtocolAdapterSet(bytes32,address)"), address(s_uninitializedParentVault)
        );
        assertEq(log.topics[1], AAVE_V3_PROTOCOL_ID);
        assertEq(address(uint160(uint256(log.topics[2]))), address(s_mockProtocolAdapter));
    }

    function test_ParentVault_setInitialActiveProtocolAdapter_Success_EmitsActiveProtocolAdapterSetEvent() external {
        vm.recordLogs();

        s_uninitializedParentVault.setInitialActiveProtocolAdapter(AAVE_V3_PROTOCOL_ID);

        Vm.Log memory log = _assertEmittedBy(
            keccak256("ActiveProtocolAdapterSet(bytes32,address)"), address(s_uninitializedParentVault)
        );
        assertEq(log.topics[1], AAVE_V3_PROTOCOL_ID);
        assertEq(address(uint160(uint256(log.topics[2]))), address(s_mockProtocolAdapter));
    }
}

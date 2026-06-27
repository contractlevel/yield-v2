// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {BaseVault, IBaseVault} from "../../../../src/vaults/BaseVault.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

abstract contract BaseVault_SetDefaultCcipGasLimitUnitTest is BaseUnitTest {
    BaseVault internal s_vault;

    function test_BaseVault_setDefaultCcipGasLimit_RevertWhen_CallerDoesNotHaveCONFIG_OPERATOR_ROLE() external {
        _changePrank(i_nonOwner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.CONFIG_OPERATOR_ROLE
            )
        );
        s_vault.setDefaultCcipGasLimit(DEFAULT_CCIP_GAS_LIMIT);
    }

    function test_BaseVault_setDefaultCcipGasLimit_RevertWhen_GasLimitIsZero() external {
        vm.expectRevert(IBaseVault.BaseVault__NoZeroAmount.selector);
        s_vault.setDefaultCcipGasLimit(0);
    }

    function test_BaseVault_setDefaultCcipGasLimit_Success() external {
        vm.recordLogs();
        s_vault.setDefaultCcipGasLimit(DEFAULT_CCIP_GAS_LIMIT);

        Vm.Log memory log = _assertEmittedBy(keccak256("DefaultCcipGasLimitSet(uint256)"), address(s_vault));
        assertEq(uint256(log.topics[1]), DEFAULT_CCIP_GAS_LIMIT);
        assertEq(s_vault.getDefaultCcipGasLimit(), DEFAULT_CCIP_GAS_LIMIT);
    }
}

contract ParentVault_SetDefaultCcipGasLimitUnitTest is BaseVault_SetDefaultCcipGasLimitUnitTest {
    function setUp() public {
        s_vault = s_parentVault;
        _changePrank(i_configOperator);
    }
}

contract ChildVault_SetDefaultCcipGasLimitUnitTest is BaseVault_SetDefaultCcipGasLimitUnitTest {
    function setUp() public {
        s_vault = s_childVault;
        _changePrank(i_configOperator);
    }
}

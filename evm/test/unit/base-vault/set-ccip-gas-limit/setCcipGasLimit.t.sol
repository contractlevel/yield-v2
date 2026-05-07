// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {BaseVault} from "../../../../src/vaults/BaseVault.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

abstract contract BaseVault_SetCcipGasLimitUnitTest is BaseUnitTest {
    BaseVault internal s_vault;

    uint64 internal constant GAS_LIMIT_CHAIN_SELECTOR = CHAIN_SELECTOR;
    uint256 internal constant CCIP_GAS_LIMIT = 500_000;

    function test_BaseVault_setCcipGasLimit_RevertWhen_CallerDoesNotHaveCONFIG_OPERATOR_ROLE() external {
        _changePrank(i_nonOwner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.CONFIG_OPERATOR_ROLE
            )
        );
        s_vault.setCcipGasLimit(GAS_LIMIT_CHAIN_SELECTOR, CCIP_GAS_LIMIT);
    }

    function test_BaseVault_setCcipGasLimit_Success() external {
        vm.recordLogs();
        s_vault.setCcipGasLimit(GAS_LIMIT_CHAIN_SELECTOR, CCIP_GAS_LIMIT);

        Vm.Log memory log = _assertEmittedBy(keccak256("CcipGasLimitSet(uint64,uint256)"), address(s_vault));
        assertEq(uint64(uint256(log.topics[1])), GAS_LIMIT_CHAIN_SELECTOR);
        assertEq(uint256(log.topics[2]), CCIP_GAS_LIMIT);
        assertEq(s_vault.getCcipGasLimit(GAS_LIMIT_CHAIN_SELECTOR), CCIP_GAS_LIMIT);
    }
}

contract ParentVault_SetCcipGasLimitUnitTest is BaseVault_SetCcipGasLimitUnitTest {
    function setUp() public {
        s_vault = s_parentVault;
        _changePrank(i_configOperator);
    }
}

contract ChildVault_SetCcipGasLimitUnitTest is BaseVault_SetCcipGasLimitUnitTest {
    function setUp() public {
        s_vault = s_childVault;
        _changePrank(i_configOperator);
    }
}

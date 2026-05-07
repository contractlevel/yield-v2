// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest, Vm} from "../../BaseUnitTest.t.sol";

import {BaseVault, IBaseVault} from "../../../../src/vaults/BaseVault.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

abstract contract BaseVault_SetCrosschainVaultsUnitTest is BaseUnitTest {
    BaseVault internal s_vault;

    address internal immutable i_crosschainVault = makeAddr("crosschainVault");

    function test_BaseVault_setCrosschainVaults_RevertWhen_CallerDoesNotHaveCONFIG_OPERATOR_ROLE()
        external
        whenCallerIsNotAdmin
    {
        uint64[] memory chainSelectors = new uint64[](1);
        chainSelectors[0] = CHAIN_SELECTOR;
        address[] memory vaults = new address[](1);
        vaults[0] = i_crosschainVault;

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, i_nonOwner, Roles.CONFIG_OPERATOR_ROLE
            )
        );
        s_vault.setCrosschainVaults(chainSelectors, vaults);
    }

    function test_BaseVault_setCrosschainVaults_RevertWhen_ArrayLengthsDoNotMatch() external {
        uint64[] memory chainSelectors = new uint64[](2);
        address[] memory vaults = new address[](1);

        vm.expectRevert(IBaseVault.BaseVault__InvalidInputLengths.selector);
        s_vault.setCrosschainVaults(chainSelectors, vaults);
    }

    function test_BaseVault_setCrosschainVaults_Success() external {
        uint64[] memory chainSelectors = new uint64[](1);
        chainSelectors[0] = CHAIN_SELECTOR;
        address[] memory vaults = new address[](1);
        vaults[0] = i_crosschainVault;

        vm.recordLogs();
        s_vault.setCrosschainVaults(chainSelectors, vaults);

        Vm.Log memory log = _assertEmittedBy(keccak256("CrosschainVaultSet(uint64,address)"), address(s_vault));
        assertEq(uint64(uint256(log.topics[1])), CHAIN_SELECTOR);
        assertEq(address(uint160(uint256(log.topics[2]))), i_crosschainVault);
        assertEq(s_vault.getCrosschainVault(CHAIN_SELECTOR), i_crosschainVault);
    }
}

contract ParentVault_SetCrosschainVaultsUnitTest is BaseVault_SetCrosschainVaultsUnitTest {
    function setUp() public {
        s_vault = s_parentVault;
        _changePrank(i_configOperator);
    }
}

contract ChildVault_SetCrosschainVaultsUnitTest is BaseVault_SetCrosschainVaultsUnitTest {
    function setUp() public {
        s_vault = s_childVault;
        _changePrank(i_configOperator);
    }
}

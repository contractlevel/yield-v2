// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";
import {IShare} from "../../../../src/interfaces/token/IShare.sol";
import {YieldcoinShare} from "../../../../src/token/YieldcoinShare.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract YieldcoinShare_InitializeUnitTest is BaseUnitTest {
    function test_YieldcoinShare_initialize_Success() external view {
        assertEq(s_yieldcoin.name(), "Yieldcoin");
        assertEq(s_yieldcoin.symbol(), "YIELD");
        assertEq(s_yieldcoin.decimals(), 18);
        assertEq(s_yieldcoin.getCCIPAdmin(), i_configOperator);
        assertEq(s_yieldcoin.defaultAdmin(), i_owner);
        assertFalse(s_yieldcoin.paused());
        assertTrue(s_yieldcoin.hasRole(Roles.PAUSER_ROLE, i_pauser));
        assertTrue(s_yieldcoin.hasRole(Roles.UNPAUSER_ROLE, i_unpauser));
        assertTrue(s_yieldcoin.hasRole(Roles.CONFIG_OPERATOR_ROLE, i_configOperator));
        assertTrue(s_yieldcoin.hasRole(Roles.UPGRADER_ROLE, i_upgrader));
    }

    function test_YieldcoinShare_initialize_RevertWhen_DefaultAdminIsZero() external {
        _expectInitializationRevert(address(0), i_pauser, i_unpauser, i_configOperator, i_configOperator, i_upgrader);
    }

    function test_YieldcoinShare_initialize_RevertWhen_PauserIsZero() external {
        _expectInitializationRevert(i_owner, address(0), i_unpauser, i_configOperator, i_configOperator, i_upgrader);
    }

    function test_YieldcoinShare_initialize_RevertWhen_UnpauserIsZero() external {
        _expectInitializationRevert(i_owner, i_pauser, address(0), i_configOperator, i_configOperator, i_upgrader);
    }

    function test_YieldcoinShare_initialize_RevertWhen_ConfigOperatorIsZero() external {
        _expectInitializationRevert(i_owner, i_pauser, i_unpauser, address(0), i_configOperator, i_upgrader);
    }

    function test_YieldcoinShare_initialize_RevertWhen_CcipAdminIsZero() external {
        _expectInitializationRevert(i_owner, i_pauser, i_unpauser, i_configOperator, address(0), i_upgrader);
    }

    function test_YieldcoinShare_initialize_RevertWhen_UpgraderIsZero() external {
        _expectInitializationRevert(i_owner, i_pauser, i_unpauser, i_configOperator, i_configOperator, address(0));
    }

    function test_YieldcoinShare_initialize_RevertWhen_AlreadyInitialized() external {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        s_yieldcoin.initialize(i_owner, i_pauser, i_unpauser, i_configOperator, i_configOperator, i_upgrader);
    }

    function test_YieldcoinShare_initialize_RevertWhen_CalledOnImplementation() external {
        YieldcoinShare implementation = new YieldcoinShare();
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        implementation.initialize(i_owner, i_pauser, i_unpauser, i_configOperator, i_configOperator, i_upgrader);
    }

    function _expectInitializationRevert(
        address defaultAdmin,
        address pauser,
        address unpauser,
        address configOperator,
        address ccipAdmin,
        address upgrader
    ) internal {
        YieldcoinShare implementation = new YieldcoinShare();
        vm.expectRevert(IShare.YieldcoinShare__NoZeroAddress.selector);
        new ERC1967Proxy(
            address(implementation),
            abi.encodeCall(
                YieldcoinShare.initialize, (defaultAdmin, pauser, unpauser, configOperator, ccipAdmin, upgrader)
            )
        );
    }
}

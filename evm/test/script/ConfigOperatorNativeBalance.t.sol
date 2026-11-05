// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Test} from "forge-std/Test.sol";

import {
    ConfigOperatorNativeBalance,
    FundConfigOperator,
    SweepConfigOperator
} from "../../script/interactions/ConfigOperatorNativeBalance.s.sol";

contract ConfigOperatorNativeBalanceTest is Test {
    address private constant MAINNET_DEPLOYER = 0x4920e32FE7169187bB61F717512Fd967fa9A5C9C;
    address private constant CONFIG_OPERATOR = 0xD22f590FE47d4F9882C68c919bE295bC42013b50;

    FundConfigOperator private funder;
    SweepConfigOperator private sweeper;

    function setUp() public {
        vm.chainId(1);
        funder = new FundConfigOperator();
        sweeper = new SweepConfigOperator();
    }

    function test_FundConfigOperator() public {
        vm.deal(MAINNET_DEPLOYER, 2_000_000);
        vm.deal(address(funder), 1_000_000);

        vm.prank(MAINNET_DEPLOYER);
        funder.fund(1_000_000);

        assertEq(CONFIG_OPERATOR.balance, 1_000_000);
    }

    function test_SweepConfigOperator() public {
        vm.deal(CONFIG_OPERATOR, 2_000_000);
        vm.deal(address(sweeper), 1_000_000);

        vm.prank(CONFIG_OPERATOR);
        sweeper.sweep(1_000_000);

        assertEq(MAINNET_DEPLOYER.balance, 1_000_000);
    }

    function test_availableBalance() public view {
        assertEq(funder.availableBalance(2_000_000, 500_000), 1_500_000);
    }

    function test_availableBalance_RevertWhenReserveIsZero() public {
        vm.expectRevert(ConfigOperatorNativeBalance.ConfigOperatorNativeBalance__ZeroReserve.selector);
        funder.availableBalance(2_000_000, 0);
    }

    function test_availableBalance_RevertWhenReserveExhaustsBalance() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                ConfigOperatorNativeBalance.ConfigOperatorNativeBalance__ReserveExhaustsBalance.selector,
                2_000_000,
                2_000_000
            )
        );
        funder.availableBalance(2_000_000, 2_000_000);
    }

    function test_FundConfigOperator_RevertWhenWrongSender() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                ConfigOperatorNativeBalance.ConfigOperatorNativeBalance__WrongSender.selector,
                MAINNET_DEPLOYER,
                address(this)
            )
        );
        funder.fund(1);
    }

    function test_FundConfigOperator_RevertWhenUnsupportedChain() public {
        vm.chainId(11_155_111);
        vm.prank(MAINNET_DEPLOYER);
        vm.expectRevert(
            abi.encodeWithSelector(
                ConfigOperatorNativeBalance.ConfigOperatorNativeBalance__UnsupportedChain.selector, 11_155_111
            )
        );
        funder.fund(1);
    }

    function test_FundConfigOperator_RevertWhenZeroAmount() public {
        vm.prank(MAINNET_DEPLOYER);
        vm.expectRevert(ConfigOperatorNativeBalance.ConfigOperatorNativeBalance__ZeroAmount.selector);
        funder.fund(0);
    }

    function test_FundConfigOperator_RevertWhenInsufficientBalance() public {
        vm.deal(MAINNET_DEPLOYER, 1);
        vm.prank(MAINNET_DEPLOYER);
        vm.expectRevert(
            abi.encodeWithSelector(
                ConfigOperatorNativeBalance.ConfigOperatorNativeBalance__InsufficientBalance.selector, 1, 2
            )
        );
        funder.fund(2);
    }
}

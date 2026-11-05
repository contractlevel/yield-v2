// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Script} from "forge-std/Script.sol";

abstract contract ConfigOperatorNativeBalance is Script {
    error ConfigOperatorNativeBalance__UnsupportedChain(uint256 chainId);
    error ConfigOperatorNativeBalance__WrongSender(address expected, address actual);
    error ConfigOperatorNativeBalance__ZeroAmount();
    error ConfigOperatorNativeBalance__ZeroReserve();
    error ConfigOperatorNativeBalance__ReserveExhaustsBalance(uint256 balance, uint256 reserve);
    error ConfigOperatorNativeBalance__InsufficientBalance(uint256 balance, uint256 required);
    error ConfigOperatorNativeBalance__TransferFailed();

    address internal constant MAINNET_DEPLOYER = 0x4920e32FE7169187bB61F717512Fd967fa9A5C9C;
    address internal constant CONFIG_OPERATOR = 0xD22f590FE47d4F9882C68c919bE295bC42013b50;

    function _validate(address expectedSender, uint256 amount) internal view {
        if (!_isSupportedMainnet(block.chainid)) {
            revert ConfigOperatorNativeBalance__UnsupportedChain(block.chainid);
        }
        if (msg.sender != expectedSender) {
            revert ConfigOperatorNativeBalance__WrongSender(expectedSender, msg.sender);
        }
        if (amount == 0) revert ConfigOperatorNativeBalance__ZeroAmount();
        if (msg.sender.balance < amount) {
            revert ConfigOperatorNativeBalance__InsufficientBalance(msg.sender.balance, amount);
        }
    }

    function _send(address recipient, uint256 amount) internal {
        (bool success,) = payable(recipient).call{value: amount}("");
        if (!success) revert ConfigOperatorNativeBalance__TransferFailed();
    }

    function availableBalance(uint256 balance, uint256 reserve) public pure returns (uint256 amount) {
        if (reserve == 0) revert ConfigOperatorNativeBalance__ZeroReserve();
        if (reserve >= balance) {
            revert ConfigOperatorNativeBalance__ReserveExhaustsBalance(balance, reserve);
        }
        return balance - reserve;
    }

    function _isSupportedMainnet(uint256 chainId) private pure returns (bool) {
        return
            chainId == 1 || chainId == 10 || chainId == 137 || chainId == 8453 || chainId == 42_161 || chainId == 43_114;
    }
}

contract FundConfigOperator is ConfigOperatorNativeBalance {
    function run() external {
        uint256 reserve = vm.envUint("FUNDING_GAS_RESERVE_WEI");
        uint256 amount = availableBalance(msg.sender.balance, reserve);
        vm.startBroadcast(msg.sender);
        fund(amount);
        vm.stopBroadcast();
    }

    function fund(uint256 amount) public {
        _validate(MAINNET_DEPLOYER, amount);
        _send(CONFIG_OPERATOR, amount);
    }
}

contract SweepConfigOperator is ConfigOperatorNativeBalance {
    function run() external {
        uint256 reserve = vm.envUint("SWEEP_GAS_RESERVE_WEI");
        uint256 amount = availableBalance(msg.sender.balance, reserve);
        vm.startBroadcast(msg.sender);
        sweep(amount);
        vm.stopBroadcast();
    }

    function sweep(uint256 amount) public {
        _validate(CONFIG_OPERATOR, amount);
        _send(MAINNET_DEPLOYER, amount);
    }
}

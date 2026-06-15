// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

contract MockAToken {
    mapping(address account => uint256 balance) internal s_balances;

    function mint(address to, uint256 amount) external {
        s_balances[to] += amount;
    }

    function burn(address from, uint256 amount) external {
        s_balances[from] -= amount;
    }

    function balanceOf(address account) external view returns (uint256 balance) {
        balance = s_balances[account];
    }
}

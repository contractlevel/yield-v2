// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

contract MockYieldcoinShare {
    mapping(address => uint256) public balanceOf;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function burn(address from, uint256 amount) external {
        balanceOf[from] -= amount;
    }
}

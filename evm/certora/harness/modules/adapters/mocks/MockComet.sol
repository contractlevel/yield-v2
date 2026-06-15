// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

interface IMintableERC20 {
    function mint(address to, uint256 amount) external;
}

contract MockComet {
    mapping(address account => uint256 balance) internal s_balances;

    function supply(address, uint256 amount) external {
        s_balances[msg.sender] += amount;
    }

    function withdraw(address asset, uint256 amount) external {
        uint256 balance = s_balances[msg.sender];
        uint256 amountOut = amount == type(uint256).max ? balance : amount;

        require(amountOut <= balance);

        s_balances[msg.sender] = balance - amountOut;
        IMintableERC20(asset).mint(msg.sender, amountOut);
    }

    function balanceOf(address account) external view returns (uint256 balance) {
        balance = s_balances[account];
    }
}

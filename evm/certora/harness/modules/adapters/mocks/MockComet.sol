// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

interface IMintableERC20 {
    function mint(address to, uint256 amount) external;
}

contract MockComet {
    address internal immutable i_asset;

    mapping(address account => uint256 balance) internal s_balances;

    bool public s_decreaseTVLOnSupply;
    uint256 public s_supplyTVLChange;
    uint256 public s_withdrawAmount;

    constructor(address asset) {
        i_asset = asset;
    }

    function baseToken() external view returns (address) {
        return i_asset;
    }

    function supply(address, uint256 amount) external {
        if (s_decreaseTVLOnSupply) s_balances[msg.sender] -= s_supplyTVLChange;
        else s_balances[msg.sender] += s_supplyTVLChange;
    }

    function withdraw(address asset, uint256 amount) external {
        uint256 balance = s_balances[msg.sender];
        uint256 tvlChange = amount == type(uint256).max ? balance : amount;

        require(tvlChange <= balance);

        s_balances[msg.sender] = balance - tvlChange;
        IMintableERC20(asset).mint(msg.sender, s_withdrawAmount);
    }

    function balanceOf(address account) external view returns (uint256 balance) {
        balance = s_balances[account];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IProtocolAdapter} from "../../src/interfaces/IProtocolAdapter.sol";

contract MockProtocolAdapter is IProtocolAdapter {
    uint256 internal s_lastDepositAmount;
    uint256 internal s_lastWithdrawAmount;
    uint256 internal s_withdrawReturnAmount;
    uint256 internal s_tvl;
    uint256 internal s_depositCalls;
    uint256 internal s_withdrawCalls;
    bool internal s_useWithdrawReturnAmount;
    bool internal s_depositReverts;
    bool internal s_withdrawReverts;
    address internal s_vault;

    function deposit(uint256 amount) external override {
        if (s_depositReverts) revert("MockProtocolAdapter: deposit reverted");
        s_lastDepositAmount = amount;
        ++s_depositCalls;
    }

    function withdraw(uint256 amount) external override returns (uint256) {
        if (s_withdrawReverts) revert("MockProtocolAdapter: withdraw reverted");
        s_lastWithdrawAmount = amount;
        ++s_withdrawCalls;
        return s_useWithdrawReturnAmount ? s_withdrawReturnAmount : amount;
    }

    function getTVL() external view override returns (uint256) {
        return s_tvl;
    }

    function getProtocolPool() external pure override returns (address) {
        return address(0);
    }

    function getVault() external view override returns (address) {
        return s_vault;
    }

    function getAsset() external pure override returns (address) {
        return address(0);
    }

    function setDepositReverts(bool depositReverts) external {
        s_depositReverts = depositReverts;
    }

    function setWithdrawReverts(bool withdrawReverts) external {
        s_withdrawReverts = withdrawReverts;
    }

    function setWithdrawReturnAmount(uint256 withdrawReturnAmount) external {
        s_withdrawReturnAmount = withdrawReturnAmount;
        s_useWithdrawReturnAmount = true;
    }

    function clearWithdrawReturnAmount() external {
        s_useWithdrawReturnAmount = false;
        s_withdrawReturnAmount = 0;
    }

    function setTVL(uint256 tvl) external {
        s_tvl = tvl;
    }

    function setVault(address vault) external {
        s_vault = vault;
    }

    function getLastDepositAmount() external view returns (uint256) {
        return s_lastDepositAmount;
    }

    function getLastWithdrawAmount() external view returns (uint256) {
        return s_lastWithdrawAmount;
    }

    function getDepositCalls() external view returns (uint256) {
        return s_depositCalls;
    }

    function getWithdrawCalls() external view returns (uint256) {
        return s_withdrawCalls;
    }
}

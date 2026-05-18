// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IProtocolAdapter} from "../../src/interfaces/IProtocolAdapter.sol";

contract RevertingProtocolAdapter is IProtocolAdapter {
    address internal immutable i_vault;
    address internal immutable i_usdc;

    constructor(address vault, address usdc) {
        i_vault = vault;
        i_usdc = usdc;
    }

    function deposit(uint256) external pure {
        revert("RevertingProtocolAdapter: deposit");
    }

    function withdraw(uint256) external pure returns (uint256) {
        revert("RevertingProtocolAdapter: withdraw");
    }

    function getTVL() external pure returns (uint256 tvl) {
        return 0;
    }

    function getProtocolPool() external pure returns (address pool) {
        return address(0);
    }

    function getVault() external view returns (address vault) {
        return i_vault;
    }

    function getUsdc() external view returns (address usdc) {
        return i_usdc;
    }
}

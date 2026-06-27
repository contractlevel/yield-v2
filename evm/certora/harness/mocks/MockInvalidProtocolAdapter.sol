// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

contract MockInvalidProtocolAdapter {
    address internal immutable i_vault;

    constructor(address vault) {
        i_vault = vault;
    }

    function getVault() external view returns (address vault) {
        vault = i_vault;
    }
}

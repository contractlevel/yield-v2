// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

contract MockAaveV3PoolAddressesProvider {
    address internal immutable i_pool;

    constructor(address pool) {
        i_pool = pool;
    }

    function getPool() external view returns (address) {
        return i_pool;
    }
}

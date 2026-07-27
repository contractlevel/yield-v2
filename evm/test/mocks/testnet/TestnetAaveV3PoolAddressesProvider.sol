// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

contract TestnetAaveV3PoolAddressesProvider {
    address public immutable pool;

    constructor(address pool_) {
        pool = pool_;
    }

    function getPool() external view returns (address) {
        return pool;
    }
}

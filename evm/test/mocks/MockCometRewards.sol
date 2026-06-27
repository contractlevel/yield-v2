// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

contract MockCometRewards {
    address public lastTo;

    function claimTo(address, address, address to, bool) external {
        lastTo = to;
    }
}

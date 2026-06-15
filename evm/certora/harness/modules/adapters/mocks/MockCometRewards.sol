// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

contract MockCometRewards {
    address internal s_lastTo;

    function claimTo(address, address, address to, bool) external {
        s_lastTo = to;
    }

    function lastTo() external view returns (address) {
        return s_lastTo;
    }
}

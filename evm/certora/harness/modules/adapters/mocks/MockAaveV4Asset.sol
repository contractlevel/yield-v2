// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {MockUSDC} from "../../../mocks/MockUSDC.sol";

contract MockAaveV4Asset is MockUSDC {
    bool public s_approveZeroReverts;

    function approve(address spender, uint256 amount) external override returns (bool) {
        require(amount != 0 || !s_approveZeroReverts);
        allowance[msg.sender][spender] = amount;
        return true;
    }
}

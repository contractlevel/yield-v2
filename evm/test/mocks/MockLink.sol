// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockLink is ERC20 {
    constructor() ERC20("Mock Chainlink Token", "LINK") {}
}

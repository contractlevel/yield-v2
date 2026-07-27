// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract TestnetAToken is ERC20 {
    error TestnetAToken__OnlyPool();

    address internal immutable i_pool;
    uint8 internal immutable i_decimals;

    constructor(address asset) ERC20("Testnet Aave V3 Token", "taToken") {
        i_pool = msg.sender;
        i_decimals = IERC20Metadata(asset).decimals();
    }

    function mint(address to, uint256 amount) external {
        if (msg.sender != i_pool) revert TestnetAToken__OnlyPool();
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        if (msg.sender != i_pool) revert TestnetAToken__OnlyPool();
        _burn(from, amount);
    }

    function decimals() public view override returns (uint8) {
        return i_decimals;
    }
}

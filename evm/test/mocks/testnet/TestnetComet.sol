// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {TestnetProtocolAccess} from "./TestnetProtocolAccess.sol";
import {IComet} from "../../../src/interfaces/external/IComet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TestnetComet is TestnetProtocolAccess, IComet {
    using SafeERC20 for IERC20;

    error TestnetComet__AssetMismatch();

    address public immutable override baseToken;
    mapping(address account => uint256 amount) internal s_balances;

    constructor(address baseToken_, address initialOwner) TestnetProtocolAccess(initialOwner) {
        if (baseToken_ == address(0)) revert TestnetProtocolAccess__NoZeroAddress();
        baseToken = baseToken_;
    }

    function supply(address asset, uint256 amount) external onlyAllowedCaller {
        if (asset != baseToken) revert TestnetComet__AssetMismatch();
        IERC20(baseToken).safeTransferFrom(msg.sender, address(this), amount);
        s_balances[msg.sender] += amount;
    }

    function withdraw(address asset, uint256 amount) external onlyAllowedCaller {
        if (asset != baseToken) revert TestnetComet__AssetMismatch();

        uint256 balance = s_balances[msg.sender];
        uint256 withdrawn = amount == type(uint256).max ? balance : amount;
        s_balances[msg.sender] = balance - withdrawn;
        IERC20(baseToken).safeTransfer(msg.sender, withdrawn);
    }

    function balanceOf(address account) external view returns (uint256) {
        return s_balances[account];
    }
}

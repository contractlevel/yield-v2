// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {TestnetProtocolAccess} from "./TestnetProtocolAccess.sol";
import {TestnetAToken} from "./TestnetAToken.sol";
import {DataTypes} from "@aave/v3-origin/src/contracts/protocol/libraries/types/DataTypes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TestnetAaveV3Pool is TestnetProtocolAccess {
    using SafeERC20 for IERC20;

    error TestnetAaveV3Pool__AssetMismatch();
    error TestnetAaveV3Pool__InvalidPositionOwner();

    address public immutable asset;
    TestnetAToken public immutable aToken;

    constructor(address asset_, address initialOwner) TestnetProtocolAccess(initialOwner) {
        if (asset_ == address(0)) revert TestnetProtocolAccess__NoZeroAddress();
        asset = asset_;
        aToken = new TestnetAToken(asset_);
    }

    function supply(address asset_, uint256 amount, address onBehalfOf, uint16) external onlyAllowedCaller {
        if (asset_ != asset) revert TestnetAaveV3Pool__AssetMismatch();
        if (onBehalfOf != msg.sender) revert TestnetAaveV3Pool__InvalidPositionOwner();

        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        aToken.mint(msg.sender, amount);
    }

    function withdraw(address asset_, uint256 amount, address to)
        external
        onlyAllowedCaller
        returns (uint256 withdrawn)
    {
        if (asset_ != asset) revert TestnetAaveV3Pool__AssetMismatch();

        uint256 balance = aToken.balanceOf(msg.sender);
        withdrawn = amount == type(uint256).max ? balance : amount;
        aToken.burn(msg.sender, withdrawn);
        IERC20(asset).safeTransfer(to, withdrawn);
    }

    function getReserveData(address asset_) external view returns (DataTypes.ReserveDataLegacy memory data) {
        if (asset_ == asset) data.aTokenAddress = address(aToken);
    }
}

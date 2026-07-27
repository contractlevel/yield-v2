// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {TestnetProtocolAccess} from "./TestnetProtocolAccess.sol";
import {IAaveV4Spoke} from "../../../src/interfaces/external/IAaveV4Spoke.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TestnetAaveV4Spoke is TestnetProtocolAccess, IAaveV4Spoke {
    using SafeERC20 for IERC20;

    error TestnetAaveV4Spoke__InvalidReserve();
    error TestnetAaveV4Spoke__InvalidPositionOwner();

    uint256 internal constant RESERVE_ID = 0;

    address public immutable asset;
    Reserve internal s_reserve;
    mapping(address account => uint256 amount) internal s_suppliedAssets;

    constructor(address asset_, address initialOwner) TestnetProtocolAccess(initialOwner) {
        if (asset_ == address(0)) revert TestnetProtocolAccess__NoZeroAddress();
        asset = asset_;
        s_reserve = Reserve({
            underlying: asset_,
            hub: address(0),
            assetId: 0,
            decimals: IERC20Metadata(asset_).decimals(),
            collateralRisk: 0,
            flags: 0,
            dynamicConfigKey: 0
        });
    }

    function supply(uint256 reserveId, uint256 amount, address onBehalfOf)
        external
        onlyAllowedCaller
        returns (uint256 suppliedShares, uint256 suppliedAmount)
    {
        _validatePosition(reserveId, onBehalfOf);
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        s_suppliedAssets[msg.sender] += amount;
        return (amount, amount);
    }

    function withdraw(uint256 reserveId, uint256 amount, address onBehalfOf)
        external
        onlyAllowedCaller
        returns (uint256 withdrawnShares, uint256 withdrawnAmount)
    {
        _validatePosition(reserveId, onBehalfOf);

        uint256 balance = s_suppliedAssets[msg.sender];
        withdrawnAmount = amount >= balance ? balance : amount;
        s_suppliedAssets[msg.sender] = balance - withdrawnAmount;
        IERC20(asset).safeTransfer(msg.sender, withdrawnAmount);
        return (withdrawnAmount, withdrawnAmount);
    }

    function getUserSuppliedAssets(uint256 reserveId, address user) external view returns (uint256) {
        if (reserveId != RESERVE_ID) revert TestnetAaveV4Spoke__InvalidReserve();
        return s_suppliedAssets[user];
    }

    function getReserveCount() external pure returns (uint256) {
        return 1;
    }

    function getReserve(uint256 reserveId) external view returns (Reserve memory) {
        if (reserveId != RESERVE_ID) revert TestnetAaveV4Spoke__InvalidReserve();
        return s_reserve;
    }

    function _validatePosition(uint256 reserveId, address onBehalfOf) internal view {
        if (reserveId != RESERVE_ID) revert TestnetAaveV4Spoke__InvalidReserve();
        if (onBehalfOf != msg.sender) revert TestnetAaveV4Spoke__InvalidPositionOwner();
    }
}

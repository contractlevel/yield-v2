// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockAaveV4Spoke {
    struct Reserve {
        address underlying;
        address hub;
        uint16 assetId;
        uint8 decimals;
        uint24 collateralRisk;
        uint8 flags;
        uint32 dynamicConfigKey;
    }

    error MockAaveV4Spoke__SupplyReverts();
    error MockAaveV4Spoke__WithdrawReverts();
    error MockAaveV4Spoke__UnexpectedWithdrawAmount(uint256 actual, uint256 expected);

    address internal immutable i_underlying;
    Reserve[] internal s_reserves;
    uint256 internal s_withdrawReturn;
    uint256 internal s_expectedWithdrawAmount;
    bool internal s_supplyReverts;
    bool internal s_withdrawReverts;
    bool internal s_useExpectedWithdrawAmount;

    mapping(uint256 reserveId => mapping(address user => uint256 suppliedAssets)) internal s_suppliedAssets;

    constructor(address underlying) {
        i_underlying = underlying;
        _addReserve(underlying);
    }

    function addReserve(address underlying) external returns (uint256 reserveId) {
        reserveId = _addReserve(underlying);
    }

    function clearReserves() external {
        delete s_reserves;
    }

    function setWithdrawReturn(uint256 amount) external {
        s_withdrawReturn = amount;
        s_useExpectedWithdrawAmount = false;
    }

    function setExpectedWithdrawAmount(uint256 amount) external {
        s_expectedWithdrawAmount = amount;
        s_useExpectedWithdrawAmount = true;
    }

    function setSupplyReverts(bool supplyReverts) external {
        s_supplyReverts = supplyReverts;
    }

    function setWithdrawReverts(bool withdrawReverts) external {
        s_withdrawReverts = withdrawReverts;
    }

    function setUserSuppliedAssets(uint256 reserveId, address user, uint256 amount) external {
        s_suppliedAssets[reserveId][user] = amount;
    }

    function supply(uint256 reserveId, uint256 amount, address onBehalfOf)
        external
        returns (uint256 suppliedShares, uint256 suppliedAmount)
    {
        if (s_supplyReverts) revert MockAaveV4Spoke__SupplyReverts();
        IERC20(i_underlying).transferFrom(msg.sender, address(this), amount);
        s_suppliedAssets[reserveId][onBehalfOf] += amount;
        return (amount, amount);
    }

    function withdraw(uint256 reserveId, uint256 amount, address onBehalfOf) external returns (uint256, uint256) {
        if (s_withdrawReverts) revert MockAaveV4Spoke__WithdrawReverts();
        uint256 suppliedAssets = s_suppliedAssets[reserveId][onBehalfOf];

        if (amount == type(uint256).max) {
            if (s_useExpectedWithdrawAmount && amount != s_expectedWithdrawAmount) {
                revert MockAaveV4Spoke__UnexpectedWithdrawAmount(amount, s_expectedWithdrawAmount);
            }

            s_suppliedAssets[reserveId][onBehalfOf] = 0;
            IERC20(i_underlying).transfer(msg.sender, suppliedAssets);
            return (suppliedAssets, suppliedAssets);
        }

        uint256 amountToTransfer = s_withdrawReturn;
        if (s_useExpectedWithdrawAmount) {
            if (amount != s_expectedWithdrawAmount) {
                revert MockAaveV4Spoke__UnexpectedWithdrawAmount(amount, s_expectedWithdrawAmount);
            }
            amountToTransfer = amount;
        }

        if (amountToTransfer >= suppliedAssets) s_suppliedAssets[reserveId][onBehalfOf] = 0;
        else s_suppliedAssets[reserveId][onBehalfOf] = suppliedAssets - amountToTransfer;

        IERC20(i_underlying).transfer(msg.sender, amountToTransfer);
        return (amountToTransfer, amountToTransfer);
    }

    function getUserSuppliedAssets(uint256 reserveId, address user) external view returns (uint256) {
        return s_suppliedAssets[reserveId][user];
    }

    function getReserveCount() external view returns (uint256) {
        return s_reserves.length;
    }

    function getReserve(uint256 reserveId) external view returns (Reserve memory) {
        return s_reserves[reserveId];
    }

    function _addReserve(address underlying) internal returns (uint256 reserveId) {
        reserveId = s_reserves.length;
        s_reserves.push(
            Reserve({
                underlying: underlying,
                hub: address(0),
                assetId: uint16(reserveId),
                decimals: 6,
                collateralRisk: 0,
                flags: 0,
                dynamicConfigKey: 0
            })
        );
    }
}

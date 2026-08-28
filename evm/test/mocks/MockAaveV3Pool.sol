// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DataTypes} from "@aave/v3-origin/src/contracts/protocol/libraries/types/DataTypes.sol";
import {MockAToken} from "./MockAToken.sol";

contract MockAaveV3Pool {
    error MockAaveV3Pool__SupplyReverts(uint256 amount);
    error MockAaveV3Pool__WithdrawReverts();
    error MockAaveV3Pool__UnexpectedWithdrawAmount(uint256 actual, uint256 expected);
    error MockAaveV3Pool__NormalizedIncomeReverts(uint256 marker);
    error InvalidMintAmount();
    error InvalidAmount();

    mapping(address asset => DataTypes.ReserveDataLegacy) internal s_reserveData;
    uint256 internal s_withdrawReturn;
    uint256 internal s_expectedWithdrawAmount;
    uint256 internal s_supplyCreditAmount;
    uint256 internal s_supplyTVLDecreaseAmount;
    uint256 internal s_minimumSupplyAmount;
    uint256 internal s_normalizedIncome = 1e27;
    uint256 internal s_supplyCallCount;
    bool internal s_supplyReverts;
    bool internal s_withdrawReverts;
    bool internal s_useWithdrawReturn;
    bool internal s_useExpectedWithdrawAmount;
    bool internal s_useSupplyCreditAmount;
    bool internal s_useDeployedDustError;
    bool internal s_normalizedIncomeReverts;

    constructor(address asset) {
        s_reserveData[asset].aTokenAddress = address(new MockAToken());
    }

    function setATokenAddress(address asset, address aTokenAddress) external {
        s_reserveData[asset].aTokenAddress = aTokenAddress;
    }

    function setWithdrawReturn(uint256 amount) external {
        s_withdrawReturn = amount;
        s_useWithdrawReturn = true;
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

    function setSupplyCreditAmount(uint256 amount) external {
        s_supplyCreditAmount = amount;
        s_useSupplyCreditAmount = true;
    }

    function setSupplyTVLDecreaseAmount(uint256 amount) external {
        s_supplyTVLDecreaseAmount = amount;
    }

    function setMinimumSupplyAmount(uint256 amount) external {
        s_minimumSupplyAmount = amount;
    }

    function setUseDeployedDustError(bool useDeployedDustError) external {
        s_useDeployedDustError = useDeployedDustError;
    }

    function setNormalizedIncome(uint256 normalizedIncome) external {
        s_normalizedIncome = normalizedIncome;
    }

    function setNormalizedIncomeReverts(bool normalizedIncomeReverts) external {
        s_normalizedIncomeReverts = normalizedIncomeReverts;
    }

    function supply(address asset, uint256 amount, address onBehalfOf, uint16) external {
        ++s_supplyCallCount;
        if (s_supplyReverts) revert MockAaveV3Pool__SupplyReverts(amount);
        if (amount < s_minimumSupplyAmount) {
            if (s_useDeployedDustError) revert InvalidAmount();
            revert InvalidMintAmount();
        }
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        if (s_supplyTVLDecreaseAmount != 0) {
            MockAToken(s_reserveData[asset].aTokenAddress).burn(onBehalfOf, s_supplyTVLDecreaseAmount);
            return;
        }
        uint256 creditAmount = s_useSupplyCreditAmount ? s_supplyCreditAmount : amount;
        MockAToken(s_reserveData[asset].aTokenAddress).mint(onBehalfOf, creditAmount);
    }

    function withdraw(address asset, uint256 amount, address to) external returns (uint256) {
        if (s_withdrawReverts) revert MockAaveV3Pool__WithdrawReverts();
        address aTokenAddress = s_reserveData[asset].aTokenAddress;
        if (amount == type(uint256).max) {
            if (s_useExpectedWithdrawAmount && amount != s_expectedWithdrawAmount) {
                revert MockAaveV3Pool__UnexpectedWithdrawAmount(amount, s_expectedWithdrawAmount);
            }

            uint256 tvl = IERC20(aTokenAddress).balanceOf(msg.sender);
            MockAToken(aTokenAddress).burn(msg.sender, tvl);
            IERC20(asset).transfer(to, tvl);
            return tvl;
        }

        if (s_useExpectedWithdrawAmount) {
            if (amount != s_expectedWithdrawAmount) {
                revert MockAaveV3Pool__UnexpectedWithdrawAmount(amount, s_expectedWithdrawAmount);
            }
            MockAToken(aTokenAddress).burn(msg.sender, amount);
            IERC20(asset).transfer(to, amount);
            return amount;
        }

        uint256 returnAmount = s_useWithdrawReturn ? s_withdrawReturn : amount;
        MockAToken(aTokenAddress).burn(msg.sender, returnAmount);
        IERC20(asset).transfer(to, returnAmount);
        return returnAmount;
    }

    function getReserveData(address asset) external view returns (DataTypes.ReserveDataLegacy memory data) {
        data = s_reserveData[asset];
    }

    function getReserveNormalizedIncome(address) external view returns (uint256) {
        if (s_normalizedIncomeReverts) revert MockAaveV3Pool__NormalizedIncomeReverts(42);
        return s_normalizedIncome;
    }

    function getSupplyCallCount() external view returns (uint256) {
        return s_supplyCallCount;
    }
}

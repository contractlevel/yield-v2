// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Script} from "forge-std/Script.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IPool} from "@aave/v3-origin/src/contracts/interfaces/IPool.sol";

import {IAdapterRegistry} from "../../src/interfaces/modules/IAdapterRegistry.sol";
import {IAaveV3Adapter} from "../../src/interfaces/adapters/IAaveV3Adapter.sol";
import {IBaseVault} from "../../src/interfaces/vaults/IBaseVault.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

/// @notice Donates USDC directly to the active Ethereum Aave V3 position to offset the first management fee
contract OffsetFirstManagementFee is Script {
    using SafeERC20 for IERC20;

    error OffsetFirstManagementFee__UnsupportedChain(uint256 chainId);
    error OffsetFirstManagementFee__UnexpectedActiveAdapter(address actual, address expected);
    error OffsetFirstManagementFee__UnexpectedAsset(address actual, address expected);
    error OffsetFirstManagementFee__UnexpectedPoolAddressesProvider(address actual, address expected);
    error OffsetFirstManagementFee__ZeroTVL();
    error OffsetFirstManagementFee__InsufficientBalance(uint256 balance, uint256 required);
    error OffsetFirstManagementFee__InsufficientDonation(uint256 actualTVL, uint256 requiredTVL);

    bytes32 internal constant AAVE_V3_PROTOCOL_ID = keccak256("aave-v3");

    // ManagementFeeCollected(1, 103766076864535769), emitted by the Base ParentVault after the first rebalance.
    uint256 internal constant FIRST_MANAGEMENT_FEE_SHARES = 103_766_076_864_535_769;
    uint256 internal constant PRE_FEE_TOTAL_SHARES = 150 ether;

    function run() external returns (uint256 donationAmount) {
        if (block.chainid != 1) revert OffsetFirstManagementFee__UnsupportedChain(block.chainid);

        HelperConfig.NetworkConfig memory config = new HelperConfig().getActiveNetworkConfig();
        IBaseVault vault = IBaseVault(config.deployed.vaultProxy);
        address expectedAdapter = IAdapterRegistry(vault.getAdapterRegistry()).getAdapter(AAVE_V3_PROTOCOL_ID);
        address activeAdapter = vault.getActiveProtocolAdapter();
        if (activeAdapter != expectedAdapter) {
            revert OffsetFirstManagementFee__UnexpectedActiveAdapter(activeAdapter, expectedAdapter);
        }

        IAaveV3Adapter adapter = IAaveV3Adapter(activeAdapter);
        if (adapter.getAsset() != config.tokens.usdc) {
            revert OffsetFirstManagementFee__UnexpectedAsset(adapter.getAsset(), config.tokens.usdc);
        }
        if (adapter.getPoolAddressesProvider() != config.protocols.aaveV3PoolAddressesProvider) {
            revert OffsetFirstManagementFee__UnexpectedPoolAddressesProvider(
                adapter.getPoolAddressesProvider(), config.protocols.aaveV3PoolAddressesProvider
            );
        }

        uint256 tvl = adapter.getTVL();
        if (tvl == 0) revert OffsetFirstManagementFee__ZeroTVL();
        donationAmount = calculateDonation(tvl);

        IERC20 asset = IERC20(config.tokens.usdc);
        uint256 balance = asset.balanceOf(msg.sender);
        if (balance < donationAmount) {
            revert OffsetFirstManagementFee__InsufficientBalance(balance, donationAmount);
        }

        address pool = adapter.getProtocolPool();
        vm.startBroadcast(msg.sender);
        asset.forceApprove(pool, donationAmount);
        IPool(pool).supply(config.tokens.usdc, donationAmount, activeAdapter, 0);
        vm.stopBroadcast();

        uint256 requiredTVL = tvl + donationAmount;
        uint256 actualTVL = adapter.getTVL();
        if (actualTVL < requiredTVL) {
            revert OffsetFirstManagementFee__InsufficientDonation(actualTVL, requiredTVL);
        }
    }

    function calculateDonation(uint256 tvl) public pure returns (uint256 donationAmount) {
        // Round up to the nearest asset unit so the fee is fully offset.
        donationAmount = Math.mulDiv(tvl, FIRST_MANAGEMENT_FEE_SHARES, PRE_FEE_TOTAL_SHARES, Math.Rounding.Ceil);
    }
}

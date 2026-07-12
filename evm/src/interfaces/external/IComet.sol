// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

/// @title Compound v3 Comet Interface
/// @notice Minimal Compound v3 Comet interface used by the CompoundV3Adapter
interface IComet {
    function supply(address asset, uint256 amount) external;
    function withdraw(address asset, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function baseToken() external view returns (address);
}

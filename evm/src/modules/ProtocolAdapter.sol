// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IProtocolAdapter} from "../interfaces/IProtocolAdapter.sol";
import {IBaseVault} from "../interfaces/IBaseVault.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title Yieldcoin v2 Protocol Adapter
/// @author @contractlevel
/// @notice Base contract for protocol adapters
abstract contract ProtocolAdapter is IProtocolAdapter, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                               IMMUTABLE
    //////////////////////////////////////////////////////////////*/
    /// @dev The Yieldcoin v2 Vault on this chain
    address internal immutable i_vault;
    /// @dev The underlying asset token
    address internal immutable i_asset;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @param vault The address of the Yieldcoin v2 Vault
    /// @dev Precondition: vault must not be the zero address
    constructor(address vault) {
        _revertIfZeroAddress(vault);

        i_vault = vault;
        i_asset = IBaseVault(vault).getAsset();
    }

    /// @notice Reverts when a required address input is zero
    /// @param value The address to validate
    function _revertIfZeroAddress(address value) internal pure {
        if (value == address(0)) revert ProtocolAdapter__NoZeroAddress();
    }

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    /// @dev Precondition: Caller must be the Yieldcoin v2 Vault
    modifier onlyVault() {
        if (msg.sender != i_vault) {
            revert ProtocolAdapter__OnlyVault();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IProtocolAdapter
    function getVault() external view returns (address vault) {
        vault = i_vault;
    }

    /// @inheritdoc IProtocolAdapter
    function getAsset() external view returns (address asset) {
        asset = i_asset;
    }
}

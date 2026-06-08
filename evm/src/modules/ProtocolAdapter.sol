// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IProtocolAdapter} from "../interfaces/IProtocolAdapter.sol";
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
    /// @param asset The address of the underlying asset token
    //slither-disable-next-line missing-zero-check
    constructor(address vault, address asset) {
        i_vault = vault;
        i_asset = asset;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

/// @title Yieldcoin v2 Allowlist namespaced storage
/// @notice ERC-7201 storage owned by the Allowlist module
abstract contract AllowlistStore {
    /// @custom:storage-location erc7201:yieldcoin.storage.Allowlist
    /// @param s_allowlistEnabled Whether the allowlist is enabled.
    /// @param s_allowlistedUser Per-user allowlist status.
    struct AllowlistStorage {
        bool s_allowlistEnabled;
        mapping(address user => bool allowed) s_allowlistedUser;
    }

    // keccak256(abi.encode(uint256(keccak256("yieldcoin.storage.Allowlist")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ALLOWLIST_STORAGE_LOCATION =
        0xfd10b3d077a927ee38f8d55fa741cf68a2d6bb30b57f9d6ca973730b1c1c4300;

    function _allowlistStorage() internal pure returns (AllowlistStorage storage $) {
        //slither-disable-next-line assembly
        assembly {
            $.slot := ALLOWLIST_STORAGE_LOCATION
        }
    }
}

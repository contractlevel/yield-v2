// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

/// @title YieldcoinShareStore
/// @author @contractlevel
/// @notice Stores YieldcoinShare-specific state outside the inherited ACE token storage
contract YieldcoinShareStore {
    /// @custom:storage-location erc7201:yieldcoin.storage.YieldcoinShare
    /// @notice Namespaced storage for the YieldcoinShare token's Chainlink CCIP admin identity
    /// @param ccipAdmin The CCIP admin identity returned by getCCIPAdmin(), which may be used as part of
    ///      future Cross-Chain Token registration. Set initially by initialize() and subsequently through the
    ///      ACE-policy-protected setCCIPAdmin() function; the deployment configures setCCIPAdmin() to require
    ///      CONFIG_OPERATOR_ROLE.
    struct YieldcoinShareStorage {
        address ccipAdmin;
    }

    // keccak256(abi.encode(uint256(keccak256("yieldcoin.storage.YieldcoinShare")) - 1)) &
    // ~bytes32(uint256(0xff))
    bytes32 private constant YIELDCOIN_SHARE_STORAGE_LOCATION =
        0x41e0a3d2fe098fdb6914a7f5b701ff6b1c613a556bd3607f71a6be16b1a71800;

    /// @notice Returns the YieldcoinShare namespaced storage pointer
    /// @return $ The YieldcoinShare namespaced storage pointer
    function getYieldcoinShareStorage() internal pure returns (YieldcoinShareStorage storage $) {
        //slither-disable-next-line assembly
        assembly {
            $.slot := YIELDCOIN_SHARE_STORAGE_LOCATION
        }
    }
}

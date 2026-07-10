// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {ParentVaultStore} from "../vaults/ParentVaultStore.sol";
import {IBaseVault} from "../interfaces/IBaseVault.sol";
import {IParentVault} from "../interfaces/IParentVault.sol";

/// @title Yieldcoin v2 ParentVault config logic library
/// @author @contractlevel
/// @notice Handles ParentVault-specific config setter logic.
/// @dev Public library functions are linked by Solidity and execute by DELEGATECALL in the ParentVault context.
library ParentVaultConfigLib {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Solidity requires locally declared events for emits; these must match IParentVault and emit from the vault via DELEGATECALL.
    event TreasurySet(address indexed treasury);
    event SupportedProtocolSet(bytes32 indexed protocolId, bool indexed isSupported);

    /*//////////////////////////////////////////////////////////////
                                  CONFIG
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets the treasury address.
    /// @param $ ParentVault namespaced storage
    /// @param treasury The address of the treasury
    function setTreasury(ParentVaultStore.ParentVaultStorage storage $, address treasury) public {
        _setTreasury($, treasury);
    }

    /// @notice Sets whether a protocol is supported on any chain across the Yieldcoin v2 system.
    /// @param $ ParentVault namespaced storage
    /// @param protocolId The protocol identifier of the protocol
    /// @param isSupported Whether the protocol is supported
    function setSupportedProtocol(ParentVaultStore.ParentVaultStorage storage $, bytes32 protocolId, bool isSupported)
        public
    {
        _setSupportedProtocol($, protocolId, isSupported);
    }

    function _setTreasury(ParentVaultStore.ParentVaultStorage storage $, address treasury) internal {
        if (treasury == address(0)) revert IBaseVault.BaseVault__NoZeroAddress();
        $.s_treasury = treasury;
        emit TreasurySet(treasury);
    }

    function _setSupportedProtocol(ParentVaultStore.ParentVaultStorage storage $, bytes32 protocolId, bool isSupported)
        internal
    {
        if (protocolId == bytes32(0)) revert IParentVault.ParentVault__NoZeroProtocolId();
        if (!isSupported) {
            if (protocolId == $.s_rebalance.activeStrategy.protocolId) {
                revert IParentVault.ParentVault__CannotRemoveActiveProtocol(protocolId);
            }
            if (protocolId == $.s_rebalance.pendingStrategy.protocolId) {
                revert IParentVault.ParentVault__CannotRemovePendingProtocol(protocolId);
            }
        }
        $.s_supportedProtocol[protocolId] = isSupported;
        emit SupportedProtocolSet(protocolId, isSupported);
    }
}

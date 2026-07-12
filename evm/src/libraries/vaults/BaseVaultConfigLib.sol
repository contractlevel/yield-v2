// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseVaultStore} from "../../vaults/BaseVaultStore.sol";
import {IBaseVault} from "../../interfaces/vaults/IBaseVault.sol";

/// @title Yieldcoin v2 BaseVault config logic library
/// @author @contractlevel
/// @notice Handles shared config setter logic for BaseVault implementations.
/// @dev Public library functions are linked by Solidity and execute by DELEGATECALL in the vault context.
library BaseVaultConfigLib {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Solidity requires locally declared events for emits; these must match IBaseVault and emit from the vault via DELEGATECALL.
    event CrosschainVaultSet(uint64 indexed chainSelector, address indexed vault);
    event CcipGasLimitSet(uint64 indexed chainSelector, uint256 indexed gasLimit);
    event DefaultCcipGasLimitSet(uint256 indexed gasLimit);
    event EmergencyReceiverSet(address indexed emergencyReceiver);

    /*//////////////////////////////////////////////////////////////
                                  CONFIG
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets the crosschain vaults.
    /// @param $ BaseVault namespaced storage
    /// @param chainSelectors The CCIP selectors of the chains
    /// @param vaults The addresses of the crosschain vaults
    function setCrosschainVaults(
        BaseVaultStore.BaseVaultStorage storage $,
        uint64[] calldata chainSelectors,
        address[] calldata vaults
    ) public {
        _setCrosschainVaults($, chainSelectors, vaults);
    }

    /// @notice Sets the CCIP gas limit for a given chain selector.
    /// @param $ BaseVault namespaced storage
    /// @param chainSelector The CCIP selector of the chain
    /// @param gasLimit The CCIP gas limit
    function setCcipGasLimit(BaseVaultStore.BaseVaultStorage storage $, uint64 chainSelector, uint256 gasLimit) public {
        _setCcipGasLimit($, chainSelector, gasLimit);
    }

    /// @notice Sets the default CCIP gas limit.
    /// @param $ BaseVault namespaced storage
    /// @param gasLimit The default CCIP gas limit
    function setDefaultCcipGasLimit(BaseVaultStore.BaseVaultStorage storage $, uint256 gasLimit) public {
        _setDefaultCcipGasLimit($, gasLimit);
    }

    /// @notice Sets the emergency receiver.
    /// @param $ BaseVault namespaced storage
    /// @param emergencyReceiver The address that receives the underlying asset during emergency drain
    function setEmergencyReceiver(BaseVaultStore.BaseVaultStorage storage $, address emergencyReceiver) public {
        _setEmergencyReceiver($, emergencyReceiver);
    }

    function _setCrosschainVaults(
        BaseVaultStore.BaseVaultStorage storage $,
        uint64[] calldata chainSelectors,
        address[] calldata vaults
    ) internal {
        if (chainSelectors.length == 0) revert IBaseVault.BaseVault__EmptyInput();
        if (chainSelectors.length != vaults.length) revert IBaseVault.BaseVault__InvalidInputLengths();
        for (uint256 i; i < chainSelectors.length; ++i) {
            uint64 chainSelector = chainSelectors[i];
            if (chainSelector == 0) revert IBaseVault.BaseVault__NoZeroChainSelector();
            $.s_crosschainVaults[chainSelector] = vaults[i];
            emit CrosschainVaultSet(chainSelector, vaults[i]);
        }
    }

    function _setCcipGasLimit(BaseVaultStore.BaseVaultStorage storage $, uint64 chainSelector, uint256 gasLimit)
        internal
    {
        if (chainSelector == 0) revert IBaseVault.BaseVault__NoZeroChainSelector();
        $.s_ccipGasLimits[chainSelector] = gasLimit;
        emit CcipGasLimitSet(chainSelector, gasLimit);
    }

    function _setDefaultCcipGasLimit(BaseVaultStore.BaseVaultStorage storage $, uint256 gasLimit) internal {
        if (gasLimit == 0) revert IBaseVault.BaseVault__NoZeroAmount();
        $.s_defaultCcipGasLimit = gasLimit;
        emit DefaultCcipGasLimitSet(gasLimit);
    }

    function _setEmergencyReceiver(BaseVaultStore.BaseVaultStorage storage $, address emergencyReceiver) internal {
        if (emergencyReceiver == address(0)) revert IBaseVault.BaseVault__NoZeroAddress();
        $.s_emergencyReceiver = emergencyReceiver;
        emit EmergencyReceiverSet(emergencyReceiver);
    }
}

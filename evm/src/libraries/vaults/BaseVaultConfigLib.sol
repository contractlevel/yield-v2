// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseVaultStore} from "../../vaults/BaseVaultStore.sol";
import {IBaseVault} from "../../interfaces/vaults/IBaseVault.sol";

/// @title Yieldcoin v2 BaseVault config logic library
/// @author @contractlevel
/// @notice Handles shared configuration updates for BaseVault implementations
/// @dev Public library functions are linked by Solidity and execute by DELEGATECALL in the vault context
library BaseVaultConfigLib {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Solidity requires locally declared events for emits; these must match IBaseVault and emit from the vault via DELEGATECALL
    /// @notice Emitted when the crosschain vault for a chain selector is set or removed
    /// @param chainSelector The CCIP selector of the remote chain
    /// @param vault The registered vault address, or address(0) if the registration was removed
    event CrosschainVaultSet(uint64 indexed chainSelector, address indexed vault);
    /// @notice Emitted when a per-chain CCIP gas-limit override is set or cleared
    /// @param chainSelector The CCIP selector of the chain
    /// @param gasLimit The override, or zero if the override was cleared
    event CcipGasLimitSet(uint64 indexed chainSelector, uint256 indexed gasLimit);
    /// @notice Emitted when the default CCIP gas limit is set
    /// @param gasLimit The gas limit for the default CCIP send
    event DefaultCcipGasLimitSet(uint256 indexed gasLimit);

    /*//////////////////////////////////////////////////////////////
                                  CONFIG
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets or removes the crosschain vault registered for each supplied chain selector
    /// @param $ BaseVault namespaced storage
    /// @param chainSelectors The CCIP selectors of the remote chains
    /// @param vaults The vault addresses, using address(0) to remove a registration
    /// @dev Reverts if chainSelectors is empty
    /// @dev Reverts if chainSelectors and vaults have different lengths
    /// @dev Reverts if any chain selector is zero
    function setCrosschainVaults(
        BaseVaultStore.BaseVaultStorage storage $,
        uint64[] calldata chainSelectors,
        address[] calldata vaults
    ) public {
        _setCrosschainVaults($, chainSelectors, vaults);
    }

    /// @notice Sets or clears the CCIP gas-limit override for a chain selector
    /// @param $ BaseVault namespaced storage
    /// @param chainSelector The CCIP selector of the chain
    /// @param gasLimit The override, or zero to clear it and use the default
    /// @dev Reverts if chainSelector is zero
    function setCcipGasLimit(BaseVaultStore.BaseVaultStorage storage $, uint64 chainSelector, uint256 gasLimit) public {
        _setCcipGasLimit($, chainSelector, gasLimit);
    }

    /// @notice Sets the default CCIP gas limit
    /// @param $ BaseVault namespaced storage
    /// @param gasLimit The default CCIP gas limit
    /// @dev Reverts if gasLimit is zero
    function setDefaultCcipGasLimit(BaseVaultStore.BaseVaultStorage storage $, uint256 gasLimit) public {
        _setDefaultCcipGasLimit($, gasLimit);
    }

    /// @notice Sets or removes the crosschain vault registered for each supplied chain selector
    /// @param $ BaseVault namespaced storage
    /// @param chainSelectors The CCIP selectors of the remote chains
    /// @param vaults The vault addresses, using address(0) to remove a registration
    /// @dev Reverts if chainSelectors is empty
    /// @dev Reverts if chainSelectors and vaults have different lengths
    /// @dev Reverts if any chain selector is zero
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

    /// @notice Sets or clears the CCIP gas-limit override for a chain selector
    /// @param $ BaseVault namespaced storage
    /// @param chainSelector The CCIP selector of the chain
    /// @param gasLimit The override, or zero to clear it and use the default
    /// @dev Reverts if chainSelector is zero
    function _setCcipGasLimit(BaseVaultStore.BaseVaultStorage storage $, uint64 chainSelector, uint256 gasLimit)
        internal
    {
        if (chainSelector == 0) revert IBaseVault.BaseVault__NoZeroChainSelector();
        $.s_ccipGasLimits[chainSelector] = gasLimit;
        emit CcipGasLimitSet(chainSelector, gasLimit);
    }

    /// @notice Sets the default CCIP gas limit
    /// @param $ BaseVault namespaced storage
    /// @param gasLimit The default CCIP gas limit
    /// @dev Reverts if gasLimit is zero
    function _setDefaultCcipGasLimit(BaseVaultStore.BaseVaultStorage storage $, uint256 gasLimit) internal {
        if (gasLimit == 0) revert IBaseVault.BaseVault__NoZeroAmount();
        $.s_defaultCcipGasLimit = gasLimit;
        emit DefaultCcipGasLimitSet(gasLimit);
    }
}

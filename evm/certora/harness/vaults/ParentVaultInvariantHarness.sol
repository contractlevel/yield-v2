// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {ParentVault} from "../../../src/vaults/ParentVault.sol";
import {BaseVault} from "../../../src/vaults/BaseVault.sol";
import {BaseVaultCcipLib} from "../../../src/libraries/vaults/BaseVaultCcipLib.sol";
import {BaseVaultStrategyLib} from "../../../src/libraries/vaults/BaseVaultStrategyLib.sol";
import {ParentVaultRebalanceLib} from "../../../src/libraries/vaults/ParentVaultRebalanceLib.sol";
import {Types} from "../../../src/libraries/Types.sol";

/// @notice Production-ABI ParentVault target for invariant verification.
/// @dev Certora cannot resolve selected public library delegatecalls in ParentVault. This target
///      adds no external methods and overrides only those internal call boundaries to invoke each
///      library's equivalent internal implementation.
contract ParentVaultInvariantHarness is ParentVault {
    constructor(BaseVault.ConstructorParams memory params, address share) ParentVault(params, share) {}

    function _onlyAllowedSender(address sender, uint64 srcChainSelector) internal view override {
        BaseVaultCcipLib._onlyAllowedSender(_baseVaultStorage(), sender, srcChainSelector);
    }

    function _setActiveAdapter(bytes32 protocolId) internal override returns (address adapter) {
        adapter = BaseVaultStrategyLib._setActiveAdapter(
            _baseVaultStorage(), protocolId, i_adapterRegistry, address(this)
        );
    }

    function _clearActiveAdapter(address adapter) internal override {
        BaseVaultStrategyLib._clearActiveAdapter(_baseVaultStorage(), adapter);
    }

    function _finalizeRebalance(uint256 rebalanceNonce, Types.Strategy memory newStrategy) internal override {
        ParentVaultRebalanceLib._finalizeRebalance(
            _parentVaultStorage(), i_share, rebalanceNonce, newStrategy, false
        );
    }

    function _finalizeLocalToLocalRebalance(uint256 rebalanceNonce, Types.Strategy memory newStrategy)
        internal
        override
    {
        ParentVaultRebalanceLib._finalizeRebalance(
            _parentVaultStorage(), i_share, rebalanceNonce, newStrategy, true
        );
    }
}

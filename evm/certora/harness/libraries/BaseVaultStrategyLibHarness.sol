// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperHarness} from "../HelperHarness.sol";
import {BaseVaultStore} from "../../../src/vaults/BaseVaultStore.sol";
import {BaseVaultStrategyLib} from "../../../src/libraries/BaseVaultStrategyLib.sol";

contract BaseVaultStrategyLibHarness is BaseVaultStore, HelperHarness {
    address internal immutable i_adapterRegistry;

    constructor(address adapterRegistry) {
        i_adapterRegistry = adapterRegistry;
    }

    function getActiveProtocolAdapter() external view returns (address activeProtocolAdapter) {
        activeProtocolAdapter = _baseVaultStorage().s_activeProtocolAdapter;
    }

    function setActiveAdapter(bytes32 protocolId) external returns (address adapter) {
        adapter = BaseVaultStrategyLib._setActiveAdapter(
            _baseVaultStorage(), protocolId, i_adapterRegistry, address(this)
        );
    }

    function clearActiveAdapter() external {
        BaseVaultStrategyLib._clearActiveAdapter(_baseVaultStorage());
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperHarness} from "../HelperHarness.sol";
import {ParentVaultStore} from "../../../src/vaults/ParentVaultStore.sol";
import {ParentVaultConfigLib} from "../../../src/libraries/vaults/ParentVaultConfigLib.sol";

contract ParentVaultConfigLibHarness is ParentVaultStore, HelperHarness {
    function getTreasury() external view returns (address) {
        return _parentVaultStorage().s_treasury;
    }

    function getSupportedProtocol(bytes32 protocolId) external view returns (bool) {
        return _parentVaultStorage().s_supportedProtocol[protocolId];
    }

    function getActiveStrategyProtocolId() external view returns (bytes32) {
        return _parentVaultStorage().s_rebalance.activeStrategy.protocolId;
    }

    function getPendingStrategyProtocolId() external view returns (bytes32) {
        return _parentVaultStorage().s_rebalance.pendingStrategy.protocolId;
    }

    function setTreasury(address treasury) external {
        ParentVaultConfigLib._setTreasury(_parentVaultStorage(), treasury);
    }

    function setSupportedProtocol(bytes32 protocolId, bool isSupported) external {
        ParentVaultConfigLib._setSupportedProtocol(_parentVaultStorage(), protocolId, isSupported);
    }
}

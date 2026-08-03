// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperHarness} from "../HelperHarness.sol";
import {BaseVaultStore} from "../../../src/vaults/BaseVaultStore.sol";
import {BaseVaultConfigLib} from "../../../src/libraries/vaults/BaseVaultConfigLib.sol";

contract BaseVaultConfigLibHarness is BaseVaultStore, HelperHarness {
    function getCrosschainVault(uint64 chainSelector) external view returns (address) {
        return _baseVaultStorage().s_crosschainVaults[chainSelector];
    }

    function getCcipGasLimit(uint64 chainSelector) external view returns (uint256) {
        return _baseVaultStorage().s_ccipGasLimits[chainSelector];
    }

    function getDefaultCcipGasLimit() external view returns (uint256) {
        return _baseVaultStorage().s_defaultCcipGasLimit;
    }

    function setCrosschainVaults(uint64[] calldata chainSelectors, address[] calldata vaults) external {
        BaseVaultConfigLib._setCrosschainVaults(_baseVaultStorage(), chainSelectors, vaults);
    }

    function setCcipGasLimit(uint64 chainSelector, uint256 gasLimit) external {
        BaseVaultConfigLib._setCcipGasLimit(_baseVaultStorage(), chainSelector, gasLimit);
    }

    function setDefaultCcipGasLimit(uint256 gasLimit) external {
        BaseVaultConfigLib._setDefaultCcipGasLimit(_baseVaultStorage(), gasLimit);
    }
}

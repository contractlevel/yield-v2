// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperHarness} from "../HelperHarness.sol";
import {ParentVaultStore} from "../../../src/vaults/ParentVaultStore.sol";
import {ParentVaultFeesLib} from "../../../src/libraries/vaults/ParentVaultFeesLib.sol";

contract ParentVaultFeesLibHarness is ParentVaultStore, HelperHarness {
    address internal immutable i_share;

    constructor(address share) {
        i_share = share;
    }

    function collectManagementFee(uint256 rebalanceNonce, uint256 lastRebalanceCompletedTimestamp) external {
        ParentVaultFeesLib._collectManagementFee(
            _parentVaultStorage(), rebalanceNonce, lastRebalanceCompletedTimestamp, i_share
        );
    }

    function getTotalShares() external view returns (uint256 totalShares) {
        totalShares = _parentVaultStorage().s_totalShares;
    }

    function getTreasury() external view returns (address treasury) {
        treasury = _parentVaultStorage().s_treasury;
    }
}

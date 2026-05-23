// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseSetup} from "@chimera/BaseSetup.sol";
import {BaseIntegrationTest} from "../../integration/BaseIntegrationTest.t.sol";

abstract contract Setup is BaseSetup, BaseIntegrationTest {
    bytes32 internal constant CLOSE_EPOCH_WORKFLOW_ID = keccak256("invariant-close-epoch");
    bytes10 internal constant CLOSE_EPOCH_WORKFLOW_NAME = bytes10("closeEpoch");

    uint256 internal constant MAX_DEPOSIT_AMOUNT = 1_000_000 * 1e6;

    function setup() internal virtual override {
        super.setUp();

        _deployLocalParentTwoChildTopology();
        _configureCloseEpochWorkflow(parent.workflowRouter, CLOSE_EPOCH_WORKFLOW_ID, CLOSE_EPOCH_WORKFLOW_NAME, i_owner);
        _setDefaultCcipGasLimits();

        _setupInvariantActors();
    }

    function _setupInvariantActors() internal virtual {}

    function _boundToRange(uint256 value, uint256 min, uint256 max) internal pure returns (uint256) {
        if (value < min || value > max) return min + (value % (max - min + 1));
        return value;
    }
}

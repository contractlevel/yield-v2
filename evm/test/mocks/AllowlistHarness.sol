// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Allowlist} from "../../src/modules/Allowlist.sol";
import {Roles} from "../../src/libraries/Roles.sol";

/// @notice Exposes internal validation solely for module unit tests.
contract AllowlistHarness is Allowlist {
    constructor(address admin, address operator) initializer {
        __AccessControlDefaultAdminRules_init(0, admin);
        _grantRole(Roles.ALLOWLIST_OPERATOR_ROLE, operator);
    }

    function validate(address user) external view {
        _validateAllowlist(user);
    }

    function validate(address caller, address beneficiary) external view {
        _validateAllowlist(caller, beneficiary);
    }
}

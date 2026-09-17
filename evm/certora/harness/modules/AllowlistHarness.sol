// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperHarness} from "../HelperHarness.sol";

import {Allowlist} from "../../../src/modules/Allowlist.sol";
import {Roles} from "../../../src/libraries/Roles.sol";

contract AllowlistHarness is Allowlist, HelperHarness {
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

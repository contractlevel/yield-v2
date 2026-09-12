// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {
    AccessControlDefaultAdminRulesUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlDefaultAdminRulesUpgradeable.sol";
import {AllowlistStore} from "./AllowlistStore.sol";
import {Roles} from "../libraries/Roles.sol";

/// @title Yieldcoin v2 Allowlist
/// @notice Optional address allowlist enforced by inheriting contracts at their entry points
abstract contract Allowlist is AllowlistStore, AccessControlDefaultAdminRulesUpgradeable {
    error Allowlist__UserNotAllowlisted(address user);

    event AllowlistEnabledSet(bool indexed enabled);
    event AllowlistedUserSet(address indexed user, bool indexed allowed);

    /// @notice Enables or disables enforcement without clearing membership
    function setAllowlistEnabled(bool enabled) external onlyRole(Roles.ALLOWLIST_OPERATOR_ROLE) {
        _setAllowlistEnabled(enabled);
    }

    /// @notice Sets the same membership status for every supplied user
    function setAllowlistedUsers(address[] calldata users, bool allowed)
        external
        onlyRole(Roles.ALLOWLIST_OPERATOR_ROLE)
    {
        AllowlistStorage storage $ = _allowlistStorage();
        for (uint256 i; i < users.length; ++i) {
            $.s_allowlistedUser[users[i]] = allowed;
            emit AllowlistedUserSet(users[i], allowed);
        }
    }

    function getAllowlistEnabled() external view returns (bool allowlistEnabled) {
        allowlistEnabled = _allowlistStorage().s_allowlistEnabled;
    }

    /// @notice Returns stored membership, regardless of whether enforcement is enabled
    function getAllowlistedUser(address user) external view returns (bool allowlisted) {
        allowlisted = _allowlistStorage().s_allowlistedUser[user];
    }

    function _setAllowlistEnabled(bool enabled) internal {
        _allowlistStorage().s_allowlistEnabled = enabled;
        emit AllowlistEnabledSet(enabled);
    }

    function _validateAllowlist(address user) internal view {
        AllowlistStorage storage $ = _allowlistStorage();
        if ($.s_allowlistEnabled) if (!$.s_allowlistedUser[user]) revert Allowlist__UserNotAllowlisted(user);
    }

    function _validateAllowlist(address caller, address beneficiary) internal view {
        AllowlistStorage storage $ = _allowlistStorage();
        if ($.s_allowlistEnabled) {
            if (!$.s_allowlistedUser[caller]) revert Allowlist__UserNotAllowlisted(caller);
            if (beneficiary != caller && !$.s_allowlistedUser[beneficiary]) revert Allowlist__UserNotAllowlisted(beneficiary);
        }
    }
}

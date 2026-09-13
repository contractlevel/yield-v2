// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {
    AccessControlDefaultAdminRulesUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlDefaultAdminRulesUpgradeable.sol";

import {IAllowlist} from "../interfaces/modules/IAllowlist.sol";
import {AllowlistStore} from "./AllowlistStore.sol";
import {Roles} from "../libraries/Roles.sol";

/// @title Yieldcoin v2 Allowlist
/// @author @contractlevel
/// @notice Optional address allowlist enforced by inheriting contracts at their entry points
abstract contract Allowlist is IAllowlist, AllowlistStore, AccessControlDefaultAdminRulesUpgradeable {
    /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Enables or disables enforcement without clearing membership
    /// @param enabled Whether to enforce allowlist membership
    /// @dev Reverts if the caller does not have ALLOWLIST_OPERATOR_ROLE
    /// @dev Emits AllowlistEnabledSet even if enforcement is unchanged
    function setAllowlistEnabled(bool enabled) external onlyRole(Roles.ALLOWLIST_OPERATOR_ROLE) {
        _setAllowlistEnabled(enabled);
    }

    /// @notice Sets the same membership status for every supplied user
    /// @param users The addresses whose membership status is updated
    /// @param allowed Whether the users are allowlisted
    /// @dev Reverts if the caller does not have ALLOWLIST_OPERATOR_ROLE
    /// @dev Accepts an empty array, duplicate users, and the zero address
    /// @dev Emits AllowlistedUserSet for every supplied user, even if membership is unchanged
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

    /*//////////////////////////////////////////////////////////////
                            INTERNAL SETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Enables or disables enforcement without clearing membership
    /// @param enabled Whether to enforce allowlist membership
    /// @dev Does not perform access control; authorization is the responsibility of the caller
    /// @dev Emits AllowlistEnabledSet even if enforcement is unchanged
    function _setAllowlistEnabled(bool enabled) internal {
        _allowlistStorage().s_allowlistEnabled = enabled;
        emit AllowlistEnabledSet(enabled);
    }

    /*//////////////////////////////////////////////////////////////
                          ALLOWLIST VALIDATION
    //////////////////////////////////////////////////////////////*/
    /// @notice Validates a user's allowlist membership when enforcement is enabled
    /// @param user The address to validate
    /// @dev Reverts if enforcement is enabled and user is not allowlisted
    /// @dev Skips validation when enforcement is disabled
    function _validateAllowlist(address user) internal view {
        AllowlistStorage storage $ = _allowlistStorage();
        if ($.s_allowlistEnabled) if (!$.s_allowlistedUser[user]) revert Allowlist__UserNotAllowlisted(user);
    }

    /// @notice Validates caller and beneficiary membership when enforcement is enabled
    /// @param caller The address initiating the operation
    /// @param beneficiary The address benefiting from the operation
    /// @dev Reverts if enforcement is enabled and caller is not allowlisted
    /// @dev Reverts if enforcement is enabled and a distinct beneficiary is not allowlisted
    /// @dev Skips validation when enforcement is disabled; checks identical addresses only once
    function _validateAllowlist(address caller, address beneficiary) internal view {
        AllowlistStorage storage $ = _allowlistStorage();
        if ($.s_allowlistEnabled) {
            if (!$.s_allowlistedUser[caller]) revert Allowlist__UserNotAllowlisted(caller);
            if (beneficiary != caller && !$.s_allowlistedUser[beneficiary]) {
                revert Allowlist__UserNotAllowlisted(beneficiary);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns whether allowlist enforcement is enabled
    /// @return allowlistEnabled Whether allowlist membership is enforced
    function getAllowlistEnabled() external view returns (bool allowlistEnabled) {
        allowlistEnabled = _allowlistStorage().s_allowlistEnabled;
    }

    /// @notice Returns stored membership, regardless of whether enforcement is enabled
    /// @param user The address whose membership status is queried
    /// @return allowlisted Whether the user is stored as allowlisted
    function getAllowlistedUser(address user) external view returns (bool allowlisted) {
        allowlisted = _allowlistStorage().s_allowlistedUser[user];
    }
}

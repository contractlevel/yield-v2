// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

/// @title Yieldcoin v2 Allowlist Interface
/// @author @contractlevel
/// @notice Interface for optional address allowlist enforcement
interface IAllowlist {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @dev Thrown when enforcement is enabled and a required user is not allowlisted
    /// @param user The address that failed the membership check
    error Allowlist__UserNotAllowlisted(address user);

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when allowlist enforcement is set
    /// @param enabled Whether allowlist membership is enforced
    event AllowlistEnabledSet(bool indexed enabled);

    /// @notice Emitted when a user's allowlist membership is set
    /// @param user The address whose membership status was set
    /// @param allowed Whether the user is allowlisted
    event AllowlistedUserSet(address indexed user, bool indexed allowed);

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Enables or disables enforcement without clearing membership
    /// @param enabled Whether to enforce allowlist membership
    /// @dev Reverts if the caller does not have ALLOWLIST_OPERATOR_ROLE
    /// @dev Emits AllowlistEnabledSet even if enforcement is unchanged
    function setAllowlistEnabled(bool enabled) external;

    /// @notice Sets the same membership status for every supplied user
    /// @param users The addresses whose membership status is updated
    /// @param allowed Whether the users are allowlisted
    /// @dev Reverts if the caller does not have ALLOWLIST_OPERATOR_ROLE
    /// @dev Accepts an empty array, duplicate users, and the zero address
    /// @dev Emits AllowlistedUserSet for every supplied user, even if membership is unchanged
    function setAllowlistedUsers(address[] calldata users, bool allowed) external;

    /// @notice Returns whether allowlist enforcement is enabled
    /// @return allowlistEnabled Whether allowlist membership is enforced
    function getAllowlistEnabled() external view returns (bool allowlistEnabled);

    /// @notice Returns stored membership, regardless of whether enforcement is enabled
    /// @param user The address whose membership status is queried
    /// @return allowlisted Whether the user is stored as allowlisted
    function getAllowlistedUser(address user) external view returns (bool allowlisted);
}

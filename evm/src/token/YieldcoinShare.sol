// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IShare} from "../interfaces/token/IShare.sol";
import {Roles} from "../libraries/Roles.sol";
import {YieldcoinShareStore} from "./YieldcoinShareStore.sol";

import {
    AccessControlDefaultAdminRulesUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlDefaultAdminRulesUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {
    ReentrancyGuardTransientUpgradeable
} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardTransientUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title Yieldcoin v2 Share Token
/// @author @contractlevel
/// @notice Upgradeable ERC20 token representing shares in Yieldcoin v2
/// @dev Minting and burning are restricted to their respective roles
/// @dev Pausing disables transfers, minting, and burning while leaving approvals available
contract YieldcoinShare is
    IShare,
    YieldcoinShareStore,
    ERC20Upgradeable,
    PausableUpgradeable,
    AccessControlDefaultAdminRulesUpgradeable,
    ReentrancyGuardTransientUpgradeable,
    UUPSUpgradeable
{
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Initial delay for transferring the default admin role
    uint48 internal constant INITIAL_DEFAULT_ADMIN_ROLE_TRANSFER_DELAY = 0;

    /*//////////////////////////////////////////////////////////////
                              IMMUTABLE
    //////////////////////////////////////////////////////////////*/
    /// @dev ParentVault
    address internal immutable i_parentVault;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Validates that caller is the ParentVault
    /// @dev Reverts if caller is not the ParentVault
    modifier onlyParentVault() {
        _onlyParentVault();
        _;
    }

    /// @notice Validates that caller is the ParentVault
    /// @dev Reverts if caller is not the ParentVault
    function _onlyParentVault() internal view {
        if (msg.sender != i_parentVault) revert YieldcoinShare__OnlyParentVault();
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @notice Disables initialization of the implementation contract
    /// @param parentVault The address of the ParentVault (proxy)
    /// @dev Reverts if parentVault is the zero address
    /// @dev The proxy must be initialized through `initialize`
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address parentVault) {
        _revertIfZeroAddress(parentVault);
        i_parentVault = parentVault;
        _disableInitializers();
    }

    /// @notice Initializes the token, CCIP admin, and role-based access control
    /// @param defaultAdmin The initial default admin
    /// @param pauser The address authorized to pause the token
    /// @param unpauser The address authorized to unpause the token
    /// @param configOperator The address authorized to update token configuration
    /// @param initialCcipAdmin The initial Chainlink CCIP token administrator
    /// @param upgrader The address authorized to upgrade the token implementation
    /// @dev Reverts if any address parameter is the zero address
    /// @dev Reverts if the call is reentered
    /// @dev Sets the token name to Yieldcoin, symbol to YIELD, and decimals to 18
    function initialize(
        address defaultAdmin,
        address pauser,
        address unpauser,
        address configOperator,
        address initialCcipAdmin,
        address upgrader
    ) external nonReentrant initializer {
        _revertIfZeroAddress(defaultAdmin);
        _revertIfZeroAddress(pauser);
        _revertIfZeroAddress(unpauser);
        _revertIfZeroAddress(configOperator);
        _revertIfZeroAddress(initialCcipAdmin);
        _revertIfZeroAddress(upgrader);

        __ERC20_init("Yieldcoin", "YIELD");
        __Pausable_init();
        __AccessControlDefaultAdminRules_init(INITIAL_DEFAULT_ADMIN_ROLE_TRANSFER_DELAY, defaultAdmin);
        __ReentrancyGuardTransient_init();
        __UUPSUpgradeable_init();

        _grantRole(Roles.PAUSER_ROLE, pauser);
        _grantRole(Roles.UNPAUSER_ROLE, unpauser);
        _grantRole(Roles.CONFIG_OPERATOR_ROLE, configOperator);
        _grantRole(Roles.UPGRADER_ROLE, upgrader);
        _setCCIPAdmin(initialCcipAdmin);
    }

    /// @notice Validates that a required address is nonzero
    /// @param value The address to validate
    /// @dev Reverts if value is the zero address
    function _revertIfZeroAddress(address value) internal pure {
        if (value == address(0)) revert YieldcoinShare__NoZeroAddress();
    }

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Mints shares to an address
    /// @param to The address to mint shares to
    /// @param amount The amount of shares to mint
    /// @dev Reverts if the caller is not the ParentVault
    /// @dev Reverts if to is the zero address
    /// @dev Reverts if the token is paused
    function mint(address to, uint256 amount) external onlyParentVault {
        _mint(to, amount);
    }

    /// @notice Burns shares from an address
    /// @param user The address to burn shares from
    /// @param amount The amount of shares to burn
    /// @dev Reverts if the caller is not the ParentVault
    /// @dev Reverts if user is the zero address
    /// @dev Reverts if amount exceeds the user's share balance
    /// @dev Reverts if the token is paused
    function burn(address user, uint256 amount) external onlyParentVault {
        _burn(user, amount);
    }

    /// @notice Pauses transfers, minting, and burning
    /// @dev Reverts if the caller does not have PAUSER_ROLE
    /// @dev Reverts if the token is already paused
    function pause() external onlyRole(Roles.PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpauses transfers, minting, and burning
    /// @dev Reverts if the caller does not have UNPAUSER_ROLE
    /// @dev Reverts if the token is not paused
    function unpause() external onlyRole(Roles.UNPAUSER_ROLE) {
        _unpause();
    }

    /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets the Chainlink CCIP token admin identity
    /// @param newAdmin The new CCIP admin
    /// @dev Reverts if the caller does not have CONFIG_OPERATOR_ROLE
    /// @dev Reverts if newAdmin is the zero address
    function setCCIPAdmin(address newAdmin) external onlyRole(Roles.CONFIG_OPERATOR_ROLE) {
        _setCCIPAdmin(newAdmin);
    }

    /// @notice Updates the Chainlink CCIP token administrator
    /// @param newAdmin The new CCIP token administrator
    /// @dev Reverts if newAdmin is the zero address
    function _setCCIPAdmin(address newAdmin) internal {
        _revertIfZeroAddress(newAdmin);

        YieldcoinShareStorage storage $ = _yieldcoinShareStorage();
        address previousAdmin = $.ccipAdmin;
        $.ccipAdmin = newAdmin;
        emit CCIPAdminTransferred(previousAdmin, newAdmin);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns the Chainlink CCIP token admin identity
    /// @return ccipAdmin The stored CCIP admin
    function getCCIPAdmin() external view returns (address ccipAdmin) {
        ccipAdmin = _yieldcoinShareStorage().ccipAdmin;
    }

    /*//////////////////////////////////////////////////////////////
                                OVERRIDE
    //////////////////////////////////////////////////////////////*/
    /// @notice Authorizes a UUPS implementation upgrade
    /// @dev Reverts if the caller does not have UPGRADER_ROLE
    function _authorizeUpgrade(address) internal override onlyRole(Roles.UPGRADER_ROLE) {}

    /// @notice Applies ERC20 balance and supply updates while the token is unpaused
    /// @dev Covers transfers, minting, and burning
    function _update(address from, address to, uint256 value) internal override whenNotPaused {
        super._update(from, to, value);
    }
}

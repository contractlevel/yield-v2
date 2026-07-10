// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {ComplianceTokenERC3643} from "@chainlink/tokens/erc-3643/src/ComplianceTokenERC3643.sol";
import {YieldcoinShareStore} from "./YieldcoinShareStore.sol";

import {
    ReentrancyGuardTransientUpgradeable
} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardTransientUpgradeable.sol";

/// @title YieldcoinShare
/// @author @contractlevel
/// @notice YieldcoinShare is the compliance-ready share token of the Yieldcoin v2 system.
contract YieldcoinShare is ComplianceTokenERC3643, YieldcoinShareStore, ReentrancyGuardTransientUpgradeable {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @dev Thrown when the zero address is provided for required configuration
    error YieldcoinShare__NoZeroAddress();
    /// @dev Thrown to permanently prevent renouncing ownership, which would irrecoverably disable UUPS upgrades
    error YieldcoinShare__CannotRenounceOwnership();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when the CCIP token admin identity changes
    /// @param previousAdmin The previous CCIP admin
    /// @param newAdmin The new CCIP admin
    event CCIPAdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                               INITIALIZE
    //////////////////////////////////////////////////////////////*/
    /// @param policyEngine Chainlink ACE PolicyEngine component
    /// @param initialCcipAdmin Initial address for CCIP admin
    /// @param upgrader Address authorized to upgrade this contract via UUPS (set as OZ owner)
    /// @dev Precondition: initialCcipAdmin must not be the zero address
    /// @dev Precondition: upgrader must not be the zero address
    function initialize(address policyEngine, address initialCcipAdmin, address upgrader)
        external
        nonReentrant
        initializer
    {
        if (upgrader == address(0)) revert YieldcoinShare__NoZeroAddress();
        _validatePolicyEngine(policyEngine);
        __ComplianceTokenERC3643_init("Yieldcoin", "YIELD", 18, policyEngine);
        _setCCIPAdmin(initialCcipAdmin);
        _transferOwnership(upgrader);
    }

    /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets the Chainlink CCIP token admin identity
    /// @param newAdmin The new CCIP admin
    /// @dev This function is protected by Chainlink ACE RoleBasedAccessControlPolicy authorization
    ///      The deploy script should gate access to this function to the CONFIG_OPERATOR_ROLE.
    /// @dev Precondition: newAdmin must not be the zero address
    function setCCIPAdmin(address newAdmin) external runPolicy {
        _setCCIPAdmin(newAdmin);
    }

    function _setCCIPAdmin(address newAdmin) internal {
        if (newAdmin == address(0)) revert YieldcoinShare__NoZeroAddress();

        YieldcoinShareStorage storage $ = getYieldcoinShareStorage();
        address previousAdmin = $.ccipAdmin;
        $.ccipAdmin = newAdmin;
        emit CCIPAdminTransferred(previousAdmin, newAdmin);
    }

    /// @notice Attaches a policy engine through ACE policy authorization
    /// @param policyEngine The new policy engine
    /// @dev This function is protected by Chainlink ACE RoleBasedAccessControlPolicy authorization
    ///      The deploy script should gate access to this function to the POLICY_ENGINE_MANAGER_ROLE.
    function attachPolicyEngine(address policyEngine) external override runPolicy {
        _validatePolicyEngine(policyEngine);
        _attachPolicyEngine(policyEngine);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Gets the Chainlink CCIP token admin identity
    /// @return ccipAdmin The stored CCIP admin
    function getCCIPAdmin() public view override returns (address ccipAdmin) {
        ccipAdmin = getYieldcoinShareStorage().ccipAdmin;
    }

    /*//////////////////////////////////////////////////////////////
                                OVERRIDE
    //////////////////////////////////////////////////////////////*/
    /// @dev Disabled: renouncing ownership would irrecoverably remove upgrade authority.
    ///      Use transferOwnership to rotate the upgrader key instead.
    ///
    /// @dev WARNING: transferOwnership (inherited from OwnableUpgradeable) is a single-step transfer
    ///      with no confirmation from the new owner. Sending to an incorrect or uncontrolled address
    ///      permanently removes upgrade capability with no recovery path. Rotate keys with extreme care.
    function renounceOwnership() public pure override {
        revert YieldcoinShare__CannotRenounceOwnership();
    }
}

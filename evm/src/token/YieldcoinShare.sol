// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {ComplianceTokenERC3643} from "@chainlink/tokens/erc-3643/src/ComplianceTokenERC3643.sol";
import {YieldcoinShareStore} from "./YieldcoinShareStore.sol";

import {
    ReentrancyGuardTransientUpgradeable
} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardTransientUpgradeable.sol";

/// @title YieldcoinShare
/// @author @contractlevel
/// @notice Compliance-ready share token for the Yieldcoin v2 system
/// @dev Does not inherit IShare because not all required ComplianceTokenERC3643 functions can be overridden to
///      resolve the interface inheritance
//slither-disable-next-line missing-inheritance
contract YieldcoinShare is ComplianceTokenERC3643, YieldcoinShareStore, ReentrancyGuardTransientUpgradeable {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @dev Thrown when the zero address is provided for required configuration
    error YieldcoinShare__NoZeroAddress();
    /// @dev Thrown to permanently prevent renouncing ownership, which would irrecoverably disable UUPS upgrades
    error YieldcoinShare__CannotRenounceOwnership();
    /// @dev Thrown when the inherited ComplianceTokenERC3643 initializer is called; YieldcoinShare
    ///      must only be initialized through its own initialize(address,address,address)
    error YieldcoinShare__InvalidInitialize();

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
    /// @notice Disables initialization of the implementation contract
    /// @dev The token must be initialized through a proxy
    constructor() {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                               INITIALIZE
    //////////////////////////////////////////////////////////////*/
    /// @notice Initializes the YieldcoinShare token and sets the initial CCIP admin and UUPS upgrader
    /// @param policyEngine The Chainlink ACE PolicyEngine
    /// @param initialCcipAdmin The initial Chainlink CCIP token admin identity
    /// @param upgrader The address authorized to upgrade this contract through UUPS
    /// @dev Reverts if policyEngine is the zero address
    /// @dev Reverts if initialCcipAdmin is the zero address
    /// @dev Reverts if upgrader is the zero address
    /// @dev Reverts if the proxy is already initialized
    /// @dev Reverts if the function is called on the implementation contract
    /// @dev Reverts if the call is reentered
    /// @dev Reverts if attaching policyEngine fails
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
    /// @dev Reverts if the call is rejected by the attached ACE policies
    /// @dev Reverts if newAdmin is the zero address
    /// @dev The deployment configures RoleBasedAccessControlPolicy to require CONFIG_OPERATOR_ROLE
    function setCCIPAdmin(address newAdmin) external runPolicy {
        _setCCIPAdmin(newAdmin);
    }

    /// @notice Sets the stored CCIP admin and emits CCIPAdminTransferred
    /// @param newAdmin The new CCIP admin
    /// @dev Reverts if newAdmin is the zero address
    function _setCCIPAdmin(address newAdmin) internal {
        if (newAdmin == address(0)) revert YieldcoinShare__NoZeroAddress();

        YieldcoinShareStorage storage $ = getYieldcoinShareStorage();
        address previousAdmin = $.ccipAdmin;
        $.ccipAdmin = newAdmin;
        emit CCIPAdminTransferred(previousAdmin, newAdmin);
    }

    /// @notice Attaches a policy engine through ACE policy authorization
    /// @param policyEngine The new policy engine
    /// @dev Reverts if the call is rejected by the currently attached ACE policies
    /// @dev Reverts if policyEngine is the zero address
    /// @dev Reverts if attaching the new policy engine fails
    /// @dev Failure to detach the previous policy engine does not revert; the inherited implementation emits
    ///      PolicyEngineDetachFailed instead
    /// @dev The deployment configures RoleBasedAccessControlPolicy to require POLICY_ENGINE_MANAGER_ROLE
    function attachPolicyEngine(address policyEngine) external override runPolicy {
        _validatePolicyEngine(policyEngine);
        _attachPolicyEngine(policyEngine);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns the Chainlink CCIP token admin identity
    /// @return ccipAdmin The stored CCIP admin
    function getCCIPAdmin() public view override returns (address ccipAdmin) {
        ccipAdmin = getYieldcoinShareStorage().ccipAdmin;
    }

    /*//////////////////////////////////////////////////////////////
                                OVERRIDE
    //////////////////////////////////////////////////////////////*/
    /// @notice Prevents the UUPS upgrader from renouncing ownership
    /// @dev Reverts on every call because renouncing ownership would irrecoverably remove upgrade authority
    ///      Use transferOwnership to rotate the upgrader key instead.
    ///
    /// @dev WARNING: transferOwnership (inherited from OwnableUpgradeable) is a single-step transfer
    ///      with no confirmation from the new owner. Sending to an incorrect or uncontrolled address
    ///      permanently removes upgrade capability with no recovery path. Rotate keys with extreme care.
    function renounceOwnership() public pure override {
        revert YieldcoinShare__CannotRenounceOwnership();
    }

    /// @notice Prevents initialization through the inherited ComplianceTokenERC3643 initializer
    /// @dev Reverts on every call. ComplianceTokenERC3643 declares this initializer as public virtual, so it
    ///      remains an independently-callable selector unless overridden. YieldcoinShare must only
    ///      be initialized through initialize(address,address,address) above.
    /// @dev All inputs are ignored
    function initialize(string calldata, string calldata, uint8, address) public pure override {
        revert YieldcoinShare__InvalidInitialize();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IPolicyProtected} from "@chainlink/policy-management/interfaces/IPolicyProtected.sol";
import {ComplianceTokenERC3643} from "@chainlink/tokens/erc-3643/src/ComplianceTokenERC3643.sol";
import {YieldcoinShareStore} from "./YieldcoinShareStore.sol";

/// @title YieldcoinShare
/// @author @contractlevel
/// @notice YieldcoinShare is the compliance-ready share token of the Yieldcoin v2 system.
contract YieldcoinShare is ComplianceTokenERC3643, YieldcoinShareStore {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when the CCIP token admin identity changes
    /// @param previousAdmin The previous CCIP admin
    /// @param newAdmin The new CCIP admin
    event CCIPAdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    /*//////////////////////////////////////////////////////////////
                               INITIALIZE
    //////////////////////////////////////////////////////////////*/
    function initialize(address policyEngine, address initialCcipAdmin) external initializer {
        __ComplianceTokenERC3643_init("Yieldcoin", "YIELD", 18, policyEngine);
        _setCCIPAdmin(initialCcipAdmin);
    }

    /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets the Chainlink CCIP token admin identity
    /// @param newAdmin The new CCIP admin
    /// @dev This function is protected by Chainlink ACE RoleBasedAccessControlPolicy authorization
    ///      The deploy script should gate access to this function to the CONFIG_OPERATOR_ROLE.
    //slither-disable-next-line missing-zero-check
    function setCCIPAdmin(address newAdmin) external runPolicy {
        _setCCIPAdmin(newAdmin);
    }

    function _setCCIPAdmin(address newAdmin) internal {
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
}

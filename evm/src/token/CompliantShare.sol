// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.28;

// import {ComplianceTokenERC3643} from "@chainlink/ace/packages/tokens/erc-3643/src/ComplianceTokenERC3643.sol";
// import {AccessControlDefaultAdminRulesUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlDefaultAdminRulesUpgradeable.sol";

// contract YieldcoinShare is ComplianceTokenERC3643, AccessControlDefaultAdminRulesUpgradeable {
//     function initialize(
//         address policyEngine
//     ) public override initializer {
//         __ComplianceTokenERC3643_init("Yieldcoin", "YIELD", 18, policyEngine);
//         __AccessControlDefaultAdminRules_init();
//     }

//     // modifier onlyVault() {
//     //     if (msg.sender != address(i_vault)) revert CompliantShare__OnlyVault();
//     //     _;
//     // }

//     // function mint(address to, uint256 amount) public override onlyVault {
//     //     super.mint(to, amount);
//     // }

//     // function burn(uint256 amount) public override onlyVault {
//     //     super.burn(amount);
//     // }
// }

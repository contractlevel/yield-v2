// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BurnMintERC677} from "@chainlink/contracts/src/v0.8/shared/token/ERC677/BurnMintERC677.sol";
import {IGetCCIPAdmin} from "@chainlink/contracts/src/v0.8/shared/interfaces/IGetCCIPAdmin.sol";

/// @title Yieldcoin Token
/// @author @contractlevel
/// @notice Yieldcoin is the native share token of the Yieldcoin v2 system that allows users to redeem USDC.
contract Yieldcoin is BurnMintERC677, IGetCCIPAdmin {
    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    // @review ccipAdmin should be passed or transferred in deploy script
    constructor() BurnMintERC677("Yieldcoin", "YIELD", 18, 0) {}

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns the current CCIPAdmin
    function getCCIPAdmin() external view returns (address) {
        return owner();
    }
}

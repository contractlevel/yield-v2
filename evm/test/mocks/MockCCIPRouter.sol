// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IRouterClient, Client} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockCCIPRouter is IRouterClient {
    error MockCCIPRouter__GetFeeReverts();
    error MockCCIPRouter__CcipSendReverts();

    address internal immutable i_asset;
    bool internal s_getFeeReverts;
    bool internal s_ccipSendReverts;

    constructor(address asset) {
        i_asset = asset;
    }

    function setGetFeeReverts(bool getFeeReverts) external {
        s_getFeeReverts = getFeeReverts;
    }

    function setCcipSendReverts(bool ccipSendReverts) external {
        s_ccipSendReverts = ccipSendReverts;
    }

    function getFee(
        uint64,
        /* destinationChainSelector */
        Client.EVM2AnyMessage memory /* message */
    )
        external
        view
        returns (uint256)
    {
        if (s_getFeeReverts) revert MockCCIPRouter__GetFeeReverts();
        return 0;
    }

    function ccipSend(
        uint64,
        /* destinationChainSelector */
        Client.EVM2AnyMessage memory message
    )
        external
        payable
        returns (bytes32)
    {
        if (s_ccipSendReverts) revert MockCCIPRouter__CcipSendReverts();
        IERC20(i_asset).transferFrom(msg.sender, address(this), message.tokenAmounts[0].amount);
        return bytes32(0);
    }

    function isChainSupported(
        uint64 /* destinationChainSelector */
    )
        external
        pure
        returns (bool)
    {
        return true;
    }
}

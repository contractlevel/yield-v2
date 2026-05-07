// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IRouterClient, Client} from "@chainlink/contracts-ccip/interfaces/IRouterClient.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockCCIPRouter is IRouterClient {
    address internal immutable i_usdc;

    constructor(address usdc) {
        i_usdc = usdc;
    }

    function getFee(
        uint64,
        /* destinationChainSelector */
        Client.EVM2AnyMessage memory /* message */
    )
        external
        pure
        returns (uint256)
    {
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
        IERC20(i_usdc).transferFrom(msg.sender, address(this), message.tokenAmounts[0].amount);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IRouterClient, Client} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
import {RateLimiter} from "@chainlink/contracts-ccip/contracts/libraries/RateLimiter.sol";

/// @notice Standalone router fixture that always rejects sends for token capacity.
contract MockCCIPSendCapacityRouter is IRouterClient {
    /// @notice Fixed mock fee for rule preconditions; does not perform a fee lookup.
    function getFee() external pure returns (uint256) {
        return 1;
    }

    function getFee(uint64, Client.EVM2AnyMessage calldata) external pure returns (uint256) {
        return 1;
    }

    function ccipSend(uint64, Client.EVM2AnyMessage calldata) external payable returns (bytes32) {
        revert RateLimiter.TokenMaxCapacityExceeded(0, 1, address(0));
    }

    function isChainSupported(uint64) external pure returns (bool) {
        return true;
    }

    function getFeeReverts() external pure returns (bool) {
        return false;
    }

    function ccipSendReverts() external pure returns (bool) {
        return true;
    }

    function capacityError() external pure returns (bool) {
        return true;
    }

    function getLastMessageDataHash() external pure returns (bytes32) {
        return bytes32(0);
    }
}

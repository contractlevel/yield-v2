// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IRouterClient, Client} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Minimal CCIP router mock for Certora verification.
contract MockCCIPRouter is IRouterClient {
    uint256 internal constant FEE = 1;

    bool internal s_getFeeReverts;
    bool internal s_ccipSendReverts;

    /// @notice Returns the fee used by the mock without requiring a constructed CCIP message
    function getFee() external view returns (uint256) {
        if (s_getFeeReverts) revert();
        return FEE;
    }

    function getFee(uint64, Client.EVM2AnyMessage memory) external view returns (uint256) {
        if (s_getFeeReverts) revert();
        return FEE;
    }

    function ccipSend(uint64, Client.EVM2AnyMessage memory message) external payable returns (bytes32) {
        if (s_ccipSendReverts) revert();
        IERC20(message.feeToken).transferFrom(msg.sender, address(this), FEE);
        IERC20(message.tokenAmounts[0].token).transferFrom(
            msg.sender, address(this), message.tokenAmounts[0].amount
        );
        return keccak256(abi.encode(block.number, block.timestamp));
    }

    function isChainSupported(uint64) external pure returns (bool) {
        return true;
    }

    function getFeeReverts() external view returns (bool) {
        return s_getFeeReverts;
    }

    function ccipSendReverts() external view returns (bool) {
        return s_ccipSendReverts;
    }
}

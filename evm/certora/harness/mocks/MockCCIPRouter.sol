// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IRouterClient, Client} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Minimal CCIP router mock for Certora verification.
contract MockCCIPRouter is IRouterClient {
    uint256 internal constant FEE = 1;

    bool internal s_getFeeReverts;
    bool internal s_ccipSendReverts;
    uint64 internal s_lastDestinationChainSelector;
    bytes32 internal s_lastReceiverHash;
    bytes32 internal s_lastMessageDataHash;
    uint256 internal s_lastTokenAmountsLength;
    address internal s_lastToken;
    uint256 internal s_lastTokenAmount;
    bytes32 internal s_lastExtraArgsHash;
    address internal s_lastFeeToken;

    /// @notice Returns the fee used by the mock without requiring a constructed CCIP message
    function getFee() external view returns (uint256) {
        if (s_getFeeReverts) revert();
        return FEE;
    }

    function getFee(uint64, Client.EVM2AnyMessage memory) external view returns (uint256) {
        if (s_getFeeReverts) revert();
        return FEE;
    }

    function ccipSend(uint64 destinationChainSelector, Client.EVM2AnyMessage memory message)
        external
        payable
        returns (bytes32)
    {
        if (s_ccipSendReverts) revert();
        s_lastDestinationChainSelector = destinationChainSelector;
        s_lastReceiverHash = keccak256(message.receiver);
        s_lastMessageDataHash = keccak256(message.data);
        s_lastTokenAmountsLength = message.tokenAmounts.length;
        s_lastToken = message.tokenAmounts[0].token;
        s_lastTokenAmount = message.tokenAmounts[0].amount;
        s_lastExtraArgsHash = keccak256(message.extraArgs);
        s_lastFeeToken = message.feeToken;
        IERC20(message.feeToken).transferFrom(msg.sender, address(this), FEE);
        IERC20(message.tokenAmounts[0].token).transferFrom(msg.sender, address(this), message.tokenAmounts[0].amount);
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

    function getLastMessageDataHash() external view returns (bytes32) {
        return s_lastMessageDataHash;
    }

    function getLastDestinationChainSelector() external view returns (uint64) {
        return s_lastDestinationChainSelector;
    }

    function getLastReceiverHash() external view returns (bytes32) {
        return s_lastReceiverHash;
    }

    function getLastTokenAmountsLength() external view returns (uint256) {
        return s_lastTokenAmountsLength;
    }

    function getLastToken() external view returns (address) {
        return s_lastToken;
    }

    function getLastTokenAmount() external view returns (uint256) {
        return s_lastTokenAmount;
    }

    function getLastExtraArgsHash() external view returns (bytes32) {
        return s_lastExtraArgsHash;
    }

    function getLastFeeToken() external view returns (address) {
        return s_lastFeeToken;
    }
}

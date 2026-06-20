// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IRouterClient, Client} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Minimal CCIP router mock for Certora verification.
///         The test-suite mock (test/mocks/MockCCIPRouter.sol) has configurable failure flags and
///         other behavior that adds unnecessary state-change noise to formal proofs.
///         This mock succeeds unconditionally and pulls the fee token and bridged asset.
contract MockCCIPRouter is IRouterClient {
    uint256 internal constant FEE = 1;

    /// @notice Returns the fee used by the mock without requiring a constructed CCIP message
    function getFee() external pure returns (uint256) {
        return FEE;
    }

    function getFee(uint64, Client.EVM2AnyMessage memory) external pure returns (uint256) {
        return FEE;
    }

    function ccipSend(uint64, Client.EVM2AnyMessage memory message) external payable returns (bytes32) {
        IERC20(message.feeToken).transferFrom(msg.sender, address(this), FEE);
        IERC20(message.tokenAmounts[0].token).transferFrom(
            msg.sender, address(this), message.tokenAmounts[0].amount
        );
        return keccak256(abi.encode(block.number, block.timestamp));
    }

    function isChainSupported(uint64) external pure returns (bool) {
        return true;
    }
}

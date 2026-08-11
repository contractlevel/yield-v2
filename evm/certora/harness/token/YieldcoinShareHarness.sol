// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperHarness} from "../HelperHarness.sol";
import {YieldcoinShare} from "../../../src/token/YieldcoinShare.sol";

/// @notice Certora helpers for YieldcoinShare's initializer, metadata, roles, and UUPS authorization.
contract YieldcoinShareHarness is YieldcoinShare, HelperHarness {
    bytes32 private constant INITIALIZABLE_STORAGE =
        0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;
    bytes32 private constant ERC20_STORAGE =
        0x52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace00;

    function isInitialized() external view returns (bool initialized) {
        bytes32 slot = INITIALIZABLE_STORAGE;
        assembly {
            initialized := gt(and(sload(slot), 0xFFFFFFFFFFFFFFFF), 0)
        }
    }

    function isInitializing() external view returns (bool initializing) {
        bytes32 slot = INITIALIZABLE_STORAGE;
        assembly {
            initializing := iszero(iszero(and(shr(64, sload(slot)), 0xFF)))
        }
    }

    function hasExpectedMetadata() external view returns (bool) {
        return keccak256(bytes(name())) == keccak256(bytes("Yieldcoin"))
            && keccak256(bytes(symbol())) == keccak256(bytes("YIELD")) && decimals() == 18;
    }

    /// @dev Checks the raw OZ ERC20 name/symbol slots before invoking their string decoders.
    function hasEmptyMetadata() external view returns (bool empty) {
        bytes32 slot = ERC20_STORAGE;
        uint256 nameSlot;
        uint256 symbolSlot;
        assembly {
            nameSlot := sload(add(slot, 3))
            symbolSlot := sload(add(slot, 4))
        }
        empty = nameSlot == 0 && symbolSlot == 0;
    }

    function authorizeUpgrade(address newImplementation) external {
        _authorizeUpgrade(newImplementation);
    }
}

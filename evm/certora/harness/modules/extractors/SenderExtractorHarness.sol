// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {SenderExtractor} from "../../../../src/modules/extractors/SenderExtractor.sol";

contract SenderExtractorHarness is SenderExtractor {
    function bytesToAddress(bytes memory value) external pure returns (address decoded) {
        decoded = abi.decode(value, (address));
    }
}

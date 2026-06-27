// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperHarness} from "../../HelperHarness.sol";
import {SenderExtractor} from "../../../../src/modules/extractors/SenderExtractor.sol";

contract SenderExtractorHarness is SenderExtractor, HelperHarness {}

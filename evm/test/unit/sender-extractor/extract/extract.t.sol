// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {SenderExtractor} from "../../../../src/modules/extractors/SenderExtractor.sol";
import {IPolicyEngine} from "@chainlink/policy-management/interfaces/IPolicyEngine.sol";

contract SenderExtractor_ExtractUnitTest is BaseUnitTest {
    SenderExtractor internal s_senderExtractor;

    address internal i_sender = makeAddr("sender");

    function setUp() public {
        s_senderExtractor = new SenderExtractor();
    }

    function test_SenderExtractor_extract_Success() external view {
        IPolicyEngine.Payload memory payload = IPolicyEngine.Payload({
            selector: bytes4(keccak256("someSelector()")), sender: i_sender, data: bytes(""), context: bytes("")
        });

        IPolicyEngine.Parameter[] memory parameters = s_senderExtractor.extract(payload);

        assertEq(parameters.length, 1);
        assertEq(parameters[0].name, s_senderExtractor.PARAM_SENDER());
        assertEq(parameters[0].value, abi.encode(i_sender));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {YieldcoinShareKycExtractor} from "../../../../src/modules/extractors/YieldcoinShareKycExtractor.sol";
import {ComplianceTokenERC3643} from "@chainlink/tokens/erc-3643/src/ComplianceTokenERC3643.sol";
import {IPolicyEngine} from "@chainlink/policy-management/interfaces/IPolicyEngine.sol";

contract YieldcoinShareKycExtractor_ExtractUnitTest is BaseUnitTest {
    YieldcoinShareKycExtractor internal s_extractor;

    address internal i_sender = makeAddr("sender");
    address internal i_from = makeAddr("from");
    address internal i_to = makeAddr("to");
    address internal i_spender = makeAddr("spender");
    address internal i_recipientOne = makeAddr("recipientOne");
    address internal i_recipientTwo = makeAddr("recipientTwo");

    function setUp() public {
        s_extractor = new YieldcoinShareKycExtractor();
    }

    function test_YieldcoinShareKycExtractor_extract_Success_WhenSelectorIsTransfer() external view {
        IPolicyEngine.Parameter[] memory parameters =
            s_extractor.extract(_payload(ComplianceTokenERC3643.transfer.selector, abi.encode(i_to, uint256(1))));

        _assertKycAccounts(parameters, _accounts(i_sender, i_to));
    }

    function test_YieldcoinShareKycExtractor_extract_Success_WhenSelectorIsTransferFrom() external view {
        IPolicyEngine.Parameter[] memory parameters = s_extractor.extract(
            _payload(ComplianceTokenERC3643.transferFrom.selector, abi.encode(i_from, i_to, uint256(1)))
        );

        address[] memory expectedAccounts = new address[](3);
        expectedAccounts[0] = i_sender;
        expectedAccounts[1] = i_from;
        expectedAccounts[2] = i_to;
        _assertKycAccounts(parameters, expectedAccounts);
    }

    function test_YieldcoinShareKycExtractor_extract_Success_WhenSelectorIsBatchTransfer() external view {
        address[] memory recipients = new address[](2);
        recipients[0] = i_recipientOne;
        recipients[1] = i_recipientTwo;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 2;

        IPolicyEngine.Parameter[] memory parameters = s_extractor.extract(
            _payload(ComplianceTokenERC3643.batchTransfer.selector, abi.encode(recipients, amounts))
        );

        address[] memory expectedAccounts = new address[](3);
        expectedAccounts[0] = i_sender;
        expectedAccounts[1] = i_recipientOne;
        expectedAccounts[2] = i_recipientTwo;
        _assertKycAccounts(parameters, expectedAccounts);
    }

    function test_YieldcoinShareKycExtractor_extract_Success_WhenSelectorIsApprove() external view {
        IPolicyEngine.Parameter[] memory parameters =
            s_extractor.extract(_payload(ComplianceTokenERC3643.approve.selector, abi.encode(i_spender, uint256(1))));

        _assertKycAccounts(parameters, _accounts(i_sender, i_spender));
    }

    function test_YieldcoinShareKycExtractor_extract_Success_WhenSelectorIsIncreaseAllowance() external view {
        IPolicyEngine.Parameter[] memory parameters = s_extractor.extract(
            _payload(ComplianceTokenERC3643.increaseAllowance.selector, abi.encode(i_spender, uint256(1)))
        );

        _assertKycAccounts(parameters, _accounts(i_sender, i_spender));
    }

    function test_YieldcoinShareKycExtractor_extract_Success_WhenSelectorIsDecreaseAllowance() external view {
        IPolicyEngine.Parameter[] memory parameters = s_extractor.extract(
            _payload(ComplianceTokenERC3643.decreaseAllowance.selector, abi.encode(i_spender, uint256(1)))
        );

        _assertKycAccounts(parameters, _accounts(i_sender, i_spender));
    }

    function test_YieldcoinShareKycExtractor_extract_RevertWhen_SelectorIsUnsupported() external {
        bytes4 selector = bytes4(keccak256("unsupported()"));

        vm.expectRevert(abi.encodeWithSelector(IPolicyEngine.UnsupportedSelector.selector, selector));
        s_extractor.extract(_payload(selector, bytes("")));
    }

    function _payload(bytes4 selector, bytes memory data) internal view returns (IPolicyEngine.Payload memory payload) {
        payload = IPolicyEngine.Payload({selector: selector, sender: i_sender, data: data, context: bytes("")});
    }

    function _accounts(address first, address second) internal pure returns (address[] memory accounts) {
        accounts = new address[](2);
        accounts[0] = first;
        accounts[1] = second;
    }

    function _assertKycAccounts(IPolicyEngine.Parameter[] memory parameters, address[] memory expectedAccounts)
        internal
        view
    {
        assertEq(parameters.length, 1);
        assertEq(parameters[0].name, s_extractor.PARAM_KYC_ACCOUNTS());

        address[] memory actualAccounts = abi.decode(parameters[0].value, (address[]));
        assertEq(actualAccounts.length, expectedAccounts.length);
        for (uint256 i; i < expectedAccounts.length; ++i) {
            assertEq(actualAccounts[i], expectedAccounts[i]);
        }
    }
}

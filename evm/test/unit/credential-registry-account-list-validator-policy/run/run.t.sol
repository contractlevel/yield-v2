// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {
    CredentialRegistryAccountListValidatorPolicy
} from "../../../../src/modules/policies/CredentialRegistryAccountListValidatorPolicy.sol";
import {ICredentialRequirements} from "@chainlink/cross-chain-identity/interfaces/ICredentialRequirements.sol";
import {IPolicyEngine} from "@chainlink/policy-management/interfaces/IPolicyEngine.sol";
import {Policy} from "@chainlink/policy-management/core/Policy.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {MockCredentialRegistry} from "../../../mocks/MockCredentialRegistry.sol";
import {MockIdentityRegistry} from "../../../mocks/MockIdentityRegistry.sol";

contract CredentialRegistryAccountListValidatorPolicy_RunUnitTest is BaseUnitTest {
    bytes32 internal constant KYC_CREDENTIAL = keccak256("common.kyc");
    bytes32 internal constant KYC_REQUIREMENT = keccak256("KYC");

    address internal i_policyEngine = makeAddr("policyEngine");
    address internal i_policyOwner = makeAddr("policyOwner");
    address internal i_accountOne = makeAddr("accountOne");
    address internal i_accountTwo = makeAddr("accountTwo");

    MockIdentityRegistry internal s_identityRegistry;
    MockCredentialRegistry internal s_credentialRegistry;
    CredentialRegistryAccountListValidatorPolicy internal s_policy;

    function setUp() public {
        s_identityRegistry = new MockIdentityRegistry();
        s_credentialRegistry = new MockCredentialRegistry();
        s_policy = _deployPolicy();
    }

    function test_CredentialRegistryAccountListValidatorPolicy_run_Success_WhenAllAccountsHaveKyc() external {
        address[] memory accounts = _accounts(i_accountOne, i_accountTwo);
        _setKyc(i_accountOne);
        _setKyc(i_accountTwo);

        IPolicyEngine.PolicyResult result =
            s_policy.run(address(0), address(0), bytes4(0), _parameters(accounts), bytes(""));

        assertEq(uint8(result), uint8(IPolicyEngine.PolicyResult.Continue));
    }

    function test_CredentialRegistryAccountListValidatorPolicy_run_RevertWhen_AnyAccountDoesNotHaveKyc() external {
        address[] memory accounts = _accounts(i_accountOne, i_accountTwo);
        _setKyc(i_accountOne);

        vm.expectRevert(
            abi.encodeWithSelector(IPolicyEngine.PolicyRejected.selector, "account identity validation failed")
        );
        s_policy.run(address(0), address(0), bytes4(0), _parameters(accounts), bytes(""));
    }

    function test_CredentialRegistryAccountListValidatorPolicy_run_RevertWhen_ParametersAreEmpty() external {
        bytes[] memory parameters = new bytes[](0);

        vm.expectRevert(abi.encodeWithSelector(Policy.InvalidParameters.selector, "expected kyc account list"));
        s_policy.run(address(0), address(0), bytes4(0), parameters, bytes(""));
    }

    function test_CredentialRegistryAccountListValidatorPolicy_run_RevertWhen_ParametersHaveMultipleItems() external {
        bytes[] memory parameters = new bytes[](2);
        parameters[0] = abi.encode(_accounts(i_accountOne, i_accountTwo));
        parameters[1] = abi.encode(_accounts(i_accountOne, i_accountTwo));

        vm.expectRevert(abi.encodeWithSelector(Policy.InvalidParameters.selector, "expected kyc account list"));
        s_policy.run(address(0), address(0), bytes4(0), parameters, bytes(""));
    }

    function test_CredentialRegistryAccountListValidatorPolicy_run_RevertWhen_AccountListIsEmpty() external {
        address[] memory accounts = new address[](0);

        vm.expectRevert(abi.encodeWithSelector(Policy.InvalidParameters.selector, "expected at least 1 kyc account"));
        s_policy.run(address(0), address(0), bytes4(0), _parameters(accounts), bytes(""));
    }

    function _deployPolicy() internal returns (CredentialRegistryAccountListValidatorPolicy policy) {
        CredentialRegistryAccountListValidatorPolicy impl = new CredentialRegistryAccountListValidatorPolicy();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl), abi.encodeWithSelector(Policy.initialize.selector, i_policyEngine, i_policyOwner, _config())
        );
        policy = CredentialRegistryAccountListValidatorPolicy(address(proxy));
    }

    function _config() internal view returns (bytes memory) {
        ICredentialRequirements.CredentialSourceInput[] memory sources =
            new ICredentialRequirements.CredentialSourceInput[](1);
        sources[0] = ICredentialRequirements.CredentialSourceInput({
            credentialTypeId: KYC_CREDENTIAL,
            identityRegistry: address(s_identityRegistry),
            credentialRegistry: address(s_credentialRegistry),
            dataValidator: address(0)
        });

        bytes32[] memory credentials = new bytes32[](1);
        credentials[0] = KYC_CREDENTIAL;
        ICredentialRequirements.CredentialRequirementInput[] memory requirements =
            new ICredentialRequirements.CredentialRequirementInput[](1);
        requirements[0] = ICredentialRequirements.CredentialRequirementInput({
            requirementId: KYC_REQUIREMENT, credentialTypeIds: credentials, minValidations: 1, invert: false
        });

        return abi.encode(sources, requirements);
    }

    function _setKyc(address account) internal {
        bytes32 ccid = keccak256(abi.encode(account));
        s_identityRegistry.setIdentity(account, ccid);
        s_credentialRegistry.setCredential(ccid, KYC_CREDENTIAL, true);
    }

    function _parameters(address[] memory accounts) internal pure returns (bytes[] memory parameters) {
        parameters = new bytes[](1);
        parameters[0] = abi.encode(accounts);
    }

    function _accounts(address first, address second) internal pure returns (address[] memory accounts) {
        accounts = new address[](2);
        accounts[0] = first;
        accounts[1] = second;
    }
}

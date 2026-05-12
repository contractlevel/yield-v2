// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {
    CredentialRegistryAccountListValidatorPolicy
} from "../../../../src/modules/policies/CredentialRegistryAccountListValidatorPolicy.sol";
import {ICredentialRequirements} from "@chainlink/cross-chain-identity/interfaces/ICredentialRequirements.sol";
import {Policy} from "@chainlink/policy-management/core/Policy.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract CredentialRegistryAccountListValidatorPolicy_ConfigureUnitTest is BaseUnitTest {
    bytes32 internal constant KYC_CREDENTIAL = keccak256("common.kyc");
    bytes32 internal constant KYC_REQUIREMENT = keccak256("KYC");
    bytes32 internal constant AML_CREDENTIAL = keccak256("common.aml");
    bytes32 internal constant AML_REQUIREMENT = keccak256("AML");

    address internal i_policyEngine = makeAddr("policyEngine");
    address internal i_policyOwner = makeAddr("policyOwner");
    address internal i_identityRegistry = makeAddr("identityRegistry");
    address internal i_credentialRegistry = makeAddr("credentialRegistry");
    address internal i_secondIdentityRegistry = makeAddr("secondIdentityRegistry");
    address internal i_secondCredentialRegistry = makeAddr("secondCredentialRegistry");

    function test_CredentialRegistryAccountListValidatorPolicy_configure_Success_WhenParametersAreEmpty() external {
        CredentialRegistryAccountListValidatorPolicy policy = _deployPolicy(new bytes(0));

        bytes32[] memory requirementIds = policy.getCredentialRequirementIds();
        ICredentialRequirements.CredentialSource[] memory sources = policy.getCredentialSources(KYC_CREDENTIAL);

        assertEq(requirementIds.length, 0);
        assertEq(sources.length, 0);
    }

    function test_CredentialRegistryAccountListValidatorPolicy_configure_Success_WhenParametersAreValid() external {
        CredentialRegistryAccountListValidatorPolicy policy = _deployPolicy(_validConfig());

        _assertRequirement(policy, KYC_REQUIREMENT, KYC_CREDENTIAL);
        _assertSource(policy, KYC_CREDENTIAL, 0, i_identityRegistry, i_credentialRegistry);
    }

    function test_CredentialRegistryAccountListValidatorPolicy_configure_Success_WhenMultipleInputsAreValid() external {
        ICredentialRequirements.CredentialSourceInput[] memory sources =
            new ICredentialRequirements.CredentialSourceInput[](2);
        sources[0] = _source(KYC_CREDENTIAL, i_identityRegistry, i_credentialRegistry);
        sources[1] = _source(AML_CREDENTIAL, i_secondIdentityRegistry, i_secondCredentialRegistry);

        ICredentialRequirements.CredentialRequirementInput[] memory requirements =
            new ICredentialRequirements.CredentialRequirementInput[](2);
        requirements[0] = _requirement(KYC_REQUIREMENT, KYC_CREDENTIAL, 1);
        requirements[1] = _requirement(AML_REQUIREMENT, AML_CREDENTIAL, 1);

        CredentialRegistryAccountListValidatorPolicy policy = _deployPolicy(abi.encode(sources, requirements));

        _assertRequirement(policy, KYC_REQUIREMENT, KYC_CREDENTIAL);
        _assertRequirement(policy, AML_REQUIREMENT, AML_CREDENTIAL);
        _assertSource(policy, KYC_CREDENTIAL, 0, i_identityRegistry, i_credentialRegistry);
        _assertSource(policy, AML_CREDENTIAL, 0, i_secondIdentityRegistry, i_secondCredentialRegistry);
    }

    function test_CredentialRegistryAccountListValidatorPolicy_configure_RevertWhen_ParametersAreMalformed() external {
        CredentialRegistryAccountListValidatorPolicy impl = new CredentialRegistryAccountListValidatorPolicy();

        vm.expectRevert();
        _deployProxy(impl, hex"1234");
    }

    function test_CredentialRegistryAccountListValidatorPolicy_configure_RevertWhen_RequirementMinValidationsIsZero()
        external
    {
        ICredentialRequirements.CredentialSourceInput[] memory sources =
            new ICredentialRequirements.CredentialSourceInput[](1);
        sources[0] = _source(KYC_CREDENTIAL, i_identityRegistry, i_credentialRegistry);

        ICredentialRequirements.CredentialRequirementInput[] memory requirements =
            new ICredentialRequirements.CredentialRequirementInput[](1);
        requirements[0] = _requirement(KYC_REQUIREMENT, KYC_CREDENTIAL, 0);

        CredentialRegistryAccountListValidatorPolicy impl = new CredentialRegistryAccountListValidatorPolicy();

        vm.expectRevert(
            abi.encodeWithSelector(
                ICredentialRequirements.InvalidRequirementConfiguration.selector,
                "minValidations must be greater than 0"
            )
        );
        _deployProxy(impl, abi.encode(sources, requirements));
    }

    function test_CredentialRegistryAccountListValidatorPolicy_configure_RevertWhen_RequirementCredentialTypesAreEmpty()
        external
    {
        ICredentialRequirements.CredentialSourceInput[] memory sources =
            new ICredentialRequirements.CredentialSourceInput[](1);
        sources[0] = _source(KYC_CREDENTIAL, i_identityRegistry, i_credentialRegistry);

        ICredentialRequirements.CredentialRequirementInput[] memory requirements =
            new ICredentialRequirements.CredentialRequirementInput[](1);
        requirements[0] = ICredentialRequirements.CredentialRequirementInput({
            requirementId: KYC_REQUIREMENT, credentialTypeIds: new bytes32[](0), minValidations: 1, invert: false
        });

        CredentialRegistryAccountListValidatorPolicy impl = new CredentialRegistryAccountListValidatorPolicy();

        vm.expectRevert(
            abi.encodeWithSelector(
                ICredentialRequirements.InvalidRequirementConfiguration.selector, "Invalid credential types length"
            )
        );
        _deployProxy(impl, abi.encode(sources, requirements));
    }

    function test_CredentialRegistryAccountListValidatorPolicy_configure_RevertWhen_RequirementIsDuplicate() external {
        ICredentialRequirements.CredentialSourceInput[] memory sources =
            new ICredentialRequirements.CredentialSourceInput[](1);
        sources[0] = _source(KYC_CREDENTIAL, i_identityRegistry, i_credentialRegistry);

        ICredentialRequirements.CredentialRequirementInput[] memory requirements =
            new ICredentialRequirements.CredentialRequirementInput[](2);
        requirements[0] = _requirement(KYC_REQUIREMENT, KYC_CREDENTIAL, 1);
        requirements[1] = _requirement(KYC_REQUIREMENT, KYC_CREDENTIAL, 1);

        CredentialRegistryAccountListValidatorPolicy impl = new CredentialRegistryAccountListValidatorPolicy();

        vm.expectRevert(abi.encodeWithSelector(ICredentialRequirements.RequirementExists.selector, KYC_REQUIREMENT));
        _deployProxy(impl, abi.encode(sources, requirements));
    }

    function test_CredentialRegistryAccountListValidatorPolicy_configure_RevertWhen_SourceIsDuplicate() external {
        ICredentialRequirements.CredentialSourceInput[] memory sources =
            new ICredentialRequirements.CredentialSourceInput[](2);
        sources[0] = _source(KYC_CREDENTIAL, i_identityRegistry, i_credentialRegistry);
        sources[1] = _source(KYC_CREDENTIAL, i_identityRegistry, i_credentialRegistry);

        ICredentialRequirements.CredentialRequirementInput[] memory requirements =
            new ICredentialRequirements.CredentialRequirementInput[](1);
        requirements[0] = _requirement(KYC_REQUIREMENT, KYC_CREDENTIAL, 1);

        CredentialRegistryAccountListValidatorPolicy impl = new CredentialRegistryAccountListValidatorPolicy();

        vm.expectRevert(
            abi.encodeWithSelector(
                ICredentialRequirements.SourceExists.selector, KYC_CREDENTIAL, i_identityRegistry, i_credentialRegistry
            )
        );
        _deployProxy(impl, abi.encode(sources, requirements));
    }

    function _deployPolicy(bytes memory config) internal returns (CredentialRegistryAccountListValidatorPolicy policy) {
        CredentialRegistryAccountListValidatorPolicy impl = new CredentialRegistryAccountListValidatorPolicy();
        policy = _deployProxy(impl, config);
    }

    function _deployProxy(CredentialRegistryAccountListValidatorPolicy impl, bytes memory config)
        internal
        returns (CredentialRegistryAccountListValidatorPolicy policy)
    {
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl), abi.encodeWithSelector(Policy.initialize.selector, i_policyEngine, i_policyOwner, config)
        );
        policy = CredentialRegistryAccountListValidatorPolicy(address(proxy));
    }

    function _validConfig() internal view returns (bytes memory) {
        ICredentialRequirements.CredentialSourceInput[] memory sources =
            new ICredentialRequirements.CredentialSourceInput[](1);
        sources[0] = _source(KYC_CREDENTIAL, i_identityRegistry, i_credentialRegistry);

        ICredentialRequirements.CredentialRequirementInput[] memory requirements =
            new ICredentialRequirements.CredentialRequirementInput[](1);
        requirements[0] = _requirement(KYC_REQUIREMENT, KYC_CREDENTIAL, 1);

        return abi.encode(sources, requirements);
    }

    function _source(bytes32 credential, address identityRegistry, address credentialRegistry)
        internal
        pure
        returns (ICredentialRequirements.CredentialSourceInput memory)
    {
        return ICredentialRequirements.CredentialSourceInput({
            credentialTypeId: credential,
            identityRegistry: identityRegistry,
            credentialRegistry: credentialRegistry,
            dataValidator: address(0)
        });
    }

    function _requirement(bytes32 requirementId, bytes32 credential, uint256 minValidations)
        internal
        pure
        returns (ICredentialRequirements.CredentialRequirementInput memory)
    {
        bytes32[] memory credentials = new bytes32[](1);
        credentials[0] = credential;
        return ICredentialRequirements.CredentialRequirementInput({
            requirementId: requirementId, credentialTypeIds: credentials, minValidations: minValidations, invert: false
        });
    }

    function _assertRequirement(
        CredentialRegistryAccountListValidatorPolicy policy,
        bytes32 requirementId,
        bytes32 credential
    ) internal view {
        bytes32[] memory requirementIds = policy.getCredentialRequirementIds();
        bool found;
        for (uint256 i; i < requirementIds.length; ++i) {
            if (requirementIds[i] == requirementId) found = true;
        }
        assertEq(found, true);

        ICredentialRequirements.CredentialRequirement memory requirement =
            policy.getCredentialRequirement(requirementId);
        assertEq(requirement.credentialTypeIds.length, 1);
        assertEq(requirement.credentialTypeIds[0], credential);
        assertEq(requirement.minValidations, 1);
        assertEq(requirement.invert, false);
    }

    function _assertSource(
        CredentialRegistryAccountListValidatorPolicy policy,
        bytes32 credential,
        uint256 index,
        address identityRegistry,
        address credentialRegistry
    ) internal view {
        ICredentialRequirements.CredentialSource[] memory sources = policy.getCredentialSources(credential);
        assertGt(sources.length, index);
        assertEq(sources[index].identityRegistry, identityRegistry);
        assertEq(sources[index].credentialRegistry, credentialRegistry);
        assertEq(sources[index].dataValidator, address(0));
    }
}

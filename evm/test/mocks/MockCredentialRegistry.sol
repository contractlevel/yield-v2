// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {ICredentialRegistry} from "@chainlink/cross-chain-identity/interfaces/ICredentialRegistry.sol";

contract MockCredentialRegistry is ICredentialRegistry {
    mapping(bytes32 ccid => mapping(bytes32 credentialTypeId => Credential credential)) internal s_credentials;
    mapping(bytes32 ccid => bytes32[] credentialTypeIds) internal s_credentialTypeIds;

    function typeAndVersion() external pure returns (string memory) {
        return "MockCredentialRegistry 1.0.0";
    }

    function setCredential(bytes32 ccid, bytes32 credentialTypeId, bool valid) external {
        if (valid) {
            _setCredential(ccid, credentialTypeId, 0, bytes(""));
        } else {
            delete s_credentials[ccid][credentialTypeId];
        }
    }

    function validate(bytes32 ccid, bytes32 credentialTypeId, bytes calldata) external view returns (bool) {
        Credential memory credential = s_credentials[ccid][credentialTypeId];
        return credential.expiresAt == 0 && credential.credentialData.length != 0;
    }

    function validateAll(bytes32 ccid, bytes32[] calldata credentialTypeIds, bytes calldata)
        external
        view
        returns (bool)
    {
        for (uint256 i; i < credentialTypeIds.length; ++i) {
            Credential memory credential = s_credentials[ccid][credentialTypeIds[i]];
            if (credential.expiresAt != 0 || credential.credentialData.length == 0) return false;
        }
        return true;
    }

    function registerCredential(
        bytes32 ccid,
        bytes32 credentialTypeId,
        uint40 expiresAt,
        bytes calldata credentialData,
        bytes calldata
    ) external {
        _setCredential(ccid, credentialTypeId, expiresAt, credentialData);
    }

    function registerCredentials(
        bytes32 ccid,
        bytes32[] calldata credentialTypeIds,
        uint40 expiresAt,
        bytes[] calldata credentialDatas,
        bytes calldata
    ) external {
        for (uint256 i; i < credentialTypeIds.length; ++i) {
            _setCredential(ccid, credentialTypeIds[i], expiresAt, credentialDatas[i]);
        }
    }

    function removeCredential(bytes32 ccid, bytes32 credentialTypeId, bytes calldata) external {
        delete s_credentials[ccid][credentialTypeId];
    }

    function renewCredential(bytes32 ccid, bytes32 credentialTypeId, uint40 expiresAt, bytes calldata) external {
        s_credentials[ccid][credentialTypeId].expiresAt = expiresAt;
    }

    function isCredentialExpired(bytes32 ccid, bytes32 credentialTypeId) external view returns (bool) {
        uint40 expiresAt = s_credentials[ccid][credentialTypeId].expiresAt;
        return expiresAt != 0 && expiresAt < block.timestamp;
    }

    function getCredentialTypes(bytes32 ccid) external view returns (bytes32[] memory) {
        return s_credentialTypeIds[ccid];
    }

    function getCredential(bytes32 ccid, bytes32 credentialTypeId) external view returns (Credential memory) {
        return s_credentials[ccid][credentialTypeId];
    }

    function getCredentials(bytes32 ccid, bytes32[] calldata credentialTypeIds)
        external
        view
        returns (Credential[] memory credentials)
    {
        credentials = new Credential[](credentialTypeIds.length);
        for (uint256 i; i < credentialTypeIds.length; ++i) {
            credentials[i] = s_credentials[ccid][credentialTypeIds[i]];
        }
    }

    function _setCredential(bytes32 ccid, bytes32 credentialTypeId, uint40 expiresAt, bytes memory credentialData)
        internal
    {
        if (credentialData.length == 0) credentialData = bytes("valid");
        if (s_credentials[ccid][credentialTypeId].credentialData.length == 0) {
            s_credentialTypeIds[ccid].push(credentialTypeId);
        }
        s_credentials[ccid][credentialTypeId] = Credential({expiresAt: expiresAt, credentialData: credentialData});
    }
}

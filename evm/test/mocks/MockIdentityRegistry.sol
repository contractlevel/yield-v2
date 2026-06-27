// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IIdentityRegistry} from "@chainlink/cross-chain-identity/interfaces/IIdentityRegistry.sol";

contract MockIdentityRegistry is IIdentityRegistry {
    mapping(address account => bytes32 ccid) internal s_identities;
    mapping(bytes32 ccid => address[] accounts) internal s_accounts;

    function typeAndVersion() external pure returns (string memory) {
        return "MockIdentityRegistry 1.0.0";
    }

    function setIdentity(address account, bytes32 ccid) external {
        s_identities[account] = ccid;
        s_accounts[ccid].push(account);
    }

    function registerIdentity(bytes32 ccid, address account, bytes calldata) external {
        s_identities[account] = ccid;
        s_accounts[ccid].push(account);
    }

    function registerIdentities(bytes32[] calldata ccids, address[] calldata accounts, bytes calldata) external {
        for (uint256 i; i < accounts.length; ++i) {
            s_identities[accounts[i]] = ccids[i];
            s_accounts[ccids[i]].push(accounts[i]);
        }
    }

    function removeIdentity(bytes32 ccid, address account, bytes calldata) external {
        delete s_identities[account];

        address[] storage accounts = s_accounts[ccid];
        for (uint256 i; i < accounts.length; ++i) {
            if (accounts[i] == account) {
                accounts[i] = accounts[accounts.length - 1];
                accounts.pop();
                return;
            }
        }
    }

    function getIdentity(address account) external view returns (bytes32) {
        return s_identities[account];
    }

    function getAccounts(bytes32 ccid) external view returns (address[] memory) {
        return s_accounts[ccid];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {MockVault} from "../../../../../test/mocks/MockVault.sol";
import {IProtocolAdapter} from "../../../../../src/interfaces/adapters/IProtocolAdapter.sol";

contract MockAaveV4Vault is MockVault {
    constructor(address asset) MockVault(asset) {}

    function depositAndGetRevertData(address adapter, uint256 amount)
        external
        returns (bool reverted, bytes memory reason)
    {
        try IProtocolAdapter(adapter).deposit(amount) {
            return (false, bytes(""));
        } catch (bytes memory revertData) {
            return (true, revertData);
        }
    }
}

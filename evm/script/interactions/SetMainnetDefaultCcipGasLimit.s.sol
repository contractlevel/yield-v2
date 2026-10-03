// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Script} from "forge-std/Script.sol";

import {HelperConfig} from "../HelperConfig.s.sol";
import {IBaseVault} from "../../src/interfaces/vaults/IBaseVault.sol";

contract SetMainnetDefaultCcipGasLimit is Script {
    error SetMainnetDefaultCcipGasLimit__UnsupportedChain(uint256 chainId);
    error SetMainnetDefaultCcipGasLimit__UnexpectedGasLimit(uint256 actual, uint256 expected);

    uint256 internal constant DEFAULT_CCIP_GAS_LIMIT = 800_000;

    function run() external {
        if (!_isSupportedMainnet(block.chainid)) {
            revert SetMainnetDefaultCcipGasLimit__UnsupportedChain(block.chainid);
        }

        address vaultAddress = new HelperConfig().getActiveNetworkConfig().deployed.vaultProxy;
        IBaseVault vault = IBaseVault(vaultAddress);
        if (vault.getDefaultCcipGasLimit() == DEFAULT_CCIP_GAS_LIMIT) return;

        vm.broadcast(msg.sender);
        vault.setDefaultCcipGasLimit(DEFAULT_CCIP_GAS_LIMIT);

        uint256 actual = vault.getDefaultCcipGasLimit();
        if (actual != DEFAULT_CCIP_GAS_LIMIT) {
            revert SetMainnetDefaultCcipGasLimit__UnexpectedGasLimit(actual, DEFAULT_CCIP_GAS_LIMIT);
        }
    }

    function _isSupportedMainnet(uint256 chainId) private pure returns (bool) {
        return
            chainId == 1 || chainId == 10 || chainId == 137 || chainId == 8453 || chainId == 42_161 || chainId == 43_114;
    }
}

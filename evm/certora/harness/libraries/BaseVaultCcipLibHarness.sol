// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperHarness} from "../HelperHarness.sol";
import {BaseVaultStore} from "../../../src/vaults/BaseVaultStore.sol";
import {BaseVaultCcipLib} from "../../../src/libraries/vaults/BaseVaultCcipLib.sol";
import {Types} from "../../../src/libraries/Types.sol";
import {Client} from "@chainlink/contracts-ccip/contracts/libraries/Client.sol";

contract BaseVaultCcipLibHarness is BaseVaultStore, HelperHarness {
    address internal immutable i_asset;
    address internal immutable i_link;
    address internal immutable i_ccipRouter;

    constructor(address asset, address link, address ccipRouter) {
        i_asset = asset;
        i_link = link;
        i_ccipRouter = ccipRouter;
    }

    function getCrosschainVault(uint64 chainSelector) external view returns (address vault) {
        vault = _baseVaultStorage().s_crosschainVaults[chainSelector];
    }

    function getCcipGasLimit(uint64 chainSelector) external view returns (uint256 gasLimit) {
        gasLimit = _baseVaultStorage().s_ccipGasLimits[chainSelector];
    }

    function getResolvedCcipGasLimit(uint64 chainSelector) external view returns (uint256 gasLimit) {
        gasLimit = BaseVaultCcipLib._getCcipGasLimit(_baseVaultStorage(), chainSelector);
    }

    function getDefaultCcipGasLimit() external view returns (uint256 defaultCcipGasLimit) {
        defaultCcipGasLimit = _baseVaultStorage().s_defaultCcipGasLimit;
    }

    function getAsset() external view returns (address asset) {
        asset = i_asset;
    }

    function getRouter() external view returns (address router) {
        router = i_ccipRouter;
    }

    function onlyAllowedSender(address sender, uint64 srcChainSelector) external view {
        BaseVaultCcipLib._onlyAllowedSender(_baseVaultStorage(), sender, srcChainSelector);
    }

    function validateCcipSend(uint256 bridgeAmount, uint64 destinationChainSelector, uint64 thisChainSelector)
        external
        view
        returns (address vault)
    {
        vault = BaseVaultCcipLib._validateCcipSend(
            _baseVaultStorage(), bridgeAmount, destinationChainSelector, thisChainSelector
        );
    }

    function executeCcipSend(
        uint256 bridgeAmount,
        uint64 destinationChainSelector,
        Types.CcipTx ccipTxType,
        bytes calldata txData,
        uint64 thisChainSelector
    ) external {
        BaseVaultCcipLib._send(
            _baseVaultStorage(),
            bridgeAmount,
            destinationChainSelector,
            ccipTxType,
            txData,
            i_asset,
            i_link,
            i_ccipRouter,
            thisChainSelector
        );
    }

    function validateReceivedTokenAndGetAmount(Client.Any2EVMMessage calldata message)
        external
        view
        returns (uint256 amount)
    {
        amount = BaseVaultCcipLib._validateReceivedTokenAndGetAmount(message, i_asset);
    }
}

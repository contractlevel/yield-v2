// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseVaultStore} from "../../vaults/BaseVaultStore.sol";
import {IBaseVault} from "../../interfaces/vaults/IBaseVault.sol";
import {Types} from "../Types.sol";

import {IRouterClient, Client} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Yieldcoin v2 BaseVault CCIP logic library
/// @author @contractlevel
/// @notice Handles shared CCIP validation and message sending for BaseVault implementations.
/// @dev Public library functions are linked by Solidity and execute by DELEGATECALL in the vault context.
library BaseVaultCcipLib {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Solidity requires locally declared events for emits; these must match IBaseVault and emit from the vault via DELEGATECALL.
    event CCIPBridged(bytes32 indexed ccipMessageId, uint256 indexed amount, Types.CcipTx indexed ccipTxType);

    /*//////////////////////////////////////////////////////////////
                                  CCIP
    //////////////////////////////////////////////////////////////*/
    /// @notice Reverts unless the CCIP sender matches the configured crosschain vault for the source chain.
    /// @param $ BaseVault namespaced storage
    /// @param sender The decoded CCIP sender
    /// @param srcChainSelector The CCIP selector of the source chain
    function onlyAllowedSender(BaseVaultStore.BaseVaultStorage storage $, address sender, uint64 srcChainSelector)
        public
        view
    {
        _onlyAllowedSender($, sender, srcChainSelector);
    }

    /// @notice Validates CCIP send parameters and returns the registered destination vault.
    /// @param $ BaseVault namespaced storage
    /// @param bridgeAmount The amount of asset to bridge
    /// @param destinationChainSelector The CCIP selector of the destination chain
    /// @param thisChainSelector The CCIP selector of this chain
    /// @return vault The registered vault for the destination chain
    function validateCcipSend(
        BaseVaultStore.BaseVaultStorage storage $,
        uint256 bridgeAmount,
        uint64 destinationChainSelector,
        uint64 thisChainSelector
    ) public view returns (address vault) {
        vault = _validateCcipSend($, bridgeAmount, destinationChainSelector, thisChainSelector);
    }

    /// @notice Builds and sends a CCIP message.
    /// @param $ BaseVault namespaced storage
    /// @param bridgeAmount The amount of asset to bridge
    /// @param destinationChainSelector The CCIP selector of the destination chain
    /// @param ccipTxType The type of CCIP transaction
    /// @param nonce The epoch nonce (EPOCH_NET_DEPOSIT/EPOCH_NET_WITHDRAW) or rebalance nonce (REBALANCE)
    /// @param protocolId The target strategy protocol id; only meaningful when ccipTxType is REBALANCE
    /// @param asset The underlying asset managed by the vault
    /// @param link The LINK token used to pay CCIP fees
    /// @param ccipRouter The CCIP router
    /// @param thisChainSelector The CCIP selector of this chain
    function send(
        BaseVaultStore.BaseVaultStorage storage $,
        uint256 bridgeAmount,
        uint64 destinationChainSelector,
        Types.CcipTx ccipTxType,
        uint256 nonce,
        bytes32 protocolId,
        address asset,
        address link,
        address ccipRouter,
        uint64 thisChainSelector
    ) public {
        _send(
            $,
            bridgeAmount,
            destinationChainSelector,
            ccipTxType,
            nonce,
            protocolId,
            asset,
            link,
            ccipRouter,
            thisChainSelector
        );
    }

    /// @notice Validates that a CCIP message delivered the vault's configured asset token and returns the delivered amount.
    /// @param message The CCIP message received from the router
    /// @param asset The vault's configured asset token
    /// @return amount The amount of asset delivered by CCIP
    function validateReceivedTokenAndGetAmount(Client.Any2EVMMessage memory message, address asset)
        public
        pure
        returns (uint256 amount)
    {
        amount = _validateReceivedTokenAndGetAmount(message, asset);
    }

    function _onlyAllowedSender(BaseVaultStore.BaseVaultStorage storage $, address sender, uint64 srcChainSelector)
        internal
        view
    {
        address registeredVault = $.s_crosschainVaults[srcChainSelector];
        if (registeredVault == address(0) || sender != registeredVault) {
            revert IBaseVault.BaseVault__InvalidSender(sender, srcChainSelector);
        }
    }

    function _send(
        BaseVaultStore.BaseVaultStorage storage $,
        uint256 bridgeAmount,
        uint64 destinationChainSelector,
        Types.CcipTx ccipTxType,
        uint256 nonce,
        bytes32 protocolId,
        address asset,
        address link,
        address ccipRouter,
        uint64 thisChainSelector
    ) internal {
        address vault = _validateCcipSend($, bridgeAmount, destinationChainSelector, thisChainSelector);
        uint256 gasLimit = _getCcipGasLimit($, destinationChainSelector);
        bytes memory txData = ccipTxType == Types.CcipTx.REBALANCE ? abi.encode(nonce, protocolId) : abi.encode(nonce);
        bytes memory data = abi.encode(ccipTxType, txData);

        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: asset, amount: bridgeAmount});

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(vault),
            data: data,
            tokenAmounts: tokenAmounts,
            extraArgs: Client._argsToBytes(
                Client.GenericExtraArgsV2({gasLimit: gasLimit, allowOutOfOrderExecution: false})
            ),
            feeToken: link
        });

        uint256 fee = IRouterClient(ccipRouter).getFee(destinationChainSelector, message);
        IERC20(link).forceApprove(ccipRouter, fee);
        IERC20(asset).forceApprove(ccipRouter, bridgeAmount);
        bytes32 ccipMessageId = IRouterClient(ccipRouter).ccipSend(destinationChainSelector, message);
        emit CCIPBridged(ccipMessageId, bridgeAmount, ccipTxType);
    }

    function _validateReceivedTokenAndGetAmount(Client.Any2EVMMessage memory message, address asset)
        internal
        pure
        returns (uint256 amount)
    {
        uint256 tokenAmountsLength = message.destTokenAmounts.length;
        if (tokenAmountsLength != 1) {
            revert IBaseVault.BaseVault__InvalidTokenAmountsLength(tokenAmountsLength, 1);
        }

        Client.EVMTokenAmount memory tokenAmount = message.destTokenAmounts[0];
        if (tokenAmount.token != asset) revert IBaseVault.BaseVault__InvalidReceivedToken(tokenAmount.token, asset);
        amount = tokenAmount.amount;
        if (amount == 0) revert IBaseVault.BaseVault__NoZeroAmount();
    }

    function _validateCcipSend(
        BaseVaultStore.BaseVaultStorage storage $,
        uint256 bridgeAmount,
        uint64 destinationChainSelector,
        uint64 thisChainSelector
    ) internal view returns (address vault) {
        if (bridgeAmount == 0) revert IBaseVault.BaseVault__NoZeroAmount();
        if (destinationChainSelector == 0 || destinationChainSelector == thisChainSelector) {
            revert IBaseVault.BaseVault__InvalidDestinationChainSelector(destinationChainSelector);
        }

        vault = $.s_crosschainVaults[destinationChainSelector];
        if (vault == address(0)) revert IBaseVault.BaseVault__DestinationVaultNotSet(destinationChainSelector);
    }

    function _getCcipGasLimit(BaseVaultStore.BaseVaultStorage storage $, uint64 chainSelector)
        internal
        view
        returns (uint256 gasLimit)
    {
        gasLimit = $.s_ccipGasLimits[chainSelector];
        if (gasLimit == 0) gasLimit = $.s_defaultCcipGasLimit;
    }
}

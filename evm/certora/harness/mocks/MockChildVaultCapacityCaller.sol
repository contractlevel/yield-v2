// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {ChildVaultHarness} from "../vaults/ChildVaultHarness.sol";
import {IRouterClient, Client} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
import {RateLimiter} from "@chainlink/contracts-ccip/contracts/libraries/RateLimiter.sol";
import {Types} from "../../../src/libraries/Types.sol";

/// @notice Captures actual router and vault revert data without replacing the vault's catch.
contract MockChildVaultCapacityCaller {
    IRouterClient internal immutable i_router;
    ChildVaultHarness internal immutable i_vault;

    constructor(address router, address vault) {
        i_router = IRouterClient(router);
        i_vault = ChildVaultHarness(vault);
    }

    function expectedCapacityError() external pure returns (bytes memory) {
        return abi.encodeWithSelector(RateLimiter.TokenMaxCapacityExceeded.selector, uint256(0), uint256(1), address(0));
    }

    function captureRouterSend(uint64 destinationChainSelector, Client.EVM2AnyMessage calldata message)
        external
        returns (bool reverted, bytes memory reason)
    {
        try i_router.ccipSend(destinationChainSelector, message) returns (bytes32) {
            return (false, bytes(""));
        } catch (bytes memory revertData) {
            return (true, revertData);
        }
    }

    function captureEpochWithdraw(uint256 epochNonce, uint256 amount)
        external
        returns (bool reverted, bytes memory reason)
    {
        try i_vault.executeEpochWithdraw(epochNonce, amount) {
            return (false, bytes(""));
        } catch (bytes memory revertData) {
            return (true, revertData);
        }
    }

    function captureRebalance(uint256 rebalanceNonce, Types.Strategy calldata newStrategy)
        external
        returns (bool reverted, bytes memory reason)
    {
        try i_vault.executeRebalance(rebalanceNonce, newStrategy) {
            return (false, bytes(""));
        } catch (bytes memory revertData) {
            return (true, revertData);
        }
    }

    function captureRecovery() external returns (bool reverted, bytes memory reason) {
        try i_vault.executeRecovery() {
            return (false, bytes(""));
        } catch (bytes memory revertData) {
            return (true, revertData);
        }
    }

    function captureVaultSend(
        uint256 bridgeAmount,
        uint64 destinationChainSelector,
        Types.CcipTx ccipTxType,
        uint256 nonce,
        bytes32 protocolId
    ) external returns (bool reverted, bytes memory reason) {
        try i_vault.ccipSend(bridgeAmount, destinationChainSelector, ccipTxType, nonce, protocolId) {
            return (false, bytes(""));
        } catch (bytes memory revertData) {
            return (true, revertData);
        }
    }
}

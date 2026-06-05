// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";
import {TargetFunctions} from "./TargetFunctions.t.sol";

contract CryticToFoundry is TargetFunctions, FoundryAsserts {
    function setUp() public override {
        setup();

        bytes4[] memory selectors = new bytes4[](14);
        selectors[0] = TargetFunctions.handler_deposit.selector;
        selectors[1] = TargetFunctions.handler_cancelDeposit.selector;
        selectors[2] = TargetFunctions.handler_closeEpoch.selector;
        selectors[3] = TargetFunctions.handler_claimShares.selector;
        selectors[4] = TargetFunctions.handler_withdraw.selector;
        selectors[5] = TargetFunctions.handler_cancelWithdraw.selector;
        selectors[6] = TargetFunctions.handler_claimUsdc.selector;
        selectors[7] = TargetFunctions.handler_initiateRebalance.selector;
        selectors[8] = TargetFunctions.handler_emergencyDrainAndDonate.selector;
        selectors[9] = TargetFunctions.handler_recoverFailedCcipSend.selector;
        selectors[10] = TargetFunctions.handler_recoverFailedEpochDeposit.selector;
        selectors[11] = TargetFunctions.handler_recoverFailedEpochWithdraw.selector;
        selectors[12] = TargetFunctions.handler_recoverFailedRebalanceDeposit.selector;
        selectors[13] = TargetFunctions.handler_recoverFailedRebalanceWithdraw.selector;

        targetSelector(FuzzSelector({addr: address(this), selectors: selectors}));
        targetContract(address(this));
    }

    function test_crytic() public {
        // --- User flows ---
        handler_deposit(0, MIN_DEPOSIT_AMOUNT);
        handler_cancelDeposit(0, MIN_DEPOSIT_AMOUNT);
        handler_withdraw(0, MIN_DEPOSIT_AMOUNT, MIN_DEPOSIT_AMOUNT);
        handler_cancelWithdraw(0, MIN_DEPOSIT_AMOUNT, MIN_DEPOSIT_AMOUNT);
        handler_closeEpoch(0);
        handler_claimShares(0, 0, MIN_DEPOSIT_AMOUNT);
        handler_claimUsdc(0, 0, MIN_DEPOSIT_AMOUNT, MIN_DEPOSIT_AMOUNT);

        // --- Rebalance: all 3 chains x all 3 protocols ---
        handler_initiateRebalance(0, 0, 0, MIN_DEPOSIT_AMOUNT); // parent,      AaveV3
        handler_initiateRebalance(1, 1, 0, MIN_DEPOSIT_AMOUNT); // child,       AaveV4
        handler_initiateRebalance(2, 2, 0, MIN_DEPOSIT_AMOUNT); // remoteChild, CompoundV3

        // --- Emergency recovery ---
        handler_emergencyDrainAndDonate();

        // --- CCIP send failure: epoch-withdraw (both child vaults) ---
        handler_recoverFailedCcipSend(0, 0, 0, MIN_DEPOSIT_AMOUNT); // epoch-withdraw, child.vault
        handler_recoverFailedCcipSend(2, 0, 0, MIN_DEPOSIT_AMOUNT); // epoch-withdraw, remoteChild.vault
        // --- CCIP send failure: rebalance (dest=parent vs dest=other child) ---
        handler_recoverFailedCcipSend(1, 0, 0, MIN_DEPOSIT_AMOUNT); // rebalance, child.vault -> parent
        handler_recoverFailedCcipSend(3, 1, 0, MIN_DEPOSIT_AMOUNT); // rebalance, remoteChild.vault -> child

        // --- Epoch deposit failure (both child vaults) ---
        handler_recoverFailedEpochDeposit(0, 0, 0, MIN_DEPOSIT_AMOUNT); // child.vault
        handler_recoverFailedEpochDeposit(1, 0, 0, MIN_DEPOSIT_AMOUNT); // remoteChild.vault

        // --- Epoch withdraw failure (both child vaults) ---
        handler_recoverFailedEpochWithdraw(0, 0, 0, MIN_DEPOSIT_AMOUNT); // child.vault
        handler_recoverFailedEpochWithdraw(1, 0, 0, MIN_DEPOSIT_AMOUNT); // remoteChild.vault

        // --- Rebalance deposit failure: all 4 source x destination paths ---
        handler_recoverFailedRebalanceDeposit(0, 0, 0, MIN_DEPOSIT_AMOUNT); // child.vault -> parent
        handler_recoverFailedRebalanceDeposit(1, 0, 0, MIN_DEPOSIT_AMOUNT); // child.vault -> remoteChild
        handler_recoverFailedRebalanceDeposit(2, 0, 0, MIN_DEPOSIT_AMOUNT); // remoteChild.vault -> parent
        handler_recoverFailedRebalanceDeposit(3, 0, 0, MIN_DEPOSIT_AMOUNT); // remoteChild.vault -> child

        // --- Rebalance withdraw failure: all 4 source x destination paths ---
        handler_recoverFailedRebalanceWithdraw(0, 0, 0, MIN_DEPOSIT_AMOUNT); // child.vault -> parent
        handler_recoverFailedRebalanceWithdraw(0, 1, 0, MIN_DEPOSIT_AMOUNT); // child.vault -> remoteChild
        handler_recoverFailedRebalanceWithdraw(1, 0, 0, MIN_DEPOSIT_AMOUNT); // remoteChild.vault -> parent
        handler_recoverFailedRebalanceWithdraw(1, 1, 0, MIN_DEPOSIT_AMOUNT); // remoteChild.vault -> child
    }
}

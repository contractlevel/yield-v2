// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";
import {TargetFunctions} from "./TargetFunctions.t.sol";

contract CryticToFoundry is TargetFunctions, FoundryAsserts {
    function setUp() public override {
        setup();

        bytes4[] memory selectors = new bytes4[](15);
        selectors[0] = TargetFunctions.handler_deposit.selector;
        selectors[1] = TargetFunctions.handler_cancelDeposit.selector;
        selectors[2] = TargetFunctions.handler_closeEpoch.selector;
        selectors[3] = TargetFunctions.handler_claimShares.selector;
        selectors[4] = TargetFunctions.handler_withdraw.selector;
        selectors[5] = TargetFunctions.handler_cancelWithdraw.selector;
        selectors[6] = TargetFunctions.handler_claimAsset.selector;
        selectors[7] = TargetFunctions.handler_initiateRebalance.selector;
        selectors[8] = TargetFunctions.handler_executeRecovery.selector;
        selectors[9] = TargetFunctions.handler_forceCancelDeposit.selector;
        selectors[10] = TargetFunctions.handler_replaceActiveAdapterRegistryEntry.selector;
        selectors[11] = TargetFunctions.handler_depositFor.selector;
        selectors[12] = TargetFunctions.handler_withdrawFor.selector;
        selectors[13] = TargetFunctions.handler_claimSharesFor.selector;
        selectors[14] = TargetFunctions.handler_claimAssetFor.selector;

        targetSelector(FuzzSelector({addr: address(this), selectors: selectors}));
        targetContract(address(this));
    }

    function test_crytic() public {
        handler_deposit(0, MIN_DEPOSIT_AMOUNT);
        handler_cancelDeposit(0, MIN_DEPOSIT_AMOUNT);
        handler_withdraw(0, MIN_DEPOSIT_AMOUNT, MIN_DEPOSIT_AMOUNT);
        handler_cancelWithdraw(0, MIN_DEPOSIT_AMOUNT, MIN_DEPOSIT_AMOUNT);
        handler_closeEpoch(0);
        handler_claimShares(0, 0, MIN_DEPOSIT_AMOUNT);
        handler_claimAsset(0, 0, MIN_DEPOSIT_AMOUNT, MIN_DEPOSIT_AMOUNT);
        handler_initiateRebalance(0, 0, 0, MIN_DEPOSIT_AMOUNT);
        handler_executeRecovery(0, 0, 0, MIN_DEPOSIT_AMOUNT);
        handler_forceCancelDeposit(0, MIN_DEPOSIT_AMOUNT);
        handler_replaceActiveAdapterRegistryEntry();
        handler_depositFor(0, 1, MIN_DEPOSIT_AMOUNT);
        handler_withdrawFor(0, 1, MIN_DEPOSIT_AMOUNT, MIN_DEPOSIT_AMOUNT);
        handler_closeEpoch(0);
        handler_claimSharesFor(1, 0, 0, MIN_DEPOSIT_AMOUNT);
        handler_claimAssetFor(1, 0, 0, MIN_DEPOSIT_AMOUNT, MIN_DEPOSIT_AMOUNT);
    }
}

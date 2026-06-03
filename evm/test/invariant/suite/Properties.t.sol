// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BeforeAfter} from "./BeforeAfter.t.sol";
import {Asserts} from "@chimera/Asserts.sol";
import {Types} from "../../../src/libraries/Types.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console2} from "forge-std/console2.sol";

abstract contract Properties is BeforeAfter, Asserts {
    /*//////////////////////////////////////////////////////////////
                                  MISC
    //////////////////////////////////////////////////////////////*/
    function invariant_depositGhostMatchesOpenEpochTotal() public {
        uint256 currentEpochNonce = parent.vault.getEpochNonce();
        eq(
            parent.vault.getEpoch(currentEpochNonce).totalDepositAmount,
            ghost_totalDepositedByEpoch[currentEpochNonce],
            "deposit ghost does not match open epoch total"
        );
    }

    /*//////////////////////////////////////////////////////////////
                                SOLVENCY
    //////////////////////////////////////////////////////////////*/
    function invariant_SOLV_001_parentCoversClaimableWithdrawObligations() public {
        lte(
            ghost_claimableWithdrawObligation,
            IERC20(parent.vault.getUsdc()).balanceOf(address(parent.vault)),
            "SOLV-001: parent USDC balance does not cover claimable withdraw obligations"
        );
    }

    function invariant_SOLV_005_userRedemptionEntitlementCoversPrincipalNetOfFees() public {
        for (uint256 i; i < s_actors.length; ++i) {
            address actor = s_actors[i];
            uint256 principal = ghost_totalDepositedByActor[actor];
            uint256 feeBurden = ghost_feeBurdenByActor[actor];
            uint256 requiredValue = principal > feeBurden ? principal - feeBurden : 0;

            lte(
                requiredValue,
                _actorRedemptionEntitlement(actor) + _redemptionRoundingTolerance(),
                "SOLV-005: user redemption entitlement below principal net of fees"
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 EPOCH
    //////////////////////////////////////////////////////////////*/
    function invariant_EPOCH_001_currentEpochIsOpen() public {
        uint256 currentEpochNonce = parent.vault.getEpochNonce();
        t(
            parent.vault.getEpoch(currentEpochNonce).status == Types.EpochStatus.OPEN,
            "EPOCH-001: current epoch is not open"
        );
    }

    function invariant_EPOCH_008_depositRemainingCountersStayBounded() public {
        for (uint256 i; i < ghost_claimableEpochs.length; ++i) {
            uint256 epochNonce = ghost_claimableEpochs[i];
            Types.Epoch memory epoch = parent.vault.getEpoch(epochNonce);

            lte(
                epoch.remainingDepositClaimAmount,
                epoch.totalDepositAmount,
                "EPOCH-008: remaining deposit claims exceed total deposits"
            );
            lte(
                epoch.remainingShareMintAmount,
                ghost_totalShareMintedByEpoch[epochNonce],
                "EPOCH-008: remaining share mints exceed total share mints"
            );
        }
    }

    function invariant_EPOCH_009_depositRemainingCountersReachZeroTogether() public {
        for (uint256 i; i < ghost_claimableEpochs.length; ++i) {
            uint256 epochNonce = ghost_claimableEpochs[i];
            Types.Epoch memory epoch = parent.vault.getEpoch(epochNonce);
            bool depositCountersMatch =
                (epoch.remainingDepositClaimAmount == 0) == (epoch.remainingShareMintAmount == 0);

            if (!depositCountersMatch) {
                console2.log("EPOCH-009 failure epochNonce", epochNonce);
                console2.log("EPOCH-009 totalDepositAmount", epoch.totalDepositAmount);
                console2.log("EPOCH-009 remainingDepositClaimAmount", epoch.remainingDepositClaimAmount);
                console2.log("EPOCH-009 remainingShareMintAmount", epoch.remainingShareMintAmount);
                console2.log("EPOCH-009 pricePerShare", epoch.pricePerShare);
                console2.log("EPOCH-009 ghost totalShareMinted", ghost_totalShareMintedByEpoch[epochNonce]);
                console2.log("EPOCH-009 ghost claimable epochs", ghost_claimableEpochs.length);
            }

            t(depositCountersMatch, "EPOCH-009: deposit-side remaining counters did not reach zero together");
        }
    }

    function invariant_EPOCH_011_withdrawRemainingCountersStayBounded() public {
        for (uint256 i; i < ghost_claimableEpochs.length; ++i) {
            uint256 epochNonce = ghost_claimableEpochs[i];
            Types.Epoch memory epoch = parent.vault.getEpoch(epochNonce);

            lte(
                epoch.remainingShareBurnAmount,
                epoch.totalShareBurnAmount,
                "EPOCH-011: remaining share burns exceed total share burns"
            );
            lte(
                epoch.remainingWithdrawClaimAmount,
                epoch.totalWithdrawClaimAmount,
                "EPOCH-011: remaining withdraw claims exceed total withdraw claims"
            );
        }
    }

    function invariant_EPOCH_012_noWithdrawClaimAmountAfterShareBurnsProcessed() public {
        for (uint256 i; i < ghost_claimableEpochs.length; ++i) {
            uint256 epochNonce = ghost_claimableEpochs[i];
            Types.Epoch memory epoch = parent.vault.getEpoch(epochNonce);

            t(
                epoch.remainingShareBurnAmount != 0 || epoch.remainingWithdrawClaimAmount == 0,
                "EPOCH-012: withdraw claim amount remains after all share burns processed"
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                               REBALANCE
    //////////////////////////////////////////////////////////////*/
    function invariant_REBAL_001_rebalanceStateIsValid() public {
        Types.Rebalance memory rebalance = parent.vault.getRebalance();

        t(
            rebalance.state == Types.RebalanceState.NONE || rebalance.state == Types.RebalanceState.REBALANCING,
            "REBAL-001: invalid rebalance state"
        );
    }

    function invariant_REBAL_004_pendingStrategyMatchesRebalanceState() public {
        Types.Rebalance memory rebalance = parent.vault.getRebalance();

        if (rebalance.state == Types.RebalanceState.NONE) {
            t(_strategyIsEmpty(rebalance.pendingStrategy), "REBAL-004: pending strategy set while not rebalancing");
        } else {
            t(!_strategyIsEmpty(rebalance.pendingStrategy), "REBAL-004: pending strategy missing while rebalancing");
        }
    }

    function invariant_REBAL_006_activeStrategyAdapterMatchesActiveChain() public {
        Types.Strategy memory activeStrategy = parent.vault.getRebalance().activeStrategy;

        if (activeStrategy.chainSelector == PARENT_CHAIN_SELECTOR) {
            _assertActiveStrategyAdapter(
                parent.vault.getActiveProtocolAdapter(),
                parent.adapterRegistry.getAdapter(activeStrategy.protocolId),
                "REBAL-006: parent active adapter mismatch"
            );
            t(child.vault.getActiveProtocolAdapter() == address(0), "REBAL-006: adapter set for child strategy");
            t(remoteChild.vault.getActiveProtocolAdapter() == address(0), "REBAL-006: adapter set for child strategy");
        } else if (activeStrategy.chainSelector == CHILD_CHAIN_SELECTOR) {
            _assertActiveStrategyAdapter(
                child.vault.getActiveProtocolAdapter(),
                child.adapterRegistry.getAdapter(activeStrategy.protocolId),
                "REBAL-006: child active adapter mismatch"
            );
            t(parent.vault.getActiveProtocolAdapter() == address(0), "REBAL-006: parent adapter set for child strategy");
            t(
                remoteChild.vault.getActiveProtocolAdapter() == address(0),
                "REBAL-006: adapter set for wrong child strategy"
            );
        } else if (activeStrategy.chainSelector == REMOTE_CHILD_CHAIN_SELECTOR) {
            _assertActiveStrategyAdapter(
                remoteChild.vault.getActiveProtocolAdapter(),
                remoteChild.adapterRegistry.getAdapter(activeStrategy.protocolId),
                "REBAL-006: remote child active adapter mismatch"
            );
            t(parent.vault.getActiveProtocolAdapter() == address(0), "REBAL-006: parent adapter set for child strategy");
            t(child.vault.getActiveProtocolAdapter() == address(0), "REBAL-006: adapter set for wrong child strategy");
        } else {
            t(false, "REBAL-006: active strategy chain is unsupported");
        }
    }

    function invariant_REBAL_008_noRebalanceWhilePreviousEpochExecuting() public {
        uint256 currentEpochNonce = parent.vault.getEpochNonce();
        if (currentEpochNonce <= 1) return;

        Types.Rebalance memory rebalance = parent.vault.getRebalance();
        Types.Epoch memory previousEpoch = parent.vault.getEpoch(currentEpochNonce - 1);

        t(
            rebalance.state != Types.RebalanceState.REBALANCING || previousEpoch.status != Types.EpochStatus.EXECUTING,
            "REBAL-008: rebalance active while previous epoch is executing"
        );
    }

    function _strategyIsEmpty(Types.Strategy memory strategy) internal pure returns (bool) {
        return strategy.protocolId == bytes32(0) && strategy.chainSelector == 0;
    }

    function _assertActiveStrategyAdapter(address activeAdapter, address expectedAdapter, string memory message)
        internal
    {
        t(expectedAdapter != address(0), "REBAL-006: active strategy has no registered adapter");
        t(activeAdapter == expectedAdapter, message);
    }

    function _redemptionRoundingTolerance() internal view returns (uint256) {
        return 1e6 + ghost_claimableEpochs.length + s_actors.length;
    }
}

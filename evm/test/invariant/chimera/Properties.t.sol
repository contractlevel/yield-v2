// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BeforeAfter} from "./BeforeAfter.t.sol";
import {Asserts} from "@chimera/Asserts.sol";
import {Types} from "../../../src/libraries/Types.sol";
import {BaseVault} from "../../../src/vaults/BaseVault.sol";
import {ChildVault} from "../../../src/vaults/ChildVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IProtocolAdapter} from "../../../src/interfaces/adapters/IProtocolAdapter.sol";

abstract contract Properties is BeforeAfter, Asserts {
    /*//////////////////////////////////////////////////////////////
                         THIRD-PARTY OPERATIONS
    //////////////////////////////////////////////////////////////*/
    function invariant_FOR_001_depositPositionsBelongToBeneficiaries() public {
        uint256 epochNonce = parent.vault.getEpochNonce();
        for (uint256 i; i < s_actors.length; ++i) {
            address beneficiary = s_actors[i];
            eq(
                parent.vault.getDepositAmount(beneficiary, epochNonce),
                ghost_depositedByActorByEpoch[beneficiary][epochNonce],
                "FOR-001: beneficiary deposit position differs from ghost"
            );
        }
    }

    function invariant_FOR_002_withdrawPositionsBelongToBeneficiaries() public {
        uint256 epochNonce = parent.vault.getEpochNonce();
        for (uint256 i; i < s_actors.length; ++i) {
            address beneficiary = s_actors[i];
            eq(
                parent.vault.getWithdrawShareBurnAmount(beneficiary, epochNonce),
                ghost_shareBurnedByActorByEpoch[beneficiary][epochNonce],
                "FOR-002: beneficiary withdraw position differs from ghost"
            );
        }
    }

    function invariant_FOR_007_thirdPartyFundingConservesModeledValue() public {
        eq(ghost_totalForGiftValueSent, ghost_totalForGiftValueReceived, "FOR-007: sent and received gift value differ");
    }

    function invariant_FOR_008_forClaimsPreserveShrinkingPoolAccounting() public {
        for (uint256 i; i < ghost_shareAccountingEpochs.length; ++i) {
            Types.Epoch memory epoch = parent.vault.getEpoch(ghost_shareAccountingEpochs[i]);
            t(
                (epoch.remainingDepositClaimAmount == 0) == (epoch.remainingShareMintAmount == 0),
                "FOR-008: deposit claim pools do not exhaust together"
            );
            t(
                epoch.remainingShareBurnAmount != 0 || epoch.remainingWithdrawClaimAmount == 0,
                "FOR-008: asset remains after withdraw pool exhaustion"
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                                  MISC
    //////////////////////////////////////////////////////////////*/
    function invariant_SOLV_006_depositGhostMatchesOpenEpochTotal() public {
        uint256 currentEpochNonce = parent.vault.getEpochNonce();
        eq(
            parent.vault.getEpoch(currentEpochNonce).totalDepositAmount,
            ghost_totalDepositedByEpoch[currentEpochNonce],
            "SOLV-006: deposit ghost does not match open epoch total"
        );
    }

    /*//////////////////////////////////////////////////////////////
                                SOLVENCY
    //////////////////////////////////////////////////////////////*/
    function invariant_SOLV_001_parentCoversClaimableWithdrawObligations() public {
        lte(
            ghost_claimableWithdrawObligation,
            IERC20(parent.vault.getAsset()).balanceOf(address(parent.vault)),
            "SOLV-001: parent USDC balance does not cover claimable withdraw obligations"
        );
    }

    function invariant_SOLV_003_parentCoversAccountedShareEscrow() public {
        uint256 accountedEscrow = parent.vault.getEpoch(parent.vault.getEpochNonce()).totalShareBurnAmount;
        for (uint256 i; i < ghost_shareAccountingEpochs.length; ++i) {
            accountedEscrow += parent.vault.getEpoch(ghost_shareAccountingEpochs[i]).remainingShareBurnAmount;
        }

        lte(
            accountedEscrow,
            parent.share.balanceOf(address(parent.vault)),
            "SOLV-003: parent share balance does not cover accounted escrow"
        );
    }

    function invariant_EPOCH_017_openEpochShareBurnDoesNotExceedAuthoritativeShares() public {
        uint256 epochNonce = parent.vault.getEpochNonce();
        lte(
            parent.vault.getEpoch(epochNonce).totalShareBurnAmount,
            parent.vault.getTotalShares(),
            "EPOCH-017: open epoch share burns exceed authoritative shares"
        );
    }

    /// @dev The protocol mocks do not model involuntary strategy loss. This fixture-only
    ///      conservation check is not evidence of production principal protection.
    function invariant_SOLV_005_losslessFixtureEntitlementCoversPrincipalNetOfFees() public {
        if (_recoveryModeExists()) return;

        for (uint256 i; i < s_actors.length; ++i) {
            address actor = s_actors[i];
            // A share-funded gift transfers a pro-rata claim whose asset value continues to move with
            // fees and TVL. The fixed principal ghost has no sound per-user cost basis after that
            // transfer; FOR-007 separately proves exact aggregate gift conservation.
            if (ghost_forGiftParticipant[actor]) continue;

            uint256 principal = ghost_totalDepositedByActor[actor];
            uint256 feeBurden = ghost_feeBurdenByActor[actor];
            uint256 requiredValue = principal > feeBurden ? principal - feeBurden : 0;
            uint256 roundingBurden = _depositRoundingBurden(actor);
            requiredValue = requiredValue > roundingBurden ? requiredValue - roundingBurden : 0;

            lte(
                requiredValue,
                _actorRedemptionEntitlement(actor) + _redemptionRoundingTolerance(),
                "SOLV-005: user redemption entitlement below principal net of fees"
            );
        }
    }

    function invariant_SOLV_002_REC_007_recoveryPreservesSolvency() public {
        lte(
            ghost_claimableWithdrawObligation,
            IERC20(parent.vault.getAsset()).balanceOf(address(parent.vault)),
            "SOLV-002/REC-007: recovery broke withdraw solvency"
        );

        _assertPendingCcipSendRecoveryIsCollateralized(child.vault);
        _assertPendingCcipSendRecoveryIsCollateralized(remoteChild.vault);
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

    function invariant_EPOCH_002_epochTransitionsAreValid() public {
        uint256 currentEpochNonce = parent.vault.getEpochNonce();

        for (uint256 i; i < ghost_claimableEpochs.length; ++i) {
            t(
                parent.vault.getEpoch(ghost_claimableEpochs[i]).status == Types.EpochStatus.CLAIMABLE,
                "EPOCH-002: epoch transitioned out of CLAIMABLE"
            );
        }

        if (currentEpochNonce > 1) {
            Types.EpochStatus prevStatus = parent.vault.getEpoch(currentEpochNonce - 1).status;
            t(
                prevStatus == Types.EpochStatus.CLAIMABLE || prevStatus == Types.EpochStatus.EXECUTING,
                "EPOCH-002: previous epoch in invalid state"
            );
        }
    }

    function invariant_EPOCH_005_closedEpochTotalsAreFrozen() public {
        for (uint256 i; i < ghost_shareAccountingEpochs.length; ++i) {
            uint256 epochNonce = ghost_shareAccountingEpochs[i];
            Types.Epoch memory epoch = parent.vault.getEpoch(epochNonce);
            eq(
                epoch.totalDepositAmount,
                ghost_totalDepositedByEpoch[epochNonce],
                "EPOCH-005: deposit amount changed in closed epoch"
            );
            eq(
                epoch.totalShareBurnAmount,
                ghost_totalShareBurnedByEpoch[epochNonce],
                "EPOCH-005: share burn amount changed in closed epoch"
            );
        }
    }

    function invariant_EPOCH_008_depositRemainingCountersStayBounded() public {
        for (uint256 i; i < ghost_shareAccountingEpochs.length; ++i) {
            uint256 epochNonce = ghost_shareAccountingEpochs[i];
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

    function invariant_EPOCH_008_depositRemainingCountersReachZeroTogether() public {
        for (uint256 i; i < ghost_shareAccountingEpochs.length; ++i) {
            uint256 epochNonce = ghost_shareAccountingEpochs[i];
            Types.Epoch memory epoch = parent.vault.getEpoch(epochNonce);
            bool depositCountersMatch =
                (epoch.remainingDepositClaimAmount == 0) == (epoch.remainingShareMintAmount == 0);

            t(depositCountersMatch, "EPOCH-008: deposit-side remaining counters did not reach zero together");
        }
    }

    function invariant_EPOCH_011_withdrawRemainingCountersStayBounded() public {
        for (uint256 i; i < ghost_shareAccountingEpochs.length; ++i) {
            uint256 epochNonce = ghost_shareAccountingEpochs[i];
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

    function invariant_EPOCH_013_noWithdrawClaimAmountAfterShareBurnsProcessed() public {
        for (uint256 i; i < ghost_shareAccountingEpochs.length; ++i) {
            uint256 epochNonce = ghost_shareAccountingEpochs[i];
            Types.Epoch memory epoch = parent.vault.getEpoch(epochNonce);

            t(
                epoch.remainingShareBurnAmount != 0 || epoch.remainingWithdrawClaimAmount == 0,
                "EPOCH-013: withdraw claim amount remains after all share burns processed"
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                            SHARE / FEES
    //////////////////////////////////////////////////////////////*/
    function invariant_SHARE_003_tokenSupplyMatchesAuthoritativeLazySettlementLedger() public {
        eq(
            parent.share.totalSupply(),
            _expectedShareTokenSupply(),
            "SHARE-003: token supply does not match authoritative shares adjusted for lazy settlement"
        );
    }

    function invariant_FEE_001_allManagementFeeSharesMintToTreasury() public {
        uint256 totalUserSharesMinted;
        uint256 totalSharesBurned;
        for (uint256 i; i < ghost_claimableEpochs.length; ++i) {
            uint256 epochNonce = ghost_claimableEpochs[i];
            totalUserSharesMinted += ghost_totalShareMintedByEpoch[epochNonce];
            totalSharesBurned += parent.vault.getEpoch(epochNonce).totalShareBurnAmount;
        }

        // An EXECUTING epoch's burns have already reduced getTotalShares() but it is not yet in
        // ghost_claimableEpochs. Include its burns and user-deposit mints so the formula balances.
        uint256 currentNonce = parent.vault.getEpochNonce();
        if (currentNonce > 1) {
            Types.Epoch memory prevEpoch = parent.vault.getEpoch(currentNonce - 1);
            if (prevEpoch.status == Types.EpochStatus.EXECUTING) {
                totalSharesBurned += prevEpoch.totalShareBurnAmount;
                totalUserSharesMinted += prevEpoch.remainingShareMintAmount;
            }
        }

        uint256 expectedTreasuryShares = parent.vault.getTotalShares() + totalSharesBurned - totalUserSharesMinted;
        eq(
            parent.share.balanceOf(parent.vault.getTreasury()),
            expectedTreasuryShares,
            "FEE-001: treasury share balance doesn't match total management fee shares minted"
        );
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
        Types.Rebalance memory rebalance = parent.vault.getRebalance();
        if (rebalance.state == Types.RebalanceState.REBALANCING) return;

        Types.Strategy memory activeStrategy = rebalance.activeStrategy;

        if (activeStrategy.chainSelector == PARENT_CHAIN_SELECTOR) {
            _assertActiveStrategyAdapter(
                parent.vault.getActiveProtocolAdapter(),
                address(parent.vault),
                "REBAL-006: parent active adapter mismatch"
            );
            t(child.vault.getActiveProtocolAdapter() == address(0), "REBAL-006: adapter set for child strategy");
            t(remoteChild.vault.getActiveProtocolAdapter() == address(0), "REBAL-006: adapter set for child strategy");
        } else if (activeStrategy.chainSelector == CHILD_CHAIN_SELECTOR) {
            _assertActiveStrategyAdapter(
                child.vault.getActiveProtocolAdapter(), address(child.vault), "REBAL-006: child active adapter mismatch"
            );
            t(parent.vault.getActiveProtocolAdapter() == address(0), "REBAL-006: parent adapter set for child strategy");
            t(
                remoteChild.vault.getActiveProtocolAdapter() == address(0),
                "REBAL-006: adapter set for wrong child strategy"
            );
        } else if (activeStrategy.chainSelector == REMOTE_CHILD_CHAIN_SELECTOR) {
            _assertActiveStrategyAdapter(
                remoteChild.vault.getActiveProtocolAdapter(),
                address(remoteChild.vault),
                "REBAL-006: remote child active adapter mismatch"
            );
            t(parent.vault.getActiveProtocolAdapter() == address(0), "REBAL-006: parent adapter set for child strategy");
            t(child.vault.getActiveProtocolAdapter() == address(0), "REBAL-006: adapter set for wrong child strategy");
        } else {
            t(false, "REBAL-006: active strategy chain is unsupported");
        }
    }

    function invariant_REBAL_009_noRebalanceWhilePreviousEpochExecuting() public {
        uint256 currentEpochNonce = parent.vault.getEpochNonce();
        if (currentEpochNonce <= 1) return;

        Types.Rebalance memory rebalance = parent.vault.getRebalance();
        Types.Epoch memory previousEpoch = parent.vault.getEpoch(currentEpochNonce - 1);

        t(
            rebalance.state != Types.RebalanceState.REBALANCING || previousEpoch.status != Types.EpochStatus.EXECUTING,
            "REBAL-009: rebalance active while previous epoch is executing"
        );
    }

    /*//////////////////////////////////////////////////////////////
                                RECOVERY
    //////////////////////////////////////////////////////////////*/
    function invariant_REC_002_recoverySentinelsAreConsistent() public {
        _assertRebalanceDepositRecoverySentinel(parent.vault);
        _assertChildRecoverySentinels(child.vault);
        _assertChildRecoverySentinels(remoteChild.vault);
    }

    function invariant_REC_010_onlyOneConfiguredVaultRecoveryModeIsPending() public {
        lte(_recoveryModeCount(), 1, "REC-010: more than one configured vault recovery mode is pending");
    }

    function invariant_SOLV_004_pendingChildCcipSendRecoveryIsCollateralized() public {
        _assertPendingCcipSendRecoveryIsCollateralized(child.vault);
        _assertPendingCcipSendRecoveryIsCollateralized(remoteChild.vault);
    }

    function invariant_CCIP_006_pendingChildCcipSendRecoveryIsCollateralized() public {
        _assertPendingCcipSendRecoveryIsCollateralized(child.vault);
        _assertPendingCcipSendRecoveryIsCollateralized(remoteChild.vault);
    }

    /*//////////////////////////////////////////////////////////////
                                ADAPTERS
    //////////////////////////////////////////////////////////////*/
    function invariant_REBAL_008_vaultTvlEquationsAreExact() public {
        _assertParentTvlEquation(parent.vault);
        _assertChildTvlEquation(child.vault);
        _assertChildTvlEquation(remoteChild.vault);
    }

    function invariant_REC_006_ADAPTER_005_recoveryAttributionAndPhaseAwareTvlAreExact() public {
        _assertParentTvlEquation(parent.vault);
        _assertChildTvlEquation(child.vault);
        _assertChildTvlEquation(remoteChild.vault);
    }

    function invariant_CFG_002_treasuryIsNonzero() public {
        t(parent.vault.getTreasury() != address(0), "CFG-002: treasury is zero");
    }

    function invariant_NONCE_009_parentNoncesAreStrictlyPositive() public {
        t(parent.vault.getEpochNonce() != 0, "NONCE-009: parent epoch nonce is zero");
        t(parent.vault.getRebalance().nonce != 0, "NONCE-009: parent rebalance nonce is zero");
    }

    function invariant_NONCE_006_pendingRecoveryNonceMatchesChildHighWaterMark() public {
        _assertPendingRecoveryNonce(child.vault);
        _assertPendingRecoveryNonce(remoteChild.vault);
    }

    function invariant_NONCE_011_parentRebalanceUsesCurrentNonce() public {
        Types.Rebalance memory rebalance = parent.vault.getRebalance();
        if (rebalance.state != Types.RebalanceState.REBALANCING) return;

        Types.RebalanceDepositRecovery memory parentRecovery = parent.vault.getRebalanceDepositRecovery();
        if (_rebalanceDepositRecoveryPending(parentRecovery)) {
            eq(parentRecovery.rebalanceNonce, rebalance.nonce, "NONCE-011: parent recovery nonce mismatch");
        }
    }

    function _recoveryModeExists() internal view returns (bool) {
        return _recoveryModeCount() != 0;
    }

    function _recoveryModeCount() internal view returns (uint256 count) {
        if (_rebalanceDepositRecoveryPending(parent.vault.getRebalanceDepositRecovery())) ++count;
        count += _childRecoveryModeCount(child.vault);
        count += _childRecoveryModeCount(remoteChild.vault);
    }

    function _childRecoveryModeCount(ChildVault vault) internal view returns (uint256 count) {
        if (_rebalanceDepositRecoveryPending(vault.getRebalanceDepositRecovery())) ++count;
        if (_epochRecoveryPending(vault.getEpochDepositRecovery())) ++count;
        if (_epochRecoveryPending(vault.getEpochWithdrawRecovery())) ++count;
        if (_rebalanceWithdrawRecoveryPending(vault.getRebalanceWithdrawRecovery())) ++count;
        if (_ccipSendRecoveryPending(vault.getCcipSendRecovery())) ++count;
    }

    function _assertChildRecoverySentinels(ChildVault vault) internal {
        Types.RecoveryMode mode = vault.getRecoveryMode();
        uint256 matchingPayloads;
        if (
            mode == Types.RecoveryMode.REBALANCE_DEPOSIT
                && _rebalanceDepositRecoveryPending(vault.getRebalanceDepositRecovery())
        ) ++matchingPayloads;
        if (mode == Types.RecoveryMode.EPOCH_DEPOSIT && _epochRecoveryPending(vault.getEpochDepositRecovery())) {
            ++matchingPayloads;
        }
        if (mode == Types.RecoveryMode.EPOCH_WITHDRAW && _epochRecoveryPending(vault.getEpochWithdrawRecovery())) {
            ++matchingPayloads;
        }
        if (
            mode == Types.RecoveryMode.REBALANCE_WITHDRAW
                && _rebalanceWithdrawRecoveryPending(vault.getRebalanceWithdrawRecovery())
        ) ++matchingPayloads;
        if (mode == Types.RecoveryMode.CCIP_SEND && _ccipSendRecoveryPending(vault.getCcipSendRecovery())) {
            ++matchingPayloads;
        }
        eq(matchingPayloads, mode == Types.RecoveryMode.NONE ? 0 : 1, "REC-002: mode does not match payload");
        eq(
            _childRecoveryModeCount(vault),
            mode == Types.RecoveryMode.NONE ? 0 : 1,
            "REC-002: payloads are not exclusive"
        );

        _assertRebalanceDepositRecoverySentinel(vault);
        _assertEpochRecoverySentinel(vault.getEpochDepositRecovery(), "REC-002: epoch deposit recovery");
        _assertEpochRecoverySentinel(vault.getEpochWithdrawRecovery(), "REC-002: epoch withdraw recovery");
        _assertRebalanceWithdrawRecoverySentinel(vault.getRebalanceWithdrawRecovery());
        _assertCcipSendRecoverySentinel(vault.getCcipSendRecovery());
    }

    function _assertRebalanceDepositRecoverySentinel(BaseVault vault) internal {
        Types.RebalanceDepositRecovery memory recovery = vault.getRebalanceDepositRecovery();
        Types.RecoveryMode mode = vault.getRecoveryMode();

        if (_rebalanceDepositRecoveryPending(recovery)) {
            t(mode == Types.RecoveryMode.REBALANCE_DEPOSIT, "REC-002: rebalance deposit mode mismatch");
            t(recovery.amount != 0, "REC-002: rebalance deposit recovery amount missing");
        } else {
            t(mode != Types.RecoveryMode.REBALANCE_DEPOSIT, "REC-002: rebalance deposit mode has no payload");
            eq(recovery.rebalanceNonce, 0, "REC-002: cleared rebalance deposit recovery nonce set");
            eq(recovery.amount, 0, "REC-002: cleared rebalance deposit recovery amount set");
        }
    }

    function _assertEpochRecoverySentinel(Types.EpochRecovery memory recovery, string memory label) internal {
        if (_epochRecoveryPending(recovery)) {
            t(recovery.epochNonce != 0, label);
        } else {
            eq(recovery.epochNonce, 0, label);
        }
    }

    function _assertRebalanceWithdrawRecoverySentinel(Types.RebalanceWithdrawRecovery memory recovery) internal {
        if (_rebalanceWithdrawRecoveryPending(recovery)) {
            t(recovery.strategy.protocolId != bytes32(0), "REC-002: rebalance withdraw recovery protocol missing");
        } else {
            eq(recovery.rebalanceNonce, 0, "REC-002: cleared rebalance withdraw recovery nonce set");
            t(recovery.strategy.protocolId == bytes32(0), "REC-002: cleared rebalance withdraw recovery protocol set");
        }
    }

    function _assertCcipSendRecoverySentinel(Types.CcipSendRecovery memory recovery) internal {
        if (_ccipSendRecoveryPending(recovery)) {
            t(recovery.ccipTxType != Types.CcipTx.EPOCH_NET_DEPOSIT, "REC-002: invalid child CCIP recovery tx type");
            t(recovery.destinationChainSelector != 0, "REC-002: CCIP recovery destination missing");
            t(recovery.nonce != 0, "REC-002: CCIP recovery nonce missing");
            if (recovery.ccipTxType == Types.CcipTx.REBALANCE) {
                t(recovery.protocolId != bytes32(0), "REC-002: CCIP rebalance recovery protocol id missing");
            }
        } else {
            eq(uint256(recovery.ccipTxType), 0, "REC-002: cleared CCIP recovery tx type set");
            eq(uint256(recovery.destinationChainSelector), 0, "REC-002: cleared CCIP recovery destination set");
            eq(recovery.nonce, 0, "REC-002: cleared CCIP recovery nonce set");
            t(recovery.protocolId == bytes32(0), "REC-002: cleared CCIP recovery protocol id set");
        }
    }

    function _assertPendingCcipSendRecoveryIsCollateralized(ChildVault vault) internal {
        Types.CcipSendRecovery memory recovery = vault.getCcipSendRecovery();
        if (!_ccipSendRecoveryPending(recovery)) return;

        lte(
            recovery.amount,
            IERC20(parent.vault.getAsset()).balanceOf(address(vault)),
            "SOLV-004: pending child CCIP send recovery is not collateralized"
        );
    }

    function _assertPendingRecoveryNonce(ChildVault vault) internal {
        Types.EpochRecovery memory epochDeposit = vault.getEpochDepositRecovery();
        Types.EpochRecovery memory epochWithdraw = vault.getEpochWithdrawRecovery();
        Types.RebalanceDepositRecovery memory rebalanceDeposit = vault.getRebalanceDepositRecovery();
        Types.RebalanceWithdrawRecovery memory rebalanceWithdraw = vault.getRebalanceWithdrawRecovery();
        Types.CcipSendRecovery memory ccipSend = vault.getCcipSendRecovery();

        if (_epochRecoveryPending(epochDeposit)) {
            eq(epochDeposit.epochNonce, vault.getLastHandledEpochNonce(), "NONCE-006: epoch deposit nonce mismatch");
        }
        if (_epochRecoveryPending(epochWithdraw)) {
            eq(epochWithdraw.epochNonce, vault.getLastHandledEpochNonce(), "NONCE-006: epoch withdraw nonce mismatch");
        }
        if (_rebalanceDepositRecoveryPending(rebalanceDeposit)) {
            eq(
                rebalanceDeposit.rebalanceNonce,
                vault.getLastHandledRebalanceNonce(),
                "NONCE-006: rebalance deposit nonce mismatch"
            );
        }
        if (_rebalanceWithdrawRecoveryPending(rebalanceWithdraw)) {
            eq(
                rebalanceWithdraw.rebalanceNonce,
                vault.getLastHandledRebalanceNonce(),
                "NONCE-006: rebalance withdraw nonce mismatch"
            );
        }
        if (_ccipSendRecoveryPending(ccipSend)) {
            uint256 highWaterMark = ccipSend.ccipTxType == Types.CcipTx.REBALANCE
                ? vault.getLastHandledRebalanceNonce()
                : vault.getLastHandledEpochNonce();
            eq(ccipSend.nonce, highWaterMark, "NONCE-006: CCIP send nonce mismatch");
        }
    }

    function _expectedShareTokenSupply() internal view returns (uint256 supply) {
        uint256 lazyShareMints;
        uint256 lazyShareBurns;

        for (uint256 i; i < ghost_shareAccountingEpochs.length; ++i) {
            Types.Epoch memory epoch = parent.vault.getEpoch(ghost_shareAccountingEpochs[i]);
            lazyShareMints += epoch.remainingShareMintAmount;
            lazyShareBurns += epoch.remainingShareBurnAmount;
        }

        supply = parent.vault.getTotalShares() + lazyShareBurns - lazyShareMints;
    }

    function _assertParentTvlEquation(BaseVault vault) internal {
        address adapter = vault.getActiveProtocolAdapter();
        uint256 expectedTvl =
            adapter == address(0) ? 0 : IProtocolAdapter(adapter).getTVL() + vault.getRebalanceDepositRecovery().amount;
        eq(vault.getTVL(), expectedTvl, "REBAL-008/REC-006/ADAPTER-005: parent TVL equation mismatch");
    }

    function _assertChildTvlEquation(ChildVault vault) internal {
        address adapter = vault.getActiveProtocolAdapter();
        uint256 expectedTvl = vault.getCcipSendRecovery().amount;
        if (adapter != address(0)) {
            expectedTvl += IProtocolAdapter(adapter).getTVL() + vault.getEpochDepositRecovery().amount
            + vault.getRebalanceDepositRecovery().amount;
        }
        eq(vault.getTVL(), expectedTvl, "REBAL-008/REC-006/ADAPTER-005: child TVL equation mismatch");
    }

    function _epochRecoveryPending(Types.EpochRecovery memory recovery) internal pure returns (bool) {
        return recovery.amount != 0;
    }

    function _rebalanceDepositRecoveryPending(Types.RebalanceDepositRecovery memory recovery)
        internal
        pure
        returns (bool)
    {
        return recovery.amount != 0;
    }

    function _rebalanceWithdrawRecoveryPending(Types.RebalanceWithdrawRecovery memory recovery)
        internal
        pure
        returns (bool)
    {
        return recovery.strategy.chainSelector != 0;
    }

    function _ccipSendRecoveryPending(Types.CcipSendRecovery memory recovery) internal pure returns (bool) {
        return recovery.amount != 0;
    }

    function _strategyIsEmpty(Types.Strategy memory strategy) internal pure returns (bool) {
        return strategy.protocolId == bytes32(0) && strategy.chainSelector == 0;
    }

    function _assertActiveStrategyAdapter(address activeAdapter, address expectedVault, string memory message)
        internal
    {
        t(activeAdapter != address(0), message);
        t(IProtocolAdapter(activeAdapter).getVault() == expectedVault, "REBAL-006: active adapter bound to wrong vault");
    }

    function _redemptionRoundingTolerance() internal view returns (uint256) {
        return 1e6 + ghost_claimableEpochs.length + s_actors.length;
    }
}

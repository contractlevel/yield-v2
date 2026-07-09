// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BeforeAfter} from "./BeforeAfter.t.sol";
import {Asserts} from "@chimera/Asserts.sol";
import {Types} from "../../../src/libraries/Types.sol";
import {BaseVault} from "../../../src/vaults/BaseVault.sol";
import {ChildVault} from "../../../src/vaults/ChildVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
            IERC20(parent.vault.getAsset()).balanceOf(address(parent.vault)),
            "SOLV-001: parent USDC balance does not cover claimable withdraw obligations"
        );
    }

    function invariant_SOLV_005_userRedemptionEntitlementCoversPrincipalNetOfFees() public {
        if (_recoveryModeExists()) return;

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
        for (uint256 i; i < ghost_claimableEpochs.length; ++i) {
            uint256 epochNonce = ghost_claimableEpochs[i];
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

    function invariant_EPOCH_007_depositRemainingCountersAreMonotonicallyNonIncreasing() public {
        for (uint256 i; i < ghost_claimableEpochs.length; ++i) {
            uint256 epochNonce = ghost_claimableEpochs[i];
            Types.Epoch memory epoch = parent.vault.getEpoch(epochNonce);
            lte(
                epoch.remainingDepositClaimAmount,
                ghost_maxRemainingDepositClaimAmountByEpoch[epochNonce],
                "EPOCH-007: remaining deposit claims increased"
            );
            lte(
                epoch.remainingShareMintAmount,
                ghost_maxRemainingShareMintAmountByEpoch[epochNonce],
                "EPOCH-007: remaining share mints increased"
            );
        }
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

            t(depositCountersMatch, "EPOCH-009: deposit-side remaining counters did not reach zero together");
        }
    }

    function invariant_EPOCH_010_withdrawRemainingCountersAreMonotonicallyNonIncreasing() public {
        for (uint256 i; i < ghost_claimableEpochs.length; ++i) {
            uint256 epochNonce = ghost_claimableEpochs[i];
            Types.Epoch memory epoch = parent.vault.getEpoch(epochNonce);
            lte(
                epoch.remainingShareBurnAmount,
                ghost_maxRemainingShareBurnAmountByEpoch[epochNonce],
                "EPOCH-010: remaining share burns increased"
            );
            lte(
                epoch.remainingWithdrawClaimAmount,
                ghost_maxRemainingWithdrawClaimAmountByEpoch[epochNonce],
                "EPOCH-010: remaining withdraw claims increased"
            );
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
                            SHARE / FEES
    //////////////////////////////////////////////////////////////*/
    function invariant_SHARE_001_totalSupplyEqualsAuthoritativeSharesPlusLazyBurns() public {
        eq(
            parent.share.totalSupply(),
            _expectedShareTokenSupply(),
            "SHARE-001: token supply does not match authoritative shares adjusted for lazy settlement"
        );
    }

    function invariant_SHARE_005_allFeeSharesMintToTreasury() public {
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
            "SHARE-005: treasury share balance doesn't match total fee shares minted"
        );
    }

    function invariant_FEE_003_performanceFeeHighWaterMarkIsMonotonicallyNonDecreasing() public {
        lte(
            ghost_maxPerformanceFeeHighWaterMark,
            parent.vault.getPerformanceFeeHighWaterMark(),
            "FEE-003: performance fee high-water mark decreased from historical max"
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

    /*//////////////////////////////////////////////////////////////
                                RECOVERY
    //////////////////////////////////////////////////////////////*/
    function invariant_REC_002_recoverySentinelsAreConsistent() public {
        _assertRebalanceDepositRecoverySentinel(parent.vault);
        _assertChildRecoverySentinels(child.vault);
        _assertChildRecoverySentinels(remoteChild.vault);
    }

    function invariant_REC_004_childEpochRecoveriesAreMutuallyExclusive() public {
        _assertChildEpochRecoveryMutex(child.vault);
        _assertChildEpochRecoveryMutex(remoteChild.vault);
    }

    function invariant_REC_007_rebalanceDepositAndCcipSendRecoveriesAreMutuallyExclusive() public {
        _assertRebalanceDepositAndCcipSendMutex(child.vault);
        _assertRebalanceDepositAndCcipSendMutex(remoteChild.vault);
    }

    function invariant_REC_009_onlyOneGlobalRecoveryModeIsPending() public {
        lte(_recoveryModeCount(), 1, "REC-009: more than one recovery mode is pending");
    }

    function invariant_CCIP_005b_pendingChildCcipSendRecoveryIsCollateralized() public {
        _assertPendingCcipSendRecoveryIsCollateralized(child.vault);
        _assertPendingCcipSendRecoveryIsCollateralized(remoteChild.vault);
    }

    /*//////////////////////////////////////////////////////////////
                                ADAPTERS
    //////////////////////////////////////////////////////////////*/
    function invariant_ADAPTER_004_nonActiveStrategyChainsReportZeroTvl() public {
        uint64 activeChainSelector = parent.vault.getRebalance().activeStrategy.chainSelector;

        _assertNonActiveTvlIsZero(parent.vault, PARENT_CHAIN_SELECTOR, activeChainSelector);
        _assertNonActiveTvlIsZero(child.vault, CHILD_CHAIN_SELECTOR, activeChainSelector);
        _assertNonActiveTvlIsZero(remoteChild.vault, REMOTE_CHILD_CHAIN_SELECTOR, activeChainSelector);
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
        _assertRebalanceDepositRecoverySentinel(vault);
        _assertEpochRecoverySentinel(vault.getEpochDepositRecovery(), "REC-002: epoch deposit recovery");
        _assertEpochRecoverySentinel(vault.getEpochWithdrawRecovery(), "REC-002: epoch withdraw recovery");
        _assertRebalanceWithdrawRecoverySentinel(vault.getRebalanceWithdrawRecovery());
        _assertCcipSendRecoverySentinel(vault.getCcipSendRecovery());
    }

    function _assertRebalanceDepositRecoverySentinel(BaseVault vault) internal {
        Types.RebalanceDepositRecovery memory recovery = vault.getRebalanceDepositRecovery();

        if (_rebalanceDepositRecoveryPending(recovery)) {
            t(recovery.amount != 0, "REC-002: rebalance deposit recovery amount missing");
        } else {
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

    function _assertChildEpochRecoveryMutex(ChildVault vault) internal {
        uint256 pendingEpochRecoveries;
        if (_epochRecoveryPending(vault.getEpochDepositRecovery())) ++pendingEpochRecoveries;
        if (_epochRecoveryPending(vault.getEpochWithdrawRecovery())) ++pendingEpochRecoveries;

        lte(pendingEpochRecoveries, 1, "REC-004: child epoch recoveries are both pending");
    }

    function _assertRebalanceDepositAndCcipSendMutex(ChildVault vault) internal {
        uint256 pendingRecoveries;
        if (_rebalanceDepositRecoveryPending(vault.getRebalanceDepositRecovery())) ++pendingRecoveries;
        if (_ccipSendRecoveryPending(vault.getCcipSendRecovery())) ++pendingRecoveries;

        lte(pendingRecoveries, 1, "REC-007: rebalance deposit and CCIP send recoveries are both pending");
    }

    function _assertPendingCcipSendRecoveryIsCollateralized(ChildVault vault) internal {
        Types.CcipSendRecovery memory recovery = vault.getCcipSendRecovery();
        if (!_ccipSendRecoveryPending(recovery)) return;

        lte(
            recovery.amount,
            IERC20(parent.vault.getAsset()).balanceOf(address(vault)),
            "CCIP-005b: pending child CCIP send recovery is not collateralized"
        );
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

    function _assertNonActiveTvlIsZero(BaseVault vault, uint64 vaultChainSelector, uint64 activeChainSelector)
        internal
    {
        if (vaultChainSelector == activeChainSelector) return;

        uint256 expectedTvl;
        Types.RebalanceDepositRecovery memory rebalanceDepositRecovery = vault.getRebalanceDepositRecovery();
        if (_rebalanceDepositRecoveryPending(rebalanceDepositRecovery)) {
            expectedTvl += rebalanceDepositRecovery.amount;
        }

        if (vaultChainSelector != PARENT_CHAIN_SELECTOR) {
            ChildVault childVault = ChildVault(address(vault));
            Types.EpochRecovery memory epochDepositRecovery = childVault.getEpochDepositRecovery();
            if (_epochRecoveryPending(epochDepositRecovery)) {
                expectedTvl += epochDepositRecovery.amount;
            }
        }

        eq(vault.getTVL(), expectedTvl, "ADAPTER-004: non-active strategy chain reports unexpected TVL");
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

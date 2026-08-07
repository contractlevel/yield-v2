using MockUSDC as asset;
using MockLINK as link;
using MockYieldcoinShare as share;

/// Verification of ParentVault-specific behavior
/// @author @contractlevel
/// @notice ParentVault is the single entry/exit point for users; it owns epoch, rebalance, and fee state.
/// @dev Verified directly against the production ParentVault ABI. Function-specific behavior and
///      initialization establishment are verified separately by ParentVault.rules.spec against
///      ParentVaultHarness.

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    function getEpoch(uint256) external returns (Types.Epoch) envfree;
    function getEpochNonce() external returns (uint256) envfree;
    function getTotalShares() external returns (uint256) envfree;
    function getDepositAmount(address, uint256) external returns (uint256) envfree;
    function getWithdrawShareBurnAmount(address, uint256) external returns (uint256) envfree;
    function getPerformanceFeeHighWaterMark() external returns (uint256) envfree;
    function getTreasury() external returns (address) envfree;
    function getAsset() external returns (address) envfree;
    function getRecoveryMode() external returns (Types.RecoveryMode) envfree;
    function getRebalanceDepositRecovery() external returns (Types.RebalanceDepositRecovery) envfree;

    function asset.balanceOf(address) external returns (uint256) envfree;
    function share.balanceOf(address) external returns (uint256) envfree;
    function share.totalSupply() external returns (uint256) envfree;

    /*//////////////////////////////////////////////////////////////
                         DISPATCHER SUMMARIES
    //////////////////////////////////////////////////////////////*/
    function _.transfer(address, uint256) external => DISPATCHER(true);
    function _.transferFrom(address, address, uint256) external => DISPATCHER(true);
    function _.balanceOf(address) external => DISPATCHER(true);
    function _.approve(address, uint256) external => DISPATCHER(true);
    function _.forceApprove(address, uint256) external => DISPATCHER(true);
    function _.mint(address, uint256) external => DISPATCHER(true);
    function _.burn(address, uint256) external => DISPATCHER(true);
    function _.deposit(uint256) external => DISPATCHER(true);
    function _.withdraw(uint256) external => DISPATCHER(true);
    function _.getTVL() external => DISPATCHER(true);
    function _.getVault() external => DISPATCHER(true);
    function _.getAsset() external => DISPATCHER(true);
    function _.getAdapter(bytes32) external => DISPATCHER(true);
    function _.getFee(uint64, Client.EVM2AnyMessage) external => DISPATCHER(true);
    function _.ccipSend(uint64, Client.EVM2AnyMessage) external => DISPATCHER(true);
    function _.attach() external => DISPATCHER(true);
    function _.detach() external => DISPATCHER(true);
    function _.run(IPolicyEngine.Payload) external => DISPATCHER(true);
}

/*//////////////////////////////////////////////////////////////
                          DEFINITIONS
//////////////////////////////////////////////////////////////*/

/// @notice External self-call boundaries whose arguments are constructed only by ParentVault.
/// @dev Arbitrary-method verification would otherwise permit msg.sender == ParentVault with
///      attacker-selected adapter arguments, which no production transaction can construct.
definition isSelfCallBoundary(method f) returns bool =
    f.selector == sig:tryDepositToAdapter(address,uint256).selector;

/// @notice Production-callable methods covered by this implementation-level checkpoint.
/// @dev Upgrades require separate implementation and storage-layout verification. Self-call
///      boundaries are verified by function-specific rules with production-constructible inputs.
definition isProductionMethod(method f) returns bool =
    f.selector != sig:upgradeToAndCall(address,bytes).selector && !isSelfCallBoundary(f);

/// @notice State-changing production methods that can preserve or violate protocol invariants.
definition isInvariantPreservationMethod(method f) returns bool =
    isProductionMethod(f) && !f.isView && !f.isPure;

/// @notice Deposits in the current OPEN epoch are still held by ParentVault and remain refundable.
definition currentOpenEpochDepositBacking() returns mathint =
    getEpoch(getEpochNonce()).status == Types.EpochStatus.OPEN
        ? to_mathint(getEpoch(getEpochNonce()).totalDepositAmount)
        : 0;

/// @notice Withdrawal intents in the current OPEN epoch have not yet entered settlement.
definition currentOpenEpochShareBurnEscrow() returns mathint =
    getEpoch(getEpochNonce()).status == Types.EpochStatus.OPEN
        ? to_mathint(getEpoch(getEpochNonce()).totalShareBurnAmount)
        : 0;

/// @notice Liquid backing retained by ParentVault while the previously closed epoch is EXECUTING.
/// @dev For a remote net deposit Parent retains the withdrawal portion; for a remote net withdrawal
///      it retains the deposit portion while awaiting the remote proceeds. Both equal min(deposits,
///      withdrawals). The nonce guard prevents evaluating getEpochNonce() - 1 before initialization.
definition previousExecutingEpochBacking() returns mathint =
    getEpochNonce() > 1
            && getEpoch(assert_uint256(getEpochNonce() - 1)).status == Types.EpochStatus.EXECUTING
        ? (
            getEpoch(assert_uint256(getEpochNonce() - 1)).totalDepositAmount
                    <= getEpoch(assert_uint256(getEpochNonce() - 1)).totalWithdrawClaimAmount
                ? to_mathint(getEpoch(assert_uint256(getEpochNonce() - 1)).totalDepositAmount)
                : to_mathint(getEpoch(assert_uint256(getEpochNonce() - 1)).totalWithdrawClaimAmount)
        )
        : 0;

/// @notice Assets held locally for a failed rebalance deposit remain reserved until recovery succeeds.
definition pendingRebalanceRecoveryBacking() returns mathint =
    getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT
        ? to_mathint(getRebalanceDepositRecovery().amount)
        : 0;

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
/// ─── Ghost-sum accumulators (SOLV-001 / SOLV-003 / SHARE-003) ─────
/// @dev These mirror per-key storage fields and maintain running sums across the unbounded
///      s_epochs/s_withdraws key space, updated via the Sstore hooks below. Needed because the
///      solvency/accounting invariants in the INVARIANTS section must hold across every epoch nonce
///      and user simultaneously, not just a fixed key the way the per-function Success rules do.
ghost mapping(uint256 => uint256) ghost_epochRemainingWithdrawClaimAmount {
    init_state axiom forall uint256 epochNonce. ghost_epochRemainingWithdrawClaimAmount[epochNonce] == 0;
}
ghost mapping(uint256 => Types.EpochStatus) ghost_epochStatus {
    init_state axiom forall uint256 epochNonce. ghost_epochStatus[epochNonce] == Types.EpochStatus.NONE;
}
ghost mathint ghost_sumClaimableWithdrawObligation {
    init_state axiom ghost_sumClaimableWithdrawObligation == 0;
}
ghost mathint ghost_sumWithdrawEscrow {
    init_state axiom ghost_sumWithdrawEscrow == 0;
}
ghost mathint ghost_sumPendingShareMint {
    init_state axiom ghost_sumPendingShareMint == 0;
}
ghost mathint ghost_sumPendingShareBurn {
    init_state axiom ghost_sumPendingShareBurn == 0;
}

/// @notice Total assets that must remain liquid at ParentVault in the current protocol phase.
definition reservedLiquidObligations() returns mathint =
    ghost_sumClaimableWithdrawObligation
        + currentOpenEpochDepositBacking()
        + previousExecutingEpochBacking()
        + pendingRebalanceRecoveryBacking();

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_epochs[KEY uint256 epochNonce].remainingShareMintAmount
    uint256 newValue (uint256 oldValue) {
    /// @dev SHARE-003: running sum of shares already counted in s_totalShares but not yet minted
    ghost_sumPendingShareMint = ghost_sumPendingShareMint + newValue - oldValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_epochs[KEY uint256 epochNonce].remainingShareBurnAmount
    uint256 newValue (uint256 oldValue) {
    /// @dev SHARE-003: running sum of shares already excluded from s_totalShares but not yet burned
    ghost_sumPendingShareBurn = ghost_sumPendingShareBurn + newValue - oldValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_epochs[KEY uint256 epochNonce].remainingWithdrawClaimAmount
    uint256 newValue (uint256 oldValue) {
    /// @dev SOLV-001: only accumulate while this epoch is already CLAIMABLE. The closeEpoch write that
    ///      first sets this field always precedes the status write that transitions into CLAIMABLE
    ///      (see the status hook below), so ghost_epochStatus[epochNonce] still holds the pre-close
    ///      status here and this correctly skips the initial write; the status hook picks it up instead.
    if (ghost_epochStatus[epochNonce] == Types.EpochStatus.CLAIMABLE) {
        ghost_sumClaimableWithdrawObligation = ghost_sumClaimableWithdrawObligation + newValue - oldValue;
    }
    ghost_epochRemainingWithdrawClaimAmount[epochNonce] = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_epochs[KEY uint256 epochNonce].status
    Types.EpochStatus newValue (Types.EpochStatus oldValue) {
    /// @dev SOLV-001: pick up the remainingWithdrawClaimAmount that was already written earlier in
    ///      the same closeEpoch call, now that this epoch is entering/leaving CLAIMABLE
    if (newValue == Types.EpochStatus.CLAIMABLE && oldValue != Types.EpochStatus.CLAIMABLE) {
        ghost_sumClaimableWithdrawObligation =
            ghost_sumClaimableWithdrawObligation + ghost_epochRemainingWithdrawClaimAmount[epochNonce];
    } else if (oldValue == Types.EpochStatus.CLAIMABLE && newValue != Types.EpochStatus.CLAIMABLE) {
        ghost_sumClaimableWithdrawObligation =
            ghost_sumClaimableWithdrawObligation - ghost_epochRemainingWithdrawClaimAmount[epochNonce];
    }
    ghost_epochStatus[epochNonce] = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_ParentVault.s_withdraws[KEY address withdrawer][KEY uint256 epochNonce]
    uint256 newValue (uint256 oldValue) {
    /// @dev SOLV-003: running sum of shares escrowed against outstanding withdraw intents
    ghost_sumWithdrawEscrow = ghost_sumWithdrawEscrow + newValue - oldValue;
}

/*//////////////////////////////////////////////////////////////
                           INVARIANTS
//////////////////////////////////////////////////////////////*/
/// @dev BaseVault-level invariants (validParentChainSelector-equivalent, noZeroChainSelector,
///      noZeroAssetPrecision) are already covered by BaseVault.spec running against ParentVaultHarness
///      and are not duplicated here.

/// @notice ParentVault only ever stores the REBALANCE_DEPOSIT recovery mode
/// @dev Verifies s_recoveryMode is always NONE or REBALANCE_DEPOSIT on ParentVault. The other four
///      Types.RecoveryMode values (REBALANCE_WITHDRAW, EPOCH_DEPOSIT, EPOCH_WITHDRAW, CCIP_SEND) are
///      exclusively written by ChildVault-side code paths.
invariant recoveryModeIsRestrictedToRebalanceDeposit()
    getRecoveryMode() == Types.RecoveryMode.NONE || getRecoveryMode() == Types.RecoveryMode.REBALANCE_DEPOSIT
    filtered {
        f -> isInvariantPreservationMethod(f)
    }

/// @notice The epoch nonce is strictly positive after initialization
/// @dev Verifies s_epochNonce is never zero, supporting the `epochNonce - 1` arithmetic used
///      elsewhere in ParentVaultEpochLib and ParentVaultCcipLib. Guarded by getTreasury() != 0,
///      which initialize establishes before any role-gated treasury update, rather than isInitialized(): the harness's
///      isInitialized() reads OZ's shared _initialized version slot, which BaseVault's constructor
///      already sets to a nonzero sentinel via _disableInitializers() - so isInitialized() is true
///      immediately after construction, before ParentVault.initialize() ever runs, and before
///      s_epochNonce is actually set. getTreasury() is untouched by the constructor and its first
///      reachable nonzero write occurs in initialize(), so it tracks "has ParentVault initialized."
/// @dev getTreasury() != 0 is only a sound "has initialize() run" signal if nothing else can flip it
///      from 0 to nonzero. In reality only initialize() can, since setTreasury() requires
///      CONFIG_OPERATOR_ROLE, which is only ever granted inside initialize() - but that fact isn't
///      part of this invariant's own predicate, so an unconstrained prestate could otherwise have an
///      account already (unrealistically) holding that role while treasury/epochNonce are still
///      unset, letting setTreasury() alone flip the guard true without epochNonce ever being set.
///      The preserved block below excludes that by requiring the guard already held in the prestate
///      for every method except initialize() itself, which is the one real 0-to-nonzero transition
///      (and sets s_epochNonce atomically in the same call).
invariant epochNonceIsNeverZero()
    getTreasury() != 0 => getEpochNonce() >= 1
    filtered {
        f -> isInvariantPreservationMethod(f)
    }
    {
        preserved {
            require getTreasury() != 0;
        }
        preserved initialize(
            BaseVault.InitParams params,
            address treasury,
            address policyEngineManager,
            address newPolicyEngine,
            address cancelDepositOperator
        ) with (env e) {
        }
    }

/// @notice Exactly the current epoch is OPEN once the vault is initialized
/// @dev Verifies docs/INVARIANTS.md EPOCH-001. Guarded by getTreasury() != 0 rather than
///      isInitialized() - see epochNonceIsNeverZero above for why isInitialized() is unreliable here
///      (BaseVault's constructor already makes it true via _disableInitializers(), independent of
///      whether ParentVault.initialize() has actually run). Same preserved-block reasoning as
///      epochNonceIsNeverZero above applies here too.
invariant EPOCH_001_exactlyCurrentEpochIsOpen(uint256 epochNonce)
    getTreasury() != 0 => (
        (epochNonce == getEpochNonce()) <=> (getEpoch(epochNonce).status == Types.EpochStatus.OPEN)
    )
    filtered {
        f -> isInvariantPreservationMethod(f)
    }
    {
        preserved {
            require getTreasury() != 0;
        }
        preserved closeEpoch(uint256 tvl) with (env e) {
            requireInvariant epochsBeyondCurrentHaveNoneStatus(epochNonce);
        }
        preserved initialize(
            BaseVault.InitParams params,
            address treasury,
            address policyEngineManager,
            address newPolicyEngine,
            address cancelDepositOperator
        ) with (env e) {
            require getEpoch(epochNonce).status == Types.EpochStatus.NONE;
        }
    }

/// @notice Any epoch nonce beyond the current one retains the NONE status
/// @dev Supporting invariant for epochRemainingCountersAreZeroBeforeClose below. s_epochNonce only
///      ever increments (openNextEpoch), so in every reachable state an epoch nonce greater than the
///      current one has status NONE - but nothing states that fact on its own, so Certora's
///      unconstrained induction prestate could otherwise let a "future" epoch nonce already carry
///      leftover non-NONE status/fields from an impossible history, which openNextEpoch's plain
///      status-only write (status := OPEN, nothing else touched) would then silently inherit.
invariant epochsBeyondCurrentHaveNoneStatus(uint256 otherEpochNonce)
    otherEpochNonce > getEpochNonce() => getEpoch(otherEpochNonce).status == Types.EpochStatus.NONE
    filtered {
        f -> isInvariantPreservationMethod(f)
    }
    {
        preserved initialize(
            BaseVault.InitParams params,
            address treasury,
            address policyEngineManager,
            address newPolicyEngine,
            address cancelDepositOperator
        ) with (env e) {
            /// @dev genesis fact, not provable as an invariant: if initialize() is about to succeed,
            ///      the one-shot initializer modifier guarantees this is the first-ever call, so every
            ///      epoch is still at its Solidity zero-value default. Must be an inline require - a
            ///      conditional invariant (e.g. guarded by getTreasury() == 0) is too weak, since an
            ///      unconstrained prestate can have treasury already nonzero with initialize() still
            ///      callable.
            require getEpoch(otherEpochNonce).status == Types.EpochStatus.NONE;
        }
    }

/// @notice Before an epoch has ever closed (status NONE, never touched, or OPEN, currently
///         accepting deposits/withdraws), none of its remaining-side settlement counters have been
///         set yet
/// @dev Supporting invariant for EPOCH-008, EPOCH-011, EPOCH-013, SOLV-001, and SHARE-003.
///      closeEpoch is the only place that writes
///      remainingDepositClaimAmount/remainingShareMintAmount/remainingShareBurnAmount/
///      remainingWithdrawClaimAmount, and it always transitions status away from OPEN in the same
///      call; no function reachable while an epoch is still OPEN touches these four fields. NONE
///      must be covered too: openNextEpoch (called at the tail of every closeEpoch) transitions the
///      next epoch nonce from NONE to OPEN without touching these fields (nothing to clear in
///      reality), so without this covering NONE as well, that exact transition would be a
///      counterexample to this invariant itself. Used via requireInvariant below so the "stay
///      bounded"/"reach zero together" invariants aren't forced to consider unrealistic
///      not-yet-closed prestates where a remaining-side field is nonzero.
/// @dev closeEpoch's own preserved block additionally requires epochsBeyondCurrentHaveNoneStatus:
///      without it, Certora could otherwise assume the *next* epoch nonce (s_epochNonce + 1, about
///      to be opened by openNextEpoch) already had a non-NONE status with leftover nonzero remaining
///      fields from an unreachable prestate - satisfying this invariant's own hypothesis vacuously
///      pre-call (antecedent false) - and then openNextEpoch's status-only write would flip the
///      antecedent true post-call while the stale remaining fields are still sitting there untouched.
// passing
invariant epochRemainingCountersAreZeroBeforeClose(uint256 epochNonce)
    (getEpoch(epochNonce).status == Types.EpochStatus.NONE || getEpoch(epochNonce).status == Types.EpochStatus.OPEN)
        => (
            getEpoch(epochNonce).remainingDepositClaimAmount == 0
                && getEpoch(epochNonce).remainingShareMintAmount == 0
                && getEpoch(epochNonce).remainingShareBurnAmount == 0
                && getEpoch(epochNonce).remainingWithdrawClaimAmount == 0
        )
    filtered {
        f -> isInvariantPreservationMethod(f)
    }
    {
        preserved closeEpoch(uint256 tvl) with (env e) {
            requireInvariant epochsBeyondCurrentHaveNoneStatus(epochNonce);
        }
        preserved initialize(
            BaseVault.InitParams params,
            address treasury,
            address policyEngineManager,
            address newPolicyEngine,
            address cancelDepositOperator
        ) with (env e) {
            /// @dev genesis fact, not provable as an invariant - see
            ///      epochsBeyondCurrentHaveNoneStatus's initialize() preserved block above
            require getEpoch(epochNonce).status == Types.EpochStatus.NONE;
        }
    }

/// @notice An EXECUTING epoch represents exactly a nonzero remote deposit or withdrawal flow
/// @dev A remote net deposit has totalDepositAmount > totalWithdrawClaimAmount and waits for
///      completeEpochDeposit. A remote net withdrawal has the opposite strict inequality and keeps
///      a nonzero share-burn remainder until CCIP settlement atomically makes the epoch CLAIMABLE.
///      The strict branches also exclude an unreachable zero-net-flow EXECUTING induction state.
///      This supports the withdraw-counter exhaustion property below.
invariant executingEpochHasValidNetFlow(uint256 epochNonce)
    getEpoch(epochNonce).status == Types.EpochStatus.EXECUTING => (
        getEpoch(epochNonce).totalDepositAmount > getEpoch(epochNonce).totalWithdrawClaimAmount
            || (
                getEpoch(epochNonce).totalWithdrawClaimAmount > getEpoch(epochNonce).totalDepositAmount
                    && getEpoch(epochNonce).remainingShareBurnAmount != 0
            )
    )
    filtered {
        f -> isInvariantPreservationMethod(f)
    }

/// @notice An EXECUTING epoch's provisional withdrawal remainder matches its initialized total
/// @dev closeEpoch initializes both fields to the same provisional withdrawal amount. Neither field
///      changes before completeEpochDeposit or authenticated CCIP settlement makes the epoch
///      CLAIMABLE. This is the retained-backing relationship used by SOLV-001.
invariant executingEpochRemainingWithdrawMatchesTotal(uint256 epochNonce)
    getEpoch(epochNonce).status == Types.EpochStatus.EXECUTING
        => getEpoch(epochNonce).remainingWithdrawClaimAmount
            == getEpoch(epochNonce).totalWithdrawClaimAmount
    filtered {
        f -> isInvariantPreservationMethod(f)
    }

/// @notice Future epochs have no recorded deposits before they are opened
/// @dev openNextEpoch writes only status and openedAtTimestamp. Proving the untouched future epoch's
///      deposit total is zero prevents that status-only transition from exposing arbitrary induction
///      state as newly refundable OPEN-epoch backing.
invariant futureEpochDepositTotalsAreZero(uint256 epochNonce)
    epochNonce > getEpochNonce() => getEpoch(epochNonce).totalDepositAmount == 0
    filtered {
        f -> isInvariantPreservationMethod(f)
    }
    {
        preserved initialize(
            BaseVault.InitParams params,
            address treasury,
            address policyEngineManager,
            address newPolicyEngine,
            address cancelDepositOperator
        ) with (env e) {
            require getEpochNonce() == 0;
            require getEpoch(epochNonce).totalDepositAmount == 0;
        }
    }

/// @notice Future epochs have no recorded withdrawal intents before they are opened
/// @dev Supports SOLV-003 across openNextEpoch's status-only transition, parallel to
///      futureEpochDepositTotalsAreZero on the deposit side.
invariant futureEpochShareBurnTotalsAreZero(uint256 epochNonce)
    epochNonce > getEpochNonce() => getEpoch(epochNonce).totalShareBurnAmount == 0
    filtered {
        f -> isInvariantPreservationMethod(f)
    }
    {
        preserved initialize(
            BaseVault.InitParams params,
            address treasury,
            address policyEngineManager,
            address newPolicyEngine,
            address cancelDepositOperator
        ) with (env e) {
            require getEpochNonce() == 0;
            require getEpoch(epochNonce).totalShareBurnAmount == 0;
        }
    }

/// @notice An epoch's remaining deposit-claim amount never exceeds its total deposit amount
/// @dev Verifies the boundedness portion of docs/INVARIANTS.md EPOCH-008. remainingShareMintAmount is
///      intentionally not bounded here: Types.Epoch has no stored "total minted shares" field to
///      compare against, since remainingShareMintAmount is itself the total at the instant it is set
///      in closeEpoch. Its non-increase is verified by EPOCH_007 below.
invariant EPOCH_008_epochDepositCountersStayBounded(uint256 epochNonce)
    getEpoch(epochNonce).remainingDepositClaimAmount <= getEpoch(epochNonce).totalDepositAmount
    filtered {
        f -> isInvariantPreservationMethod(f)
    }
    {
        preserved {
            requireInvariant epochRemainingCountersAreZeroBeforeClose(epochNonce);
        }
    }

/// @notice Exhausting an epoch's deposit-claim pool leaves no shares waiting to be minted
/// @dev Verifies the arithmetic-independent direction of docs/INVARIANTS.md EPOCH-008. The reverse
///      implication requires a strict proportional fullMulDiv bound that Certora does not preserve
///      for Solady's general symbolic 512-bit path.
invariant EPOCH_008_exhaustedDepositClaimsHaveNoRemainingShareMint(uint256 epochNonce)
    getEpoch(epochNonce).remainingDepositClaimAmount == 0
        => getEpoch(epochNonce).remainingShareMintAmount == 0
    filtered {
        f -> isInvariantPreservationMethod(f)
    }
    {
        preserved {
            requireInvariant epochRemainingCountersAreZeroBeforeClose(epochNonce);
        }
    }

/// @notice An epoch's remaining share-burn and withdraw-claim amounts never exceed their epoch totals
/// @dev Verifies docs/INVARIANTS.md EPOCH-011 (withdraw side)
invariant EPOCH_011_epochWithdrawCountersStayBounded(uint256 epochNonce)
    getEpoch(epochNonce).remainingShareBurnAmount <= getEpoch(epochNonce).totalShareBurnAmount
        && getEpoch(epochNonce).remainingWithdrawClaimAmount <= getEpoch(epochNonce).totalWithdrawClaimAmount
    filtered {
        f -> isInvariantPreservationMethod(f)
    }
    {
        preserved {
            requireInvariant epochRemainingCountersAreZeroBeforeClose(epochNonce);
        }
    }

/// @notice Once an initialized nonzero share-burn pool is exhausted, no asset claim remains
/// @dev Verifies the withdrawal-pool portion of docs/INVARIANTS.md EPOCH-013. Deposit-only epochs,
///      whose share-burn pool is zero from inception, are intentionally outside this Certora property
///      because Solady fullMulDiv's zero-multiplicand path is not modeled reliably. The implication
///      remains one-directional because a non-final claimant's asset amount may reach zero first
///      through rounding or the documented DEV-004 dust case while shares remain to be burned.
invariant EPOCH_013_exhaustedShareBurnHasNoRemainingAssetClaim(uint256 epochNonce)
    (
        getEpoch(epochNonce).totalShareBurnAmount != 0
            && getEpoch(epochNonce).remainingShareBurnAmount == 0
    ) => getEpoch(epochNonce).remainingWithdrawClaimAmount == 0
    filtered {
        f -> isInvariantPreservationMethod(f)
    }
    {
        preserved {
            requireInvariant epochRemainingCountersAreZeroBeforeClose(epochNonce);
        }
        preserved ccipReceive(Client.Any2EVMMessage message) with (env e) {
            requireInvariant executingEpochHasValidNetFlow(epochNonce);
        }
    }

/// @notice The status ghost remains synchronized with the corresponding epoch storage field
invariant ghostEpochStatusMatchesStorage(uint256 epochNonce)
    ghost_epochStatus[epochNonce] == getEpoch(epochNonce).status
    filtered {
        f -> isInvariantPreservationMethod(f)
    }

/// @notice The remaining-withdraw ghost remains synchronized with the corresponding storage field
invariant ghostEpochRemainingWithdrawMatchesStorage(uint256 epochNonce)
    ghost_epochRemainingWithdrawClaimAmount[epochNonce]
        == getEpoch(epochNonce).remainingWithdrawClaimAmount
    filtered {
        f -> isInvariantPreservationMethod(f)
    }

/// @notice ParentVault's liquid asset balance covers every locally reserved asset obligation
/// @dev Proves a stronger, inductive form of docs/INVARIANTS.md SOLV-001: in addition to all
///      CLAIMABLE remaining withdrawals, the balance covers refundable deposits in the current OPEN
///      epoch, the portion retained locally for the previous EXECUTING epoch, and any pending
///      rebalance-deposit recovery. Each additional term is nonnegative, so the documented
///      claimable-withdraw coverage follows directly.
/// @dev The phase terms move in lockstep with actual asset flows: closeEpoch converts OPEN backing
///      into CLAIMABLE or EXECUTING backing; completeEpochDeposit reclassifies retained EXECUTING
///      backing as CLAIMABLE; CCIP receipt adds remote proceeds as the obligation becomes CLAIMABLE;
///      and successful recovery removes both the liquid recovery funds and their reservation.
/// @dev closeEpoch's zero-flow and net-deposit branches are covered by the three focused
///      SOLV_001_closeEpochPreservesBacking_* rules below. Net-withdraw preservation is established
///      compositionally by the completed ParentVault close dispatch and ParentVaultEpochLib
///      settlement rules; re-executing the combined symbolic arithmetic here is prohibitively slow.
invariant SOLV_001_parentCoversReservedLiquidObligations()
    to_mathint(asset.balanceOf(currentContract)) >= reservedLiquidObligations()
    filtered {
        f -> isInvariantPreservationMethod(f)
            && f.selector != sig:closeEpoch(uint256).selector
    }
    {
        preserved deposit(uint256 amount) with (env e) {
            require e.msg.sender != currentContract;
        }
        preserved claimAsset(uint256 epochNonce) with (env e) {
            requireInvariant ghostEpochStatusMatchesStorage(epochNonce);
            requireInvariant ghostEpochRemainingWithdrawMatchesStorage(epochNonce);
        }
        preserved completeEpochDeposit() with (env e) {
            require getEpochNonce() > 1;
            requireInvariant ghostEpochStatusMatchesStorage(assert_uint256(getEpochNonce() - 1));
            requireInvariant ghostEpochRemainingWithdrawMatchesStorage(assert_uint256(getEpochNonce() - 1));
            requireInvariant executingEpochRemainingWithdrawMatchesTotal(
                assert_uint256(getEpochNonce() - 1)
            );
        }
        preserved ccipReceive(Client.Any2EVMMessage message) with (env e) {
            require getEpochNonce() > 1;
            /// @dev ENV-002: the authenticated CCIP router transfers the delivered asset before
            ///      invoking ccipReceive. A direct CVL method call must state that balance effect.
            require message.destTokenAmounts.length == 1;
            require message.destTokenAmounts[0].token == getAsset();
            require message.destTokenAmounts[0].amount != 0;
            require to_mathint(asset.balanceOf(currentContract))
                >= reservedLiquidObligations() + to_mathint(message.destTokenAmounts[0].amount);
            requireInvariant ghostEpochStatusMatchesStorage(assert_uint256(getEpochNonce() - 1));
            requireInvariant ghostEpochRemainingWithdrawMatchesStorage(assert_uint256(getEpochNonce() - 1));
        }
        preserved initialize(
            BaseVault.InitParams params,
            address treasury,
            address policyEngineManager,
            address newPolicyEngine,
            address cancelDepositOperator
        ) with (env e) {
            /// @dev A successful proxy initialization is the genesis transition, before any epoch,
            ///      recovery, or claimable-withdraw accounting has been created.
            require getEpochNonce() == 0;
            require getEpoch(1).status == Types.EpochStatus.NONE;
            require getEpoch(1).totalDepositAmount == 0;
            require getRecoveryMode() == Types.RecoveryMode.NONE;
            require getRebalanceDepositRecovery().amount == 0;
            require ghost_sumClaimableWithdrawObligation == 0;
            requireInvariant ghostEpochStatusMatchesStorage(1);
            requireInvariant ghostEpochRemainingWithdrawMatchesStorage(1);
        }
    }

/// @notice ParentVault's share balance covers all accounted outstanding withdrawal intents
/// @dev Verifies the balance-coverage component of docs/INVARIANTS.md SOLV-003. Every write to a
///      user's withdrawal entry moves the vault's share balance by the same delta. Unsolicited share
///      transfers may make the actual balance larger, so the relationship is intentionally >=.
invariant SOLV_003_shareBalanceCoversWithdrawEscrow()
    to_mathint(share.balanceOf(currentContract)) >= ghost_sumWithdrawEscrow
    filtered {
        f -> isInvariantPreservationMethod(f)
    }
    {
        preserved withdraw(uint256 shareBurnAmount) with (env e) {
            /// @dev No production path self-calls withdraw. transferFrom(vault, vault) would be
            ///      balance-neutral while increasing the recorded escrow.
            require e.msg.sender != currentContract;
        }
    }

/// @notice Accounted withdrawal escrow reconciles with open and closed epoch settlement state
/// @dev Completes docs/INVARIANTS.md SOLV-003. The user-entry sum equals the current OPEN epoch's
///      aggregate withdrawal intents plus remainingShareBurnAmount across closed epochs. The latter
///      is maintained by ghost_sumPendingShareBurn's storage hook.
invariant SOLV_003_withdrawEscrowReconcilesWithEpochAccounting()
    ghost_sumWithdrawEscrow == currentOpenEpochShareBurnEscrow() + ghost_sumPendingShareBurn
    filtered {
        f -> isInvariantPreservationMethod(f)
    }
    {
        preserved closeEpoch(uint256 tvl) with (env e) {
            require getEpochNonce() != max_uint256;
            requireInvariant epochRemainingCountersAreZeroBeforeClose(getEpochNonce());
            requireInvariant futureEpochShareBurnTotalsAreZero(assert_uint256(getEpochNonce() + 1));
        }
        preserved initialize(
            BaseVault.InitParams params,
            address treasury,
            address policyEngineManager,
            address newPolicyEngine,
            address cancelDepositOperator
        ) with (env e) {
            /// @dev A successful proxy initialization opens untouched epoch 1.
            require getEpochNonce() == 0;
            require getEpoch(1).totalShareBurnAmount == 0;
            require ghost_sumWithdrawEscrow == 0;
            require ghost_sumPendingShareBurn == 0;
        }
    }

/// @notice The share token's totalSupply() reconciles exactly with s_totalShares once pending
///         lazy mint/burn amounts are accounted for
/// @dev Verifies docs/INVARIANTS.md SHARE-003. s_totalShares is adjusted for a whole epoch's net
///      mint/burn atomically at closeEpoch, while the actual ERC20 mint()/burn() calls happen one
///      claimant at a time via claimShares/claimAsset. totalSupply() therefore lags s_totalShares by
///      exactly the sum of not-yet-minted shares (ghost_sumPendingShareMint) and leads it by exactly
///      the sum of not-yet-burned shares (ghost_sumPendingShareBurn). Its exact supply reconciliation
///      remains guarded by getTreasury() != 0 to scope it to initialized ParentVault state.
/// @dev closeEpoch is the one place that initializes remainingShareMintAmount and
///      remainingShareBurnAmount for an epoch. Its preserved block therefore requires those
///      counters to be zero before settlement so the aggregate ghost deltas use the correct baseline.
/// @dev Also requires getTreasury() != 0 already held in the prestate for every method except
///      initialize() - see epochNonceIsNeverZero's NatSpec for why the guard needs this.
invariant SHARE_003_totalSupplyReconcilesWithTotalShares()
    getTreasury() != 0 =>
        to_mathint(share.totalSupply()) == to_mathint(getTotalShares()) - ghost_sumPendingShareMint + ghost_sumPendingShareBurn
    filtered {
        f -> isInvariantPreservationMethod(f)
    }
    {
        preserved {
            require getTreasury() != 0;
        }
        preserved closeEpoch(uint256 tvl) with (env e) {
            require getTreasury() != 0;
            requireInvariant epochRemainingCountersAreZeroBeforeClose(getEpochNonce());
        }
        preserved initialize(
            BaseVault.InitParams params,
            address treasury,
            address policyEngineManager,
            address newPolicyEngine,
            address cancelDepositOperator
        ) with (env e) {
            /// @dev genesis fact, not provable as an invariant - see
            ///      epochsBeyondCurrentHaveNoneStatus's initialize() preserved block above. If
            ///      initialize() is about to succeed, no shares have ever been minted or accounted.
            require share.totalSupply() == 0;
            require getTotalShares() == 0;
            require ghost_sumPendingShareMint == 0;
            require ghost_sumPendingShareBurn == 0;
        }
    }

/*//////////////////////////////////////////////////////////////
                        PARAMETRIC RULES
//////////////////////////////////////////////////////////////*/

/// @dev SOLV-001's directly executable closeEpoch preservation is decomposed by settlement branch
///      because combining the zero-flow and net-deposit paths causes prohibitive path explosion.
rule SOLV_001_closeEpochPreservesBacking_ZeroNetFlow(env e, uint256 tvl) {
    requireInvariant SOLV_001_parentCoversReservedLiquidObligations();
    uint256 epochNonce = getEpochNonce();
    require epochNonce != max_uint256;
    requireInvariant ghostEpochStatusMatchesStorage(epochNonce);
    requireInvariant ghostEpochRemainingWithdrawMatchesStorage(epochNonce);
    requireInvariant futureEpochDepositTotalsAreZero(assert_uint256(epochNonce + 1));

    closeEpoch(e, tvl);

    require getEpoch(epochNonce).status == Types.EpochStatus.CLAIMABLE;
    require getEpoch(epochNonce).totalDepositAmount == getEpoch(epochNonce).totalWithdrawClaimAmount;
    assert to_mathint(asset.balanceOf(currentContract)) >= reservedLiquidObligations();
}

rule SOLV_001_closeEpochPreservesBacking_LocalNetDeposit(env e, uint256 tvl) {
    requireInvariant SOLV_001_parentCoversReservedLiquidObligations();
    uint256 epochNonce = getEpochNonce();
    require epochNonce != max_uint256;
    requireInvariant ghostEpochStatusMatchesStorage(epochNonce);
    requireInvariant ghostEpochRemainingWithdrawMatchesStorage(epochNonce);
    requireInvariant futureEpochDepositTotalsAreZero(assert_uint256(epochNonce + 1));

    closeEpoch(e, tvl);

    require getEpoch(epochNonce).status == Types.EpochStatus.CLAIMABLE;
    require getEpoch(epochNonce).totalDepositAmount > getEpoch(epochNonce).totalWithdrawClaimAmount;
    assert to_mathint(asset.balanceOf(currentContract)) >= reservedLiquidObligations();
}

rule SOLV_001_closeEpochPreservesBacking_RemoteNetDeposit(env e, uint256 tvl) {
    requireInvariant SOLV_001_parentCoversReservedLiquidObligations();
    uint256 epochNonce = getEpochNonce();
    require epochNonce != max_uint256;
    requireInvariant ghostEpochStatusMatchesStorage(epochNonce);
    requireInvariant ghostEpochRemainingWithdrawMatchesStorage(epochNonce);
    requireInvariant futureEpochDepositTotalsAreZero(assert_uint256(epochNonce + 1));

    closeEpoch(e, tvl);

    require getEpoch(epochNonce).status == Types.EpochStatus.EXECUTING;
    require getEpoch(epochNonce).totalDepositAmount > getEpoch(epochNonce).totalWithdrawClaimAmount;
    assert to_mathint(asset.balanceOf(currentContract)) >= reservedLiquidObligations();
}

/// @notice ABI mutability matches observable ParentVault storage behavior.
/// @dev Read-only functions preserve the complete current-contract storage universally. Each
///      included non-read-only function must have at least one successful storage-mutating path.
///      initialize() is exempt from the existential half because the production implementation
///      disables initializers; its proxy initialization behavior is verified in ParentVault.rules.spec.
rule storageBehaviorMatchesMutability(env e, method f, calldataarg args) filtered {
    f -> isProductionMethod(f)
} {
    storage before = lastStorage;

    f(e, args);

    storage after = lastStorage;
    bool isReadOnly = f.isView || f.isPure;
    bool isImplementationInitializer =
        f.selector == sig:initialize(BaseVault.InitParams,address,address,address,address).selector;
    bool changesExpectedExternalStorage =
        f.selector == sig:withdrawLink(uint256).selector && before[link] != after[link];

    assert isReadOnly => before[currentContract] == after[currentContract];
    satisfy isReadOnly
        || isImplementationInitializer
        || before[currentContract] != after[currentContract]
        || changesExpectedExternalStorage;
}

/// @notice The performance fee high water mark never decreases
/// @dev Verifies docs/INVARIANTS.md FEE-003. This is a parametric before/after rule rather than a
///      persistent invariant because it compares two states across one arbitrary transaction. A
///      bare rule considers a fully arbitrary "before" storage state (unlike an invariant, it is not
///      anchored to anything already proven), so without a guard, hwmBefore could be picked as an
///      unreachable garbage value exceeding i_assetPrecision, and initialize()'s unconditional
///      `s_performanceFeeHighWaterMark = i_assetPrecision` write would then look like a decrease.
///      Guarding on getTreasury() == 0 is insufficient here: that branch is vacuously satisfied
///      whenever getTreasury() != 0, so hwmBefore is still unconstrained in exactly the scenario
///      Certora would pick - a prestate where getTreasury() is already nonzero (so the guard says
///      nothing) while the unrelated `initializer` modifier's own storage still permits calling
///      initialize(). The fact that actually matters doesn't need treasury at all: if initialize()
///      is about to succeed, this must be the vault's first-ever initialization, so HWM must already
///      be at its untouched genesis value of 0 - regardless of what getTreasury() happens to read.
rule FEE_003_performanceFeeHighWaterMark_NeverDecreases(method f) filtered {
        f -> isInvariantPreservationMethod(f)
} {
    require f.selector == sig:initialize(BaseVault.InitParams,address,address,address,address).selector
        => getPerformanceFeeHighWaterMark() == 0;

    uint256 hwmBefore = getPerformanceFeeHighWaterMark();

    env e;
    calldataarg args;
    f(e, args);

    assert getPerformanceFeeHighWaterMark() >= hwmBefore;
}

/// @notice Outside an epoch's OPEN phase, its remaining deposit-claim and share-mint amounts never
///         increase
/// @dev Verifies docs/INVARIANTS.md EPOCH-007 and proves the stronger all-method transition form.
///      Excludes OPEN because closeEpoch initializes both counters when settling it; that is an
///      initial assignment, not a claim-processing increase. Closed EXECUTING/CLAIMABLE epochs are
///      therefore covered, as are untouched NONE epochs whose counters remain unchanged until the
///      epoch is opened. Epoch nonces are never reused and statuses never transition backwards.
rule EPOCH_007_epochDepositCounters_NonIncreasing(method f, uint256 epochNonce) filtered {
        f -> isInvariantPreservationMethod(f)
} {
    require getEpoch(epochNonce).status != Types.EpochStatus.OPEN;

    uint256 remainingDepositClaimBefore = getEpoch(epochNonce).remainingDepositClaimAmount;
    uint256 remainingShareMintBefore = getEpoch(epochNonce).remainingShareMintAmount;

    env e;
    calldataarg args;
    f(e, args);

    assert getEpoch(epochNonce).remainingDepositClaimAmount <= remainingDepositClaimBefore;
    assert getEpoch(epochNonce).remainingShareMintAmount <= remainingShareMintBefore;
}

/// @notice Once an epoch is CLAIMABLE, its remaining share-burn and withdraw-claim amounts never
///         increase
/// @dev Verifies docs/INVARIANTS.md EPOCH-010, scoped to the claim phase only. Excludes the
///      EXECUTING -> CLAIMABLE settlement transition: ccipReceive's _handleEpochNetWithdraw
///      overwrites remainingWithdrawClaimAmount with the actual bridged-back amount, which can
///      legitimately exceed the provisional value set at closeEpoch (the code only flags the
///      shortfall case via EpochWithdrawAmountShort; a surplus is accepted silently). That is a
///      one-time settlement rebasing, not a claim-processing regression, so it is out of scope here.
rule EPOCH_010_epochWithdrawCounters_NonIncreasing(method f, uint256 epochNonce) filtered {
        f -> isInvariantPreservationMethod(f)
} {
    require getEpoch(epochNonce).status == Types.EpochStatus.CLAIMABLE;

    uint256 remainingShareBurnBefore = getEpoch(epochNonce).remainingShareBurnAmount;
    uint256 remainingWithdrawClaimBefore = getEpoch(epochNonce).remainingWithdrawClaimAmount;

    env e;
    calldataarg args;
    f(e, args);

    assert getEpoch(epochNonce).remainingShareBurnAmount <= remainingShareBurnBefore;
    assert getEpoch(epochNonce).remainingWithdrawClaimAmount <= remainingWithdrawClaimBefore;
}

/// @notice An epoch's status only ever transitions OPEN -> EXECUTING -> CLAIMABLE or
///         OPEN -> CLAIMABLE (or NONE -> OPEN, for a brand new epoch); never backwards or sideways
/// @dev Verifies docs/INVARIANTS.md EPOCH-002. Two guards, both lessons from earlier fixes in this
///      file:
///      1. requireInvariant epochsBeyondCurrentHaveNoneStatus(epochNonce) rules out an
///         unconstrained "future" epoch nonce carrying a leftover non-NONE status from an
///         unreachable prestate - the same issue epochRemainingCountersAreZeroBeforeClose's
///         closeEpoch preserved block already guards against, relevant here because openNextEpoch
///         writes status := OPEN for exactly such a nonce.
///      2. The require on initialize() rules out the analogous issue for epoch 1 specifically:
///         initialize() unconditionally sets epoch 1's status to OPEN, and without this, an
///         arbitrary prestate could have epoch 1 already at CLAIMABLE/EXECUTING before initialize()
///         ever ran, making the transition look invalid when it's actually the vault's genesis.
rule EPOCH_002_epochTransitionsAreValid(method f, uint256 epochNonce) filtered {
        f -> isInvariantPreservationMethod(f)
} {
    requireInvariant epochsBeyondCurrentHaveNoneStatus(epochNonce);
    require f.selector == sig:initialize(BaseVault.InitParams,address,address,address,address).selector
        => getEpoch(1).status == Types.EpochStatus.NONE;

    Types.EpochStatus statusBefore = getEpoch(epochNonce).status;

    env e;
    calldataarg args;
    f(e, args);

    Types.EpochStatus statusAfter = getEpoch(epochNonce).status;

    assert statusBefore == statusAfter
        || (statusBefore == Types.EpochStatus.NONE && statusAfter == Types.EpochStatus.OPEN)
        || (statusBefore == Types.EpochStatus.OPEN && statusAfter == Types.EpochStatus.EXECUTING)
        || (statusBefore == Types.EpochStatus.OPEN && statusAfter == Types.EpochStatus.CLAIMABLE)
        || (statusBefore == Types.EpochStatus.EXECUTING && statusAfter == Types.EpochStatus.CLAIMABLE);
}


/// @notice Outside authorized force-cancellation, a caller cannot alter another user's escrowed
///         deposit or withdrawal entry for any epoch
/// @dev Every included function writing s_deposits or s_withdraws derives the affected user from
///      msg.sender. forceCancelDeposit is the intentional exception and is excluded here; its
///      authorization, target-user handling, and exact refund effects are verified separately.
rule userEpochEscrowOnlyChangedByOwnerOutsideForceCancel(method f, address user, uint256 epochNonce) filtered {
    f -> isInvariantPreservationMethod(f)
        && f.selector != sig:forceCancelDeposit(address).selector
} {
    uint256 depositBefore = getDepositAmount(user, epochNonce);
    uint256 withdrawBefore = getWithdrawShareBurnAmount(user, epochNonce);

    env e;
    require e.msg.sender != user;
    calldataarg args;
    f(e, args);

    assert getDepositAmount(user, epochNonce) == depositBefore;
    assert getWithdrawShareBurnAmount(user, epochNonce) == withdrawBefore;
}

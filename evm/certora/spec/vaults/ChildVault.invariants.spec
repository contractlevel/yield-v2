using MockInvariantAdapterRegistry as adapterRegistry;
using MockProtocolAdapter as adapter;
using MockUSDC as asset;
using MockLINK as link;
using MockCCIPRouter as ccipRouter;

/// Formal verification of ChildVault cross-function invariants.
/// @author @contractlevel
/// @notice Verified directly against ChildVault so the arbitrary-method universe contains only
///         production-callable selectors. Function-specific behavior remains in ChildVault.rules.spec.

methods {
    function getParentChainSelector() external returns (uint64) envfree;
    function getLastHandledEpochNonce() external returns (uint256) envfree;
    function getLastHandledRebalanceNonce() external returns (uint256) envfree;
    function executeRecovery() external;

    /*//////////////////////////////////////////////////////////////
                         DISPATCHER SUMMARIES
    //////////////////////////////////////////////////////////////*/
    function _.transfer(address, uint256) external => DISPATCHER(true);
    function _.transferFrom(address, address, uint256) external => DISPATCHER(true);
    function _.balanceOf(address) external => DISPATCHER(true);
    function _.approve(address, uint256) external => DISPATCHER(true);
    function _.forceApprove(address, uint256) external => DISPATCHER(true);
    function _.deposit(uint256) external => DISPATCHER(true);
    function _.withdraw(uint256) external => DISPATCHER(true);
    function _.getTVL() external => DISPATCHER(true);
    function _.getVault() external => DISPATCHER(true);
    function _.getAsset() external => DISPATCHER(true);
    function _.getAdapter(bytes32) external => DISPATCHER(true);
    function _.getFee(uint64, Client.EVM2AnyMessage) external => DISPATCHER(true);
    function _.ccipSend(uint64, Client.EVM2AnyMessage) external => DISPATCHER(true);
}

/*//////////////////////////////////////////////////////////////
                          DEFINITIONS
//////////////////////////////////////////////////////////////*/

/// @notice External self-call boundaries whose arguments are constructed only by ChildVault.
/// @dev Arbitrary-method verification would otherwise allow the impossible combination of
///      msg.sender == ChildVault with attacker-selected adapter or CCIP parameters.
definition isSelfCallBoundary(method f) returns bool =
    f.selector == sig:tryDepositToAdapter(address,uint256).selector
        || f.selector == sig:tryCcipSend(uint256,uint64,Types.CcipTx,uint256,bytes32).selector;

/*//////////////////////////////////////////////////////////////
                           INVARIANTS
//////////////////////////////////////////////////////////////*/

/// @notice The immutable parent selector is nonzero and distinct from this chain.
/// @dev upgradeToAndCall is excluded because an implementation replacement is outside the
///      behavioral guarantees of the currently verified implementation.
invariant validParentChainSelector()
    currentContract.i_parentChainSelector != 0
        && currentContract.i_parentChainSelector != currentContract.i_thisChainSelector
    filtered {
        f -> f.selector != sig:upgradeToAndCall(address,bytes).selector && !isSelfCallBoundary(f)
    }

/*//////////////////////////////////////////////////////////////
                        PARAMETRIC RULES
//////////////////////////////////////////////////////////////*/

/// @notice NONCE-002: no successful production call decreases the epoch nonce high-water mark.
rule NONCE_002_epochNonceNeverDecreases(method f) filtered {
    f -> f.selector != sig:upgradeToAndCall(address,bytes).selector && !isSelfCallBoundary(f)
} {
    uint256 nonceBefore = getLastHandledEpochNonce();

    env e;
    calldataarg args;
    f(e, args);

    assert getLastHandledEpochNonce() >= nonceBefore;
}

/// @notice NONCE-002: no successful production call decreases the rebalance nonce high-water mark.
rule NONCE_002_rebalanceNonceNeverDecreases(method f) filtered {
    f -> f.selector != sig:upgradeToAndCall(address,bytes).selector && !isSelfCallBoundary(f)
} {
    uint256 nonceBefore = getLastHandledRebalanceNonce();

    env e;
    calldataarg args;
    f(e, args);

    assert getLastHandledRebalanceNonce() >= nonceBefore;
}

/// @notice NONCE-004: changing either nonce domain leaves the other domain exactly unchanged.
rule NONCE_004_changingOneNonceDomainPreservesTheOther(method f) filtered {
    f -> f.selector != sig:upgradeToAndCall(address,bytes).selector && !isSelfCallBoundary(f)
} {
    uint256 epochNonceBefore = getLastHandledEpochNonce();
    uint256 rebalanceNonceBefore = getLastHandledRebalanceNonce();

    env e;
    calldataarg args;
    f(e, args);

    uint256 epochNonceAfter = getLastHandledEpochNonce();
    uint256 rebalanceNonceAfter = getLastHandledRebalanceNonce();

    assert epochNonceAfter != epochNonceBefore => rebalanceNonceAfter == rebalanceNonceBefore;
    assert rebalanceNonceAfter != rebalanceNonceBefore => epochNonceAfter == epochNonceBefore;
}

/// @notice NONCE-004: only the two production ingress paths for a domain can change its nonce.
rule NONCE_004_onlyCommandIngressCanChangeNonce(method f) filtered {
    f -> f.selector != sig:upgradeToAndCall(address,bytes).selector && !isSelfCallBoundary(f)
} {
    uint256 epochNonceBefore = getLastHandledEpochNonce();
    uint256 rebalanceNonceBefore = getLastHandledRebalanceNonce();

    env e;
    calldataarg args;
    f(e, args);

    assert (
        f.selector != sig:ccipReceive(Client.Any2EVMMessage).selector
            && f.selector != sig:executeEpochWithdraw(uint256,uint256).selector
    ) => getLastHandledEpochNonce() == epochNonceBefore;
    assert (
        f.selector != sig:ccipReceive(Client.Any2EVMMessage).selector
            && f.selector != sig:executeRebalance(uint256,Types.Strategy).selector
    ) => getLastHandledRebalanceNonce() == rebalanceNonceBefore;
}

/// @notice NONCE-006: retrying stored recovery never consumes a fresh command nonce.
rule NONCE_006_executeRecoveryDoesNotAdvanceHandledNonces() {
    uint256 epochNonceBefore = getLastHandledEpochNonce();
    uint256 rebalanceNonceBefore = getLastHandledRebalanceNonce();

    env e;
    executeRecovery(e);

    assert getLastHandledEpochNonce() == epochNonceBefore;
    assert getLastHandledRebalanceNonce() == rebalanceNonceBefore;
}

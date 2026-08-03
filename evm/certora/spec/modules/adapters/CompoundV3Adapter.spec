using MockComet as comet;
using MockCometRewardsVerifier as cometRewards;
using MockAccessControlVault as vault;

/// Verification of CompoundV3Adapter protocol-specific behavior
/// @author @contractlevel

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    function getTVL() external returns (uint256) envfree;
    function getProtocolPool() external returns (address) envfree;
    function getCometRewards() external returns (address) envfree;
    function getVault() external returns (address) envfree;
    function claimRewards(address) external;

    function comet.balanceOf(address) external returns (uint256) envfree;
    function cometRewards.s_lastComet() external returns (address) envfree;
    function cometRewards.s_lastSrc() external returns (address) envfree;
    function cometRewards.s_lastTo() external returns (address) envfree;
    function cometRewards.s_lastShouldAccrue() external returns (bool) envfree;
    function cometRewards.s_claimToCallCount() external returns (uint256) envfree;
    function vault.hasRole(bytes32, address) external returns (bool) envfree;

    function bytes32ToAddress(bytes32) external returns (address) envfree;

    // Roles
    function REWARDS_OPERATOR_ROLE() external returns (bytes32) envfree;
}

/*//////////////////////////////////////////////////////////////
                          DEFINITIONS
//////////////////////////////////////////////////////////////*/
definition RewardsClaimedEvent() returns bytes32 =
// keccak256("RewardsClaimed(address)")
    to_bytes32(0xfec02445b4dcb9e977f70b2966aab1907694acaa22a61ef1ff7d6ee2cb8ed780);

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
ghost mathint ghost_RewardsClaimed_EventCount {
    init_state axiom ghost_RewardsClaimed_EventCount == 0;
}

ghost address ghost_RewardsClaimed_EventParam_to {
    init_state axiom ghost_RewardsClaimed_EventParam_to == 0;
}

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/
hook LOG2(uint offset, uint length, bytes32 t0, bytes32 t1) {
    if (t0 == RewardsClaimedEvent()) {
        ghost_RewardsClaimed_EventCount = ghost_RewardsClaimed_EventCount + 1;
        ghost_RewardsClaimed_EventParam_to = bytes32ToAddress(t1);
    }
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
rule getProtocolPool_EqualsComet() {
    assert getProtocolPool() == comet;
}

rule getCometRewards_ReturnsConfiguredRewards() {
    assert getCometRewards() == cometRewards;
}

rule getTVL_EqualsCometBalance() {
    assert getTVL() == comet.balanceOf(currentContract);
}

rule claimRewards_RevertWhen_CallerNotRewardsOperator() {
    env e;
    address to;

    /// @dev revert conditions NOT being verified
    require to != 0, "to is not zero";
    require e.msg.value == 0, "non-payable";

    /// @dev revert condition being verified
    require !vault.hasRole(REWARDS_OPERATOR_ROLE(), e.msg.sender), "caller is not rewards operator";

    /// @dev ghost starting values
    require ghost_RewardsClaimed_EventCount == 0, "RewardsClaimed event count starts at zero";
    require cometRewards.s_claimToCallCount() == 0, "claimTo call count starts at zero";

    claimRewards@withrevert(e, to);

    assert lastReverted;
    assert ghost_RewardsClaimed_EventCount == 0;
    assert cometRewards.s_claimToCallCount() == 0;
}

rule claimRewards_RevertWhen_ToIsZeroAddress() {
    env e;

    /// @dev revert conditions NOT being verified
    require vault.hasRole(REWARDS_OPERATOR_ROLE(), e.msg.sender), "caller is rewards operator";
    require e.msg.value == 0, "non-payable";

    /// @dev revert condition being verified
    address to = 0;

    /// @dev ghost starting values
    require ghost_RewardsClaimed_EventCount == 0, "RewardsClaimed event count starts at zero";
    require cometRewards.s_claimToCallCount() == 0, "claimTo call count starts at zero";

    claimRewards@withrevert(e, to);

    assert lastReverted;
    assert ghost_RewardsClaimed_EventCount == 0;
    assert cometRewards.s_claimToCallCount() == 0;
}

rule claimRewards_Success_EmitsEventAndClaimsToRecipient() {
    env e;
    address to;
    bytes32 role = REWARDS_OPERATOR_ROLE();

    /// @dev revert conditions NOT being verified
    require vault.hasRole(role, e.msg.sender), "caller is rewards operator";
    require to != 0, "to is not zero";
    require e.msg.value == 0, "non-payable";

    /// @dev ghost starting values
    require ghost_RewardsClaimed_EventCount == 0, "RewardsClaimed event count starts at zero";
    require ghost_RewardsClaimed_EventParam_to == 0, "RewardsClaimed to ghost starts at zero";
    require cometRewards.s_claimToCallCount() == 0, "claimTo call count starts at zero";

    claimRewards@withrevert(e, to);

    assert !lastReverted;
    assert ghost_RewardsClaimed_EventCount == 1;
    assert ghost_RewardsClaimed_EventParam_to == to;
    assert cometRewards.s_claimToCallCount() == 1;
    assert cometRewards.s_lastComet() == getProtocolPool();
    assert cometRewards.s_lastSrc() == currentContract;
    assert cometRewards.s_lastTo() == to;
    assert cometRewards.s_lastShouldAccrue();
}

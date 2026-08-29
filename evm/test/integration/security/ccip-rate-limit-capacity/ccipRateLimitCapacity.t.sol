// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest} from "../../../unit/BaseUnitTest.t.sol";

import {Types} from "../../../../src/libraries/Types.sol";

import {IRouterClient, Client} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
import {RateLimiter} from "@chainlink/contracts-ccip/contracts/libraries/RateLimiter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RateLimitedCcipRouter is IRouterClient {
    using RateLimiter for RateLimiter.TokenBucket;

    RateLimiter.TokenBucket internal s_bucket;
    address internal immutable i_asset;

    constructor(address asset) {
        i_asset = asset;
    }

    function setBucket(uint128 tokens, uint128 capacity, uint128 rate) external {
        s_bucket = RateLimiter.TokenBucket({
            tokens: tokens, lastUpdated: uint32(block.timestamp), isEnabled: true, capacity: capacity, rate: rate
        });
    }

    function getFee(uint64, Client.EVM2AnyMessage memory) external pure returns (uint256) {
        return 0;
    }

    function ccipSend(uint64, Client.EVM2AnyMessage memory message) external payable returns (bytes32) {
        uint256 amount = message.tokenAmounts[0].amount;
        s_bucket._consume(amount, i_asset);
        IERC20(i_asset).transferFrom(msg.sender, address(this), amount);
        return bytes32(uint256(1));
    }

    function isChainSupported(uint64) external pure returns (bool) {
        return true;
    }
}

contract CcipRateLimitCapacity_IntegrationTest is BaseUnitTest {
    uint256 internal constant EPOCH_NONCE = 1;
    uint128 internal constant CAPACITY = 1_000_000 * 1e6;
    uint128 internal constant RATE = 100 * 1e6;
    uint256 internal constant OVER_CAPACITY = 1_500_000 * 1e6;
    uint256 internal constant UNDER_CAPACITY = 900_000 * 1e6;

    function setUp() public {
        _setChildActiveAdapter(address(s_mockProtocolAdapter));
        _setChildCrosschainVault(PARENT_CHAIN_SELECTOR, address(s_parentVault));
    }

    function test_ChildVault_CcipSendAboveCapacity_RevertsAtomicallyWithoutStoringRecovery() public {
        _installRateLimitedRouter(CAPACITY, CAPACITY, RATE);
        deal(address(s_mockUsdc), address(s_childVault), OVER_CAPACITY);

        bytes memory err = abi.encodeWithSelector(
            RateLimiter.TokenMaxCapacityExceeded.selector, uint256(CAPACITY), OVER_CAPACITY, address(s_mockUsdc)
        );

        _changePrank(i_epochOperator);
        vm.expectRevert(err);
        s_childVault.executeEpochWithdraw(EPOCH_NONCE, OVER_CAPACITY);

        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.NONE);
        assertEq(s_childVault.getLastHandledEpochNonce(), 0);
        assertEq(s_mockProtocolAdapter.getWithdrawCalls(), 0);
        assertEq(s_mockUsdc.balanceOf(address(s_childVault)), OVER_CAPACITY);
    }

    function test_ChildVault_TokenRateLimitReached_StoresCcipSendRecovery() public {
        _installRateLimitedRouter(0, CAPACITY, RATE);
        deal(address(s_mockUsdc), address(s_childVault), UNDER_CAPACITY);

        _changePrank(i_epochOperator);
        s_childVault.executeEpochWithdraw(EPOCH_NONCE, UNDER_CAPACITY);

        Types.CcipSendRecovery memory recovery = s_childVault.getCcipSendRecovery();
        assertTrue(s_childVault.getRecoveryMode() == Types.RecoveryMode.CCIP_SEND);
        assertEq(uint256(recovery.ccipTxType), uint256(Types.CcipTx.EPOCH_NET_WITHDRAW));
        assertEq(recovery.destinationChainSelector, PARENT_CHAIN_SELECTOR);
        assertEq(recovery.amount, UNDER_CAPACITY);
        assertEq(recovery.nonce, EPOCH_NONCE);
        assertEq(recovery.protocolId, bytes32(0));
    }

    function _installRateLimitedRouter(uint128 tokens, uint128 capacity, uint128 rate) internal {
        vm.stopPrank();
        RateLimitedCcipRouter implementation = new RateLimitedCcipRouter(address(s_mockUsdc));
        vm.etch(address(s_mockCcipRouter), address(implementation).code);
        RateLimitedCcipRouter(address(s_mockCcipRouter)).setBucket(tokens, capacity, rate);
    }
}

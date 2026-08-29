// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseIntegrationTest} from "../../BaseIntegrationTest.t.sol";

import {Types} from "../../../../src/libraries/Types.sol";

import {Client} from "@chainlink/contracts-ccip/contracts/libraries/Client.sol";
import {FinalityCodec} from "@chainlink/contracts-ccip/contracts/libraries/FinalityCodec.sol";
import {Internal} from "@chainlink/contracts-ccip/contracts/libraries/Internal.sol";
import {MessageV1Codec} from "@chainlink/contracts-ccip/contracts/libraries/MessageV1Codec.sol";
import {Pool} from "@chainlink/contracts-ccip/contracts/libraries/Pool.sol";
import {RateLimiter} from "@chainlink/contracts-ccip/contracts/libraries/RateLimiter.sol";
import {IAny2EVMMessageReceiver} from "@chainlink/contracts-ccip/contracts/interfaces/IAny2EVMMessageReceiver.sol";
import {IPoolV2} from "@chainlink/contracts-ccip/contracts/interfaces/IPoolV2.sol";
import {IRMN} from "@chainlink/contracts-ccip/contracts/interfaces/IRMN.sol";
import {IRMNRemote} from "@chainlink/contracts-ccip/contracts/interfaces/IRMNRemote.sol";
import {IRouter} from "@chainlink/contracts-ccip/contracts/interfaces/IRouter.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
import {OnRamp} from "@chainlink/contracts-ccip/contracts/onRamp/OnRamp.sol";
import {OnRampHelper} from "@chainlink/contracts-ccip/contracts/test/helpers/OnRampHelper.sol";
import {ERC20LockBox} from "@chainlink/contracts-ccip/contracts/pools/ERC20LockBox.sol";
import {LockReleaseTokenPool} from "@chainlink/contracts-ccip/contracts/pools/LockReleaseTokenPool.sol";
import {TokenPool} from "@chainlink/contracts-ccip/contracts/pools/TokenPool.sol";
import {TokenAdminRegistry} from "@chainlink/contracts-ccip/contracts/tokenAdminRegistry/TokenAdminRegistry.sol";

import {AuthorizedCallers} from "@chainlink/contracts/src/v0.8/shared/access/AuthorizedCallers.sol";
import {IERC20 as ChainlinkIERC20} from "@openzeppelin/contracts@5.3.0/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts@5.3.0/token/ERC20/utils/SafeERC20.sol";
import {Vm} from "forge-std/Vm.sol";

contract ReconciliationUncursedRMN is IRMN, IRMNRemote {
    function isBlessed(IRMN.TaggedRoot calldata) external pure override returns (bool) {
        return true;
    }

    function verify(address, Internal.MerkleRoot[] memory, IRMNRemote.Signature[] memory) external pure override {}

    function getCursedSubjects() external pure returns (bytes16[] memory subjects) {
        subjects = new bytes16[](0);
    }

    function isCursed() external pure override(IRMN, IRMNRemote) returns (bool) {
        return false;
    }

    function isCursed(bytes16) external pure override(IRMN, IRMNRemote) returns (bool) {
        return false;
    }
}

/// @dev Uses the real vendored OnRamp and token pools to derive and release the destination amount.
contract RealFeeCcipRouter is IRouterClient, IRouter {
    using SafeERC20 for ChainlinkIERC20;

    ChainlinkIERC20 internal immutable i_token;
    OnRampHelper internal immutable i_onRamp;
    LockReleaseTokenPool internal immutable i_sourcePool;
    LockReleaseTokenPool internal immutable i_destinationPool;
    uint64 internal immutable i_sourceChainSelector;
    uint64 internal immutable i_destinationChainSelector;
    uint256 internal s_messageNonce;

    constructor(
        ChainlinkIERC20 token,
        OnRampHelper onRamp,
        LockReleaseTokenPool sourcePool,
        LockReleaseTokenPool destinationPool,
        uint64 sourceChainSelector,
        uint64 destinationChainSelector
    ) {
        i_token = token;
        i_onRamp = onRamp;
        i_sourcePool = sourcePool;
        i_destinationPool = destinationPool;
        i_sourceChainSelector = sourceChainSelector;
        i_destinationChainSelector = destinationChainSelector;
    }

    function getFee(uint64, Client.EVM2AnyMessage memory) external pure returns (uint256) {
        return 0;
    }

    function isChainSupported(uint64 selector) external view returns (bool) {
        return selector == i_destinationChainSelector;
    }

    function ccipSend(uint64 destinationChainSelector, Client.EVM2AnyMessage calldata message)
        external
        payable
        returns (bytes32 messageId)
    {
        require(destinationChainSelector == i_destinationChainSelector, "wrong destination");

        uint256 sourceAmount = message.tokenAmounts[0].amount;
        address receiver = abi.decode(message.receiver, (address));
        i_token.safeTransferFrom(msg.sender, address(i_sourcePool), sourceAmount);

        MessageV1Codec.TokenTransferV1 memory transfer = i_onRamp.lockOrBurnSingleToken(
            message.tokenAmounts[0],
            destinationChainSelector,
            message.receiver,
            msg.sender,
            FinalityCodec.WAIT_FOR_FINALITY_FLAG,
            ""
        );
        Pool.ReleaseOrMintOutV1 memory released = i_destinationPool.releaseOrMint(
            Pool.ReleaseOrMintInV1({
                originalSender: abi.encode(msg.sender),
                remoteChainSelector: i_sourceChainSelector,
                receiver: receiver,
                sourceDenominatedAmount: transfer.amount,
                localToken: address(i_token),
                sourcePoolAddress: transfer.sourcePoolAddress,
                sourcePoolData: transfer.extraData,
                offchainTokenData: ""
            }),
            FinalityCodec.WAIT_FOR_FINALITY_FLAG
        );

        Client.EVMTokenAmount[] memory delivered = new Client.EVMTokenAmount[](1);
        delivered[0] = Client.EVMTokenAmount({token: address(i_token), amount: released.destinationAmount});
        messageId = keccak256(abi.encode(address(this), ++s_messageNonce, sourceAmount, released.destinationAmount));

        IAny2EVMMessageReceiver(receiver)
            .ccipReceive(
                Client.Any2EVMMessage({
                    messageId: messageId,
                    sourceChainSelector: i_sourceChainSelector,
                    sender: abi.encode(msg.sender),
                    data: message.data,
                    destTokenAmounts: delivered
                })
            );
    }

    function getOnRamp(uint64 destinationChainSelector) external view returns (address) {
        return destinationChainSelector == i_destinationChainSelector ? address(i_onRamp) : address(0);
    }

    function isOffRamp(uint64 sourceChainSelector, address offRamp) external view returns (bool) {
        return sourceChainSelector == i_sourceChainSelector && offRamp == address(this);
    }

    function routeMessage(Client.Any2EVMMessage calldata, uint16, uint256, address)
        external
        pure
        returns (bool success, bytes memory retBytes, uint256 gasUsed)
    {
        return (false, "", 0);
    }
}

contract RealCcipPoolDepositReconciliationIntegrationTest is BaseIntegrationTest {
    uint256 private constant PRINCIPAL = 1_000_000e6;
    uint256 private constant NEW_DEPOSIT = 100_000e6;
    uint16 private constant FEE_BPS = 100;
    bytes32 private constant WORKFLOW_ID = keccak256("real-ccip-pool-reconciliation");
    bytes10 private constant WORKFLOW_NAME = bytes10("closeEpoch");

    LockReleaseTokenPool private s_sourcePool;
    LockReleaseTokenPool private s_destinationPool;

    function setUp() public override {
        super.setUp();
        _deployLocalParentChildTopology();
        vm.stopPrank();
        _installRealFeeCapableCcipPath();
        _configureCloseEpochWorkflow(parent.workflowRouter, WORKFLOW_ID, WORKFLOW_NAME, i_owner);
        _setParentRemoteStrategyToChild(AAVE_V3_PROTOCOL_ID);
        _setChildActiveAdapter(AAVE_V3_PROTOCOL_ID);
        _setDefaultCcipGasLimits();
        _seedChildLocalTvl(PRINCIPAL);
    }

    function test_RealCcipPoolFee_ReconcilesSharesToReleasedDestinationAmount() external {
        _enableSourcePoolTransferFee(FEE_BPS);
        uint256 sharesBefore = parent.vault.getTotalShares();
        uint256 tvlBefore = child.vault.getTVL();

        _fundAndApproveUsdc(i_recipient1, NEW_DEPOSIT);
        _changePrank(i_recipient1);
        parent.vault.deposit(NEW_DEPOSIT);

        _warpPastMinEpoch();
        vm.recordLogs();
        _closeEpochThroughWorkflow(parent.workflowRouter, WORKFLOW_ID, WORKFLOW_NAME, i_owner, tvlBefore);
        Vm.Log memory successLog = _assertEmittedBy(
            vm.getRecordedLogs(), keccak256("EpochDepositToStrategySuccess(uint256,uint256)"), address(child.vault)
        );
        uint256 actualDepositAmount = uint256(successLog.topics[2]);
        uint256 feeAmount = NEW_DEPOSIT * FEE_BPS / 10_000;
        uint256 nominalShares = NEW_DEPOSIT * sharesBefore / tvlBefore;
        uint256 expectedShares = nominalShares * actualDepositAmount / NEW_DEPOSIT;

        assertEq(actualDepositAmount, NEW_DEPOSIT - feeAmount);
        assertEq(ChainlinkIERC20(parent.asset).balanceOf(address(s_sourcePool)), feeAmount);
        assertEq(child.vault.getTVL(), tvlBefore + actualDepositAmount);

        _completeEpochDepositThroughWorkflow(
            parent.workflowRouter,
            WORKFLOW_ID,
            WORKFLOW_NAME,
            i_owner,
            uint256(successLog.topics[1]),
            actualDepositAmount
        );

        assertEq(parent.vault.getTotalShares(), sharesBefore + expectedShares);
        assertEq(uint256(parent.vault.getEpoch(2).status), uint256(Types.EpochStatus.CLAIMABLE));
        _changePrank(i_recipient1);
        parent.vault.claimShares(2);
        assertEq(parent.share.balanceOf(i_recipient1), expectedShares);
    }

    function _enableSourcePoolTransferFee(uint16 feeBps) private {
        vm.stopPrank();
        TokenPool.TokenTransferFeeConfigArgs[] memory updates = new TokenPool.TokenTransferFeeConfigArgs[](1);
        updates[0] = TokenPool.TokenTransferFeeConfigArgs({
            destChainSelector: CHILD_CHAIN_SELECTOR,
            tokenTransferFeeConfig: IPoolV2.TokenTransferFeeConfig({
                destGasOverhead: 1,
                destBytesOverhead: 32,
                finalityFeeUSDCents: 0,
                fastFinalityFeeUSDCents: 0,
                finalityTransferFeeBps: feeBps,
                fastFinalityTransferFeeBps: feeBps,
                isEnabled: true
            })
        });
        s_sourcePool.applyTokenTransferFeeConfigUpdates(updates, new uint64[](0));
    }

    function _installRealFeeCapableCcipPath() private {
        ChainlinkIERC20 token = ChainlinkIERC20(parent.asset);
        ReconciliationUncursedRMN rmn = new ReconciliationUncursedRMN();
        ERC20LockBox sourceLockBox = new ERC20LockBox(address(token));
        ERC20LockBox destinationLockBox = new ERC20LockBox(address(token));

        s_sourcePool = new LockReleaseTokenPool(
            token, 6, address(0), address(rmn), address(local.mockCcipRouter), address(sourceLockBox)
        );
        s_destinationPool = new LockReleaseTokenPool(
            token, 6, address(0), address(rmn), address(local.mockCcipRouter), address(destinationLockBox)
        );

        _authorizeLockBox(sourceLockBox, address(s_sourcePool));
        _authorizeLockBox(destinationLockBox, address(s_destinationPool));
        _configurePoolLane(s_sourcePool, CHILD_CHAIN_SELECTOR, address(s_destinationPool));
        _configurePoolLane(s_destinationPool, PARENT_CHAIN_SELECTOR, address(s_sourcePool));

        TokenAdminRegistry registry = new TokenAdminRegistry();
        registry.proposeAdministrator(address(token), address(this));
        registry.acceptAdminRole(address(token));
        registry.setPool(address(token), address(s_sourcePool));

        OnRampHelper onRamp = new OnRampHelper(
            OnRamp.StaticConfig({
                chainSelector: PARENT_CHAIN_SELECTOR,
                rmnRemote: IRMNRemote(address(rmn)),
                maxUSDCentsPerMessage: type(uint32).max,
                tokenAdminRegistry: address(registry)
            }),
            OnRamp.DynamicConfig({feeQuoter: address(1), reentrancyGuardEntered: false, feeAggregator: address(0)})
        );
        OnRamp.DestChainConfigArgs[] memory rampUpdates = new OnRamp.DestChainConfigArgs[](1);
        address[] memory defaultCCVs = new address[](1);
        defaultCCVs[0] = address(3);
        rampUpdates[0] = OnRamp.DestChainConfigArgs({
            destChainSelector: CHILD_CHAIN_SELECTOR,
            router: IRouter(address(local.mockCcipRouter)),
            addressBytesLength: 20,
            tokenReceiverAllowed: false,
            messageNetworkFeeUSDCents: 1,
            tokenNetworkFeeUSDCents: 1,
            baseExecutionGasCost: 1,
            defaultCCVs: defaultCCVs,
            laneMandatedCCVs: new address[](0),
            defaultExecutor: address(2),
            offRamp: abi.encodePacked(address(local.mockCcipRouter))
        });
        onRamp.applyDestChainConfigUpdates(rampUpdates);

        RealFeeCcipRouter implementation = new RealFeeCcipRouter(
            token, onRamp, s_sourcePool, s_destinationPool, PARENT_CHAIN_SELECTOR, CHILD_CHAIN_SELECTOR
        );
        vm.etch(address(local.mockCcipRouter), address(implementation).code);
        local.usdc.mint(address(destinationLockBox), 20_000_000e6);
    }

    function _authorizeLockBox(ERC20LockBox lockBox, address pool) private {
        address[] memory added = new address[](1);
        added[0] = pool;
        lockBox.applyAuthorizedCallerUpdates(
            AuthorizedCallers.AuthorizedCallerArgs({addedCallers: added, removedCallers: new address[](0)})
        );
    }

    function _configurePoolLane(LockReleaseTokenPool pool, uint64 remoteSelector, address remotePool) private {
        bytes[] memory remotePools = new bytes[](1);
        remotePools[0] = abi.encode(remotePool);
        TokenPool.ChainUpdate[] memory updates = new TokenPool.ChainUpdate[](1);
        updates[0] = TokenPool.ChainUpdate({
            remoteChainSelector: remoteSelector,
            remotePoolAddresses: remotePools,
            remoteTokenAddress: abi.encodePacked(parent.asset),
            outboundRateLimiterConfig: RateLimiter.Config({isEnabled: false, capacity: 0, rate: 0}),
            inboundRateLimiterConfig: RateLimiter.Config({isEnabled: false, capacity: 0, rate: 0})
        });
        pool.applyChainUpdates(new uint64[](0), updates);
    }
}

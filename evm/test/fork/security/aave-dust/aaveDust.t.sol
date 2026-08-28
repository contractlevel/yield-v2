// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Test} from "forge-std/Test.sol";

import {AdapterRegistry} from "../../../../src/modules/AdapterRegistry.sol";
import {AaveV3Adapter} from "../../../../src/modules/adapters/AaveV3Adapter.sol";
import {AaveV4Adapter} from "../../../../src/modules/adapters/AaveV4Adapter.sol";
import {BaseVault} from "../../../../src/vaults/BaseVault.sol";
import {ChildVault} from "../../../../src/vaults/ChildVault.sol";
import {IPool} from "@aave/v3-origin/src/contracts/interfaces/IPool.sol";
import {IAaveV4Spoke} from "../../../../src/interfaces/external/IAaveV4Spoke.sol";
import {IAaveV4Adapter} from "../../../../src/interfaces/adapters/IAaveV4Adapter.sol";
import {IProtocolAdapter} from "../../../../src/interfaces/adapters/IProtocolAdapter.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";
import {Types} from "../../../../src/libraries/Types.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Client} from "@chainlink/contracts-ccip/contracts/libraries/Client.sol";
import {IAny2EVMMessageReceiver} from "@chainlink/contracts-ccip/contracts/interfaces/IAny2EVMMessageReceiver.sol";

interface IAaveV4HubPreview {
    function previewAddByAssets(uint256 assetId, uint256 assets) external view returns (uint256);
    function getAddedAssets(uint256 assetId) external view returns (uint256);
    function getAddedShares(uint256 assetId) external view returns (uint256);
}

contract AaveDust_SecurityForkTest is Test {
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address internal constant CCIP_ROUTER = 0x80226fc0Ee2b096224EeAc085Bb9a8cba1146f7D;
    address internal constant AAVE_V3_PROVIDER = 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;
    address internal constant AAVE_V4_SPOKE = 0x94e7A5dCbE816e498b89aB752661904E2F56c485;

    uint64 internal constant ETHEREUM_SELECTOR = 5009297550715157269;
    uint64 internal constant ARBITRUM_SELECTOR = 4949039107694359620;
    uint256 internal constant ETHEREUM_FORK_BLOCK = 25_110_160;
    uint256 internal constant INITIAL_POSITION = 1_000e6;

    bytes32 internal constant AAVE_V3_PROTOCOL_ID = keccak256("aave-v3");
    bytes32 internal constant AAVE_V4_PROTOCOL_ID = keccak256("aave-v4");

    ChildVault internal child;
    AaveV3Adapter internal aaveV3Adapter;
    AaveV4Adapter internal aaveV4Adapter;
    address internal parent = makeAddr("parent-vault");

    function setUp() public {
        vm.createSelectFork(vm.envString("ETHEREUM_MAINNET_RPC_URL"), ETHEREUM_FORK_BLOCK);

        AdapterRegistry registry = new AdapterRegistry(0, address(this));
        registry.grantRole(Roles.CONFIG_OPERATOR_ROLE, address(this));

        BaseVault.ConstructorParams memory constructorParams = BaseVault.ConstructorParams({
            link: LINK,
            asset: USDC,
            ccipRouter: CCIP_ROUTER,
            adapterRegistry: address(registry),
            thisChainSelector: ETHEREUM_SELECTOR
        });
        BaseVault.InitParams memory initParams = BaseVault.InitParams({
            defaultAdmin: address(this),
            pauser: address(this),
            unpauser: address(this),
            configOperator: address(this),
            initialDefaultCcipGasLimit: 500_000,
            upgrader: address(this)
        });

        ChildVault implementation = new ChildVault(constructorParams, ARBITRUM_SELECTOR);
        child = ChildVault(
            address(
                new ERC1967Proxy(
                    address(implementation), abi.encodeWithSelector(ChildVault.initialize.selector, initParams)
                )
            )
        );

        aaveV3Adapter = new AaveV3Adapter(address(child), AAVE_V3_PROVIDER);
        aaveV4Adapter = new AaveV4Adapter(address(child), AAVE_V4_SPOKE);
        registry.setAdapter(AAVE_V3_PROTOCOL_ID, address(aaveV3Adapter));
        registry.setAdapter(AAVE_V4_PROTOCOL_ID, address(aaveV4Adapter));

        uint64[] memory selectors = new uint64[](1);
        selectors[0] = ARBITRUM_SELECTOR;
        address[] memory vaults = new address[](1);
        vaults[0] = parent;
        child.setCrosschainVaults(selectors, vaults);
    }

    function test_AaveDust_AaveV4OneUnitBuffersAndSecondUnitFlushes() external {
        _deliverRebalance(1, INITIAL_POSITION, AAVE_V4_PROTOCOL_ID);

        uint256 reserveId = aaveV4Adapter.getReserveId();
        IAaveV4Spoke.Reserve memory reserve = IAaveV4Spoke(AAVE_V4_SPOKE).getReserve(reserveId);
        IAaveV4HubPreview hub = IAaveV4HubPreview(reserve.hub);
        assertEq(hub.previewAddByAssets(reserve.assetId, 1), 0);
        assertGt(hub.previewAddByAssets(reserve.assetId, 2), 0);

        deal(USDC, address(this), 1);
        IERC20(USDC).approve(AAVE_V4_SPOKE, 1);
        vm.expectRevert(abi.encodeWithSelector(IAaveV4Adapter.InvalidShares.selector));
        IAaveV4Spoke(AAVE_V4_SPOKE).supply(reserveId, 1, address(this));

        _assertOneUnitBuffersAndSecondFlushes(aaveV4Adapter);
    }

    function test_AaveDust_AaveV4BuffersUpToFirstPositivePreviewAfterExchangeRateIncreases() external {
        _deliverRebalance(1, INITIAL_POSITION, AAVE_V4_PROTOCOL_ID);

        uint256 reserveId = aaveV4Adapter.getReserveId();
        IAaveV4Spoke.Reserve memory reserve = IAaveV4Spoke(AAVE_V4_SPOKE).getReserve(reserveId);
        IAaveV4HubPreview hub = IAaveV4HubPreview(reserve.hub);
        uint256 addedAssetsBefore = hub.getAddedAssets(reserve.assetId);
        uint256 addedShares = hub.getAddedShares(reserve.assetId);
        uint256 minimumBefore = _firstAmountWithPositivePreview(hub, reserve.assetId);

        vm.warp(block.timestamp + 365 days);

        uint256 addedAssetsAfter = hub.getAddedAssets(reserve.assetId);
        uint256 minimumAfter = _firstAmountWithPositivePreview(hub, reserve.assetId);
        assertGt(addedAssetsAfter, addedAssetsBefore);
        assertEq(hub.getAddedShares(reserve.assetId), addedShares);
        assertGe(minimumAfter, minimumBefore);
        assertGt(minimumAfter, 1);
        assertEq(hub.previewAddByAssets(reserve.assetId, minimumAfter - 1), 0);
        assertGt(hub.previewAddByAssets(reserve.assetId, minimumAfter), 0);

        uint256 tvlBefore = aaveV4Adapter.getTVL();
        _deliverEpochDeposit(1, minimumAfter - 1);

        assertEq(aaveV4Adapter.getBufferedAssets(), minimumAfter - 1);
        assertEq(aaveV4Adapter.getTVL(), tvlBefore + minimumAfter - 1);
        assertEq(uint256(child.getRecoveryMode()), uint256(Types.RecoveryMode.NONE));

        _deliverEpochDeposit(2, 1);

        assertEq(aaveV4Adapter.getBufferedAssets(), 0);
        assertApproxEqAbs(aaveV4Adapter.getTVL(), tvlBefore + minimumAfter, 100);
        assertEq(uint256(child.getRecoveryMode()), uint256(Types.RecoveryMode.NONE));
    }

    function test_AaveDust_AaveV3OneUnitBuffersAndSecondUnitFlushes() external {
        _deliverRebalance(1, INITIAL_POSITION, AAVE_V3_PROTOCOL_ID);

        IPool pool = IPool(aaveV3Adapter.getProtocolPool());
        uint256 index = pool.getReserveNormalizedIncome(USDC);
        uint256 maximumZeroScaledAmount = (index - 1) / 1e27;
        assertLe(1, maximumZeroScaledAmount);
        assertGt(2, maximumZeroScaledAmount);

        _assertOneUnitBuffersAndSecondFlushes(aaveV3Adapter);
    }

    function test_AaveDust_AaveV3BuffersUpToFirstPositivePreviewAfterIndexIncreases() external {
        _deliverRebalance(1, INITIAL_POSITION, AAVE_V3_PROTOCOL_ID);

        IPool pool = IPool(aaveV3Adapter.getProtocolPool());
        uint256 indexBefore = pool.getReserveNormalizedIncome(USDC);

        vm.warp(block.timestamp + 365 days);

        uint256 indexAfter = pool.getReserveNormalizedIncome(USDC);
        uint256 maximumZeroScaledAmount = (indexAfter - 1) / 1e27;
        uint256 firstPositiveScaledAmount = maximumZeroScaledAmount + 1;
        assertGt(indexAfter, indexBefore);
        assertGe(maximumZeroScaledAmount, 1);
        assertLe(maximumZeroScaledAmount, 50);
        assertLe(maximumZeroScaledAmount * 1e27, indexAfter - 1);
        assertGt(firstPositiveScaledAmount * 1e27, indexAfter - 1);

        uint256 tvlBefore = aaveV3Adapter.getTVL();
        _deliverEpochDeposit(1, maximumZeroScaledAmount);

        assertEq(aaveV3Adapter.getBufferedAssets(), maximumZeroScaledAmount);
        assertEq(aaveV3Adapter.getTVL(), tvlBefore + maximumZeroScaledAmount);
        assertEq(uint256(child.getRecoveryMode()), uint256(Types.RecoveryMode.NONE));

        _deliverEpochDeposit(2, 1);

        assertEq(aaveV3Adapter.getBufferedAssets(), 0);
        assertApproxEqAbs(aaveV3Adapter.getTVL(), tvlBefore + firstPositiveScaledAmount, 100);
        assertEq(uint256(child.getRecoveryMode()), uint256(Types.RecoveryMode.NONE));
    }

    function _assertOneUnitBuffersAndSecondFlushes(IProtocolAdapter adapter) internal {
        uint256 tvlBefore = adapter.getTVL();

        _deliverEpochDeposit(1, 1);

        assertEq(adapter.getBufferedAssets(), 1);
        assertEq(adapter.getTVL(), tvlBefore + 1);
        assertEq(IERC20(USDC).balanceOf(address(adapter)), 1);
        assertEq(IERC20(USDC).allowance(address(adapter), adapter.getProtocolPool()), 0);
        assertEq(uint256(child.getRecoveryMode()), uint256(Types.RecoveryMode.NONE));
        assertEq(child.getEpochDepositRecovery().amount, 0);

        _deliverEpochDeposit(2, 1);

        assertEq(adapter.getBufferedAssets(), 0);
        assertApproxEqAbs(adapter.getTVL(), tvlBefore + 2, 100);
        assertEq(IERC20(USDC).balanceOf(address(adapter)), 0);
        assertEq(uint256(child.getRecoveryMode()), uint256(Types.RecoveryMode.NONE));
    }

    function _firstAmountWithPositivePreview(IAaveV4HubPreview hub, uint256 assetId)
        internal
        view
        returns (uint256 amount)
    {
        for (amount = 1; amount <= 50; ++amount) {
            if (hub.previewAddByAssets(assetId, amount) != 0) return amount;
        }
        revert("positive preview exceeds adapter buffer bound");
    }

    function _deliverRebalance(uint256 nonce, uint256 amount, bytes32 protocolId) internal {
        _deliver(
            keccak256(abi.encode("rebalance", nonce, protocolId)),
            amount,
            abi.encode(Types.CcipTx.REBALANCE, abi.encode(nonce, protocolId))
        );
    }

    function _deliverEpochDeposit(uint256 nonce, uint256 amount) internal {
        _deliver(
            keccak256(abi.encode("epoch", nonce)), amount, abi.encode(Types.CcipTx.EPOCH_NET_DEPOSIT, abi.encode(nonce))
        );
    }

    function _deliver(bytes32 messageId, uint256 amount, bytes memory data) internal {
        deal(USDC, address(child), amount);
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: USDC, amount: amount});
        Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
            messageId: messageId,
            sourceChainSelector: ARBITRUM_SELECTOR,
            sender: abi.encode(parent),
            data: data,
            destTokenAmounts: tokenAmounts
        });

        vm.prank(CCIP_ROUTER);
        IAny2EVMMessageReceiver(address(child)).ccipReceive(message);
    }
}

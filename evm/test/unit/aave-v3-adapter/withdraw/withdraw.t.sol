// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseAaveV3AdapterUnitTest, Vm} from "../BaseAaveV3AdapterUnitTest.t.sol";

import {AaveV3Adapter} from "../../../../src/modules/adapters/AaveV3Adapter.sol";
import {IProtocolAdapter} from "../../../../src/interfaces/adapters/IProtocolAdapter.sol";
import {MockAaveV3PoolAddressesProvider} from "../../../mocks/MockAaveV3PoolAddressesProvider.sol";

import {DataTypes} from "@aave/v3-origin/src/contracts/protocol/libraries/types/DataTypes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AaveV3Adapter_WithdrawUnitTest is BaseAaveV3AdapterUnitTest {
    uint256 internal constant TVL = 1000 * 1e6;
    uint256 internal constant WITHDRAW_AMOUNT = 500 * 1e6;
    uint256 internal constant INSUFFICIENT_AMOUNT = 900 * 1e6;
    uint256 internal constant TOLERANCE_SHORTFALL_TVL = TVL - 100;
    uint256 internal constant EXCESSIVE_SHORTFALL_TVL = TVL - 101;

    function setUp() public {
        _changePrank(address(s_parentVault));
    }

    function test_AaveV3Adapter_withdraw_RevertWhen_CallerIsNotVault() external {
        _changePrank(i_nonOwner);
        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__OnlyVault.selector);
        s_aaveV3Adapter.withdraw(WITHDRAW_AMOUNT);
    }

    function test_AaveV3Adapter_withdraw_RevertWhen_RebalanceWithdrawAmountIsLessThanTVL() external {
        UnderpayingAaveV3Pool underpayingPool = new UnderpayingAaveV3Pool(address(s_mockAToken), INSUFFICIENT_AMOUNT);
        MockAaveV3PoolAddressesProvider provider = new MockAaveV3PoolAddressesProvider(address(underpayingPool));
        AaveV3Adapter adapter = new AaveV3Adapter(address(s_parentVault), address(provider));

        s_mockAToken.mint(address(adapter), TVL);
        deal(address(s_mockUsdc), address(underpayingPool), INSUFFICIENT_AMOUNT);

        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__IncorrectWithdrawAmount.selector);
        adapter.withdraw(type(uint256).max);
    }

    function test_AaveV3Adapter_withdraw_RevertWhen_RebalanceWithdrawShortfallExceedsRoundingTolerance() external {
        UnderpayingAaveV3Pool underpayingPool =
            new UnderpayingAaveV3Pool(address(s_mockAToken), EXCESSIVE_SHORTFALL_TVL);
        MockAaveV3PoolAddressesProvider provider = new MockAaveV3PoolAddressesProvider(address(underpayingPool));
        AaveV3Adapter adapter = new AaveV3Adapter(address(s_parentVault), address(provider));

        s_mockAToken.mint(address(adapter), TVL);
        deal(address(s_mockUsdc), address(underpayingPool), EXCESSIVE_SHORTFALL_TVL);

        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__IncorrectWithdrawAmount.selector);
        adapter.withdraw(type(uint256).max);
    }

    function test_AaveV3Adapter_withdraw_SucceedsWhen_RebalanceWithdrawShortfallEqualsRoundingTolerance() external {
        UnderpayingAaveV3Pool underpayingPool =
            new UnderpayingAaveV3Pool(address(s_mockAToken), TOLERANCE_SHORTFALL_TVL);
        MockAaveV3PoolAddressesProvider provider = new MockAaveV3PoolAddressesProvider(address(underpayingPool));
        AaveV3Adapter adapter = new AaveV3Adapter(address(s_parentVault), address(provider));

        s_mockAToken.mint(address(adapter), TVL);
        deal(address(s_mockUsdc), address(underpayingPool), TOLERANCE_SHORTFALL_TVL);

        uint256 actualAmount = adapter.withdraw(type(uint256).max);

        assertEq(actualAmount, TOLERANCE_SHORTFALL_TVL);
    }

    function test_AaveV3Adapter_withdraw_RevertWhen_RebalanceWithdrawReturnsZero() external {
        UnderpayingAaveV3Pool underpayingPool = new UnderpayingAaveV3Pool(address(s_mockAToken), 0);
        MockAaveV3PoolAddressesProvider provider = new MockAaveV3PoolAddressesProvider(address(underpayingPool));
        AaveV3Adapter adapter = new AaveV3Adapter(address(s_parentVault), address(provider));

        s_mockAToken.mint(address(adapter), TVL);

        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__NoZeroAmount.selector);
        adapter.withdraw(type(uint256).max);
    }

    function test_AaveV3Adapter_withdraw_RevertWhen_EpochWithdrawAmountExceedsTVL() external {
        s_mockAToken.mint(address(s_aaveV3Adapter), WITHDRAW_AMOUNT);

        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__WithdrawAmountExceedsTotalValue.selector);
        s_aaveV3Adapter.withdraw(TVL);
    }

    function test_AaveV3Adapter_withdraw_Success_RebalanceWithdraw() external {
        deal(address(s_mockAToken), address(s_aaveV3Adapter), TVL);
        deal(address(s_mockUsdc), address(s_mockAaveV3Pool), TVL);

        vm.recordLogs();
        uint256 actualAmount = s_aaveV3Adapter.withdraw(type(uint256).max);

        Vm.Log memory log = _assertEmittedBy(keccak256("Withdraw(uint256)"), address(s_aaveV3Adapter));
        assertEq(uint256(log.topics[1]), TVL);
        assertEq(actualAmount, TVL);
        assertEq(s_mockUsdc.balanceOf(address(s_parentVault)), TVL);
        assertEq(s_mockAToken.balanceOf(address(s_aaveV3Adapter)), 0);
    }

    function test_AaveV3Adapter_withdraw_RevertWhen_EpochWithdrawAmountIsLessThanRequested() external {
        s_mockAToken.mint(address(s_aaveV3Adapter), TVL);
        deal(address(s_mockUsdc), address(s_mockAaveV3Pool), INSUFFICIENT_AMOUNT);
        s_mockAaveV3Pool.setWithdrawReturn(INSUFFICIENT_AMOUNT);

        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__IncorrectWithdrawAmount.selector);
        s_aaveV3Adapter.withdraw(TVL);
    }

    function test_AaveV3Adapter_withdraw_RevertWhen_EpochWithdrawShortfallExceedsRoundingTolerance() external {
        s_mockAToken.mint(address(s_aaveV3Adapter), TVL);
        deal(address(s_mockUsdc), address(s_mockAaveV3Pool), EXCESSIVE_SHORTFALL_TVL);
        s_mockAaveV3Pool.setWithdrawReturn(EXCESSIVE_SHORTFALL_TVL);

        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__IncorrectWithdrawAmount.selector);
        s_aaveV3Adapter.withdraw(TVL);
    }

    function test_AaveV3Adapter_withdraw_SucceedsWhen_EpochWithdrawShortfallEqualsRoundingTolerance() external {
        s_mockAToken.mint(address(s_aaveV3Adapter), TVL);
        deal(address(s_mockUsdc), address(s_mockAaveV3Pool), TOLERANCE_SHORTFALL_TVL);
        s_mockAaveV3Pool.setWithdrawReturn(TOLERANCE_SHORTFALL_TVL);

        uint256 actualAmount = s_aaveV3Adapter.withdraw(TVL);

        assertEq(actualAmount, TOLERANCE_SHORTFALL_TVL);
    }

    function test_AaveV3Adapter_withdraw_RevertWhen_EpochWithdrawReturnsZero() external {
        s_mockAToken.mint(address(s_aaveV3Adapter), TVL);
        s_mockAaveV3Pool.setWithdrawReturn(0);

        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__NoZeroAmount.selector);
        s_aaveV3Adapter.withdraw(TVL);
    }

    function test_AaveV3Adapter_withdraw_Success_EpochWithdraw() external {
        s_mockAToken.mint(address(s_aaveV3Adapter), WITHDRAW_AMOUNT);
        deal(address(s_mockUsdc), address(s_mockAaveV3Pool), WITHDRAW_AMOUNT);
        s_mockAaveV3Pool.setWithdrawReturn(WITHDRAW_AMOUNT);

        vm.recordLogs();
        uint256 actualAmount = s_aaveV3Adapter.withdraw(WITHDRAW_AMOUNT);

        Vm.Log memory log = _assertEmittedBy(keccak256("Withdraw(uint256)"), address(s_aaveV3Adapter));
        assertEq(uint256(log.topics[1]), WITHDRAW_AMOUNT);
        assertEq(actualAmount, WITHDRAW_AMOUNT);
        assertEq(s_mockUsdc.balanceOf(address(s_parentVault)), WITHDRAW_AMOUNT);
    }

    function test_AaveV3Adapter_withdraw_Success_EpochWithdrawFromBufferOnly() external {
        _bufferAssets(10);
        s_mockAaveV3Pool.setWithdrawReverts(true);

        uint256 actualAmount = s_aaveV3Adapter.withdraw(10);

        assertEq(actualAmount, 10);
        assertEq(s_aaveV3Adapter.getBufferedAssets(), 0);
        assertEq(s_mockUsdc.balanceOf(address(s_parentVault)), 10);
    }

    function test_AaveV3Adapter_withdraw_Success_EpochWithdrawLeavesUnusedBuffer() external {
        _bufferAssets(10);
        s_mockAaveV3Pool.setWithdrawReverts(true);

        uint256 actualAmount = s_aaveV3Adapter.withdraw(9);

        assertEq(actualAmount, 9);
        assertEq(s_aaveV3Adapter.getBufferedAssets(), 1);
        assertEq(s_aaveV3Adapter.getTVL(), 1);
    }

    function test_AaveV3Adapter_withdraw_Success_EpochWithdrawFromBufferAndProtocol() external {
        uint256 bufferedAmount = 10;
        uint256 protocolAmount = WITHDRAW_AMOUNT - bufferedAmount;
        _bufferAssets(bufferedAmount);
        s_mockAToken.mint(address(s_aaveV3Adapter), protocolAmount);
        deal(address(s_mockUsdc), address(s_mockAaveV3Pool), protocolAmount);
        s_mockAaveV3Pool.setWithdrawReturn(protocolAmount);

        uint256 actualAmount = s_aaveV3Adapter.withdraw(WITHDRAW_AMOUNT);

        assertEq(actualAmount, WITHDRAW_AMOUNT);
        assertEq(s_aaveV3Adapter.getBufferedAssets(), 0);
        assertEq(s_mockUsdc.balanceOf(address(s_parentVault)), WITHDRAW_AMOUNT);
    }

    function test_AaveV3Adapter_withdraw_Success_RebalanceWithdrawFromBufferOnly() external {
        _bufferAssets(10);
        s_mockAaveV3Pool.setWithdrawReverts(true);

        uint256 actualAmount = s_aaveV3Adapter.withdraw(type(uint256).max);

        assertEq(actualAmount, 10);
        assertEq(s_aaveV3Adapter.getBufferedAssets(), 0);
    }

    function test_AaveV3Adapter_withdraw_Success_RebalanceWithdrawFromBufferAndProtocol() external {
        _bufferAssets(1);
        s_mockAToken.mint(address(s_aaveV3Adapter), WITHDRAW_AMOUNT);
        deal(address(s_mockUsdc), address(s_mockAaveV3Pool), WITHDRAW_AMOUNT);

        uint256 actualAmount = s_aaveV3Adapter.withdraw(type(uint256).max);

        assertEq(actualAmount, WITHDRAW_AMOUNT + 1);
        assertEq(s_aaveV3Adapter.getBufferedAssets(), 0);
        assertEq(s_mockUsdc.balanceOf(address(s_parentVault)), WITHDRAW_AMOUNT + 1);
    }

    function test_AaveV3Adapter_withdraw_RevertWhen_ProtocolLegReturnsZeroWithBuffer() external {
        _bufferAssets(1);
        s_mockAToken.mint(address(s_aaveV3Adapter), 1);
        s_mockAaveV3Pool.setWithdrawReturn(0);

        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__NoZeroAmount.selector);
        s_aaveV3Adapter.withdraw(2);

        assertEq(s_aaveV3Adapter.getBufferedAssets(), 1);
    }

    function test_AaveV3Adapter_withdraw_RevertRestoresBufferWhenProtocolFails() external {
        _bufferAssets(1);
        s_mockAToken.mint(address(s_aaveV3Adapter), 1);
        s_mockAaveV3Pool.setWithdrawReverts(true);

        vm.expectRevert();
        s_aaveV3Adapter.withdraw(2);

        assertEq(s_aaveV3Adapter.getBufferedAssets(), 1);
    }

    function _bufferAssets(uint256 amount) internal {
        deal(address(s_mockUsdc), address(s_aaveV3Adapter), amount);
        s_mockAaveV3Pool.setNormalizedIncome((amount + 1) * 1e27);
        s_aaveV3Adapter.deposit(amount);
        s_mockAaveV3Pool.setNormalizedIncome(1e27);
    }
}

contract UnderpayingAaveV3Pool {
    address internal immutable i_aToken;
    uint256 internal immutable i_withdrawReturn;

    constructor(address aToken, uint256 withdrawReturn) {
        i_aToken = aToken;
        i_withdrawReturn = withdrawReturn;
    }

    function withdraw(address asset, uint256, address to) external returns (uint256) {
        IERC20(asset).transfer(to, i_withdrawReturn);
        return i_withdrawReturn;
    }

    function getReserveData(address) external view returns (DataTypes.ReserveDataLegacy memory data) {
        data.aTokenAddress = i_aToken;
    }
}

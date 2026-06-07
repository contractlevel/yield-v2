// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseAaveV4AdapterUnitTest, Vm} from "../BaseAaveV4AdapterUnitTest.t.sol";

import {AaveV4Adapter} from "../../../../src/modules/adapters/AaveV4Adapter.sol";
import {IAaveV4Spoke} from "../../../../src/interfaces/IAaveV4Spoke.sol";
import {IProtocolAdapter} from "../../../../src/interfaces/IProtocolAdapter.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AaveV4Adapter_DepositUnitTest is BaseAaveV4AdapterUnitTest {
    uint256 internal constant PARTIAL_DEPOSIT_AMOUNT = 50 * 1e6;

    function setUp() public {
        deal(address(s_mockUsdc), address(s_aaveV4Adapter), DEPOSIT_AMOUNT);
        _changePrank(address(s_parentVault));
    }

    function test_AaveV4Adapter_deposit_RevertWhen_CallerIsNotVault() external {
        _changePrank(i_nonOwner);
        vm.expectRevert(IProtocolAdapter.ProtocolAdapter__OnlyVault.selector);
        s_aaveV4Adapter.deposit(DEPOSIT_AMOUNT);
    }

    function test_AaveV4Adapter_deposit_RevertWhen_DepositAmountIsLessThanRequested() external {
        PartialSupplyAaveV4Spoke partialSpoke =
            new PartialSupplyAaveV4Spoke(address(s_mockUsdc), PARTIAL_DEPOSIT_AMOUNT);
        AaveV4Adapter adapter =
            new AaveV4Adapter(address(s_parentVault), address(s_mockUsdc), address(partialSpoke));
        deal(address(s_mockUsdc), address(adapter), DEPOSIT_AMOUNT);

        vm.expectRevert(AaveV4Adapter.AaveV4Adapter__IncompleteDeposit.selector);
        adapter.deposit(DEPOSIT_AMOUNT);
    }

    function test_AaveV4Adapter_deposit_Success() external {
        vm.recordLogs();
        s_aaveV4Adapter.deposit(DEPOSIT_AMOUNT);

        Vm.Log memory log = _assertEmittedBy(keccak256("Deposit(uint256)"), address(s_aaveV4Adapter));
        assertEq(uint256(log.topics[1]), DEPOSIT_AMOUNT);
        assertEq(s_mockUsdc.balanceOf(address(s_mockAaveV4Spoke)), DEPOSIT_AMOUNT);
        assertEq(s_aaveV4Adapter.getTVL(), DEPOSIT_AMOUNT);
    }
}

contract PartialSupplyAaveV4Spoke {
    address internal immutable i_underlying;
    uint256 internal immutable i_partialAmount;

    constructor(address underlying, uint256 partialAmount) {
        i_underlying = underlying;
        i_partialAmount = partialAmount;
    }

    function supply(uint256, uint256 amount, address) external returns (uint256, uint256) {
        IERC20(i_underlying).transferFrom(msg.sender, address(this), amount);
        return (i_partialAmount, i_partialAmount);
    }

    function getReserveCount() external pure returns (uint256) {
        return 1;
    }

    function getReserve(uint256) external view returns (IAaveV4Spoke.Reserve memory reserve) {
        reserve.underlying = i_underlying;
    }
}

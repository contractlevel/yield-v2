// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseIntegrationTest} from "../../BaseIntegrationTest.t.sol";

import {IProtocolAdapter} from "../../../../src/interfaces/adapters/IProtocolAdapter.sol";
import {MockAaveV3Pool} from "../../../mocks/MockAaveV3Pool.sol";
import {MockAaveV4Spoke} from "../../../mocks/MockAaveV4Spoke.sol";
import {Types} from "../../../../src/libraries/Types.sol";

import {Client} from "@chainlink/contracts-ccip/contracts/libraries/Client.sol";
import {IAny2EVMMessageReceiver} from "@chainlink/contracts-ccip/contracts/interfaces/IAny2EVMMessageReceiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AaveDust_SecurityIntegrationTest is BaseIntegrationTest {
    function setUp() public override {
        super.setUp();
        _deployLocalParentChildTopology();
    }

    function test_AaveDust_AaveV3BuffersWithoutRecoveryAndFlushesOnNextDeposit() external {
        _setChildActiveAdapter(AAVE_V3_PROTOCOL_ID);
        IProtocolAdapter adapter = IProtocolAdapter(address(child.aaveV3Adapter));
        MockAaveV3Pool(adapter.getProtocolPool()).setNormalizedIncome(2e27);

        _deliverEpochDeposit(1, 1);

        _assertBufferedWithoutRecovery(adapter);

        _deliverEpochDeposit(2, 1);

        assertEq(adapter.getBufferedAssets(), 0);
        assertEq(adapter.getTVL(), 2);
        assertEq(IERC20(parent.asset).balanceOf(adapter.getProtocolPool()), 2);
        assertEq(uint256(child.vault.getRecoveryMode()), uint256(Types.RecoveryMode.NONE));
    }

    function test_AaveDust_AaveV4BuffersWithoutRecoveryAndFlushesOnNextDeposit() external {
        _setChildActiveAdapter(AAVE_V4_PROTOCOL_ID);
        IProtocolAdapter adapter = IProtocolAdapter(address(child.aaveV4Adapter));
        MockAaveV4Spoke(adapter.getProtocolPool()).setMinimumPreviewAmount(2);

        _deliverEpochDeposit(1, 1);

        _assertBufferedWithoutRecovery(adapter);

        _deliverEpochDeposit(2, 1);

        assertEq(adapter.getBufferedAssets(), 0);
        assertEq(adapter.getTVL(), 2);
        assertEq(IERC20(parent.asset).balanceOf(adapter.getProtocolPool()), 2);
        assertEq(uint256(child.vault.getRecoveryMode()), uint256(Types.RecoveryMode.NONE));
    }

    function _assertBufferedWithoutRecovery(IProtocolAdapter adapter) internal view {
        assertEq(adapter.getBufferedAssets(), 1);
        assertEq(adapter.getTVL(), 1);
        assertEq(IERC20(parent.asset).balanceOf(address(adapter)), 1);
        assertEq(IERC20(parent.asset).balanceOf(address(child.vault)), 0);
        assertEq(uint256(child.vault.getRecoveryMode()), uint256(Types.RecoveryMode.NONE));
        assertEq(child.vault.getEpochDepositRecovery().amount, 0);
    }

    function _deliverEpochDeposit(uint256 epochNonce, uint256 amount) internal {
        deal(parent.asset, address(child.vault), amount);

        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: parent.asset, amount: amount});
        Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
            messageId: keccak256(abi.encode("aave-dust", epochNonce)),
            sourceChainSelector: PARENT_CHAIN_SELECTOR,
            sender: abi.encode(address(parent.vault)),
            data: abi.encode(Types.CcipTx.EPOCH_NET_DEPOSIT, abi.encode(epochNonce)),
            destTokenAmounts: tokenAmounts
        });

        _changePrank(address(local.mockCcipRouter));
        IAny2EVMMessageReceiver(address(child.vault)).ccipReceive(message);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {BaseVault, IBaseVault} from "../../../../src/vaults/BaseVault.sol";
import {ChildVault} from "../../../../src/vaults/ChildVault.sol";
import {BaseVaultCcipLib} from "../../../../src/libraries/BaseVaultCcipLib.sol";
import {Types} from "../../../../src/libraries/Types.sol";

contract BaseVaultCcipHarness is ChildVault {
    constructor(BaseVault.ConstructorParams memory params, uint64 parentChainSelector)
        ChildVault(params, parentChainSelector)
    {}

    function exposed_executeCcipSend(
        uint256 bridgeAmount,
        uint64 destinationChainSelector,
        Types.CcipTx ccipTxType,
        bytes memory txData
    ) external {
        BaseVaultCcipLib.send(
            _baseVaultStorage(),
            bridgeAmount,
            destinationChainSelector,
            ccipTxType,
            txData,
            i_asset,
            i_link,
            i_ccipRouter,
            i_thisChainSelector
        );
    }
}

contract BaseVault_ExecuteCcipSendUnitTest is BaseUnitTest {
    BaseVaultCcipHarness internal s_harness;

    function setUp() public {
        BaseVault.ConstructorParams memory params = _baseVaultParams(CHILD_CHAIN_SELECTOR);
        s_harness = new BaseVaultCcipHarness(params, PARENT_CHAIN_SELECTOR);
    }

    function test_BaseVault_executeCcipSend_RevertWhen_BridgeAmountIsZero() external {
        vm.expectRevert(IBaseVault.BaseVault__NoZeroAmount.selector);
        s_harness.exposed_executeCcipSend(0, REMOTE_CHILD_CHAIN_SELECTOR, Types.CcipTx.REBALANCE, "");
    }

    function test_BaseVault_executeCcipSend_RevertWhen_DestinationChainSelectorIsZero() external {
        vm.expectRevert(
            abi.encodeWithSelector(IBaseVault.BaseVault__InvalidDestinationChainSelector.selector, uint64(0))
        );
        s_harness.exposed_executeCcipSend(1, 0, Types.CcipTx.REBALANCE, "");
    }

    function test_BaseVault_executeCcipSend_RevertWhen_DestinationChainSelectorIsSelf() external {
        vm.expectRevert(
            abi.encodeWithSelector(IBaseVault.BaseVault__InvalidDestinationChainSelector.selector, CHILD_CHAIN_SELECTOR)
        );
        s_harness.exposed_executeCcipSend(1, CHILD_CHAIN_SELECTOR, Types.CcipTx.REBALANCE, "");
    }

    function test_BaseVault_executeCcipSend_RevertWhen_DestinationVaultNotRegistered() external {
        vm.expectRevert(
            abi.encodeWithSelector(IBaseVault.BaseVault__DestinationVaultNotSet.selector, REMOTE_CHILD_CHAIN_SELECTOR)
        );
        s_harness.exposed_executeCcipSend(1, REMOTE_CHILD_CHAIN_SELECTOR, Types.CcipTx.REBALANCE, "");
    }
}

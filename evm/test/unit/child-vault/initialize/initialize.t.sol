// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {BaseVault} from "../../../../src/vaults/BaseVault.sol";
import {ChildVault} from "../../../../src/vaults/ChildVault.sol";
import {Types} from "../../../../src/libraries/Types.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract ChildVault_InitializeUnitTest is BaseUnitTest {
    function test_ChildVault_initialize_Success_SetsChildState() external {
        ChildVault childVault = _deployChildVaultProxy();

        Types.EpochRecovery memory epochDepositRecovery = childVault.getEpochDepositRecovery();
        Types.EpochRecovery memory epochWithdrawRecovery = childVault.getEpochWithdrawRecovery();
        Types.RebalanceWithdrawRecovery memory rebalanceWithdrawRecovery = childVault.getRebalanceWithdrawRecovery();
        Types.CcipSendRecovery memory ccipSendRecovery = childVault.getCcipSendRecovery();

        assertEq(childVault.getLastHandledEpochNonce(), 0);
        assertEq(childVault.getLastHandledRebalanceNonce(), 0);
        assertEq(epochDepositRecovery.epochNonce, 0);
        assertEq(epochDepositRecovery.amount, 0);
        assertEq(epochWithdrawRecovery.epochNonce, 0);
        assertEq(epochWithdrawRecovery.amount, 0);
        assertEq(rebalanceWithdrawRecovery.rebalanceNonce, 0);
        assertEq(rebalanceWithdrawRecovery.strategy.protocolId, bytes32(0));
        assertEq(rebalanceWithdrawRecovery.strategy.chainSelector, 0);
        assertEq(uint256(ccipSendRecovery.ccipTxType), uint256(Types.CcipTx.EPOCH_NET_DEPOSIT));
        assertEq(ccipSendRecovery.amount, 0);
        assertEq(ccipSendRecovery.destinationChainSelector, 0);
        assertEq(ccipSendRecovery.nonce, 0);
        assertEq(ccipSendRecovery.protocolId, bytes32(0));
    }

    function _deployChildVaultProxy() internal returns (ChildVault childVault) {
        ChildVault childVaultImpl = new ChildVault(_baseVaultParams(CHILD_CHAIN_SELECTOR), PARENT_CHAIN_SELECTOR);
        childVault = _deployChildVaultProxy(address(childVaultImpl), _baseVaultInitParams());
    }

    function _deployChildVaultProxy(address implementation, BaseVault.InitParams memory initParams)
        internal
        returns (ChildVault childVault)
    {
        ERC1967Proxy childVaultProxy = new ERC1967Proxy(
            implementation, abi.encodeWithSelector(ChildVault.initialize.selector, initParams)
        );
        childVault = ChildVault(address(childVaultProxy));
    }
}

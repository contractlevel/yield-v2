// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest} from "../../BaseUnitTest.t.sol";

import {IChildVault} from "../../../../src/interfaces/vaults/IChildVault.sol";
import {Types} from "../../../../src/libraries/Types.sol";

contract ChildVault_TryCcipSendUnitTest is BaseUnitTest {
    uint256 private constant EPOCH_NONCE = 1;

    function test_ChildVault_AC_007_tryCcipSend_RevertWhen_CallerIsNotSelf() external {
        vm.expectRevert(IChildVault.ChildVault__OnlySelf.selector);
        s_childVault.tryCcipSend(
            DEPOSIT_AMOUNT, PARENT_CHAIN_SELECTOR, Types.CcipTx.EPOCH_NET_DEPOSIT, EPOCH_NONCE, bytes32(0)
        );
    }
}

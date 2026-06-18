// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {HelperHarness} from "../HelperHarness.sol";
import {IPolicyEngine} from "@chainlink/policy-management/interfaces/IPolicyEngine.sol";
import {YieldcoinShare} from "../../../src/token/YieldcoinShare.sol";

contract YieldcoinShareHarness is YieldcoinShare, HelperHarness {
    /// @dev OZ Initializable ERC-7201 slot: keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /// @dev Returns true if the contract has been initialized (OZ _initialized >= 1).
    ///      _initialized is uint64 packed at the low 8 bytes of INITIALIZABLE_STORAGE.
    function isInitialized() external view returns (bool) {
        uint64 version;
        assembly {
            version := and(sload(0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00), 0xFFFFFFFFFFFFFFFF)
        }
        return version > 0;
    }

    /// @dev Returns true if OZ _initializing == true.
    ///      _initializing is a bool packed at byte 8 (bits 64-71) of INITIALIZABLE_STORAGE.
    ///      Certora can freely havoc this to true, making isTopLevelCall=false and the
    ///      initializer modifier revert with InvalidInitialization before the function body runs.
    function isInitializing() external view returns (bool) {
        uint256 slotVal;
        assembly {
            slotVal := sload(0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00)
        }
        return (slotVal >> 64) & 0xFF != 0;
    }

    /// @dev Certora-facing handle for the policy engine presence check.
    ///      address(0)  → _runPolicyBefore reverts with PolicyEngineUndefined (models no engine)
    ///      non-zero    → _runPolicyBefore succeeds (models an always-allowing engine, ENV-003)
    address public s_mockPolicyEngine;

    /// @dev Override _runPolicyBefore to avoid external calls to the ERC-7201 policy engine
    ///      storage slot, which Certora cannot link directly.  The ENV-003 assumption (ACE
    ///      policy wiring is correct) means we only need to model presence vs absence.
    function _runPolicyBefore() internal override {
        if (s_mockPolicyEngine == address(0)) {
            revert IPolicyEngine.PolicyEngineUndefined();
        }
    }

    /// @dev Override _runPolicyAfter to avoid reading senderContext from the ERC-7201 slot,
    ///      whose arbitrary Certora-havoced bytes encoding causes spurious reverts.
    function _runPolicyAfter() internal override {}

    /// @dev Override getPolicyEngine so spec rules that read getPolicyEngine() stay consistent
    ///      with the _runPolicyBefore override above.
    function getPolicyEngine() public view override returns (address) {
        return s_mockPolicyEngine;
    }
}

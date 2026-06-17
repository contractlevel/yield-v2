// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

/// @title HelperHarness
/// @author @contractlevel
/// @notice HelperHarness to use in CVL specs
contract HelperHarness {
    function bytes32ToAddress(bytes32 b) external returns (address) {
        return address(uint160(uint256(b)));
    }

    function bytes32ToUint256(bytes32 b) public pure returns (uint256) {
        return uint256(b);
    }

    function bytes32ToBytes4(bytes32 b) external pure returns (bytes4) {
        return bytes4(b);
    }

    function bytes32ToBytes10(bytes32 b) external pure returns (bytes10) {
        return bytes10(b);
    }

    function bytes32ToBool(bytes32 b) external pure returns (bool) {
        return uint256(b) != 0;
    }

    function bytesToAddress(bytes memory value) external pure returns (address decoded) {
        decoded = abi.decode(value, (address));
    }

    function bytesToAddressArray(bytes memory value) external pure returns (address[] memory decoded) {
        decoded = abi.decode(value, (address[]));
    }

    function emptyParameters() external pure returns (bytes[] memory parameters) {
        parameters = new bytes[](0);
    }

    /*//////////////////////////////////////////////////////////////
                                 ROLES
    //////////////////////////////////////////////////////////////*/
    function UPGRADER_ROLE() public returns (bytes32) {
        return keccak256("UPGRADER_ROLE");
    }

    function PAUSER_ROLE() public returns (bytes32) {
        return keccak256("PAUSER_ROLE");
    }

    function UNPAUSER_ROLE() public returns (bytes32) {
        return keccak256("UNPAUSER_ROLE");
    }

    function CONFIG_OPERATOR_ROLE() public returns (bytes32) {
        return keccak256("CONFIG_OPERATOR_ROLE");
    }

    function REBALANCE_OPERATOR_ROLE() public returns (bytes32) {
        return keccak256("REBALANCE_OPERATOR_ROLE");
    }

    function EPOCH_OPERATOR_ROLE() public returns (bytes32) {
        return keccak256("EPOCH_OPERATOR_ROLE");
    }

    function LINK_OPERATOR_ROLE() public returns (bytes32) {
        return keccak256("LINK_OPERATOR_ROLE");
    }

    function DONATE_OPERATOR_ROLE() public returns (bytes32) {
        return keccak256("DONATE_OPERATOR_ROLE");
    }

    function COMPLIANCE_OPERATOR_ROLE() public returns (bytes32) {
        return keccak256("COMPLIANCE_OPERATOR_ROLE");
    }

    function EMERGENCY_DRAINER_ROLE() public returns (bytes32) {
        return keccak256("EMERGENCY_DRAINER_ROLE");
    }

    function KEYSTONE_FORWARDER_ROLE() public returns (bytes32) {
        return keccak256("KEYSTONE_FORWARDER_ROLE");
    }

    function POLICY_ENGINE_MANAGER_ROLE() public returns (bytes32) {
        return keccak256("POLICY_ENGINE_MANAGER_ROLE");
    }

    function MINTER_ROLE() public returns (bytes32) {
        return keccak256("MINTER_ROLE");
    }

    function BURNER_ROLE() public returns (bytes32) {
        return keccak256("BURNER_ROLE");
    }

    function REWARDS_OPERATOR_ROLE() public returns (bytes32) {
        return keccak256("REWARDS_OPERATOR_ROLE");
    }
}

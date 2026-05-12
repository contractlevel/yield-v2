// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

abstract contract Constants {
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    uint64 internal constant CHAIN_SELECTOR = 5009297550715157269;
    uint64 internal constant PARENT_CHAIN_SELECTOR = 1;
    uint64 internal constant CHILD_CHAIN_SELECTOR = 2;

    uint256 internal constant PENDING_DEPOSIT_TIMEOUT = 20 minutes;
    uint48 internal constant INITIAL_DEFAULT_ADMIN_DELAY = 259200; // 3 days

    bytes32 internal constant AAVE_V3_PROTOCOL_ID = keccak256("aave-v3");
    bytes32 internal constant AAVE_V4_PROTOCOL_ID = keccak256("aave-v4");

    uint256 internal constant MIN_DEPOSIT_AMOUNT = 100 * 1e6;
    uint256 internal constant SHARE_PRECISION = 1e12;
    uint256 internal constant MIN_EPOCH_PERIOD = 1 hours;

    bytes32 internal constant KYC_CREDENTIAL = keccak256("common.kyc");
    bytes32 internal constant KYC_REQUIREMENT = keccak256("KYC");
    bytes32 internal constant AML_CREDENTIAL = keccak256("common.aml");
    bytes32 internal constant AML_REQUIREMENT = keccak256("AML");
}

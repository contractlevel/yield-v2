// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract TestnetProtocolAccess is Ownable2Step {
    error TestnetProtocolAccess__CallerNotAllowed(address caller);
    error TestnetProtocolAccess__NoZeroAddress();

    mapping(address caller => bool allowed) public isAllowedCaller;

    event AllowedCallerSet(address indexed caller, bool allowed);

    constructor(address initialOwner) Ownable(initialOwner) {}

    modifier onlyAllowedCaller() {
        if (!isAllowedCaller[msg.sender]) revert TestnetProtocolAccess__CallerNotAllowed(msg.sender);
        _;
    }

    function setAllowedCaller(address caller, bool allowed) external onlyOwner {
        if (caller == address(0)) revert TestnetProtocolAccess__NoZeroAddress();
        isAllowedCaller[caller] = allowed;
        emit AllowedCallerSet(caller, allowed);
    }
}

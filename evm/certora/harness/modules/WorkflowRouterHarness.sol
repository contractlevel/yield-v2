// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {HelperHarness} from "../HelperHarness.sol";

import {WorkflowRouter} from "../../../src/modules/WorkflowRouter.sol";

contract WorkflowRouterHarness is WorkflowRouter, HelperHarness {
    constructor(WorkflowRouter.ConstructorParams memory params) WorkflowRouter(params) {}
}

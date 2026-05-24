// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MockUSDC} from "../../mocks/MockUSDC.sol";
import {Setup} from "../epoch/Setup.t.sol";

abstract contract ActorGhosts is Setup {
    address[] internal s_actors;
    address internal s_currentActor;

    mapping(address actor => bool seen) internal ghost_actorSeen;

    uint256 internal constant INVARIANT_ACTOR_USDC_BALANCE = type(uint128).max;

    function _setupInvariantActors() internal virtual override {
        _addActor(i_depositor);
        _addActor(i_withdrawer);
        _addActor(i_recipient1);
        _addActor(i_recipient2);

        for (uint256 i; i < s_actors.length; ++i) {
            _registerKyc(s_actors[i]);
            MockUSDC(parent.vault.getUsdc()).mint(s_actors[i], INVARIANT_ACTOR_USDC_BALANCE);
            _changePrank(s_actors[i]);
            IERC20(parent.vault.getUsdc()).approve(address(parent.vault), type(uint256).max);
            parent.share.approve(address(parent.vault), type(uint256).max);
        }

        s_currentActor = s_actors[0];
    }

    function _addActor(address actor) internal {
        s_actors.push(actor);
        ghost_actorSeen[actor] = true;
    }

    function _actor(uint256 actorSeed) internal view returns (address) {
        return s_actors[_boundToRange(actorSeed, 0, s_actors.length - 1)];
    }
}

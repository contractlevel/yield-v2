// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IAaveV4Spoke} from "../../../../../src/interfaces/external/IAaveV4Spoke.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockAaveV4Spoke is IAaveV4Spoke {
    address internal immutable i_underlying;
    address internal immutable i_hub;
    uint16 internal immutable i_hubAssetId;

    mapping(uint256 reserveId => mapping(address user => uint256 suppliedAssets)) internal s_suppliedAssets;

    bool public s_decreaseTVLOnSupply;
    bool public s_supplyReverts;
    bool public s_withdrawReverts;
    uint256 public s_supplyTVLChange;
    uint256 public s_withdrawAmount;
    bytes public s_supplyRevertReason;

    bool public s_supplyCalled;
    address public s_supplyCaller;
    uint256 public s_supplyReserveId;
    uint256 public s_supplyAmount;
    address public s_supplyOnBehalfOf;

    constructor(address underlying, address hub, uint16 hubAssetId) {
        i_underlying = underlying;
        i_hub = hub;
        i_hubAssetId = hubAssetId;
    }

    function setSupplyRevertReason(bytes calldata reason) external {
        s_supplyRevertReason = reason;
    }

    function supply(uint256 reserveId, uint256 amount, address onBehalfOf)
        external
        returns (uint256 suppliedShares, uint256 suppliedAmount)
    {
        if (s_supplyReverts) {
            _revertSupply();
        }
        s_supplyCalled = true;
        s_supplyCaller = msg.sender;
        s_supplyReserveId = reserveId;
        s_supplyAmount = amount;
        s_supplyOnBehalfOf = onBehalfOf;
        IERC20(i_underlying).transferFrom(msg.sender, address(this), amount);
        if (s_decreaseTVLOnSupply) s_suppliedAssets[reserveId][onBehalfOf] -= s_supplyTVLChange;
        else s_suppliedAssets[reserveId][onBehalfOf] += s_supplyTVLChange;

        return (s_supplyTVLChange, s_supplyTVLChange);
    }

    function _revertSupply() internal view virtual {
        bytes memory reason = s_supplyRevertReason;
        assembly ("memory-safe") {
            revert(add(reason, 0x20), mload(reason))
        }
    }

    function withdraw(uint256 reserveId, uint256 amount, address to)
        external
        returns (uint256 withdrawnShares, uint256 withdrawnAmount)
    {
        require(!s_withdrawReverts);
        uint256 suppliedAssets = s_suppliedAssets[reserveId][msg.sender];
        uint256 tvlChange = amount == type(uint256).max ? suppliedAssets : amount;
        withdrawnAmount = s_withdrawAmount;

        require(tvlChange <= suppliedAssets);

        s_suppliedAssets[reserveId][msg.sender] = suppliedAssets - tvlChange;
        IERC20(i_underlying).transfer(to, withdrawnAmount);

        return (withdrawnAmount, withdrawnAmount);
    }

    function getUserSuppliedAssets(uint256 reserveId, address user) external view returns (uint256 suppliedAssets) {
        suppliedAssets = s_suppliedAssets[reserveId][user];
    }

    function getReserveCount() external pure returns (uint256 reserveCount) {
        reserveCount = 1;
    }

    function getReserve(uint256) external view returns (Reserve memory reserve) {
        reserve.underlying = i_underlying;
        reserve.hub = i_hub;
        reserve.assetId = i_hubAssetId;
        reserve.decimals = 6;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {HelperHarness} from "../../HelperHarness.sol";

import {AaveV4Adapter} from "../../../../src/modules/adapters/AaveV4Adapter.sol";
import {MockAaveV4Spoke} from "./mocks/MockAaveV4Spoke.sol";
import {IAaveV4Hub} from "../../../../src/interfaces/external/IAaveV4Hub.sol";
import {IAaveV4Adapter} from "../../../../src/interfaces/adapters/IAaveV4Adapter.sol";
import {MockAaveV4Hub} from "./mocks/MockAaveV4Hub.sol";

contract AaveV4AdapterHarness is AaveV4Adapter, HelperHarness {
    constructor(address vault, address spoke) AaveV4Adapter(vault, spoke) {}

    function mockUsesBufferedAssets() external pure returns (bool) {
        return true;
    }

    function mockDepositCanSupply(uint256 amount) external view returns (bool) {
        MockAaveV4Spoke spoke = MockAaveV4Spoke(i_spoke);
        // Exclude the InvalidShares fallback covered by the adapter-specific rules.
        if (
            spoke.s_supplyReverts()
                && _isExactRevert(spoke.s_supplyRevertReason(), IAaveV4Adapter.InvalidShares.selector)
        ) {
            return false;
        }
        return
            !MockAaveV4Hub(i_hub).s_previewReverts() && IAaveV4Hub(i_hub).previewAddByAssets(i_hubAssetId, amount) != 0;
    }

    function mockDepositCanBuffer(uint256 amount) external view returns (bool) {
        return
            !MockAaveV4Hub(i_hub).s_previewReverts() && IAaveV4Hub(i_hub).previewAddByAssets(i_hubAssetId, amount) == 0;
    }

    function getHub() external view returns (address) {
        return i_hub;
    }

    function getHubAssetId() external view returns (uint256) {
        return i_hubAssetId;
    }

    function invalidSharesSelector() external pure returns (bytes4) {
        return IAaveV4Adapter.InvalidShares.selector;
    }

    function isExactRevert(bytes calldata reason, bytes4 selector) external pure returns (bool) {
        return _isExactRevert(reason, selector);
    }

    function bufferedAssetsLimitExceededSelector() external pure returns (bytes4) {
        return ProtocolAdapter__BufferedAssetsLimitExceeded.selector;
    }

    function buildRevertReason(bytes4 selector, bytes calldata suffix) external pure returns (bytes memory) {
        return abi.encodePacked(selector, suffix);
    }

    function buildShortRevertReason(bytes3 prefix, uint8 length) external pure returns (bytes memory reason) {
        require(length < 4);
        reason = abi.encodePacked(prefix);
        assembly ("memory-safe") {
            mstore(reason, length)
        }
    }

    function mockDepositDecreasesTVL() external view returns (bool) {
        return MockAaveV4Spoke(i_spoke).s_decreaseTVLOnSupply();
    }

    function mockDepositReverts() external view returns (bool) {
        return MockAaveV4Spoke(i_spoke).s_supplyReverts();
    }

    function mockWithdrawReverts() external view returns (bool) {
        return MockAaveV4Spoke(i_spoke).s_withdrawReverts();
    }

    function mockDepositTVLChange() external view returns (uint256) {
        return MockAaveV4Spoke(i_spoke).s_supplyTVLChange();
    }

    function mockWithdrawAmount() external view returns (uint256) {
        return MockAaveV4Spoke(i_spoke).s_withdrawAmount();
    }
}

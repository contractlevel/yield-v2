// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IProtocolAdapter} from "../interfaces/adapters/IProtocolAdapter.sol";
import {IBaseVault} from "../interfaces/vaults/IBaseVault.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title Yieldcoin v2 Protocol Adapter
/// @author @contractlevel
/// @notice Base contract for protocol adapters
abstract contract ProtocolAdapter is IProtocolAdapter, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Small tolerance for protocol-side share/index rounding on deposit and withdraw (e.g. Aave's
    /// ray-scaled aToken mint/balanceOf round-trip, Compound's base-index principal rounding)
    uint256 internal constant WEI_TOLERANCE = 100;

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLE
    //////////////////////////////////////////////////////////////*/
    /// @dev The Yieldcoin v2 Vault on this chain
    address internal immutable i_vault;
    /// @dev The underlying asset token
    address internal immutable i_asset;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @param vault The address of the Yieldcoin v2 Vault
    /// @dev Reverts if vault is the zero address
    constructor(address vault) {
        _revertIfZeroAddress(vault);

        i_vault = vault;
        i_asset = IBaseVault(vault).getAsset();
    }

    /// @notice Validates that a required address is nonzero
    /// @param value The address to validate
    /// @dev Reverts if value is the zero address
    function _revertIfZeroAddress(address value) internal pure {
        if (value == address(0)) revert ProtocolAdapter__NoZeroAddress();
    }

    /// @notice Validates that an epoch withdrawal does not exceed the adapter's position value
    /// @param amount The requested epoch withdrawal amount
    /// @param tvl The adapter's position value before withdrawing, denominated in the underlying asset
    /// @dev Reverts if amount exceeds tvl
    function _revertIfEpochWithdrawAmountExceedsTVL(uint256 amount, uint256 tvl) internal pure {
        if (amount > tvl) revert ProtocolAdapter__WithdrawAmountExceedsTotalValue();
    }

    /// @notice Validates that the protocol and adapter use the same underlying asset
    /// @param protocolAsset The asset reported by the wired protocol contract
    /// @param vaultAsset The adapter's underlying asset
    /// @dev Reverts if protocolAsset does not equal vaultAsset
    function _revertIfAssetMismatch(address protocolAsset, address vaultAsset) internal pure {
        if (protocolAsset != vaultAsset) revert ProtocolAdapter__AssetMismatch();
    }

    /// @notice Validates the position-value increase produced by a protocol deposit
    /// @param tvlBefore The adapter's position value before depositing
    /// @param tvlAfter The adapter's position value after depositing
    /// @param amount The amount requested to be deposited
    /// @dev Reverts if tvlAfter is less than tvlBefore
    /// @dev Reverts if the credited amount is less than amount beyond WEI_TOLERANCE
    function _revertIfIncompleteDeposit(uint256 tvlBefore, uint256 tvlAfter, uint256 amount) internal pure {
        if (tvlAfter < tvlBefore) revert ProtocolAdapter__TVLDecreasedOnDeposit();

        uint256 creditedAmount = tvlAfter - tvlBefore;
        if (creditedAmount < amount && amount - creditedAmount > WEI_TOLERANCE) {
            revert ProtocolAdapter__IncompleteDeposit();
        }
    }

    /// @notice Validates the amount returned by a protocol withdrawal
    /// @param expectedAmount The expected withdrawn amount (requested amount, or TVL for full withdrawals)
    /// @param actualAmount The actual amount withdrawn from the protocol
    /// @dev Reverts if actualAmount is zero
    /// @dev Reverts if actualAmount is less than expectedAmount beyond WEI_TOLERANCE
    function _revertIfIncompleteWithdraw(uint256 expectedAmount, uint256 actualAmount) internal pure {
        //slither-disable-next-line incorrect-equality
        if (actualAmount == 0) revert ProtocolAdapter__NoZeroAmount();
        if (actualAmount < expectedAmount && expectedAmount - actualAmount > WEI_TOLERANCE) {
            revert ProtocolAdapter__IncorrectWithdrawAmount();
        }
    }

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    /// @dev Reverts if the caller is not the Yieldcoin v2 Vault
    modifier onlyVault() {
        _onlyVault();
        _;
    }

    /// @notice Validates that the caller is the Yieldcoin v2 Vault
    /// @dev Reverts if the caller is not i_vault
    function _onlyVault() internal view {
        if (msg.sender != i_vault) revert ProtocolAdapter__OnlyVault();
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns the Yieldcoin v2 Vault authorized to call this adapter
    /// @return vault The vault address
    function getVault() external view returns (address vault) {
        vault = i_vault;
    }

    /// @notice Returns the underlying asset token used by this adapter
    /// @return asset The underlying asset token address
    function getAsset() external view returns (address asset) {
        asset = i_asset;
    }
}

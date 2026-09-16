import "ParentVault.rules.spec";

/// @notice Verify ParentVault deposit reconciliation using the mathematical contract of the unchanged math helper.
/// @dev This target assumes mulDivDown's arithmetic contract, rather than reproving Solady assembly in ParentVault.
///      Native reconciliation is verified separately in ParentVaultEpochLib.spec and the Foundry lifecycle tests.
methods {
    function _._mulDivDown(uint256 x, uint256 y, uint256 denominator) internal
        => reconciliationMulDivDown(x, y, denominator) expect uint256;
}

function reconciliationMulDivDown(uint256 x, uint256 y, uint256 denominator) returns uint256 {
    /// @dev The reconciliation branch has positive gross deposits and an effective deposit below the gross amount.
    ///      Assert the summary's domain so unexpected invalid arithmetic cannot be silently excluded.
    assert denominator > 0, "reconciliation denominator is positive";
    mathint result = to_mathint(x) * to_mathint(y) / to_mathint(denominator);
    assert result <= max_uint256, "reconciliation quotient fits uint256";
    return assert_uint256(result);
}

use rule EPOCH_014_completeEpochDeposit_Success_WhenActualDepositIsShort;
use rule EPOCH_014_completeEpochDeposit_Success_UsesFullPrecisionForShareAdjustment;

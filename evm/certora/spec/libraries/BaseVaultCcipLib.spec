using MockUSDC as asset;
using MockLINK as link;
using MockCCIPRouter as ccipRouter;

/// Verification of BaseVaultCcipLib
/// @author @contractlevel
/// @notice BaseVaultCcipLib handles shared CCIP validation and message sending for BaseVault implementations.

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    // Harness storage getters
    function getCrosschainVault(uint64) external returns (address) envfree;
    function getCcipGasLimit(uint64) external returns (uint256) envfree;
    function getResolvedCcipGasLimit(uint64) external returns (uint256) envfree;
    function getDefaultCcipGasLimit() external returns (uint256) envfree;
    function getAsset() external returns (address) envfree;
    function getRouter() external returns (address) envfree;

    // Library internal wrappers
    function onlyAllowedSender(address, uint64) external;
    function validateCcipSend(uint256, uint64, uint64) external returns (address);
    function executeCcipSend(uint256, uint64, Types.CcipTx, bytes, uint64) external;
    function validateReceivedTokenAndGetAmount(Client.Any2EVMMessage) external returns (uint256);

    // Mock methods
    function asset.balanceOf(address) external returns (uint256) envfree;
    function link.balanceOf(address) external returns (uint256) envfree;
    function ccipRouter.getFee() external returns (uint256) envfree;
    function ccipRouter.getFeeReverts() external returns (bool) envfree;
    function ccipRouter.ccipSendReverts() external returns (bool) envfree;
    function ccipRouter.getLastMessageDataHash() external returns (bytes32) envfree;

    // Harness helper methods
    function bytes32ToUint256(bytes32) external returns (uint256) envfree;
    function bytes32ToUint8(bytes32) external returns (uint8) envfree;
    function uint8ToCcipTxType(uint8) external returns (Types.CcipTx) envfree;
    function encodeEpochNonce(uint256) external returns (bytes) envfree;
    function encodeCcipTxData(Types.CcipTx, bytes) external returns (bytes) envfree;
    function hashBytes(bytes) external returns (bytes32) envfree;

    // Dispatcher summaries
    function _.transfer(address, uint256) external => DISPATCHER(true);
    function _.transferFrom(address, address, uint256) external => DISPATCHER(true);
    function _.balanceOf(address) external => DISPATCHER(true);
    function _.approve(address, uint256) external => DISPATCHER(true);
    function _.forceApprove(address, uint256) external => DISPATCHER(true);

    function _.getFee(uint64, Client.EVM2AnyMessage) external => DISPATCHER(true);
    function _.ccipSend(uint64, Client.EVM2AnyMessage) external => DISPATCHER(true);
}

/*//////////////////////////////////////////////////////////////
                         DEFINITIONS
//////////////////////////////////////////////////////////////*/
definition CCIPBridgedEvent() returns bytes32 =
// keccak256("CCIPBridged(bytes32,uint256,uint8)")
    to_bytes32(0x39e716d942b34d57d78c584f648ec8e13b9621c6e5b1a57d18ef47a98b11b39d);

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
/// @notice EventCount: track amount CCIPBridged event is emitted
ghost mathint ghost_CCIPBridged_EventCount {
    init_state axiom ghost_CCIPBridged_EventCount == 0;
}

/// @notice EmittedValue: track ccipMessageId param emitted in CCIPBridged event
ghost bytes32 ghost_CCIPBridged_Param_ccipMessageId {
    init_state axiom ghost_CCIPBridged_Param_ccipMessageId == to_bytes32(0);
}

/// @notice EmittedValue: track amount param emitted in CCIPBridged event
ghost uint256 ghost_CCIPBridged_Param_amount {
    init_state axiom ghost_CCIPBridged_Param_amount == 0;
}

/// @notice EmittedValue: track ccipTxType param emitted in CCIPBridged event
ghost Types.CcipTx ghost_CCIPBridged_Param_ccipTxType {
    init_state axiom ghost_CCIPBridged_Param_ccipTxType == Types.CcipTx.EPOCH_NET_DEPOSIT;
}

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/
/// @notice hook onto emitted events and increment relevant ghosts
hook LOG4(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2, bytes32 t3) {
    if (t0 == CCIPBridgedEvent()) {
        ghost_CCIPBridged_EventCount = ghost_CCIPBridged_EventCount + 1;
        ghost_CCIPBridged_Param_ccipMessageId = t1;
        ghost_CCIPBridged_Param_amount = bytes32ToUint256(t2);
        ghost_CCIPBridged_Param_ccipTxType = uint8ToCcipTxType(bytes32ToUint8(t3));
    }
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
/// ─────────────────── ONLY ALLOWED SENDER ──────────────────

/// @notice Sender validation reverts when no vault is registered for the source chain.
/// @dev Verifies that an unset cross-chain vault cannot authorize the zero address or modify harness storage.
rule onlyAllowedSender_RevertWhen_RegisteredVaultIsZero() {
    env e;
    address sender;
    uint64 srcChainSelector;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "onlyAllowedSender is nonpayable";
    require sender == 0, "exclude sender mismatch revert";

    /// @dev revert condition being verified
    require getCrosschainVault(srcChainSelector) == 0, "registered vault is zero";

    storage before = lastStorage;

    onlyAllowedSender@withrevert(e, sender, srcChainSelector);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Sender validation reverts when the sender is not the registered vault for the source chain.
/// @dev Verifies that sender validation does not modify harness storage.
rule onlyAllowedSender_RevertWhen_SenderIsNotRegisteredVault() {
    env e;
    address sender;
    uint64 srcChainSelector;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "onlyAllowedSender is nonpayable";
    require getCrosschainVault(srcChainSelector) != 0, "registered vault is nonzero";

    /// @dev revert condition being verified
    require sender != getCrosschainVault(srcChainSelector), "sender is not the registered vault";

    storage before = lastStorage;

    onlyAllowedSender@withrevert(e, sender, srcChainSelector);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Sender validation succeeds for the registered vault of the source chain.
/// @dev Verifies that successful sender validation does not modify harness storage.
rule onlyAllowedSender_SuccessWhen_SenderIsRegisteredVault() {
    env e;
    address sender;
    uint64 srcChainSelector;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "onlyAllowedSender is nonpayable";

    /// @dev success conditions being verified
    require getCrosschainVault(srcChainSelector) != 0, "registered vault is nonzero";
    require sender == getCrosschainVault(srcChainSelector), "sender is the registered vault";

    storage before = lastStorage;

    onlyAllowedSender@withrevert(e, sender, srcChainSelector);

    assert !lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// ─────────────────── VALIDATE CCIP SEND ─────────────────────

/// @notice CCIP send validation reverts when the bridge amount is zero.
/// @dev Verifies that validation does not modify harness storage.
rule validateCcipSend_RevertWhen_BridgeAmountIsZero() {
    env e;
    uint64 destinationChainSelector;
    uint64 thisChainSelector;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "validateCcipSend is nonpayable";
    require destinationChainSelector != 0, "destination chain selector is nonzero";
    require destinationChainSelector != thisChainSelector, "destination is not this chain";
    require getCrosschainVault(destinationChainSelector) != 0, "destination vault is registered";

    /// @dev revert condition being verified
    uint256 bridgeAmount = 0;

    storage before = lastStorage;

    validateCcipSend@withrevert(e, bridgeAmount, destinationChainSelector, thisChainSelector);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice CCIP send validation reverts when the destination chain selector is zero.
/// @dev Verifies that validation does not modify harness storage.
rule validateCcipSend_RevertWhen_DestinationChainIsZero() {
    env e;
    uint256 bridgeAmount;
    uint64 thisChainSelector;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "validateCcipSend is nonpayable";
    require bridgeAmount != 0, "bridge amount is nonzero";

    /// @dev revert condition being verified
    uint64 destinationChainSelector = 0;

    storage before = lastStorage;

    validateCcipSend@withrevert(e, bridgeAmount, destinationChainSelector, thisChainSelector);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice CCIP send validation reverts when the destination chain selector is this chain.
/// @dev Verifies that validation does not modify harness storage.
rule validateCcipSend_RevertWhen_DestinationIsSelfChain() {
    env e;
    uint256 bridgeAmount;
    uint64 thisChainSelector;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "validateCcipSend is nonpayable";
    require bridgeAmount != 0, "bridge amount is nonzero";

    /// @dev revert condition being verified
    uint64 destinationChainSelector = thisChainSelector;

    storage before = lastStorage;

    validateCcipSend@withrevert(e, bridgeAmount, destinationChainSelector, thisChainSelector);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice CCIP send validation reverts when no vault is registered for the destination chain.
/// @dev Verifies that validation does not modify harness storage.
rule validateCcipSend_RevertWhen_DestinationVaultNotRegistered() {
    env e;
    uint256 bridgeAmount;
    uint64 destinationChainSelector;
    uint64 thisChainSelector;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "validateCcipSend is nonpayable";
    require bridgeAmount != 0, "bridge amount is nonzero";
    require destinationChainSelector != 0, "destination chain selector is nonzero";
    require destinationChainSelector != thisChainSelector, "destination is not this chain";

    /// @dev revert condition being verified
    require getCrosschainVault(destinationChainSelector) == 0, "destination vault is not registered";

    storage before = lastStorage;

    validateCcipSend@withrevert(e, bridgeAmount, destinationChainSelector, thisChainSelector);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice CCIP send validation returns the registered destination vault.
/// @dev Verifies the returned vault and that validation does not modify harness storage.
rule validateCcipSend_Success() {
    env e;
    uint256 bridgeAmount;
    uint64 destinationChainSelector;
    uint64 thisChainSelector;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "validateCcipSend is nonpayable";

    /// @dev success conditions being verified
    require bridgeAmount != 0, "bridge amount is nonzero";
    require destinationChainSelector != 0, "destination chain selector is nonzero";
    require destinationChainSelector != thisChainSelector, "destination is not this chain";
    require getCrosschainVault(destinationChainSelector) != 0, "destination vault is registered";

    address expectedVault = getCrosschainVault(destinationChainSelector);
    storage before = lastStorage;

    address vault = validateCcipSend@withrevert(e, bridgeAmount, destinationChainSelector, thisChainSelector);

    assert !lastReverted;
    assert vault == expectedVault;
    assert before[currentContract] == lastStorage[currentContract];
}

/// ─────────────────── CCIP GAS LIMIT ─────────────────────

/// @notice Resolved CCIP gas limit returns the per-chain override when one is set.
/// @dev Verifies override precedence over the default gas limit.
rule getResolvedCcipGasLimit_ReturnsOverrideWhenSet() {
    uint64 chainSelector;

    /// @dev fallback condition NOT being verified
    require getCcipGasLimit(chainSelector) != 0, "gas limit override is set";

    assert getResolvedCcipGasLimit(chainSelector) == getCcipGasLimit(chainSelector);
}

/// @notice Resolved CCIP gas limit returns the default gas limit when no override is set.
/// @dev Verifies zero override values fall back to the default gas limit.
rule getResolvedCcipGasLimit_ReturnsDefaultWhenOverrideUnset() {
    uint64 chainSelector;

    /// @dev override condition NOT being verified
    require getCcipGasLimit(chainSelector) == 0, "gas limit override is unset";

    assert getResolvedCcipGasLimit(chainSelector) == getDefaultCcipGasLimit();
}

/// ─────────────────── EXECUTE CCIP SEND ──────────────────────

/// @notice Executing a CCIP send reverts when the bridge amount is zero.
/// @dev Verifies that no CCIPBridged event is emitted.
rule executeCcipSend_RevertWhen_BridgeAmountIsZero() {
    env e;
    uint64 destSelector;
    uint64 thisChainSelector;
    Types.CcipTx ccipTxType;
    bytes txData;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "executeCcipSend is nonpayable";
    require destSelector != 0, "destination chain selector is nonzero";
    require destSelector != thisChainSelector, "destination is not this chain";
    require getCrosschainVault(destSelector) != 0, "destination vault is registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup does not revert";
    require !ccipRouter.ccipSendReverts(), "router send does not revert";

    /// @dev revert condition being verified
    uint256 bridgeAmount = 0;

    /// @dev ghost starting values
    require ghost_CCIPBridged_EventCount == 0, "CCIPBridged event count starts at zero";

    executeCcipSend@withrevert(e, bridgeAmount, destSelector, ccipTxType, txData, thisChainSelector);

    assert lastReverted;
    assert ghost_CCIPBridged_EventCount == 0;
}

/// @notice Executing a CCIP send reverts when the destination chain selector is zero.
/// @dev Verifies that no CCIPBridged event is emitted.
rule executeCcipSend_RevertWhen_DestinationChainIsZero() {
    env e;
    uint256 bridgeAmount;
    uint64 thisChainSelector;
    Types.CcipTx ccipTxType;
    bytes txData;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "executeCcipSend is nonpayable";
    require bridgeAmount != 0, "bridge amount is nonzero";
    require !ccipRouter.getFeeReverts(), "router fee lookup does not revert";
    require !ccipRouter.ccipSendReverts(), "router send does not revert";

    /// @dev revert condition being verified
    uint64 destSelector = 0;

    /// @dev ghost starting values
    require ghost_CCIPBridged_EventCount == 0, "CCIPBridged event count starts at zero";

    executeCcipSend@withrevert(e, bridgeAmount, destSelector, ccipTxType, txData, thisChainSelector);

    assert lastReverted;
    assert ghost_CCIPBridged_EventCount == 0;
}

/// @notice Executing a CCIP send reverts when the destination is this chain.
/// @dev Verifies that no CCIPBridged event is emitted.
rule executeCcipSend_RevertWhen_DestinationIsSelfChain() {
    env e;
    uint256 bridgeAmount;
    uint64 thisChainSelector;
    Types.CcipTx ccipTxType;
    bytes txData;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "executeCcipSend is nonpayable";
    require bridgeAmount != 0, "bridge amount is nonzero";
    require !ccipRouter.getFeeReverts(), "router fee lookup does not revert";
    require !ccipRouter.ccipSendReverts(), "router send does not revert";

    /// @dev revert condition being verified
    uint64 destSelector = thisChainSelector;

    /// @dev ghost starting values
    require ghost_CCIPBridged_EventCount == 0, "CCIPBridged event count starts at zero";

    executeCcipSend@withrevert(e, bridgeAmount, destSelector, ccipTxType, txData, thisChainSelector);

    assert lastReverted;
    assert ghost_CCIPBridged_EventCount == 0;
}

/// @notice Executing a CCIP send reverts when no vault is registered for the destination chain.
/// @dev Verifies that no CCIPBridged event is emitted.
rule executeCcipSend_RevertWhen_DestinationVaultNotRegistered() {
    env e;
    uint256 bridgeAmount;
    uint64 destSelector;
    uint64 thisChainSelector;
    Types.CcipTx ccipTxType;
    bytes txData;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "executeCcipSend is nonpayable";
    require bridgeAmount != 0, "bridge amount is nonzero";
    require destSelector != 0, "destination chain selector is nonzero";
    require destSelector != thisChainSelector, "destination is not this chain";
    require !ccipRouter.getFeeReverts(), "router fee lookup does not revert";
    require !ccipRouter.ccipSendReverts(), "router send does not revert";

    /// @dev revert condition being verified
    require getCrosschainVault(destSelector) == 0, "destination vault is not registered";

    /// @dev ghost starting values
    require ghost_CCIPBridged_EventCount == 0, "CCIPBridged event count starts at zero";

    executeCcipSend@withrevert(e, bridgeAmount, destSelector, ccipTxType, txData, thisChainSelector);

    assert lastReverted;
    assert ghost_CCIPBridged_EventCount == 0;
}

/// @notice A valid CCIP send emits CCIPBridged with the bridged amount and transaction type.
/// @dev Verifies the linked token and router mocks approve and send without reverting.
rule executeCcipSend_Success_EmitsCCIPBridged() {
    env e;
    uint256 bridgeAmount;
    uint64 destSelector;
    uint64 thisChainSelector;
    Types.CcipTx ccipTxType;
    bytes txData;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "executeCcipSend is nonpayable";

    /// @dev success conditions being verified
    require bridgeAmount != 0, "bridge amount is nonzero";
    require destSelector != 0, "destination chain selector is nonzero";
    require destSelector != thisChainSelector, "destination is not this chain";
    require getCrosschainVault(destSelector) != 0, "destination vault is registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup does not revert";
    require !ccipRouter.ccipSendReverts(), "router send does not revert";

    /// @dev ghost starting values
    require ghost_CCIPBridged_EventCount == 0, "CCIPBridged event count starts at zero";
    require ghost_CCIPBridged_Param_ccipMessageId == to_bytes32(0), "CCIPBridged messageId ghost starts at zero";
    require ghost_CCIPBridged_Param_amount == 0, "CCIPBridged amount ghost starts at zero";

    executeCcipSend@withrevert(e, bridgeAmount, destSelector, ccipTxType, txData, thisChainSelector);

    assert !lastReverted;
    assert ghost_CCIPBridged_EventCount == 1;
    assert ghost_CCIPBridged_Param_ccipMessageId != to_bytes32(0);
    assert ghost_CCIPBridged_Param_amount == bridgeAmount;
    assert ghost_CCIPBridged_Param_ccipTxType == ccipTxType;
}

/// @notice Epoch-withdraw CCIP sends pass the epoch nonce in the router message payload.
/// @dev Verifies the exact message data hash observed by the router without reading dynamic bytes from storage.
rule executeCcipSend_EpochWithdraw_SendsEncodedEpochNoncePayload() {
    env e;
    uint256 bridgeAmount;
    uint64 destSelector;
    uint64 thisChainSelector;
    uint256 epochNonce;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "executeCcipSend is nonpayable";

    /// @dev success conditions being verified
    require bridgeAmount != 0, "bridge amount is nonzero";
    require destSelector != 0, "destination chain selector is nonzero";
    require destSelector != thisChainSelector, "destination is not this chain";
    require getCrosschainVault(destSelector) != 0, "destination vault is registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup does not revert";
    require !ccipRouter.ccipSendReverts(), "router send does not revert";

    bytes txData = encodeEpochNonce(epochNonce);
    bytes expectedMessageData = encodeCcipTxData(Types.CcipTx.EPOCH_NET_WITHDRAW, txData);

    executeCcipSend@withrevert(
        e,
        bridgeAmount,
        destSelector,
        Types.CcipTx.EPOCH_NET_WITHDRAW,
        txData,
        thisChainSelector
    );

    assert !lastReverted;
    assert ccipRouter.getLastMessageDataHash() == hashBytes(expectedMessageData);
}

/// @notice A valid CCIP send transfers the fee and bridged asset from the harness to the router.
/// @dev Verifies exact harness and router balance changes using the fee reported by the router.
rule executeCcipSend_Success_BalanceChanges() {
    env e;
    uint256 bridgeAmount;
    uint64 destSelector;
    uint64 thisChainSelector;
    Types.CcipTx ccipTxType;
    bytes txData;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "executeCcipSend is nonpayable";

    /// @dev success conditions being verified
    require bridgeAmount != 0, "bridge amount is nonzero";
    require destSelector != 0, "destination chain selector is nonzero";
    require destSelector != thisChainSelector, "destination is not this chain";
    require getCrosschainVault(destSelector) != 0, "destination vault is registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup does not revert";
    require !ccipRouter.ccipSendReverts(), "router send does not revert";

    uint256 fee = ccipRouter.getFee();
    address router = getRouter();
    uint256 vaultLinkBalanceBefore = link.balanceOf(currentContract);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);

    /// @dev mock token arithmetic conditions
    require fee <= vaultLinkBalanceBefore, "vault LINK balance covers the CCIP fee";
    require routerLinkBalanceBefore <= max_uint256 - fee, "router LINK balance does not overflow";
    require bridgeAmount <= vaultAssetBalanceBefore, "vault asset balance covers the bridge amount";
    require routerAssetBalanceBefore <= max_uint256 - bridgeAmount, "router asset balance does not overflow";

    executeCcipSend@withrevert(e, bridgeAmount, destSelector, ccipTxType, txData, thisChainSelector);

    assert !lastReverted;
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore - fee;
    assert link.balanceOf(router) == routerLinkBalanceBefore + fee;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore - bridgeAmount;
    assert asset.balanceOf(router) == routerAssetBalanceBefore + bridgeAmount;
}

/// @notice Executing a CCIP send reverts when the router fee lookup fails.
/// @dev Verifies that harness storage and token balances are unchanged and no event is emitted.
rule executeCcipSend_RevertWhen_RouterGetFeeReverts() {
    env e;
    uint256 bridgeAmount;
    uint64 destSelector;
    uint64 thisChainSelector;
    Types.CcipTx ccipTxType;
    bytes txData;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "executeCcipSend is nonpayable";
    require bridgeAmount != 0, "bridge amount is nonzero";
    require destSelector != 0, "destination chain selector is nonzero";
    require destSelector != thisChainSelector, "destination is not this chain";
    require getCrosschainVault(destSelector) != 0, "destination vault is registered";
    require !ccipRouter.ccipSendReverts(), "router send does not revert";

    /// @dev revert condition being verified
    require ccipRouter.getFeeReverts(), "router fee lookup reverts";

    storage before = lastStorage;
    address router = getRouter();
    uint256 vaultLinkBalanceBefore = link.balanceOf(currentContract);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);

    /// @dev ghost starting values
    require ghost_CCIPBridged_EventCount == 0, "CCIPBridged event count starts at zero";

    executeCcipSend@withrevert(e, bridgeAmount, destSelector, ccipTxType, txData, thisChainSelector);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore;
    assert link.balanceOf(router) == routerLinkBalanceBefore;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(router) == routerAssetBalanceBefore;
    assert ghost_CCIPBridged_EventCount == 0;
}

/// @notice Executing a CCIP send reverts when the router send fails.
/// @dev Verifies atomic rollback of approvals and token balances and that no event is emitted.
rule executeCcipSend_RevertWhen_RouterCcipSendReverts() {
    env e;
    uint256 bridgeAmount;
    uint64 destSelector;
    uint64 thisChainSelector;
    Types.CcipTx ccipTxType;
    bytes txData;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "executeCcipSend is nonpayable";
    require bridgeAmount != 0, "bridge amount is nonzero";
    require destSelector != 0, "destination chain selector is nonzero";
    require destSelector != thisChainSelector, "destination is not this chain";
    require getCrosschainVault(destSelector) != 0, "destination vault is registered";
    require !ccipRouter.getFeeReverts(), "router fee lookup does not revert";

    /// @dev revert condition being verified
    require ccipRouter.ccipSendReverts(), "router send reverts";

    storage before = lastStorage;
    address router = getRouter();
    uint256 vaultLinkBalanceBefore = link.balanceOf(currentContract);
    uint256 routerLinkBalanceBefore = link.balanceOf(router);
    uint256 vaultAssetBalanceBefore = asset.balanceOf(currentContract);
    uint256 routerAssetBalanceBefore = asset.balanceOf(router);

    /// @dev ghost starting values
    require ghost_CCIPBridged_EventCount == 0, "CCIPBridged event count starts at zero";

    executeCcipSend@withrevert(e, bridgeAmount, destSelector, ccipTxType, txData, thisChainSelector);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
    assert link.balanceOf(currentContract) == vaultLinkBalanceBefore;
    assert link.balanceOf(router) == routerLinkBalanceBefore;
    assert asset.balanceOf(currentContract) == vaultAssetBalanceBefore;
    assert asset.balanceOf(router) == routerAssetBalanceBefore;
    assert ghost_CCIPBridged_EventCount == 0;
}

/// ─────────────────── VALIDATE RECEIVED TOKEN AND GET AMOUNT ──────────────────

/// @notice Received-token validation reverts unless exactly one token amount is delivered.
/// @dev Verifies that validation does not modify harness storage.
rule validateReceivedTokenAndGetAmount_RevertWhen_TokenAmountsLengthIsInvalid() {
    env e;
    Client.Any2EVMMessage message;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "validateReceivedTokenAndGetAmount is nonpayable";

    /// @dev revert condition being verified
    require message.destTokenAmounts.length != 1, "token amounts length is invalid";

    storage before = lastStorage;

    validateReceivedTokenAndGetAmount@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Received-token validation reverts when the delivered token is not the harness asset.
/// @dev Verifies that validation does not modify harness storage.
rule validateReceivedTokenAndGetAmount_RevertWhen_TokenIsInvalid() {
    env e;
    Client.Any2EVMMessage message;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "validateReceivedTokenAndGetAmount is nonpayable";
    require message.destTokenAmounts.length == 1, "token amounts contains one element";
    require message.destTokenAmounts[0].amount != 0, "delivered amount is nonzero";

    /// @dev revert condition being verified
    require message.destTokenAmounts[0].token != getAsset(), "delivered token is not the vault asset";

    storage before = lastStorage;

    validateReceivedTokenAndGetAmount@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Received-token validation reverts when the delivered asset amount is zero.
/// @dev Verifies that validation does not modify harness storage.
rule validateReceivedTokenAndGetAmount_RevertWhen_AmountIsZero() {
    env e;
    Client.Any2EVMMessage message;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "validateReceivedTokenAndGetAmount is nonpayable";
    require message.destTokenAmounts.length == 1, "token amounts contains one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token is the vault asset";

    /// @dev revert condition being verified
    require message.destTokenAmounts[0].amount == 0, "delivered amount is zero";

    storage before = lastStorage;

    validateReceivedTokenAndGetAmount@withrevert(e, message);

    assert lastReverted;
    assert before[currentContract] == lastStorage[currentContract];
}

/// @notice Received-token validation returns the nonzero delivered asset amount.
/// @dev Verifies the returned amount and that validation does not modify harness storage.
rule validateReceivedTokenAndGetAmount_Success() {
    env e;
    Client.Any2EVMMessage message;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "validateReceivedTokenAndGetAmount is nonpayable";

    /// @dev success conditions being verified
    require message.destTokenAmounts.length == 1, "token amounts contains one element";
    require message.destTokenAmounts[0].token == getAsset(), "delivered token is the vault asset";
    require message.destTokenAmounts[0].amount != 0, "delivered amount is nonzero";

    uint256 expectedAmount = message.destTokenAmounts[0].amount;
    storage before = lastStorage;

    uint256 amount = validateReceivedTokenAndGetAmount@withrevert(e, message);

    assert !lastReverted;
    assert amount == expectedAmount;
    assert before[currentContract] == lastStorage[currentContract];
}

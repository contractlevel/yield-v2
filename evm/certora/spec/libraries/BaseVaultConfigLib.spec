/// Verification of BaseVaultConfigLib
/// @author @contractlevel
/// @notice BaseVaultConfigLib handles shared CCIP configuration state transitions for BaseVault implementations.

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    function getCrosschainVault(uint64) external returns (address) envfree;
    function getCcipGasLimit(uint64) external returns (uint256) envfree;
    function getDefaultCcipGasLimit() external returns (uint256) envfree;

    function setCrosschainVaults(uint64[], address[]) external;
    function setCcipGasLimit(uint64, uint256) external;
    function setDefaultCcipGasLimit(uint256) external;

    function bytes32ToAddress(bytes32) external returns (address) envfree;
    function bytes32ToUint64(bytes32) external returns (uint64) envfree;
    function bytes32ToUint256(bytes32) external returns (uint256) envfree;
}

/*//////////////////////////////////////////////////////////////
                         DEFINITIONS
//////////////////////////////////////////////////////////////*/
definition CrosschainVaultSetEvent() returns bytes32 =
// keccak256("CrosschainVaultSet(uint64,address)")
    to_bytes32(0x3dccebf0a32bc354f5dd3a785d9e2fc60792658c98848621290182785297b308);

definition CcipGasLimitSetEvent() returns bytes32 =
// keccak256("CcipGasLimitSet(uint64,uint256)")
    to_bytes32(0x390168a45e17c8f0ae322f9da9c220ea70ec5979bab8a6e0bec54f426ba2d390);

definition DefaultCcipGasLimitSetEvent() returns bytes32 =
// keccak256("DefaultCcipGasLimitSet(uint256)")
    to_bytes32(0xa28a825dc81451cace7e1074e39ddef702d1f349df63ca5fb8ed608cdc36f8ce);

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
ghost mathint ghost_crosschainVaults_StoreCount { init_state axiom ghost_crosschainVaults_StoreCount == 0; }
ghost uint64 ghost_crosschainVaults_StoredKey { init_state axiom ghost_crosschainVaults_StoredKey == 0; }
ghost address ghost_crosschainVaults_StoredValue { init_state axiom ghost_crosschainVaults_StoredValue == 0; }

ghost mathint ghost_ccipGasLimits_StoreCount { init_state axiom ghost_ccipGasLimits_StoreCount == 0; }
ghost uint64 ghost_ccipGasLimits_StoredKey { init_state axiom ghost_ccipGasLimits_StoredKey == 0; }
ghost uint256 ghost_ccipGasLimits_StoredValue { init_state axiom ghost_ccipGasLimits_StoredValue == 0; }

ghost mathint ghost_defaultCcipGasLimit_StoreCount { init_state axiom ghost_defaultCcipGasLimit_StoreCount == 0; }
ghost uint256 ghost_defaultCcipGasLimit_StoredValue { init_state axiom ghost_defaultCcipGasLimit_StoredValue == 0; }

ghost mathint ghost_CrosschainVaultSet_EventCount { init_state axiom ghost_CrosschainVaultSet_EventCount == 0; }
ghost uint64 ghost_CrosschainVaultSet_Param_chainSelector { init_state axiom ghost_CrosschainVaultSet_Param_chainSelector == 0; }
ghost address ghost_CrosschainVaultSet_Param_vault { init_state axiom ghost_CrosschainVaultSet_Param_vault == 0; }

ghost mathint ghost_CcipGasLimitSet_EventCount { init_state axiom ghost_CcipGasLimitSet_EventCount == 0; }
ghost uint64 ghost_CcipGasLimitSet_Param_chainSelector { init_state axiom ghost_CcipGasLimitSet_Param_chainSelector == 0; }
ghost uint256 ghost_CcipGasLimitSet_Param_gasLimit { init_state axiom ghost_CcipGasLimitSet_Param_gasLimit == 0; }

ghost mathint ghost_DefaultCcipGasLimitSet_EventCount { init_state axiom ghost_DefaultCcipGasLimitSet_EventCount == 0; }
ghost uint256 ghost_DefaultCcipGasLimitSet_Param_gasLimit { init_state axiom ghost_DefaultCcipGasLimitSet_Param_gasLimit == 0; }

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/
hook Sstore currentContract.ext_yieldcoin_storage_BaseVault.s_crosschainVaults[KEY uint64 k] address newValue {
    ghost_crosschainVaults_StoreCount = ghost_crosschainVaults_StoreCount + 1;
    ghost_crosschainVaults_StoredKey = k;
    ghost_crosschainVaults_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_BaseVault.s_ccipGasLimits[KEY uint64 k] uint256 newValue {
    ghost_ccipGasLimits_StoreCount = ghost_ccipGasLimits_StoreCount + 1;
    ghost_ccipGasLimits_StoredKey = k;
    ghost_ccipGasLimits_StoredValue = newValue;
}

hook Sstore currentContract.ext_yieldcoin_storage_BaseVault.s_defaultCcipGasLimit uint256 newValue {
    ghost_defaultCcipGasLimit_StoreCount = ghost_defaultCcipGasLimit_StoreCount + 1;
    ghost_defaultCcipGasLimit_StoredValue = newValue;
}

hook LOG2(uint offset, uint length, bytes32 t0, bytes32 t1) {
    if (t0 == DefaultCcipGasLimitSetEvent()) {
        ghost_DefaultCcipGasLimitSet_EventCount = ghost_DefaultCcipGasLimitSet_EventCount + 1;
        ghost_DefaultCcipGasLimitSet_Param_gasLimit = bytes32ToUint256(t1);
    }
}

hook LOG3(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2) {
    if (t0 == CrosschainVaultSetEvent()) {
        ghost_CrosschainVaultSet_EventCount = ghost_CrosschainVaultSet_EventCount + 1;
        ghost_CrosschainVaultSet_Param_chainSelector = bytes32ToUint64(t1);
        ghost_CrosschainVaultSet_Param_vault = bytes32ToAddress(t2);
    }
    if (t0 == CcipGasLimitSetEvent()) {
        ghost_CcipGasLimitSet_EventCount = ghost_CcipGasLimitSet_EventCount + 1;
        ghost_CcipGasLimitSet_Param_chainSelector = bytes32ToUint64(t1);
        ghost_CcipGasLimitSet_Param_gasLimit = bytes32ToUint256(t2);
    }
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
rule CFG_004_setCrosschainVaults_RevertWhen_InputIsEmpty() {
    env e;
    uint64[] chainSelectors;
    address[] vaults;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require chainSelectors.length == vaults.length, "array lengths should match";
    /// chainSelectors.length == 0 below means no zero-selector element can exist.

    /// @dev revert condition being verified
    require chainSelectors.length == 0, "chain selectors should be empty";

    /// @dev ghost starting values
    require ghost_CrosschainVaultSet_EventCount == 0, "event count starts at zero";
    require ghost_crosschainVaults_StoreCount == 0, "store count starts at zero";

    setCrosschainVaults@withrevert(e, chainSelectors, vaults);

    assert lastReverted;
    assert ghost_CrosschainVaultSet_EventCount == 0;
    assert ghost_crosschainVaults_StoreCount == 0;
}

rule CFG_004_setCrosschainVaults_RevertWhen_ArrayLengthsDoNotMatch() {
    env e;
    uint64[] chainSelectors;
    address[] vaults;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require chainSelectors.length == 1, "chain selectors should contain one item";
    require vaults.length == 0, "vaults should be empty";
    require chainSelectors[0] != 0, "chain selector should not be zero";

    /// @dev revert condition being verified
    require chainSelectors.length != vaults.length, "array lengths should not match";

    /// @dev ghost starting values
    require ghost_CrosschainVaultSet_EventCount == 0, "event count starts at zero";
    require ghost_crosschainVaults_StoreCount == 0, "store count starts at zero";

    setCrosschainVaults@withrevert(e, chainSelectors, vaults);

    assert lastReverted;
    assert ghost_CrosschainVaultSet_EventCount == 0;
    assert ghost_crosschainVaults_StoreCount == 0;
}

rule CFG_004_setCrosschainVaults_RevertWhen_FirstChainSelectorIsZero() {
    env e;
    uint64[] chainSelectors;
    address[] vaults;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require chainSelectors.length == 1, "chain selectors should contain one item";
    require vaults.length == 1, "vaults should contain one item";
    require vaults[0] <= max_uint160, "vault should be canonical";

    /// @dev revert condition being verified
    require chainSelectors[0] == 0, "first chain selector should be zero";

    /// @dev ghost starting values
    require ghost_CrosschainVaultSet_EventCount == 0, "event count starts at zero";
    require ghost_crosschainVaults_StoreCount == 0, "store count starts at zero";

    setCrosschainVaults@withrevert(e, chainSelectors, vaults);

    assert lastReverted;
    assert ghost_CrosschainVaultSet_EventCount == 0;
    assert ghost_crosschainVaults_StoreCount == 0;
}

rule setCrosschainVaults_Success() {
    env e;
    uint64[] chainSelectors;
    address[] vaults;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require chainSelectors.length == 1, "chain selectors should contain one item";
    require vaults.length == 1, "vaults should contain one item";
    require chainSelectors[0] != 0, "chain selector should not be zero";
    require vaults[0] <= max_uint160, "vault should be canonical";

    /// @dev ghost starting values
    require ghost_CrosschainVaultSet_EventCount == 0, "event count starts at zero";
    require ghost_crosschainVaults_StoreCount == 0, "store count starts at zero";

    setCrosschainVaults@withrevert(e, chainSelectors, vaults);

    assert !lastReverted;
    assert getCrosschainVault(chainSelectors[0]) == vaults[0];
    assert ghost_CrosschainVaultSet_EventCount == 1;
    assert ghost_CrosschainVaultSet_Param_chainSelector == chainSelectors[0];
    assert ghost_CrosschainVaultSet_Param_vault == vaults[0];
    assert ghost_crosschainVaults_StoreCount == 1;
    assert ghost_crosschainVaults_StoredKey == chainSelectors[0];
    assert ghost_crosschainVaults_StoredValue == vaults[0];
}

rule CFG_004_setCcipGasLimit_RevertWhen_ChainSelectorIsZero() {
    env e;
    uint256 gasLimit;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";

    /// @dev ghost starting values
    require ghost_CcipGasLimitSet_EventCount == 0, "event count starts at zero";
    require ghost_ccipGasLimits_StoreCount == 0, "store count starts at zero";

    /// @dev revert condition being verified
    setCcipGasLimit@withrevert(e, 0, gasLimit);

    assert lastReverted;
    assert ghost_CcipGasLimitSet_EventCount == 0;
    assert ghost_ccipGasLimits_StoreCount == 0;
}

rule CFG_004_setCcipGasLimit_Success() {
    env e;
    uint64 chainSelector;
    uint256 gasLimit;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require chainSelector != 0, "chain selector should not be zero";

    /// @dev ghost starting values
    require ghost_CcipGasLimitSet_EventCount == 0, "event count starts at zero";
    require ghost_ccipGasLimits_StoreCount == 0, "store count starts at zero";

    setCcipGasLimit@withrevert(e, chainSelector, gasLimit);

    assert !lastReverted;
    assert getCcipGasLimit(chainSelector) == gasLimit;
    assert ghost_CcipGasLimitSet_EventCount == 1;
    assert ghost_CcipGasLimitSet_Param_chainSelector == chainSelector;
    assert ghost_CcipGasLimitSet_Param_gasLimit == gasLimit;
    assert ghost_ccipGasLimits_StoreCount == 1;
    assert ghost_ccipGasLimits_StoredKey == chainSelector;
    assert ghost_ccipGasLimits_StoredValue == gasLimit;
}

rule CFG_004_setDefaultCcipGasLimit_RevertWhen_GasLimitIsZero() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";

    /// @dev ghost starting values
    require ghost_DefaultCcipGasLimitSet_EventCount == 0, "event count starts at zero";
    require ghost_defaultCcipGasLimit_StoreCount == 0, "store count starts at zero";

    /// @dev revert condition being verified
    setDefaultCcipGasLimit@withrevert(e, 0);

    assert lastReverted;
    assert ghost_DefaultCcipGasLimitSet_EventCount == 0;
    assert ghost_defaultCcipGasLimit_StoreCount == 0;
}

rule CFG_004_setDefaultCcipGasLimit_Success() {
    env e;
    uint256 gasLimit;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "non-payable";
    require gasLimit != 0, "gas limit should not be zero";

    /// @dev ghost starting values
    require ghost_DefaultCcipGasLimitSet_EventCount == 0, "event count starts at zero";
    require ghost_defaultCcipGasLimit_StoreCount == 0, "store count starts at zero";

    setDefaultCcipGasLimit@withrevert(e, gasLimit);

    assert !lastReverted;
    assert getDefaultCcipGasLimit() == gasLimit;
    assert ghost_DefaultCcipGasLimitSet_EventCount == 1;
    assert ghost_DefaultCcipGasLimitSet_Param_gasLimit == gasLimit;
    assert ghost_defaultCcipGasLimit_StoreCount == 1;
    assert ghost_defaultCcipGasLimit_StoredValue == gasLimit;
}

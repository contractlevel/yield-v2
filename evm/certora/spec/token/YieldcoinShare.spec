/// Verification of YieldcoinShare
/// @author @contractlevel
/// @notice YieldcoinShare is the upgradeable ERC20 accounting token of Yieldcoin v2.

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    function initialize(address, address, address, address, address, address) external;
    function setCCIPAdmin(address) external;
    function getCCIPAdmin() external returns (address) envfree;
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function pause() external;
    function unpause() external;
    function paused() external returns (bool) envfree;
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function balanceOf(address) external returns (uint256) envfree;
    function allowance(address, address) external returns (uint256) envfree;
    function totalSupply() external returns (uint256) envfree;
    function hasRole(bytes32, address) external returns (bool) envfree;
    function defaultAdmin() external returns (address) envfree;
    function reentrancyGuardEntered() external returns (bool) envfree;

    function isInitialized() external returns (bool) envfree;
    function isInitializing() external returns (bool) envfree;
    function hasExpectedMetadata() external returns (bool) envfree;
    function hasEmptyMetadata() external returns (bool) envfree;
    function authorizeUpgrade(address) external;
    function bytes32ToAddress(bytes32) external returns (address) envfree;

    function DEFAULT_ADMIN_ROLE() external returns (bytes32) envfree;
    function PAUSER_ROLE() external returns (bytes32) envfree;
    function UNPAUSER_ROLE() external returns (bytes32) envfree;
    function CONFIG_OPERATOR_ROLE() external returns (bytes32) envfree;
    function UPGRADER_ROLE() external returns (bytes32) envfree;
    function MINTER_ROLE() external returns (bytes32) envfree;
    function BURNER_ROLE() external returns (bytes32) envfree;
}

/*//////////////////////////////////////////////////////////////
                          DEFINITIONS
//////////////////////////////////////////////////////////////*/
definition CCIPAdminTransferredEvent() returns bytes32 =
    to_bytes32(0x9524c9e4b0b61eb018dd58a1cd856e3e74009528328ab4a613b434fa631d7242);

definition PausedEvent() returns bytes32 =
    to_bytes32(0x62e78cea01bee320cd4e420270b5ea74000d11b0c9f74754ebdbfc544b05a258);

definition UnpausedEvent() returns bytes32 =
    to_bytes32(0x5db9ee0a495bf2e6ff9c91a7834c1ba4fdd244a5e8aa4e537bd38aeae4b073aa);

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
ghost mathint ghost_ccipAdmin_StoreCount {
    init_state axiom ghost_ccipAdmin_StoreCount == 0;
}

ghost address ghost_ccipAdmin_StoredValue {
    init_state axiom ghost_ccipAdmin_StoredValue == 0;
}

ghost mathint ghost_CCIPAdminTransferred_EventCount {
    init_state axiom ghost_CCIPAdminTransferred_EventCount == 0;
}

ghost address ghost_CCIPAdminTransferred_EventParam_previousAdmin {
    init_state axiom ghost_CCIPAdminTransferred_EventParam_previousAdmin == 0;
}

ghost address ghost_CCIPAdminTransferred_EventParam_newAdmin {
    init_state axiom ghost_CCIPAdminTransferred_EventParam_newAdmin == 0;
}

ghost mathint ghost_Paused_EventCount {
    init_state axiom ghost_Paused_EventCount == 0;
}

ghost mathint ghost_Unpaused_EventCount {
    init_state axiom ghost_Unpaused_EventCount == 0;
}

/*//////////////////////////////////////////////////////////////
                              HOOKS
//////////////////////////////////////////////////////////////*/
hook Sstore currentContract.ext_yieldcoin_storage_YieldcoinShare.ccipAdmin address newValue (address oldValue) {
    ghost_ccipAdmin_StoreCount = ghost_ccipAdmin_StoreCount + 1;
    ghost_ccipAdmin_StoredValue = newValue;
}

hook LOG3(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2) {
    if (t0 == CCIPAdminTransferredEvent()) {
        ghost_CCIPAdminTransferred_EventCount = ghost_CCIPAdminTransferred_EventCount + 1;
        ghost_CCIPAdminTransferred_EventParam_previousAdmin = bytes32ToAddress(t1);
        ghost_CCIPAdminTransferred_EventParam_newAdmin = bytes32ToAddress(t2);
    }
}

hook LOG1(uint offset, uint length, bytes32 t0) {
    if (t0 == PausedEvent()) {
        ghost_Paused_EventCount = ghost_Paused_EventCount + 1;
    }
    if (t0 == UnpausedEvent()) {
        ghost_Unpaused_EventCount = ghost_Unpaused_EventCount + 1;
    }
}

/*//////////////////////////////////////////////////////////////
                           INITIALIZER
//////////////////////////////////////////////////////////////*/
rule REENT_001_initialize_RevertWhen_ReentrantCall() {
    env e;
    address defaultAdmin;
    address pauser;
    address unpauser;
    address configOperator;
    address ccipAdmin;
    address upgrader;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "initialize is nonpayable";
    require defaultAdmin != 0, "exclude zero default admin revert";
    require pauser != 0, "exclude zero pauser revert";
    require unpauser != 0, "exclude zero unpauser revert";
    require configOperator != 0, "exclude zero config operator revert";
    require ccipAdmin != 0, "exclude zero CCIP admin revert";
    require upgrader != 0, "exclude zero upgrader revert";
    require hasEmptyMetadata(), "metadata storage starts empty";
    require defaultAdmin() == 0, "default admin storage starts empty";
    require !isInitialized(), "exclude already-initialized revert";
    require !isInitializing(), "exclude already-initializing revert";

    /// @dev revert condition being verified
    require reentrancyGuardEntered(), "reentrancy guard is entered";

    initialize@withrevert(e, defaultAdmin, pauser, unpauser, configOperator, ccipAdmin, upgrader);
    assert lastReverted;
}

rule UPGRADE_002_initialize_RevertWhen_AlreadyInitialized() {
    env e;
    address defaultAdmin;
    address pauser;
    address unpauser;
    address configOperator;
    address ccipAdmin;
    address upgrader;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "initialize is nonpayable";
    require !reentrancyGuardEntered(), "exclude reentrant call revert";
    require defaultAdmin != 0, "exclude zero default admin revert";
    require pauser != 0, "exclude zero pauser revert";
    require unpauser != 0, "exclude zero unpauser revert";
    require configOperator != 0, "exclude zero config operator revert";
    require ccipAdmin != 0, "exclude zero CCIP admin revert";
    require upgrader != 0, "exclude zero upgrader revert";
    require hasEmptyMetadata(), "metadata storage starts empty";
    require defaultAdmin() == 0, "default admin storage starts empty";
    require !isInitializing(), "exclude already-initializing revert";

    /// @dev revert condition being verified
    require isInitialized(), "contract is already initialized";

    initialize@withrevert(e, defaultAdmin, pauser, unpauser, configOperator, ccipAdmin, upgrader);
    assert lastReverted;
}

rule initialize_RevertWhen_AlreadyInitializing() {
    env e;
    address defaultAdmin;
    address pauser;
    address unpauser;
    address configOperator;
    address ccipAdmin;
    address upgrader;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "initialize is nonpayable";
    require !reentrancyGuardEntered(), "exclude reentrant call revert";
    require defaultAdmin != 0, "exclude zero default admin revert";
    require pauser != 0, "exclude zero pauser revert";
    require unpauser != 0, "exclude zero unpauser revert";
    require configOperator != 0, "exclude zero config operator revert";
    require ccipAdmin != 0, "exclude zero CCIP admin revert";
    require upgrader != 0, "exclude zero upgrader revert";
    require hasEmptyMetadata(), "metadata storage starts empty";
    require defaultAdmin() == 0, "default admin storage starts empty";
    require !isInitialized(), "exclude already-initialized revert";

    /// @dev revert condition being verified
    require isInitializing(), "contract is already initializing";

    initialize@withrevert(e, defaultAdmin, pauser, unpauser, configOperator, ccipAdmin, upgrader);
    assert lastReverted;
}

rule CFG_001_initialize_RevertWhen_DefaultAdminIsZero() {
    env e;
    address pauser;
    address unpauser;
    address configOperator;
    address ccipAdmin;
    address upgrader;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "initialize is nonpayable";
    require !reentrancyGuardEntered(), "exclude reentrant call revert";
    require pauser != 0, "exclude zero pauser revert";
    require unpauser != 0, "exclude zero unpauser revert";
    require configOperator != 0, "exclude zero config operator revert";
    require ccipAdmin != 0, "exclude zero CCIP admin revert";
    require upgrader != 0, "exclude zero upgrader revert";
    require hasEmptyMetadata(), "metadata storage starts empty";
    require defaultAdmin() == 0, "default admin storage starts empty";
    require !isInitialized(), "exclude already-initialized revert";
    require !isInitializing(), "exclude already-initializing revert";

    /// @dev revert condition being verified
    initialize@withrevert(e, 0, pauser, unpauser, configOperator, ccipAdmin, upgrader);
    assert lastReverted;
}

rule CFG_001_initialize_RevertWhen_PauserIsZero() {
    env e;
    address defaultAdmin;
    address unpauser;
    address configOperator;
    address ccipAdmin;
    address upgrader;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "initialize is nonpayable";
    require !reentrancyGuardEntered(), "exclude reentrant call revert";
    require defaultAdmin != 0, "exclude zero default admin revert";
    require unpauser != 0, "exclude zero unpauser revert";
    require configOperator != 0, "exclude zero config operator revert";
    require ccipAdmin != 0, "exclude zero CCIP admin revert";
    require upgrader != 0, "exclude zero upgrader revert";
    require hasEmptyMetadata(), "metadata storage starts empty";
    require defaultAdmin() == 0, "default admin storage starts empty";
    require !isInitialized(), "exclude already-initialized revert";
    require !isInitializing(), "exclude already-initializing revert";

    /// @dev revert condition being verified
    initialize@withrevert(e, defaultAdmin, 0, unpauser, configOperator, ccipAdmin, upgrader);
    assert lastReverted;
}

rule CFG_001_initialize_RevertWhen_UnpauserIsZero() {
    env e;
    address defaultAdmin;
    address pauser;
    address configOperator;
    address ccipAdmin;
    address upgrader;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "initialize is nonpayable";
    require !reentrancyGuardEntered(), "exclude reentrant call revert";
    require defaultAdmin != 0, "exclude zero default admin revert";
    require pauser != 0, "exclude zero pauser revert";
    require configOperator != 0, "exclude zero config operator revert";
    require ccipAdmin != 0, "exclude zero CCIP admin revert";
    require upgrader != 0, "exclude zero upgrader revert";
    require hasEmptyMetadata(), "metadata storage starts empty";
    require defaultAdmin() == 0, "default admin storage starts empty";
    require !isInitialized(), "exclude already-initialized revert";
    require !isInitializing(), "exclude already-initializing revert";

    /// @dev revert condition being verified
    initialize@withrevert(e, defaultAdmin, pauser, 0, configOperator, ccipAdmin, upgrader);
    assert lastReverted;
}

rule CFG_001_initialize_RevertWhen_ConfigOperatorIsZero() {
    env e;
    address defaultAdmin;
    address pauser;
    address unpauser;
    address ccipAdmin;
    address upgrader;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "initialize is nonpayable";
    require !reentrancyGuardEntered(), "exclude reentrant call revert";
    require defaultAdmin != 0, "exclude zero default admin revert";
    require pauser != 0, "exclude zero pauser revert";
    require unpauser != 0, "exclude zero unpauser revert";
    require ccipAdmin != 0, "exclude zero CCIP admin revert";
    require upgrader != 0, "exclude zero upgrader revert";
    require hasEmptyMetadata(), "metadata storage starts empty";
    require defaultAdmin() == 0, "default admin storage starts empty";
    require !isInitialized(), "exclude already-initialized revert";
    require !isInitializing(), "exclude already-initializing revert";

    /// @dev revert condition being verified
    initialize@withrevert(e, defaultAdmin, pauser, unpauser, 0, ccipAdmin, upgrader);
    assert lastReverted;
}

rule CFG_001_TOKEN_001_initialize_RevertWhen_InitialCcipAdminIsZero() {
    env e;
    address defaultAdmin;
    address pauser;
    address unpauser;
    address configOperator;
    address upgrader;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "initialize is nonpayable";
    require !reentrancyGuardEntered(), "exclude reentrant call revert";
    require defaultAdmin != 0, "exclude zero default admin revert";
    require pauser != 0, "exclude zero pauser revert";
    require unpauser != 0, "exclude zero unpauser revert";
    require configOperator != 0, "exclude zero config operator revert";
    require upgrader != 0, "exclude zero upgrader revert";
    require hasEmptyMetadata(), "metadata storage starts empty";
    require defaultAdmin() == 0, "default admin storage starts empty";
    require !isInitialized(), "exclude already-initialized revert";
    require !isInitializing(), "exclude already-initializing revert";

    /// @dev revert condition being verified
    initialize@withrevert(e, defaultAdmin, pauser, unpauser, configOperator, 0, upgrader);
    assert lastReverted;
}

rule CFG_001_initialize_RevertWhen_UpgraderIsZero() {
    env e;
    address defaultAdmin;
    address pauser;
    address unpauser;
    address configOperator;
    address ccipAdmin;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "initialize is nonpayable";
    require !reentrancyGuardEntered(), "exclude reentrant call revert";
    require defaultAdmin != 0, "exclude zero default admin revert";
    require pauser != 0, "exclude zero pauser revert";
    require unpauser != 0, "exclude zero unpauser revert";
    require configOperator != 0, "exclude zero config operator revert";
    require ccipAdmin != 0, "exclude zero CCIP admin revert";
    require hasEmptyMetadata(), "metadata storage starts empty";
    require defaultAdmin() == 0, "default admin storage starts empty";
    require !isInitialized(), "exclude already-initialized revert";
    require !isInitializing(), "exclude already-initializing revert";

    /// @dev revert condition being verified
    initialize@withrevert(e, defaultAdmin, pauser, unpauser, configOperator, ccipAdmin, 0);
    assert lastReverted;
}

rule TOKEN_001_initialize_Success() {
    env e;
    address initialDefaultAdmin;
    address pauser;
    address unpauser;
    address configOperator;
    address ccipAdmin;
    address upgrader;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "initialize is nonpayable";
    require !reentrancyGuardEntered(), "exclude reentrant call revert";
    require initialDefaultAdmin != 0, "default admin is nonzero";
    require pauser != 0, "pauser is nonzero";
    require unpauser != 0, "unpauser is nonzero";
    require configOperator != 0, "config operator is nonzero";
    require ccipAdmin != 0, "CCIP admin is nonzero";
    require upgrader != 0, "upgrader is nonzero";
    require hasEmptyMetadata(), "metadata storage starts empty";
    require defaultAdmin() == 0, "default admin storage starts empty";
    require getCCIPAdmin() == 0, "CCIP admin storage starts empty";
    require !isInitialized(), "contract is not initialized";
    require !isInitializing(), "contract is not initializing";
    require ghost_CCIPAdminTransferred_EventCount == 0, "CCIP event count starts at zero";
    require ghost_ccipAdmin_StoreCount == 0, "CCIP admin store count starts at zero";

    initialize@withrevert(e, initialDefaultAdmin, pauser, unpauser, configOperator, ccipAdmin, upgrader);

    assert !lastReverted;
    assert !reentrancyGuardEntered();
    assert isInitialized();
    assert !isInitializing();
    assert hasExpectedMetadata();
    assert defaultAdmin() == initialDefaultAdmin;
    assert hasRole(DEFAULT_ADMIN_ROLE(), initialDefaultAdmin);
    assert hasRole(PAUSER_ROLE(), pauser);
    assert hasRole(UNPAUSER_ROLE(), unpauser);
    assert hasRole(CONFIG_OPERATOR_ROLE(), configOperator);
    assert hasRole(UPGRADER_ROLE(), upgrader);
    assert getCCIPAdmin() == ccipAdmin;
    assert ghost_CCIPAdminTransferred_EventCount == 1;
    assert ghost_CCIPAdminTransferred_EventParam_previousAdmin == 0;
    assert ghost_CCIPAdminTransferred_EventParam_newAdmin == ccipAdmin;
    assert ghost_ccipAdmin_StoreCount == 1;
    assert ghost_ccipAdmin_StoredValue == ccipAdmin;
}

/*//////////////////////////////////////////////////////////////
                      UUPS AUTHORIZATION
//////////////////////////////////////////////////////////////*/
rule UPGRADE_001_authorizeUpgrade_RevertWhen_CallerLacksUPGRADER_ROLE() {
    env e;
    address newImplementation;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "authorizeUpgrade is nonpayable";

    /// @dev revert condition being verified
    require !hasRole(UPGRADER_ROLE(), e.msg.sender), "caller lacks UPGRADER_ROLE";

    authorizeUpgrade@withrevert(e, newImplementation);
    assert lastReverted;
}

rule UPGRADE_001_authorizeUpgrade_Success() {
    env e;
    address newImplementation;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "authorizeUpgrade is nonpayable";
    require hasRole(UPGRADER_ROLE(), e.msg.sender), "caller has UPGRADER_ROLE";

    authorizeUpgrade@withrevert(e, newImplementation);
    assert !lastReverted;
}

/*//////////////////////////////////////////////////////////////
                          CCIP ADMIN
//////////////////////////////////////////////////////////////*/
rule TOKEN_001_setCCIPAdmin_RevertWhen_CallerLacksCONFIG_OPERATOR_ROLE() {
    env e;
    address newAdmin;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "setCCIPAdmin is nonpayable";
    require newAdmin != 0, "exclude zero new admin revert";
    require ghost_CCIPAdminTransferred_EventCount == 0, "CCIP event count starts at zero";
    require ghost_ccipAdmin_StoreCount == 0, "CCIP admin store count starts at zero";

    /// @dev revert condition being verified
    require !hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender), "caller lacks CONFIG_OPERATOR_ROLE";

    setCCIPAdmin@withrevert(e, newAdmin);
    assert lastReverted;
    assert ghost_CCIPAdminTransferred_EventCount == 0;
    assert ghost_ccipAdmin_StoreCount == 0;
}

rule CFG_001_TOKEN_001_setCCIPAdmin_RevertWhen_NewAdminIsZero() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "setCCIPAdmin is nonpayable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender), "caller has CONFIG_OPERATOR_ROLE";
    require ghost_CCIPAdminTransferred_EventCount == 0, "CCIP event count starts at zero";
    require ghost_ccipAdmin_StoreCount == 0, "CCIP admin store count starts at zero";

    /// @dev revert condition being verified
    setCCIPAdmin@withrevert(e, 0);
    assert lastReverted;
    assert ghost_CCIPAdminTransferred_EventCount == 0;
    assert ghost_ccipAdmin_StoreCount == 0;
}

rule TOKEN_001_setCCIPAdmin_Success() {
    env e;
    address newAdmin;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "setCCIPAdmin is nonpayable";
    require hasRole(CONFIG_OPERATOR_ROLE(), e.msg.sender), "caller has CONFIG_OPERATOR_ROLE";
    require newAdmin != 0, "new admin is nonzero";
    require ghost_CCIPAdminTransferred_EventCount == 0, "CCIP event count starts at zero";
    require ghost_ccipAdmin_StoreCount == 0, "CCIP admin store count starts at zero";
    address previousAdmin = getCCIPAdmin();

    setCCIPAdmin@withrevert(e, newAdmin);

    assert !lastReverted;
    assert getCCIPAdmin() == newAdmin;
    assert ghost_CCIPAdminTransferred_EventCount == 1;
    assert ghost_CCIPAdminTransferred_EventParam_previousAdmin == previousAdmin;
    assert ghost_CCIPAdminTransferred_EventParam_newAdmin == newAdmin;
    assert ghost_ccipAdmin_StoreCount == 1;
    assert ghost_ccipAdmin_StoredValue == newAdmin;
}

/*//////////////////////////////////////////////////////////////
                              PAUSE
//////////////////////////////////////////////////////////////*/
rule PAUSE_002_pause_RevertWhen_CallerLacksPAUSER_ROLE() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "pause is nonpayable";
    require !paused(), "exclude already-paused revert";

    /// @dev revert condition being verified
    require !hasRole(PAUSER_ROLE(), e.msg.sender), "caller lacks PAUSER_ROLE";

    pause@withrevert(e);
    assert lastReverted;
}

rule PAUSE_002_pause_RevertWhen_AlreadyPaused() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "pause is nonpayable";
    require hasRole(PAUSER_ROLE(), e.msg.sender), "caller has PAUSER_ROLE";

    /// @dev revert condition being verified
    require paused(), "token is already paused";

    pause@withrevert(e);
    assert lastReverted;
}

rule PAUSE_002_pause_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "pause is nonpayable";
    require hasRole(PAUSER_ROLE(), e.msg.sender), "caller has PAUSER_ROLE";
    require !paused(), "token is unpaused";
    require ghost_Paused_EventCount == 0, "Paused event count starts at zero";

    pause@withrevert(e);
    assert !lastReverted;
    assert paused();
    assert ghost_Paused_EventCount == 1;
}

rule PAUSE_002_unpause_RevertWhen_CallerLacksUNPAUSER_ROLE() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "unpause is nonpayable";
    require paused(), "exclude not-paused revert";

    /// @dev revert condition being verified
    require !hasRole(UNPAUSER_ROLE(), e.msg.sender), "caller lacks UNPAUSER_ROLE";

    unpause@withrevert(e);
    assert lastReverted;
}

rule PAUSE_002_unpause_RevertWhen_NotPaused() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "unpause is nonpayable";
    require hasRole(UNPAUSER_ROLE(), e.msg.sender), "caller has UNPAUSER_ROLE";

    /// @dev revert condition being verified
    require !paused(), "token is not paused";

    unpause@withrevert(e);
    assert lastReverted;
}

rule PAUSE_002_unpause_Success() {
    env e;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "unpause is nonpayable";
    require hasRole(UNPAUSER_ROLE(), e.msg.sender), "caller has UNPAUSER_ROLE";
    require paused(), "token is paused";
    require ghost_Unpaused_EventCount == 0, "Unpaused event count starts at zero";

    unpause@withrevert(e);
    assert !lastReverted;
    assert !paused();
    assert ghost_Unpaused_EventCount == 1;
}

/*//////////////////////////////////////////////////////////////
                         MINT AND BURN
//////////////////////////////////////////////////////////////*/
rule TOKEN_002_mint_RevertWhen_CallerLacksMINTER_ROLE() {
    env e;
    address recipient;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "mint is nonpayable";
    require recipient != 0, "exclude zero recipient revert";
    require !paused(), "exclude paused revert";
    require totalSupply() <= max_uint256 - amount, "exclude total supply overflow";
    require balanceOf(recipient) <= max_uint256 - amount, "exclude recipient balance overflow";

    /// @dev revert condition being verified
    require !hasRole(MINTER_ROLE(), e.msg.sender), "caller lacks MINTER_ROLE";

    mint@withrevert(e, recipient, amount);
    assert lastReverted;
}

rule TOKEN_002_mint_RevertWhen_RecipientIsZero() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "mint is nonpayable";
    require hasRole(MINTER_ROLE(), e.msg.sender), "caller has MINTER_ROLE";
    require !paused(), "exclude paused revert";
    require totalSupply() <= max_uint256 - amount, "exclude total supply overflow";

    /// @dev revert condition being verified
    mint@withrevert(e, 0, amount);
    assert lastReverted;
}

rule PAUSE_002_TOKEN_002_mint_RevertWhen_Paused() {
    env e;
    address recipient;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "mint is nonpayable";
    require hasRole(MINTER_ROLE(), e.msg.sender), "caller has MINTER_ROLE";
    require recipient != 0, "exclude zero recipient revert";
    require totalSupply() <= max_uint256 - amount, "exclude total supply overflow";
    require balanceOf(recipient) <= max_uint256 - amount, "exclude recipient balance overflow";

    /// @dev revert condition being verified
    require paused(), "token is paused";

    mint@withrevert(e, recipient, amount);
    assert lastReverted;
}

rule TOKEN_002_mint_Success() {
    env e;
    address recipient;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "mint is nonpayable";
    require hasRole(MINTER_ROLE(), e.msg.sender), "caller has MINTER_ROLE";
    require recipient != 0, "recipient is nonzero";
    require !paused(), "token is unpaused";
    require totalSupply() <= max_uint256 - amount, "total supply does not overflow";
    require balanceOf(recipient) <= max_uint256 - amount, "recipient balance does not overflow";
    uint256 balanceBefore = balanceOf(recipient);
    uint256 supplyBefore = totalSupply();

    mint@withrevert(e, recipient, amount);
    assert !lastReverted;
    assert balanceOf(recipient) == balanceBefore + amount;
    assert totalSupply() == supplyBefore + amount;
}

rule TOKEN_002_burn_RevertWhen_CallerLacksBURNER_ROLE() {
    env e;
    address user;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "burn is nonpayable";
    require user != 0, "exclude zero user revert";
    require !paused(), "exclude paused revert";
    require balanceOf(user) >= amount, "exclude insufficient balance revert";
    require totalSupply() >= amount, "exclude inconsistent total supply";

    /// @dev revert condition being verified
    require !hasRole(BURNER_ROLE(), e.msg.sender), "caller lacks BURNER_ROLE";

    burn@withrevert(e, user, amount);
    assert lastReverted;
}

rule TOKEN_002_burn_RevertWhen_UserIsZero() {
    env e;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "burn is nonpayable";
    require hasRole(BURNER_ROLE(), e.msg.sender), "caller has BURNER_ROLE";
    require !paused(), "exclude paused revert";

    /// @dev revert condition being verified
    burn@withrevert(e, 0, amount);
    assert lastReverted;
}

rule TOKEN_002_burn_RevertWhen_BalanceIsInsufficient() {
    env e;
    address user;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "burn is nonpayable";
    require hasRole(BURNER_ROLE(), e.msg.sender), "caller has BURNER_ROLE";
    require user != 0, "exclude zero user revert";
    require !paused(), "exclude paused revert";

    /// @dev revert condition being verified
    require balanceOf(user) < amount, "user balance is insufficient";

    burn@withrevert(e, user, amount);
    assert lastReverted;
}

rule PAUSE_002_TOKEN_002_burn_RevertWhen_Paused() {
    env e;
    address user;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "burn is nonpayable";
    require hasRole(BURNER_ROLE(), e.msg.sender), "caller has BURNER_ROLE";
    require user != 0, "exclude zero user revert";
    require balanceOf(user) >= amount, "exclude insufficient balance revert";
    require totalSupply() >= amount, "exclude inconsistent total supply";

    /// @dev revert condition being verified
    require paused(), "token is paused";

    burn@withrevert(e, user, amount);
    assert lastReverted;
}

rule TOKEN_002_burn_Success() {
    env e;
    address user;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "burn is nonpayable";
    require hasRole(BURNER_ROLE(), e.msg.sender), "caller has BURNER_ROLE";
    require user != 0, "user is nonzero";
    require !paused(), "token is unpaused";
    require balanceOf(user) >= amount, "user balance is sufficient";
    require totalSupply() >= amount, "total supply is sufficient";
    uint256 balanceBefore = balanceOf(user);
    uint256 supplyBefore = totalSupply();

    burn@withrevert(e, user, amount);
    assert !lastReverted;
    assert balanceOf(user) == balanceBefore - amount;
    assert totalSupply() == supplyBefore - amount;
}

/*//////////////////////////////////////////////////////////////
                     PAUSED ERC20 OPERATIONS
//////////////////////////////////////////////////////////////*/
rule PAUSE_002_transfer_RevertWhen_Paused() {
    env e;
    address recipient;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "transfer is nonpayable";
    require e.msg.sender != 0, "exclude zero sender revert";
    require recipient != 0, "exclude zero recipient revert";
    require balanceOf(e.msg.sender) >= amount, "exclude insufficient balance revert";

    /// @dev revert condition being verified
    require paused(), "token is paused";

    transfer@withrevert(e, recipient, amount);
    assert lastReverted;
}

rule PAUSE_002_transferFrom_RevertWhen_Paused() {
    env e;
    address from;
    address recipient;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "transferFrom is nonpayable";
    require e.msg.sender != 0, "exclude zero spender revert";
    require from != 0, "exclude zero sender revert";
    require recipient != 0, "exclude zero recipient revert";
    require balanceOf(from) >= amount, "exclude insufficient balance revert";
    require allowance(from, e.msg.sender) >= amount, "exclude insufficient allowance revert";

    /// @dev revert condition being verified
    require paused(), "token is paused";

    transferFrom@withrevert(e, from, recipient, amount);
    assert lastReverted;
}

rule PAUSE_002_approve_Success_WhenPaused() {
    env e;
    address spender;
    uint256 amount;

    /// @dev revert conditions NOT being verified
    require e.msg.value == 0, "approve is nonpayable";
    require e.msg.sender != 0, "exclude zero approver revert";
    require spender != 0, "exclude zero spender revert";
    require paused(), "token is paused";

    bool result = approve@withrevert(e, spender, amount);
    assert !lastReverted;
    assert result;
    assert allowance(e.msg.sender, spender) == amount;
}

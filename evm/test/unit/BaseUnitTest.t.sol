// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseTest, Vm} from "../BaseTest.t.sol";
import {StdStorage, stdStorage} from "forge-std/StdStorage.sol";

import {YieldcoinShare} from "../../src/token/YieldcoinShare.sol";
import {BaseVault} from "../../src/vaults/BaseVault.sol";
import {ParentVault} from "../../src/vaults/ParentVault.sol";
import {ChildVault} from "../../src/vaults/ChildVault.sol";
import {AdapterRegistry} from "../../src/modules/AdapterRegistry.sol";

import {MockLink} from "../mocks/MockLink.sol";
import {MockPolicyEngine} from "../mocks/MockPolicyEngine.sol";
import {MockProtocolAdapter} from "../mocks/MockProtocolAdapter.sol";
import {MockUSDC} from "../mocks/MockUSDC.sol";
import {MockCCIPRouter} from "../mocks/MockCCIPRouter.sol";

import {Roles} from "../../src/libraries/Roles.sol";
import {Types} from "../../src/libraries/Types.sol";

import {Client} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

abstract contract BaseUnitTest is BaseTest {
    using stdStorage for StdStorage;

    MockLink internal s_mockLink;
    MockPolicyEngine internal s_mockPolicyEngine;
    MockProtocolAdapter internal s_mockProtocolAdapter;
    MockUSDC internal s_mockUsdc;
    MockCCIPRouter internal s_mockCcipRouter;

    YieldcoinShare internal s_yieldcoin;
    ParentVault internal s_parentVault;
    ChildVault internal s_childVault;
    AdapterRegistry internal s_adapterRegistry;

    constructor() {
        _changePrank(i_owner);
        s_mockLink = new MockLink();
        s_mockPolicyEngine = new MockPolicyEngine();
        s_mockProtocolAdapter = new MockProtocolAdapter();
        s_mockUsdc = new MockUSDC();
        s_mockCcipRouter = new MockCCIPRouter(address(s_mockUsdc));

        YieldcoinShare yieldcoinImpl = new YieldcoinShare();
        ERC1967Proxy yieldcoinProxy = new ERC1967Proxy(
            address(yieldcoinImpl),
            abi.encodeWithSelector(YieldcoinShare.initialize.selector, address(s_mockPolicyEngine), i_configOperator)
        );
        s_yieldcoin = YieldcoinShare(address(yieldcoinProxy));
        s_adapterRegistry = new AdapterRegistry(0, address(i_owner));
        BaseVault.ConstructorParams memory params = _baseVaultParams(PARENT_CHAIN_SELECTOR);

        s_adapterRegistry.grantRole(Roles.CONFIG_OPERATOR_ROLE, i_configOperator);
        _changePrank(i_configOperator);
        s_adapterRegistry.setAdapter(AAVE_V3_PROTOCOL_ID, address(s_mockProtocolAdapter));
        _changePrank(i_owner);
        s_parentVault = new ParentVault(
            params, i_treasury, address(s_yieldcoin), i_policyEngineManager, address(s_mockPolicyEngine)
        );
        _changePrank(i_configOperator);
        s_parentVault.setSupportedProtocol(AAVE_V3_PROTOCOL_ID, true);
        s_parentVault.setSupportedProtocol(AAVE_V4_PROTOCOL_ID, true);
        s_parentVault.setSupportedProtocol(COMPOUND_V3_PROTOCOL_ID, true);
        _setParentCrosschainVault(PARENT_CHAIN_SELECTOR, address(s_parentVault));
        _changePrank(i_owner);
        s_parentVault.setInitialActiveProtocolAdapter(AAVE_V3_PROTOCOL_ID);

        params.thisChainSelector = CHILD_CHAIN_SELECTOR;
        s_childVault = new ChildVault(params, PARENT_CHAIN_SELECTOR);

        s_parentVault.grantRole(Roles.EPOCH_OPERATOR_ROLE, i_epochOperator);
        s_childVault.grantRole(Roles.EPOCH_OPERATOR_ROLE, i_epochOperator);
        s_parentVault.grantRole(Roles.REBALANCE_OPERATOR_ROLE, i_rebalanceOperator);
        s_childVault.grantRole(Roles.REBALANCE_OPERATOR_ROLE, i_rebalanceOperator);
        s_parentVault.grantRole(Roles.DONATE_OPERATOR_ROLE, i_donateOperator);
        s_childVault.grantRole(Roles.DONATE_OPERATOR_ROLE, i_donateOperator);

        vm.label(address(s_parentVault), "ParentVault");
        vm.label(address(s_childVault), "ChildVault");
        vm.label(address(s_yieldcoin), "Yieldcoin");
        vm.label(address(s_mockPolicyEngine), "PolicyEngine");
        vm.label(address(s_mockUsdc), "MockUSDC");
    }

    /// @notice Empty test function to ignore file in coverage report
    function test_baseTest() public virtual override {}

    function _strategy(bytes32 protocolId, uint64 chainSelector)
        internal
        pure
        returns (Types.Strategy memory strategy)
    {
        strategy = Types.Strategy({protocolId: protocolId, chainSelector: chainSelector});
    }

    function _registerAdapter(bytes32 protocolId, address adapter) internal {
        _changePrank(i_configOperator);
        s_adapterRegistry.setAdapter(protocolId, adapter);
    }

    function _setParentSupportedProtocol(bytes32 protocolId, bool isSupported) internal {
        _changePrank(i_configOperator);
        s_parentVault.setSupportedProtocol(protocolId, isSupported);
    }

    function _baseVaultParams(uint64 chainSelector) internal view returns (BaseVault.ConstructorParams memory params) {
        params = BaseVault.ConstructorParams({
            link: address(s_mockLink),
            asset: address(s_mockUsdc),
            ccipRouter: address(s_mockCcipRouter),
            defaultAdmin: address(i_owner),
            pauser: address(i_pauser),
            unpauser: address(i_unpauser),
            configOperator: address(i_configOperator),
            adapterRegistry: address(s_adapterRegistry),
            thisChainSelector: chainSelector,
            emergencyReceiver: address(i_emergencyReceiver),
            initialDefaultCcipGasLimit: DEFAULT_CCIP_GAS_LIMIT
        });
    }

    function _setParentCrosschainVault(uint64 chainSelector, address vault) internal {
        _setCrosschainVault(s_parentVault, chainSelector, vault);
    }

    function _setChildCrosschainVault(uint64 chainSelector, address vault) internal {
        _setCrosschainVault(s_childVault, chainSelector, vault);
    }

    function _setCrosschainVault(BaseVault vault, uint64 chainSelector, address crosschainVault) internal {
        uint64[] memory chainSelectors = new uint64[](1);
        address[] memory vaults = new address[](1);
        chainSelectors[0] = chainSelector;
        vaults[0] = crosschainVault;

        _changePrank(i_configOperator);
        vault.setCrosschainVaults(chainSelectors, vaults);
    }

    function _setChildActiveAdapter(address adapter) internal {
        _setActiveAdapter(s_childVault, adapter);
    }

    function _clearChildActiveAdapter() internal {
        _setActiveAdapter(s_childVault, address(0));
    }

    function _clearParentActiveAdapter() internal {
        _setActiveAdapter(s_parentVault, address(0));
    }

    function _setActiveAdapter(BaseVault vault, address adapter) internal {
        bytes32 slot = bytes32(uint256(8));
        bytes32 value = vm.load(address(vault), slot);

        uint256 pausedAtBits = uint256(value) & ~uint256(type(uint160).max);
        uint256 activeAdapterBits = uint160(adapter);

        vm.store(address(vault), slot, bytes32(pausedAtBits | activeAdapterBits));
    }

    function _setParentTotalShares(uint256 totalShares) internal {
        stdstore.target(address(s_parentVault)).sig("getTotalShares()").checked_write(totalShares);
    }

    function _setParentPerformanceFeeHighWaterMark(uint256 highWaterMark) internal {
        stdstore.target(address(s_parentVault)).sig("getPerformanceFeeHighWaterMark()").checked_write(highWaterMark);
    }

    function _setParentEpochNonce(uint256 epochNonce) internal {
        stdstore.target(address(s_parentVault)).sig("getEpochNonce()").checked_write(epochNonce);
    }

    function _setParentEpochStatus(uint256 epochNonce, Types.EpochStatus status) internal {
        stdstore.target(address(s_parentVault)).sig("getEpoch(uint256)").with_key(epochNonce).depth(10)
            .checked_write(uint256(status));
    }

    function _setParentActiveStrategy(bytes32 protocolId, uint64 chainSelector) internal {
        stdstore.target(address(s_parentVault)).sig("getRebalance()").depth(2).checked_write(protocolId);
        stdstore.target(address(s_parentVault)).sig("getRebalance()").depth(3).checked_write(chainSelector);
    }

    function _setParentPendingRebalance(bytes32 protocolId, uint64 chainSelector) internal {
        _setParentRebalanceState(Types.RebalanceState.REBALANCING);
        stdstore.target(address(s_parentVault)).sig("getRebalance()").depth(4).checked_write(protocolId);
        stdstore.target(address(s_parentVault)).sig("getRebalance()").depth(5).checked_write(chainSelector);
    }

    function _setParentRebalanceState(Types.RebalanceState state) internal {
        stdstore.target(address(s_parentVault)).sig("getRebalance()").depth(1).checked_write(uint256(state));
    }

    function _submitParentWithdraw(uint256 shareAmount) internal {
        s_yieldcoin.mint(i_withdrawer, shareAmount);
        _changePrank(i_withdrawer);
        s_yieldcoin.approve(address(s_parentVault), shareAmount);
        s_parentVault.withdraw(shareAmount);
    }

    /*//////////////////////////////////////////////////////////////
                             CCIP MESSAGES
    //////////////////////////////////////////////////////////////*/
    function _rebalanceMessage(
        uint64 sourceChainSelector,
        address sender,
        uint256 rebalanceNonce,
        bytes32 protocolId,
        uint256 amount
    ) internal view returns (Client.Any2EVMMessage memory) {
        return _message(
            sourceChainSelector, sender, Types.CcipTx.REBALANCE, abi.encode(rebalanceNonce, protocolId), amount
        );
    }

    function _message(
        uint64 sourceChainSelector,
        address sender,
        Types.CcipTx ccipTxType,
        bytes memory data,
        uint256 amount
    ) internal view returns (Client.Any2EVMMessage memory message) {
        message = Client.Any2EVMMessage({
            messageId: bytes32(0),
            sourceChainSelector: sourceChainSelector,
            sender: abi.encode(sender),
            data: abi.encode(ccipTxType, data),
            destTokenAmounts: _singleUsdcTokenAmount(amount)
        });
    }

    function _singleUsdcTokenAmount(uint256 amount)
        internal
        view
        returns (Client.EVMTokenAmount[] memory destTokenAmounts)
    {
        destTokenAmounts = new Client.EVMTokenAmount[](1);
        destTokenAmounts[0] = Client.EVMTokenAmount({token: address(s_mockUsdc), amount: amount});
    }

    function _twoUsdcTokenAmounts(uint256 firstAmount, uint256 secondAmount)
        internal
        view
        returns (Client.EVMTokenAmount[] memory destTokenAmounts)
    {
        destTokenAmounts = new Client.EVMTokenAmount[](2);
        destTokenAmounts[0] = Client.EVMTokenAmount({token: address(s_mockUsdc), amount: firstAmount});
        destTokenAmounts[1] = Client.EVMTokenAmount({token: address(s_mockUsdc), amount: secondAmount});
    }
}

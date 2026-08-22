// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {BaseUnitTest} from "../../../unit/BaseUnitTest.t.sol";

import {AaveV3Adapter} from "../../../../src/modules/adapters/AaveV3Adapter.sol";
import {WorkflowRouter} from "../../../../src/modules/WorkflowRouter.sol";
import {BaseVault} from "../../../../src/vaults/BaseVault.sol";
import {ParentVault} from "../../../../src/vaults/ParentVault.sol";
import {Roles} from "../../../../src/libraries/Roles.sol";

import {MockAaveV3PoolAddressesProvider} from "../../../mocks/MockAaveV3PoolAddressesProvider.sol";
import {MockAaveV3Pool} from "../../../mocks/MockAaveV3Pool.sol";
import {MockAToken} from "../../../mocks/MockAToken.sol";

import {KeystoneForwarder} from "@chainlink/contracts/cre/src/v1/KeystoneForwarder.sol";
import {IRouter} from "@chainlink/contracts/cre/src/v1/interfaces/IRouter.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract StaleReportRetryTest is BaseUnitTest {
    using Math for uint256;

    uint256 internal constant EXISTING_TVL = 10_000_000e6;
    uint256 internal constant TRIGGER_DEPOSIT = 1e6;
    uint256 internal constant ATTACKER_DEPOSIT = EXISTING_TVL;
    uint256 internal constant ACCRUED_YIELD = 1_000_000e6;

    uint32 internal constant DON_ID = 0x01020304;
    uint32 internal constant CONFIG_VERSION = 1;
    bytes32 internal constant WORKFLOW_ID = keccak256("close-epoch-workflow");
    bytes10 internal constant WORKFLOW_NAME = bytes10("closeepoch");
    bytes32 internal constant STALE_EXECUTION_ID = keccak256("stale-close-epoch-2");
    bytes32 internal constant FRESH_EXECUTION_ID = keccak256("fresh-close-epoch-2");
    bytes2 internal constant REPORT_ID = 0x0001;
    address internal constant HONEST_TRANSMITTER = address(0xC0FFEE);

    uint256[4] internal s_signerKeys = [uint256(101), uint256(102), uint256(103), uint256(104)];

    ParentVault internal s_vault;
    AaveV3Adapter internal s_adapter;
    MockAaveV3Pool internal s_pool;
    MockAToken internal s_aToken;
    KeystoneForwarder internal s_forwarder;
    WorkflowRouter internal s_workflowRouter;

    function setUp() public {
        _changePrank(i_owner);

        BaseVault.ConstructorParams memory vaultParams = _baseVaultParams(PARENT_CHAIN_SELECTOR);
        s_vault = _deployParentVaultProxy(vaultParams);
        s_pool = new MockAaveV3Pool(address(s_mockUsdc));
        MockAaveV3PoolAddressesProvider provider = new MockAaveV3PoolAddressesProvider(address(s_pool));
        s_adapter = new AaveV3Adapter(address(s_vault), address(provider));
        s_aToken = MockAToken(s_pool.getReserveData(address(s_mockUsdc)).aTokenAddress);

        _changePrank(i_configOperator);
        s_adapterRegistry.setAdapter(AAVE_V3_PROTOCOL_ID, address(s_adapter));
        s_vault.setSupportedProtocol(AAVE_V3_PROTOCOL_ID, true);

        _changePrank(i_owner);
        s_vault.setInitialActiveProtocolAdapter(AAVE_V3_PROTOCOL_ID);

        s_forwarder = new KeystoneForwarder();
        address[] memory signers = new address[](4);
        for (uint256 i; i < signers.length; ++i) {
            signers[i] = vm.addr(s_signerKeys[i]);
        }
        s_forwarder.setConfig(DON_ID, CONFIG_VERSION, 1, signers);

        s_workflowRouter = new WorkflowRouter(
            WorkflowRouter.ConstructorParams({
                initialDelay: 0,
                defaultAdmin: i_owner,
                pauser: i_pauser,
                unpauser: i_unpauser,
                configOperator: i_configOperator,
                keystoneForwarder: address(s_forwarder),
                vault: address(s_vault)
            })
        );
        s_vault.grantRole(Roles.EPOCH_OPERATOR_ROLE, address(s_workflowRouter));
        s_vault.grantRole(Roles.EPOCH_OPERATOR_ROLE, i_epochOperator);

        _changePrank(i_configOperator);
        s_workflowRouter.setWorkflowMetadata(WORKFLOW_ID, WORKFLOW_NAME, i_owner);
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = ParentVault.closeEpoch.selector;
        s_workflowRouter.setWorkflowSelectors(WORKFLOW_ID, selectors, true);

        _bootstrapExistingHolder();
    }

    function test_StaleReportRetry_ExpiredReportCannotCaptureIncumbentYield() external {
        uint256 existingShares = s_yieldcoin.balanceOf(i_depositor);
        (bytes memory staleReport, bytes memory reportContext, bytes[] memory staleSignatures) =
            _prepareFailedCloseReport();

        vm.warp(block.timestamp + 30 minutes + 1);
        _accrueYield(ACCRUED_YIELD);
        _fundAndDeposit(i_nonOwner, ATTACKER_DEPOSIT);

        _transmit(i_nonOwner, staleReport, reportContext, staleSignatures);

        IRouter.TransmissionInfo memory staleTransmission =
            s_forwarder.getTransmissionInfo(address(s_workflowRouter), STALE_EXECUTION_ID, REPORT_ID);
        assertEq(uint256(staleTransmission.state), uint256(IRouter.TransmissionState.FAILED));
        assertEq(s_vault.getEpochNonce(), 2, "expired report must not settle the epoch");

        _settleWithFreshReport(EXISTING_TVL + ACCRUED_YIELD);

        _changePrank(i_nonOwner);
        uint256 attackerShares = s_vault.claimShares(2);
        uint256 attackerValue = attackerShares.mulDiv(s_vault.getTVL(), s_vault.getTotalShares());
        uint256 fairShares = ATTACKER_DEPOSIT.mulDiv(existingShares, EXISTING_TVL + ACCRUED_YIELD);
        assertEq(attackerShares, fairShares);
        assertLe(attackerValue, ATTACKER_DEPOSIT);
        assertApproxEqAbs(attackerValue, ATTACKER_DEPOSIT, 1);
    }

    function testFuzz_StaleReportRetry_LateDepositorCannotClaimPreviouslyAccruedYield(
        uint256 accruedYield,
        uint256 attackerDeposit,
        uint256 reportDelay
    ) external {
        accruedYield = bound(accruedYield, 1e6, 2_000_000e6);
        attackerDeposit = bound(attackerDeposit, 1_000_000e6, 20_000_000e6);
        reportDelay = bound(reportDelay, 30 minutes + 1, 365 days);

        (bytes memory staleReport, bytes memory reportContext, bytes[] memory staleSignatures) =
            _prepareFailedCloseReport();

        vm.warp(block.timestamp + reportDelay);
        _accrueYield(accruedYield);
        _fundAndDeposit(i_nonOwner, attackerDeposit);
        _transmit(i_nonOwner, staleReport, reportContext, staleSignatures);
        assertEq(s_vault.getEpochNonce(), 2);

        _settleWithFreshReport(EXISTING_TVL + accruedYield);

        _changePrank(i_nonOwner);
        uint256 attackerShares = s_vault.claimShares(2);
        uint256 attackerValue = attackerShares.mulDiv(s_vault.getTVL(), s_vault.getTotalShares());
        assertLe(attackerValue, attackerDeposit);
        assertApproxEqAbs(attackerValue, attackerDeposit, 1);
    }

    function _prepareFailedCloseReport()
        private
        returns (bytes memory rawReport, bytes memory reportContext, bytes[] memory signatures)
    {
        _fundAndDeposit(i_nonOwner, TRIGGER_DEPOSIT);
        vm.warp(block.timestamp + MIN_EPOCH_PERIOD + 1);

        rawReport = _buildRawReport(STALE_EXECUTION_ID, 2, EXISTING_TVL);
        reportContext = new bytes(96);
        signatures = _sign(rawReport, reportContext);

        _changePrank(i_nonOwner);
        s_vault.cancelDeposit();
        _transmit(HONEST_TRANSMITTER, rawReport, reportContext, signatures);

        IRouter.TransmissionInfo memory transmission =
            s_forwarder.getTransmissionInfo(address(s_workflowRouter), STALE_EXECUTION_ID, REPORT_ID);
        assertEq(uint256(transmission.state), uint256(IRouter.TransmissionState.FAILED));
        assertEq(s_vault.getEpochNonce(), 2);
    }

    function _settleWithFreshReport(uint256 tvl) private {
        bytes memory freshReport = _buildRawReport(FRESH_EXECUTION_ID, 2, tvl);
        bytes memory reportContext = new bytes(96);
        bytes[] memory signatures = _sign(freshReport, reportContext);
        _transmit(HONEST_TRANSMITTER, freshReport, reportContext, signatures);

        IRouter.TransmissionInfo memory transmission =
            s_forwarder.getTransmissionInfo(address(s_workflowRouter), FRESH_EXECUTION_ID, REPORT_ID);
        assertEq(uint256(transmission.state), uint256(IRouter.TransmissionState.SUCCEEDED));
        assertEq(s_vault.getEpochNonce(), 3);
    }

    function _bootstrapExistingHolder() private {
        _fundAndDeposit(i_depositor, EXISTING_TVL);
        vm.warp(block.timestamp + MIN_EPOCH_PERIOD + 1);
        _changePrank(i_epochOperator);
        s_vault.closeEpoch(1, 0);
        _changePrank(i_depositor);
        s_vault.claimShares(1);
    }

    function _fundAndDeposit(address user, uint256 amount) private {
        s_mockUsdc.mint(user, amount);
        _changePrank(user);
        s_mockUsdc.approve(address(s_vault), amount);
        s_vault.deposit(amount);
    }

    function _accrueYield(uint256 amount) private {
        s_aToken.mint(address(s_adapter), amount);
        s_mockUsdc.mint(address(s_pool), amount);
    }

    function _buildRawReport(bytes32 executionId, uint256 epochNonce, uint256 tvl)
        private
        view
        returns (bytes memory rawReport)
    {
        bytes memory vaultCall = abi.encodeCall(ParentVault.closeEpoch, (epochNonce, tvl));
        bytes memory report =
            abi.encodePacked(PARENT_CHAIN_SELECTOR, address(s_workflowRouter), block.timestamp, vaultCall);
        rawReport = abi.encodePacked(
            bytes1(uint8(1)),
            executionId,
            uint32(block.timestamp),
            DON_ID,
            CONFIG_VERSION,
            WORKFLOW_ID,
            WORKFLOW_NAME,
            i_owner,
            REPORT_ID,
            report
        );
    }

    function _sign(bytes memory rawReport, bytes memory reportContext)
        private
        view
        returns (bytes[] memory signatures)
    {
        bytes32 digest = keccak256(abi.encodePacked(keccak256(rawReport), reportContext));
        signatures = new bytes[](2);
        for (uint256 i; i < signatures.length; ++i) {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(s_signerKeys[i], digest);
            signatures[i] = bytes.concat(r, s, bytes1(v - 27));
        }
    }

    function _transmit(address transmitter, bytes memory rawReport, bytes memory context, bytes[] memory signatures)
        private
    {
        _changePrank(transmitter);
        s_forwarder.report(address(s_workflowRouter), rawReport, context, signatures);
    }
}

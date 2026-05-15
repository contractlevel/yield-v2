// Code generated — DO NOT EDIT.

package child_vault

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"math/big"
	"reflect"
	"strings"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/event"
	"github.com/ethereum/go-ethereum/rpc"
	"google.golang.org/protobuf/types/known/emptypb"

	pb2 "github.com/smartcontractkit/chainlink-protos/cre/go/sdk"
	"github.com/smartcontractkit/chainlink-protos/cre/go/values/pb"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm/bindings"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

var (
	_ = bytes.Equal
	_ = errors.New
	_ = fmt.Sprintf
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
	_ = abi.ConvertType
	_ = emptypb.Empty{}
	_ = pb.NewBigIntFromInt
	_ = pb2.AggregationType_AGGREGATION_TYPE_COMMON_PREFIX
	_ = bindings.FilterOptions{}
	_ = evm.FilterLogTriggerRequest{}
	_ = cre.ResponseBufferTooSmall
	_ = rpc.API{}
	_ = json.Unmarshal
	_ = reflect.Bool
)

var ChildVaultMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"params\",\"type\":\"tuple\",\"internalType\":\"structBaseVault.ConstructorParams\",\"components\":[{\"name\":\"link\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"usdc\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"ccipRouter\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"defaultAdmin\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"pauser\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"unpauser\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"configOperator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"adapterRegistry\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"thisChainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]},{\"name\":\"parentChainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"DEFAULT_ADMIN_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"acceptDefaultAdminTransfer\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"beginDefaultAdminTransfer\",\"inputs\":[{\"name\":\"newAdmin\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"cancelDefaultAdminTransfer\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"ccipReceive\",\"inputs\":[{\"name\":\"message\",\"type\":\"tuple\",\"internalType\":\"structClient.Any2EVMMessage\",\"components\":[{\"name\":\"messageId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"sourceChainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"sender\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"destTokenAmounts\",\"type\":\"tuple[]\",\"internalType\":\"structClient.EVMTokenAmount[]\",\"components\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"changeDefaultAdminDelay\",\"inputs\":[{\"name\":\"newDelay\",\"type\":\"uint48\",\"internalType\":\"uint48\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"defaultAdmin\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"defaultAdminDelay\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint48\",\"internalType\":\"uint48\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"defaultAdminDelayIncreaseWait\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint48\",\"internalType\":\"uint48\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"emergencyDrain\",\"inputs\":[{\"name\":\"revertOnFailure\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeEpochWithdraw\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeRebalance\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"newStrategy\",\"type\":\"tuple\",\"internalType\":\"structTypes.Strategy\",\"components\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"chainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getActiveProtocolAdapter\",\"inputs\":[],\"outputs\":[{\"name\":\"activeProtocolAdapter\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAdapterRegistry\",\"inputs\":[],\"outputs\":[{\"name\":\"adapterRegistry\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getCCVsAndFinalityConfig\",\"inputs\":[{\"name\":\"\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"requiredCCVs\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"optionalCCVs\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"optionalThreshold\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"allowedFinalityConfig\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getCcipGasLimit\",\"inputs\":[{\"name\":\"chainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"outputs\":[{\"name\":\"gasLimit\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getCrosschainVault\",\"inputs\":[{\"name\":\"chainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"outputs\":[{\"name\":\"vault\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getDefaultCcipGasLimit\",\"inputs\":[],\"outputs\":[{\"name\":\"defaultCcipGasLimit\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getEpochDepositRecovery\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"recovery\",\"type\":\"tuple\",\"internalType\":\"structTypes.AmountRecovery\",\"components\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"createdAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getEpochWithdrawRecovery\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"recovery\",\"type\":\"tuple\",\"internalType\":\"structTypes.AmountRecovery\",\"components\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"createdAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getLink\",\"inputs\":[],\"outputs\":[{\"name\":\"link\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getParentChainSelector\",\"inputs\":[],\"outputs\":[{\"name\":\"parentChainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getPausedAt\",\"inputs\":[],\"outputs\":[{\"name\":\"pausedAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRebalanceDepositRecovery\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"recovery\",\"type\":\"tuple\",\"internalType\":\"structTypes.AmountRecovery\",\"components\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"createdAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRebalanceWithdrawRecovery\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"recovery\",\"type\":\"tuple\",\"internalType\":\"structTypes.RebalanceWithdrawRecovery\",\"components\":[{\"name\":\"strategy\",\"type\":\"tuple\",\"internalType\":\"structTypes.Strategy\",\"components\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"chainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]},{\"name\":\"createdAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRoleAdmin\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRouter\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getTVL\",\"inputs\":[],\"outputs\":[{\"name\":\"tvl\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getThisChainSelector\",\"inputs\":[],\"outputs\":[{\"name\":\"thisChainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getUsdc\",\"inputs\":[],\"outputs\":[{\"name\":\"usdc\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"grantRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"hasRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"owner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pause\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"paused\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pendingDefaultAdmin\",\"inputs\":[],\"outputs\":[{\"name\":\"newAdmin\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"schedule\",\"type\":\"uint48\",\"internalType\":\"uint48\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pendingDefaultAdminDelay\",\"inputs\":[],\"outputs\":[{\"name\":\"newDelay\",\"type\":\"uint48\",\"internalType\":\"uint48\"},{\"name\":\"schedule\",\"type\":\"uint48\",\"internalType\":\"uint48\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"recoverFailedEpochDeposit\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"recoverFailedEpochWithdraw\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"recoverFailedRebalanceDeposit\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"recoverFailedRebalanceWithdraw\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"revokeRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"rollbackDefaultAdminDelay\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setCcipGasLimit\",\"inputs\":[{\"name\":\"chainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"gasLimit\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setCrosschainVaults\",\"inputs\":[{\"name\":\"chainSelectors\",\"type\":\"uint64[]\",\"internalType\":\"uint64[]\"},{\"name\":\"vaults\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setDefaultCcipGasLimit\",\"inputs\":[{\"name\":\"gasLimit\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"tryDepositToAdapter\",\"inputs\":[{\"name\":\"adapter\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"unpause\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"withdrawLink\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"CcipGasLimitSet\",\"inputs\":[{\"name\":\"chainSelector\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"},{\"name\":\"gasLimit\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"CrosschainVaultSet\",\"inputs\":[{\"name\":\"chainSelector\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"},{\"name\":\"vault\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DefaultAdminDelayChangeCanceled\",\"inputs\":[],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DefaultAdminDelayChangeScheduled\",\"inputs\":[{\"name\":\"newDelay\",\"type\":\"uint48\",\"indexed\":false,\"internalType\":\"uint48\"},{\"name\":\"effectSchedule\",\"type\":\"uint48\",\"indexed\":false,\"internalType\":\"uint48\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DefaultAdminTransferCanceled\",\"inputs\":[],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DefaultAdminTransferScheduled\",\"inputs\":[{\"name\":\"newAdmin\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"acceptSchedule\",\"type\":\"uint48\",\"indexed\":false,\"internalType\":\"uint48\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DefaultCcipGasLimitSet\",\"inputs\":[{\"name\":\"gasLimit\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DepositToStrategyFailure\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DepositToStrategySuccess\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"EmergencyDrainExecuted\",\"inputs\":[{\"name\":\"drainer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"EpochDepositRecoveryCleared\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"EpochDepositRecoveryStored\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"EpochWithdrawRecoveryCleared\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"EpochWithdrawRecoveryStored\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"LinkWithdrawn\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Paused\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RebalanceDepositFailure\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RebalanceDepositRecoveryCleared\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RebalanceDepositRecoveryStored\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RebalanceDepositSuccess\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RebalanceWithdrawFailure\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RebalanceWithdrawRecoveryCleared\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RebalanceWithdrawRecoveryStored\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"protocolId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"chainSelector\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RebalanceWithdrawSuccess\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleAdminChanged\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"previousAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"newAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleGranted\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleRevoked\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"USDCBridged\",\"inputs\":[{\"name\":\"ccipMessageId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"ccipTxType\",\"type\":\"uint8\",\"indexed\":true,\"internalType\":\"enumTypes.CcipTx\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Unpaused\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"WithdrawFromStrategyFailure\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"WithdrawFromStrategySuccess\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"AccessControlBadConfirmation\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"AccessControlEnforcedDefaultAdminDelay\",\"inputs\":[{\"name\":\"schedule\",\"type\":\"uint48\",\"internalType\":\"uint48\"}]},{\"type\":\"error\",\"name\":\"AccessControlEnforcedDefaultAdminRules\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"AccessControlInvalidDefaultAdmin\",\"inputs\":[{\"name\":\"defaultAdmin\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"AccessControlUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"neededRole\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"BaseVault__DepositFailed\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"BaseVault__EmergencyDrainDelayNotMet\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"BaseVault__InvalidInputLengths\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"BaseVault__InvalidSender\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"srcChainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]},{\"type\":\"error\",\"name\":\"BaseVault__NoActiveAdapter\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"BaseVault__NoAdapterRegistered\",\"inputs\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"BaseVault__NoPendingRecovery\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"BaseVault__NoZeroAmount\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"BaseVault__OnlySelf\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"BaseVault__RecoveryAlreadyPending\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"BaseVault__WithdrawFailed\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"BaseVault__ZeroRecoveryAmount\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ChildVault__InvalidRecoveryStrategy\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"EnforcedPause\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ExpectedPause\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidRouter\",\"inputs\":[{\"name\":\"router\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ReentrancyGuardReentrantCall\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SafeCastOverflowedUintDowncast\",\"inputs\":[{\"name\":\"bits\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"SafeERC20FailedOperation\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"}]}]",
}

// Structs
type BaseVaultConstructorParams struct {
	Link              common.Address
	Usdc              common.Address
	CcipRouter        common.Address
	DefaultAdmin      common.Address
	Pauser            common.Address
	Unpauser          common.Address
	ConfigOperator    common.Address
	AdapterRegistry   common.Address
	ThisChainSelector uint64
}

type ClientAny2EVMMessage struct {
	MessageId           [32]byte
	SourceChainSelector uint64
	Sender              []byte
	Data                []byte
	DestTokenAmounts    []ClientEVMTokenAmount
}

type ClientEVMTokenAmount struct {
	Token  common.Address
	Amount *big.Int
}

type TypesAmountRecovery struct {
	Amount    *big.Int
	CreatedAt *big.Int
}

type TypesRebalanceWithdrawRecovery struct {
	Strategy  TypesStrategy
	CreatedAt *big.Int
}

type TypesStrategy struct {
	ProtocolId    [32]byte
	ChainSelector uint64
}

// Contract Method Inputs
type BeginDefaultAdminTransferInput struct {
	NewAdmin common.Address
}

type CcipReceiveInput struct {
	Message ClientAny2EVMMessage
}

type ChangeDefaultAdminDelayInput struct {
	NewDelay *big.Int
}

type EmergencyDrainInput struct {
	RevertOnFailure bool
}

type ExecuteEpochWithdrawInput struct {
	EpochNonce *big.Int
	Amount     *big.Int
}

type ExecuteRebalanceInput struct {
	RebalanceNonce *big.Int
	NewStrategy    TypesStrategy
}

type GetCCVsAndFinalityConfigInput struct {
	Arg0 uint64
	Arg1 []byte
}

type GetCcipGasLimitInput struct {
	ChainSelector uint64
}

type GetCrosschainVaultInput struct {
	ChainSelector uint64
}

type GetEpochDepositRecoveryInput struct {
	EpochNonce *big.Int
}

type GetEpochWithdrawRecoveryInput struct {
	EpochNonce *big.Int
}

type GetRebalanceDepositRecoveryInput struct {
	RebalanceNonce *big.Int
}

type GetRebalanceWithdrawRecoveryInput struct {
	RebalanceNonce *big.Int
}

type GetRoleAdminInput struct {
	Role [32]byte
}

type GrantRoleInput struct {
	Role    [32]byte
	Account common.Address
}

type HasRoleInput struct {
	Role    [32]byte
	Account common.Address
}

type RecoverFailedEpochDepositInput struct {
	EpochNonce *big.Int
}

type RecoverFailedEpochWithdrawInput struct {
	EpochNonce *big.Int
}

type RecoverFailedRebalanceDepositInput struct {
	RebalanceNonce *big.Int
}

type RecoverFailedRebalanceWithdrawInput struct {
	RebalanceNonce *big.Int
}

type RenounceRoleInput struct {
	Role    [32]byte
	Account common.Address
}

type RevokeRoleInput struct {
	Role    [32]byte
	Account common.Address
}

type SetCcipGasLimitInput struct {
	ChainSelector uint64
	GasLimit      *big.Int
}

type SetCrosschainVaultsInput struct {
	ChainSelectors []uint64
	Vaults         []common.Address
}

type SetDefaultCcipGasLimitInput struct {
	GasLimit *big.Int
}

type SupportsInterfaceInput struct {
	InterfaceId [4]byte
}

type TryDepositToAdapterInput struct {
	Adapter common.Address
	Amount  *big.Int
}

type WithdrawLinkInput struct {
	Amount *big.Int
}

// Contract Method Outputs
type GetCCVsAndFinalityConfigOutput struct {
	RequiredCCVs          []common.Address
	OptionalCCVs          []common.Address
	OptionalThreshold     uint8
	AllowedFinalityConfig [4]byte
}

type PendingDefaultAdminOutput struct {
	NewAdmin common.Address
	Schedule *big.Int
}

type PendingDefaultAdminDelayOutput struct {
	NewDelay *big.Int
	Schedule *big.Int
}

// Errors
type AccessControlBadConfirmation struct {
}

type AccessControlEnforcedDefaultAdminDelay struct {
	Schedule *big.Int
}

type AccessControlEnforcedDefaultAdminRules struct {
}

type AccessControlInvalidDefaultAdmin struct {
	DefaultAdmin common.Address
}

type AccessControlUnauthorizedAccount struct {
	Account    common.Address
	NeededRole [32]byte
}

type BaseVaultDepositFailed struct {
	Amount *big.Int
}

type BaseVaultEmergencyDrainDelayNotMet struct {
}

type BaseVaultInvalidInputLengths struct {
}

type BaseVaultInvalidSender struct {
	Sender           common.Address
	SrcChainSelector uint64
}

type BaseVaultNoActiveAdapter struct {
}

type BaseVaultNoAdapterRegistered struct {
	ProtocolId [32]byte
}

type BaseVaultNoPendingRecovery struct {
}

type BaseVaultNoZeroAmount struct {
}

type BaseVaultOnlySelf struct {
}

type BaseVaultRecoveryAlreadyPending struct {
}

type BaseVaultWithdrawFailed struct {
	Amount *big.Int
}

type BaseVaultZeroRecoveryAmount struct {
}

type ChildVaultInvalidRecoveryStrategy struct {
}

type EnforcedPause struct {
}

type ExpectedPause struct {
}

type InvalidRouter struct {
	Router common.Address
}

type ReentrancyGuardReentrantCall struct {
}

type SafeCastOverflowedUintDowncast struct {
	Bits  uint8
	Value *big.Int
}

type SafeERC20FailedOperation struct {
	Token common.Address
}

// Events
// The <Event>Topics struct should be used as a filter (for log triggers).
// Note: It is only possible to filter on indexed fields.
// Indexed (string and bytes) fields will be of type common.Hash.
// They need to he (crypto.Keccak256) hashed and passed in.
// Indexed (tuple/slice/array) fields can be passed in as is, the Encode<Event>Topics function will handle the hashing.
//
// The <Event>Decoded struct will be the result of calling decode (Adapt) on the log trigger result.
// Indexed dynamic type fields will be of type common.Hash.

type CcipGasLimitSetTopics struct {
	ChainSelector uint64
	GasLimit      *big.Int
}

type CcipGasLimitSetDecoded struct {
	ChainSelector uint64
	GasLimit      *big.Int
}

type CrosschainVaultSetTopics struct {
	ChainSelector uint64
	Vault         common.Address
}

type CrosschainVaultSetDecoded struct {
	ChainSelector uint64
	Vault         common.Address
}

type DefaultAdminDelayChangeCanceledTopics struct {
}

type DefaultAdminDelayChangeCanceledDecoded struct {
}

type DefaultAdminDelayChangeScheduledTopics struct {
}

type DefaultAdminDelayChangeScheduledDecoded struct {
	NewDelay       *big.Int
	EffectSchedule *big.Int
}

type DefaultAdminTransferCanceledTopics struct {
}

type DefaultAdminTransferCanceledDecoded struct {
}

type DefaultAdminTransferScheduledTopics struct {
	NewAdmin common.Address
}

type DefaultAdminTransferScheduledDecoded struct {
	NewAdmin       common.Address
	AcceptSchedule *big.Int
}

type DefaultCcipGasLimitSetTopics struct {
	GasLimit *big.Int
}

type DefaultCcipGasLimitSetDecoded struct {
	GasLimit *big.Int
}

type DepositToStrategyFailureTopics struct {
	EpochNonce *big.Int
	Amount     *big.Int
}

type DepositToStrategyFailureDecoded struct {
	EpochNonce *big.Int
	Amount     *big.Int
}

type DepositToStrategySuccessTopics struct {
	EpochNonce *big.Int
	Amount     *big.Int
}

type DepositToStrategySuccessDecoded struct {
	EpochNonce *big.Int
	Amount     *big.Int
}

type EmergencyDrainExecutedTopics struct {
	Drainer common.Address
	Amount  *big.Int
}

type EmergencyDrainExecutedDecoded struct {
	Drainer common.Address
	Amount  *big.Int
}

type EpochDepositRecoveryClearedTopics struct {
	EpochNonce *big.Int
}

type EpochDepositRecoveryClearedDecoded struct {
	EpochNonce *big.Int
}

type EpochDepositRecoveryStoredTopics struct {
	EpochNonce *big.Int
	Amount     *big.Int
}

type EpochDepositRecoveryStoredDecoded struct {
	EpochNonce *big.Int
	Amount     *big.Int
}

type EpochWithdrawRecoveryClearedTopics struct {
	EpochNonce *big.Int
}

type EpochWithdrawRecoveryClearedDecoded struct {
	EpochNonce *big.Int
}

type EpochWithdrawRecoveryStoredTopics struct {
	EpochNonce *big.Int
	Amount     *big.Int
}

type EpochWithdrawRecoveryStoredDecoded struct {
	EpochNonce *big.Int
	Amount     *big.Int
}

type LinkWithdrawnTopics struct {
	Operator common.Address
	Amount   *big.Int
}

type LinkWithdrawnDecoded struct {
	Operator common.Address
	Amount   *big.Int
}

type PausedTopics struct {
}

type PausedDecoded struct {
	Account common.Address
}

type RebalanceDepositFailureTopics struct {
	RebalanceNonce *big.Int
	Amount         *big.Int
}

type RebalanceDepositFailureDecoded struct {
	RebalanceNonce *big.Int
	Amount         *big.Int
}

type RebalanceDepositRecoveryClearedTopics struct {
	RebalanceNonce *big.Int
}

type RebalanceDepositRecoveryClearedDecoded struct {
	RebalanceNonce *big.Int
}

type RebalanceDepositRecoveryStoredTopics struct {
	RebalanceNonce *big.Int
	Amount         *big.Int
}

type RebalanceDepositRecoveryStoredDecoded struct {
	RebalanceNonce *big.Int
	Amount         *big.Int
}

type RebalanceDepositSuccessTopics struct {
	RebalanceNonce *big.Int
	Amount         *big.Int
}

type RebalanceDepositSuccessDecoded struct {
	RebalanceNonce *big.Int
	Amount         *big.Int
}

type RebalanceWithdrawFailureTopics struct {
	RebalanceNonce *big.Int
}

type RebalanceWithdrawFailureDecoded struct {
	RebalanceNonce *big.Int
}

type RebalanceWithdrawRecoveryClearedTopics struct {
	RebalanceNonce *big.Int
}

type RebalanceWithdrawRecoveryClearedDecoded struct {
	RebalanceNonce *big.Int
}

type RebalanceWithdrawRecoveryStoredTopics struct {
	RebalanceNonce *big.Int
	ProtocolId     [32]byte
	ChainSelector  uint64
}

type RebalanceWithdrawRecoveryStoredDecoded struct {
	RebalanceNonce *big.Int
	ProtocolId     [32]byte
	ChainSelector  uint64
}

type RebalanceWithdrawSuccessTopics struct {
	RebalanceNonce *big.Int
	Amount         *big.Int
}

type RebalanceWithdrawSuccessDecoded struct {
	RebalanceNonce *big.Int
	Amount         *big.Int
}

type RoleAdminChangedTopics struct {
	Role              [32]byte
	PreviousAdminRole [32]byte
	NewAdminRole      [32]byte
}

type RoleAdminChangedDecoded struct {
	Role              [32]byte
	PreviousAdminRole [32]byte
	NewAdminRole      [32]byte
}

type RoleGrantedTopics struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
}

type RoleGrantedDecoded struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
}

type RoleRevokedTopics struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
}

type RoleRevokedDecoded struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
}

type USDCBridgedTopics struct {
	CcipMessageId [32]byte
	Amount        *big.Int
	CcipTxType    uint8
}

type USDCBridgedDecoded struct {
	CcipMessageId [32]byte
	Amount        *big.Int
	CcipTxType    uint8
}

type UnpausedTopics struct {
}

type UnpausedDecoded struct {
	Account common.Address
}

type WithdrawFromStrategyFailureTopics struct {
	EpochNonce *big.Int
	Amount     *big.Int
}

type WithdrawFromStrategyFailureDecoded struct {
	EpochNonce *big.Int
	Amount     *big.Int
}

type WithdrawFromStrategySuccessTopics struct {
	EpochNonce *big.Int
	Amount     *big.Int
}

type WithdrawFromStrategySuccessDecoded struct {
	EpochNonce *big.Int
	Amount     *big.Int
}

// Main Binding Type for ChildVault
type ChildVault struct {
	Address common.Address
	Options *bindings.ContractInitOptions
	ABI     *abi.ABI
	client  *evm.Client
	Codec   ChildVaultCodec
}

type ChildVaultCodec interface {
	EncodeDEFAULTADMINROLEMethodCall() ([]byte, error)
	DecodeDEFAULTADMINROLEMethodOutput(data []byte) ([32]byte, error)
	EncodeAcceptDefaultAdminTransferMethodCall() ([]byte, error)
	EncodeBeginDefaultAdminTransferMethodCall(in BeginDefaultAdminTransferInput) ([]byte, error)
	EncodeCancelDefaultAdminTransferMethodCall() ([]byte, error)
	EncodeCcipReceiveMethodCall(in CcipReceiveInput) ([]byte, error)
	EncodeChangeDefaultAdminDelayMethodCall(in ChangeDefaultAdminDelayInput) ([]byte, error)
	EncodeDefaultAdminMethodCall() ([]byte, error)
	DecodeDefaultAdminMethodOutput(data []byte) (common.Address, error)
	EncodeDefaultAdminDelayMethodCall() ([]byte, error)
	DecodeDefaultAdminDelayMethodOutput(data []byte) (*big.Int, error)
	EncodeDefaultAdminDelayIncreaseWaitMethodCall() ([]byte, error)
	DecodeDefaultAdminDelayIncreaseWaitMethodOutput(data []byte) (*big.Int, error)
	EncodeEmergencyDrainMethodCall(in EmergencyDrainInput) ([]byte, error)
	EncodeExecuteEpochWithdrawMethodCall(in ExecuteEpochWithdrawInput) ([]byte, error)
	EncodeExecuteRebalanceMethodCall(in ExecuteRebalanceInput) ([]byte, error)
	EncodeGetActiveProtocolAdapterMethodCall() ([]byte, error)
	DecodeGetActiveProtocolAdapterMethodOutput(data []byte) (common.Address, error)
	EncodeGetAdapterRegistryMethodCall() ([]byte, error)
	DecodeGetAdapterRegistryMethodOutput(data []byte) (common.Address, error)
	EncodeGetCCVsAndFinalityConfigMethodCall(in GetCCVsAndFinalityConfigInput) ([]byte, error)
	DecodeGetCCVsAndFinalityConfigMethodOutput(data []byte) (GetCCVsAndFinalityConfigOutput, error)
	EncodeGetCcipGasLimitMethodCall(in GetCcipGasLimitInput) ([]byte, error)
	DecodeGetCcipGasLimitMethodOutput(data []byte) (*big.Int, error)
	EncodeGetCrosschainVaultMethodCall(in GetCrosschainVaultInput) ([]byte, error)
	DecodeGetCrosschainVaultMethodOutput(data []byte) (common.Address, error)
	EncodeGetDefaultCcipGasLimitMethodCall() ([]byte, error)
	DecodeGetDefaultCcipGasLimitMethodOutput(data []byte) (*big.Int, error)
	EncodeGetEpochDepositRecoveryMethodCall(in GetEpochDepositRecoveryInput) ([]byte, error)
	DecodeGetEpochDepositRecoveryMethodOutput(data []byte) (TypesAmountRecovery, error)
	EncodeGetEpochWithdrawRecoveryMethodCall(in GetEpochWithdrawRecoveryInput) ([]byte, error)
	DecodeGetEpochWithdrawRecoveryMethodOutput(data []byte) (TypesAmountRecovery, error)
	EncodeGetLinkMethodCall() ([]byte, error)
	DecodeGetLinkMethodOutput(data []byte) (common.Address, error)
	EncodeGetParentChainSelectorMethodCall() ([]byte, error)
	DecodeGetParentChainSelectorMethodOutput(data []byte) (uint64, error)
	EncodeGetPausedAtMethodCall() ([]byte, error)
	DecodeGetPausedAtMethodOutput(data []byte) (*big.Int, error)
	EncodeGetRebalanceDepositRecoveryMethodCall(in GetRebalanceDepositRecoveryInput) ([]byte, error)
	DecodeGetRebalanceDepositRecoveryMethodOutput(data []byte) (TypesAmountRecovery, error)
	EncodeGetRebalanceWithdrawRecoveryMethodCall(in GetRebalanceWithdrawRecoveryInput) ([]byte, error)
	DecodeGetRebalanceWithdrawRecoveryMethodOutput(data []byte) (TypesRebalanceWithdrawRecovery, error)
	EncodeGetRoleAdminMethodCall(in GetRoleAdminInput) ([]byte, error)
	DecodeGetRoleAdminMethodOutput(data []byte) ([32]byte, error)
	EncodeGetRouterMethodCall() ([]byte, error)
	DecodeGetRouterMethodOutput(data []byte) (common.Address, error)
	EncodeGetTVLMethodCall() ([]byte, error)
	DecodeGetTVLMethodOutput(data []byte) (*big.Int, error)
	EncodeGetThisChainSelectorMethodCall() ([]byte, error)
	DecodeGetThisChainSelectorMethodOutput(data []byte) (uint64, error)
	EncodeGetUsdcMethodCall() ([]byte, error)
	DecodeGetUsdcMethodOutput(data []byte) (common.Address, error)
	EncodeGrantRoleMethodCall(in GrantRoleInput) ([]byte, error)
	EncodeHasRoleMethodCall(in HasRoleInput) ([]byte, error)
	DecodeHasRoleMethodOutput(data []byte) (bool, error)
	EncodeOwnerMethodCall() ([]byte, error)
	DecodeOwnerMethodOutput(data []byte) (common.Address, error)
	EncodePauseMethodCall() ([]byte, error)
	EncodePausedMethodCall() ([]byte, error)
	DecodePausedMethodOutput(data []byte) (bool, error)
	EncodePendingDefaultAdminMethodCall() ([]byte, error)
	DecodePendingDefaultAdminMethodOutput(data []byte) (PendingDefaultAdminOutput, error)
	EncodePendingDefaultAdminDelayMethodCall() ([]byte, error)
	DecodePendingDefaultAdminDelayMethodOutput(data []byte) (PendingDefaultAdminDelayOutput, error)
	EncodeRecoverFailedEpochDepositMethodCall(in RecoverFailedEpochDepositInput) ([]byte, error)
	EncodeRecoverFailedEpochWithdrawMethodCall(in RecoverFailedEpochWithdrawInput) ([]byte, error)
	EncodeRecoverFailedRebalanceDepositMethodCall(in RecoverFailedRebalanceDepositInput) ([]byte, error)
	EncodeRecoverFailedRebalanceWithdrawMethodCall(in RecoverFailedRebalanceWithdrawInput) ([]byte, error)
	EncodeRenounceRoleMethodCall(in RenounceRoleInput) ([]byte, error)
	EncodeRevokeRoleMethodCall(in RevokeRoleInput) ([]byte, error)
	EncodeRollbackDefaultAdminDelayMethodCall() ([]byte, error)
	EncodeSetCcipGasLimitMethodCall(in SetCcipGasLimitInput) ([]byte, error)
	EncodeSetCrosschainVaultsMethodCall(in SetCrosschainVaultsInput) ([]byte, error)
	EncodeSetDefaultCcipGasLimitMethodCall(in SetDefaultCcipGasLimitInput) ([]byte, error)
	EncodeSupportsInterfaceMethodCall(in SupportsInterfaceInput) ([]byte, error)
	DecodeSupportsInterfaceMethodOutput(data []byte) (bool, error)
	EncodeTryDepositToAdapterMethodCall(in TryDepositToAdapterInput) ([]byte, error)
	EncodeUnpauseMethodCall() ([]byte, error)
	EncodeWithdrawLinkMethodCall(in WithdrawLinkInput) ([]byte, error)
	EncodeBaseVaultConstructorParamsStruct(in BaseVaultConstructorParams) ([]byte, error)
	EncodeClientAny2EVMMessageStruct(in ClientAny2EVMMessage) ([]byte, error)
	EncodeClientEVMTokenAmountStruct(in ClientEVMTokenAmount) ([]byte, error)
	EncodeTypesAmountRecoveryStruct(in TypesAmountRecovery) ([]byte, error)
	EncodeTypesRebalanceWithdrawRecoveryStruct(in TypesRebalanceWithdrawRecovery) ([]byte, error)
	EncodeTypesStrategyStruct(in TypesStrategy) ([]byte, error)
	CcipGasLimitSetLogHash() []byte
	EncodeCcipGasLimitSetTopics(evt abi.Event, values []CcipGasLimitSetTopics) ([]*evm.TopicValues, error)
	DecodeCcipGasLimitSet(log *evm.Log) (*CcipGasLimitSetDecoded, error)
	CrosschainVaultSetLogHash() []byte
	EncodeCrosschainVaultSetTopics(evt abi.Event, values []CrosschainVaultSetTopics) ([]*evm.TopicValues, error)
	DecodeCrosschainVaultSet(log *evm.Log) (*CrosschainVaultSetDecoded, error)
	DefaultAdminDelayChangeCanceledLogHash() []byte
	EncodeDefaultAdminDelayChangeCanceledTopics(evt abi.Event, values []DefaultAdminDelayChangeCanceledTopics) ([]*evm.TopicValues, error)
	DecodeDefaultAdminDelayChangeCanceled(log *evm.Log) (*DefaultAdminDelayChangeCanceledDecoded, error)
	DefaultAdminDelayChangeScheduledLogHash() []byte
	EncodeDefaultAdminDelayChangeScheduledTopics(evt abi.Event, values []DefaultAdminDelayChangeScheduledTopics) ([]*evm.TopicValues, error)
	DecodeDefaultAdminDelayChangeScheduled(log *evm.Log) (*DefaultAdminDelayChangeScheduledDecoded, error)
	DefaultAdminTransferCanceledLogHash() []byte
	EncodeDefaultAdminTransferCanceledTopics(evt abi.Event, values []DefaultAdminTransferCanceledTopics) ([]*evm.TopicValues, error)
	DecodeDefaultAdminTransferCanceled(log *evm.Log) (*DefaultAdminTransferCanceledDecoded, error)
	DefaultAdminTransferScheduledLogHash() []byte
	EncodeDefaultAdminTransferScheduledTopics(evt abi.Event, values []DefaultAdminTransferScheduledTopics) ([]*evm.TopicValues, error)
	DecodeDefaultAdminTransferScheduled(log *evm.Log) (*DefaultAdminTransferScheduledDecoded, error)
	DefaultCcipGasLimitSetLogHash() []byte
	EncodeDefaultCcipGasLimitSetTopics(evt abi.Event, values []DefaultCcipGasLimitSetTopics) ([]*evm.TopicValues, error)
	DecodeDefaultCcipGasLimitSet(log *evm.Log) (*DefaultCcipGasLimitSetDecoded, error)
	DepositToStrategyFailureLogHash() []byte
	EncodeDepositToStrategyFailureTopics(evt abi.Event, values []DepositToStrategyFailureTopics) ([]*evm.TopicValues, error)
	DecodeDepositToStrategyFailure(log *evm.Log) (*DepositToStrategyFailureDecoded, error)
	DepositToStrategySuccessLogHash() []byte
	EncodeDepositToStrategySuccessTopics(evt abi.Event, values []DepositToStrategySuccessTopics) ([]*evm.TopicValues, error)
	DecodeDepositToStrategySuccess(log *evm.Log) (*DepositToStrategySuccessDecoded, error)
	EmergencyDrainExecutedLogHash() []byte
	EncodeEmergencyDrainExecutedTopics(evt abi.Event, values []EmergencyDrainExecutedTopics) ([]*evm.TopicValues, error)
	DecodeEmergencyDrainExecuted(log *evm.Log) (*EmergencyDrainExecutedDecoded, error)
	EpochDepositRecoveryClearedLogHash() []byte
	EncodeEpochDepositRecoveryClearedTopics(evt abi.Event, values []EpochDepositRecoveryClearedTopics) ([]*evm.TopicValues, error)
	DecodeEpochDepositRecoveryCleared(log *evm.Log) (*EpochDepositRecoveryClearedDecoded, error)
	EpochDepositRecoveryStoredLogHash() []byte
	EncodeEpochDepositRecoveryStoredTopics(evt abi.Event, values []EpochDepositRecoveryStoredTopics) ([]*evm.TopicValues, error)
	DecodeEpochDepositRecoveryStored(log *evm.Log) (*EpochDepositRecoveryStoredDecoded, error)
	EpochWithdrawRecoveryClearedLogHash() []byte
	EncodeEpochWithdrawRecoveryClearedTopics(evt abi.Event, values []EpochWithdrawRecoveryClearedTopics) ([]*evm.TopicValues, error)
	DecodeEpochWithdrawRecoveryCleared(log *evm.Log) (*EpochWithdrawRecoveryClearedDecoded, error)
	EpochWithdrawRecoveryStoredLogHash() []byte
	EncodeEpochWithdrawRecoveryStoredTopics(evt abi.Event, values []EpochWithdrawRecoveryStoredTopics) ([]*evm.TopicValues, error)
	DecodeEpochWithdrawRecoveryStored(log *evm.Log) (*EpochWithdrawRecoveryStoredDecoded, error)
	LinkWithdrawnLogHash() []byte
	EncodeLinkWithdrawnTopics(evt abi.Event, values []LinkWithdrawnTopics) ([]*evm.TopicValues, error)
	DecodeLinkWithdrawn(log *evm.Log) (*LinkWithdrawnDecoded, error)
	PausedLogHash() []byte
	EncodePausedTopics(evt abi.Event, values []PausedTopics) ([]*evm.TopicValues, error)
	DecodePaused(log *evm.Log) (*PausedDecoded, error)
	RebalanceDepositFailureLogHash() []byte
	EncodeRebalanceDepositFailureTopics(evt abi.Event, values []RebalanceDepositFailureTopics) ([]*evm.TopicValues, error)
	DecodeRebalanceDepositFailure(log *evm.Log) (*RebalanceDepositFailureDecoded, error)
	RebalanceDepositRecoveryClearedLogHash() []byte
	EncodeRebalanceDepositRecoveryClearedTopics(evt abi.Event, values []RebalanceDepositRecoveryClearedTopics) ([]*evm.TopicValues, error)
	DecodeRebalanceDepositRecoveryCleared(log *evm.Log) (*RebalanceDepositRecoveryClearedDecoded, error)
	RebalanceDepositRecoveryStoredLogHash() []byte
	EncodeRebalanceDepositRecoveryStoredTopics(evt abi.Event, values []RebalanceDepositRecoveryStoredTopics) ([]*evm.TopicValues, error)
	DecodeRebalanceDepositRecoveryStored(log *evm.Log) (*RebalanceDepositRecoveryStoredDecoded, error)
	RebalanceDepositSuccessLogHash() []byte
	EncodeRebalanceDepositSuccessTopics(evt abi.Event, values []RebalanceDepositSuccessTopics) ([]*evm.TopicValues, error)
	DecodeRebalanceDepositSuccess(log *evm.Log) (*RebalanceDepositSuccessDecoded, error)
	RebalanceWithdrawFailureLogHash() []byte
	EncodeRebalanceWithdrawFailureTopics(evt abi.Event, values []RebalanceWithdrawFailureTopics) ([]*evm.TopicValues, error)
	DecodeRebalanceWithdrawFailure(log *evm.Log) (*RebalanceWithdrawFailureDecoded, error)
	RebalanceWithdrawRecoveryClearedLogHash() []byte
	EncodeRebalanceWithdrawRecoveryClearedTopics(evt abi.Event, values []RebalanceWithdrawRecoveryClearedTopics) ([]*evm.TopicValues, error)
	DecodeRebalanceWithdrawRecoveryCleared(log *evm.Log) (*RebalanceWithdrawRecoveryClearedDecoded, error)
	RebalanceWithdrawRecoveryStoredLogHash() []byte
	EncodeRebalanceWithdrawRecoveryStoredTopics(evt abi.Event, values []RebalanceWithdrawRecoveryStoredTopics) ([]*evm.TopicValues, error)
	DecodeRebalanceWithdrawRecoveryStored(log *evm.Log) (*RebalanceWithdrawRecoveryStoredDecoded, error)
	RebalanceWithdrawSuccessLogHash() []byte
	EncodeRebalanceWithdrawSuccessTopics(evt abi.Event, values []RebalanceWithdrawSuccessTopics) ([]*evm.TopicValues, error)
	DecodeRebalanceWithdrawSuccess(log *evm.Log) (*RebalanceWithdrawSuccessDecoded, error)
	RoleAdminChangedLogHash() []byte
	EncodeRoleAdminChangedTopics(evt abi.Event, values []RoleAdminChangedTopics) ([]*evm.TopicValues, error)
	DecodeRoleAdminChanged(log *evm.Log) (*RoleAdminChangedDecoded, error)
	RoleGrantedLogHash() []byte
	EncodeRoleGrantedTopics(evt abi.Event, values []RoleGrantedTopics) ([]*evm.TopicValues, error)
	DecodeRoleGranted(log *evm.Log) (*RoleGrantedDecoded, error)
	RoleRevokedLogHash() []byte
	EncodeRoleRevokedTopics(evt abi.Event, values []RoleRevokedTopics) ([]*evm.TopicValues, error)
	DecodeRoleRevoked(log *evm.Log) (*RoleRevokedDecoded, error)
	USDCBridgedLogHash() []byte
	EncodeUSDCBridgedTopics(evt abi.Event, values []USDCBridgedTopics) ([]*evm.TopicValues, error)
	DecodeUSDCBridged(log *evm.Log) (*USDCBridgedDecoded, error)
	UnpausedLogHash() []byte
	EncodeUnpausedTopics(evt abi.Event, values []UnpausedTopics) ([]*evm.TopicValues, error)
	DecodeUnpaused(log *evm.Log) (*UnpausedDecoded, error)
	WithdrawFromStrategyFailureLogHash() []byte
	EncodeWithdrawFromStrategyFailureTopics(evt abi.Event, values []WithdrawFromStrategyFailureTopics) ([]*evm.TopicValues, error)
	DecodeWithdrawFromStrategyFailure(log *evm.Log) (*WithdrawFromStrategyFailureDecoded, error)
	WithdrawFromStrategySuccessLogHash() []byte
	EncodeWithdrawFromStrategySuccessTopics(evt abi.Event, values []WithdrawFromStrategySuccessTopics) ([]*evm.TopicValues, error)
	DecodeWithdrawFromStrategySuccess(log *evm.Log) (*WithdrawFromStrategySuccessDecoded, error)
}

func NewChildVault(
	client *evm.Client,
	address common.Address,
	options *bindings.ContractInitOptions,
) (*ChildVault, error) {
	parsed, err := abi.JSON(strings.NewReader(ChildVaultMetaData.ABI))
	if err != nil {
		return nil, err
	}
	codec, err := NewCodec()
	if err != nil {
		return nil, err
	}
	return &ChildVault{
		Address: address,
		Options: options,
		ABI:     &parsed,
		client:  client,
		Codec:   codec,
	}, nil
}

type Codec struct {
	abi *abi.ABI
}

func NewCodec() (ChildVaultCodec, error) {
	parsed, err := abi.JSON(strings.NewReader(ChildVaultMetaData.ABI))
	if err != nil {
		return nil, err
	}
	return &Codec{abi: &parsed}, nil
}

func (c *Codec) EncodeDEFAULTADMINROLEMethodCall() ([]byte, error) {
	return c.abi.Pack("DEFAULT_ADMIN_ROLE")
}

func (c *Codec) DecodeDEFAULTADMINROLEMethodOutput(data []byte) ([32]byte, error) {
	vals, err := c.abi.Methods["DEFAULT_ADMIN_ROLE"].Outputs.Unpack(data)
	if err != nil {
		return *new([32]byte), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new([32]byte), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result [32]byte
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new([32]byte), fmt.Errorf("failed to unmarshal to [32]byte: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeAcceptDefaultAdminTransferMethodCall() ([]byte, error) {
	return c.abi.Pack("acceptDefaultAdminTransfer")
}

func (c *Codec) EncodeBeginDefaultAdminTransferMethodCall(in BeginDefaultAdminTransferInput) ([]byte, error) {
	return c.abi.Pack("beginDefaultAdminTransfer", in.NewAdmin)
}

func (c *Codec) EncodeCancelDefaultAdminTransferMethodCall() ([]byte, error) {
	return c.abi.Pack("cancelDefaultAdminTransfer")
}

func (c *Codec) EncodeCcipReceiveMethodCall(in CcipReceiveInput) ([]byte, error) {
	return c.abi.Pack("ccipReceive", in.Message)
}

func (c *Codec) EncodeChangeDefaultAdminDelayMethodCall(in ChangeDefaultAdminDelayInput) ([]byte, error) {
	return c.abi.Pack("changeDefaultAdminDelay", in.NewDelay)
}

func (c *Codec) EncodeDefaultAdminMethodCall() ([]byte, error) {
	return c.abi.Pack("defaultAdmin")
}

func (c *Codec) DecodeDefaultAdminMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["defaultAdmin"].Outputs.Unpack(data)
	if err != nil {
		return *new(common.Address), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(common.Address), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result common.Address
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(common.Address), fmt.Errorf("failed to unmarshal to common.Address: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeDefaultAdminDelayMethodCall() ([]byte, error) {
	return c.abi.Pack("defaultAdminDelay")
}

func (c *Codec) DecodeDefaultAdminDelayMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["defaultAdminDelay"].Outputs.Unpack(data)
	if err != nil {
		return *new(*big.Int), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(*big.Int), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result *big.Int
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(*big.Int), fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeDefaultAdminDelayIncreaseWaitMethodCall() ([]byte, error) {
	return c.abi.Pack("defaultAdminDelayIncreaseWait")
}

func (c *Codec) DecodeDefaultAdminDelayIncreaseWaitMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["defaultAdminDelayIncreaseWait"].Outputs.Unpack(data)
	if err != nil {
		return *new(*big.Int), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(*big.Int), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result *big.Int
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(*big.Int), fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeEmergencyDrainMethodCall(in EmergencyDrainInput) ([]byte, error) {
	return c.abi.Pack("emergencyDrain", in.RevertOnFailure)
}

func (c *Codec) EncodeExecuteEpochWithdrawMethodCall(in ExecuteEpochWithdrawInput) ([]byte, error) {
	return c.abi.Pack("executeEpochWithdraw", in.EpochNonce, in.Amount)
}

func (c *Codec) EncodeExecuteRebalanceMethodCall(in ExecuteRebalanceInput) ([]byte, error) {
	return c.abi.Pack("executeRebalance", in.RebalanceNonce, in.NewStrategy)
}

func (c *Codec) EncodeGetActiveProtocolAdapterMethodCall() ([]byte, error) {
	return c.abi.Pack("getActiveProtocolAdapter")
}

func (c *Codec) DecodeGetActiveProtocolAdapterMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getActiveProtocolAdapter"].Outputs.Unpack(data)
	if err != nil {
		return *new(common.Address), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(common.Address), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result common.Address
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(common.Address), fmt.Errorf("failed to unmarshal to common.Address: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetAdapterRegistryMethodCall() ([]byte, error) {
	return c.abi.Pack("getAdapterRegistry")
}

func (c *Codec) DecodeGetAdapterRegistryMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getAdapterRegistry"].Outputs.Unpack(data)
	if err != nil {
		return *new(common.Address), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(common.Address), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result common.Address
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(common.Address), fmt.Errorf("failed to unmarshal to common.Address: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetCCVsAndFinalityConfigMethodCall(in GetCCVsAndFinalityConfigInput) ([]byte, error) {
	return c.abi.Pack("getCCVsAndFinalityConfig", in.Arg0, in.Arg1)
}

func (c *Codec) DecodeGetCCVsAndFinalityConfigMethodOutput(data []byte) (GetCCVsAndFinalityConfigOutput, error) {
	vals, err := c.abi.Methods["getCCVsAndFinalityConfig"].Outputs.Unpack(data)
	if err != nil {
		return GetCCVsAndFinalityConfigOutput{}, err
	}
	if len(vals) != 4 {
		return GetCCVsAndFinalityConfigOutput{}, fmt.Errorf("expected 4 values, got %d", len(vals))
	}
	jsonData0, err := json.Marshal(vals[0])
	if err != nil {
		return GetCCVsAndFinalityConfigOutput{}, fmt.Errorf("failed to marshal ABI result 0: %w", err)
	}

	var result0 []common.Address
	if err := json.Unmarshal(jsonData0, &result0); err != nil {
		return GetCCVsAndFinalityConfigOutput{}, fmt.Errorf("failed to unmarshal to []common.Address: %w", err)
	}
	jsonData1, err := json.Marshal(vals[1])
	if err != nil {
		return GetCCVsAndFinalityConfigOutput{}, fmt.Errorf("failed to marshal ABI result 1: %w", err)
	}

	var result1 []common.Address
	if err := json.Unmarshal(jsonData1, &result1); err != nil {
		return GetCCVsAndFinalityConfigOutput{}, fmt.Errorf("failed to unmarshal to []common.Address: %w", err)
	}
	jsonData2, err := json.Marshal(vals[2])
	if err != nil {
		return GetCCVsAndFinalityConfigOutput{}, fmt.Errorf("failed to marshal ABI result 2: %w", err)
	}

	var result2 uint8
	if err := json.Unmarshal(jsonData2, &result2); err != nil {
		return GetCCVsAndFinalityConfigOutput{}, fmt.Errorf("failed to unmarshal to uint8: %w", err)
	}
	jsonData3, err := json.Marshal(vals[3])
	if err != nil {
		return GetCCVsAndFinalityConfigOutput{}, fmt.Errorf("failed to marshal ABI result 3: %w", err)
	}

	var result3 [4]byte
	if err := json.Unmarshal(jsonData3, &result3); err != nil {
		return GetCCVsAndFinalityConfigOutput{}, fmt.Errorf("failed to unmarshal to [4]byte: %w", err)
	}

	return GetCCVsAndFinalityConfigOutput{
		RequiredCCVs:          result0,
		OptionalCCVs:          result1,
		OptionalThreshold:     result2,
		AllowedFinalityConfig: result3,
	}, nil
}

func (c *Codec) EncodeGetCcipGasLimitMethodCall(in GetCcipGasLimitInput) ([]byte, error) {
	return c.abi.Pack("getCcipGasLimit", in.ChainSelector)
}

func (c *Codec) DecodeGetCcipGasLimitMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getCcipGasLimit"].Outputs.Unpack(data)
	if err != nil {
		return *new(*big.Int), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(*big.Int), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result *big.Int
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(*big.Int), fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetCrosschainVaultMethodCall(in GetCrosschainVaultInput) ([]byte, error) {
	return c.abi.Pack("getCrosschainVault", in.ChainSelector)
}

func (c *Codec) DecodeGetCrosschainVaultMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getCrosschainVault"].Outputs.Unpack(data)
	if err != nil {
		return *new(common.Address), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(common.Address), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result common.Address
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(common.Address), fmt.Errorf("failed to unmarshal to common.Address: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetDefaultCcipGasLimitMethodCall() ([]byte, error) {
	return c.abi.Pack("getDefaultCcipGasLimit")
}

func (c *Codec) DecodeGetDefaultCcipGasLimitMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getDefaultCcipGasLimit"].Outputs.Unpack(data)
	if err != nil {
		return *new(*big.Int), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(*big.Int), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result *big.Int
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(*big.Int), fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetEpochDepositRecoveryMethodCall(in GetEpochDepositRecoveryInput) ([]byte, error) {
	return c.abi.Pack("getEpochDepositRecovery", in.EpochNonce)
}

func (c *Codec) DecodeGetEpochDepositRecoveryMethodOutput(data []byte) (TypesAmountRecovery, error) {
	vals, err := c.abi.Methods["getEpochDepositRecovery"].Outputs.Unpack(data)
	if err != nil {
		return *new(TypesAmountRecovery), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(TypesAmountRecovery), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result TypesAmountRecovery
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(TypesAmountRecovery), fmt.Errorf("failed to unmarshal to TypesAmountRecovery: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetEpochWithdrawRecoveryMethodCall(in GetEpochWithdrawRecoveryInput) ([]byte, error) {
	return c.abi.Pack("getEpochWithdrawRecovery", in.EpochNonce)
}

func (c *Codec) DecodeGetEpochWithdrawRecoveryMethodOutput(data []byte) (TypesAmountRecovery, error) {
	vals, err := c.abi.Methods["getEpochWithdrawRecovery"].Outputs.Unpack(data)
	if err != nil {
		return *new(TypesAmountRecovery), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(TypesAmountRecovery), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result TypesAmountRecovery
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(TypesAmountRecovery), fmt.Errorf("failed to unmarshal to TypesAmountRecovery: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetLinkMethodCall() ([]byte, error) {
	return c.abi.Pack("getLink")
}

func (c *Codec) DecodeGetLinkMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getLink"].Outputs.Unpack(data)
	if err != nil {
		return *new(common.Address), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(common.Address), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result common.Address
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(common.Address), fmt.Errorf("failed to unmarshal to common.Address: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetParentChainSelectorMethodCall() ([]byte, error) {
	return c.abi.Pack("getParentChainSelector")
}

func (c *Codec) DecodeGetParentChainSelectorMethodOutput(data []byte) (uint64, error) {
	vals, err := c.abi.Methods["getParentChainSelector"].Outputs.Unpack(data)
	if err != nil {
		return *new(uint64), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(uint64), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result uint64
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(uint64), fmt.Errorf("failed to unmarshal to uint64: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetPausedAtMethodCall() ([]byte, error) {
	return c.abi.Pack("getPausedAt")
}

func (c *Codec) DecodeGetPausedAtMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getPausedAt"].Outputs.Unpack(data)
	if err != nil {
		return *new(*big.Int), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(*big.Int), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result *big.Int
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(*big.Int), fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetRebalanceDepositRecoveryMethodCall(in GetRebalanceDepositRecoveryInput) ([]byte, error) {
	return c.abi.Pack("getRebalanceDepositRecovery", in.RebalanceNonce)
}

func (c *Codec) DecodeGetRebalanceDepositRecoveryMethodOutput(data []byte) (TypesAmountRecovery, error) {
	vals, err := c.abi.Methods["getRebalanceDepositRecovery"].Outputs.Unpack(data)
	if err != nil {
		return *new(TypesAmountRecovery), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(TypesAmountRecovery), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result TypesAmountRecovery
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(TypesAmountRecovery), fmt.Errorf("failed to unmarshal to TypesAmountRecovery: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetRebalanceWithdrawRecoveryMethodCall(in GetRebalanceWithdrawRecoveryInput) ([]byte, error) {
	return c.abi.Pack("getRebalanceWithdrawRecovery", in.RebalanceNonce)
}

func (c *Codec) DecodeGetRebalanceWithdrawRecoveryMethodOutput(data []byte) (TypesRebalanceWithdrawRecovery, error) {
	vals, err := c.abi.Methods["getRebalanceWithdrawRecovery"].Outputs.Unpack(data)
	if err != nil {
		return *new(TypesRebalanceWithdrawRecovery), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(TypesRebalanceWithdrawRecovery), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result TypesRebalanceWithdrawRecovery
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(TypesRebalanceWithdrawRecovery), fmt.Errorf("failed to unmarshal to TypesRebalanceWithdrawRecovery: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetRoleAdminMethodCall(in GetRoleAdminInput) ([]byte, error) {
	return c.abi.Pack("getRoleAdmin", in.Role)
}

func (c *Codec) DecodeGetRoleAdminMethodOutput(data []byte) ([32]byte, error) {
	vals, err := c.abi.Methods["getRoleAdmin"].Outputs.Unpack(data)
	if err != nil {
		return *new([32]byte), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new([32]byte), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result [32]byte
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new([32]byte), fmt.Errorf("failed to unmarshal to [32]byte: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetRouterMethodCall() ([]byte, error) {
	return c.abi.Pack("getRouter")
}

func (c *Codec) DecodeGetRouterMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getRouter"].Outputs.Unpack(data)
	if err != nil {
		return *new(common.Address), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(common.Address), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result common.Address
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(common.Address), fmt.Errorf("failed to unmarshal to common.Address: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetTVLMethodCall() ([]byte, error) {
	return c.abi.Pack("getTVL")
}

func (c *Codec) DecodeGetTVLMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getTVL"].Outputs.Unpack(data)
	if err != nil {
		return *new(*big.Int), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(*big.Int), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result *big.Int
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(*big.Int), fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetThisChainSelectorMethodCall() ([]byte, error) {
	return c.abi.Pack("getThisChainSelector")
}

func (c *Codec) DecodeGetThisChainSelectorMethodOutput(data []byte) (uint64, error) {
	vals, err := c.abi.Methods["getThisChainSelector"].Outputs.Unpack(data)
	if err != nil {
		return *new(uint64), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(uint64), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result uint64
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(uint64), fmt.Errorf("failed to unmarshal to uint64: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetUsdcMethodCall() ([]byte, error) {
	return c.abi.Pack("getUsdc")
}

func (c *Codec) DecodeGetUsdcMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getUsdc"].Outputs.Unpack(data)
	if err != nil {
		return *new(common.Address), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(common.Address), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result common.Address
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(common.Address), fmt.Errorf("failed to unmarshal to common.Address: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGrantRoleMethodCall(in GrantRoleInput) ([]byte, error) {
	return c.abi.Pack("grantRole", in.Role, in.Account)
}

func (c *Codec) EncodeHasRoleMethodCall(in HasRoleInput) ([]byte, error) {
	return c.abi.Pack("hasRole", in.Role, in.Account)
}

func (c *Codec) DecodeHasRoleMethodOutput(data []byte) (bool, error) {
	vals, err := c.abi.Methods["hasRole"].Outputs.Unpack(data)
	if err != nil {
		return *new(bool), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(bool), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result bool
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(bool), fmt.Errorf("failed to unmarshal to bool: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeOwnerMethodCall() ([]byte, error) {
	return c.abi.Pack("owner")
}

func (c *Codec) DecodeOwnerMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["owner"].Outputs.Unpack(data)
	if err != nil {
		return *new(common.Address), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(common.Address), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result common.Address
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(common.Address), fmt.Errorf("failed to unmarshal to common.Address: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodePauseMethodCall() ([]byte, error) {
	return c.abi.Pack("pause")
}

func (c *Codec) EncodePausedMethodCall() ([]byte, error) {
	return c.abi.Pack("paused")
}

func (c *Codec) DecodePausedMethodOutput(data []byte) (bool, error) {
	vals, err := c.abi.Methods["paused"].Outputs.Unpack(data)
	if err != nil {
		return *new(bool), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(bool), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result bool
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(bool), fmt.Errorf("failed to unmarshal to bool: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodePendingDefaultAdminMethodCall() ([]byte, error) {
	return c.abi.Pack("pendingDefaultAdmin")
}

func (c *Codec) DecodePendingDefaultAdminMethodOutput(data []byte) (PendingDefaultAdminOutput, error) {
	vals, err := c.abi.Methods["pendingDefaultAdmin"].Outputs.Unpack(data)
	if err != nil {
		return PendingDefaultAdminOutput{}, err
	}
	if len(vals) != 2 {
		return PendingDefaultAdminOutput{}, fmt.Errorf("expected 2 values, got %d", len(vals))
	}
	jsonData0, err := json.Marshal(vals[0])
	if err != nil {
		return PendingDefaultAdminOutput{}, fmt.Errorf("failed to marshal ABI result 0: %w", err)
	}

	var result0 common.Address
	if err := json.Unmarshal(jsonData0, &result0); err != nil {
		return PendingDefaultAdminOutput{}, fmt.Errorf("failed to unmarshal to common.Address: %w", err)
	}
	jsonData1, err := json.Marshal(vals[1])
	if err != nil {
		return PendingDefaultAdminOutput{}, fmt.Errorf("failed to marshal ABI result 1: %w", err)
	}

	var result1 *big.Int
	if err := json.Unmarshal(jsonData1, &result1); err != nil {
		return PendingDefaultAdminOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}

	return PendingDefaultAdminOutput{
		NewAdmin: result0,
		Schedule: result1,
	}, nil
}

func (c *Codec) EncodePendingDefaultAdminDelayMethodCall() ([]byte, error) {
	return c.abi.Pack("pendingDefaultAdminDelay")
}

func (c *Codec) DecodePendingDefaultAdminDelayMethodOutput(data []byte) (PendingDefaultAdminDelayOutput, error) {
	vals, err := c.abi.Methods["pendingDefaultAdminDelay"].Outputs.Unpack(data)
	if err != nil {
		return PendingDefaultAdminDelayOutput{}, err
	}
	if len(vals) != 2 {
		return PendingDefaultAdminDelayOutput{}, fmt.Errorf("expected 2 values, got %d", len(vals))
	}
	jsonData0, err := json.Marshal(vals[0])
	if err != nil {
		return PendingDefaultAdminDelayOutput{}, fmt.Errorf("failed to marshal ABI result 0: %w", err)
	}

	var result0 *big.Int
	if err := json.Unmarshal(jsonData0, &result0); err != nil {
		return PendingDefaultAdminDelayOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData1, err := json.Marshal(vals[1])
	if err != nil {
		return PendingDefaultAdminDelayOutput{}, fmt.Errorf("failed to marshal ABI result 1: %w", err)
	}

	var result1 *big.Int
	if err := json.Unmarshal(jsonData1, &result1); err != nil {
		return PendingDefaultAdminDelayOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}

	return PendingDefaultAdminDelayOutput{
		NewDelay: result0,
		Schedule: result1,
	}, nil
}

func (c *Codec) EncodeRecoverFailedEpochDepositMethodCall(in RecoverFailedEpochDepositInput) ([]byte, error) {
	return c.abi.Pack("recoverFailedEpochDeposit", in.EpochNonce)
}

func (c *Codec) EncodeRecoverFailedEpochWithdrawMethodCall(in RecoverFailedEpochWithdrawInput) ([]byte, error) {
	return c.abi.Pack("recoverFailedEpochWithdraw", in.EpochNonce)
}

func (c *Codec) EncodeRecoverFailedRebalanceDepositMethodCall(in RecoverFailedRebalanceDepositInput) ([]byte, error) {
	return c.abi.Pack("recoverFailedRebalanceDeposit", in.RebalanceNonce)
}

func (c *Codec) EncodeRecoverFailedRebalanceWithdrawMethodCall(in RecoverFailedRebalanceWithdrawInput) ([]byte, error) {
	return c.abi.Pack("recoverFailedRebalanceWithdraw", in.RebalanceNonce)
}

func (c *Codec) EncodeRenounceRoleMethodCall(in RenounceRoleInput) ([]byte, error) {
	return c.abi.Pack("renounceRole", in.Role, in.Account)
}

func (c *Codec) EncodeRevokeRoleMethodCall(in RevokeRoleInput) ([]byte, error) {
	return c.abi.Pack("revokeRole", in.Role, in.Account)
}

func (c *Codec) EncodeRollbackDefaultAdminDelayMethodCall() ([]byte, error) {
	return c.abi.Pack("rollbackDefaultAdminDelay")
}

func (c *Codec) EncodeSetCcipGasLimitMethodCall(in SetCcipGasLimitInput) ([]byte, error) {
	return c.abi.Pack("setCcipGasLimit", in.ChainSelector, in.GasLimit)
}

func (c *Codec) EncodeSetCrosschainVaultsMethodCall(in SetCrosschainVaultsInput) ([]byte, error) {
	return c.abi.Pack("setCrosschainVaults", in.ChainSelectors, in.Vaults)
}

func (c *Codec) EncodeSetDefaultCcipGasLimitMethodCall(in SetDefaultCcipGasLimitInput) ([]byte, error) {
	return c.abi.Pack("setDefaultCcipGasLimit", in.GasLimit)
}

func (c *Codec) EncodeSupportsInterfaceMethodCall(in SupportsInterfaceInput) ([]byte, error) {
	return c.abi.Pack("supportsInterface", in.InterfaceId)
}

func (c *Codec) DecodeSupportsInterfaceMethodOutput(data []byte) (bool, error) {
	vals, err := c.abi.Methods["supportsInterface"].Outputs.Unpack(data)
	if err != nil {
		return *new(bool), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(bool), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result bool
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(bool), fmt.Errorf("failed to unmarshal to bool: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeTryDepositToAdapterMethodCall(in TryDepositToAdapterInput) ([]byte, error) {
	return c.abi.Pack("tryDepositToAdapter", in.Adapter, in.Amount)
}

func (c *Codec) EncodeUnpauseMethodCall() ([]byte, error) {
	return c.abi.Pack("unpause")
}

func (c *Codec) EncodeWithdrawLinkMethodCall(in WithdrawLinkInput) ([]byte, error) {
	return c.abi.Pack("withdrawLink", in.Amount)
}

func (c *Codec) EncodeBaseVaultConstructorParamsStruct(in BaseVaultConstructorParams) ([]byte, error) {
	tupleType, err := abi.NewType(
		"tuple", "",
		[]abi.ArgumentMarshaling{
			{Name: "link", Type: "address"},
			{Name: "usdc", Type: "address"},
			{Name: "ccipRouter", Type: "address"},
			{Name: "defaultAdmin", Type: "address"},
			{Name: "pauser", Type: "address"},
			{Name: "unpauser", Type: "address"},
			{Name: "configOperator", Type: "address"},
			{Name: "adapterRegistry", Type: "address"},
			{Name: "thisChainSelector", Type: "uint64"},
		},
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create tuple type for BaseVaultConstructorParams: %w", err)
	}
	args := abi.Arguments{
		{Name: "baseVaultConstructorParams", Type: tupleType},
	}

	return args.Pack(in)
}
func (c *Codec) EncodeClientAny2EVMMessageStruct(in ClientAny2EVMMessage) ([]byte, error) {
	tupleType, err := abi.NewType(
		"tuple", "",
		[]abi.ArgumentMarshaling{
			{Name: "messageId", Type: "bytes32"},
			{Name: "sourceChainSelector", Type: "uint64"},
			{Name: "sender", Type: "bytes"},
			{Name: "data", Type: "bytes"},
			{Name: "destTokenAmounts", Type: "(address,uint256)[]"},
		},
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create tuple type for ClientAny2EVMMessage: %w", err)
	}
	args := abi.Arguments{
		{Name: "clientAny2EVMMessage", Type: tupleType},
	}

	return args.Pack(in)
}
func (c *Codec) EncodeClientEVMTokenAmountStruct(in ClientEVMTokenAmount) ([]byte, error) {
	tupleType, err := abi.NewType(
		"tuple", "",
		[]abi.ArgumentMarshaling{
			{Name: "token", Type: "address"},
			{Name: "amount", Type: "uint256"},
		},
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create tuple type for ClientEVMTokenAmount: %w", err)
	}
	args := abi.Arguments{
		{Name: "clientEVMTokenAmount", Type: tupleType},
	}

	return args.Pack(in)
}
func (c *Codec) EncodeTypesAmountRecoveryStruct(in TypesAmountRecovery) ([]byte, error) {
	tupleType, err := abi.NewType(
		"tuple", "",
		[]abi.ArgumentMarshaling{
			{Name: "amount", Type: "uint256"},
			{Name: "createdAt", Type: "uint256"},
		},
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create tuple type for TypesAmountRecovery: %w", err)
	}
	args := abi.Arguments{
		{Name: "typesAmountRecovery", Type: tupleType},
	}

	return args.Pack(in)
}
func (c *Codec) EncodeTypesRebalanceWithdrawRecoveryStruct(in TypesRebalanceWithdrawRecovery) ([]byte, error) {
	tupleType, err := abi.NewType(
		"tuple", "",
		[]abi.ArgumentMarshaling{
			{Name: "strategy", Type: "(bytes32,uint64)"},
			{Name: "createdAt", Type: "uint256"},
		},
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create tuple type for TypesRebalanceWithdrawRecovery: %w", err)
	}
	args := abi.Arguments{
		{Name: "typesRebalanceWithdrawRecovery", Type: tupleType},
	}

	return args.Pack(in)
}
func (c *Codec) EncodeTypesStrategyStruct(in TypesStrategy) ([]byte, error) {
	tupleType, err := abi.NewType(
		"tuple", "",
		[]abi.ArgumentMarshaling{
			{Name: "protocolId", Type: "bytes32"},
			{Name: "chainSelector", Type: "uint64"},
		},
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create tuple type for TypesStrategy: %w", err)
	}
	args := abi.Arguments{
		{Name: "typesStrategy", Type: tupleType},
	}

	return args.Pack(in)
}

func (c *Codec) CcipGasLimitSetLogHash() []byte {
	return c.abi.Events["CcipGasLimitSet"].ID.Bytes()
}

func (c *Codec) EncodeCcipGasLimitSetTopics(
	evt abi.Event,
	values []CcipGasLimitSetTopics,
) ([]*evm.TopicValues, error) {
	var chainSelectorRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ChainSelector).IsZero() {
			chainSelectorRule = append(chainSelectorRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.ChainSelector)
		if err != nil {
			return nil, err
		}
		chainSelectorRule = append(chainSelectorRule, fieldVal)
	}
	var gasLimitRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.GasLimit).IsZero() {
			gasLimitRule = append(gasLimitRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.GasLimit)
		if err != nil {
			return nil, err
		}
		gasLimitRule = append(gasLimitRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		chainSelectorRule,
		gasLimitRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeCcipGasLimitSet decodes a log into a CcipGasLimitSet struct.
func (c *Codec) DecodeCcipGasLimitSet(log *evm.Log) (*CcipGasLimitSetDecoded, error) {
	event := new(CcipGasLimitSetDecoded)
	if err := c.abi.UnpackIntoInterface(event, "CcipGasLimitSet", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["CcipGasLimitSet"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) CrosschainVaultSetLogHash() []byte {
	return c.abi.Events["CrosschainVaultSet"].ID.Bytes()
}

func (c *Codec) EncodeCrosschainVaultSetTopics(
	evt abi.Event,
	values []CrosschainVaultSetTopics,
) ([]*evm.TopicValues, error) {
	var chainSelectorRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ChainSelector).IsZero() {
			chainSelectorRule = append(chainSelectorRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.ChainSelector)
		if err != nil {
			return nil, err
		}
		chainSelectorRule = append(chainSelectorRule, fieldVal)
	}
	var vaultRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Vault).IsZero() {
			vaultRule = append(vaultRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Vault)
		if err != nil {
			return nil, err
		}
		vaultRule = append(vaultRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		chainSelectorRule,
		vaultRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeCrosschainVaultSet decodes a log into a CrosschainVaultSet struct.
func (c *Codec) DecodeCrosschainVaultSet(log *evm.Log) (*CrosschainVaultSetDecoded, error) {
	event := new(CrosschainVaultSetDecoded)
	if err := c.abi.UnpackIntoInterface(event, "CrosschainVaultSet", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["CrosschainVaultSet"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) DefaultAdminDelayChangeCanceledLogHash() []byte {
	return c.abi.Events["DefaultAdminDelayChangeCanceled"].ID.Bytes()
}

func (c *Codec) EncodeDefaultAdminDelayChangeCanceledTopics(
	evt abi.Event,
	values []DefaultAdminDelayChangeCanceledTopics,
) ([]*evm.TopicValues, error) {

	rawTopics, err := abi.MakeTopics()
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeDefaultAdminDelayChangeCanceled decodes a log into a DefaultAdminDelayChangeCanceled struct.
func (c *Codec) DecodeDefaultAdminDelayChangeCanceled(log *evm.Log) (*DefaultAdminDelayChangeCanceledDecoded, error) {
	event := new(DefaultAdminDelayChangeCanceledDecoded)
	if err := c.abi.UnpackIntoInterface(event, "DefaultAdminDelayChangeCanceled", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["DefaultAdminDelayChangeCanceled"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) DefaultAdminDelayChangeScheduledLogHash() []byte {
	return c.abi.Events["DefaultAdminDelayChangeScheduled"].ID.Bytes()
}

func (c *Codec) EncodeDefaultAdminDelayChangeScheduledTopics(
	evt abi.Event,
	values []DefaultAdminDelayChangeScheduledTopics,
) ([]*evm.TopicValues, error) {

	rawTopics, err := abi.MakeTopics()
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeDefaultAdminDelayChangeScheduled decodes a log into a DefaultAdminDelayChangeScheduled struct.
func (c *Codec) DecodeDefaultAdminDelayChangeScheduled(log *evm.Log) (*DefaultAdminDelayChangeScheduledDecoded, error) {
	event := new(DefaultAdminDelayChangeScheduledDecoded)
	if err := c.abi.UnpackIntoInterface(event, "DefaultAdminDelayChangeScheduled", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["DefaultAdminDelayChangeScheduled"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) DefaultAdminTransferCanceledLogHash() []byte {
	return c.abi.Events["DefaultAdminTransferCanceled"].ID.Bytes()
}

func (c *Codec) EncodeDefaultAdminTransferCanceledTopics(
	evt abi.Event,
	values []DefaultAdminTransferCanceledTopics,
) ([]*evm.TopicValues, error) {

	rawTopics, err := abi.MakeTopics()
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeDefaultAdminTransferCanceled decodes a log into a DefaultAdminTransferCanceled struct.
func (c *Codec) DecodeDefaultAdminTransferCanceled(log *evm.Log) (*DefaultAdminTransferCanceledDecoded, error) {
	event := new(DefaultAdminTransferCanceledDecoded)
	if err := c.abi.UnpackIntoInterface(event, "DefaultAdminTransferCanceled", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["DefaultAdminTransferCanceled"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) DefaultAdminTransferScheduledLogHash() []byte {
	return c.abi.Events["DefaultAdminTransferScheduled"].ID.Bytes()
}

func (c *Codec) EncodeDefaultAdminTransferScheduledTopics(
	evt abi.Event,
	values []DefaultAdminTransferScheduledTopics,
) ([]*evm.TopicValues, error) {
	var newAdminRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.NewAdmin).IsZero() {
			newAdminRule = append(newAdminRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.NewAdmin)
		if err != nil {
			return nil, err
		}
		newAdminRule = append(newAdminRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		newAdminRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeDefaultAdminTransferScheduled decodes a log into a DefaultAdminTransferScheduled struct.
func (c *Codec) DecodeDefaultAdminTransferScheduled(log *evm.Log) (*DefaultAdminTransferScheduledDecoded, error) {
	event := new(DefaultAdminTransferScheduledDecoded)
	if err := c.abi.UnpackIntoInterface(event, "DefaultAdminTransferScheduled", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["DefaultAdminTransferScheduled"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) DefaultCcipGasLimitSetLogHash() []byte {
	return c.abi.Events["DefaultCcipGasLimitSet"].ID.Bytes()
}

func (c *Codec) EncodeDefaultCcipGasLimitSetTopics(
	evt abi.Event,
	values []DefaultCcipGasLimitSetTopics,
) ([]*evm.TopicValues, error) {
	var gasLimitRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.GasLimit).IsZero() {
			gasLimitRule = append(gasLimitRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.GasLimit)
		if err != nil {
			return nil, err
		}
		gasLimitRule = append(gasLimitRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		gasLimitRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeDefaultCcipGasLimitSet decodes a log into a DefaultCcipGasLimitSet struct.
func (c *Codec) DecodeDefaultCcipGasLimitSet(log *evm.Log) (*DefaultCcipGasLimitSetDecoded, error) {
	event := new(DefaultCcipGasLimitSetDecoded)
	if err := c.abi.UnpackIntoInterface(event, "DefaultCcipGasLimitSet", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["DefaultCcipGasLimitSet"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) DepositToStrategyFailureLogHash() []byte {
	return c.abi.Events["DepositToStrategyFailure"].ID.Bytes()
}

func (c *Codec) EncodeDepositToStrategyFailureTopics(
	evt abi.Event,
	values []DepositToStrategyFailureTopics,
) ([]*evm.TopicValues, error) {
	var epochNonceRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.EpochNonce).IsZero() {
			epochNonceRule = append(epochNonceRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.EpochNonce)
		if err != nil {
			return nil, err
		}
		epochNonceRule = append(epochNonceRule, fieldVal)
	}
	var amountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Amount).IsZero() {
			amountRule = append(amountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Amount)
		if err != nil {
			return nil, err
		}
		amountRule = append(amountRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		epochNonceRule,
		amountRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeDepositToStrategyFailure decodes a log into a DepositToStrategyFailure struct.
func (c *Codec) DecodeDepositToStrategyFailure(log *evm.Log) (*DepositToStrategyFailureDecoded, error) {
	event := new(DepositToStrategyFailureDecoded)
	if err := c.abi.UnpackIntoInterface(event, "DepositToStrategyFailure", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["DepositToStrategyFailure"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) DepositToStrategySuccessLogHash() []byte {
	return c.abi.Events["DepositToStrategySuccess"].ID.Bytes()
}

func (c *Codec) EncodeDepositToStrategySuccessTopics(
	evt abi.Event,
	values []DepositToStrategySuccessTopics,
) ([]*evm.TopicValues, error) {
	var epochNonceRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.EpochNonce).IsZero() {
			epochNonceRule = append(epochNonceRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.EpochNonce)
		if err != nil {
			return nil, err
		}
		epochNonceRule = append(epochNonceRule, fieldVal)
	}
	var amountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Amount).IsZero() {
			amountRule = append(amountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Amount)
		if err != nil {
			return nil, err
		}
		amountRule = append(amountRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		epochNonceRule,
		amountRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeDepositToStrategySuccess decodes a log into a DepositToStrategySuccess struct.
func (c *Codec) DecodeDepositToStrategySuccess(log *evm.Log) (*DepositToStrategySuccessDecoded, error) {
	event := new(DepositToStrategySuccessDecoded)
	if err := c.abi.UnpackIntoInterface(event, "DepositToStrategySuccess", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["DepositToStrategySuccess"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) EmergencyDrainExecutedLogHash() []byte {
	return c.abi.Events["EmergencyDrainExecuted"].ID.Bytes()
}

func (c *Codec) EncodeEmergencyDrainExecutedTopics(
	evt abi.Event,
	values []EmergencyDrainExecutedTopics,
) ([]*evm.TopicValues, error) {
	var drainerRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Drainer).IsZero() {
			drainerRule = append(drainerRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.Drainer)
		if err != nil {
			return nil, err
		}
		drainerRule = append(drainerRule, fieldVal)
	}
	var amountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Amount).IsZero() {
			amountRule = append(amountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Amount)
		if err != nil {
			return nil, err
		}
		amountRule = append(amountRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		drainerRule,
		amountRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeEmergencyDrainExecuted decodes a log into a EmergencyDrainExecuted struct.
func (c *Codec) DecodeEmergencyDrainExecuted(log *evm.Log) (*EmergencyDrainExecutedDecoded, error) {
	event := new(EmergencyDrainExecutedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "EmergencyDrainExecuted", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["EmergencyDrainExecuted"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) EpochDepositRecoveryClearedLogHash() []byte {
	return c.abi.Events["EpochDepositRecoveryCleared"].ID.Bytes()
}

func (c *Codec) EncodeEpochDepositRecoveryClearedTopics(
	evt abi.Event,
	values []EpochDepositRecoveryClearedTopics,
) ([]*evm.TopicValues, error) {
	var epochNonceRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.EpochNonce).IsZero() {
			epochNonceRule = append(epochNonceRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.EpochNonce)
		if err != nil {
			return nil, err
		}
		epochNonceRule = append(epochNonceRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		epochNonceRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeEpochDepositRecoveryCleared decodes a log into a EpochDepositRecoveryCleared struct.
func (c *Codec) DecodeEpochDepositRecoveryCleared(log *evm.Log) (*EpochDepositRecoveryClearedDecoded, error) {
	event := new(EpochDepositRecoveryClearedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "EpochDepositRecoveryCleared", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["EpochDepositRecoveryCleared"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) EpochDepositRecoveryStoredLogHash() []byte {
	return c.abi.Events["EpochDepositRecoveryStored"].ID.Bytes()
}

func (c *Codec) EncodeEpochDepositRecoveryStoredTopics(
	evt abi.Event,
	values []EpochDepositRecoveryStoredTopics,
) ([]*evm.TopicValues, error) {
	var epochNonceRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.EpochNonce).IsZero() {
			epochNonceRule = append(epochNonceRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.EpochNonce)
		if err != nil {
			return nil, err
		}
		epochNonceRule = append(epochNonceRule, fieldVal)
	}
	var amountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Amount).IsZero() {
			amountRule = append(amountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Amount)
		if err != nil {
			return nil, err
		}
		amountRule = append(amountRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		epochNonceRule,
		amountRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeEpochDepositRecoveryStored decodes a log into a EpochDepositRecoveryStored struct.
func (c *Codec) DecodeEpochDepositRecoveryStored(log *evm.Log) (*EpochDepositRecoveryStoredDecoded, error) {
	event := new(EpochDepositRecoveryStoredDecoded)
	if err := c.abi.UnpackIntoInterface(event, "EpochDepositRecoveryStored", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["EpochDepositRecoveryStored"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) EpochWithdrawRecoveryClearedLogHash() []byte {
	return c.abi.Events["EpochWithdrawRecoveryCleared"].ID.Bytes()
}

func (c *Codec) EncodeEpochWithdrawRecoveryClearedTopics(
	evt abi.Event,
	values []EpochWithdrawRecoveryClearedTopics,
) ([]*evm.TopicValues, error) {
	var epochNonceRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.EpochNonce).IsZero() {
			epochNonceRule = append(epochNonceRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.EpochNonce)
		if err != nil {
			return nil, err
		}
		epochNonceRule = append(epochNonceRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		epochNonceRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeEpochWithdrawRecoveryCleared decodes a log into a EpochWithdrawRecoveryCleared struct.
func (c *Codec) DecodeEpochWithdrawRecoveryCleared(log *evm.Log) (*EpochWithdrawRecoveryClearedDecoded, error) {
	event := new(EpochWithdrawRecoveryClearedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "EpochWithdrawRecoveryCleared", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["EpochWithdrawRecoveryCleared"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) EpochWithdrawRecoveryStoredLogHash() []byte {
	return c.abi.Events["EpochWithdrawRecoveryStored"].ID.Bytes()
}

func (c *Codec) EncodeEpochWithdrawRecoveryStoredTopics(
	evt abi.Event,
	values []EpochWithdrawRecoveryStoredTopics,
) ([]*evm.TopicValues, error) {
	var epochNonceRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.EpochNonce).IsZero() {
			epochNonceRule = append(epochNonceRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.EpochNonce)
		if err != nil {
			return nil, err
		}
		epochNonceRule = append(epochNonceRule, fieldVal)
	}
	var amountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Amount).IsZero() {
			amountRule = append(amountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Amount)
		if err != nil {
			return nil, err
		}
		amountRule = append(amountRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		epochNonceRule,
		amountRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeEpochWithdrawRecoveryStored decodes a log into a EpochWithdrawRecoveryStored struct.
func (c *Codec) DecodeEpochWithdrawRecoveryStored(log *evm.Log) (*EpochWithdrawRecoveryStoredDecoded, error) {
	event := new(EpochWithdrawRecoveryStoredDecoded)
	if err := c.abi.UnpackIntoInterface(event, "EpochWithdrawRecoveryStored", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["EpochWithdrawRecoveryStored"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) LinkWithdrawnLogHash() []byte {
	return c.abi.Events["LinkWithdrawn"].ID.Bytes()
}

func (c *Codec) EncodeLinkWithdrawnTopics(
	evt abi.Event,
	values []LinkWithdrawnTopics,
) ([]*evm.TopicValues, error) {
	var operatorRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Operator).IsZero() {
			operatorRule = append(operatorRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.Operator)
		if err != nil {
			return nil, err
		}
		operatorRule = append(operatorRule, fieldVal)
	}
	var amountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Amount).IsZero() {
			amountRule = append(amountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Amount)
		if err != nil {
			return nil, err
		}
		amountRule = append(amountRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		operatorRule,
		amountRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeLinkWithdrawn decodes a log into a LinkWithdrawn struct.
func (c *Codec) DecodeLinkWithdrawn(log *evm.Log) (*LinkWithdrawnDecoded, error) {
	event := new(LinkWithdrawnDecoded)
	if err := c.abi.UnpackIntoInterface(event, "LinkWithdrawn", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["LinkWithdrawn"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) PausedLogHash() []byte {
	return c.abi.Events["Paused"].ID.Bytes()
}

func (c *Codec) EncodePausedTopics(
	evt abi.Event,
	values []PausedTopics,
) ([]*evm.TopicValues, error) {

	rawTopics, err := abi.MakeTopics()
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodePaused decodes a log into a Paused struct.
func (c *Codec) DecodePaused(log *evm.Log) (*PausedDecoded, error) {
	event := new(PausedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "Paused", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["Paused"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) RebalanceDepositFailureLogHash() []byte {
	return c.abi.Events["RebalanceDepositFailure"].ID.Bytes()
}

func (c *Codec) EncodeRebalanceDepositFailureTopics(
	evt abi.Event,
	values []RebalanceDepositFailureTopics,
) ([]*evm.TopicValues, error) {
	var rebalanceNonceRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.RebalanceNonce).IsZero() {
			rebalanceNonceRule = append(rebalanceNonceRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.RebalanceNonce)
		if err != nil {
			return nil, err
		}
		rebalanceNonceRule = append(rebalanceNonceRule, fieldVal)
	}
	var amountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Amount).IsZero() {
			amountRule = append(amountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Amount)
		if err != nil {
			return nil, err
		}
		amountRule = append(amountRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		rebalanceNonceRule,
		amountRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeRebalanceDepositFailure decodes a log into a RebalanceDepositFailure struct.
func (c *Codec) DecodeRebalanceDepositFailure(log *evm.Log) (*RebalanceDepositFailureDecoded, error) {
	event := new(RebalanceDepositFailureDecoded)
	if err := c.abi.UnpackIntoInterface(event, "RebalanceDepositFailure", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["RebalanceDepositFailure"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) RebalanceDepositRecoveryClearedLogHash() []byte {
	return c.abi.Events["RebalanceDepositRecoveryCleared"].ID.Bytes()
}

func (c *Codec) EncodeRebalanceDepositRecoveryClearedTopics(
	evt abi.Event,
	values []RebalanceDepositRecoveryClearedTopics,
) ([]*evm.TopicValues, error) {
	var rebalanceNonceRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.RebalanceNonce).IsZero() {
			rebalanceNonceRule = append(rebalanceNonceRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.RebalanceNonce)
		if err != nil {
			return nil, err
		}
		rebalanceNonceRule = append(rebalanceNonceRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		rebalanceNonceRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeRebalanceDepositRecoveryCleared decodes a log into a RebalanceDepositRecoveryCleared struct.
func (c *Codec) DecodeRebalanceDepositRecoveryCleared(log *evm.Log) (*RebalanceDepositRecoveryClearedDecoded, error) {
	event := new(RebalanceDepositRecoveryClearedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "RebalanceDepositRecoveryCleared", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["RebalanceDepositRecoveryCleared"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) RebalanceDepositRecoveryStoredLogHash() []byte {
	return c.abi.Events["RebalanceDepositRecoveryStored"].ID.Bytes()
}

func (c *Codec) EncodeRebalanceDepositRecoveryStoredTopics(
	evt abi.Event,
	values []RebalanceDepositRecoveryStoredTopics,
) ([]*evm.TopicValues, error) {
	var rebalanceNonceRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.RebalanceNonce).IsZero() {
			rebalanceNonceRule = append(rebalanceNonceRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.RebalanceNonce)
		if err != nil {
			return nil, err
		}
		rebalanceNonceRule = append(rebalanceNonceRule, fieldVal)
	}
	var amountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Amount).IsZero() {
			amountRule = append(amountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Amount)
		if err != nil {
			return nil, err
		}
		amountRule = append(amountRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		rebalanceNonceRule,
		amountRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeRebalanceDepositRecoveryStored decodes a log into a RebalanceDepositRecoveryStored struct.
func (c *Codec) DecodeRebalanceDepositRecoveryStored(log *evm.Log) (*RebalanceDepositRecoveryStoredDecoded, error) {
	event := new(RebalanceDepositRecoveryStoredDecoded)
	if err := c.abi.UnpackIntoInterface(event, "RebalanceDepositRecoveryStored", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["RebalanceDepositRecoveryStored"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) RebalanceDepositSuccessLogHash() []byte {
	return c.abi.Events["RebalanceDepositSuccess"].ID.Bytes()
}

func (c *Codec) EncodeRebalanceDepositSuccessTopics(
	evt abi.Event,
	values []RebalanceDepositSuccessTopics,
) ([]*evm.TopicValues, error) {
	var rebalanceNonceRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.RebalanceNonce).IsZero() {
			rebalanceNonceRule = append(rebalanceNonceRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.RebalanceNonce)
		if err != nil {
			return nil, err
		}
		rebalanceNonceRule = append(rebalanceNonceRule, fieldVal)
	}
	var amountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Amount).IsZero() {
			amountRule = append(amountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Amount)
		if err != nil {
			return nil, err
		}
		amountRule = append(amountRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		rebalanceNonceRule,
		amountRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeRebalanceDepositSuccess decodes a log into a RebalanceDepositSuccess struct.
func (c *Codec) DecodeRebalanceDepositSuccess(log *evm.Log) (*RebalanceDepositSuccessDecoded, error) {
	event := new(RebalanceDepositSuccessDecoded)
	if err := c.abi.UnpackIntoInterface(event, "RebalanceDepositSuccess", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["RebalanceDepositSuccess"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) RebalanceWithdrawFailureLogHash() []byte {
	return c.abi.Events["RebalanceWithdrawFailure"].ID.Bytes()
}

func (c *Codec) EncodeRebalanceWithdrawFailureTopics(
	evt abi.Event,
	values []RebalanceWithdrawFailureTopics,
) ([]*evm.TopicValues, error) {
	var rebalanceNonceRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.RebalanceNonce).IsZero() {
			rebalanceNonceRule = append(rebalanceNonceRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.RebalanceNonce)
		if err != nil {
			return nil, err
		}
		rebalanceNonceRule = append(rebalanceNonceRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		rebalanceNonceRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeRebalanceWithdrawFailure decodes a log into a RebalanceWithdrawFailure struct.
func (c *Codec) DecodeRebalanceWithdrawFailure(log *evm.Log) (*RebalanceWithdrawFailureDecoded, error) {
	event := new(RebalanceWithdrawFailureDecoded)
	if err := c.abi.UnpackIntoInterface(event, "RebalanceWithdrawFailure", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["RebalanceWithdrawFailure"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) RebalanceWithdrawRecoveryClearedLogHash() []byte {
	return c.abi.Events["RebalanceWithdrawRecoveryCleared"].ID.Bytes()
}

func (c *Codec) EncodeRebalanceWithdrawRecoveryClearedTopics(
	evt abi.Event,
	values []RebalanceWithdrawRecoveryClearedTopics,
) ([]*evm.TopicValues, error) {
	var rebalanceNonceRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.RebalanceNonce).IsZero() {
			rebalanceNonceRule = append(rebalanceNonceRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.RebalanceNonce)
		if err != nil {
			return nil, err
		}
		rebalanceNonceRule = append(rebalanceNonceRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		rebalanceNonceRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeRebalanceWithdrawRecoveryCleared decodes a log into a RebalanceWithdrawRecoveryCleared struct.
func (c *Codec) DecodeRebalanceWithdrawRecoveryCleared(log *evm.Log) (*RebalanceWithdrawRecoveryClearedDecoded, error) {
	event := new(RebalanceWithdrawRecoveryClearedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "RebalanceWithdrawRecoveryCleared", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["RebalanceWithdrawRecoveryCleared"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) RebalanceWithdrawRecoveryStoredLogHash() []byte {
	return c.abi.Events["RebalanceWithdrawRecoveryStored"].ID.Bytes()
}

func (c *Codec) EncodeRebalanceWithdrawRecoveryStoredTopics(
	evt abi.Event,
	values []RebalanceWithdrawRecoveryStoredTopics,
) ([]*evm.TopicValues, error) {
	var rebalanceNonceRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.RebalanceNonce).IsZero() {
			rebalanceNonceRule = append(rebalanceNonceRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.RebalanceNonce)
		if err != nil {
			return nil, err
		}
		rebalanceNonceRule = append(rebalanceNonceRule, fieldVal)
	}
	var protocolIdRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ProtocolId).IsZero() {
			protocolIdRule = append(protocolIdRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.ProtocolId)
		if err != nil {
			return nil, err
		}
		protocolIdRule = append(protocolIdRule, fieldVal)
	}
	var chainSelectorRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ChainSelector).IsZero() {
			chainSelectorRule = append(chainSelectorRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.ChainSelector)
		if err != nil {
			return nil, err
		}
		chainSelectorRule = append(chainSelectorRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		rebalanceNonceRule,
		protocolIdRule,
		chainSelectorRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeRebalanceWithdrawRecoveryStored decodes a log into a RebalanceWithdrawRecoveryStored struct.
func (c *Codec) DecodeRebalanceWithdrawRecoveryStored(log *evm.Log) (*RebalanceWithdrawRecoveryStoredDecoded, error) {
	event := new(RebalanceWithdrawRecoveryStoredDecoded)
	if err := c.abi.UnpackIntoInterface(event, "RebalanceWithdrawRecoveryStored", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["RebalanceWithdrawRecoveryStored"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) RebalanceWithdrawSuccessLogHash() []byte {
	return c.abi.Events["RebalanceWithdrawSuccess"].ID.Bytes()
}

func (c *Codec) EncodeRebalanceWithdrawSuccessTopics(
	evt abi.Event,
	values []RebalanceWithdrawSuccessTopics,
) ([]*evm.TopicValues, error) {
	var rebalanceNonceRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.RebalanceNonce).IsZero() {
			rebalanceNonceRule = append(rebalanceNonceRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.RebalanceNonce)
		if err != nil {
			return nil, err
		}
		rebalanceNonceRule = append(rebalanceNonceRule, fieldVal)
	}
	var amountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Amount).IsZero() {
			amountRule = append(amountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Amount)
		if err != nil {
			return nil, err
		}
		amountRule = append(amountRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		rebalanceNonceRule,
		amountRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeRebalanceWithdrawSuccess decodes a log into a RebalanceWithdrawSuccess struct.
func (c *Codec) DecodeRebalanceWithdrawSuccess(log *evm.Log) (*RebalanceWithdrawSuccessDecoded, error) {
	event := new(RebalanceWithdrawSuccessDecoded)
	if err := c.abi.UnpackIntoInterface(event, "RebalanceWithdrawSuccess", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["RebalanceWithdrawSuccess"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) RoleAdminChangedLogHash() []byte {
	return c.abi.Events["RoleAdminChanged"].ID.Bytes()
}

func (c *Codec) EncodeRoleAdminChangedTopics(
	evt abi.Event,
	values []RoleAdminChangedTopics,
) ([]*evm.TopicValues, error) {
	var roleRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Role).IsZero() {
			roleRule = append(roleRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.Role)
		if err != nil {
			return nil, err
		}
		roleRule = append(roleRule, fieldVal)
	}
	var previousAdminRoleRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.PreviousAdminRole).IsZero() {
			previousAdminRoleRule = append(previousAdminRoleRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.PreviousAdminRole)
		if err != nil {
			return nil, err
		}
		previousAdminRoleRule = append(previousAdminRoleRule, fieldVal)
	}
	var newAdminRoleRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.NewAdminRole).IsZero() {
			newAdminRoleRule = append(newAdminRoleRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.NewAdminRole)
		if err != nil {
			return nil, err
		}
		newAdminRoleRule = append(newAdminRoleRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		roleRule,
		previousAdminRoleRule,
		newAdminRoleRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeRoleAdminChanged decodes a log into a RoleAdminChanged struct.
func (c *Codec) DecodeRoleAdminChanged(log *evm.Log) (*RoleAdminChangedDecoded, error) {
	event := new(RoleAdminChangedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "RoleAdminChanged", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["RoleAdminChanged"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) RoleGrantedLogHash() []byte {
	return c.abi.Events["RoleGranted"].ID.Bytes()
}

func (c *Codec) EncodeRoleGrantedTopics(
	evt abi.Event,
	values []RoleGrantedTopics,
) ([]*evm.TopicValues, error) {
	var roleRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Role).IsZero() {
			roleRule = append(roleRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.Role)
		if err != nil {
			return nil, err
		}
		roleRule = append(roleRule, fieldVal)
	}
	var accountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Account).IsZero() {
			accountRule = append(accountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Account)
		if err != nil {
			return nil, err
		}
		accountRule = append(accountRule, fieldVal)
	}
	var senderRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Sender).IsZero() {
			senderRule = append(senderRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.Sender)
		if err != nil {
			return nil, err
		}
		senderRule = append(senderRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		roleRule,
		accountRule,
		senderRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeRoleGranted decodes a log into a RoleGranted struct.
func (c *Codec) DecodeRoleGranted(log *evm.Log) (*RoleGrantedDecoded, error) {
	event := new(RoleGrantedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "RoleGranted", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["RoleGranted"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) RoleRevokedLogHash() []byte {
	return c.abi.Events["RoleRevoked"].ID.Bytes()
}

func (c *Codec) EncodeRoleRevokedTopics(
	evt abi.Event,
	values []RoleRevokedTopics,
) ([]*evm.TopicValues, error) {
	var roleRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Role).IsZero() {
			roleRule = append(roleRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.Role)
		if err != nil {
			return nil, err
		}
		roleRule = append(roleRule, fieldVal)
	}
	var accountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Account).IsZero() {
			accountRule = append(accountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Account)
		if err != nil {
			return nil, err
		}
		accountRule = append(accountRule, fieldVal)
	}
	var senderRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Sender).IsZero() {
			senderRule = append(senderRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.Sender)
		if err != nil {
			return nil, err
		}
		senderRule = append(senderRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		roleRule,
		accountRule,
		senderRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeRoleRevoked decodes a log into a RoleRevoked struct.
func (c *Codec) DecodeRoleRevoked(log *evm.Log) (*RoleRevokedDecoded, error) {
	event := new(RoleRevokedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "RoleRevoked", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["RoleRevoked"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) USDCBridgedLogHash() []byte {
	return c.abi.Events["USDCBridged"].ID.Bytes()
}

func (c *Codec) EncodeUSDCBridgedTopics(
	evt abi.Event,
	values []USDCBridgedTopics,
) ([]*evm.TopicValues, error) {
	var ccipMessageIdRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.CcipMessageId).IsZero() {
			ccipMessageIdRule = append(ccipMessageIdRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.CcipMessageId)
		if err != nil {
			return nil, err
		}
		ccipMessageIdRule = append(ccipMessageIdRule, fieldVal)
	}
	var amountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Amount).IsZero() {
			amountRule = append(amountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Amount)
		if err != nil {
			return nil, err
		}
		amountRule = append(amountRule, fieldVal)
	}
	var ccipTxTypeRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.CcipTxType).IsZero() {
			ccipTxTypeRule = append(ccipTxTypeRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.CcipTxType)
		if err != nil {
			return nil, err
		}
		ccipTxTypeRule = append(ccipTxTypeRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		ccipMessageIdRule,
		amountRule,
		ccipTxTypeRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeUSDCBridged decodes a log into a USDCBridged struct.
func (c *Codec) DecodeUSDCBridged(log *evm.Log) (*USDCBridgedDecoded, error) {
	event := new(USDCBridgedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "USDCBridged", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["USDCBridged"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) UnpausedLogHash() []byte {
	return c.abi.Events["Unpaused"].ID.Bytes()
}

func (c *Codec) EncodeUnpausedTopics(
	evt abi.Event,
	values []UnpausedTopics,
) ([]*evm.TopicValues, error) {

	rawTopics, err := abi.MakeTopics()
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeUnpaused decodes a log into a Unpaused struct.
func (c *Codec) DecodeUnpaused(log *evm.Log) (*UnpausedDecoded, error) {
	event := new(UnpausedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "Unpaused", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["Unpaused"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) WithdrawFromStrategyFailureLogHash() []byte {
	return c.abi.Events["WithdrawFromStrategyFailure"].ID.Bytes()
}

func (c *Codec) EncodeWithdrawFromStrategyFailureTopics(
	evt abi.Event,
	values []WithdrawFromStrategyFailureTopics,
) ([]*evm.TopicValues, error) {
	var epochNonceRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.EpochNonce).IsZero() {
			epochNonceRule = append(epochNonceRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.EpochNonce)
		if err != nil {
			return nil, err
		}
		epochNonceRule = append(epochNonceRule, fieldVal)
	}
	var amountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Amount).IsZero() {
			amountRule = append(amountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Amount)
		if err != nil {
			return nil, err
		}
		amountRule = append(amountRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		epochNonceRule,
		amountRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeWithdrawFromStrategyFailure decodes a log into a WithdrawFromStrategyFailure struct.
func (c *Codec) DecodeWithdrawFromStrategyFailure(log *evm.Log) (*WithdrawFromStrategyFailureDecoded, error) {
	event := new(WithdrawFromStrategyFailureDecoded)
	if err := c.abi.UnpackIntoInterface(event, "WithdrawFromStrategyFailure", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["WithdrawFromStrategyFailure"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) WithdrawFromStrategySuccessLogHash() []byte {
	return c.abi.Events["WithdrawFromStrategySuccess"].ID.Bytes()
}

func (c *Codec) EncodeWithdrawFromStrategySuccessTopics(
	evt abi.Event,
	values []WithdrawFromStrategySuccessTopics,
) ([]*evm.TopicValues, error) {
	var epochNonceRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.EpochNonce).IsZero() {
			epochNonceRule = append(epochNonceRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.EpochNonce)
		if err != nil {
			return nil, err
		}
		epochNonceRule = append(epochNonceRule, fieldVal)
	}
	var amountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Amount).IsZero() {
			amountRule = append(amountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Amount)
		if err != nil {
			return nil, err
		}
		amountRule = append(amountRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		epochNonceRule,
		amountRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeWithdrawFromStrategySuccess decodes a log into a WithdrawFromStrategySuccess struct.
func (c *Codec) DecodeWithdrawFromStrategySuccess(log *evm.Log) (*WithdrawFromStrategySuccessDecoded, error) {
	event := new(WithdrawFromStrategySuccessDecoded)
	if err := c.abi.UnpackIntoInterface(event, "WithdrawFromStrategySuccess", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["WithdrawFromStrategySuccess"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c ChildVault) DEFAULTADMINROLE(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[[32]byte] {
	calldata, err := c.Codec.EncodeDEFAULTADMINROLEMethodCall()
	if err != nil {
		return cre.PromiseFromResult[[32]byte](*new([32]byte), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) ([32]byte, error) {
		return c.Codec.DecodeDEFAULTADMINROLEMethodOutput(response.Data)
	})

}

func (c ChildVault) DefaultAdmin(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeDefaultAdminMethodCall()
	if err != nil {
		return cre.PromiseFromResult[common.Address](*new(common.Address), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (common.Address, error) {
		return c.Codec.DecodeDefaultAdminMethodOutput(response.Data)
	})

}

func (c ChildVault) DefaultAdminDelay(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeDefaultAdminDelayMethodCall()
	if err != nil {
		return cre.PromiseFromResult[*big.Int](*new(*big.Int), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (*big.Int, error) {
		return c.Codec.DecodeDefaultAdminDelayMethodOutput(response.Data)
	})

}

func (c ChildVault) DefaultAdminDelayIncreaseWait(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeDefaultAdminDelayIncreaseWaitMethodCall()
	if err != nil {
		return cre.PromiseFromResult[*big.Int](*new(*big.Int), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (*big.Int, error) {
		return c.Codec.DecodeDefaultAdminDelayIncreaseWaitMethodOutput(response.Data)
	})

}

func (c ChildVault) GetActiveProtocolAdapter(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetActiveProtocolAdapterMethodCall()
	if err != nil {
		return cre.PromiseFromResult[common.Address](*new(common.Address), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (common.Address, error) {
		return c.Codec.DecodeGetActiveProtocolAdapterMethodOutput(response.Data)
	})

}

func (c ChildVault) GetAdapterRegistry(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetAdapterRegistryMethodCall()
	if err != nil {
		return cre.PromiseFromResult[common.Address](*new(common.Address), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (common.Address, error) {
		return c.Codec.DecodeGetAdapterRegistryMethodOutput(response.Data)
	})

}

func (c ChildVault) GetCCVsAndFinalityConfig(
	runtime cre.Runtime,
	args GetCCVsAndFinalityConfigInput,
	blockNumber *big.Int,
) cre.Promise[GetCCVsAndFinalityConfigOutput] {
	calldata, err := c.Codec.EncodeGetCCVsAndFinalityConfigMethodCall(args)
	if err != nil {
		return cre.PromiseFromResult[GetCCVsAndFinalityConfigOutput](GetCCVsAndFinalityConfigOutput{}, err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (GetCCVsAndFinalityConfigOutput, error) {
		return c.Codec.DecodeGetCCVsAndFinalityConfigMethodOutput(response.Data)
	})

}

func (c ChildVault) GetCcipGasLimit(
	runtime cre.Runtime,
	args GetCcipGasLimitInput,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeGetCcipGasLimitMethodCall(args)
	if err != nil {
		return cre.PromiseFromResult[*big.Int](*new(*big.Int), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (*big.Int, error) {
		return c.Codec.DecodeGetCcipGasLimitMethodOutput(response.Data)
	})

}

func (c ChildVault) GetCrosschainVault(
	runtime cre.Runtime,
	args GetCrosschainVaultInput,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetCrosschainVaultMethodCall(args)
	if err != nil {
		return cre.PromiseFromResult[common.Address](*new(common.Address), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (common.Address, error) {
		return c.Codec.DecodeGetCrosschainVaultMethodOutput(response.Data)
	})

}

func (c ChildVault) GetDefaultCcipGasLimit(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeGetDefaultCcipGasLimitMethodCall()
	if err != nil {
		return cre.PromiseFromResult[*big.Int](*new(*big.Int), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (*big.Int, error) {
		return c.Codec.DecodeGetDefaultCcipGasLimitMethodOutput(response.Data)
	})

}

func (c ChildVault) GetEpochDepositRecovery(
	runtime cre.Runtime,
	args GetEpochDepositRecoveryInput,
	blockNumber *big.Int,
) cre.Promise[TypesAmountRecovery] {
	calldata, err := c.Codec.EncodeGetEpochDepositRecoveryMethodCall(args)
	if err != nil {
		return cre.PromiseFromResult[TypesAmountRecovery](*new(TypesAmountRecovery), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (TypesAmountRecovery, error) {
		return c.Codec.DecodeGetEpochDepositRecoveryMethodOutput(response.Data)
	})

}

func (c ChildVault) GetEpochWithdrawRecovery(
	runtime cre.Runtime,
	args GetEpochWithdrawRecoveryInput,
	blockNumber *big.Int,
) cre.Promise[TypesAmountRecovery] {
	calldata, err := c.Codec.EncodeGetEpochWithdrawRecoveryMethodCall(args)
	if err != nil {
		return cre.PromiseFromResult[TypesAmountRecovery](*new(TypesAmountRecovery), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (TypesAmountRecovery, error) {
		return c.Codec.DecodeGetEpochWithdrawRecoveryMethodOutput(response.Data)
	})

}

func (c ChildVault) GetLink(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetLinkMethodCall()
	if err != nil {
		return cre.PromiseFromResult[common.Address](*new(common.Address), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (common.Address, error) {
		return c.Codec.DecodeGetLinkMethodOutput(response.Data)
	})

}

func (c ChildVault) GetParentChainSelector(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[uint64] {
	calldata, err := c.Codec.EncodeGetParentChainSelectorMethodCall()
	if err != nil {
		return cre.PromiseFromResult[uint64](*new(uint64), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (uint64, error) {
		return c.Codec.DecodeGetParentChainSelectorMethodOutput(response.Data)
	})

}

func (c ChildVault) GetPausedAt(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeGetPausedAtMethodCall()
	if err != nil {
		return cre.PromiseFromResult[*big.Int](*new(*big.Int), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (*big.Int, error) {
		return c.Codec.DecodeGetPausedAtMethodOutput(response.Data)
	})

}

func (c ChildVault) GetRebalanceDepositRecovery(
	runtime cre.Runtime,
	args GetRebalanceDepositRecoveryInput,
	blockNumber *big.Int,
) cre.Promise[TypesAmountRecovery] {
	calldata, err := c.Codec.EncodeGetRebalanceDepositRecoveryMethodCall(args)
	if err != nil {
		return cre.PromiseFromResult[TypesAmountRecovery](*new(TypesAmountRecovery), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (TypesAmountRecovery, error) {
		return c.Codec.DecodeGetRebalanceDepositRecoveryMethodOutput(response.Data)
	})

}

func (c ChildVault) GetRebalanceWithdrawRecovery(
	runtime cre.Runtime,
	args GetRebalanceWithdrawRecoveryInput,
	blockNumber *big.Int,
) cre.Promise[TypesRebalanceWithdrawRecovery] {
	calldata, err := c.Codec.EncodeGetRebalanceWithdrawRecoveryMethodCall(args)
	if err != nil {
		return cre.PromiseFromResult[TypesRebalanceWithdrawRecovery](*new(TypesRebalanceWithdrawRecovery), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (TypesRebalanceWithdrawRecovery, error) {
		return c.Codec.DecodeGetRebalanceWithdrawRecoveryMethodOutput(response.Data)
	})

}

func (c ChildVault) GetRoleAdmin(
	runtime cre.Runtime,
	args GetRoleAdminInput,
	blockNumber *big.Int,
) cre.Promise[[32]byte] {
	calldata, err := c.Codec.EncodeGetRoleAdminMethodCall(args)
	if err != nil {
		return cre.PromiseFromResult[[32]byte](*new([32]byte), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) ([32]byte, error) {
		return c.Codec.DecodeGetRoleAdminMethodOutput(response.Data)
	})

}

func (c ChildVault) GetRouter(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetRouterMethodCall()
	if err != nil {
		return cre.PromiseFromResult[common.Address](*new(common.Address), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (common.Address, error) {
		return c.Codec.DecodeGetRouterMethodOutput(response.Data)
	})

}

func (c ChildVault) GetTVL(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeGetTVLMethodCall()
	if err != nil {
		return cre.PromiseFromResult[*big.Int](*new(*big.Int), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (*big.Int, error) {
		return c.Codec.DecodeGetTVLMethodOutput(response.Data)
	})

}

func (c ChildVault) GetThisChainSelector(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[uint64] {
	calldata, err := c.Codec.EncodeGetThisChainSelectorMethodCall()
	if err != nil {
		return cre.PromiseFromResult[uint64](*new(uint64), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (uint64, error) {
		return c.Codec.DecodeGetThisChainSelectorMethodOutput(response.Data)
	})

}

func (c ChildVault) GetUsdc(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetUsdcMethodCall()
	if err != nil {
		return cre.PromiseFromResult[common.Address](*new(common.Address), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (common.Address, error) {
		return c.Codec.DecodeGetUsdcMethodOutput(response.Data)
	})

}

func (c ChildVault) HasRole(
	runtime cre.Runtime,
	args HasRoleInput,
	blockNumber *big.Int,
) cre.Promise[bool] {
	calldata, err := c.Codec.EncodeHasRoleMethodCall(args)
	if err != nil {
		return cre.PromiseFromResult[bool](*new(bool), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (bool, error) {
		return c.Codec.DecodeHasRoleMethodOutput(response.Data)
	})

}

func (c ChildVault) Owner(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeOwnerMethodCall()
	if err != nil {
		return cre.PromiseFromResult[common.Address](*new(common.Address), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (common.Address, error) {
		return c.Codec.DecodeOwnerMethodOutput(response.Data)
	})

}

func (c ChildVault) Paused(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[bool] {
	calldata, err := c.Codec.EncodePausedMethodCall()
	if err != nil {
		return cre.PromiseFromResult[bool](*new(bool), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (bool, error) {
		return c.Codec.DecodePausedMethodOutput(response.Data)
	})

}

func (c ChildVault) PendingDefaultAdmin(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[PendingDefaultAdminOutput] {
	calldata, err := c.Codec.EncodePendingDefaultAdminMethodCall()
	if err != nil {
		return cre.PromiseFromResult[PendingDefaultAdminOutput](PendingDefaultAdminOutput{}, err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (PendingDefaultAdminOutput, error) {
		return c.Codec.DecodePendingDefaultAdminMethodOutput(response.Data)
	})

}

func (c ChildVault) PendingDefaultAdminDelay(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[PendingDefaultAdminDelayOutput] {
	calldata, err := c.Codec.EncodePendingDefaultAdminDelayMethodCall()
	if err != nil {
		return cre.PromiseFromResult[PendingDefaultAdminDelayOutput](PendingDefaultAdminDelayOutput{}, err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (PendingDefaultAdminDelayOutput, error) {
		return c.Codec.DecodePendingDefaultAdminDelayMethodOutput(response.Data)
	})

}

func (c ChildVault) WriteReportFromBaseVaultConstructorParams(
	runtime cre.Runtime,
	input BaseVaultConstructorParams,
	gasConfig *evm.GasConfig,
) cre.Promise[*evm.WriteReportReply] {
	encoded, err := c.Codec.EncodeBaseVaultConstructorParamsStruct(input)
	if err != nil {
		return cre.PromiseFromResult[*evm.WriteReportReply](nil, err)
	}
	promise := runtime.GenerateReport(&pb2.ReportRequest{
		EncodedPayload: encoded,
		EncoderName:    "evm",
		SigningAlgo:    "ecdsa",
		HashingAlgo:    "keccak256",
	})

	return cre.ThenPromise(promise, func(report *cre.Report) cre.Promise[*evm.WriteReportReply] {
		return c.client.WriteReport(runtime, &evm.WriteCreReportRequest{
			Receiver:  c.Address.Bytes(),
			Report:    report,
			GasConfig: gasConfig,
		})
	})
}

func (c ChildVault) WriteReportFromClientAny2EVMMessage(
	runtime cre.Runtime,
	input ClientAny2EVMMessage,
	gasConfig *evm.GasConfig,
) cre.Promise[*evm.WriteReportReply] {
	encoded, err := c.Codec.EncodeClientAny2EVMMessageStruct(input)
	if err != nil {
		return cre.PromiseFromResult[*evm.WriteReportReply](nil, err)
	}
	promise := runtime.GenerateReport(&pb2.ReportRequest{
		EncodedPayload: encoded,
		EncoderName:    "evm",
		SigningAlgo:    "ecdsa",
		HashingAlgo:    "keccak256",
	})

	return cre.ThenPromise(promise, func(report *cre.Report) cre.Promise[*evm.WriteReportReply] {
		return c.client.WriteReport(runtime, &evm.WriteCreReportRequest{
			Receiver:  c.Address.Bytes(),
			Report:    report,
			GasConfig: gasConfig,
		})
	})
}

func (c ChildVault) WriteReportFromClientEVMTokenAmount(
	runtime cre.Runtime,
	input ClientEVMTokenAmount,
	gasConfig *evm.GasConfig,
) cre.Promise[*evm.WriteReportReply] {
	encoded, err := c.Codec.EncodeClientEVMTokenAmountStruct(input)
	if err != nil {
		return cre.PromiseFromResult[*evm.WriteReportReply](nil, err)
	}
	promise := runtime.GenerateReport(&pb2.ReportRequest{
		EncodedPayload: encoded,
		EncoderName:    "evm",
		SigningAlgo:    "ecdsa",
		HashingAlgo:    "keccak256",
	})

	return cre.ThenPromise(promise, func(report *cre.Report) cre.Promise[*evm.WriteReportReply] {
		return c.client.WriteReport(runtime, &evm.WriteCreReportRequest{
			Receiver:  c.Address.Bytes(),
			Report:    report,
			GasConfig: gasConfig,
		})
	})
}

func (c ChildVault) WriteReportFromTypesAmountRecovery(
	runtime cre.Runtime,
	input TypesAmountRecovery,
	gasConfig *evm.GasConfig,
) cre.Promise[*evm.WriteReportReply] {
	encoded, err := c.Codec.EncodeTypesAmountRecoveryStruct(input)
	if err != nil {
		return cre.PromiseFromResult[*evm.WriteReportReply](nil, err)
	}
	promise := runtime.GenerateReport(&pb2.ReportRequest{
		EncodedPayload: encoded,
		EncoderName:    "evm",
		SigningAlgo:    "ecdsa",
		HashingAlgo:    "keccak256",
	})

	return cre.ThenPromise(promise, func(report *cre.Report) cre.Promise[*evm.WriteReportReply] {
		return c.client.WriteReport(runtime, &evm.WriteCreReportRequest{
			Receiver:  c.Address.Bytes(),
			Report:    report,
			GasConfig: gasConfig,
		})
	})
}

func (c ChildVault) WriteReportFromTypesRebalanceWithdrawRecovery(
	runtime cre.Runtime,
	input TypesRebalanceWithdrawRecovery,
	gasConfig *evm.GasConfig,
) cre.Promise[*evm.WriteReportReply] {
	encoded, err := c.Codec.EncodeTypesRebalanceWithdrawRecoveryStruct(input)
	if err != nil {
		return cre.PromiseFromResult[*evm.WriteReportReply](nil, err)
	}
	promise := runtime.GenerateReport(&pb2.ReportRequest{
		EncodedPayload: encoded,
		EncoderName:    "evm",
		SigningAlgo:    "ecdsa",
		HashingAlgo:    "keccak256",
	})

	return cre.ThenPromise(promise, func(report *cre.Report) cre.Promise[*evm.WriteReportReply] {
		return c.client.WriteReport(runtime, &evm.WriteCreReportRequest{
			Receiver:  c.Address.Bytes(),
			Report:    report,
			GasConfig: gasConfig,
		})
	})
}

func (c ChildVault) WriteReportFromTypesStrategy(
	runtime cre.Runtime,
	input TypesStrategy,
	gasConfig *evm.GasConfig,
) cre.Promise[*evm.WriteReportReply] {
	encoded, err := c.Codec.EncodeTypesStrategyStruct(input)
	if err != nil {
		return cre.PromiseFromResult[*evm.WriteReportReply](nil, err)
	}
	promise := runtime.GenerateReport(&pb2.ReportRequest{
		EncodedPayload: encoded,
		EncoderName:    "evm",
		SigningAlgo:    "ecdsa",
		HashingAlgo:    "keccak256",
	})

	return cre.ThenPromise(promise, func(report *cre.Report) cre.Promise[*evm.WriteReportReply] {
		return c.client.WriteReport(runtime, &evm.WriteCreReportRequest{
			Receiver:  c.Address.Bytes(),
			Report:    report,
			GasConfig: gasConfig,
		})
	})
}

func (c ChildVault) WriteReport(
	runtime cre.Runtime,
	report *cre.Report,
	gasConfig *evm.GasConfig,
) cre.Promise[*evm.WriteReportReply] {
	return c.client.WriteReport(runtime, &evm.WriteCreReportRequest{
		Receiver:  c.Address.Bytes(),
		Report:    report,
		GasConfig: gasConfig,
	})
}

// DecodeAccessControlBadConfirmationError decodes a AccessControlBadConfirmation error from revert data.
func (c *ChildVault) DecodeAccessControlBadConfirmationError(data []byte) (*AccessControlBadConfirmation, error) {
	args := c.ABI.Errors["AccessControlBadConfirmation"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &AccessControlBadConfirmation{}, nil
}

// Error implements the error interface for AccessControlBadConfirmation.
func (e *AccessControlBadConfirmation) Error() string {
	return fmt.Sprintf("AccessControlBadConfirmation error:")
}

// DecodeAccessControlEnforcedDefaultAdminDelayError decodes a AccessControlEnforcedDefaultAdminDelay error from revert data.
func (c *ChildVault) DecodeAccessControlEnforcedDefaultAdminDelayError(data []byte) (*AccessControlEnforcedDefaultAdminDelay, error) {
	args := c.ABI.Errors["AccessControlEnforcedDefaultAdminDelay"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	schedule, ok0 := values[0].(*big.Int)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for schedule in AccessControlEnforcedDefaultAdminDelay error")
	}

	return &AccessControlEnforcedDefaultAdminDelay{
		Schedule: schedule,
	}, nil
}

// Error implements the error interface for AccessControlEnforcedDefaultAdminDelay.
func (e *AccessControlEnforcedDefaultAdminDelay) Error() string {
	return fmt.Sprintf("AccessControlEnforcedDefaultAdminDelay error: schedule=%v;", e.Schedule)
}

// DecodeAccessControlEnforcedDefaultAdminRulesError decodes a AccessControlEnforcedDefaultAdminRules error from revert data.
func (c *ChildVault) DecodeAccessControlEnforcedDefaultAdminRulesError(data []byte) (*AccessControlEnforcedDefaultAdminRules, error) {
	args := c.ABI.Errors["AccessControlEnforcedDefaultAdminRules"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &AccessControlEnforcedDefaultAdminRules{}, nil
}

// Error implements the error interface for AccessControlEnforcedDefaultAdminRules.
func (e *AccessControlEnforcedDefaultAdminRules) Error() string {
	return fmt.Sprintf("AccessControlEnforcedDefaultAdminRules error:")
}

// DecodeAccessControlInvalidDefaultAdminError decodes a AccessControlInvalidDefaultAdmin error from revert data.
func (c *ChildVault) DecodeAccessControlInvalidDefaultAdminError(data []byte) (*AccessControlInvalidDefaultAdmin, error) {
	args := c.ABI.Errors["AccessControlInvalidDefaultAdmin"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	defaultAdmin, ok0 := values[0].(common.Address)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for defaultAdmin in AccessControlInvalidDefaultAdmin error")
	}

	return &AccessControlInvalidDefaultAdmin{
		DefaultAdmin: defaultAdmin,
	}, nil
}

// Error implements the error interface for AccessControlInvalidDefaultAdmin.
func (e *AccessControlInvalidDefaultAdmin) Error() string {
	return fmt.Sprintf("AccessControlInvalidDefaultAdmin error: defaultAdmin=%v;", e.DefaultAdmin)
}

// DecodeAccessControlUnauthorizedAccountError decodes a AccessControlUnauthorizedAccount error from revert data.
func (c *ChildVault) DecodeAccessControlUnauthorizedAccountError(data []byte) (*AccessControlUnauthorizedAccount, error) {
	args := c.ABI.Errors["AccessControlUnauthorizedAccount"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 2 {
		return nil, fmt.Errorf("expected 2 values, got %d", len(values))
	}

	account, ok0 := values[0].(common.Address)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for account in AccessControlUnauthorizedAccount error")
	}

	neededRole, ok1 := values[1].([32]byte)
	if !ok1 {
		return nil, fmt.Errorf("unexpected type for neededRole in AccessControlUnauthorizedAccount error")
	}

	return &AccessControlUnauthorizedAccount{
		Account:    account,
		NeededRole: neededRole,
	}, nil
}

// Error implements the error interface for AccessControlUnauthorizedAccount.
func (e *AccessControlUnauthorizedAccount) Error() string {
	return fmt.Sprintf("AccessControlUnauthorizedAccount error: account=%v; neededRole=%v;", e.Account, e.NeededRole)
}

// DecodeBaseVaultDepositFailedError decodes a BaseVault__DepositFailed error from revert data.
func (c *ChildVault) DecodeBaseVaultDepositFailedError(data []byte) (*BaseVaultDepositFailed, error) {
	args := c.ABI.Errors["BaseVault__DepositFailed"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	amount, ok0 := values[0].(*big.Int)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for amount in BaseVaultDepositFailed error")
	}

	return &BaseVaultDepositFailed{
		Amount: amount,
	}, nil
}

// Error implements the error interface for BaseVaultDepositFailed.
func (e *BaseVaultDepositFailed) Error() string {
	return fmt.Sprintf("BaseVaultDepositFailed error: amount=%v;", e.Amount)
}

// DecodeBaseVaultEmergencyDrainDelayNotMetError decodes a BaseVault__EmergencyDrainDelayNotMet error from revert data.
func (c *ChildVault) DecodeBaseVaultEmergencyDrainDelayNotMetError(data []byte) (*BaseVaultEmergencyDrainDelayNotMet, error) {
	args := c.ABI.Errors["BaseVault__EmergencyDrainDelayNotMet"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &BaseVaultEmergencyDrainDelayNotMet{}, nil
}

// Error implements the error interface for BaseVaultEmergencyDrainDelayNotMet.
func (e *BaseVaultEmergencyDrainDelayNotMet) Error() string {
	return fmt.Sprintf("BaseVaultEmergencyDrainDelayNotMet error:")
}

// DecodeBaseVaultInvalidInputLengthsError decodes a BaseVault__InvalidInputLengths error from revert data.
func (c *ChildVault) DecodeBaseVaultInvalidInputLengthsError(data []byte) (*BaseVaultInvalidInputLengths, error) {
	args := c.ABI.Errors["BaseVault__InvalidInputLengths"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &BaseVaultInvalidInputLengths{}, nil
}

// Error implements the error interface for BaseVaultInvalidInputLengths.
func (e *BaseVaultInvalidInputLengths) Error() string {
	return fmt.Sprintf("BaseVaultInvalidInputLengths error:")
}

// DecodeBaseVaultInvalidSenderError decodes a BaseVault__InvalidSender error from revert data.
func (c *ChildVault) DecodeBaseVaultInvalidSenderError(data []byte) (*BaseVaultInvalidSender, error) {
	args := c.ABI.Errors["BaseVault__InvalidSender"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 2 {
		return nil, fmt.Errorf("expected 2 values, got %d", len(values))
	}

	sender, ok0 := values[0].(common.Address)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for sender in BaseVaultInvalidSender error")
	}

	srcChainSelector, ok1 := values[1].(uint64)
	if !ok1 {
		return nil, fmt.Errorf("unexpected type for srcChainSelector in BaseVaultInvalidSender error")
	}

	return &BaseVaultInvalidSender{
		Sender:           sender,
		SrcChainSelector: srcChainSelector,
	}, nil
}

// Error implements the error interface for BaseVaultInvalidSender.
func (e *BaseVaultInvalidSender) Error() string {
	return fmt.Sprintf("BaseVaultInvalidSender error: sender=%v; srcChainSelector=%v;", e.Sender, e.SrcChainSelector)
}

// DecodeBaseVaultNoActiveAdapterError decodes a BaseVault__NoActiveAdapter error from revert data.
func (c *ChildVault) DecodeBaseVaultNoActiveAdapterError(data []byte) (*BaseVaultNoActiveAdapter, error) {
	args := c.ABI.Errors["BaseVault__NoActiveAdapter"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &BaseVaultNoActiveAdapter{}, nil
}

// Error implements the error interface for BaseVaultNoActiveAdapter.
func (e *BaseVaultNoActiveAdapter) Error() string {
	return fmt.Sprintf("BaseVaultNoActiveAdapter error:")
}

// DecodeBaseVaultNoAdapterRegisteredError decodes a BaseVault__NoAdapterRegistered error from revert data.
func (c *ChildVault) DecodeBaseVaultNoAdapterRegisteredError(data []byte) (*BaseVaultNoAdapterRegistered, error) {
	args := c.ABI.Errors["BaseVault__NoAdapterRegistered"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	protocolId, ok0 := values[0].([32]byte)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for protocolId in BaseVaultNoAdapterRegistered error")
	}

	return &BaseVaultNoAdapterRegistered{
		ProtocolId: protocolId,
	}, nil
}

// Error implements the error interface for BaseVaultNoAdapterRegistered.
func (e *BaseVaultNoAdapterRegistered) Error() string {
	return fmt.Sprintf("BaseVaultNoAdapterRegistered error: protocolId=%v;", e.ProtocolId)
}

// DecodeBaseVaultNoPendingRecoveryError decodes a BaseVault__NoPendingRecovery error from revert data.
func (c *ChildVault) DecodeBaseVaultNoPendingRecoveryError(data []byte) (*BaseVaultNoPendingRecovery, error) {
	args := c.ABI.Errors["BaseVault__NoPendingRecovery"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &BaseVaultNoPendingRecovery{}, nil
}

// Error implements the error interface for BaseVaultNoPendingRecovery.
func (e *BaseVaultNoPendingRecovery) Error() string {
	return fmt.Sprintf("BaseVaultNoPendingRecovery error:")
}

// DecodeBaseVaultNoZeroAmountError decodes a BaseVault__NoZeroAmount error from revert data.
func (c *ChildVault) DecodeBaseVaultNoZeroAmountError(data []byte) (*BaseVaultNoZeroAmount, error) {
	args := c.ABI.Errors["BaseVault__NoZeroAmount"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &BaseVaultNoZeroAmount{}, nil
}

// Error implements the error interface for BaseVaultNoZeroAmount.
func (e *BaseVaultNoZeroAmount) Error() string {
	return fmt.Sprintf("BaseVaultNoZeroAmount error:")
}

// DecodeBaseVaultOnlySelfError decodes a BaseVault__OnlySelf error from revert data.
func (c *ChildVault) DecodeBaseVaultOnlySelfError(data []byte) (*BaseVaultOnlySelf, error) {
	args := c.ABI.Errors["BaseVault__OnlySelf"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &BaseVaultOnlySelf{}, nil
}

// Error implements the error interface for BaseVaultOnlySelf.
func (e *BaseVaultOnlySelf) Error() string {
	return fmt.Sprintf("BaseVaultOnlySelf error:")
}

// DecodeBaseVaultRecoveryAlreadyPendingError decodes a BaseVault__RecoveryAlreadyPending error from revert data.
func (c *ChildVault) DecodeBaseVaultRecoveryAlreadyPendingError(data []byte) (*BaseVaultRecoveryAlreadyPending, error) {
	args := c.ABI.Errors["BaseVault__RecoveryAlreadyPending"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &BaseVaultRecoveryAlreadyPending{}, nil
}

// Error implements the error interface for BaseVaultRecoveryAlreadyPending.
func (e *BaseVaultRecoveryAlreadyPending) Error() string {
	return fmt.Sprintf("BaseVaultRecoveryAlreadyPending error:")
}

// DecodeBaseVaultWithdrawFailedError decodes a BaseVault__WithdrawFailed error from revert data.
func (c *ChildVault) DecodeBaseVaultWithdrawFailedError(data []byte) (*BaseVaultWithdrawFailed, error) {
	args := c.ABI.Errors["BaseVault__WithdrawFailed"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	amount, ok0 := values[0].(*big.Int)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for amount in BaseVaultWithdrawFailed error")
	}

	return &BaseVaultWithdrawFailed{
		Amount: amount,
	}, nil
}

// Error implements the error interface for BaseVaultWithdrawFailed.
func (e *BaseVaultWithdrawFailed) Error() string {
	return fmt.Sprintf("BaseVaultWithdrawFailed error: amount=%v;", e.Amount)
}

// DecodeBaseVaultZeroRecoveryAmountError decodes a BaseVault__ZeroRecoveryAmount error from revert data.
func (c *ChildVault) DecodeBaseVaultZeroRecoveryAmountError(data []byte) (*BaseVaultZeroRecoveryAmount, error) {
	args := c.ABI.Errors["BaseVault__ZeroRecoveryAmount"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &BaseVaultZeroRecoveryAmount{}, nil
}

// Error implements the error interface for BaseVaultZeroRecoveryAmount.
func (e *BaseVaultZeroRecoveryAmount) Error() string {
	return fmt.Sprintf("BaseVaultZeroRecoveryAmount error:")
}

// DecodeChildVaultInvalidRecoveryStrategyError decodes a ChildVault__InvalidRecoveryStrategy error from revert data.
func (c *ChildVault) DecodeChildVaultInvalidRecoveryStrategyError(data []byte) (*ChildVaultInvalidRecoveryStrategy, error) {
	args := c.ABI.Errors["ChildVault__InvalidRecoveryStrategy"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &ChildVaultInvalidRecoveryStrategy{}, nil
}

// Error implements the error interface for ChildVaultInvalidRecoveryStrategy.
func (e *ChildVaultInvalidRecoveryStrategy) Error() string {
	return fmt.Sprintf("ChildVaultInvalidRecoveryStrategy error:")
}

// DecodeEnforcedPauseError decodes a EnforcedPause error from revert data.
func (c *ChildVault) DecodeEnforcedPauseError(data []byte) (*EnforcedPause, error) {
	args := c.ABI.Errors["EnforcedPause"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &EnforcedPause{}, nil
}

// Error implements the error interface for EnforcedPause.
func (e *EnforcedPause) Error() string {
	return fmt.Sprintf("EnforcedPause error:")
}

// DecodeExpectedPauseError decodes a ExpectedPause error from revert data.
func (c *ChildVault) DecodeExpectedPauseError(data []byte) (*ExpectedPause, error) {
	args := c.ABI.Errors["ExpectedPause"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &ExpectedPause{}, nil
}

// Error implements the error interface for ExpectedPause.
func (e *ExpectedPause) Error() string {
	return fmt.Sprintf("ExpectedPause error:")
}

// DecodeInvalidRouterError decodes a InvalidRouter error from revert data.
func (c *ChildVault) DecodeInvalidRouterError(data []byte) (*InvalidRouter, error) {
	args := c.ABI.Errors["InvalidRouter"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	router, ok0 := values[0].(common.Address)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for router in InvalidRouter error")
	}

	return &InvalidRouter{
		Router: router,
	}, nil
}

// Error implements the error interface for InvalidRouter.
func (e *InvalidRouter) Error() string {
	return fmt.Sprintf("InvalidRouter error: router=%v;", e.Router)
}

// DecodeReentrancyGuardReentrantCallError decodes a ReentrancyGuardReentrantCall error from revert data.
func (c *ChildVault) DecodeReentrancyGuardReentrantCallError(data []byte) (*ReentrancyGuardReentrantCall, error) {
	args := c.ABI.Errors["ReentrancyGuardReentrantCall"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &ReentrancyGuardReentrantCall{}, nil
}

// Error implements the error interface for ReentrancyGuardReentrantCall.
func (e *ReentrancyGuardReentrantCall) Error() string {
	return fmt.Sprintf("ReentrancyGuardReentrantCall error:")
}

// DecodeSafeCastOverflowedUintDowncastError decodes a SafeCastOverflowedUintDowncast error from revert data.
func (c *ChildVault) DecodeSafeCastOverflowedUintDowncastError(data []byte) (*SafeCastOverflowedUintDowncast, error) {
	args := c.ABI.Errors["SafeCastOverflowedUintDowncast"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 2 {
		return nil, fmt.Errorf("expected 2 values, got %d", len(values))
	}

	bits, ok0 := values[0].(uint8)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for bits in SafeCastOverflowedUintDowncast error")
	}

	value, ok1 := values[1].(*big.Int)
	if !ok1 {
		return nil, fmt.Errorf("unexpected type for value in SafeCastOverflowedUintDowncast error")
	}

	return &SafeCastOverflowedUintDowncast{
		Bits:  bits,
		Value: value,
	}, nil
}

// Error implements the error interface for SafeCastOverflowedUintDowncast.
func (e *SafeCastOverflowedUintDowncast) Error() string {
	return fmt.Sprintf("SafeCastOverflowedUintDowncast error: bits=%v; value=%v;", e.Bits, e.Value)
}

// DecodeSafeERC20FailedOperationError decodes a SafeERC20FailedOperation error from revert data.
func (c *ChildVault) DecodeSafeERC20FailedOperationError(data []byte) (*SafeERC20FailedOperation, error) {
	args := c.ABI.Errors["SafeERC20FailedOperation"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	token, ok0 := values[0].(common.Address)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for token in SafeERC20FailedOperation error")
	}

	return &SafeERC20FailedOperation{
		Token: token,
	}, nil
}

// Error implements the error interface for SafeERC20FailedOperation.
func (e *SafeERC20FailedOperation) Error() string {
	return fmt.Sprintf("SafeERC20FailedOperation error: token=%v;", e.Token)
}

func (c *ChildVault) UnpackError(data []byte) (any, error) {
	switch common.Bytes2Hex(data[:4]) {
	case common.Bytes2Hex(c.ABI.Errors["AccessControlBadConfirmation"].ID.Bytes()[:4]):
		return c.DecodeAccessControlBadConfirmationError(data)
	case common.Bytes2Hex(c.ABI.Errors["AccessControlEnforcedDefaultAdminDelay"].ID.Bytes()[:4]):
		return c.DecodeAccessControlEnforcedDefaultAdminDelayError(data)
	case common.Bytes2Hex(c.ABI.Errors["AccessControlEnforcedDefaultAdminRules"].ID.Bytes()[:4]):
		return c.DecodeAccessControlEnforcedDefaultAdminRulesError(data)
	case common.Bytes2Hex(c.ABI.Errors["AccessControlInvalidDefaultAdmin"].ID.Bytes()[:4]):
		return c.DecodeAccessControlInvalidDefaultAdminError(data)
	case common.Bytes2Hex(c.ABI.Errors["AccessControlUnauthorizedAccount"].ID.Bytes()[:4]):
		return c.DecodeAccessControlUnauthorizedAccountError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__DepositFailed"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultDepositFailedError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__EmergencyDrainDelayNotMet"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultEmergencyDrainDelayNotMetError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__InvalidInputLengths"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultInvalidInputLengthsError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__InvalidSender"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultInvalidSenderError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__NoActiveAdapter"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultNoActiveAdapterError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__NoAdapterRegistered"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultNoAdapterRegisteredError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__NoPendingRecovery"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultNoPendingRecoveryError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__NoZeroAmount"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultNoZeroAmountError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__OnlySelf"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultOnlySelfError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__RecoveryAlreadyPending"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultRecoveryAlreadyPendingError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__WithdrawFailed"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultWithdrawFailedError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__ZeroRecoveryAmount"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultZeroRecoveryAmountError(data)
	case common.Bytes2Hex(c.ABI.Errors["ChildVault__InvalidRecoveryStrategy"].ID.Bytes()[:4]):
		return c.DecodeChildVaultInvalidRecoveryStrategyError(data)
	case common.Bytes2Hex(c.ABI.Errors["EnforcedPause"].ID.Bytes()[:4]):
		return c.DecodeEnforcedPauseError(data)
	case common.Bytes2Hex(c.ABI.Errors["ExpectedPause"].ID.Bytes()[:4]):
		return c.DecodeExpectedPauseError(data)
	case common.Bytes2Hex(c.ABI.Errors["InvalidRouter"].ID.Bytes()[:4]):
		return c.DecodeInvalidRouterError(data)
	case common.Bytes2Hex(c.ABI.Errors["ReentrancyGuardReentrantCall"].ID.Bytes()[:4]):
		return c.DecodeReentrancyGuardReentrantCallError(data)
	case common.Bytes2Hex(c.ABI.Errors["SafeCastOverflowedUintDowncast"].ID.Bytes()[:4]):
		return c.DecodeSafeCastOverflowedUintDowncastError(data)
	case common.Bytes2Hex(c.ABI.Errors["SafeERC20FailedOperation"].ID.Bytes()[:4]):
		return c.DecodeSafeERC20FailedOperationError(data)
	default:
		return nil, errors.New("unknown error selector")
	}
}

// CcipGasLimitSetTrigger wraps the raw log trigger and provides decoded CcipGasLimitSetDecoded data
type CcipGasLimitSetTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into CcipGasLimitSet data
func (t *CcipGasLimitSetTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[CcipGasLimitSetDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeCcipGasLimitSet(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode CcipGasLimitSet log: %w", err)
	}

	return &bindings.DecodedLog[CcipGasLimitSetDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerCcipGasLimitSetLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []CcipGasLimitSetTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[CcipGasLimitSetDecoded]], error) {
	event := c.ABI.Events["CcipGasLimitSet"]
	topics, err := c.Codec.EncodeCcipGasLimitSetTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for CcipGasLimitSet: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &CcipGasLimitSetTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsCcipGasLimitSet(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.CcipGasLimitSetLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// CrosschainVaultSetTrigger wraps the raw log trigger and provides decoded CrosschainVaultSetDecoded data
type CrosschainVaultSetTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into CrosschainVaultSet data
func (t *CrosschainVaultSetTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[CrosschainVaultSetDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeCrosschainVaultSet(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode CrosschainVaultSet log: %w", err)
	}

	return &bindings.DecodedLog[CrosschainVaultSetDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerCrosschainVaultSetLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []CrosschainVaultSetTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[CrosschainVaultSetDecoded]], error) {
	event := c.ABI.Events["CrosschainVaultSet"]
	topics, err := c.Codec.EncodeCrosschainVaultSetTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for CrosschainVaultSet: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &CrosschainVaultSetTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsCrosschainVaultSet(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.CrosschainVaultSetLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// DefaultAdminDelayChangeCanceledTrigger wraps the raw log trigger and provides decoded DefaultAdminDelayChangeCanceledDecoded data
type DefaultAdminDelayChangeCanceledTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into DefaultAdminDelayChangeCanceled data
func (t *DefaultAdminDelayChangeCanceledTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[DefaultAdminDelayChangeCanceledDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeDefaultAdminDelayChangeCanceled(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode DefaultAdminDelayChangeCanceled log: %w", err)
	}

	return &bindings.DecodedLog[DefaultAdminDelayChangeCanceledDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerDefaultAdminDelayChangeCanceledLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []DefaultAdminDelayChangeCanceledTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[DefaultAdminDelayChangeCanceledDecoded]], error) {
	event := c.ABI.Events["DefaultAdminDelayChangeCanceled"]
	topics, err := c.Codec.EncodeDefaultAdminDelayChangeCanceledTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for DefaultAdminDelayChangeCanceled: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &DefaultAdminDelayChangeCanceledTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsDefaultAdminDelayChangeCanceled(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.DefaultAdminDelayChangeCanceledLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// DefaultAdminDelayChangeScheduledTrigger wraps the raw log trigger and provides decoded DefaultAdminDelayChangeScheduledDecoded data
type DefaultAdminDelayChangeScheduledTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into DefaultAdminDelayChangeScheduled data
func (t *DefaultAdminDelayChangeScheduledTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[DefaultAdminDelayChangeScheduledDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeDefaultAdminDelayChangeScheduled(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode DefaultAdminDelayChangeScheduled log: %w", err)
	}

	return &bindings.DecodedLog[DefaultAdminDelayChangeScheduledDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerDefaultAdminDelayChangeScheduledLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []DefaultAdminDelayChangeScheduledTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[DefaultAdminDelayChangeScheduledDecoded]], error) {
	event := c.ABI.Events["DefaultAdminDelayChangeScheduled"]
	topics, err := c.Codec.EncodeDefaultAdminDelayChangeScheduledTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for DefaultAdminDelayChangeScheduled: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &DefaultAdminDelayChangeScheduledTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsDefaultAdminDelayChangeScheduled(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.DefaultAdminDelayChangeScheduledLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// DefaultAdminTransferCanceledTrigger wraps the raw log trigger and provides decoded DefaultAdminTransferCanceledDecoded data
type DefaultAdminTransferCanceledTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into DefaultAdminTransferCanceled data
func (t *DefaultAdminTransferCanceledTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[DefaultAdminTransferCanceledDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeDefaultAdminTransferCanceled(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode DefaultAdminTransferCanceled log: %w", err)
	}

	return &bindings.DecodedLog[DefaultAdminTransferCanceledDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerDefaultAdminTransferCanceledLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []DefaultAdminTransferCanceledTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[DefaultAdminTransferCanceledDecoded]], error) {
	event := c.ABI.Events["DefaultAdminTransferCanceled"]
	topics, err := c.Codec.EncodeDefaultAdminTransferCanceledTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for DefaultAdminTransferCanceled: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &DefaultAdminTransferCanceledTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsDefaultAdminTransferCanceled(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.DefaultAdminTransferCanceledLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// DefaultAdminTransferScheduledTrigger wraps the raw log trigger and provides decoded DefaultAdminTransferScheduledDecoded data
type DefaultAdminTransferScheduledTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into DefaultAdminTransferScheduled data
func (t *DefaultAdminTransferScheduledTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[DefaultAdminTransferScheduledDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeDefaultAdminTransferScheduled(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode DefaultAdminTransferScheduled log: %w", err)
	}

	return &bindings.DecodedLog[DefaultAdminTransferScheduledDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerDefaultAdminTransferScheduledLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []DefaultAdminTransferScheduledTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[DefaultAdminTransferScheduledDecoded]], error) {
	event := c.ABI.Events["DefaultAdminTransferScheduled"]
	topics, err := c.Codec.EncodeDefaultAdminTransferScheduledTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for DefaultAdminTransferScheduled: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &DefaultAdminTransferScheduledTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsDefaultAdminTransferScheduled(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.DefaultAdminTransferScheduledLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// DefaultCcipGasLimitSetTrigger wraps the raw log trigger and provides decoded DefaultCcipGasLimitSetDecoded data
type DefaultCcipGasLimitSetTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into DefaultCcipGasLimitSet data
func (t *DefaultCcipGasLimitSetTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[DefaultCcipGasLimitSetDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeDefaultCcipGasLimitSet(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode DefaultCcipGasLimitSet log: %w", err)
	}

	return &bindings.DecodedLog[DefaultCcipGasLimitSetDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerDefaultCcipGasLimitSetLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []DefaultCcipGasLimitSetTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[DefaultCcipGasLimitSetDecoded]], error) {
	event := c.ABI.Events["DefaultCcipGasLimitSet"]
	topics, err := c.Codec.EncodeDefaultCcipGasLimitSetTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for DefaultCcipGasLimitSet: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &DefaultCcipGasLimitSetTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsDefaultCcipGasLimitSet(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.DefaultCcipGasLimitSetLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// DepositToStrategyFailureTrigger wraps the raw log trigger and provides decoded DepositToStrategyFailureDecoded data
type DepositToStrategyFailureTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into DepositToStrategyFailure data
func (t *DepositToStrategyFailureTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[DepositToStrategyFailureDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeDepositToStrategyFailure(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode DepositToStrategyFailure log: %w", err)
	}

	return &bindings.DecodedLog[DepositToStrategyFailureDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerDepositToStrategyFailureLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []DepositToStrategyFailureTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[DepositToStrategyFailureDecoded]], error) {
	event := c.ABI.Events["DepositToStrategyFailure"]
	topics, err := c.Codec.EncodeDepositToStrategyFailureTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for DepositToStrategyFailure: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &DepositToStrategyFailureTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsDepositToStrategyFailure(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.DepositToStrategyFailureLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// DepositToStrategySuccessTrigger wraps the raw log trigger and provides decoded DepositToStrategySuccessDecoded data
type DepositToStrategySuccessTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into DepositToStrategySuccess data
func (t *DepositToStrategySuccessTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[DepositToStrategySuccessDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeDepositToStrategySuccess(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode DepositToStrategySuccess log: %w", err)
	}

	return &bindings.DecodedLog[DepositToStrategySuccessDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerDepositToStrategySuccessLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []DepositToStrategySuccessTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[DepositToStrategySuccessDecoded]], error) {
	event := c.ABI.Events["DepositToStrategySuccess"]
	topics, err := c.Codec.EncodeDepositToStrategySuccessTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for DepositToStrategySuccess: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &DepositToStrategySuccessTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsDepositToStrategySuccess(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.DepositToStrategySuccessLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// EmergencyDrainExecutedTrigger wraps the raw log trigger and provides decoded EmergencyDrainExecutedDecoded data
type EmergencyDrainExecutedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into EmergencyDrainExecuted data
func (t *EmergencyDrainExecutedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[EmergencyDrainExecutedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeEmergencyDrainExecuted(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode EmergencyDrainExecuted log: %w", err)
	}

	return &bindings.DecodedLog[EmergencyDrainExecutedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerEmergencyDrainExecutedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []EmergencyDrainExecutedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[EmergencyDrainExecutedDecoded]], error) {
	event := c.ABI.Events["EmergencyDrainExecuted"]
	topics, err := c.Codec.EncodeEmergencyDrainExecutedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for EmergencyDrainExecuted: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &EmergencyDrainExecutedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsEmergencyDrainExecuted(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.EmergencyDrainExecutedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// EpochDepositRecoveryClearedTrigger wraps the raw log trigger and provides decoded EpochDepositRecoveryClearedDecoded data
type EpochDepositRecoveryClearedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into EpochDepositRecoveryCleared data
func (t *EpochDepositRecoveryClearedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[EpochDepositRecoveryClearedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeEpochDepositRecoveryCleared(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode EpochDepositRecoveryCleared log: %w", err)
	}

	return &bindings.DecodedLog[EpochDepositRecoveryClearedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerEpochDepositRecoveryClearedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []EpochDepositRecoveryClearedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[EpochDepositRecoveryClearedDecoded]], error) {
	event := c.ABI.Events["EpochDepositRecoveryCleared"]
	topics, err := c.Codec.EncodeEpochDepositRecoveryClearedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for EpochDepositRecoveryCleared: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &EpochDepositRecoveryClearedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsEpochDepositRecoveryCleared(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.EpochDepositRecoveryClearedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// EpochDepositRecoveryStoredTrigger wraps the raw log trigger and provides decoded EpochDepositRecoveryStoredDecoded data
type EpochDepositRecoveryStoredTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into EpochDepositRecoveryStored data
func (t *EpochDepositRecoveryStoredTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[EpochDepositRecoveryStoredDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeEpochDepositRecoveryStored(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode EpochDepositRecoveryStored log: %w", err)
	}

	return &bindings.DecodedLog[EpochDepositRecoveryStoredDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerEpochDepositRecoveryStoredLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []EpochDepositRecoveryStoredTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[EpochDepositRecoveryStoredDecoded]], error) {
	event := c.ABI.Events["EpochDepositRecoveryStored"]
	topics, err := c.Codec.EncodeEpochDepositRecoveryStoredTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for EpochDepositRecoveryStored: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &EpochDepositRecoveryStoredTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsEpochDepositRecoveryStored(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.EpochDepositRecoveryStoredLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// EpochWithdrawRecoveryClearedTrigger wraps the raw log trigger and provides decoded EpochWithdrawRecoveryClearedDecoded data
type EpochWithdrawRecoveryClearedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into EpochWithdrawRecoveryCleared data
func (t *EpochWithdrawRecoveryClearedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[EpochWithdrawRecoveryClearedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeEpochWithdrawRecoveryCleared(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode EpochWithdrawRecoveryCleared log: %w", err)
	}

	return &bindings.DecodedLog[EpochWithdrawRecoveryClearedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerEpochWithdrawRecoveryClearedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []EpochWithdrawRecoveryClearedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[EpochWithdrawRecoveryClearedDecoded]], error) {
	event := c.ABI.Events["EpochWithdrawRecoveryCleared"]
	topics, err := c.Codec.EncodeEpochWithdrawRecoveryClearedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for EpochWithdrawRecoveryCleared: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &EpochWithdrawRecoveryClearedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsEpochWithdrawRecoveryCleared(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.EpochWithdrawRecoveryClearedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// EpochWithdrawRecoveryStoredTrigger wraps the raw log trigger and provides decoded EpochWithdrawRecoveryStoredDecoded data
type EpochWithdrawRecoveryStoredTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into EpochWithdrawRecoveryStored data
func (t *EpochWithdrawRecoveryStoredTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[EpochWithdrawRecoveryStoredDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeEpochWithdrawRecoveryStored(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode EpochWithdrawRecoveryStored log: %w", err)
	}

	return &bindings.DecodedLog[EpochWithdrawRecoveryStoredDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerEpochWithdrawRecoveryStoredLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []EpochWithdrawRecoveryStoredTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[EpochWithdrawRecoveryStoredDecoded]], error) {
	event := c.ABI.Events["EpochWithdrawRecoveryStored"]
	topics, err := c.Codec.EncodeEpochWithdrawRecoveryStoredTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for EpochWithdrawRecoveryStored: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &EpochWithdrawRecoveryStoredTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsEpochWithdrawRecoveryStored(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.EpochWithdrawRecoveryStoredLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// LinkWithdrawnTrigger wraps the raw log trigger and provides decoded LinkWithdrawnDecoded data
type LinkWithdrawnTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into LinkWithdrawn data
func (t *LinkWithdrawnTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[LinkWithdrawnDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeLinkWithdrawn(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode LinkWithdrawn log: %w", err)
	}

	return &bindings.DecodedLog[LinkWithdrawnDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerLinkWithdrawnLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []LinkWithdrawnTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[LinkWithdrawnDecoded]], error) {
	event := c.ABI.Events["LinkWithdrawn"]
	topics, err := c.Codec.EncodeLinkWithdrawnTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for LinkWithdrawn: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &LinkWithdrawnTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsLinkWithdrawn(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.LinkWithdrawnLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// PausedTrigger wraps the raw log trigger and provides decoded PausedDecoded data
type PausedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into Paused data
func (t *PausedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[PausedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodePaused(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode Paused log: %w", err)
	}

	return &bindings.DecodedLog[PausedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerPausedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []PausedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[PausedDecoded]], error) {
	event := c.ABI.Events["Paused"]
	topics, err := c.Codec.EncodePausedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for Paused: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &PausedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsPaused(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.PausedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// RebalanceDepositFailureTrigger wraps the raw log trigger and provides decoded RebalanceDepositFailureDecoded data
type RebalanceDepositFailureTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into RebalanceDepositFailure data
func (t *RebalanceDepositFailureTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[RebalanceDepositFailureDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeRebalanceDepositFailure(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode RebalanceDepositFailure log: %w", err)
	}

	return &bindings.DecodedLog[RebalanceDepositFailureDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerRebalanceDepositFailureLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []RebalanceDepositFailureTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[RebalanceDepositFailureDecoded]], error) {
	event := c.ABI.Events["RebalanceDepositFailure"]
	topics, err := c.Codec.EncodeRebalanceDepositFailureTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for RebalanceDepositFailure: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &RebalanceDepositFailureTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsRebalanceDepositFailure(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.RebalanceDepositFailureLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// RebalanceDepositRecoveryClearedTrigger wraps the raw log trigger and provides decoded RebalanceDepositRecoveryClearedDecoded data
type RebalanceDepositRecoveryClearedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into RebalanceDepositRecoveryCleared data
func (t *RebalanceDepositRecoveryClearedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[RebalanceDepositRecoveryClearedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeRebalanceDepositRecoveryCleared(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode RebalanceDepositRecoveryCleared log: %w", err)
	}

	return &bindings.DecodedLog[RebalanceDepositRecoveryClearedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerRebalanceDepositRecoveryClearedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []RebalanceDepositRecoveryClearedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[RebalanceDepositRecoveryClearedDecoded]], error) {
	event := c.ABI.Events["RebalanceDepositRecoveryCleared"]
	topics, err := c.Codec.EncodeRebalanceDepositRecoveryClearedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for RebalanceDepositRecoveryCleared: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &RebalanceDepositRecoveryClearedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsRebalanceDepositRecoveryCleared(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.RebalanceDepositRecoveryClearedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// RebalanceDepositRecoveryStoredTrigger wraps the raw log trigger and provides decoded RebalanceDepositRecoveryStoredDecoded data
type RebalanceDepositRecoveryStoredTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into RebalanceDepositRecoveryStored data
func (t *RebalanceDepositRecoveryStoredTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[RebalanceDepositRecoveryStoredDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeRebalanceDepositRecoveryStored(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode RebalanceDepositRecoveryStored log: %w", err)
	}

	return &bindings.DecodedLog[RebalanceDepositRecoveryStoredDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerRebalanceDepositRecoveryStoredLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []RebalanceDepositRecoveryStoredTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[RebalanceDepositRecoveryStoredDecoded]], error) {
	event := c.ABI.Events["RebalanceDepositRecoveryStored"]
	topics, err := c.Codec.EncodeRebalanceDepositRecoveryStoredTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for RebalanceDepositRecoveryStored: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &RebalanceDepositRecoveryStoredTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsRebalanceDepositRecoveryStored(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.RebalanceDepositRecoveryStoredLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// RebalanceDepositSuccessTrigger wraps the raw log trigger and provides decoded RebalanceDepositSuccessDecoded data
type RebalanceDepositSuccessTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into RebalanceDepositSuccess data
func (t *RebalanceDepositSuccessTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[RebalanceDepositSuccessDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeRebalanceDepositSuccess(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode RebalanceDepositSuccess log: %w", err)
	}

	return &bindings.DecodedLog[RebalanceDepositSuccessDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerRebalanceDepositSuccessLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []RebalanceDepositSuccessTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[RebalanceDepositSuccessDecoded]], error) {
	event := c.ABI.Events["RebalanceDepositSuccess"]
	topics, err := c.Codec.EncodeRebalanceDepositSuccessTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for RebalanceDepositSuccess: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &RebalanceDepositSuccessTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsRebalanceDepositSuccess(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.RebalanceDepositSuccessLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// RebalanceWithdrawFailureTrigger wraps the raw log trigger and provides decoded RebalanceWithdrawFailureDecoded data
type RebalanceWithdrawFailureTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into RebalanceWithdrawFailure data
func (t *RebalanceWithdrawFailureTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[RebalanceWithdrawFailureDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeRebalanceWithdrawFailure(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode RebalanceWithdrawFailure log: %w", err)
	}

	return &bindings.DecodedLog[RebalanceWithdrawFailureDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerRebalanceWithdrawFailureLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []RebalanceWithdrawFailureTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[RebalanceWithdrawFailureDecoded]], error) {
	event := c.ABI.Events["RebalanceWithdrawFailure"]
	topics, err := c.Codec.EncodeRebalanceWithdrawFailureTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for RebalanceWithdrawFailure: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &RebalanceWithdrawFailureTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsRebalanceWithdrawFailure(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.RebalanceWithdrawFailureLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// RebalanceWithdrawRecoveryClearedTrigger wraps the raw log trigger and provides decoded RebalanceWithdrawRecoveryClearedDecoded data
type RebalanceWithdrawRecoveryClearedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into RebalanceWithdrawRecoveryCleared data
func (t *RebalanceWithdrawRecoveryClearedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[RebalanceWithdrawRecoveryClearedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeRebalanceWithdrawRecoveryCleared(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode RebalanceWithdrawRecoveryCleared log: %w", err)
	}

	return &bindings.DecodedLog[RebalanceWithdrawRecoveryClearedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerRebalanceWithdrawRecoveryClearedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []RebalanceWithdrawRecoveryClearedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[RebalanceWithdrawRecoveryClearedDecoded]], error) {
	event := c.ABI.Events["RebalanceWithdrawRecoveryCleared"]
	topics, err := c.Codec.EncodeRebalanceWithdrawRecoveryClearedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for RebalanceWithdrawRecoveryCleared: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &RebalanceWithdrawRecoveryClearedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsRebalanceWithdrawRecoveryCleared(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.RebalanceWithdrawRecoveryClearedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// RebalanceWithdrawRecoveryStoredTrigger wraps the raw log trigger and provides decoded RebalanceWithdrawRecoveryStoredDecoded data
type RebalanceWithdrawRecoveryStoredTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into RebalanceWithdrawRecoveryStored data
func (t *RebalanceWithdrawRecoveryStoredTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[RebalanceWithdrawRecoveryStoredDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeRebalanceWithdrawRecoveryStored(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode RebalanceWithdrawRecoveryStored log: %w", err)
	}

	return &bindings.DecodedLog[RebalanceWithdrawRecoveryStoredDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerRebalanceWithdrawRecoveryStoredLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []RebalanceWithdrawRecoveryStoredTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[RebalanceWithdrawRecoveryStoredDecoded]], error) {
	event := c.ABI.Events["RebalanceWithdrawRecoveryStored"]
	topics, err := c.Codec.EncodeRebalanceWithdrawRecoveryStoredTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for RebalanceWithdrawRecoveryStored: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &RebalanceWithdrawRecoveryStoredTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsRebalanceWithdrawRecoveryStored(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.RebalanceWithdrawRecoveryStoredLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// RebalanceWithdrawSuccessTrigger wraps the raw log trigger and provides decoded RebalanceWithdrawSuccessDecoded data
type RebalanceWithdrawSuccessTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into RebalanceWithdrawSuccess data
func (t *RebalanceWithdrawSuccessTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[RebalanceWithdrawSuccessDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeRebalanceWithdrawSuccess(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode RebalanceWithdrawSuccess log: %w", err)
	}

	return &bindings.DecodedLog[RebalanceWithdrawSuccessDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerRebalanceWithdrawSuccessLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []RebalanceWithdrawSuccessTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[RebalanceWithdrawSuccessDecoded]], error) {
	event := c.ABI.Events["RebalanceWithdrawSuccess"]
	topics, err := c.Codec.EncodeRebalanceWithdrawSuccessTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for RebalanceWithdrawSuccess: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &RebalanceWithdrawSuccessTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsRebalanceWithdrawSuccess(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.RebalanceWithdrawSuccessLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// RoleAdminChangedTrigger wraps the raw log trigger and provides decoded RoleAdminChangedDecoded data
type RoleAdminChangedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into RoleAdminChanged data
func (t *RoleAdminChangedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[RoleAdminChangedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeRoleAdminChanged(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode RoleAdminChanged log: %w", err)
	}

	return &bindings.DecodedLog[RoleAdminChangedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerRoleAdminChangedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []RoleAdminChangedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[RoleAdminChangedDecoded]], error) {
	event := c.ABI.Events["RoleAdminChanged"]
	topics, err := c.Codec.EncodeRoleAdminChangedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for RoleAdminChanged: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &RoleAdminChangedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsRoleAdminChanged(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.RoleAdminChangedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// RoleGrantedTrigger wraps the raw log trigger and provides decoded RoleGrantedDecoded data
type RoleGrantedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into RoleGranted data
func (t *RoleGrantedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[RoleGrantedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeRoleGranted(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode RoleGranted log: %w", err)
	}

	return &bindings.DecodedLog[RoleGrantedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerRoleGrantedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []RoleGrantedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[RoleGrantedDecoded]], error) {
	event := c.ABI.Events["RoleGranted"]
	topics, err := c.Codec.EncodeRoleGrantedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for RoleGranted: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &RoleGrantedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsRoleGranted(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.RoleGrantedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// RoleRevokedTrigger wraps the raw log trigger and provides decoded RoleRevokedDecoded data
type RoleRevokedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into RoleRevoked data
func (t *RoleRevokedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[RoleRevokedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeRoleRevoked(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode RoleRevoked log: %w", err)
	}

	return &bindings.DecodedLog[RoleRevokedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerRoleRevokedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []RoleRevokedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[RoleRevokedDecoded]], error) {
	event := c.ABI.Events["RoleRevoked"]
	topics, err := c.Codec.EncodeRoleRevokedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for RoleRevoked: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &RoleRevokedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsRoleRevoked(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.RoleRevokedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// USDCBridgedTrigger wraps the raw log trigger and provides decoded USDCBridgedDecoded data
type USDCBridgedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into USDCBridged data
func (t *USDCBridgedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[USDCBridgedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeUSDCBridged(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode USDCBridged log: %w", err)
	}

	return &bindings.DecodedLog[USDCBridgedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerUSDCBridgedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []USDCBridgedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[USDCBridgedDecoded]], error) {
	event := c.ABI.Events["USDCBridged"]
	topics, err := c.Codec.EncodeUSDCBridgedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for USDCBridged: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &USDCBridgedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsUSDCBridged(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.USDCBridgedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// UnpausedTrigger wraps the raw log trigger and provides decoded UnpausedDecoded data
type UnpausedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into Unpaused data
func (t *UnpausedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[UnpausedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeUnpaused(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode Unpaused log: %w", err)
	}

	return &bindings.DecodedLog[UnpausedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerUnpausedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []UnpausedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[UnpausedDecoded]], error) {
	event := c.ABI.Events["Unpaused"]
	topics, err := c.Codec.EncodeUnpausedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for Unpaused: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &UnpausedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsUnpaused(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.UnpausedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// WithdrawFromStrategyFailureTrigger wraps the raw log trigger and provides decoded WithdrawFromStrategyFailureDecoded data
type WithdrawFromStrategyFailureTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into WithdrawFromStrategyFailure data
func (t *WithdrawFromStrategyFailureTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[WithdrawFromStrategyFailureDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeWithdrawFromStrategyFailure(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode WithdrawFromStrategyFailure log: %w", err)
	}

	return &bindings.DecodedLog[WithdrawFromStrategyFailureDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerWithdrawFromStrategyFailureLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []WithdrawFromStrategyFailureTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[WithdrawFromStrategyFailureDecoded]], error) {
	event := c.ABI.Events["WithdrawFromStrategyFailure"]
	topics, err := c.Codec.EncodeWithdrawFromStrategyFailureTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for WithdrawFromStrategyFailure: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &WithdrawFromStrategyFailureTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsWithdrawFromStrategyFailure(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.WithdrawFromStrategyFailureLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// WithdrawFromStrategySuccessTrigger wraps the raw log trigger and provides decoded WithdrawFromStrategySuccessDecoded data
type WithdrawFromStrategySuccessTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]             // Embed the raw trigger
	contract                        *ChildVault // Keep reference for decoding
}

// Adapt method that decodes the log into WithdrawFromStrategySuccess data
func (t *WithdrawFromStrategySuccessTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[WithdrawFromStrategySuccessDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeWithdrawFromStrategySuccess(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode WithdrawFromStrategySuccess log: %w", err)
	}

	return &bindings.DecodedLog[WithdrawFromStrategySuccessDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ChildVault) LogTriggerWithdrawFromStrategySuccessLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []WithdrawFromStrategySuccessTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[WithdrawFromStrategySuccessDecoded]], error) {
	event := c.ABI.Events["WithdrawFromStrategySuccess"]
	topics, err := c.Codec.EncodeWithdrawFromStrategySuccessTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for WithdrawFromStrategySuccess: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &WithdrawFromStrategySuccessTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ChildVault) FilterLogsWithdrawFromStrategySuccess(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.WithdrawFromStrategySuccessLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

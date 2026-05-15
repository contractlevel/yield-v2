// Code generated — DO NOT EDIT.

package parent_vault

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

var ParentVaultMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"params\",\"type\":\"tuple\",\"internalType\":\"structBaseVault.ConstructorParams\",\"components\":[{\"name\":\"link\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"usdc\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"ccipRouter\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"defaultAdmin\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"pauser\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"unpauser\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"configOperator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"adapterRegistry\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"thisChainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]},{\"name\":\"treasury\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"share\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"policyEngineManager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"policyEngine\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"DEFAULT_ADMIN_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"acceptDefaultAdminTransfer\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"attachPolicyEngine\",\"inputs\":[{\"name\":\"policyEngine\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"beginDefaultAdminTransfer\",\"inputs\":[{\"name\":\"newAdmin\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"cancelDefaultAdminTransfer\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"cancelDeposit\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"cancelWithdraw\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"ccipReceive\",\"inputs\":[{\"name\":\"message\",\"type\":\"tuple\",\"internalType\":\"structClient.Any2EVMMessage\",\"components\":[{\"name\":\"messageId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"sourceChainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"sender\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"destTokenAmounts\",\"type\":\"tuple[]\",\"internalType\":\"structClient.EVMTokenAmount[]\",\"components\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"changeDefaultAdminDelay\",\"inputs\":[{\"name\":\"newDelay\",\"type\":\"uint48\",\"internalType\":\"uint48\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"claimShares\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"shareMintAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"claimUsdc\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"usdcWithdrawAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"clearContext\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"closeEpoch\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"tvl\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"completeRebalance\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"defaultAdmin\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"defaultAdminDelay\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint48\",\"internalType\":\"uint48\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"defaultAdminDelayIncreaseWait\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint48\",\"internalType\":\"uint48\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"deposit\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"emergencyDrain\",\"inputs\":[{\"name\":\"revertOnFailure\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getActiveProtocolAdapter\",\"inputs\":[],\"outputs\":[{\"name\":\"activeProtocolAdapter\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAdapterRegistry\",\"inputs\":[],\"outputs\":[{\"name\":\"adapterRegistry\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getCCVsAndFinalityConfig\",\"inputs\":[{\"name\":\"\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"requiredCCVs\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"optionalCCVs\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"optionalThreshold\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"allowedFinalityConfig\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getCcipGasLimit\",\"inputs\":[{\"name\":\"chainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"outputs\":[{\"name\":\"gasLimit\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getContext\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getCrosschainVault\",\"inputs\":[{\"name\":\"chainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"outputs\":[{\"name\":\"vault\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getDefaultCcipGasLimit\",\"inputs\":[],\"outputs\":[{\"name\":\"defaultCcipGasLimit\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getDepositAmount\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getEpoch\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"epoch\",\"type\":\"tuple\",\"internalType\":\"structTypes.Epoch\",\"components\":[{\"name\":\"totalDepositAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"totalShareBurnAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"totalWithdrawClaimAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"pricePerShare\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"openedAtTimestamp\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"closedAtTimestamp\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"status\",\"type\":\"uint8\",\"internalType\":\"enumTypes.EpochStatus\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getEpochNonce\",\"inputs\":[],\"outputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getInitialActiveProtocolAdapterSet\",\"inputs\":[],\"outputs\":[{\"name\":\"initialActiveProtocolAdapterSet\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getLink\",\"inputs\":[],\"outputs\":[{\"name\":\"link\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getNetAmountAndOperationFee\",\"inputs\":[{\"name\":\"grossAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"netAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"feeAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"getPausedAt\",\"inputs\":[],\"outputs\":[{\"name\":\"pausedAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getPolicyEngine\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRebalance\",\"inputs\":[],\"outputs\":[{\"name\":\"rebalance\",\"type\":\"tuple\",\"internalType\":\"structTypes.Rebalance\",\"components\":[{\"name\":\"nonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"state\",\"type\":\"uint8\",\"internalType\":\"enumTypes.RebalanceState\"},{\"name\":\"activeStrategy\",\"type\":\"tuple\",\"internalType\":\"structTypes.Strategy\",\"components\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"chainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]},{\"name\":\"pendingStrategy\",\"type\":\"tuple\",\"internalType\":\"structTypes.Strategy\",\"components\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"chainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]},{\"name\":\"lastRebalanceInitiatedTimestamp\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"lastRebalanceCompletedTimestamp\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRebalanceDepositRecovery\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"recovery\",\"type\":\"tuple\",\"internalType\":\"structTypes.AmountRecovery\",\"components\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"createdAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRoleAdmin\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRouter\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getShare\",\"inputs\":[],\"outputs\":[{\"name\":\"share\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getTVL\",\"inputs\":[],\"outputs\":[{\"name\":\"tvl\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getThisChainSelector\",\"inputs\":[],\"outputs\":[{\"name\":\"thisChainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getTotalShares\",\"inputs\":[],\"outputs\":[{\"name\":\"totalShares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getTreasury\",\"inputs\":[],\"outputs\":[{\"name\":\"treasury\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getUsdc\",\"inputs\":[],\"outputs\":[{\"name\":\"usdc\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getWithdrawShareBurnAmount\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"shareBurnAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"grantRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"hasRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"initiateRebalance\",\"inputs\":[{\"name\":\"newStrategy\",\"type\":\"tuple\",\"internalType\":\"structTypes.Strategy\",\"components\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"chainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"owner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pause\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"paused\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pendingDefaultAdmin\",\"inputs\":[],\"outputs\":[{\"name\":\"newAdmin\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"schedule\",\"type\":\"uint48\",\"internalType\":\"uint48\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pendingDefaultAdminDelay\",\"inputs\":[],\"outputs\":[{\"name\":\"newDelay\",\"type\":\"uint48\",\"internalType\":\"uint48\"},{\"name\":\"schedule\",\"type\":\"uint48\",\"internalType\":\"uint48\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"recoverFailedRebalanceDeposit\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceOwnership\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"revokeRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"rollbackDefaultAdminDelay\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setCcipGasLimit\",\"inputs\":[{\"name\":\"chainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"gasLimit\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setContext\",\"inputs\":[{\"name\":\"context\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setCrosschainVaults\",\"inputs\":[{\"name\":\"chainSelectors\",\"type\":\"uint64[]\",\"internalType\":\"uint64[]\"},{\"name\":\"vaults\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setDefaultCcipGasLimit\",\"inputs\":[{\"name\":\"gasLimit\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setInitialActiveProtocolAdapter\",\"inputs\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setTreasury\",\"inputs\":[{\"name\":\"treasury\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"transferOwnership\",\"inputs\":[{\"name\":\"newOwner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"tryDepositToAdapter\",\"inputs\":[{\"name\":\"adapter\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"unpause\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"withdraw\",\"inputs\":[{\"name\":\"shareBurnAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"withdrawLink\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"CcipGasLimitSet\",\"inputs\":[{\"name\":\"chainSelector\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"},{\"name\":\"gasLimit\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"CrosschainVaultSet\",\"inputs\":[{\"name\":\"chainSelector\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"},{\"name\":\"vault\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DefaultAdminDelayChangeCanceled\",\"inputs\":[],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DefaultAdminDelayChangeScheduled\",\"inputs\":[{\"name\":\"newDelay\",\"type\":\"uint48\",\"indexed\":false,\"internalType\":\"uint48\"},{\"name\":\"effectSchedule\",\"type\":\"uint48\",\"indexed\":false,\"internalType\":\"uint48\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DefaultAdminTransferCanceled\",\"inputs\":[],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DefaultAdminTransferScheduled\",\"inputs\":[{\"name\":\"newAdmin\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"acceptSchedule\",\"type\":\"uint48\",\"indexed\":false,\"internalType\":\"uint48\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DefaultCcipGasLimitSet\",\"inputs\":[{\"name\":\"gasLimit\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DepositCancelled\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"depositor\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DepositClaimed\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"depositor\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"shareMintAmount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DepositFeeCollected\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"depositor\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"fee\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DepositSubmitted\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"depositor\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DepositToStrategyFailure\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DepositToStrategySuccess\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"EmergencyDrainExecuted\",\"inputs\":[{\"name\":\"drainer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"EpochClaimable\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"EpochExecuting\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"EpochOpen\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"EpochWithdrawAmountShort\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"expectedAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"actualAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"InitialActiveProtocolAdapterSet\",\"inputs\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"adapter\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"LinkWithdrawn\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ManagementFeeCollected\",\"inputs\":[{\"name\":\"feeShares\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"OwnershipTransferred\",\"inputs\":[{\"name\":\"previousOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Paused\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PolicyEngineAttached\",\"inputs\":[{\"name\":\"policyEngine\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PolicyEngineDetachFailed\",\"inputs\":[{\"name\":\"policyEngine\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"reason\",\"type\":\"bytes\",\"indexed\":false,\"internalType\":\"bytes\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RebalanceCompleted\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RebalanceDepositFailure\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RebalanceDepositRecoveryCleared\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RebalanceDepositRecoveryStored\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RebalanceDepositSuccess\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RebalanceInitiated\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"chainSelector\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"},{\"name\":\"protocolId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RebalanceWithdrawFailure\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RebalanceWithdrawSuccess\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleAdminChanged\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"previousAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"newAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleGranted\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleRevoked\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TreasurySet\",\"inputs\":[{\"name\":\"treasury\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"CCIPBridged\",\"inputs\":[{\"name\":\"ccipMessageId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"ccipTxType\",\"type\":\"uint8\",\"indexed\":true,\"internalType\":\"enumTypes.CcipTx\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Unpaused\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"WithdrawCancelled\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"withdrawer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"WithdrawClaimed\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"withdrawer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"WithdrawFeeCollected\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"withdrawer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"fee\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"WithdrawFromStrategyFailure\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"WithdrawFromStrategySuccess\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"WithdrawSubmitted\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"withdrawer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"shareBurnAmount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"AccessControlBadConfirmation\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"AccessControlEnforcedDefaultAdminDelay\",\"inputs\":[{\"name\":\"schedule\",\"type\":\"uint48\",\"internalType\":\"uint48\"}]},{\"type\":\"error\",\"name\":\"AccessControlEnforcedDefaultAdminRules\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"AccessControlInvalidDefaultAdmin\",\"inputs\":[{\"name\":\"defaultAdmin\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"AccessControlUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"neededRole\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"BaseVault__DepositFailed\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"BaseVault__EmergencyDrainDelayNotMet\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"BaseVault__InvalidInputLengths\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"BaseVault__InvalidSender\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"srcChainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]},{\"type\":\"error\",\"name\":\"BaseVault__NoActiveAdapter\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"BaseVault__NoAdapterRegistered\",\"inputs\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"BaseVault__NoPendingRecovery\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"BaseVault__NoZeroAmount\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"BaseVault__OnlySelf\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"BaseVault__RecoveryAlreadyPending\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"BaseVault__WithdrawFailed\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"BaseVault__ZeroRecoveryAmount\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"EnforcedPause\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ExpectedPause\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidRouter\",\"inputs\":[{\"name\":\"router\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"OwnableInvalidOwner\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"OwnableUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ParentVault__AmountTooSmall\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ParentVault__EmptyEpoch\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ParentVault__EpochExecuting\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ParentVault__EpochNotClaimable\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ParentVault__EpochNotExecuting\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ParentVault__EpochNotOpen\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ParentVault__EpochTooShort\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ParentVault__InitialActiveProtocolAdapterAlreadySet\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ParentVault__InvalidRebalanceNonce\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ParentVault__NoDeposit\",\"inputs\":[{\"name\":\"depositor\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ParentVault__NoRebalanceInProgress\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ParentVault__NoWithdraw\",\"inputs\":[{\"name\":\"withdrawer\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ParentVault__NoZeroAmount\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ParentVault__RebalanceInProgress\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ParentVault__SameStrategy\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ParentVault__WithdrawFailed\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"PolicyEngineUndefined\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ReentrancyGuardReentrantCall\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SafeCastOverflowedUintDowncast\",\"inputs\":[{\"name\":\"bits\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"SafeERC20FailedOperation\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"}]}]",
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

type TypesEpoch struct {
	TotalDepositAmount       *big.Int
	TotalShareBurnAmount     *big.Int
	TotalWithdrawClaimAmount *big.Int
	PricePerShare            *big.Int
	OpenedAtTimestamp        *big.Int
	ClosedAtTimestamp        *big.Int
	Status                   uint8
}

type TypesRebalance struct {
	Nonce                           *big.Int
	State                           uint8
	ActiveStrategy                  TypesStrategy
	PendingStrategy                 TypesStrategy
	LastRebalanceInitiatedTimestamp *big.Int
	LastRebalanceCompletedTimestamp *big.Int
}

type TypesStrategy struct {
	ProtocolId    [32]byte
	ChainSelector uint64
}

// Contract Method Inputs
type AttachPolicyEngineInput struct {
	PolicyEngine common.Address
}

type BeginDefaultAdminTransferInput struct {
	NewAdmin common.Address
}

type CcipReceiveInput struct {
	Message ClientAny2EVMMessage
}

type ChangeDefaultAdminDelayInput struct {
	NewDelay *big.Int
}

type ClaimSharesInput struct {
	EpochNonce *big.Int
}

type ClaimUsdcInput struct {
	EpochNonce *big.Int
}

type CloseEpochInput struct {
	EpochNonce *big.Int
	Tvl        *big.Int
}

type CompleteRebalanceInput struct {
	RebalanceNonce *big.Int
}

type DepositInput struct {
	Amount *big.Int
}

type EmergencyDrainInput struct {
	RevertOnFailure bool
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

type GetDepositAmountInput struct {
	User       common.Address
	EpochNonce *big.Int
}

type GetEpochInput struct {
	EpochNonce *big.Int
}

type GetNetAmountAndOperationFeeInput struct {
	GrossAmount *big.Int
}

type GetRebalanceDepositRecoveryInput struct {
	RebalanceNonce *big.Int
}

type GetRoleAdminInput struct {
	Role [32]byte
}

type GetWithdrawShareBurnAmountInput struct {
	User       common.Address
	EpochNonce *big.Int
}

type GrantRoleInput struct {
	Role    [32]byte
	Account common.Address
}

type HasRoleInput struct {
	Role    [32]byte
	Account common.Address
}

type InitiateRebalanceInput struct {
	NewStrategy TypesStrategy
}

type RecoverFailedRebalanceDepositInput struct {
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

type SetContextInput struct {
	Context []byte
}

type SetCrosschainVaultsInput struct {
	ChainSelectors []uint64
	Vaults         []common.Address
}

type SetDefaultCcipGasLimitInput struct {
	GasLimit *big.Int
}

type SetInitialActiveProtocolAdapterInput struct {
	ProtocolId [32]byte
}

type SetTreasuryInput struct {
	Treasury common.Address
}

type SupportsInterfaceInput struct {
	InterfaceId [4]byte
}

type TransferOwnershipInput struct {
	NewOwner common.Address
}

type TryDepositToAdapterInput struct {
	Adapter common.Address
	Amount  *big.Int
}

type WithdrawInput struct {
	ShareBurnAmount *big.Int
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

type GetNetAmountAndOperationFeeOutput struct {
	NetAmount *big.Int
	FeeAmount *big.Int
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

type EnforcedPause struct {
}

type ExpectedPause struct {
}

type InvalidRouter struct {
	Router common.Address
}

type OwnableInvalidOwner struct {
	Owner common.Address
}

type OwnableUnauthorizedAccount struct {
	Account common.Address
}

type ParentVaultAmountTooSmall struct {
	Amount *big.Int
}

type ParentVaultEmptyEpoch struct {
	EpochNonce *big.Int
}

type ParentVaultEpochExecuting struct {
	EpochNonce *big.Int
}

type ParentVaultEpochNotClaimable struct {
	EpochNonce *big.Int
}

type ParentVaultEpochNotExecuting struct {
	EpochNonce *big.Int
}

type ParentVaultEpochNotOpen struct {
	EpochNonce *big.Int
}

type ParentVaultEpochTooShort struct {
	EpochNonce *big.Int
}

type ParentVaultInitialActiveProtocolAdapterAlreadySet struct {
}

type ParentVaultInvalidRebalanceNonce struct {
	RebalanceNonce *big.Int
}

type ParentVaultNoDeposit struct {
	Depositor  common.Address
	EpochNonce *big.Int
}

type ParentVaultNoRebalanceInProgress struct {
}

type ParentVaultNoWithdraw struct {
	Withdrawer common.Address
	EpochNonce *big.Int
}

type ParentVaultNoZeroAmount struct {
}

type ParentVaultRebalanceInProgress struct {
}

type ParentVaultSameStrategy struct {
}

type ParentVaultWithdrawFailed struct {
	EpochNonce *big.Int
	Amount     *big.Int
}

type PolicyEngineUndefined struct {
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

type CCIPBridgedTopics struct {
	CcipMessageId [32]byte
	Amount        *big.Int
	CcipTxType    uint8
}

type CCIPBridgedDecoded struct {
	CcipMessageId [32]byte
	Amount        *big.Int
	CcipTxType    uint8
}

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

type DepositCancelledTopics struct {
	EpochNonce *big.Int
	Depositor  common.Address
	Amount     *big.Int
}

type DepositCancelledDecoded struct {
	EpochNonce *big.Int
	Depositor  common.Address
	Amount     *big.Int
}

type DepositClaimedTopics struct {
	EpochNonce      *big.Int
	Depositor       common.Address
	ShareMintAmount *big.Int
}

type DepositClaimedDecoded struct {
	EpochNonce      *big.Int
	Depositor       common.Address
	ShareMintAmount *big.Int
}

type DepositFeeCollectedTopics struct {
	EpochNonce *big.Int
	Depositor  common.Address
	Fee        *big.Int
}

type DepositFeeCollectedDecoded struct {
	EpochNonce *big.Int
	Depositor  common.Address
	Fee        *big.Int
}

type DepositSubmittedTopics struct {
	EpochNonce *big.Int
	Depositor  common.Address
	Amount     *big.Int
}

type DepositSubmittedDecoded struct {
	EpochNonce *big.Int
	Depositor  common.Address
	Amount     *big.Int
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

type EpochClaimableTopics struct {
	EpochNonce *big.Int
}

type EpochClaimableDecoded struct {
	EpochNonce *big.Int
}

type EpochExecutingTopics struct {
	EpochNonce *big.Int
	Amount     *big.Int
}

type EpochExecutingDecoded struct {
	EpochNonce *big.Int
	Amount     *big.Int
}

type EpochOpenTopics struct {
	EpochNonce *big.Int
}

type EpochOpenDecoded struct {
	EpochNonce *big.Int
}

type EpochWithdrawAmountShortTopics struct {
	EpochNonce *big.Int
}

type EpochWithdrawAmountShortDecoded struct {
	EpochNonce     *big.Int
	ExpectedAmount *big.Int
	ActualAmount   *big.Int
}

type InitialActiveProtocolAdapterSetTopics struct {
	ProtocolId [32]byte
	Adapter    common.Address
}

type InitialActiveProtocolAdapterSetDecoded struct {
	ProtocolId [32]byte
	Adapter    common.Address
}

type LinkWithdrawnTopics struct {
	Operator common.Address
	Amount   *big.Int
}

type LinkWithdrawnDecoded struct {
	Operator common.Address
	Amount   *big.Int
}

type ManagementFeeCollectedTopics struct {
	FeeShares *big.Int
}

type ManagementFeeCollectedDecoded struct {
	FeeShares *big.Int
}

type OwnershipTransferredTopics struct {
	PreviousOwner common.Address
	NewOwner      common.Address
}

type OwnershipTransferredDecoded struct {
	PreviousOwner common.Address
	NewOwner      common.Address
}

type PausedTopics struct {
}

type PausedDecoded struct {
	Account common.Address
}

type PolicyEngineAttachedTopics struct {
	PolicyEngine common.Address
}

type PolicyEngineAttachedDecoded struct {
	PolicyEngine common.Address
}

type PolicyEngineDetachFailedTopics struct {
	PolicyEngine common.Address
}

type PolicyEngineDetachFailedDecoded struct {
	PolicyEngine common.Address
	Reason       []byte
}

type RebalanceCompletedTopics struct {
	RebalanceNonce *big.Int
}

type RebalanceCompletedDecoded struct {
	RebalanceNonce *big.Int
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

type RebalanceInitiatedTopics struct {
	RebalanceNonce *big.Int
	ChainSelector  uint64
	ProtocolId     [32]byte
}

type RebalanceInitiatedDecoded struct {
	RebalanceNonce *big.Int
	ChainSelector  uint64
	ProtocolId     [32]byte
}

type RebalanceWithdrawFailureTopics struct {
	RebalanceNonce *big.Int
}

type RebalanceWithdrawFailureDecoded struct {
	RebalanceNonce *big.Int
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

type TreasurySetTopics struct {
	Treasury common.Address
}

type TreasurySetDecoded struct {
	Treasury common.Address
}

type UnpausedTopics struct {
}

type UnpausedDecoded struct {
	Account common.Address
}

type WithdrawCancelledTopics struct {
	EpochNonce *big.Int
	Withdrawer common.Address
	Amount     *big.Int
}

type WithdrawCancelledDecoded struct {
	EpochNonce *big.Int
	Withdrawer common.Address
	Amount     *big.Int
}

type WithdrawClaimedTopics struct {
	EpochNonce *big.Int
	Withdrawer common.Address
	Amount     *big.Int
}

type WithdrawClaimedDecoded struct {
	EpochNonce *big.Int
	Withdrawer common.Address
	Amount     *big.Int
}

type WithdrawFeeCollectedTopics struct {
	EpochNonce *big.Int
	Withdrawer common.Address
	Fee        *big.Int
}

type WithdrawFeeCollectedDecoded struct {
	EpochNonce *big.Int
	Withdrawer common.Address
	Fee        *big.Int
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

type WithdrawSubmittedTopics struct {
	EpochNonce      *big.Int
	Withdrawer      common.Address
	ShareBurnAmount *big.Int
}

type WithdrawSubmittedDecoded struct {
	EpochNonce      *big.Int
	Withdrawer      common.Address
	ShareBurnAmount *big.Int
}

// Main Binding Type for ParentVault
type ParentVault struct {
	Address common.Address
	Options *bindings.ContractInitOptions
	ABI     *abi.ABI
	client  *evm.Client
	Codec   ParentVaultCodec
}

type ParentVaultCodec interface {
	EncodeDEFAULTADMINROLEMethodCall() ([]byte, error)
	DecodeDEFAULTADMINROLEMethodOutput(data []byte) ([32]byte, error)
	EncodeAcceptDefaultAdminTransferMethodCall() ([]byte, error)
	EncodeAttachPolicyEngineMethodCall(in AttachPolicyEngineInput) ([]byte, error)
	EncodeBeginDefaultAdminTransferMethodCall(in BeginDefaultAdminTransferInput) ([]byte, error)
	EncodeCancelDefaultAdminTransferMethodCall() ([]byte, error)
	EncodeCancelDepositMethodCall() ([]byte, error)
	EncodeCancelWithdrawMethodCall() ([]byte, error)
	EncodeCcipReceiveMethodCall(in CcipReceiveInput) ([]byte, error)
	EncodeChangeDefaultAdminDelayMethodCall(in ChangeDefaultAdminDelayInput) ([]byte, error)
	EncodeClaimSharesMethodCall(in ClaimSharesInput) ([]byte, error)
	DecodeClaimSharesMethodOutput(data []byte) (*big.Int, error)
	EncodeClaimUsdcMethodCall(in ClaimUsdcInput) ([]byte, error)
	DecodeClaimUsdcMethodOutput(data []byte) (*big.Int, error)
	EncodeClearContextMethodCall() ([]byte, error)
	EncodeCloseEpochMethodCall(in CloseEpochInput) ([]byte, error)
	EncodeCompleteRebalanceMethodCall(in CompleteRebalanceInput) ([]byte, error)
	EncodeDefaultAdminMethodCall() ([]byte, error)
	DecodeDefaultAdminMethodOutput(data []byte) (common.Address, error)
	EncodeDefaultAdminDelayMethodCall() ([]byte, error)
	DecodeDefaultAdminDelayMethodOutput(data []byte) (*big.Int, error)
	EncodeDefaultAdminDelayIncreaseWaitMethodCall() ([]byte, error)
	DecodeDefaultAdminDelayIncreaseWaitMethodOutput(data []byte) (*big.Int, error)
	EncodeDepositMethodCall(in DepositInput) ([]byte, error)
	DecodeDepositMethodOutput(data []byte) (*big.Int, error)
	EncodeEmergencyDrainMethodCall(in EmergencyDrainInput) ([]byte, error)
	EncodeGetActiveProtocolAdapterMethodCall() ([]byte, error)
	DecodeGetActiveProtocolAdapterMethodOutput(data []byte) (common.Address, error)
	EncodeGetAdapterRegistryMethodCall() ([]byte, error)
	DecodeGetAdapterRegistryMethodOutput(data []byte) (common.Address, error)
	EncodeGetCCVsAndFinalityConfigMethodCall(in GetCCVsAndFinalityConfigInput) ([]byte, error)
	DecodeGetCCVsAndFinalityConfigMethodOutput(data []byte) (GetCCVsAndFinalityConfigOutput, error)
	EncodeGetCcipGasLimitMethodCall(in GetCcipGasLimitInput) ([]byte, error)
	DecodeGetCcipGasLimitMethodOutput(data []byte) (*big.Int, error)
	EncodeGetContextMethodCall() ([]byte, error)
	DecodeGetContextMethodOutput(data []byte) ([]byte, error)
	EncodeGetCrosschainVaultMethodCall(in GetCrosschainVaultInput) ([]byte, error)
	DecodeGetCrosschainVaultMethodOutput(data []byte) (common.Address, error)
	EncodeGetDefaultCcipGasLimitMethodCall() ([]byte, error)
	DecodeGetDefaultCcipGasLimitMethodOutput(data []byte) (*big.Int, error)
	EncodeGetDepositAmountMethodCall(in GetDepositAmountInput) ([]byte, error)
	DecodeGetDepositAmountMethodOutput(data []byte) (*big.Int, error)
	EncodeGetEpochMethodCall(in GetEpochInput) ([]byte, error)
	DecodeGetEpochMethodOutput(data []byte) (TypesEpoch, error)
	EncodeGetEpochNonceMethodCall() ([]byte, error)
	DecodeGetEpochNonceMethodOutput(data []byte) (*big.Int, error)
	EncodeGetInitialActiveProtocolAdapterSetMethodCall() ([]byte, error)
	DecodeGetInitialActiveProtocolAdapterSetMethodOutput(data []byte) (bool, error)
	EncodeGetLinkMethodCall() ([]byte, error)
	DecodeGetLinkMethodOutput(data []byte) (common.Address, error)
	EncodeGetNetAmountAndOperationFeeMethodCall(in GetNetAmountAndOperationFeeInput) ([]byte, error)
	DecodeGetNetAmountAndOperationFeeMethodOutput(data []byte) (GetNetAmountAndOperationFeeOutput, error)
	EncodeGetPausedAtMethodCall() ([]byte, error)
	DecodeGetPausedAtMethodOutput(data []byte) (*big.Int, error)
	EncodeGetPolicyEngineMethodCall() ([]byte, error)
	DecodeGetPolicyEngineMethodOutput(data []byte) (common.Address, error)
	EncodeGetRebalanceMethodCall() ([]byte, error)
	DecodeGetRebalanceMethodOutput(data []byte) (TypesRebalance, error)
	EncodeGetRebalanceDepositRecoveryMethodCall(in GetRebalanceDepositRecoveryInput) ([]byte, error)
	DecodeGetRebalanceDepositRecoveryMethodOutput(data []byte) (TypesAmountRecovery, error)
	EncodeGetRoleAdminMethodCall(in GetRoleAdminInput) ([]byte, error)
	DecodeGetRoleAdminMethodOutput(data []byte) ([32]byte, error)
	EncodeGetRouterMethodCall() ([]byte, error)
	DecodeGetRouterMethodOutput(data []byte) (common.Address, error)
	EncodeGetShareMethodCall() ([]byte, error)
	DecodeGetShareMethodOutput(data []byte) (common.Address, error)
	EncodeGetTVLMethodCall() ([]byte, error)
	DecodeGetTVLMethodOutput(data []byte) (*big.Int, error)
	EncodeGetThisChainSelectorMethodCall() ([]byte, error)
	DecodeGetThisChainSelectorMethodOutput(data []byte) (uint64, error)
	EncodeGetTotalSharesMethodCall() ([]byte, error)
	DecodeGetTotalSharesMethodOutput(data []byte) (*big.Int, error)
	EncodeGetTreasuryMethodCall() ([]byte, error)
	DecodeGetTreasuryMethodOutput(data []byte) (common.Address, error)
	EncodeGetUsdcMethodCall() ([]byte, error)
	DecodeGetUsdcMethodOutput(data []byte) (common.Address, error)
	EncodeGetWithdrawShareBurnAmountMethodCall(in GetWithdrawShareBurnAmountInput) ([]byte, error)
	DecodeGetWithdrawShareBurnAmountMethodOutput(data []byte) (*big.Int, error)
	EncodeGrantRoleMethodCall(in GrantRoleInput) ([]byte, error)
	EncodeHasRoleMethodCall(in HasRoleInput) ([]byte, error)
	DecodeHasRoleMethodOutput(data []byte) (bool, error)
	EncodeInitiateRebalanceMethodCall(in InitiateRebalanceInput) ([]byte, error)
	EncodeOwnerMethodCall() ([]byte, error)
	DecodeOwnerMethodOutput(data []byte) (common.Address, error)
	EncodePauseMethodCall() ([]byte, error)
	EncodePausedMethodCall() ([]byte, error)
	DecodePausedMethodOutput(data []byte) (bool, error)
	EncodePendingDefaultAdminMethodCall() ([]byte, error)
	DecodePendingDefaultAdminMethodOutput(data []byte) (PendingDefaultAdminOutput, error)
	EncodePendingDefaultAdminDelayMethodCall() ([]byte, error)
	DecodePendingDefaultAdminDelayMethodOutput(data []byte) (PendingDefaultAdminDelayOutput, error)
	EncodeRecoverFailedRebalanceDepositMethodCall(in RecoverFailedRebalanceDepositInput) ([]byte, error)
	EncodeRenounceOwnershipMethodCall() ([]byte, error)
	EncodeRenounceRoleMethodCall(in RenounceRoleInput) ([]byte, error)
	EncodeRevokeRoleMethodCall(in RevokeRoleInput) ([]byte, error)
	EncodeRollbackDefaultAdminDelayMethodCall() ([]byte, error)
	EncodeSetCcipGasLimitMethodCall(in SetCcipGasLimitInput) ([]byte, error)
	EncodeSetContextMethodCall(in SetContextInput) ([]byte, error)
	EncodeSetCrosschainVaultsMethodCall(in SetCrosschainVaultsInput) ([]byte, error)
	EncodeSetDefaultCcipGasLimitMethodCall(in SetDefaultCcipGasLimitInput) ([]byte, error)
	EncodeSetInitialActiveProtocolAdapterMethodCall(in SetInitialActiveProtocolAdapterInput) ([]byte, error)
	EncodeSetTreasuryMethodCall(in SetTreasuryInput) ([]byte, error)
	EncodeSupportsInterfaceMethodCall(in SupportsInterfaceInput) ([]byte, error)
	DecodeSupportsInterfaceMethodOutput(data []byte) (bool, error)
	EncodeTransferOwnershipMethodCall(in TransferOwnershipInput) ([]byte, error)
	EncodeTryDepositToAdapterMethodCall(in TryDepositToAdapterInput) ([]byte, error)
	EncodeUnpauseMethodCall() ([]byte, error)
	EncodeWithdrawMethodCall(in WithdrawInput) ([]byte, error)
	DecodeWithdrawMethodOutput(data []byte) (*big.Int, error)
	EncodeWithdrawLinkMethodCall(in WithdrawLinkInput) ([]byte, error)
	EncodeBaseVaultConstructorParamsStruct(in BaseVaultConstructorParams) ([]byte, error)
	EncodeClientAny2EVMMessageStruct(in ClientAny2EVMMessage) ([]byte, error)
	EncodeClientEVMTokenAmountStruct(in ClientEVMTokenAmount) ([]byte, error)
	EncodeTypesAmountRecoveryStruct(in TypesAmountRecovery) ([]byte, error)
	EncodeTypesEpochStruct(in TypesEpoch) ([]byte, error)
	EncodeTypesRebalanceStruct(in TypesRebalance) ([]byte, error)
	EncodeTypesStrategyStruct(in TypesStrategy) ([]byte, error)
	CCIPBridgedLogHash() []byte
	EncodeCCIPBridgedTopics(evt abi.Event, values []CCIPBridgedTopics) ([]*evm.TopicValues, error)
	DecodeCCIPBridged(log *evm.Log) (*CCIPBridgedDecoded, error)
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
	DepositCancelledLogHash() []byte
	EncodeDepositCancelledTopics(evt abi.Event, values []DepositCancelledTopics) ([]*evm.TopicValues, error)
	DecodeDepositCancelled(log *evm.Log) (*DepositCancelledDecoded, error)
	DepositClaimedLogHash() []byte
	EncodeDepositClaimedTopics(evt abi.Event, values []DepositClaimedTopics) ([]*evm.TopicValues, error)
	DecodeDepositClaimed(log *evm.Log) (*DepositClaimedDecoded, error)
	DepositFeeCollectedLogHash() []byte
	EncodeDepositFeeCollectedTopics(evt abi.Event, values []DepositFeeCollectedTopics) ([]*evm.TopicValues, error)
	DecodeDepositFeeCollected(log *evm.Log) (*DepositFeeCollectedDecoded, error)
	DepositSubmittedLogHash() []byte
	EncodeDepositSubmittedTopics(evt abi.Event, values []DepositSubmittedTopics) ([]*evm.TopicValues, error)
	DecodeDepositSubmitted(log *evm.Log) (*DepositSubmittedDecoded, error)
	DepositToStrategyFailureLogHash() []byte
	EncodeDepositToStrategyFailureTopics(evt abi.Event, values []DepositToStrategyFailureTopics) ([]*evm.TopicValues, error)
	DecodeDepositToStrategyFailure(log *evm.Log) (*DepositToStrategyFailureDecoded, error)
	DepositToStrategySuccessLogHash() []byte
	EncodeDepositToStrategySuccessTopics(evt abi.Event, values []DepositToStrategySuccessTopics) ([]*evm.TopicValues, error)
	DecodeDepositToStrategySuccess(log *evm.Log) (*DepositToStrategySuccessDecoded, error)
	EmergencyDrainExecutedLogHash() []byte
	EncodeEmergencyDrainExecutedTopics(evt abi.Event, values []EmergencyDrainExecutedTopics) ([]*evm.TopicValues, error)
	DecodeEmergencyDrainExecuted(log *evm.Log) (*EmergencyDrainExecutedDecoded, error)
	EpochClaimableLogHash() []byte
	EncodeEpochClaimableTopics(evt abi.Event, values []EpochClaimableTopics) ([]*evm.TopicValues, error)
	DecodeEpochClaimable(log *evm.Log) (*EpochClaimableDecoded, error)
	EpochExecutingLogHash() []byte
	EncodeEpochExecutingTopics(evt abi.Event, values []EpochExecutingTopics) ([]*evm.TopicValues, error)
	DecodeEpochExecuting(log *evm.Log) (*EpochExecutingDecoded, error)
	EpochOpenLogHash() []byte
	EncodeEpochOpenTopics(evt abi.Event, values []EpochOpenTopics) ([]*evm.TopicValues, error)
	DecodeEpochOpen(log *evm.Log) (*EpochOpenDecoded, error)
	EpochWithdrawAmountShortLogHash() []byte
	EncodeEpochWithdrawAmountShortTopics(evt abi.Event, values []EpochWithdrawAmountShortTopics) ([]*evm.TopicValues, error)
	DecodeEpochWithdrawAmountShort(log *evm.Log) (*EpochWithdrawAmountShortDecoded, error)
	InitialActiveProtocolAdapterSetLogHash() []byte
	EncodeInitialActiveProtocolAdapterSetTopics(evt abi.Event, values []InitialActiveProtocolAdapterSetTopics) ([]*evm.TopicValues, error)
	DecodeInitialActiveProtocolAdapterSet(log *evm.Log) (*InitialActiveProtocolAdapterSetDecoded, error)
	LinkWithdrawnLogHash() []byte
	EncodeLinkWithdrawnTopics(evt abi.Event, values []LinkWithdrawnTopics) ([]*evm.TopicValues, error)
	DecodeLinkWithdrawn(log *evm.Log) (*LinkWithdrawnDecoded, error)
	ManagementFeeCollectedLogHash() []byte
	EncodeManagementFeeCollectedTopics(evt abi.Event, values []ManagementFeeCollectedTopics) ([]*evm.TopicValues, error)
	DecodeManagementFeeCollected(log *evm.Log) (*ManagementFeeCollectedDecoded, error)
	OwnershipTransferredLogHash() []byte
	EncodeOwnershipTransferredTopics(evt abi.Event, values []OwnershipTransferredTopics) ([]*evm.TopicValues, error)
	DecodeOwnershipTransferred(log *evm.Log) (*OwnershipTransferredDecoded, error)
	PausedLogHash() []byte
	EncodePausedTopics(evt abi.Event, values []PausedTopics) ([]*evm.TopicValues, error)
	DecodePaused(log *evm.Log) (*PausedDecoded, error)
	PolicyEngineAttachedLogHash() []byte
	EncodePolicyEngineAttachedTopics(evt abi.Event, values []PolicyEngineAttachedTopics) ([]*evm.TopicValues, error)
	DecodePolicyEngineAttached(log *evm.Log) (*PolicyEngineAttachedDecoded, error)
	PolicyEngineDetachFailedLogHash() []byte
	EncodePolicyEngineDetachFailedTopics(evt abi.Event, values []PolicyEngineDetachFailedTopics) ([]*evm.TopicValues, error)
	DecodePolicyEngineDetachFailed(log *evm.Log) (*PolicyEngineDetachFailedDecoded, error)
	RebalanceCompletedLogHash() []byte
	EncodeRebalanceCompletedTopics(evt abi.Event, values []RebalanceCompletedTopics) ([]*evm.TopicValues, error)
	DecodeRebalanceCompleted(log *evm.Log) (*RebalanceCompletedDecoded, error)
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
	RebalanceInitiatedLogHash() []byte
	EncodeRebalanceInitiatedTopics(evt abi.Event, values []RebalanceInitiatedTopics) ([]*evm.TopicValues, error)
	DecodeRebalanceInitiated(log *evm.Log) (*RebalanceInitiatedDecoded, error)
	RebalanceWithdrawFailureLogHash() []byte
	EncodeRebalanceWithdrawFailureTopics(evt abi.Event, values []RebalanceWithdrawFailureTopics) ([]*evm.TopicValues, error)
	DecodeRebalanceWithdrawFailure(log *evm.Log) (*RebalanceWithdrawFailureDecoded, error)
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
	TreasurySetLogHash() []byte
	EncodeTreasurySetTopics(evt abi.Event, values []TreasurySetTopics) ([]*evm.TopicValues, error)
	DecodeTreasurySet(log *evm.Log) (*TreasurySetDecoded, error)
	UnpausedLogHash() []byte
	EncodeUnpausedTopics(evt abi.Event, values []UnpausedTopics) ([]*evm.TopicValues, error)
	DecodeUnpaused(log *evm.Log) (*UnpausedDecoded, error)
	WithdrawCancelledLogHash() []byte
	EncodeWithdrawCancelledTopics(evt abi.Event, values []WithdrawCancelledTopics) ([]*evm.TopicValues, error)
	DecodeWithdrawCancelled(log *evm.Log) (*WithdrawCancelledDecoded, error)
	WithdrawClaimedLogHash() []byte
	EncodeWithdrawClaimedTopics(evt abi.Event, values []WithdrawClaimedTopics) ([]*evm.TopicValues, error)
	DecodeWithdrawClaimed(log *evm.Log) (*WithdrawClaimedDecoded, error)
	WithdrawFeeCollectedLogHash() []byte
	EncodeWithdrawFeeCollectedTopics(evt abi.Event, values []WithdrawFeeCollectedTopics) ([]*evm.TopicValues, error)
	DecodeWithdrawFeeCollected(log *evm.Log) (*WithdrawFeeCollectedDecoded, error)
	WithdrawFromStrategyFailureLogHash() []byte
	EncodeWithdrawFromStrategyFailureTopics(evt abi.Event, values []WithdrawFromStrategyFailureTopics) ([]*evm.TopicValues, error)
	DecodeWithdrawFromStrategyFailure(log *evm.Log) (*WithdrawFromStrategyFailureDecoded, error)
	WithdrawFromStrategySuccessLogHash() []byte
	EncodeWithdrawFromStrategySuccessTopics(evt abi.Event, values []WithdrawFromStrategySuccessTopics) ([]*evm.TopicValues, error)
	DecodeWithdrawFromStrategySuccess(log *evm.Log) (*WithdrawFromStrategySuccessDecoded, error)
	WithdrawSubmittedLogHash() []byte
	EncodeWithdrawSubmittedTopics(evt abi.Event, values []WithdrawSubmittedTopics) ([]*evm.TopicValues, error)
	DecodeWithdrawSubmitted(log *evm.Log) (*WithdrawSubmittedDecoded, error)
}

func NewParentVault(
	client *evm.Client,
	address common.Address,
	options *bindings.ContractInitOptions,
) (*ParentVault, error) {
	parsed, err := abi.JSON(strings.NewReader(ParentVaultMetaData.ABI))
	if err != nil {
		return nil, err
	}
	codec, err := NewCodec()
	if err != nil {
		return nil, err
	}
	return &ParentVault{
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

func NewCodec() (ParentVaultCodec, error) {
	parsed, err := abi.JSON(strings.NewReader(ParentVaultMetaData.ABI))
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

func (c *Codec) EncodeAttachPolicyEngineMethodCall(in AttachPolicyEngineInput) ([]byte, error) {
	return c.abi.Pack("attachPolicyEngine", in.PolicyEngine)
}

func (c *Codec) EncodeBeginDefaultAdminTransferMethodCall(in BeginDefaultAdminTransferInput) ([]byte, error) {
	return c.abi.Pack("beginDefaultAdminTransfer", in.NewAdmin)
}

func (c *Codec) EncodeCancelDefaultAdminTransferMethodCall() ([]byte, error) {
	return c.abi.Pack("cancelDefaultAdminTransfer")
}

func (c *Codec) EncodeCancelDepositMethodCall() ([]byte, error) {
	return c.abi.Pack("cancelDeposit")
}

func (c *Codec) EncodeCancelWithdrawMethodCall() ([]byte, error) {
	return c.abi.Pack("cancelWithdraw")
}

func (c *Codec) EncodeCcipReceiveMethodCall(in CcipReceiveInput) ([]byte, error) {
	return c.abi.Pack("ccipReceive", in.Message)
}

func (c *Codec) EncodeChangeDefaultAdminDelayMethodCall(in ChangeDefaultAdminDelayInput) ([]byte, error) {
	return c.abi.Pack("changeDefaultAdminDelay", in.NewDelay)
}

func (c *Codec) EncodeClaimSharesMethodCall(in ClaimSharesInput) ([]byte, error) {
	return c.abi.Pack("claimShares", in.EpochNonce)
}

func (c *Codec) DecodeClaimSharesMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["claimShares"].Outputs.Unpack(data)
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

func (c *Codec) EncodeClaimUsdcMethodCall(in ClaimUsdcInput) ([]byte, error) {
	return c.abi.Pack("claimUsdc", in.EpochNonce)
}

func (c *Codec) DecodeClaimUsdcMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["claimUsdc"].Outputs.Unpack(data)
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

func (c *Codec) EncodeClearContextMethodCall() ([]byte, error) {
	return c.abi.Pack("clearContext")
}

func (c *Codec) EncodeCloseEpochMethodCall(in CloseEpochInput) ([]byte, error) {
	return c.abi.Pack("closeEpoch", in.EpochNonce, in.Tvl)
}

func (c *Codec) EncodeCompleteRebalanceMethodCall(in CompleteRebalanceInput) ([]byte, error) {
	return c.abi.Pack("completeRebalance", in.RebalanceNonce)
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

func (c *Codec) EncodeDepositMethodCall(in DepositInput) ([]byte, error) {
	return c.abi.Pack("deposit", in.Amount)
}

func (c *Codec) DecodeDepositMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["deposit"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetContextMethodCall() ([]byte, error) {
	return c.abi.Pack("getContext")
}

func (c *Codec) DecodeGetContextMethodOutput(data []byte) ([]byte, error) {
	vals, err := c.abi.Methods["getContext"].Outputs.Unpack(data)
	if err != nil {
		return *new([]byte), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new([]byte), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result []byte
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new([]byte), fmt.Errorf("failed to unmarshal to []byte: %w", err)
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

func (c *Codec) EncodeGetDepositAmountMethodCall(in GetDepositAmountInput) ([]byte, error) {
	return c.abi.Pack("getDepositAmount", in.User, in.EpochNonce)
}

func (c *Codec) DecodeGetDepositAmountMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getDepositAmount"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetEpochMethodCall(in GetEpochInput) ([]byte, error) {
	return c.abi.Pack("getEpoch", in.EpochNonce)
}

func (c *Codec) DecodeGetEpochMethodOutput(data []byte) (TypesEpoch, error) {
	vals, err := c.abi.Methods["getEpoch"].Outputs.Unpack(data)
	if err != nil {
		return *new(TypesEpoch), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(TypesEpoch), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result TypesEpoch
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(TypesEpoch), fmt.Errorf("failed to unmarshal to TypesEpoch: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetEpochNonceMethodCall() ([]byte, error) {
	return c.abi.Pack("getEpochNonce")
}

func (c *Codec) DecodeGetEpochNonceMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getEpochNonce"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetInitialActiveProtocolAdapterSetMethodCall() ([]byte, error) {
	return c.abi.Pack("getInitialActiveProtocolAdapterSet")
}

func (c *Codec) DecodeGetInitialActiveProtocolAdapterSetMethodOutput(data []byte) (bool, error) {
	vals, err := c.abi.Methods["getInitialActiveProtocolAdapterSet"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetNetAmountAndOperationFeeMethodCall(in GetNetAmountAndOperationFeeInput) ([]byte, error) {
	return c.abi.Pack("getNetAmountAndOperationFee", in.GrossAmount)
}

func (c *Codec) DecodeGetNetAmountAndOperationFeeMethodOutput(data []byte) (GetNetAmountAndOperationFeeOutput, error) {
	vals, err := c.abi.Methods["getNetAmountAndOperationFee"].Outputs.Unpack(data)
	if err != nil {
		return GetNetAmountAndOperationFeeOutput{}, err
	}
	if len(vals) != 2 {
		return GetNetAmountAndOperationFeeOutput{}, fmt.Errorf("expected 2 values, got %d", len(vals))
	}
	jsonData0, err := json.Marshal(vals[0])
	if err != nil {
		return GetNetAmountAndOperationFeeOutput{}, fmt.Errorf("failed to marshal ABI result 0: %w", err)
	}

	var result0 *big.Int
	if err := json.Unmarshal(jsonData0, &result0); err != nil {
		return GetNetAmountAndOperationFeeOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData1, err := json.Marshal(vals[1])
	if err != nil {
		return GetNetAmountAndOperationFeeOutput{}, fmt.Errorf("failed to marshal ABI result 1: %w", err)
	}

	var result1 *big.Int
	if err := json.Unmarshal(jsonData1, &result1); err != nil {
		return GetNetAmountAndOperationFeeOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}

	return GetNetAmountAndOperationFeeOutput{
		NetAmount: result0,
		FeeAmount: result1,
	}, nil
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

func (c *Codec) EncodeGetPolicyEngineMethodCall() ([]byte, error) {
	return c.abi.Pack("getPolicyEngine")
}

func (c *Codec) DecodeGetPolicyEngineMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getPolicyEngine"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetRebalanceMethodCall() ([]byte, error) {
	return c.abi.Pack("getRebalance")
}

func (c *Codec) DecodeGetRebalanceMethodOutput(data []byte) (TypesRebalance, error) {
	vals, err := c.abi.Methods["getRebalance"].Outputs.Unpack(data)
	if err != nil {
		return *new(TypesRebalance), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(TypesRebalance), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result TypesRebalance
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(TypesRebalance), fmt.Errorf("failed to unmarshal to TypesRebalance: %w", err)
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

func (c *Codec) EncodeGetShareMethodCall() ([]byte, error) {
	return c.abi.Pack("getShare")
}

func (c *Codec) DecodeGetShareMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getShare"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetTotalSharesMethodCall() ([]byte, error) {
	return c.abi.Pack("getTotalShares")
}

func (c *Codec) DecodeGetTotalSharesMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getTotalShares"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetTreasuryMethodCall() ([]byte, error) {
	return c.abi.Pack("getTreasury")
}

func (c *Codec) DecodeGetTreasuryMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getTreasury"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetWithdrawShareBurnAmountMethodCall(in GetWithdrawShareBurnAmountInput) ([]byte, error) {
	return c.abi.Pack("getWithdrawShareBurnAmount", in.User, in.EpochNonce)
}

func (c *Codec) DecodeGetWithdrawShareBurnAmountMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getWithdrawShareBurnAmount"].Outputs.Unpack(data)
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

func (c *Codec) EncodeInitiateRebalanceMethodCall(in InitiateRebalanceInput) ([]byte, error) {
	return c.abi.Pack("initiateRebalance", in.NewStrategy)
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

func (c *Codec) EncodeRecoverFailedRebalanceDepositMethodCall(in RecoverFailedRebalanceDepositInput) ([]byte, error) {
	return c.abi.Pack("recoverFailedRebalanceDeposit", in.RebalanceNonce)
}

func (c *Codec) EncodeRenounceOwnershipMethodCall() ([]byte, error) {
	return c.abi.Pack("renounceOwnership")
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

func (c *Codec) EncodeSetContextMethodCall(in SetContextInput) ([]byte, error) {
	return c.abi.Pack("setContext", in.Context)
}

func (c *Codec) EncodeSetCrosschainVaultsMethodCall(in SetCrosschainVaultsInput) ([]byte, error) {
	return c.abi.Pack("setCrosschainVaults", in.ChainSelectors, in.Vaults)
}

func (c *Codec) EncodeSetDefaultCcipGasLimitMethodCall(in SetDefaultCcipGasLimitInput) ([]byte, error) {
	return c.abi.Pack("setDefaultCcipGasLimit", in.GasLimit)
}

func (c *Codec) EncodeSetInitialActiveProtocolAdapterMethodCall(in SetInitialActiveProtocolAdapterInput) ([]byte, error) {
	return c.abi.Pack("setInitialActiveProtocolAdapter", in.ProtocolId)
}

func (c *Codec) EncodeSetTreasuryMethodCall(in SetTreasuryInput) ([]byte, error) {
	return c.abi.Pack("setTreasury", in.Treasury)
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

func (c *Codec) EncodeTransferOwnershipMethodCall(in TransferOwnershipInput) ([]byte, error) {
	return c.abi.Pack("transferOwnership", in.NewOwner)
}

func (c *Codec) EncodeTryDepositToAdapterMethodCall(in TryDepositToAdapterInput) ([]byte, error) {
	return c.abi.Pack("tryDepositToAdapter", in.Adapter, in.Amount)
}

func (c *Codec) EncodeUnpauseMethodCall() ([]byte, error) {
	return c.abi.Pack("unpause")
}

func (c *Codec) EncodeWithdrawMethodCall(in WithdrawInput) ([]byte, error) {
	return c.abi.Pack("withdraw", in.ShareBurnAmount)
}

func (c *Codec) DecodeWithdrawMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["withdraw"].Outputs.Unpack(data)
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
func (c *Codec) EncodeTypesEpochStruct(in TypesEpoch) ([]byte, error) {
	tupleType, err := abi.NewType(
		"tuple", "",
		[]abi.ArgumentMarshaling{
			{Name: "totalDepositAmount", Type: "uint256"},
			{Name: "totalShareBurnAmount", Type: "uint256"},
			{Name: "totalWithdrawClaimAmount", Type: "uint256"},
			{Name: "pricePerShare", Type: "uint256"},
			{Name: "openedAtTimestamp", Type: "uint256"},
			{Name: "closedAtTimestamp", Type: "uint256"},
			{Name: "status", Type: "uint8"},
		},
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create tuple type for TypesEpoch: %w", err)
	}
	args := abi.Arguments{
		{Name: "typesEpoch", Type: tupleType},
	}

	return args.Pack(in)
}
func (c *Codec) EncodeTypesRebalanceStruct(in TypesRebalance) ([]byte, error) {
	tupleType, err := abi.NewType(
		"tuple", "",
		[]abi.ArgumentMarshaling{
			{Name: "nonce", Type: "uint256"},
			{Name: "state", Type: "uint8"},
			{Name: "activeStrategy", Type: "(bytes32,uint64)"},
			{Name: "pendingStrategy", Type: "(bytes32,uint64)"},
			{Name: "lastRebalanceInitiatedTimestamp", Type: "uint256"},
			{Name: "lastRebalanceCompletedTimestamp", Type: "uint256"},
		},
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create tuple type for TypesRebalance: %w", err)
	}
	args := abi.Arguments{
		{Name: "typesRebalance", Type: tupleType},
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

func (c *Codec) CCIPBridgedLogHash() []byte {
	return c.abi.Events["CCIPBridged"].ID.Bytes()
}

func (c *Codec) EncodeCCIPBridgedTopics(
	evt abi.Event,
	values []CCIPBridgedTopics,
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

// DecodeCCIPBridged decodes a log into a CCIPBridged struct.
func (c *Codec) DecodeCCIPBridged(log *evm.Log) (*CCIPBridgedDecoded, error) {
	event := new(CCIPBridgedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "CCIPBridged", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["CCIPBridged"].Inputs {
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

func (c *Codec) DepositCancelledLogHash() []byte {
	return c.abi.Events["DepositCancelled"].ID.Bytes()
}

func (c *Codec) EncodeDepositCancelledTopics(
	evt abi.Event,
	values []DepositCancelledTopics,
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
	var depositorRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Depositor).IsZero() {
			depositorRule = append(depositorRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Depositor)
		if err != nil {
			return nil, err
		}
		depositorRule = append(depositorRule, fieldVal)
	}
	var amountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Amount).IsZero() {
			amountRule = append(amountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.Amount)
		if err != nil {
			return nil, err
		}
		amountRule = append(amountRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		epochNonceRule,
		depositorRule,
		amountRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeDepositCancelled decodes a log into a DepositCancelled struct.
func (c *Codec) DecodeDepositCancelled(log *evm.Log) (*DepositCancelledDecoded, error) {
	event := new(DepositCancelledDecoded)
	if err := c.abi.UnpackIntoInterface(event, "DepositCancelled", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["DepositCancelled"].Inputs {
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

func (c *Codec) DepositClaimedLogHash() []byte {
	return c.abi.Events["DepositClaimed"].ID.Bytes()
}

func (c *Codec) EncodeDepositClaimedTopics(
	evt abi.Event,
	values []DepositClaimedTopics,
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
	var depositorRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Depositor).IsZero() {
			depositorRule = append(depositorRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Depositor)
		if err != nil {
			return nil, err
		}
		depositorRule = append(depositorRule, fieldVal)
	}
	var shareMintAmountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ShareMintAmount).IsZero() {
			shareMintAmountRule = append(shareMintAmountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.ShareMintAmount)
		if err != nil {
			return nil, err
		}
		shareMintAmountRule = append(shareMintAmountRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		epochNonceRule,
		depositorRule,
		shareMintAmountRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeDepositClaimed decodes a log into a DepositClaimed struct.
func (c *Codec) DecodeDepositClaimed(log *evm.Log) (*DepositClaimedDecoded, error) {
	event := new(DepositClaimedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "DepositClaimed", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["DepositClaimed"].Inputs {
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

func (c *Codec) DepositFeeCollectedLogHash() []byte {
	return c.abi.Events["DepositFeeCollected"].ID.Bytes()
}

func (c *Codec) EncodeDepositFeeCollectedTopics(
	evt abi.Event,
	values []DepositFeeCollectedTopics,
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
	var depositorRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Depositor).IsZero() {
			depositorRule = append(depositorRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Depositor)
		if err != nil {
			return nil, err
		}
		depositorRule = append(depositorRule, fieldVal)
	}
	var feeRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Fee).IsZero() {
			feeRule = append(feeRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.Fee)
		if err != nil {
			return nil, err
		}
		feeRule = append(feeRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		epochNonceRule,
		depositorRule,
		feeRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeDepositFeeCollected decodes a log into a DepositFeeCollected struct.
func (c *Codec) DecodeDepositFeeCollected(log *evm.Log) (*DepositFeeCollectedDecoded, error) {
	event := new(DepositFeeCollectedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "DepositFeeCollected", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["DepositFeeCollected"].Inputs {
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

func (c *Codec) DepositSubmittedLogHash() []byte {
	return c.abi.Events["DepositSubmitted"].ID.Bytes()
}

func (c *Codec) EncodeDepositSubmittedTopics(
	evt abi.Event,
	values []DepositSubmittedTopics,
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
	var depositorRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Depositor).IsZero() {
			depositorRule = append(depositorRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Depositor)
		if err != nil {
			return nil, err
		}
		depositorRule = append(depositorRule, fieldVal)
	}
	var amountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Amount).IsZero() {
			amountRule = append(amountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.Amount)
		if err != nil {
			return nil, err
		}
		amountRule = append(amountRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		epochNonceRule,
		depositorRule,
		amountRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeDepositSubmitted decodes a log into a DepositSubmitted struct.
func (c *Codec) DecodeDepositSubmitted(log *evm.Log) (*DepositSubmittedDecoded, error) {
	event := new(DepositSubmittedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "DepositSubmitted", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["DepositSubmitted"].Inputs {
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

func (c *Codec) EpochClaimableLogHash() []byte {
	return c.abi.Events["EpochClaimable"].ID.Bytes()
}

func (c *Codec) EncodeEpochClaimableTopics(
	evt abi.Event,
	values []EpochClaimableTopics,
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

// DecodeEpochClaimable decodes a log into a EpochClaimable struct.
func (c *Codec) DecodeEpochClaimable(log *evm.Log) (*EpochClaimableDecoded, error) {
	event := new(EpochClaimableDecoded)
	if err := c.abi.UnpackIntoInterface(event, "EpochClaimable", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["EpochClaimable"].Inputs {
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

func (c *Codec) EpochExecutingLogHash() []byte {
	return c.abi.Events["EpochExecuting"].ID.Bytes()
}

func (c *Codec) EncodeEpochExecutingTopics(
	evt abi.Event,
	values []EpochExecutingTopics,
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

// DecodeEpochExecuting decodes a log into a EpochExecuting struct.
func (c *Codec) DecodeEpochExecuting(log *evm.Log) (*EpochExecutingDecoded, error) {
	event := new(EpochExecutingDecoded)
	if err := c.abi.UnpackIntoInterface(event, "EpochExecuting", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["EpochExecuting"].Inputs {
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

func (c *Codec) EpochOpenLogHash() []byte {
	return c.abi.Events["EpochOpen"].ID.Bytes()
}

func (c *Codec) EncodeEpochOpenTopics(
	evt abi.Event,
	values []EpochOpenTopics,
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

// DecodeEpochOpen decodes a log into a EpochOpen struct.
func (c *Codec) DecodeEpochOpen(log *evm.Log) (*EpochOpenDecoded, error) {
	event := new(EpochOpenDecoded)
	if err := c.abi.UnpackIntoInterface(event, "EpochOpen", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["EpochOpen"].Inputs {
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

func (c *Codec) EpochWithdrawAmountShortLogHash() []byte {
	return c.abi.Events["EpochWithdrawAmountShort"].ID.Bytes()
}

func (c *Codec) EncodeEpochWithdrawAmountShortTopics(
	evt abi.Event,
	values []EpochWithdrawAmountShortTopics,
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

// DecodeEpochWithdrawAmountShort decodes a log into a EpochWithdrawAmountShort struct.
func (c *Codec) DecodeEpochWithdrawAmountShort(log *evm.Log) (*EpochWithdrawAmountShortDecoded, error) {
	event := new(EpochWithdrawAmountShortDecoded)
	if err := c.abi.UnpackIntoInterface(event, "EpochWithdrawAmountShort", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["EpochWithdrawAmountShort"].Inputs {
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

func (c *Codec) InitialActiveProtocolAdapterSetLogHash() []byte {
	return c.abi.Events["InitialActiveProtocolAdapterSet"].ID.Bytes()
}

func (c *Codec) EncodeInitialActiveProtocolAdapterSetTopics(
	evt abi.Event,
	values []InitialActiveProtocolAdapterSetTopics,
) ([]*evm.TopicValues, error) {
	var protocolIdRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ProtocolId).IsZero() {
			protocolIdRule = append(protocolIdRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.ProtocolId)
		if err != nil {
			return nil, err
		}
		protocolIdRule = append(protocolIdRule, fieldVal)
	}
	var adapterRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Adapter).IsZero() {
			adapterRule = append(adapterRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Adapter)
		if err != nil {
			return nil, err
		}
		adapterRule = append(adapterRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		protocolIdRule,
		adapterRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeInitialActiveProtocolAdapterSet decodes a log into a InitialActiveProtocolAdapterSet struct.
func (c *Codec) DecodeInitialActiveProtocolAdapterSet(log *evm.Log) (*InitialActiveProtocolAdapterSetDecoded, error) {
	event := new(InitialActiveProtocolAdapterSetDecoded)
	if err := c.abi.UnpackIntoInterface(event, "InitialActiveProtocolAdapterSet", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["InitialActiveProtocolAdapterSet"].Inputs {
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

func (c *Codec) ManagementFeeCollectedLogHash() []byte {
	return c.abi.Events["ManagementFeeCollected"].ID.Bytes()
}

func (c *Codec) EncodeManagementFeeCollectedTopics(
	evt abi.Event,
	values []ManagementFeeCollectedTopics,
) ([]*evm.TopicValues, error) {
	var feeSharesRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.FeeShares).IsZero() {
			feeSharesRule = append(feeSharesRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.FeeShares)
		if err != nil {
			return nil, err
		}
		feeSharesRule = append(feeSharesRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		feeSharesRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeManagementFeeCollected decodes a log into a ManagementFeeCollected struct.
func (c *Codec) DecodeManagementFeeCollected(log *evm.Log) (*ManagementFeeCollectedDecoded, error) {
	event := new(ManagementFeeCollectedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "ManagementFeeCollected", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["ManagementFeeCollected"].Inputs {
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

func (c *Codec) OwnershipTransferredLogHash() []byte {
	return c.abi.Events["OwnershipTransferred"].ID.Bytes()
}

func (c *Codec) EncodeOwnershipTransferredTopics(
	evt abi.Event,
	values []OwnershipTransferredTopics,
) ([]*evm.TopicValues, error) {
	var previousOwnerRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.PreviousOwner).IsZero() {
			previousOwnerRule = append(previousOwnerRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.PreviousOwner)
		if err != nil {
			return nil, err
		}
		previousOwnerRule = append(previousOwnerRule, fieldVal)
	}
	var newOwnerRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.NewOwner).IsZero() {
			newOwnerRule = append(newOwnerRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.NewOwner)
		if err != nil {
			return nil, err
		}
		newOwnerRule = append(newOwnerRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		previousOwnerRule,
		newOwnerRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeOwnershipTransferred decodes a log into a OwnershipTransferred struct.
func (c *Codec) DecodeOwnershipTransferred(log *evm.Log) (*OwnershipTransferredDecoded, error) {
	event := new(OwnershipTransferredDecoded)
	if err := c.abi.UnpackIntoInterface(event, "OwnershipTransferred", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["OwnershipTransferred"].Inputs {
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

func (c *Codec) PolicyEngineAttachedLogHash() []byte {
	return c.abi.Events["PolicyEngineAttached"].ID.Bytes()
}

func (c *Codec) EncodePolicyEngineAttachedTopics(
	evt abi.Event,
	values []PolicyEngineAttachedTopics,
) ([]*evm.TopicValues, error) {
	var policyEngineRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.PolicyEngine).IsZero() {
			policyEngineRule = append(policyEngineRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.PolicyEngine)
		if err != nil {
			return nil, err
		}
		policyEngineRule = append(policyEngineRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		policyEngineRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodePolicyEngineAttached decodes a log into a PolicyEngineAttached struct.
func (c *Codec) DecodePolicyEngineAttached(log *evm.Log) (*PolicyEngineAttachedDecoded, error) {
	event := new(PolicyEngineAttachedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "PolicyEngineAttached", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["PolicyEngineAttached"].Inputs {
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

func (c *Codec) PolicyEngineDetachFailedLogHash() []byte {
	return c.abi.Events["PolicyEngineDetachFailed"].ID.Bytes()
}

func (c *Codec) EncodePolicyEngineDetachFailedTopics(
	evt abi.Event,
	values []PolicyEngineDetachFailedTopics,
) ([]*evm.TopicValues, error) {
	var policyEngineRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.PolicyEngine).IsZero() {
			policyEngineRule = append(policyEngineRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.PolicyEngine)
		if err != nil {
			return nil, err
		}
		policyEngineRule = append(policyEngineRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		policyEngineRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodePolicyEngineDetachFailed decodes a log into a PolicyEngineDetachFailed struct.
func (c *Codec) DecodePolicyEngineDetachFailed(log *evm.Log) (*PolicyEngineDetachFailedDecoded, error) {
	event := new(PolicyEngineDetachFailedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "PolicyEngineDetachFailed", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["PolicyEngineDetachFailed"].Inputs {
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

func (c *Codec) RebalanceCompletedLogHash() []byte {
	return c.abi.Events["RebalanceCompleted"].ID.Bytes()
}

func (c *Codec) EncodeRebalanceCompletedTopics(
	evt abi.Event,
	values []RebalanceCompletedTopics,
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

// DecodeRebalanceCompleted decodes a log into a RebalanceCompleted struct.
func (c *Codec) DecodeRebalanceCompleted(log *evm.Log) (*RebalanceCompletedDecoded, error) {
	event := new(RebalanceCompletedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "RebalanceCompleted", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["RebalanceCompleted"].Inputs {
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

func (c *Codec) RebalanceInitiatedLogHash() []byte {
	return c.abi.Events["RebalanceInitiated"].ID.Bytes()
}

func (c *Codec) EncodeRebalanceInitiatedTopics(
	evt abi.Event,
	values []RebalanceInitiatedTopics,
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
	var chainSelectorRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ChainSelector).IsZero() {
			chainSelectorRule = append(chainSelectorRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.ChainSelector)
		if err != nil {
			return nil, err
		}
		chainSelectorRule = append(chainSelectorRule, fieldVal)
	}
	var protocolIdRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ProtocolId).IsZero() {
			protocolIdRule = append(protocolIdRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.ProtocolId)
		if err != nil {
			return nil, err
		}
		protocolIdRule = append(protocolIdRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		rebalanceNonceRule,
		chainSelectorRule,
		protocolIdRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeRebalanceInitiated decodes a log into a RebalanceInitiated struct.
func (c *Codec) DecodeRebalanceInitiated(log *evm.Log) (*RebalanceInitiatedDecoded, error) {
	event := new(RebalanceInitiatedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "RebalanceInitiated", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["RebalanceInitiated"].Inputs {
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

func (c *Codec) TreasurySetLogHash() []byte {
	return c.abi.Events["TreasurySet"].ID.Bytes()
}

func (c *Codec) EncodeTreasurySetTopics(
	evt abi.Event,
	values []TreasurySetTopics,
) ([]*evm.TopicValues, error) {
	var treasuryRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Treasury).IsZero() {
			treasuryRule = append(treasuryRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.Treasury)
		if err != nil {
			return nil, err
		}
		treasuryRule = append(treasuryRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		treasuryRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeTreasurySet decodes a log into a TreasurySet struct.
func (c *Codec) DecodeTreasurySet(log *evm.Log) (*TreasurySetDecoded, error) {
	event := new(TreasurySetDecoded)
	if err := c.abi.UnpackIntoInterface(event, "TreasurySet", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["TreasurySet"].Inputs {
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

func (c *Codec) WithdrawCancelledLogHash() []byte {
	return c.abi.Events["WithdrawCancelled"].ID.Bytes()
}

func (c *Codec) EncodeWithdrawCancelledTopics(
	evt abi.Event,
	values []WithdrawCancelledTopics,
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
	var withdrawerRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Withdrawer).IsZero() {
			withdrawerRule = append(withdrawerRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Withdrawer)
		if err != nil {
			return nil, err
		}
		withdrawerRule = append(withdrawerRule, fieldVal)
	}
	var amountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Amount).IsZero() {
			amountRule = append(amountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.Amount)
		if err != nil {
			return nil, err
		}
		amountRule = append(amountRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		epochNonceRule,
		withdrawerRule,
		amountRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeWithdrawCancelled decodes a log into a WithdrawCancelled struct.
func (c *Codec) DecodeWithdrawCancelled(log *evm.Log) (*WithdrawCancelledDecoded, error) {
	event := new(WithdrawCancelledDecoded)
	if err := c.abi.UnpackIntoInterface(event, "WithdrawCancelled", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["WithdrawCancelled"].Inputs {
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

func (c *Codec) WithdrawClaimedLogHash() []byte {
	return c.abi.Events["WithdrawClaimed"].ID.Bytes()
}

func (c *Codec) EncodeWithdrawClaimedTopics(
	evt abi.Event,
	values []WithdrawClaimedTopics,
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
	var withdrawerRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Withdrawer).IsZero() {
			withdrawerRule = append(withdrawerRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Withdrawer)
		if err != nil {
			return nil, err
		}
		withdrawerRule = append(withdrawerRule, fieldVal)
	}
	var amountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Amount).IsZero() {
			amountRule = append(amountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.Amount)
		if err != nil {
			return nil, err
		}
		amountRule = append(amountRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		epochNonceRule,
		withdrawerRule,
		amountRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeWithdrawClaimed decodes a log into a WithdrawClaimed struct.
func (c *Codec) DecodeWithdrawClaimed(log *evm.Log) (*WithdrawClaimedDecoded, error) {
	event := new(WithdrawClaimedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "WithdrawClaimed", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["WithdrawClaimed"].Inputs {
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

func (c *Codec) WithdrawFeeCollectedLogHash() []byte {
	return c.abi.Events["WithdrawFeeCollected"].ID.Bytes()
}

func (c *Codec) EncodeWithdrawFeeCollectedTopics(
	evt abi.Event,
	values []WithdrawFeeCollectedTopics,
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
	var withdrawerRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Withdrawer).IsZero() {
			withdrawerRule = append(withdrawerRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Withdrawer)
		if err != nil {
			return nil, err
		}
		withdrawerRule = append(withdrawerRule, fieldVal)
	}
	var feeRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Fee).IsZero() {
			feeRule = append(feeRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.Fee)
		if err != nil {
			return nil, err
		}
		feeRule = append(feeRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		epochNonceRule,
		withdrawerRule,
		feeRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeWithdrawFeeCollected decodes a log into a WithdrawFeeCollected struct.
func (c *Codec) DecodeWithdrawFeeCollected(log *evm.Log) (*WithdrawFeeCollectedDecoded, error) {
	event := new(WithdrawFeeCollectedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "WithdrawFeeCollected", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["WithdrawFeeCollected"].Inputs {
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

func (c *Codec) WithdrawSubmittedLogHash() []byte {
	return c.abi.Events["WithdrawSubmitted"].ID.Bytes()
}

func (c *Codec) EncodeWithdrawSubmittedTopics(
	evt abi.Event,
	values []WithdrawSubmittedTopics,
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
	var withdrawerRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Withdrawer).IsZero() {
			withdrawerRule = append(withdrawerRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.Withdrawer)
		if err != nil {
			return nil, err
		}
		withdrawerRule = append(withdrawerRule, fieldVal)
	}
	var shareBurnAmountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ShareBurnAmount).IsZero() {
			shareBurnAmountRule = append(shareBurnAmountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.ShareBurnAmount)
		if err != nil {
			return nil, err
		}
		shareBurnAmountRule = append(shareBurnAmountRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		epochNonceRule,
		withdrawerRule,
		shareBurnAmountRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeWithdrawSubmitted decodes a log into a WithdrawSubmitted struct.
func (c *Codec) DecodeWithdrawSubmitted(log *evm.Log) (*WithdrawSubmittedDecoded, error) {
	event := new(WithdrawSubmittedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "WithdrawSubmitted", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["WithdrawSubmitted"].Inputs {
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

func (c ParentVault) DEFAULTADMINROLE(
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

func (c ParentVault) DefaultAdmin(
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

func (c ParentVault) DefaultAdminDelay(
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

func (c ParentVault) DefaultAdminDelayIncreaseWait(
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

func (c ParentVault) GetActiveProtocolAdapter(
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

func (c ParentVault) GetAdapterRegistry(
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

func (c ParentVault) GetCCVsAndFinalityConfig(
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

func (c ParentVault) GetCcipGasLimit(
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

func (c ParentVault) GetContext(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[[]byte] {
	calldata, err := c.Codec.EncodeGetContextMethodCall()
	if err != nil {
		return cre.PromiseFromResult[[]byte](*new([]byte), err)
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
	return cre.Then(promise, func(response *evm.CallContractReply) ([]byte, error) {
		return c.Codec.DecodeGetContextMethodOutput(response.Data)
	})

}

func (c ParentVault) GetCrosschainVault(
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

func (c ParentVault) GetDefaultCcipGasLimit(
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

func (c ParentVault) GetDepositAmount(
	runtime cre.Runtime,
	args GetDepositAmountInput,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeGetDepositAmountMethodCall(args)
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
		return c.Codec.DecodeGetDepositAmountMethodOutput(response.Data)
	})

}

func (c ParentVault) GetEpoch(
	runtime cre.Runtime,
	args GetEpochInput,
	blockNumber *big.Int,
) cre.Promise[TypesEpoch] {
	calldata, err := c.Codec.EncodeGetEpochMethodCall(args)
	if err != nil {
		return cre.PromiseFromResult[TypesEpoch](*new(TypesEpoch), err)
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
	return cre.Then(promise, func(response *evm.CallContractReply) (TypesEpoch, error) {
		return c.Codec.DecodeGetEpochMethodOutput(response.Data)
	})

}

func (c ParentVault) GetEpochNonce(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeGetEpochNonceMethodCall()
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
		return c.Codec.DecodeGetEpochNonceMethodOutput(response.Data)
	})

}

func (c ParentVault) GetInitialActiveProtocolAdapterSet(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[bool] {
	calldata, err := c.Codec.EncodeGetInitialActiveProtocolAdapterSetMethodCall()
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
		return c.Codec.DecodeGetInitialActiveProtocolAdapterSetMethodOutput(response.Data)
	})

}

func (c ParentVault) GetLink(
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

func (c ParentVault) GetPausedAt(
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

func (c ParentVault) GetPolicyEngine(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetPolicyEngineMethodCall()
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
		return c.Codec.DecodeGetPolicyEngineMethodOutput(response.Data)
	})

}

func (c ParentVault) GetRebalance(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[TypesRebalance] {
	calldata, err := c.Codec.EncodeGetRebalanceMethodCall()
	if err != nil {
		return cre.PromiseFromResult[TypesRebalance](*new(TypesRebalance), err)
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
	return cre.Then(promise, func(response *evm.CallContractReply) (TypesRebalance, error) {
		return c.Codec.DecodeGetRebalanceMethodOutput(response.Data)
	})

}

func (c ParentVault) GetRebalanceDepositRecovery(
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

func (c ParentVault) GetRoleAdmin(
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

func (c ParentVault) GetRouter(
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

func (c ParentVault) GetShare(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetShareMethodCall()
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
		return c.Codec.DecodeGetShareMethodOutput(response.Data)
	})

}

func (c ParentVault) GetTVL(
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

func (c ParentVault) GetThisChainSelector(
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

func (c ParentVault) GetTotalShares(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeGetTotalSharesMethodCall()
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
		return c.Codec.DecodeGetTotalSharesMethodOutput(response.Data)
	})

}

func (c ParentVault) GetTreasury(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetTreasuryMethodCall()
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
		return c.Codec.DecodeGetTreasuryMethodOutput(response.Data)
	})

}

func (c ParentVault) GetUsdc(
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

func (c ParentVault) GetWithdrawShareBurnAmount(
	runtime cre.Runtime,
	args GetWithdrawShareBurnAmountInput,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeGetWithdrawShareBurnAmountMethodCall(args)
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
		return c.Codec.DecodeGetWithdrawShareBurnAmountMethodOutput(response.Data)
	})

}

func (c ParentVault) HasRole(
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

func (c ParentVault) Owner(
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

func (c ParentVault) Paused(
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

func (c ParentVault) PendingDefaultAdmin(
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

func (c ParentVault) PendingDefaultAdminDelay(
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

func (c ParentVault) WriteReportFromBaseVaultConstructorParams(
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

func (c ParentVault) WriteReportFromClientAny2EVMMessage(
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

func (c ParentVault) WriteReportFromClientEVMTokenAmount(
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

func (c ParentVault) WriteReportFromTypesAmountRecovery(
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

func (c ParentVault) WriteReportFromTypesEpoch(
	runtime cre.Runtime,
	input TypesEpoch,
	gasConfig *evm.GasConfig,
) cre.Promise[*evm.WriteReportReply] {
	encoded, err := c.Codec.EncodeTypesEpochStruct(input)
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

func (c ParentVault) WriteReportFromTypesRebalance(
	runtime cre.Runtime,
	input TypesRebalance,
	gasConfig *evm.GasConfig,
) cre.Promise[*evm.WriteReportReply] {
	encoded, err := c.Codec.EncodeTypesRebalanceStruct(input)
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

func (c ParentVault) WriteReportFromTypesStrategy(
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

func (c ParentVault) WriteReport(
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
func (c *ParentVault) DecodeAccessControlBadConfirmationError(data []byte) (*AccessControlBadConfirmation, error) {
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
func (c *ParentVault) DecodeAccessControlEnforcedDefaultAdminDelayError(data []byte) (*AccessControlEnforcedDefaultAdminDelay, error) {
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
func (c *ParentVault) DecodeAccessControlEnforcedDefaultAdminRulesError(data []byte) (*AccessControlEnforcedDefaultAdminRules, error) {
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
func (c *ParentVault) DecodeAccessControlInvalidDefaultAdminError(data []byte) (*AccessControlInvalidDefaultAdmin, error) {
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
func (c *ParentVault) DecodeAccessControlUnauthorizedAccountError(data []byte) (*AccessControlUnauthorizedAccount, error) {
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
func (c *ParentVault) DecodeBaseVaultDepositFailedError(data []byte) (*BaseVaultDepositFailed, error) {
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
func (c *ParentVault) DecodeBaseVaultEmergencyDrainDelayNotMetError(data []byte) (*BaseVaultEmergencyDrainDelayNotMet, error) {
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
func (c *ParentVault) DecodeBaseVaultInvalidInputLengthsError(data []byte) (*BaseVaultInvalidInputLengths, error) {
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
func (c *ParentVault) DecodeBaseVaultInvalidSenderError(data []byte) (*BaseVaultInvalidSender, error) {
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
func (c *ParentVault) DecodeBaseVaultNoActiveAdapterError(data []byte) (*BaseVaultNoActiveAdapter, error) {
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
func (c *ParentVault) DecodeBaseVaultNoAdapterRegisteredError(data []byte) (*BaseVaultNoAdapterRegistered, error) {
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
func (c *ParentVault) DecodeBaseVaultNoPendingRecoveryError(data []byte) (*BaseVaultNoPendingRecovery, error) {
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
func (c *ParentVault) DecodeBaseVaultNoZeroAmountError(data []byte) (*BaseVaultNoZeroAmount, error) {
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
func (c *ParentVault) DecodeBaseVaultOnlySelfError(data []byte) (*BaseVaultOnlySelf, error) {
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
func (c *ParentVault) DecodeBaseVaultRecoveryAlreadyPendingError(data []byte) (*BaseVaultRecoveryAlreadyPending, error) {
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
func (c *ParentVault) DecodeBaseVaultWithdrawFailedError(data []byte) (*BaseVaultWithdrawFailed, error) {
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
func (c *ParentVault) DecodeBaseVaultZeroRecoveryAmountError(data []byte) (*BaseVaultZeroRecoveryAmount, error) {
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

// DecodeEnforcedPauseError decodes a EnforcedPause error from revert data.
func (c *ParentVault) DecodeEnforcedPauseError(data []byte) (*EnforcedPause, error) {
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
func (c *ParentVault) DecodeExpectedPauseError(data []byte) (*ExpectedPause, error) {
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
func (c *ParentVault) DecodeInvalidRouterError(data []byte) (*InvalidRouter, error) {
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

// DecodeOwnableInvalidOwnerError decodes a OwnableInvalidOwner error from revert data.
func (c *ParentVault) DecodeOwnableInvalidOwnerError(data []byte) (*OwnableInvalidOwner, error) {
	args := c.ABI.Errors["OwnableInvalidOwner"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	owner, ok0 := values[0].(common.Address)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for owner in OwnableInvalidOwner error")
	}

	return &OwnableInvalidOwner{
		Owner: owner,
	}, nil
}

// Error implements the error interface for OwnableInvalidOwner.
func (e *OwnableInvalidOwner) Error() string {
	return fmt.Sprintf("OwnableInvalidOwner error: owner=%v;", e.Owner)
}

// DecodeOwnableUnauthorizedAccountError decodes a OwnableUnauthorizedAccount error from revert data.
func (c *ParentVault) DecodeOwnableUnauthorizedAccountError(data []byte) (*OwnableUnauthorizedAccount, error) {
	args := c.ABI.Errors["OwnableUnauthorizedAccount"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	account, ok0 := values[0].(common.Address)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for account in OwnableUnauthorizedAccount error")
	}

	return &OwnableUnauthorizedAccount{
		Account: account,
	}, nil
}

// Error implements the error interface for OwnableUnauthorizedAccount.
func (e *OwnableUnauthorizedAccount) Error() string {
	return fmt.Sprintf("OwnableUnauthorizedAccount error: account=%v;", e.Account)
}

// DecodeParentVaultAmountTooSmallError decodes a ParentVault__AmountTooSmall error from revert data.
func (c *ParentVault) DecodeParentVaultAmountTooSmallError(data []byte) (*ParentVaultAmountTooSmall, error) {
	args := c.ABI.Errors["ParentVault__AmountTooSmall"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	amount, ok0 := values[0].(*big.Int)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for amount in ParentVaultAmountTooSmall error")
	}

	return &ParentVaultAmountTooSmall{
		Amount: amount,
	}, nil
}

// Error implements the error interface for ParentVaultAmountTooSmall.
func (e *ParentVaultAmountTooSmall) Error() string {
	return fmt.Sprintf("ParentVaultAmountTooSmall error: amount=%v;", e.Amount)
}

// DecodeParentVaultEmptyEpochError decodes a ParentVault__EmptyEpoch error from revert data.
func (c *ParentVault) DecodeParentVaultEmptyEpochError(data []byte) (*ParentVaultEmptyEpoch, error) {
	args := c.ABI.Errors["ParentVault__EmptyEpoch"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	epochNonce, ok0 := values[0].(*big.Int)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for epochNonce in ParentVaultEmptyEpoch error")
	}

	return &ParentVaultEmptyEpoch{
		EpochNonce: epochNonce,
	}, nil
}

// Error implements the error interface for ParentVaultEmptyEpoch.
func (e *ParentVaultEmptyEpoch) Error() string {
	return fmt.Sprintf("ParentVaultEmptyEpoch error: epochNonce=%v;", e.EpochNonce)
}

// DecodeParentVaultEpochExecutingError decodes a ParentVault__EpochExecuting error from revert data.
func (c *ParentVault) DecodeParentVaultEpochExecutingError(data []byte) (*ParentVaultEpochExecuting, error) {
	args := c.ABI.Errors["ParentVault__EpochExecuting"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	epochNonce, ok0 := values[0].(*big.Int)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for epochNonce in ParentVaultEpochExecuting error")
	}

	return &ParentVaultEpochExecuting{
		EpochNonce: epochNonce,
	}, nil
}

// Error implements the error interface for ParentVaultEpochExecuting.
func (e *ParentVaultEpochExecuting) Error() string {
	return fmt.Sprintf("ParentVaultEpochExecuting error: epochNonce=%v;", e.EpochNonce)
}

// DecodeParentVaultEpochNotClaimableError decodes a ParentVault__EpochNotClaimable error from revert data.
func (c *ParentVault) DecodeParentVaultEpochNotClaimableError(data []byte) (*ParentVaultEpochNotClaimable, error) {
	args := c.ABI.Errors["ParentVault__EpochNotClaimable"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	epochNonce, ok0 := values[0].(*big.Int)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for epochNonce in ParentVaultEpochNotClaimable error")
	}

	return &ParentVaultEpochNotClaimable{
		EpochNonce: epochNonce,
	}, nil
}

// Error implements the error interface for ParentVaultEpochNotClaimable.
func (e *ParentVaultEpochNotClaimable) Error() string {
	return fmt.Sprintf("ParentVaultEpochNotClaimable error: epochNonce=%v;", e.EpochNonce)
}

// DecodeParentVaultEpochNotExecutingError decodes a ParentVault__EpochNotExecuting error from revert data.
func (c *ParentVault) DecodeParentVaultEpochNotExecutingError(data []byte) (*ParentVaultEpochNotExecuting, error) {
	args := c.ABI.Errors["ParentVault__EpochNotExecuting"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	epochNonce, ok0 := values[0].(*big.Int)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for epochNonce in ParentVaultEpochNotExecuting error")
	}

	return &ParentVaultEpochNotExecuting{
		EpochNonce: epochNonce,
	}, nil
}

// Error implements the error interface for ParentVaultEpochNotExecuting.
func (e *ParentVaultEpochNotExecuting) Error() string {
	return fmt.Sprintf("ParentVaultEpochNotExecuting error: epochNonce=%v;", e.EpochNonce)
}

// DecodeParentVaultEpochNotOpenError decodes a ParentVault__EpochNotOpen error from revert data.
func (c *ParentVault) DecodeParentVaultEpochNotOpenError(data []byte) (*ParentVaultEpochNotOpen, error) {
	args := c.ABI.Errors["ParentVault__EpochNotOpen"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	epochNonce, ok0 := values[0].(*big.Int)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for epochNonce in ParentVaultEpochNotOpen error")
	}

	return &ParentVaultEpochNotOpen{
		EpochNonce: epochNonce,
	}, nil
}

// Error implements the error interface for ParentVaultEpochNotOpen.
func (e *ParentVaultEpochNotOpen) Error() string {
	return fmt.Sprintf("ParentVaultEpochNotOpen error: epochNonce=%v;", e.EpochNonce)
}

// DecodeParentVaultEpochTooShortError decodes a ParentVault__EpochTooShort error from revert data.
func (c *ParentVault) DecodeParentVaultEpochTooShortError(data []byte) (*ParentVaultEpochTooShort, error) {
	args := c.ABI.Errors["ParentVault__EpochTooShort"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	epochNonce, ok0 := values[0].(*big.Int)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for epochNonce in ParentVaultEpochTooShort error")
	}

	return &ParentVaultEpochTooShort{
		EpochNonce: epochNonce,
	}, nil
}

// Error implements the error interface for ParentVaultEpochTooShort.
func (e *ParentVaultEpochTooShort) Error() string {
	return fmt.Sprintf("ParentVaultEpochTooShort error: epochNonce=%v;", e.EpochNonce)
}

// DecodeParentVaultInitialActiveProtocolAdapterAlreadySetError decodes a ParentVault__InitialActiveProtocolAdapterAlreadySet error from revert data.
func (c *ParentVault) DecodeParentVaultInitialActiveProtocolAdapterAlreadySetError(data []byte) (*ParentVaultInitialActiveProtocolAdapterAlreadySet, error) {
	args := c.ABI.Errors["ParentVault__InitialActiveProtocolAdapterAlreadySet"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &ParentVaultInitialActiveProtocolAdapterAlreadySet{}, nil
}

// Error implements the error interface for ParentVaultInitialActiveProtocolAdapterAlreadySet.
func (e *ParentVaultInitialActiveProtocolAdapterAlreadySet) Error() string {
	return fmt.Sprintf("ParentVaultInitialActiveProtocolAdapterAlreadySet error:")
}

// DecodeParentVaultInvalidRebalanceNonceError decodes a ParentVault__InvalidRebalanceNonce error from revert data.
func (c *ParentVault) DecodeParentVaultInvalidRebalanceNonceError(data []byte) (*ParentVaultInvalidRebalanceNonce, error) {
	args := c.ABI.Errors["ParentVault__InvalidRebalanceNonce"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	rebalanceNonce, ok0 := values[0].(*big.Int)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for rebalanceNonce in ParentVaultInvalidRebalanceNonce error")
	}

	return &ParentVaultInvalidRebalanceNonce{
		RebalanceNonce: rebalanceNonce,
	}, nil
}

// Error implements the error interface for ParentVaultInvalidRebalanceNonce.
func (e *ParentVaultInvalidRebalanceNonce) Error() string {
	return fmt.Sprintf("ParentVaultInvalidRebalanceNonce error: rebalanceNonce=%v;", e.RebalanceNonce)
}

// DecodeParentVaultNoDepositError decodes a ParentVault__NoDeposit error from revert data.
func (c *ParentVault) DecodeParentVaultNoDepositError(data []byte) (*ParentVaultNoDeposit, error) {
	args := c.ABI.Errors["ParentVault__NoDeposit"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 2 {
		return nil, fmt.Errorf("expected 2 values, got %d", len(values))
	}

	depositor, ok0 := values[0].(common.Address)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for depositor in ParentVaultNoDeposit error")
	}

	epochNonce, ok1 := values[1].(*big.Int)
	if !ok1 {
		return nil, fmt.Errorf("unexpected type for epochNonce in ParentVaultNoDeposit error")
	}

	return &ParentVaultNoDeposit{
		Depositor:  depositor,
		EpochNonce: epochNonce,
	}, nil
}

// Error implements the error interface for ParentVaultNoDeposit.
func (e *ParentVaultNoDeposit) Error() string {
	return fmt.Sprintf("ParentVaultNoDeposit error: depositor=%v; epochNonce=%v;", e.Depositor, e.EpochNonce)
}

// DecodeParentVaultNoRebalanceInProgressError decodes a ParentVault__NoRebalanceInProgress error from revert data.
func (c *ParentVault) DecodeParentVaultNoRebalanceInProgressError(data []byte) (*ParentVaultNoRebalanceInProgress, error) {
	args := c.ABI.Errors["ParentVault__NoRebalanceInProgress"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &ParentVaultNoRebalanceInProgress{}, nil
}

// Error implements the error interface for ParentVaultNoRebalanceInProgress.
func (e *ParentVaultNoRebalanceInProgress) Error() string {
	return fmt.Sprintf("ParentVaultNoRebalanceInProgress error:")
}

// DecodeParentVaultNoWithdrawError decodes a ParentVault__NoWithdraw error from revert data.
func (c *ParentVault) DecodeParentVaultNoWithdrawError(data []byte) (*ParentVaultNoWithdraw, error) {
	args := c.ABI.Errors["ParentVault__NoWithdraw"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 2 {
		return nil, fmt.Errorf("expected 2 values, got %d", len(values))
	}

	withdrawer, ok0 := values[0].(common.Address)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for withdrawer in ParentVaultNoWithdraw error")
	}

	epochNonce, ok1 := values[1].(*big.Int)
	if !ok1 {
		return nil, fmt.Errorf("unexpected type for epochNonce in ParentVaultNoWithdraw error")
	}

	return &ParentVaultNoWithdraw{
		Withdrawer: withdrawer,
		EpochNonce: epochNonce,
	}, nil
}

// Error implements the error interface for ParentVaultNoWithdraw.
func (e *ParentVaultNoWithdraw) Error() string {
	return fmt.Sprintf("ParentVaultNoWithdraw error: withdrawer=%v; epochNonce=%v;", e.Withdrawer, e.EpochNonce)
}

// DecodeParentVaultNoZeroAmountError decodes a ParentVault__NoZeroAmount error from revert data.
func (c *ParentVault) DecodeParentVaultNoZeroAmountError(data []byte) (*ParentVaultNoZeroAmount, error) {
	args := c.ABI.Errors["ParentVault__NoZeroAmount"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &ParentVaultNoZeroAmount{}, nil
}

// Error implements the error interface for ParentVaultNoZeroAmount.
func (e *ParentVaultNoZeroAmount) Error() string {
	return fmt.Sprintf("ParentVaultNoZeroAmount error:")
}

// DecodeParentVaultRebalanceInProgressError decodes a ParentVault__RebalanceInProgress error from revert data.
func (c *ParentVault) DecodeParentVaultRebalanceInProgressError(data []byte) (*ParentVaultRebalanceInProgress, error) {
	args := c.ABI.Errors["ParentVault__RebalanceInProgress"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &ParentVaultRebalanceInProgress{}, nil
}

// Error implements the error interface for ParentVaultRebalanceInProgress.
func (e *ParentVaultRebalanceInProgress) Error() string {
	return fmt.Sprintf("ParentVaultRebalanceInProgress error:")
}

// DecodeParentVaultSameStrategyError decodes a ParentVault__SameStrategy error from revert data.
func (c *ParentVault) DecodeParentVaultSameStrategyError(data []byte) (*ParentVaultSameStrategy, error) {
	args := c.ABI.Errors["ParentVault__SameStrategy"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &ParentVaultSameStrategy{}, nil
}

// Error implements the error interface for ParentVaultSameStrategy.
func (e *ParentVaultSameStrategy) Error() string {
	return fmt.Sprintf("ParentVaultSameStrategy error:")
}

// DecodeParentVaultWithdrawFailedError decodes a ParentVault__WithdrawFailed error from revert data.
func (c *ParentVault) DecodeParentVaultWithdrawFailedError(data []byte) (*ParentVaultWithdrawFailed, error) {
	args := c.ABI.Errors["ParentVault__WithdrawFailed"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 2 {
		return nil, fmt.Errorf("expected 2 values, got %d", len(values))
	}

	epochNonce, ok0 := values[0].(*big.Int)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for epochNonce in ParentVaultWithdrawFailed error")
	}

	amount, ok1 := values[1].(*big.Int)
	if !ok1 {
		return nil, fmt.Errorf("unexpected type for amount in ParentVaultWithdrawFailed error")
	}

	return &ParentVaultWithdrawFailed{
		EpochNonce: epochNonce,
		Amount:     amount,
	}, nil
}

// Error implements the error interface for ParentVaultWithdrawFailed.
func (e *ParentVaultWithdrawFailed) Error() string {
	return fmt.Sprintf("ParentVaultWithdrawFailed error: epochNonce=%v; amount=%v;", e.EpochNonce, e.Amount)
}

// DecodePolicyEngineUndefinedError decodes a PolicyEngineUndefined error from revert data.
func (c *ParentVault) DecodePolicyEngineUndefinedError(data []byte) (*PolicyEngineUndefined, error) {
	args := c.ABI.Errors["PolicyEngineUndefined"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &PolicyEngineUndefined{}, nil
}

// Error implements the error interface for PolicyEngineUndefined.
func (e *PolicyEngineUndefined) Error() string {
	return fmt.Sprintf("PolicyEngineUndefined error:")
}

// DecodeReentrancyGuardReentrantCallError decodes a ReentrancyGuardReentrantCall error from revert data.
func (c *ParentVault) DecodeReentrancyGuardReentrantCallError(data []byte) (*ReentrancyGuardReentrantCall, error) {
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
func (c *ParentVault) DecodeSafeCastOverflowedUintDowncastError(data []byte) (*SafeCastOverflowedUintDowncast, error) {
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
func (c *ParentVault) DecodeSafeERC20FailedOperationError(data []byte) (*SafeERC20FailedOperation, error) {
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

func (c *ParentVault) UnpackError(data []byte) (any, error) {
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
	case common.Bytes2Hex(c.ABI.Errors["EnforcedPause"].ID.Bytes()[:4]):
		return c.DecodeEnforcedPauseError(data)
	case common.Bytes2Hex(c.ABI.Errors["ExpectedPause"].ID.Bytes()[:4]):
		return c.DecodeExpectedPauseError(data)
	case common.Bytes2Hex(c.ABI.Errors["InvalidRouter"].ID.Bytes()[:4]):
		return c.DecodeInvalidRouterError(data)
	case common.Bytes2Hex(c.ABI.Errors["OwnableInvalidOwner"].ID.Bytes()[:4]):
		return c.DecodeOwnableInvalidOwnerError(data)
	case common.Bytes2Hex(c.ABI.Errors["OwnableUnauthorizedAccount"].ID.Bytes()[:4]):
		return c.DecodeOwnableUnauthorizedAccountError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__AmountTooSmall"].ID.Bytes()[:4]):
		return c.DecodeParentVaultAmountTooSmallError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__EmptyEpoch"].ID.Bytes()[:4]):
		return c.DecodeParentVaultEmptyEpochError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__EpochExecuting"].ID.Bytes()[:4]):
		return c.DecodeParentVaultEpochExecutingError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__EpochNotClaimable"].ID.Bytes()[:4]):
		return c.DecodeParentVaultEpochNotClaimableError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__EpochNotExecuting"].ID.Bytes()[:4]):
		return c.DecodeParentVaultEpochNotExecutingError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__EpochNotOpen"].ID.Bytes()[:4]):
		return c.DecodeParentVaultEpochNotOpenError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__EpochTooShort"].ID.Bytes()[:4]):
		return c.DecodeParentVaultEpochTooShortError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__InitialActiveProtocolAdapterAlreadySet"].ID.Bytes()[:4]):
		return c.DecodeParentVaultInitialActiveProtocolAdapterAlreadySetError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__InvalidRebalanceNonce"].ID.Bytes()[:4]):
		return c.DecodeParentVaultInvalidRebalanceNonceError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__NoDeposit"].ID.Bytes()[:4]):
		return c.DecodeParentVaultNoDepositError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__NoRebalanceInProgress"].ID.Bytes()[:4]):
		return c.DecodeParentVaultNoRebalanceInProgressError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__NoWithdraw"].ID.Bytes()[:4]):
		return c.DecodeParentVaultNoWithdrawError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__NoZeroAmount"].ID.Bytes()[:4]):
		return c.DecodeParentVaultNoZeroAmountError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__RebalanceInProgress"].ID.Bytes()[:4]):
		return c.DecodeParentVaultRebalanceInProgressError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__SameStrategy"].ID.Bytes()[:4]):
		return c.DecodeParentVaultSameStrategyError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__WithdrawFailed"].ID.Bytes()[:4]):
		return c.DecodeParentVaultWithdrawFailedError(data)
	case common.Bytes2Hex(c.ABI.Errors["PolicyEngineUndefined"].ID.Bytes()[:4]):
		return c.DecodePolicyEngineUndefinedError(data)
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

// CCIPBridgedTrigger wraps the raw log trigger and provides decoded CCIPBridgedDecoded data
type CCIPBridgedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into CCIPBridged data
func (t *CCIPBridgedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[CCIPBridgedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeCCIPBridged(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode CCIPBridged log: %w", err)
	}

	return &bindings.DecodedLog[CCIPBridgedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerCCIPBridgedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []CCIPBridgedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[CCIPBridgedDecoded]], error) {
	event := c.ABI.Events["CCIPBridged"]
	topics, err := c.Codec.EncodeCCIPBridgedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for CCIPBridged: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &CCIPBridgedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsCCIPBridged(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.CCIPBridgedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// CcipGasLimitSetTrigger wraps the raw log trigger and provides decoded CcipGasLimitSetDecoded data
type CcipGasLimitSetTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
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

func (c *ParentVault) LogTriggerCcipGasLimitSetLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []CcipGasLimitSetTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[CcipGasLimitSetDecoded]], error) {
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

func (c *ParentVault) FilterLogsCcipGasLimitSet(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
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
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
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

func (c *ParentVault) LogTriggerCrosschainVaultSetLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []CrosschainVaultSetTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[CrosschainVaultSetDecoded]], error) {
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

func (c *ParentVault) FilterLogsCrosschainVaultSet(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
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
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
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

func (c *ParentVault) LogTriggerDefaultAdminDelayChangeCanceledLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []DefaultAdminDelayChangeCanceledTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[DefaultAdminDelayChangeCanceledDecoded]], error) {
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

func (c *ParentVault) FilterLogsDefaultAdminDelayChangeCanceled(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
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
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
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

func (c *ParentVault) LogTriggerDefaultAdminDelayChangeScheduledLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []DefaultAdminDelayChangeScheduledTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[DefaultAdminDelayChangeScheduledDecoded]], error) {
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

func (c *ParentVault) FilterLogsDefaultAdminDelayChangeScheduled(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
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
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
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

func (c *ParentVault) LogTriggerDefaultAdminTransferCanceledLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []DefaultAdminTransferCanceledTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[DefaultAdminTransferCanceledDecoded]], error) {
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

func (c *ParentVault) FilterLogsDefaultAdminTransferCanceled(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
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
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
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

func (c *ParentVault) LogTriggerDefaultAdminTransferScheduledLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []DefaultAdminTransferScheduledTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[DefaultAdminTransferScheduledDecoded]], error) {
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

func (c *ParentVault) FilterLogsDefaultAdminTransferScheduled(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
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
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
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

func (c *ParentVault) LogTriggerDefaultCcipGasLimitSetLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []DefaultCcipGasLimitSetTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[DefaultCcipGasLimitSetDecoded]], error) {
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

func (c *ParentVault) FilterLogsDefaultCcipGasLimitSet(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
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

// DepositCancelledTrigger wraps the raw log trigger and provides decoded DepositCancelledDecoded data
type DepositCancelledTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into DepositCancelled data
func (t *DepositCancelledTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[DepositCancelledDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeDepositCancelled(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode DepositCancelled log: %w", err)
	}

	return &bindings.DecodedLog[DepositCancelledDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerDepositCancelledLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []DepositCancelledTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[DepositCancelledDecoded]], error) {
	event := c.ABI.Events["DepositCancelled"]
	topics, err := c.Codec.EncodeDepositCancelledTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for DepositCancelled: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &DepositCancelledTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsDepositCancelled(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.DepositCancelledLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// DepositClaimedTrigger wraps the raw log trigger and provides decoded DepositClaimedDecoded data
type DepositClaimedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into DepositClaimed data
func (t *DepositClaimedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[DepositClaimedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeDepositClaimed(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode DepositClaimed log: %w", err)
	}

	return &bindings.DecodedLog[DepositClaimedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerDepositClaimedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []DepositClaimedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[DepositClaimedDecoded]], error) {
	event := c.ABI.Events["DepositClaimed"]
	topics, err := c.Codec.EncodeDepositClaimedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for DepositClaimed: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &DepositClaimedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsDepositClaimed(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.DepositClaimedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// DepositFeeCollectedTrigger wraps the raw log trigger and provides decoded DepositFeeCollectedDecoded data
type DepositFeeCollectedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into DepositFeeCollected data
func (t *DepositFeeCollectedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[DepositFeeCollectedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeDepositFeeCollected(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode DepositFeeCollected log: %w", err)
	}

	return &bindings.DecodedLog[DepositFeeCollectedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerDepositFeeCollectedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []DepositFeeCollectedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[DepositFeeCollectedDecoded]], error) {
	event := c.ABI.Events["DepositFeeCollected"]
	topics, err := c.Codec.EncodeDepositFeeCollectedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for DepositFeeCollected: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &DepositFeeCollectedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsDepositFeeCollected(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.DepositFeeCollectedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// DepositSubmittedTrigger wraps the raw log trigger and provides decoded DepositSubmittedDecoded data
type DepositSubmittedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into DepositSubmitted data
func (t *DepositSubmittedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[DepositSubmittedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeDepositSubmitted(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode DepositSubmitted log: %w", err)
	}

	return &bindings.DecodedLog[DepositSubmittedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerDepositSubmittedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []DepositSubmittedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[DepositSubmittedDecoded]], error) {
	event := c.ABI.Events["DepositSubmitted"]
	topics, err := c.Codec.EncodeDepositSubmittedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for DepositSubmitted: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &DepositSubmittedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsDepositSubmitted(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.DepositSubmittedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// DepositToStrategyFailureTrigger wraps the raw log trigger and provides decoded DepositToStrategyFailureDecoded data
type DepositToStrategyFailureTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
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

func (c *ParentVault) LogTriggerDepositToStrategyFailureLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []DepositToStrategyFailureTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[DepositToStrategyFailureDecoded]], error) {
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

func (c *ParentVault) FilterLogsDepositToStrategyFailure(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
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
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
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

func (c *ParentVault) LogTriggerDepositToStrategySuccessLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []DepositToStrategySuccessTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[DepositToStrategySuccessDecoded]], error) {
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

func (c *ParentVault) FilterLogsDepositToStrategySuccess(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
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
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
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

func (c *ParentVault) LogTriggerEmergencyDrainExecutedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []EmergencyDrainExecutedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[EmergencyDrainExecutedDecoded]], error) {
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

func (c *ParentVault) FilterLogsEmergencyDrainExecuted(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
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

// EpochClaimableTrigger wraps the raw log trigger and provides decoded EpochClaimableDecoded data
type EpochClaimableTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into EpochClaimable data
func (t *EpochClaimableTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[EpochClaimableDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeEpochClaimable(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode EpochClaimable log: %w", err)
	}

	return &bindings.DecodedLog[EpochClaimableDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerEpochClaimableLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []EpochClaimableTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[EpochClaimableDecoded]], error) {
	event := c.ABI.Events["EpochClaimable"]
	topics, err := c.Codec.EncodeEpochClaimableTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for EpochClaimable: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &EpochClaimableTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsEpochClaimable(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.EpochClaimableLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// EpochExecutingTrigger wraps the raw log trigger and provides decoded EpochExecutingDecoded data
type EpochExecutingTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into EpochExecuting data
func (t *EpochExecutingTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[EpochExecutingDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeEpochExecuting(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode EpochExecuting log: %w", err)
	}

	return &bindings.DecodedLog[EpochExecutingDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerEpochExecutingLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []EpochExecutingTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[EpochExecutingDecoded]], error) {
	event := c.ABI.Events["EpochExecuting"]
	topics, err := c.Codec.EncodeEpochExecutingTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for EpochExecuting: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &EpochExecutingTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsEpochExecuting(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.EpochExecutingLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// EpochOpenTrigger wraps the raw log trigger and provides decoded EpochOpenDecoded data
type EpochOpenTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into EpochOpen data
func (t *EpochOpenTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[EpochOpenDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeEpochOpen(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode EpochOpen log: %w", err)
	}

	return &bindings.DecodedLog[EpochOpenDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerEpochOpenLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []EpochOpenTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[EpochOpenDecoded]], error) {
	event := c.ABI.Events["EpochOpen"]
	topics, err := c.Codec.EncodeEpochOpenTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for EpochOpen: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &EpochOpenTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsEpochOpen(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.EpochOpenLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// EpochWithdrawAmountShortTrigger wraps the raw log trigger and provides decoded EpochWithdrawAmountShortDecoded data
type EpochWithdrawAmountShortTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into EpochWithdrawAmountShort data
func (t *EpochWithdrawAmountShortTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[EpochWithdrawAmountShortDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeEpochWithdrawAmountShort(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode EpochWithdrawAmountShort log: %w", err)
	}

	return &bindings.DecodedLog[EpochWithdrawAmountShortDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerEpochWithdrawAmountShortLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []EpochWithdrawAmountShortTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[EpochWithdrawAmountShortDecoded]], error) {
	event := c.ABI.Events["EpochWithdrawAmountShort"]
	topics, err := c.Codec.EncodeEpochWithdrawAmountShortTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for EpochWithdrawAmountShort: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &EpochWithdrawAmountShortTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsEpochWithdrawAmountShort(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.EpochWithdrawAmountShortLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// InitialActiveProtocolAdapterSetTrigger wraps the raw log trigger and provides decoded InitialActiveProtocolAdapterSetDecoded data
type InitialActiveProtocolAdapterSetTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into InitialActiveProtocolAdapterSet data
func (t *InitialActiveProtocolAdapterSetTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[InitialActiveProtocolAdapterSetDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeInitialActiveProtocolAdapterSet(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode InitialActiveProtocolAdapterSet log: %w", err)
	}

	return &bindings.DecodedLog[InitialActiveProtocolAdapterSetDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerInitialActiveProtocolAdapterSetLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []InitialActiveProtocolAdapterSetTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[InitialActiveProtocolAdapterSetDecoded]], error) {
	event := c.ABI.Events["InitialActiveProtocolAdapterSet"]
	topics, err := c.Codec.EncodeInitialActiveProtocolAdapterSetTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for InitialActiveProtocolAdapterSet: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &InitialActiveProtocolAdapterSetTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsInitialActiveProtocolAdapterSet(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.InitialActiveProtocolAdapterSetLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// LinkWithdrawnTrigger wraps the raw log trigger and provides decoded LinkWithdrawnDecoded data
type LinkWithdrawnTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
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

func (c *ParentVault) LogTriggerLinkWithdrawnLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []LinkWithdrawnTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[LinkWithdrawnDecoded]], error) {
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

func (c *ParentVault) FilterLogsLinkWithdrawn(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
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

// ManagementFeeCollectedTrigger wraps the raw log trigger and provides decoded ManagementFeeCollectedDecoded data
type ManagementFeeCollectedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into ManagementFeeCollected data
func (t *ManagementFeeCollectedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[ManagementFeeCollectedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeManagementFeeCollected(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode ManagementFeeCollected log: %w", err)
	}

	return &bindings.DecodedLog[ManagementFeeCollectedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerManagementFeeCollectedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []ManagementFeeCollectedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[ManagementFeeCollectedDecoded]], error) {
	event := c.ABI.Events["ManagementFeeCollected"]
	topics, err := c.Codec.EncodeManagementFeeCollectedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for ManagementFeeCollected: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &ManagementFeeCollectedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsManagementFeeCollected(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.ManagementFeeCollectedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// OwnershipTransferredTrigger wraps the raw log trigger and provides decoded OwnershipTransferredDecoded data
type OwnershipTransferredTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into OwnershipTransferred data
func (t *OwnershipTransferredTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[OwnershipTransferredDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeOwnershipTransferred(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode OwnershipTransferred log: %w", err)
	}

	return &bindings.DecodedLog[OwnershipTransferredDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerOwnershipTransferredLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []OwnershipTransferredTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[OwnershipTransferredDecoded]], error) {
	event := c.ABI.Events["OwnershipTransferred"]
	topics, err := c.Codec.EncodeOwnershipTransferredTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for OwnershipTransferred: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &OwnershipTransferredTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsOwnershipTransferred(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.OwnershipTransferredLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// PausedTrigger wraps the raw log trigger and provides decoded PausedDecoded data
type PausedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
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

func (c *ParentVault) LogTriggerPausedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []PausedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[PausedDecoded]], error) {
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

func (c *ParentVault) FilterLogsPaused(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
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

// PolicyEngineAttachedTrigger wraps the raw log trigger and provides decoded PolicyEngineAttachedDecoded data
type PolicyEngineAttachedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into PolicyEngineAttached data
func (t *PolicyEngineAttachedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[PolicyEngineAttachedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodePolicyEngineAttached(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode PolicyEngineAttached log: %w", err)
	}

	return &bindings.DecodedLog[PolicyEngineAttachedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerPolicyEngineAttachedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []PolicyEngineAttachedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[PolicyEngineAttachedDecoded]], error) {
	event := c.ABI.Events["PolicyEngineAttached"]
	topics, err := c.Codec.EncodePolicyEngineAttachedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for PolicyEngineAttached: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &PolicyEngineAttachedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsPolicyEngineAttached(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.PolicyEngineAttachedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// PolicyEngineDetachFailedTrigger wraps the raw log trigger and provides decoded PolicyEngineDetachFailedDecoded data
type PolicyEngineDetachFailedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into PolicyEngineDetachFailed data
func (t *PolicyEngineDetachFailedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[PolicyEngineDetachFailedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodePolicyEngineDetachFailed(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode PolicyEngineDetachFailed log: %w", err)
	}

	return &bindings.DecodedLog[PolicyEngineDetachFailedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerPolicyEngineDetachFailedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []PolicyEngineDetachFailedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[PolicyEngineDetachFailedDecoded]], error) {
	event := c.ABI.Events["PolicyEngineDetachFailed"]
	topics, err := c.Codec.EncodePolicyEngineDetachFailedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for PolicyEngineDetachFailed: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &PolicyEngineDetachFailedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsPolicyEngineDetachFailed(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.PolicyEngineDetachFailedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// RebalanceCompletedTrigger wraps the raw log trigger and provides decoded RebalanceCompletedDecoded data
type RebalanceCompletedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into RebalanceCompleted data
func (t *RebalanceCompletedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[RebalanceCompletedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeRebalanceCompleted(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode RebalanceCompleted log: %w", err)
	}

	return &bindings.DecodedLog[RebalanceCompletedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerRebalanceCompletedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []RebalanceCompletedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[RebalanceCompletedDecoded]], error) {
	event := c.ABI.Events["RebalanceCompleted"]
	topics, err := c.Codec.EncodeRebalanceCompletedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for RebalanceCompleted: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &RebalanceCompletedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsRebalanceCompleted(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.RebalanceCompletedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// RebalanceDepositFailureTrigger wraps the raw log trigger and provides decoded RebalanceDepositFailureDecoded data
type RebalanceDepositFailureTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
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

func (c *ParentVault) LogTriggerRebalanceDepositFailureLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []RebalanceDepositFailureTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[RebalanceDepositFailureDecoded]], error) {
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

func (c *ParentVault) FilterLogsRebalanceDepositFailure(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
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
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
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

func (c *ParentVault) LogTriggerRebalanceDepositRecoveryClearedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []RebalanceDepositRecoveryClearedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[RebalanceDepositRecoveryClearedDecoded]], error) {
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

func (c *ParentVault) FilterLogsRebalanceDepositRecoveryCleared(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
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
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
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

func (c *ParentVault) LogTriggerRebalanceDepositRecoveryStoredLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []RebalanceDepositRecoveryStoredTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[RebalanceDepositRecoveryStoredDecoded]], error) {
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

func (c *ParentVault) FilterLogsRebalanceDepositRecoveryStored(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
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
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
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

func (c *ParentVault) LogTriggerRebalanceDepositSuccessLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []RebalanceDepositSuccessTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[RebalanceDepositSuccessDecoded]], error) {
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

func (c *ParentVault) FilterLogsRebalanceDepositSuccess(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
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

// RebalanceInitiatedTrigger wraps the raw log trigger and provides decoded RebalanceInitiatedDecoded data
type RebalanceInitiatedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into RebalanceInitiated data
func (t *RebalanceInitiatedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[RebalanceInitiatedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeRebalanceInitiated(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode RebalanceInitiated log: %w", err)
	}

	return &bindings.DecodedLog[RebalanceInitiatedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerRebalanceInitiatedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []RebalanceInitiatedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[RebalanceInitiatedDecoded]], error) {
	event := c.ABI.Events["RebalanceInitiated"]
	topics, err := c.Codec.EncodeRebalanceInitiatedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for RebalanceInitiated: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &RebalanceInitiatedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsRebalanceInitiated(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.RebalanceInitiatedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// RebalanceWithdrawFailureTrigger wraps the raw log trigger and provides decoded RebalanceWithdrawFailureDecoded data
type RebalanceWithdrawFailureTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
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

func (c *ParentVault) LogTriggerRebalanceWithdrawFailureLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []RebalanceWithdrawFailureTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[RebalanceWithdrawFailureDecoded]], error) {
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

func (c *ParentVault) FilterLogsRebalanceWithdrawFailure(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
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

// RebalanceWithdrawSuccessTrigger wraps the raw log trigger and provides decoded RebalanceWithdrawSuccessDecoded data
type RebalanceWithdrawSuccessTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
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

func (c *ParentVault) LogTriggerRebalanceWithdrawSuccessLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []RebalanceWithdrawSuccessTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[RebalanceWithdrawSuccessDecoded]], error) {
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

func (c *ParentVault) FilterLogsRebalanceWithdrawSuccess(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
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
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
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

func (c *ParentVault) LogTriggerRoleAdminChangedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []RoleAdminChangedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[RoleAdminChangedDecoded]], error) {
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

func (c *ParentVault) FilterLogsRoleAdminChanged(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
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
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
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

func (c *ParentVault) LogTriggerRoleGrantedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []RoleGrantedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[RoleGrantedDecoded]], error) {
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

func (c *ParentVault) FilterLogsRoleGranted(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
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
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
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

func (c *ParentVault) LogTriggerRoleRevokedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []RoleRevokedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[RoleRevokedDecoded]], error) {
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

func (c *ParentVault) FilterLogsRoleRevoked(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
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

// TreasurySetTrigger wraps the raw log trigger and provides decoded TreasurySetDecoded data
type TreasurySetTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into TreasurySet data
func (t *TreasurySetTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[TreasurySetDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeTreasurySet(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode TreasurySet log: %w", err)
	}

	return &bindings.DecodedLog[TreasurySetDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerTreasurySetLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []TreasurySetTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[TreasurySetDecoded]], error) {
	event := c.ABI.Events["TreasurySet"]
	topics, err := c.Codec.EncodeTreasurySetTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for TreasurySet: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &TreasurySetTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsTreasurySet(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.TreasurySetLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// UnpausedTrigger wraps the raw log trigger and provides decoded UnpausedDecoded data
type UnpausedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
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

func (c *ParentVault) LogTriggerUnpausedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []UnpausedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[UnpausedDecoded]], error) {
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

func (c *ParentVault) FilterLogsUnpaused(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
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

// WithdrawCancelledTrigger wraps the raw log trigger and provides decoded WithdrawCancelledDecoded data
type WithdrawCancelledTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into WithdrawCancelled data
func (t *WithdrawCancelledTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[WithdrawCancelledDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeWithdrawCancelled(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode WithdrawCancelled log: %w", err)
	}

	return &bindings.DecodedLog[WithdrawCancelledDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerWithdrawCancelledLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []WithdrawCancelledTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[WithdrawCancelledDecoded]], error) {
	event := c.ABI.Events["WithdrawCancelled"]
	topics, err := c.Codec.EncodeWithdrawCancelledTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for WithdrawCancelled: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &WithdrawCancelledTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsWithdrawCancelled(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.WithdrawCancelledLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// WithdrawClaimedTrigger wraps the raw log trigger and provides decoded WithdrawClaimedDecoded data
type WithdrawClaimedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into WithdrawClaimed data
func (t *WithdrawClaimedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[WithdrawClaimedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeWithdrawClaimed(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode WithdrawClaimed log: %w", err)
	}

	return &bindings.DecodedLog[WithdrawClaimedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerWithdrawClaimedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []WithdrawClaimedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[WithdrawClaimedDecoded]], error) {
	event := c.ABI.Events["WithdrawClaimed"]
	topics, err := c.Codec.EncodeWithdrawClaimedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for WithdrawClaimed: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &WithdrawClaimedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsWithdrawClaimed(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.WithdrawClaimedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// WithdrawFeeCollectedTrigger wraps the raw log trigger and provides decoded WithdrawFeeCollectedDecoded data
type WithdrawFeeCollectedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into WithdrawFeeCollected data
func (t *WithdrawFeeCollectedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[WithdrawFeeCollectedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeWithdrawFeeCollected(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode WithdrawFeeCollected log: %w", err)
	}

	return &bindings.DecodedLog[WithdrawFeeCollectedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerWithdrawFeeCollectedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []WithdrawFeeCollectedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[WithdrawFeeCollectedDecoded]], error) {
	event := c.ABI.Events["WithdrawFeeCollected"]
	topics, err := c.Codec.EncodeWithdrawFeeCollectedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for WithdrawFeeCollected: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &WithdrawFeeCollectedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsWithdrawFeeCollected(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.WithdrawFeeCollectedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// WithdrawFromStrategyFailureTrigger wraps the raw log trigger and provides decoded WithdrawFromStrategyFailureDecoded data
type WithdrawFromStrategyFailureTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
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

func (c *ParentVault) LogTriggerWithdrawFromStrategyFailureLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []WithdrawFromStrategyFailureTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[WithdrawFromStrategyFailureDecoded]], error) {
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

func (c *ParentVault) FilterLogsWithdrawFromStrategyFailure(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
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
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
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

func (c *ParentVault) LogTriggerWithdrawFromStrategySuccessLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []WithdrawFromStrategySuccessTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[WithdrawFromStrategySuccessDecoded]], error) {
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

func (c *ParentVault) FilterLogsWithdrawFromStrategySuccess(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
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

// WithdrawSubmittedTrigger wraps the raw log trigger and provides decoded WithdrawSubmittedDecoded data
type WithdrawSubmittedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into WithdrawSubmitted data
func (t *WithdrawSubmittedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[WithdrawSubmittedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeWithdrawSubmitted(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode WithdrawSubmitted log: %w", err)
	}

	return &bindings.DecodedLog[WithdrawSubmittedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerWithdrawSubmittedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []WithdrawSubmittedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[WithdrawSubmittedDecoded]], error) {
	event := c.ABI.Events["WithdrawSubmitted"]
	topics, err := c.Codec.EncodeWithdrawSubmittedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for WithdrawSubmitted: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &WithdrawSubmittedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsWithdrawSubmitted(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.WithdrawSubmittedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

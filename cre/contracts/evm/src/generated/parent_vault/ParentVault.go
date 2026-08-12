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
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"params\",\"type\":\"tuple\",\"internalType\":\"structBaseVault.ConstructorParams\",\"components\":[{\"name\":\"link\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"asset\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"ccipRouter\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"adapterRegistry\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"thisChainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]},{\"name\":\"share\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"DEFAULT_ADMIN_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"UPGRADE_INTERFACE_VERSION\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"acceptDefaultAdminTransfer\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"beginDefaultAdminTransfer\",\"inputs\":[{\"name\":\"newAdmin\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"cancelDefaultAdminTransfer\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"cancelDeposit\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"cancelWithdraw\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"ccipReceive\",\"inputs\":[{\"name\":\"message\",\"type\":\"tuple\",\"internalType\":\"structClient.Any2EVMMessage\",\"components\":[{\"name\":\"messageId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"sourceChainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"sender\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"destTokenAmounts\",\"type\":\"tuple[]\",\"internalType\":\"structClient.EVMTokenAmount[]\",\"components\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"changeDefaultAdminDelay\",\"inputs\":[{\"name\":\"newDelay\",\"type\":\"uint48\",\"internalType\":\"uint48\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"claimAsset\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"withdrawAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"claimShares\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"shareMintAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"closeEpoch\",\"inputs\":[{\"name\":\"tvl\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"completeEpochDeposit\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"completeRebalance\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"defaultAdmin\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"defaultAdminDelay\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint48\",\"internalType\":\"uint48\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"defaultAdminDelayIncreaseWait\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint48\",\"internalType\":\"uint48\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"deposit\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"executeRecovery\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"forceCancelDeposit\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getActiveProtocolAdapter\",\"inputs\":[],\"outputs\":[{\"name\":\"activeProtocolAdapter\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAdapterRegistry\",\"inputs\":[],\"outputs\":[{\"name\":\"adapterRegistry\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAsset\",\"inputs\":[],\"outputs\":[{\"name\":\"asset\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAssetPrecision\",\"inputs\":[],\"outputs\":[{\"name\":\"assetPrecision\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getCCVsAndFinalityConfig\",\"inputs\":[{\"name\":\"\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"requiredCCVs\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"optionalCCVs\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"optionalThreshold\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"allowedFinalityConfig\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getCcipGasLimit\",\"inputs\":[{\"name\":\"chainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"outputs\":[{\"name\":\"gasLimit\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getCrosschainVault\",\"inputs\":[{\"name\":\"chainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"outputs\":[{\"name\":\"vault\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getDefaultCcipGasLimit\",\"inputs\":[],\"outputs\":[{\"name\":\"defaultCcipGasLimit\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getDepositAmount\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getEpoch\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"epoch\",\"type\":\"tuple\",\"internalType\":\"structTypes.Epoch\",\"components\":[{\"name\":\"totalDepositAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"totalShareBurnAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"totalWithdrawClaimAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"pricePerShare\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"remainingDepositClaimAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"remainingShareMintAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"remainingShareBurnAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"remainingWithdrawClaimAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"openedAtTimestamp\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"status\",\"type\":\"uint8\",\"internalType\":\"enumTypes.EpochStatus\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getEpochNonce\",\"inputs\":[],\"outputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getInitialActiveProtocolAdapterSet\",\"inputs\":[],\"outputs\":[{\"name\":\"initialActiveProtocolAdapterSet\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getLink\",\"inputs\":[],\"outputs\":[{\"name\":\"link\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getMinDepositAmount\",\"inputs\":[],\"outputs\":[{\"name\":\"minDepositAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRebalance\",\"inputs\":[],\"outputs\":[{\"name\":\"rebalance\",\"type\":\"tuple\",\"internalType\":\"structTypes.Rebalance\",\"components\":[{\"name\":\"nonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"state\",\"type\":\"uint8\",\"internalType\":\"enumTypes.RebalanceState\"},{\"name\":\"activeStrategy\",\"type\":\"tuple\",\"internalType\":\"structTypes.Strategy\",\"components\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"chainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]},{\"name\":\"pendingStrategy\",\"type\":\"tuple\",\"internalType\":\"structTypes.Strategy\",\"components\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"chainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]},{\"name\":\"lastRebalanceCompletedTimestamp\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRebalanceDepositRecovery\",\"inputs\":[],\"outputs\":[{\"name\":\"recovery\",\"type\":\"tuple\",\"internalType\":\"structTypes.RebalanceDepositRecovery\",\"components\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRecoveryMode\",\"inputs\":[],\"outputs\":[{\"name\":\"recoveryMode\",\"type\":\"uint8\",\"internalType\":\"enumTypes.RecoveryMode\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRoleAdmin\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRouter\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getShare\",\"inputs\":[],\"outputs\":[{\"name\":\"share\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getSharePrecision\",\"inputs\":[],\"outputs\":[{\"name\":\"sharePrecision\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"getSupportedProtocol\",\"inputs\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"isSupported\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getTVL\",\"inputs\":[],\"outputs\":[{\"name\":\"tvl\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getThisChainSelector\",\"inputs\":[],\"outputs\":[{\"name\":\"thisChainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getTotalShares\",\"inputs\":[],\"outputs\":[{\"name\":\"totalShares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getTreasury\",\"inputs\":[],\"outputs\":[{\"name\":\"treasury\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getWithdrawShareBurnAmount\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"shareBurnAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"grantRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"hasRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"initialize\",\"inputs\":[{\"name\":\"params\",\"type\":\"tuple\",\"internalType\":\"structBaseVault.InitParams\",\"components\":[{\"name\":\"defaultAdmin\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"pauser\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"unpauser\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"configOperator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"initialDefaultCcipGasLimit\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"upgrader\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"name\":\"treasury\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"cancelDepositOperator\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"initiateRebalance\",\"inputs\":[{\"name\":\"newStrategy\",\"type\":\"tuple\",\"internalType\":\"structTypes.Strategy\",\"components\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"chainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"owner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pause\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"paused\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pendingDefaultAdmin\",\"inputs\":[],\"outputs\":[{\"name\":\"newAdmin\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"schedule\",\"type\":\"uint48\",\"internalType\":\"uint48\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pendingDefaultAdminDelay\",\"inputs\":[],\"outputs\":[{\"name\":\"newDelay\",\"type\":\"uint48\",\"internalType\":\"uint48\"},{\"name\":\"schedule\",\"type\":\"uint48\",\"internalType\":\"uint48\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"proxiableUUID\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"renounceRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"revokeRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"rollbackDefaultAdminDelay\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setCcipGasLimit\",\"inputs\":[{\"name\":\"chainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"gasLimit\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setCrosschainVaults\",\"inputs\":[{\"name\":\"chainSelectors\",\"type\":\"uint64[]\",\"internalType\":\"uint64[]\"},{\"name\":\"vaults\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setDefaultCcipGasLimit\",\"inputs\":[{\"name\":\"gasLimit\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setInitialActiveProtocolAdapter\",\"inputs\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setSupportedProtocol\",\"inputs\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"isSupported\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setTreasury\",\"inputs\":[{\"name\":\"treasury\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"isSupported\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"tryDepositToAdapter\",\"inputs\":[{\"name\":\"adapter\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"unpause\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"upgradeToAndCall\",\"inputs\":[{\"name\":\"newImplementation\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"withdraw\",\"inputs\":[{\"name\":\"shareBurnAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"withdrawLink\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"ActiveProtocolAdapterCleared\",\"inputs\":[{\"name\":\"adapter\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ActiveProtocolAdapterSet\",\"inputs\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"adapter\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"CCIPBridged\",\"inputs\":[{\"name\":\"ccipMessageId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"destinationChainSelector\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"},{\"name\":\"ccipTxType\",\"type\":\"uint8\",\"indexed\":true,\"internalType\":\"enumTypes.CcipTx\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"CCIPReceived\",\"inputs\":[{\"name\":\"ccipMessageId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"sourceChainSelector\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"},{\"name\":\"ccipTxType\",\"type\":\"uint8\",\"indexed\":true,\"internalType\":\"enumTypes.CcipTx\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"CcipGasLimitSet\",\"inputs\":[{\"name\":\"chainSelector\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"},{\"name\":\"gasLimit\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"CrosschainVaultSet\",\"inputs\":[{\"name\":\"chainSelector\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"},{\"name\":\"vault\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DefaultAdminDelayChangeCanceled\",\"inputs\":[],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DefaultAdminDelayChangeScheduled\",\"inputs\":[{\"name\":\"newDelay\",\"type\":\"uint48\",\"indexed\":false,\"internalType\":\"uint48\"},{\"name\":\"effectSchedule\",\"type\":\"uint48\",\"indexed\":false,\"internalType\":\"uint48\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DefaultAdminTransferCanceled\",\"inputs\":[],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DefaultAdminTransferScheduled\",\"inputs\":[{\"name\":\"newAdmin\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"acceptSchedule\",\"type\":\"uint48\",\"indexed\":false,\"internalType\":\"uint48\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DefaultCcipGasLimitSet\",\"inputs\":[{\"name\":\"gasLimit\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DepositCancelled\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"depositor\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DepositClaimed\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"depositor\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"shareMintAmount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DepositForceCancelled\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"depositor\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DepositSubmitted\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"depositor\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"EpochClaimable\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"EpochClaimable\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"EpochDepositExecuting\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"EpochDepositToStrategySuccess\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"EpochOpen\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"EpochWithdrawAmountShort\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"expectedAmount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"actualAmount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"EpochWithdrawAmountShort\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"expectedAmount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"actualAmount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"EpochWithdrawExecuting\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"EpochWithdrawFromStrategySuccess\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"InitialActiveProtocolAdapterSet\",\"inputs\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"adapter\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Initialized\",\"inputs\":[{\"name\":\"version\",\"type\":\"uint64\",\"indexed\":false,\"internalType\":\"uint64\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"LinkWithdrawn\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ManagementFeeCollected\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"feeShares\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ManagementFeeCollected\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"feeShares\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Paused\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RebalanceCompleted\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"newProtocolId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"newChainSelector\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RebalanceCompleted\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"newProtocolId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"newChainSelector\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RebalanceDepositFailure\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RebalanceDepositRecoveryCleared\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RebalanceDepositRecoveryStored\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RebalanceDepositSuccess\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RebalanceInitiated\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"protocolId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"chainSelector\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RebalanceWithdrawSuccess\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleAdminChanged\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"previousAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"newAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleGranted\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleRevoked\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SupportedProtocolSet\",\"inputs\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"isSupported\",\"type\":\"bool\",\"indexed\":true,\"internalType\":\"bool\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TreasurySet\",\"inputs\":[{\"name\":\"treasury\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Unpaused\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Upgraded\",\"inputs\":[{\"name\":\"implementation\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"WithdrawCancelled\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"withdrawer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"shareBurnAmount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"WithdrawClaimed\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"withdrawer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"WithdrawSubmitted\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"withdrawer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"shareBurnAmount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"AccessControlBadConfirmation\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"AccessControlEnforcedDefaultAdminDelay\",\"inputs\":[{\"name\":\"schedule\",\"type\":\"uint48\",\"internalType\":\"uint48\"}]},{\"type\":\"error\",\"name\":\"AccessControlEnforcedDefaultAdminRules\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"AccessControlInvalidDefaultAdmin\",\"inputs\":[{\"name\":\"defaultAdmin\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"AccessControlUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"neededRole\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"AddressEmptyCode\",\"inputs\":[{\"name\":\"target\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"BaseVault__DepositFailed\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"BaseVault__DestinationVaultNotSet\",\"inputs\":[{\"name\":\"destinationChainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]},{\"type\":\"error\",\"name\":\"BaseVault__EmptyInput\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"BaseVault__InvalidAdapterVault\",\"inputs\":[{\"name\":\"adapter\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"actualVault\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"expectedVault\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"BaseVault__InvalidDestinationChainSelector\",\"inputs\":[{\"name\":\"destinationChainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]},{\"type\":\"error\",\"name\":\"BaseVault__InvalidInputLengths\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"BaseVault__InvalidReceivedToken\",\"inputs\":[{\"name\":\"receivedToken\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"expectedToken\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"BaseVault__InvalidSender\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"srcChainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]},{\"type\":\"error\",\"name\":\"BaseVault__InvalidSourceChainSelector\",\"inputs\":[{\"name\":\"sourceChainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"expectedSourceChainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]},{\"type\":\"error\",\"name\":\"BaseVault__InvalidTokenAmountsLength\",\"inputs\":[{\"name\":\"receivedLength\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"expectedLength\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"BaseVault__InvalidTxType\",\"inputs\":[{\"name\":\"ccipTxType\",\"type\":\"uint8\",\"internalType\":\"enumTypes.CcipTx\"}]},{\"type\":\"error\",\"name\":\"BaseVault__NoActiveAdapter\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"BaseVault__NoAdapterRegistered\",\"inputs\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"BaseVault__NoPendingRecovery\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"BaseVault__NoZeroAddress\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"BaseVault__NoZeroAmount\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"BaseVault__NoZeroChainSelector\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"BaseVault__OnlySelf\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"BaseVault__RecoveryAlreadyPending\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"BaseVault__WithdrawFailed\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"BaseVault__ZeroRecoveryAmount\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ERC1967InvalidImplementation\",\"inputs\":[{\"name\":\"implementation\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1967NonPayable\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"EnforcedPause\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ExpectedPause\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"FailedCall\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidInitialization\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidRouter\",\"inputs\":[{\"name\":\"router\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"NotInitializing\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ParentVault__AmountTooSmall\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ParentVault__CannotRemoveActiveProtocol\",\"inputs\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"ParentVault__CannotRemovePendingProtocol\",\"inputs\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"ParentVault__DepositWouldMintZeroShares\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ParentVault__EmptyEpoch\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ParentVault__EpochExecuting\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ParentVault__EpochNotClaimable\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ParentVault__EpochNotExecuting\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ParentVault__EpochNotNetDeposit\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ParentVault__EpochNotOpen\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ParentVault__EpochTooShort\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ParentVault__InitialActiveProtocolAdapterAlreadySet\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ParentVault__InvalidChainSelector\",\"inputs\":[{\"name\":\"chainSelector\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]},{\"type\":\"error\",\"name\":\"ParentVault__InvalidEpochNonce\",\"inputs\":[{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ParentVault__InvalidPendingProtocolId\",\"inputs\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"ParentVault__InvalidProtocolId\",\"inputs\":[{\"name\":\"protocolId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"ParentVault__InvalidRebalanceNonce\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ParentVault__NoCompletedEpoch\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ParentVault__NoDeposit\",\"inputs\":[{\"name\":\"depositor\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ParentVault__NoRebalanceInProgress\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ParentVault__NoWithdraw\",\"inputs\":[{\"name\":\"withdrawer\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"epochNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ParentVault__NoZeroAmount\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ParentVault__NoZeroProtocolId\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ParentVault__RebalanceInProgress\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ParentVault__RebalanceTooSoon\",\"inputs\":[{\"name\":\"rebalanceNonce\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ParentVault__SameStrategy\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ParentVault__ZeroPricePerShare\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ParentVault__ZeroTvlWithOutstandingShares\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ReentrancyGuardReentrantCall\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SafeCastOverflowedUintDowncast\",\"inputs\":[{\"name\":\"bits\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"SafeERC20FailedOperation\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"UUPSUnauthorizedCallContext\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"UUPSUnsupportedProxiableUUID\",\"inputs\":[{\"name\":\"slot\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]}]",
}

// Structs
type BaseVaultConstructorParams struct {
	Link              common.Address
	Asset             common.Address
	CcipRouter        common.Address
	AdapterRegistry   common.Address
	ThisChainSelector uint64
}

type BaseVaultInitParams struct {
	DefaultAdmin               common.Address
	Pauser                     common.Address
	Unpauser                   common.Address
	ConfigOperator             common.Address
	InitialDefaultCcipGasLimit *big.Int
	Upgrader                   common.Address
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

type TypesEpoch struct {
	TotalDepositAmount           *big.Int
	TotalShareBurnAmount         *big.Int
	TotalWithdrawClaimAmount     *big.Int
	PricePerShare                *big.Int
	RemainingDepositClaimAmount  *big.Int
	RemainingShareMintAmount     *big.Int
	RemainingShareBurnAmount     *big.Int
	RemainingWithdrawClaimAmount *big.Int
	OpenedAtTimestamp            *big.Int
	Status                       uint8
}

type TypesRebalance struct {
	Nonce                           *big.Int
	State                           uint8
	ActiveStrategy                  TypesStrategy
	PendingStrategy                 TypesStrategy
	LastRebalanceCompletedTimestamp *big.Int
}

type TypesRebalanceDepositRecovery struct {
	RebalanceNonce *big.Int
	Amount         *big.Int
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

type ClaimAssetInput struct {
	EpochNonce *big.Int
}

type ClaimSharesInput struct {
	EpochNonce *big.Int
}

type CloseEpochInput struct {
	Tvl *big.Int
}

type DepositInput struct {
	Amount *big.Int
}

type ForceCancelDepositInput struct {
	User common.Address
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

type GetRoleAdminInput struct {
	Role [32]byte
}

type GetSupportedProtocolInput struct {
	ProtocolId [32]byte
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

type InitializeInput struct {
	Params                BaseVaultInitParams
	Treasury              common.Address
	CancelDepositOperator common.Address
}

type InitiateRebalanceInput struct {
	NewStrategy TypesStrategy
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

type SetInitialActiveProtocolAdapterInput struct {
	ProtocolId [32]byte
}

type SetSupportedProtocolInput struct {
	ProtocolId  [32]byte
	IsSupported bool
}

type SetTreasuryInput struct {
	Treasury common.Address
}

type SupportsInterfaceInput struct {
	InterfaceId [4]byte
}

type TryDepositToAdapterInput struct {
	Adapter common.Address
	Amount  *big.Int
}

type UpgradeToAndCallInput struct {
	NewImplementation common.Address
	Data              []byte
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

type AddressEmptyCode struct {
	Target common.Address
}

type BaseVaultDepositFailed struct {
	Amount *big.Int
}

type BaseVaultDestinationVaultNotSet struct {
	DestinationChainSelector uint64
}

type BaseVaultEmptyInput struct {
}

type BaseVaultInvalidAdapterVault struct {
	Adapter       common.Address
	ActualVault   common.Address
	ExpectedVault common.Address
}

type BaseVaultInvalidDestinationChainSelector struct {
	DestinationChainSelector uint64
}

type BaseVaultInvalidInputLengths struct {
}

type BaseVaultInvalidReceivedToken struct {
	ReceivedToken common.Address
	ExpectedToken common.Address
}

type BaseVaultInvalidSender struct {
	Sender           common.Address
	SrcChainSelector uint64
}

type BaseVaultInvalidSourceChainSelector struct {
	SourceChainSelector         uint64
	ExpectedSourceChainSelector uint64
}

type BaseVaultInvalidTokenAmountsLength struct {
	ReceivedLength *big.Int
	ExpectedLength *big.Int
}

type BaseVaultInvalidTxType struct {
	CcipTxType uint8
}

type BaseVaultNoActiveAdapter struct {
}

type BaseVaultNoAdapterRegistered struct {
	ProtocolId [32]byte
}

type BaseVaultNoPendingRecovery struct {
}

type BaseVaultNoZeroAddress struct {
}

type BaseVaultNoZeroAmount struct {
}

type BaseVaultNoZeroChainSelector struct {
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

type ERC1967InvalidImplementation struct {
	Implementation common.Address
}

type ERC1967NonPayable struct {
}

type EnforcedPause struct {
}

type ExpectedPause struct {
}

type FailedCall struct {
}

type InvalidInitialization struct {
}

type InvalidRouter struct {
	Router common.Address
}

type NotInitializing struct {
}

type ParentVaultAmountTooSmall struct {
	Amount *big.Int
}

type ParentVaultCannotRemoveActiveProtocol struct {
	ProtocolId [32]byte
}

type ParentVaultCannotRemovePendingProtocol struct {
	ProtocolId [32]byte
}

type ParentVaultDepositWouldMintZeroShares struct {
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

type ParentVaultEpochNotNetDeposit struct {
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

type ParentVaultInvalidChainSelector struct {
	ChainSelector uint64
}

type ParentVaultInvalidEpochNonce struct {
	EpochNonce *big.Int
}

type ParentVaultInvalidPendingProtocolId struct {
	ProtocolId [32]byte
}

type ParentVaultInvalidProtocolId struct {
	ProtocolId [32]byte
}

type ParentVaultInvalidRebalanceNonce struct {
	RebalanceNonce *big.Int
}

type ParentVaultNoCompletedEpoch struct {
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

type ParentVaultNoZeroProtocolId struct {
}

type ParentVaultRebalanceInProgress struct {
}

type ParentVaultRebalanceTooSoon struct {
	RebalanceNonce *big.Int
}

type ParentVaultSameStrategy struct {
}

type ParentVaultZeroPricePerShare struct {
}

type ParentVaultZeroTvlWithOutstandingShares struct {
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

type UUPSUnauthorizedCallContext struct {
}

type UUPSUnsupportedProxiableUUID struct {
	Slot [32]byte
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

type ActiveProtocolAdapterClearedTopics struct {
	Adapter common.Address
}

type ActiveProtocolAdapterClearedDecoded struct {
	Adapter common.Address
}

type ActiveProtocolAdapterSetTopics struct {
	ProtocolId [32]byte
	Adapter    common.Address
}

type ActiveProtocolAdapterSetDecoded struct {
	ProtocolId [32]byte
	Adapter    common.Address
}

type CCIPBridgedTopics struct {
	CcipMessageId            [32]byte
	DestinationChainSelector uint64
	CcipTxType               uint8
}

type CCIPBridgedDecoded struct {
	CcipMessageId            [32]byte
	DestinationChainSelector uint64
	CcipTxType               uint8
}

type CCIPReceivedTopics struct {
	CcipMessageId       [32]byte
	SourceChainSelector uint64
	CcipTxType          uint8
}

type CCIPReceivedDecoded struct {
	CcipMessageId       [32]byte
	SourceChainSelector uint64
	CcipTxType          uint8
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

type DepositForceCancelledTopics struct {
	EpochNonce *big.Int
	Depositor  common.Address
	Amount     *big.Int
}

type DepositForceCancelledDecoded struct {
	EpochNonce *big.Int
	Depositor  common.Address
	Amount     *big.Int
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

type EpochClaimableTopics struct {
	EpochNonce *big.Int
}

type EpochClaimableDecoded struct {
	EpochNonce *big.Int
}

type EpochClaimable0Topics struct {
	EpochNonce *big.Int
}

type EpochClaimable0Decoded struct {
	EpochNonce *big.Int
}

type EpochDepositExecutingTopics struct {
	EpochNonce *big.Int
	Amount     *big.Int
}

type EpochDepositExecutingDecoded struct {
	EpochNonce *big.Int
	Amount     *big.Int
}

type EpochDepositToStrategySuccessTopics struct {
	EpochNonce *big.Int
	Amount     *big.Int
}

type EpochDepositToStrategySuccessDecoded struct {
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
	EpochNonce     *big.Int
	ExpectedAmount *big.Int
	ActualAmount   *big.Int
}

type EpochWithdrawAmountShortDecoded struct {
	EpochNonce     *big.Int
	ExpectedAmount *big.Int
	ActualAmount   *big.Int
}

type EpochWithdrawAmountShort0Topics struct {
	EpochNonce     *big.Int
	ExpectedAmount *big.Int
	ActualAmount   *big.Int
}

type EpochWithdrawAmountShort0Decoded struct {
	EpochNonce     *big.Int
	ExpectedAmount *big.Int
	ActualAmount   *big.Int
}

type EpochWithdrawExecutingTopics struct {
	EpochNonce *big.Int
	Amount     *big.Int
}

type EpochWithdrawExecutingDecoded struct {
	EpochNonce *big.Int
	Amount     *big.Int
}

type EpochWithdrawFromStrategySuccessTopics struct {
	EpochNonce *big.Int
	Amount     *big.Int
}

type EpochWithdrawFromStrategySuccessDecoded struct {
	EpochNonce *big.Int
	Amount     *big.Int
}

type InitialActiveProtocolAdapterSetTopics struct {
	ProtocolId [32]byte
	Adapter    common.Address
}

type InitialActiveProtocolAdapterSetDecoded struct {
	ProtocolId [32]byte
	Adapter    common.Address
}

type InitializedTopics struct {
}

type InitializedDecoded struct {
	Version uint64
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
	RebalanceNonce *big.Int
	FeeShares      *big.Int
}

type ManagementFeeCollectedDecoded struct {
	RebalanceNonce *big.Int
	FeeShares      *big.Int
}

type ManagementFeeCollected0Topics struct {
	RebalanceNonce *big.Int
	FeeShares      *big.Int
}

type ManagementFeeCollected0Decoded struct {
	RebalanceNonce *big.Int
	FeeShares      *big.Int
}

type PausedTopics struct {
}

type PausedDecoded struct {
	Account common.Address
}

type RebalanceCompletedTopics struct {
	RebalanceNonce   *big.Int
	NewProtocolId    [32]byte
	NewChainSelector uint64
}

type RebalanceCompletedDecoded struct {
	RebalanceNonce   *big.Int
	NewProtocolId    [32]byte
	NewChainSelector uint64
}

type RebalanceCompleted0Topics struct {
	RebalanceNonce   *big.Int
	NewProtocolId    [32]byte
	NewChainSelector uint64
}

type RebalanceCompleted0Decoded struct {
	RebalanceNonce   *big.Int
	NewProtocolId    [32]byte
	NewChainSelector uint64
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
	ProtocolId     [32]byte
	ChainSelector  uint64
}

type RebalanceInitiatedDecoded struct {
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

type SupportedProtocolSetTopics struct {
	ProtocolId  [32]byte
	IsSupported bool
}

type SupportedProtocolSetDecoded struct {
	ProtocolId  [32]byte
	IsSupported bool
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

type UpgradedTopics struct {
	Implementation common.Address
}

type UpgradedDecoded struct {
	Implementation common.Address
}

type WithdrawCancelledTopics struct {
	EpochNonce      *big.Int
	Withdrawer      common.Address
	ShareBurnAmount *big.Int
}

type WithdrawCancelledDecoded struct {
	EpochNonce      *big.Int
	Withdrawer      common.Address
	ShareBurnAmount *big.Int
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
	EncodeUPGRADEINTERFACEVERSIONMethodCall() ([]byte, error)
	DecodeUPGRADEINTERFACEVERSIONMethodOutput(data []byte) (string, error)
	EncodeAcceptDefaultAdminTransferMethodCall() ([]byte, error)
	EncodeBeginDefaultAdminTransferMethodCall(in BeginDefaultAdminTransferInput) ([]byte, error)
	EncodeCancelDefaultAdminTransferMethodCall() ([]byte, error)
	EncodeCancelDepositMethodCall() ([]byte, error)
	EncodeCancelWithdrawMethodCall() ([]byte, error)
	EncodeCcipReceiveMethodCall(in CcipReceiveInput) ([]byte, error)
	EncodeChangeDefaultAdminDelayMethodCall(in ChangeDefaultAdminDelayInput) ([]byte, error)
	EncodeClaimAssetMethodCall(in ClaimAssetInput) ([]byte, error)
	DecodeClaimAssetMethodOutput(data []byte) (*big.Int, error)
	EncodeClaimSharesMethodCall(in ClaimSharesInput) ([]byte, error)
	DecodeClaimSharesMethodOutput(data []byte) (*big.Int, error)
	EncodeCloseEpochMethodCall(in CloseEpochInput) ([]byte, error)
	EncodeCompleteEpochDepositMethodCall() ([]byte, error)
	EncodeCompleteRebalanceMethodCall() ([]byte, error)
	EncodeDefaultAdminMethodCall() ([]byte, error)
	DecodeDefaultAdminMethodOutput(data []byte) (common.Address, error)
	EncodeDefaultAdminDelayMethodCall() ([]byte, error)
	DecodeDefaultAdminDelayMethodOutput(data []byte) (*big.Int, error)
	EncodeDefaultAdminDelayIncreaseWaitMethodCall() ([]byte, error)
	DecodeDefaultAdminDelayIncreaseWaitMethodOutput(data []byte) (*big.Int, error)
	EncodeDepositMethodCall(in DepositInput) ([]byte, error)
	DecodeDepositMethodOutput(data []byte) (*big.Int, error)
	EncodeExecuteRecoveryMethodCall() ([]byte, error)
	EncodeForceCancelDepositMethodCall(in ForceCancelDepositInput) ([]byte, error)
	EncodeGetActiveProtocolAdapterMethodCall() ([]byte, error)
	DecodeGetActiveProtocolAdapterMethodOutput(data []byte) (common.Address, error)
	EncodeGetAdapterRegistryMethodCall() ([]byte, error)
	DecodeGetAdapterRegistryMethodOutput(data []byte) (common.Address, error)
	EncodeGetAssetMethodCall() ([]byte, error)
	DecodeGetAssetMethodOutput(data []byte) (common.Address, error)
	EncodeGetAssetPrecisionMethodCall() ([]byte, error)
	DecodeGetAssetPrecisionMethodOutput(data []byte) (*big.Int, error)
	EncodeGetCCVsAndFinalityConfigMethodCall(in GetCCVsAndFinalityConfigInput) ([]byte, error)
	DecodeGetCCVsAndFinalityConfigMethodOutput(data []byte) (GetCCVsAndFinalityConfigOutput, error)
	EncodeGetCcipGasLimitMethodCall(in GetCcipGasLimitInput) ([]byte, error)
	DecodeGetCcipGasLimitMethodOutput(data []byte) (*big.Int, error)
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
	EncodeGetMinDepositAmountMethodCall() ([]byte, error)
	DecodeGetMinDepositAmountMethodOutput(data []byte) (*big.Int, error)
	EncodeGetRebalanceMethodCall() ([]byte, error)
	DecodeGetRebalanceMethodOutput(data []byte) (TypesRebalance, error)
	EncodeGetRebalanceDepositRecoveryMethodCall() ([]byte, error)
	DecodeGetRebalanceDepositRecoveryMethodOutput(data []byte) (TypesRebalanceDepositRecovery, error)
	EncodeGetRecoveryModeMethodCall() ([]byte, error)
	DecodeGetRecoveryModeMethodOutput(data []byte) (uint8, error)
	EncodeGetRoleAdminMethodCall(in GetRoleAdminInput) ([]byte, error)
	DecodeGetRoleAdminMethodOutput(data []byte) ([32]byte, error)
	EncodeGetRouterMethodCall() ([]byte, error)
	DecodeGetRouterMethodOutput(data []byte) (common.Address, error)
	EncodeGetShareMethodCall() ([]byte, error)
	DecodeGetShareMethodOutput(data []byte) (common.Address, error)
	EncodeGetSharePrecisionMethodCall() ([]byte, error)
	DecodeGetSharePrecisionMethodOutput(data []byte) (*big.Int, error)
	EncodeGetSupportedProtocolMethodCall(in GetSupportedProtocolInput) ([]byte, error)
	DecodeGetSupportedProtocolMethodOutput(data []byte) (bool, error)
	EncodeGetTVLMethodCall() ([]byte, error)
	DecodeGetTVLMethodOutput(data []byte) (*big.Int, error)
	EncodeGetThisChainSelectorMethodCall() ([]byte, error)
	DecodeGetThisChainSelectorMethodOutput(data []byte) (uint64, error)
	EncodeGetTotalSharesMethodCall() ([]byte, error)
	DecodeGetTotalSharesMethodOutput(data []byte) (*big.Int, error)
	EncodeGetTreasuryMethodCall() ([]byte, error)
	DecodeGetTreasuryMethodOutput(data []byte) (common.Address, error)
	EncodeGetWithdrawShareBurnAmountMethodCall(in GetWithdrawShareBurnAmountInput) ([]byte, error)
	DecodeGetWithdrawShareBurnAmountMethodOutput(data []byte) (*big.Int, error)
	EncodeGrantRoleMethodCall(in GrantRoleInput) ([]byte, error)
	EncodeHasRoleMethodCall(in HasRoleInput) ([]byte, error)
	DecodeHasRoleMethodOutput(data []byte) (bool, error)
	EncodeInitializeMethodCall(in InitializeInput) ([]byte, error)
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
	EncodeProxiableUUIDMethodCall() ([]byte, error)
	DecodeProxiableUUIDMethodOutput(data []byte) ([32]byte, error)
	EncodeRenounceRoleMethodCall(in RenounceRoleInput) ([]byte, error)
	EncodeRevokeRoleMethodCall(in RevokeRoleInput) ([]byte, error)
	EncodeRollbackDefaultAdminDelayMethodCall() ([]byte, error)
	EncodeSetCcipGasLimitMethodCall(in SetCcipGasLimitInput) ([]byte, error)
	EncodeSetCrosschainVaultsMethodCall(in SetCrosschainVaultsInput) ([]byte, error)
	EncodeSetDefaultCcipGasLimitMethodCall(in SetDefaultCcipGasLimitInput) ([]byte, error)
	EncodeSetInitialActiveProtocolAdapterMethodCall(in SetInitialActiveProtocolAdapterInput) ([]byte, error)
	EncodeSetSupportedProtocolMethodCall(in SetSupportedProtocolInput) ([]byte, error)
	EncodeSetTreasuryMethodCall(in SetTreasuryInput) ([]byte, error)
	EncodeSupportsInterfaceMethodCall(in SupportsInterfaceInput) ([]byte, error)
	DecodeSupportsInterfaceMethodOutput(data []byte) (bool, error)
	EncodeTryDepositToAdapterMethodCall(in TryDepositToAdapterInput) ([]byte, error)
	EncodeUnpauseMethodCall() ([]byte, error)
	EncodeUpgradeToAndCallMethodCall(in UpgradeToAndCallInput) ([]byte, error)
	EncodeWithdrawMethodCall(in WithdrawInput) ([]byte, error)
	DecodeWithdrawMethodOutput(data []byte) (*big.Int, error)
	EncodeWithdrawLinkMethodCall(in WithdrawLinkInput) ([]byte, error)
	EncodeBaseVaultConstructorParamsStruct(in BaseVaultConstructorParams) ([]byte, error)
	EncodeBaseVaultInitParamsStruct(in BaseVaultInitParams) ([]byte, error)
	EncodeClientAny2EVMMessageStruct(in ClientAny2EVMMessage) ([]byte, error)
	EncodeClientEVMTokenAmountStruct(in ClientEVMTokenAmount) ([]byte, error)
	EncodeTypesEpochStruct(in TypesEpoch) ([]byte, error)
	EncodeTypesRebalanceStruct(in TypesRebalance) ([]byte, error)
	EncodeTypesRebalanceDepositRecoveryStruct(in TypesRebalanceDepositRecovery) ([]byte, error)
	EncodeTypesStrategyStruct(in TypesStrategy) ([]byte, error)
	ActiveProtocolAdapterClearedLogHash() []byte
	EncodeActiveProtocolAdapterClearedTopics(evt abi.Event, values []ActiveProtocolAdapterClearedTopics) ([]*evm.TopicValues, error)
	DecodeActiveProtocolAdapterCleared(log *evm.Log) (*ActiveProtocolAdapterClearedDecoded, error)
	ActiveProtocolAdapterSetLogHash() []byte
	EncodeActiveProtocolAdapterSetTopics(evt abi.Event, values []ActiveProtocolAdapterSetTopics) ([]*evm.TopicValues, error)
	DecodeActiveProtocolAdapterSet(log *evm.Log) (*ActiveProtocolAdapterSetDecoded, error)
	CCIPBridgedLogHash() []byte
	EncodeCCIPBridgedTopics(evt abi.Event, values []CCIPBridgedTopics) ([]*evm.TopicValues, error)
	DecodeCCIPBridged(log *evm.Log) (*CCIPBridgedDecoded, error)
	CCIPReceivedLogHash() []byte
	EncodeCCIPReceivedTopics(evt abi.Event, values []CCIPReceivedTopics) ([]*evm.TopicValues, error)
	DecodeCCIPReceived(log *evm.Log) (*CCIPReceivedDecoded, error)
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
	DepositForceCancelledLogHash() []byte
	EncodeDepositForceCancelledTopics(evt abi.Event, values []DepositForceCancelledTopics) ([]*evm.TopicValues, error)
	DecodeDepositForceCancelled(log *evm.Log) (*DepositForceCancelledDecoded, error)
	DepositSubmittedLogHash() []byte
	EncodeDepositSubmittedTopics(evt abi.Event, values []DepositSubmittedTopics) ([]*evm.TopicValues, error)
	DecodeDepositSubmitted(log *evm.Log) (*DepositSubmittedDecoded, error)
	EpochClaimableLogHash() []byte
	EncodeEpochClaimableTopics(evt abi.Event, values []EpochClaimableTopics) ([]*evm.TopicValues, error)
	DecodeEpochClaimable(log *evm.Log) (*EpochClaimableDecoded, error)
	EpochClaimable0LogHash() []byte
	EncodeEpochClaimable0Topics(evt abi.Event, values []EpochClaimable0Topics) ([]*evm.TopicValues, error)
	DecodeEpochClaimable0(log *evm.Log) (*EpochClaimable0Decoded, error)
	EpochDepositExecutingLogHash() []byte
	EncodeEpochDepositExecutingTopics(evt abi.Event, values []EpochDepositExecutingTopics) ([]*evm.TopicValues, error)
	DecodeEpochDepositExecuting(log *evm.Log) (*EpochDepositExecutingDecoded, error)
	EpochDepositToStrategySuccessLogHash() []byte
	EncodeEpochDepositToStrategySuccessTopics(evt abi.Event, values []EpochDepositToStrategySuccessTopics) ([]*evm.TopicValues, error)
	DecodeEpochDepositToStrategySuccess(log *evm.Log) (*EpochDepositToStrategySuccessDecoded, error)
	EpochOpenLogHash() []byte
	EncodeEpochOpenTopics(evt abi.Event, values []EpochOpenTopics) ([]*evm.TopicValues, error)
	DecodeEpochOpen(log *evm.Log) (*EpochOpenDecoded, error)
	EpochWithdrawAmountShortLogHash() []byte
	EncodeEpochWithdrawAmountShortTopics(evt abi.Event, values []EpochWithdrawAmountShortTopics) ([]*evm.TopicValues, error)
	DecodeEpochWithdrawAmountShort(log *evm.Log) (*EpochWithdrawAmountShortDecoded, error)
	EpochWithdrawAmountShort0LogHash() []byte
	EncodeEpochWithdrawAmountShort0Topics(evt abi.Event, values []EpochWithdrawAmountShort0Topics) ([]*evm.TopicValues, error)
	DecodeEpochWithdrawAmountShort0(log *evm.Log) (*EpochWithdrawAmountShort0Decoded, error)
	EpochWithdrawExecutingLogHash() []byte
	EncodeEpochWithdrawExecutingTopics(evt abi.Event, values []EpochWithdrawExecutingTopics) ([]*evm.TopicValues, error)
	DecodeEpochWithdrawExecuting(log *evm.Log) (*EpochWithdrawExecutingDecoded, error)
	EpochWithdrawFromStrategySuccessLogHash() []byte
	EncodeEpochWithdrawFromStrategySuccessTopics(evt abi.Event, values []EpochWithdrawFromStrategySuccessTopics) ([]*evm.TopicValues, error)
	DecodeEpochWithdrawFromStrategySuccess(log *evm.Log) (*EpochWithdrawFromStrategySuccessDecoded, error)
	InitialActiveProtocolAdapterSetLogHash() []byte
	EncodeInitialActiveProtocolAdapterSetTopics(evt abi.Event, values []InitialActiveProtocolAdapterSetTopics) ([]*evm.TopicValues, error)
	DecodeInitialActiveProtocolAdapterSet(log *evm.Log) (*InitialActiveProtocolAdapterSetDecoded, error)
	InitializedLogHash() []byte
	EncodeInitializedTopics(evt abi.Event, values []InitializedTopics) ([]*evm.TopicValues, error)
	DecodeInitialized(log *evm.Log) (*InitializedDecoded, error)
	LinkWithdrawnLogHash() []byte
	EncodeLinkWithdrawnTopics(evt abi.Event, values []LinkWithdrawnTopics) ([]*evm.TopicValues, error)
	DecodeLinkWithdrawn(log *evm.Log) (*LinkWithdrawnDecoded, error)
	ManagementFeeCollectedLogHash() []byte
	EncodeManagementFeeCollectedTopics(evt abi.Event, values []ManagementFeeCollectedTopics) ([]*evm.TopicValues, error)
	DecodeManagementFeeCollected(log *evm.Log) (*ManagementFeeCollectedDecoded, error)
	ManagementFeeCollected0LogHash() []byte
	EncodeManagementFeeCollected0Topics(evt abi.Event, values []ManagementFeeCollected0Topics) ([]*evm.TopicValues, error)
	DecodeManagementFeeCollected0(log *evm.Log) (*ManagementFeeCollected0Decoded, error)
	PausedLogHash() []byte
	EncodePausedTopics(evt abi.Event, values []PausedTopics) ([]*evm.TopicValues, error)
	DecodePaused(log *evm.Log) (*PausedDecoded, error)
	RebalanceCompletedLogHash() []byte
	EncodeRebalanceCompletedTopics(evt abi.Event, values []RebalanceCompletedTopics) ([]*evm.TopicValues, error)
	DecodeRebalanceCompleted(log *evm.Log) (*RebalanceCompletedDecoded, error)
	RebalanceCompleted0LogHash() []byte
	EncodeRebalanceCompleted0Topics(evt abi.Event, values []RebalanceCompleted0Topics) ([]*evm.TopicValues, error)
	DecodeRebalanceCompleted0(log *evm.Log) (*RebalanceCompleted0Decoded, error)
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
	SupportedProtocolSetLogHash() []byte
	EncodeSupportedProtocolSetTopics(evt abi.Event, values []SupportedProtocolSetTopics) ([]*evm.TopicValues, error)
	DecodeSupportedProtocolSet(log *evm.Log) (*SupportedProtocolSetDecoded, error)
	TreasurySetLogHash() []byte
	EncodeTreasurySetTopics(evt abi.Event, values []TreasurySetTopics) ([]*evm.TopicValues, error)
	DecodeTreasurySet(log *evm.Log) (*TreasurySetDecoded, error)
	UnpausedLogHash() []byte
	EncodeUnpausedTopics(evt abi.Event, values []UnpausedTopics) ([]*evm.TopicValues, error)
	DecodeUnpaused(log *evm.Log) (*UnpausedDecoded, error)
	UpgradedLogHash() []byte
	EncodeUpgradedTopics(evt abi.Event, values []UpgradedTopics) ([]*evm.TopicValues, error)
	DecodeUpgraded(log *evm.Log) (*UpgradedDecoded, error)
	WithdrawCancelledLogHash() []byte
	EncodeWithdrawCancelledTopics(evt abi.Event, values []WithdrawCancelledTopics) ([]*evm.TopicValues, error)
	DecodeWithdrawCancelled(log *evm.Log) (*WithdrawCancelledDecoded, error)
	WithdrawClaimedLogHash() []byte
	EncodeWithdrawClaimedTopics(evt abi.Event, values []WithdrawClaimedTopics) ([]*evm.TopicValues, error)
	DecodeWithdrawClaimed(log *evm.Log) (*WithdrawClaimedDecoded, error)
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

func (c *Codec) EncodeUPGRADEINTERFACEVERSIONMethodCall() ([]byte, error) {
	return c.abi.Pack("UPGRADE_INTERFACE_VERSION")
}

func (c *Codec) DecodeUPGRADEINTERFACEVERSIONMethodOutput(data []byte) (string, error) {
	vals, err := c.abi.Methods["UPGRADE_INTERFACE_VERSION"].Outputs.Unpack(data)
	if err != nil {
		return *new(string), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(string), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result string
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(string), fmt.Errorf("failed to unmarshal to string: %w", err)
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

func (c *Codec) EncodeClaimAssetMethodCall(in ClaimAssetInput) ([]byte, error) {
	return c.abi.Pack("claimAsset", in.EpochNonce)
}

func (c *Codec) DecodeClaimAssetMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["claimAsset"].Outputs.Unpack(data)
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

func (c *Codec) EncodeCloseEpochMethodCall(in CloseEpochInput) ([]byte, error) {
	return c.abi.Pack("closeEpoch", in.Tvl)
}

func (c *Codec) EncodeCompleteEpochDepositMethodCall() ([]byte, error) {
	return c.abi.Pack("completeEpochDeposit")
}

func (c *Codec) EncodeCompleteRebalanceMethodCall() ([]byte, error) {
	return c.abi.Pack("completeRebalance")
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

func (c *Codec) EncodeExecuteRecoveryMethodCall() ([]byte, error) {
	return c.abi.Pack("executeRecovery")
}

func (c *Codec) EncodeForceCancelDepositMethodCall(in ForceCancelDepositInput) ([]byte, error) {
	return c.abi.Pack("forceCancelDeposit", in.User)
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

func (c *Codec) EncodeGetAssetMethodCall() ([]byte, error) {
	return c.abi.Pack("getAsset")
}

func (c *Codec) DecodeGetAssetMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["getAsset"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetAssetPrecisionMethodCall() ([]byte, error) {
	return c.abi.Pack("getAssetPrecision")
}

func (c *Codec) DecodeGetAssetPrecisionMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getAssetPrecision"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetMinDepositAmountMethodCall() ([]byte, error) {
	return c.abi.Pack("getMinDepositAmount")
}

func (c *Codec) DecodeGetMinDepositAmountMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getMinDepositAmount"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetRebalanceDepositRecoveryMethodCall() ([]byte, error) {
	return c.abi.Pack("getRebalanceDepositRecovery")
}

func (c *Codec) DecodeGetRebalanceDepositRecoveryMethodOutput(data []byte) (TypesRebalanceDepositRecovery, error) {
	vals, err := c.abi.Methods["getRebalanceDepositRecovery"].Outputs.Unpack(data)
	if err != nil {
		return *new(TypesRebalanceDepositRecovery), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(TypesRebalanceDepositRecovery), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result TypesRebalanceDepositRecovery
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(TypesRebalanceDepositRecovery), fmt.Errorf("failed to unmarshal to TypesRebalanceDepositRecovery: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetRecoveryModeMethodCall() ([]byte, error) {
	return c.abi.Pack("getRecoveryMode")
}

func (c *Codec) DecodeGetRecoveryModeMethodOutput(data []byte) (uint8, error) {
	vals, err := c.abi.Methods["getRecoveryMode"].Outputs.Unpack(data)
	if err != nil {
		return *new(uint8), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(uint8), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result uint8
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(uint8), fmt.Errorf("failed to unmarshal to uint8: %w", err)
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

func (c *Codec) EncodeGetSharePrecisionMethodCall() ([]byte, error) {
	return c.abi.Pack("getSharePrecision")
}

func (c *Codec) DecodeGetSharePrecisionMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["getSharePrecision"].Outputs.Unpack(data)
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

func (c *Codec) EncodeGetSupportedProtocolMethodCall(in GetSupportedProtocolInput) ([]byte, error) {
	return c.abi.Pack("getSupportedProtocol", in.ProtocolId)
}

func (c *Codec) DecodeGetSupportedProtocolMethodOutput(data []byte) (bool, error) {
	vals, err := c.abi.Methods["getSupportedProtocol"].Outputs.Unpack(data)
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

func (c *Codec) EncodeInitializeMethodCall(in InitializeInput) ([]byte, error) {
	return c.abi.Pack("initialize", in.Params, in.Treasury, in.CancelDepositOperator)
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

func (c *Codec) EncodeProxiableUUIDMethodCall() ([]byte, error) {
	return c.abi.Pack("proxiableUUID")
}

func (c *Codec) DecodeProxiableUUIDMethodOutput(data []byte) ([32]byte, error) {
	vals, err := c.abi.Methods["proxiableUUID"].Outputs.Unpack(data)
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

func (c *Codec) EncodeSetInitialActiveProtocolAdapterMethodCall(in SetInitialActiveProtocolAdapterInput) ([]byte, error) {
	return c.abi.Pack("setInitialActiveProtocolAdapter", in.ProtocolId)
}

func (c *Codec) EncodeSetSupportedProtocolMethodCall(in SetSupportedProtocolInput) ([]byte, error) {
	return c.abi.Pack("setSupportedProtocol", in.ProtocolId, in.IsSupported)
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

func (c *Codec) EncodeTryDepositToAdapterMethodCall(in TryDepositToAdapterInput) ([]byte, error) {
	return c.abi.Pack("tryDepositToAdapter", in.Adapter, in.Amount)
}

func (c *Codec) EncodeUnpauseMethodCall() ([]byte, error) {
	return c.abi.Pack("unpause")
}

func (c *Codec) EncodeUpgradeToAndCallMethodCall(in UpgradeToAndCallInput) ([]byte, error) {
	return c.abi.Pack("upgradeToAndCall", in.NewImplementation, in.Data)
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
			{Name: "asset", Type: "address"},
			{Name: "ccipRouter", Type: "address"},
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
func (c *Codec) EncodeBaseVaultInitParamsStruct(in BaseVaultInitParams) ([]byte, error) {
	tupleType, err := abi.NewType(
		"tuple", "",
		[]abi.ArgumentMarshaling{
			{Name: "defaultAdmin", Type: "address"},
			{Name: "pauser", Type: "address"},
			{Name: "unpauser", Type: "address"},
			{Name: "configOperator", Type: "address"},
			{Name: "initialDefaultCcipGasLimit", Type: "uint256"},
			{Name: "upgrader", Type: "address"},
		},
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create tuple type for BaseVaultInitParams: %w", err)
	}
	args := abi.Arguments{
		{Name: "baseVaultInitParams", Type: tupleType},
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
func (c *Codec) EncodeTypesEpochStruct(in TypesEpoch) ([]byte, error) {
	tupleType, err := abi.NewType(
		"tuple", "",
		[]abi.ArgumentMarshaling{
			{Name: "totalDepositAmount", Type: "uint256"},
			{Name: "totalShareBurnAmount", Type: "uint256"},
			{Name: "totalWithdrawClaimAmount", Type: "uint256"},
			{Name: "pricePerShare", Type: "uint256"},
			{Name: "remainingDepositClaimAmount", Type: "uint256"},
			{Name: "remainingShareMintAmount", Type: "uint256"},
			{Name: "remainingShareBurnAmount", Type: "uint256"},
			{Name: "remainingWithdrawClaimAmount", Type: "uint256"},
			{Name: "openedAtTimestamp", Type: "uint256"},
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
func (c *Codec) EncodeTypesRebalanceDepositRecoveryStruct(in TypesRebalanceDepositRecovery) ([]byte, error) {
	tupleType, err := abi.NewType(
		"tuple", "",
		[]abi.ArgumentMarshaling{
			{Name: "rebalanceNonce", Type: "uint256"},
			{Name: "amount", Type: "uint256"},
		},
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create tuple type for TypesRebalanceDepositRecovery: %w", err)
	}
	args := abi.Arguments{
		{Name: "typesRebalanceDepositRecovery", Type: tupleType},
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

func (c *Codec) ActiveProtocolAdapterClearedLogHash() []byte {
	return c.abi.Events["ActiveProtocolAdapterCleared"].ID.Bytes()
}

func (c *Codec) EncodeActiveProtocolAdapterClearedTopics(
	evt abi.Event,
	values []ActiveProtocolAdapterClearedTopics,
) ([]*evm.TopicValues, error) {
	var adapterRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Adapter).IsZero() {
			adapterRule = append(adapterRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.Adapter)
		if err != nil {
			return nil, err
		}
		adapterRule = append(adapterRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		adapterRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeActiveProtocolAdapterCleared decodes a log into a ActiveProtocolAdapterCleared struct.
func (c *Codec) DecodeActiveProtocolAdapterCleared(log *evm.Log) (*ActiveProtocolAdapterClearedDecoded, error) {
	event := new(ActiveProtocolAdapterClearedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "ActiveProtocolAdapterCleared", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["ActiveProtocolAdapterCleared"].Inputs {
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

func (c *Codec) ActiveProtocolAdapterSetLogHash() []byte {
	return c.abi.Events["ActiveProtocolAdapterSet"].ID.Bytes()
}

func (c *Codec) EncodeActiveProtocolAdapterSetTopics(
	evt abi.Event,
	values []ActiveProtocolAdapterSetTopics,
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

// DecodeActiveProtocolAdapterSet decodes a log into a ActiveProtocolAdapterSet struct.
func (c *Codec) DecodeActiveProtocolAdapterSet(log *evm.Log) (*ActiveProtocolAdapterSetDecoded, error) {
	event := new(ActiveProtocolAdapterSetDecoded)
	if err := c.abi.UnpackIntoInterface(event, "ActiveProtocolAdapterSet", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["ActiveProtocolAdapterSet"].Inputs {
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
	var destinationChainSelectorRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.DestinationChainSelector).IsZero() {
			destinationChainSelectorRule = append(destinationChainSelectorRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.DestinationChainSelector)
		if err != nil {
			return nil, err
		}
		destinationChainSelectorRule = append(destinationChainSelectorRule, fieldVal)
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
		destinationChainSelectorRule,
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

func (c *Codec) CCIPReceivedLogHash() []byte {
	return c.abi.Events["CCIPReceived"].ID.Bytes()
}

func (c *Codec) EncodeCCIPReceivedTopics(
	evt abi.Event,
	values []CCIPReceivedTopics,
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
	var sourceChainSelectorRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.SourceChainSelector).IsZero() {
			sourceChainSelectorRule = append(sourceChainSelectorRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.SourceChainSelector)
		if err != nil {
			return nil, err
		}
		sourceChainSelectorRule = append(sourceChainSelectorRule, fieldVal)
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
		sourceChainSelectorRule,
		ccipTxTypeRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeCCIPReceived decodes a log into a CCIPReceived struct.
func (c *Codec) DecodeCCIPReceived(log *evm.Log) (*CCIPReceivedDecoded, error) {
	event := new(CCIPReceivedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "CCIPReceived", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["CCIPReceived"].Inputs {
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

func (c *Codec) DepositForceCancelledLogHash() []byte {
	return c.abi.Events["DepositForceCancelled"].ID.Bytes()
}

func (c *Codec) EncodeDepositForceCancelledTopics(
	evt abi.Event,
	values []DepositForceCancelledTopics,
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

// DecodeDepositForceCancelled decodes a log into a DepositForceCancelled struct.
func (c *Codec) DecodeDepositForceCancelled(log *evm.Log) (*DepositForceCancelledDecoded, error) {
	event := new(DepositForceCancelledDecoded)
	if err := c.abi.UnpackIntoInterface(event, "DepositForceCancelled", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["DepositForceCancelled"].Inputs {
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

func (c *Codec) EpochClaimable0LogHash() []byte {
	return c.abi.Events["EpochClaimable0"].ID.Bytes()
}

func (c *Codec) EncodeEpochClaimable0Topics(
	evt abi.Event,
	values []EpochClaimable0Topics,
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

// DecodeEpochClaimable0 decodes a log into a EpochClaimable0 struct.
func (c *Codec) DecodeEpochClaimable0(log *evm.Log) (*EpochClaimable0Decoded, error) {
	event := new(EpochClaimable0Decoded)
	if err := c.abi.UnpackIntoInterface(event, "EpochClaimable0", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["EpochClaimable0"].Inputs {
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

func (c *Codec) EpochDepositExecutingLogHash() []byte {
	return c.abi.Events["EpochDepositExecuting"].ID.Bytes()
}

func (c *Codec) EncodeEpochDepositExecutingTopics(
	evt abi.Event,
	values []EpochDepositExecutingTopics,
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

// DecodeEpochDepositExecuting decodes a log into a EpochDepositExecuting struct.
func (c *Codec) DecodeEpochDepositExecuting(log *evm.Log) (*EpochDepositExecutingDecoded, error) {
	event := new(EpochDepositExecutingDecoded)
	if err := c.abi.UnpackIntoInterface(event, "EpochDepositExecuting", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["EpochDepositExecuting"].Inputs {
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

func (c *Codec) EpochDepositToStrategySuccessLogHash() []byte {
	return c.abi.Events["EpochDepositToStrategySuccess"].ID.Bytes()
}

func (c *Codec) EncodeEpochDepositToStrategySuccessTopics(
	evt abi.Event,
	values []EpochDepositToStrategySuccessTopics,
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

// DecodeEpochDepositToStrategySuccess decodes a log into a EpochDepositToStrategySuccess struct.
func (c *Codec) DecodeEpochDepositToStrategySuccess(log *evm.Log) (*EpochDepositToStrategySuccessDecoded, error) {
	event := new(EpochDepositToStrategySuccessDecoded)
	if err := c.abi.UnpackIntoInterface(event, "EpochDepositToStrategySuccess", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["EpochDepositToStrategySuccess"].Inputs {
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
	var expectedAmountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ExpectedAmount).IsZero() {
			expectedAmountRule = append(expectedAmountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.ExpectedAmount)
		if err != nil {
			return nil, err
		}
		expectedAmountRule = append(expectedAmountRule, fieldVal)
	}
	var actualAmountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ActualAmount).IsZero() {
			actualAmountRule = append(actualAmountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.ActualAmount)
		if err != nil {
			return nil, err
		}
		actualAmountRule = append(actualAmountRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		epochNonceRule,
		expectedAmountRule,
		actualAmountRule,
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

func (c *Codec) EpochWithdrawAmountShort0LogHash() []byte {
	return c.abi.Events["EpochWithdrawAmountShort0"].ID.Bytes()
}

func (c *Codec) EncodeEpochWithdrawAmountShort0Topics(
	evt abi.Event,
	values []EpochWithdrawAmountShort0Topics,
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
	var expectedAmountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ExpectedAmount).IsZero() {
			expectedAmountRule = append(expectedAmountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.ExpectedAmount)
		if err != nil {
			return nil, err
		}
		expectedAmountRule = append(expectedAmountRule, fieldVal)
	}
	var actualAmountRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.ActualAmount).IsZero() {
			actualAmountRule = append(actualAmountRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.ActualAmount)
		if err != nil {
			return nil, err
		}
		actualAmountRule = append(actualAmountRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		epochNonceRule,
		expectedAmountRule,
		actualAmountRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeEpochWithdrawAmountShort0 decodes a log into a EpochWithdrawAmountShort0 struct.
func (c *Codec) DecodeEpochWithdrawAmountShort0(log *evm.Log) (*EpochWithdrawAmountShort0Decoded, error) {
	event := new(EpochWithdrawAmountShort0Decoded)
	if err := c.abi.UnpackIntoInterface(event, "EpochWithdrawAmountShort0", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["EpochWithdrawAmountShort0"].Inputs {
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

func (c *Codec) EpochWithdrawExecutingLogHash() []byte {
	return c.abi.Events["EpochWithdrawExecuting"].ID.Bytes()
}

func (c *Codec) EncodeEpochWithdrawExecutingTopics(
	evt abi.Event,
	values []EpochWithdrawExecutingTopics,
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

// DecodeEpochWithdrawExecuting decodes a log into a EpochWithdrawExecuting struct.
func (c *Codec) DecodeEpochWithdrawExecuting(log *evm.Log) (*EpochWithdrawExecutingDecoded, error) {
	event := new(EpochWithdrawExecutingDecoded)
	if err := c.abi.UnpackIntoInterface(event, "EpochWithdrawExecuting", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["EpochWithdrawExecuting"].Inputs {
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

func (c *Codec) EpochWithdrawFromStrategySuccessLogHash() []byte {
	return c.abi.Events["EpochWithdrawFromStrategySuccess"].ID.Bytes()
}

func (c *Codec) EncodeEpochWithdrawFromStrategySuccessTopics(
	evt abi.Event,
	values []EpochWithdrawFromStrategySuccessTopics,
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

// DecodeEpochWithdrawFromStrategySuccess decodes a log into a EpochWithdrawFromStrategySuccess struct.
func (c *Codec) DecodeEpochWithdrawFromStrategySuccess(log *evm.Log) (*EpochWithdrawFromStrategySuccessDecoded, error) {
	event := new(EpochWithdrawFromStrategySuccessDecoded)
	if err := c.abi.UnpackIntoInterface(event, "EpochWithdrawFromStrategySuccess", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["EpochWithdrawFromStrategySuccess"].Inputs {
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

func (c *Codec) InitializedLogHash() []byte {
	return c.abi.Events["Initialized"].ID.Bytes()
}

func (c *Codec) EncodeInitializedTopics(
	evt abi.Event,
	values []InitializedTopics,
) ([]*evm.TopicValues, error) {

	rawTopics, err := abi.MakeTopics()
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeInitialized decodes a log into a Initialized struct.
func (c *Codec) DecodeInitialized(log *evm.Log) (*InitializedDecoded, error) {
	event := new(InitializedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "Initialized", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["Initialized"].Inputs {
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
	var feeSharesRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.FeeShares).IsZero() {
			feeSharesRule = append(feeSharesRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.FeeShares)
		if err != nil {
			return nil, err
		}
		feeSharesRule = append(feeSharesRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		rebalanceNonceRule,
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

func (c *Codec) ManagementFeeCollected0LogHash() []byte {
	return c.abi.Events["ManagementFeeCollected0"].ID.Bytes()
}

func (c *Codec) EncodeManagementFeeCollected0Topics(
	evt abi.Event,
	values []ManagementFeeCollected0Topics,
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
	var feeSharesRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.FeeShares).IsZero() {
			feeSharesRule = append(feeSharesRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.FeeShares)
		if err != nil {
			return nil, err
		}
		feeSharesRule = append(feeSharesRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		rebalanceNonceRule,
		feeSharesRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeManagementFeeCollected0 decodes a log into a ManagementFeeCollected0 struct.
func (c *Codec) DecodeManagementFeeCollected0(log *evm.Log) (*ManagementFeeCollected0Decoded, error) {
	event := new(ManagementFeeCollected0Decoded)
	if err := c.abi.UnpackIntoInterface(event, "ManagementFeeCollected0", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["ManagementFeeCollected0"].Inputs {
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
	var newProtocolIdRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.NewProtocolId).IsZero() {
			newProtocolIdRule = append(newProtocolIdRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.NewProtocolId)
		if err != nil {
			return nil, err
		}
		newProtocolIdRule = append(newProtocolIdRule, fieldVal)
	}
	var newChainSelectorRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.NewChainSelector).IsZero() {
			newChainSelectorRule = append(newChainSelectorRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.NewChainSelector)
		if err != nil {
			return nil, err
		}
		newChainSelectorRule = append(newChainSelectorRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		rebalanceNonceRule,
		newProtocolIdRule,
		newChainSelectorRule,
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

func (c *Codec) RebalanceCompleted0LogHash() []byte {
	return c.abi.Events["RebalanceCompleted0"].ID.Bytes()
}

func (c *Codec) EncodeRebalanceCompleted0Topics(
	evt abi.Event,
	values []RebalanceCompleted0Topics,
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
	var newProtocolIdRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.NewProtocolId).IsZero() {
			newProtocolIdRule = append(newProtocolIdRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.NewProtocolId)
		if err != nil {
			return nil, err
		}
		newProtocolIdRule = append(newProtocolIdRule, fieldVal)
	}
	var newChainSelectorRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.NewChainSelector).IsZero() {
			newChainSelectorRule = append(newChainSelectorRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[2], v.NewChainSelector)
		if err != nil {
			return nil, err
		}
		newChainSelectorRule = append(newChainSelectorRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		rebalanceNonceRule,
		newProtocolIdRule,
		newChainSelectorRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeRebalanceCompleted0 decodes a log into a RebalanceCompleted0 struct.
func (c *Codec) DecodeRebalanceCompleted0(log *evm.Log) (*RebalanceCompleted0Decoded, error) {
	event := new(RebalanceCompleted0Decoded)
	if err := c.abi.UnpackIntoInterface(event, "RebalanceCompleted0", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["RebalanceCompleted0"].Inputs {
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

func (c *Codec) SupportedProtocolSetLogHash() []byte {
	return c.abi.Events["SupportedProtocolSet"].ID.Bytes()
}

func (c *Codec) EncodeSupportedProtocolSetTopics(
	evt abi.Event,
	values []SupportedProtocolSetTopics,
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
	var isSupportedRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.IsSupported).IsZero() {
			isSupportedRule = append(isSupportedRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.IsSupported)
		if err != nil {
			return nil, err
		}
		isSupportedRule = append(isSupportedRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		protocolIdRule,
		isSupportedRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeSupportedProtocolSet decodes a log into a SupportedProtocolSet struct.
func (c *Codec) DecodeSupportedProtocolSet(log *evm.Log) (*SupportedProtocolSetDecoded, error) {
	event := new(SupportedProtocolSetDecoded)
	if err := c.abi.UnpackIntoInterface(event, "SupportedProtocolSet", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["SupportedProtocolSet"].Inputs {
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

func (c *Codec) UpgradedLogHash() []byte {
	return c.abi.Events["Upgraded"].ID.Bytes()
}

func (c *Codec) EncodeUpgradedTopics(
	evt abi.Event,
	values []UpgradedTopics,
) ([]*evm.TopicValues, error) {
	var implementationRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.Implementation).IsZero() {
			implementationRule = append(implementationRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.Implementation)
		if err != nil {
			return nil, err
		}
		implementationRule = append(implementationRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		implementationRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeUpgraded decodes a log into a Upgraded struct.
func (c *Codec) DecodeUpgraded(log *evm.Log) (*UpgradedDecoded, error) {
	event := new(UpgradedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "Upgraded", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["Upgraded"].Inputs {
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

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) ([32]byte, error) {
		return c.Codec.DecodeDEFAULTADMINROLEMethodOutput(response.Data)
	})

}

func (c ParentVault) UPGRADEINTERFACEVERSION(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[string] {
	calldata, err := c.Codec.EncodeUPGRADEINTERFACEVERSIONMethodCall()
	if err != nil {
		return cre.PromiseFromResult[string](*new(string), err)
	}

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (string, error) {
		return c.Codec.DecodeUPGRADEINTERFACEVERSIONMethodOutput(response.Data)
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

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
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

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
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

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
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

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
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

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (common.Address, error) {
		return c.Codec.DecodeGetAdapterRegistryMethodOutput(response.Data)
	})

}

func (c ParentVault) GetAsset(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeGetAssetMethodCall()
	if err != nil {
		return cre.PromiseFromResult[common.Address](*new(common.Address), err)
	}

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (common.Address, error) {
		return c.Codec.DecodeGetAssetMethodOutput(response.Data)
	})

}

func (c ParentVault) GetAssetPrecision(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeGetAssetPrecisionMethodCall()
	if err != nil {
		return cre.PromiseFromResult[*big.Int](*new(*big.Int), err)
	}

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (*big.Int, error) {
		return c.Codec.DecodeGetAssetPrecisionMethodOutput(response.Data)
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

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
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

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (*big.Int, error) {
		return c.Codec.DecodeGetCcipGasLimitMethodOutput(response.Data)
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

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
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

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
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

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
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

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
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

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
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

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
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

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (common.Address, error) {
		return c.Codec.DecodeGetLinkMethodOutput(response.Data)
	})

}

func (c ParentVault) GetMinDepositAmount(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeGetMinDepositAmountMethodCall()
	if err != nil {
		return cre.PromiseFromResult[*big.Int](*new(*big.Int), err)
	}

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (*big.Int, error) {
		return c.Codec.DecodeGetMinDepositAmountMethodOutput(response.Data)
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

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
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
	blockNumber *big.Int,
) cre.Promise[TypesRebalanceDepositRecovery] {
	calldata, err := c.Codec.EncodeGetRebalanceDepositRecoveryMethodCall()
	if err != nil {
		return cre.PromiseFromResult[TypesRebalanceDepositRecovery](*new(TypesRebalanceDepositRecovery), err)
	}

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (TypesRebalanceDepositRecovery, error) {
		return c.Codec.DecodeGetRebalanceDepositRecoveryMethodOutput(response.Data)
	})

}

func (c ParentVault) GetRecoveryMode(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[uint8] {
	calldata, err := c.Codec.EncodeGetRecoveryModeMethodCall()
	if err != nil {
		return cre.PromiseFromResult[uint8](*new(uint8), err)
	}

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (uint8, error) {
		return c.Codec.DecodeGetRecoveryModeMethodOutput(response.Data)
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

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
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

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
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

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (common.Address, error) {
		return c.Codec.DecodeGetShareMethodOutput(response.Data)
	})

}

func (c ParentVault) GetSupportedProtocol(
	runtime cre.Runtime,
	args GetSupportedProtocolInput,
	blockNumber *big.Int,
) cre.Promise[bool] {
	calldata, err := c.Codec.EncodeGetSupportedProtocolMethodCall(args)
	if err != nil {
		return cre.PromiseFromResult[bool](*new(bool), err)
	}

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (bool, error) {
		return c.Codec.DecodeGetSupportedProtocolMethodOutput(response.Data)
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

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
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

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
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

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
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

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (common.Address, error) {
		return c.Codec.DecodeGetTreasuryMethodOutput(response.Data)
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

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
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

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
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

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
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

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
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

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
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

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (PendingDefaultAdminDelayOutput, error) {
		return c.Codec.DecodePendingDefaultAdminDelayMethodOutput(response.Data)
	})

}

func (c ParentVault) ProxiableUUID(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[[32]byte] {
	calldata, err := c.Codec.EncodeProxiableUUIDMethodCall()
	if err != nil {
		return cre.PromiseFromResult[[32]byte](*new([32]byte), err)
	}

	bn := bindings.FinalizedBlockNumber
	if blockNumber != nil {
		bn = pb.NewBigIntFromInt(blockNumber)
	}

	promise := cre.ThenPromise(cre.PromiseFromResult(bn, nil), func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) ([32]byte, error) {
		return c.Codec.DecodeProxiableUUIDMethodOutput(response.Data)
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

func (c ParentVault) WriteReportFromBaseVaultInitParams(
	runtime cre.Runtime,
	input BaseVaultInitParams,
	gasConfig *evm.GasConfig,
) cre.Promise[*evm.WriteReportReply] {
	encoded, err := c.Codec.EncodeBaseVaultInitParamsStruct(input)
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

func (c ParentVault) WriteReportFromTypesRebalanceDepositRecovery(
	runtime cre.Runtime,
	input TypesRebalanceDepositRecovery,
	gasConfig *evm.GasConfig,
) cre.Promise[*evm.WriteReportReply] {
	encoded, err := c.Codec.EncodeTypesRebalanceDepositRecoveryStruct(input)
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

// DecodeAddressEmptyCodeError decodes a AddressEmptyCode error from revert data.
func (c *ParentVault) DecodeAddressEmptyCodeError(data []byte) (*AddressEmptyCode, error) {
	args := c.ABI.Errors["AddressEmptyCode"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	target, ok0 := values[0].(common.Address)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for target in AddressEmptyCode error")
	}

	return &AddressEmptyCode{
		Target: target,
	}, nil
}

// Error implements the error interface for AddressEmptyCode.
func (e *AddressEmptyCode) Error() string {
	return fmt.Sprintf("AddressEmptyCode error: target=%v;", e.Target)
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

// DecodeBaseVaultDestinationVaultNotSetError decodes a BaseVault__DestinationVaultNotSet error from revert data.
func (c *ParentVault) DecodeBaseVaultDestinationVaultNotSetError(data []byte) (*BaseVaultDestinationVaultNotSet, error) {
	args := c.ABI.Errors["BaseVault__DestinationVaultNotSet"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	destinationChainSelector, ok0 := values[0].(uint64)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for destinationChainSelector in BaseVaultDestinationVaultNotSet error")
	}

	return &BaseVaultDestinationVaultNotSet{
		DestinationChainSelector: destinationChainSelector,
	}, nil
}

// Error implements the error interface for BaseVaultDestinationVaultNotSet.
func (e *BaseVaultDestinationVaultNotSet) Error() string {
	return fmt.Sprintf("BaseVaultDestinationVaultNotSet error: destinationChainSelector=%v;", e.DestinationChainSelector)
}

// DecodeBaseVaultEmptyInputError decodes a BaseVault__EmptyInput error from revert data.
func (c *ParentVault) DecodeBaseVaultEmptyInputError(data []byte) (*BaseVaultEmptyInput, error) {
	args := c.ABI.Errors["BaseVault__EmptyInput"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &BaseVaultEmptyInput{}, nil
}

// Error implements the error interface for BaseVaultEmptyInput.
func (e *BaseVaultEmptyInput) Error() string {
	return fmt.Sprintf("BaseVaultEmptyInput error:")
}

// DecodeBaseVaultInvalidAdapterVaultError decodes a BaseVault__InvalidAdapterVault error from revert data.
func (c *ParentVault) DecodeBaseVaultInvalidAdapterVaultError(data []byte) (*BaseVaultInvalidAdapterVault, error) {
	args := c.ABI.Errors["BaseVault__InvalidAdapterVault"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 3 {
		return nil, fmt.Errorf("expected 3 values, got %d", len(values))
	}

	adapter, ok0 := values[0].(common.Address)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for adapter in BaseVaultInvalidAdapterVault error")
	}

	actualVault, ok1 := values[1].(common.Address)
	if !ok1 {
		return nil, fmt.Errorf("unexpected type for actualVault in BaseVaultInvalidAdapterVault error")
	}

	expectedVault, ok2 := values[2].(common.Address)
	if !ok2 {
		return nil, fmt.Errorf("unexpected type for expectedVault in BaseVaultInvalidAdapterVault error")
	}

	return &BaseVaultInvalidAdapterVault{
		Adapter:       adapter,
		ActualVault:   actualVault,
		ExpectedVault: expectedVault,
	}, nil
}

// Error implements the error interface for BaseVaultInvalidAdapterVault.
func (e *BaseVaultInvalidAdapterVault) Error() string {
	return fmt.Sprintf("BaseVaultInvalidAdapterVault error: adapter=%v; actualVault=%v; expectedVault=%v;", e.Adapter, e.ActualVault, e.ExpectedVault)
}

// DecodeBaseVaultInvalidDestinationChainSelectorError decodes a BaseVault__InvalidDestinationChainSelector error from revert data.
func (c *ParentVault) DecodeBaseVaultInvalidDestinationChainSelectorError(data []byte) (*BaseVaultInvalidDestinationChainSelector, error) {
	args := c.ABI.Errors["BaseVault__InvalidDestinationChainSelector"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	destinationChainSelector, ok0 := values[0].(uint64)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for destinationChainSelector in BaseVaultInvalidDestinationChainSelector error")
	}

	return &BaseVaultInvalidDestinationChainSelector{
		DestinationChainSelector: destinationChainSelector,
	}, nil
}

// Error implements the error interface for BaseVaultInvalidDestinationChainSelector.
func (e *BaseVaultInvalidDestinationChainSelector) Error() string {
	return fmt.Sprintf("BaseVaultInvalidDestinationChainSelector error: destinationChainSelector=%v;", e.DestinationChainSelector)
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

// DecodeBaseVaultInvalidReceivedTokenError decodes a BaseVault__InvalidReceivedToken error from revert data.
func (c *ParentVault) DecodeBaseVaultInvalidReceivedTokenError(data []byte) (*BaseVaultInvalidReceivedToken, error) {
	args := c.ABI.Errors["BaseVault__InvalidReceivedToken"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 2 {
		return nil, fmt.Errorf("expected 2 values, got %d", len(values))
	}

	receivedToken, ok0 := values[0].(common.Address)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for receivedToken in BaseVaultInvalidReceivedToken error")
	}

	expectedToken, ok1 := values[1].(common.Address)
	if !ok1 {
		return nil, fmt.Errorf("unexpected type for expectedToken in BaseVaultInvalidReceivedToken error")
	}

	return &BaseVaultInvalidReceivedToken{
		ReceivedToken: receivedToken,
		ExpectedToken: expectedToken,
	}, nil
}

// Error implements the error interface for BaseVaultInvalidReceivedToken.
func (e *BaseVaultInvalidReceivedToken) Error() string {
	return fmt.Sprintf("BaseVaultInvalidReceivedToken error: receivedToken=%v; expectedToken=%v;", e.ReceivedToken, e.ExpectedToken)
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

// DecodeBaseVaultInvalidSourceChainSelectorError decodes a BaseVault__InvalidSourceChainSelector error from revert data.
func (c *ParentVault) DecodeBaseVaultInvalidSourceChainSelectorError(data []byte) (*BaseVaultInvalidSourceChainSelector, error) {
	args := c.ABI.Errors["BaseVault__InvalidSourceChainSelector"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 2 {
		return nil, fmt.Errorf("expected 2 values, got %d", len(values))
	}

	sourceChainSelector, ok0 := values[0].(uint64)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for sourceChainSelector in BaseVaultInvalidSourceChainSelector error")
	}

	expectedSourceChainSelector, ok1 := values[1].(uint64)
	if !ok1 {
		return nil, fmt.Errorf("unexpected type for expectedSourceChainSelector in BaseVaultInvalidSourceChainSelector error")
	}

	return &BaseVaultInvalidSourceChainSelector{
		SourceChainSelector:         sourceChainSelector,
		ExpectedSourceChainSelector: expectedSourceChainSelector,
	}, nil
}

// Error implements the error interface for BaseVaultInvalidSourceChainSelector.
func (e *BaseVaultInvalidSourceChainSelector) Error() string {
	return fmt.Sprintf("BaseVaultInvalidSourceChainSelector error: sourceChainSelector=%v; expectedSourceChainSelector=%v;", e.SourceChainSelector, e.ExpectedSourceChainSelector)
}

// DecodeBaseVaultInvalidTokenAmountsLengthError decodes a BaseVault__InvalidTokenAmountsLength error from revert data.
func (c *ParentVault) DecodeBaseVaultInvalidTokenAmountsLengthError(data []byte) (*BaseVaultInvalidTokenAmountsLength, error) {
	args := c.ABI.Errors["BaseVault__InvalidTokenAmountsLength"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 2 {
		return nil, fmt.Errorf("expected 2 values, got %d", len(values))
	}

	receivedLength, ok0 := values[0].(*big.Int)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for receivedLength in BaseVaultInvalidTokenAmountsLength error")
	}

	expectedLength, ok1 := values[1].(*big.Int)
	if !ok1 {
		return nil, fmt.Errorf("unexpected type for expectedLength in BaseVaultInvalidTokenAmountsLength error")
	}

	return &BaseVaultInvalidTokenAmountsLength{
		ReceivedLength: receivedLength,
		ExpectedLength: expectedLength,
	}, nil
}

// Error implements the error interface for BaseVaultInvalidTokenAmountsLength.
func (e *BaseVaultInvalidTokenAmountsLength) Error() string {
	return fmt.Sprintf("BaseVaultInvalidTokenAmountsLength error: receivedLength=%v; expectedLength=%v;", e.ReceivedLength, e.ExpectedLength)
}

// DecodeBaseVaultInvalidTxTypeError decodes a BaseVault__InvalidTxType error from revert data.
func (c *ParentVault) DecodeBaseVaultInvalidTxTypeError(data []byte) (*BaseVaultInvalidTxType, error) {
	args := c.ABI.Errors["BaseVault__InvalidTxType"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	ccipTxType, ok0 := values[0].(uint8)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for ccipTxType in BaseVaultInvalidTxType error")
	}

	return &BaseVaultInvalidTxType{
		CcipTxType: ccipTxType,
	}, nil
}

// Error implements the error interface for BaseVaultInvalidTxType.
func (e *BaseVaultInvalidTxType) Error() string {
	return fmt.Sprintf("BaseVaultInvalidTxType error: ccipTxType=%v;", e.CcipTxType)
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

// DecodeBaseVaultNoZeroAddressError decodes a BaseVault__NoZeroAddress error from revert data.
func (c *ParentVault) DecodeBaseVaultNoZeroAddressError(data []byte) (*BaseVaultNoZeroAddress, error) {
	args := c.ABI.Errors["BaseVault__NoZeroAddress"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &BaseVaultNoZeroAddress{}, nil
}

// Error implements the error interface for BaseVaultNoZeroAddress.
func (e *BaseVaultNoZeroAddress) Error() string {
	return fmt.Sprintf("BaseVaultNoZeroAddress error:")
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

// DecodeBaseVaultNoZeroChainSelectorError decodes a BaseVault__NoZeroChainSelector error from revert data.
func (c *ParentVault) DecodeBaseVaultNoZeroChainSelectorError(data []byte) (*BaseVaultNoZeroChainSelector, error) {
	args := c.ABI.Errors["BaseVault__NoZeroChainSelector"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &BaseVaultNoZeroChainSelector{}, nil
}

// Error implements the error interface for BaseVaultNoZeroChainSelector.
func (e *BaseVaultNoZeroChainSelector) Error() string {
	return fmt.Sprintf("BaseVaultNoZeroChainSelector error:")
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

// DecodeERC1967InvalidImplementationError decodes a ERC1967InvalidImplementation error from revert data.
func (c *ParentVault) DecodeERC1967InvalidImplementationError(data []byte) (*ERC1967InvalidImplementation, error) {
	args := c.ABI.Errors["ERC1967InvalidImplementation"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	implementation, ok0 := values[0].(common.Address)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for implementation in ERC1967InvalidImplementation error")
	}

	return &ERC1967InvalidImplementation{
		Implementation: implementation,
	}, nil
}

// Error implements the error interface for ERC1967InvalidImplementation.
func (e *ERC1967InvalidImplementation) Error() string {
	return fmt.Sprintf("ERC1967InvalidImplementation error: implementation=%v;", e.Implementation)
}

// DecodeERC1967NonPayableError decodes a ERC1967NonPayable error from revert data.
func (c *ParentVault) DecodeERC1967NonPayableError(data []byte) (*ERC1967NonPayable, error) {
	args := c.ABI.Errors["ERC1967NonPayable"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &ERC1967NonPayable{}, nil
}

// Error implements the error interface for ERC1967NonPayable.
func (e *ERC1967NonPayable) Error() string {
	return fmt.Sprintf("ERC1967NonPayable error:")
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

// DecodeFailedCallError decodes a FailedCall error from revert data.
func (c *ParentVault) DecodeFailedCallError(data []byte) (*FailedCall, error) {
	args := c.ABI.Errors["FailedCall"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &FailedCall{}, nil
}

// Error implements the error interface for FailedCall.
func (e *FailedCall) Error() string {
	return fmt.Sprintf("FailedCall error:")
}

// DecodeInvalidInitializationError decodes a InvalidInitialization error from revert data.
func (c *ParentVault) DecodeInvalidInitializationError(data []byte) (*InvalidInitialization, error) {
	args := c.ABI.Errors["InvalidInitialization"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &InvalidInitialization{}, nil
}

// Error implements the error interface for InvalidInitialization.
func (e *InvalidInitialization) Error() string {
	return fmt.Sprintf("InvalidInitialization error:")
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

// DecodeNotInitializingError decodes a NotInitializing error from revert data.
func (c *ParentVault) DecodeNotInitializingError(data []byte) (*NotInitializing, error) {
	args := c.ABI.Errors["NotInitializing"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &NotInitializing{}, nil
}

// Error implements the error interface for NotInitializing.
func (e *NotInitializing) Error() string {
	return fmt.Sprintf("NotInitializing error:")
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

// DecodeParentVaultCannotRemoveActiveProtocolError decodes a ParentVault__CannotRemoveActiveProtocol error from revert data.
func (c *ParentVault) DecodeParentVaultCannotRemoveActiveProtocolError(data []byte) (*ParentVaultCannotRemoveActiveProtocol, error) {
	args := c.ABI.Errors["ParentVault__CannotRemoveActiveProtocol"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	protocolId, ok0 := values[0].([32]byte)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for protocolId in ParentVaultCannotRemoveActiveProtocol error")
	}

	return &ParentVaultCannotRemoveActiveProtocol{
		ProtocolId: protocolId,
	}, nil
}

// Error implements the error interface for ParentVaultCannotRemoveActiveProtocol.
func (e *ParentVaultCannotRemoveActiveProtocol) Error() string {
	return fmt.Sprintf("ParentVaultCannotRemoveActiveProtocol error: protocolId=%v;", e.ProtocolId)
}

// DecodeParentVaultCannotRemovePendingProtocolError decodes a ParentVault__CannotRemovePendingProtocol error from revert data.
func (c *ParentVault) DecodeParentVaultCannotRemovePendingProtocolError(data []byte) (*ParentVaultCannotRemovePendingProtocol, error) {
	args := c.ABI.Errors["ParentVault__CannotRemovePendingProtocol"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	protocolId, ok0 := values[0].([32]byte)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for protocolId in ParentVaultCannotRemovePendingProtocol error")
	}

	return &ParentVaultCannotRemovePendingProtocol{
		ProtocolId: protocolId,
	}, nil
}

// Error implements the error interface for ParentVaultCannotRemovePendingProtocol.
func (e *ParentVaultCannotRemovePendingProtocol) Error() string {
	return fmt.Sprintf("ParentVaultCannotRemovePendingProtocol error: protocolId=%v;", e.ProtocolId)
}

// DecodeParentVaultDepositWouldMintZeroSharesError decodes a ParentVault__DepositWouldMintZeroShares error from revert data.
func (c *ParentVault) DecodeParentVaultDepositWouldMintZeroSharesError(data []byte) (*ParentVaultDepositWouldMintZeroShares, error) {
	args := c.ABI.Errors["ParentVault__DepositWouldMintZeroShares"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &ParentVaultDepositWouldMintZeroShares{}, nil
}

// Error implements the error interface for ParentVaultDepositWouldMintZeroShares.
func (e *ParentVaultDepositWouldMintZeroShares) Error() string {
	return fmt.Sprintf("ParentVaultDepositWouldMintZeroShares error:")
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

// DecodeParentVaultEpochNotNetDepositError decodes a ParentVault__EpochNotNetDeposit error from revert data.
func (c *ParentVault) DecodeParentVaultEpochNotNetDepositError(data []byte) (*ParentVaultEpochNotNetDeposit, error) {
	args := c.ABI.Errors["ParentVault__EpochNotNetDeposit"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	epochNonce, ok0 := values[0].(*big.Int)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for epochNonce in ParentVaultEpochNotNetDeposit error")
	}

	return &ParentVaultEpochNotNetDeposit{
		EpochNonce: epochNonce,
	}, nil
}

// Error implements the error interface for ParentVaultEpochNotNetDeposit.
func (e *ParentVaultEpochNotNetDeposit) Error() string {
	return fmt.Sprintf("ParentVaultEpochNotNetDeposit error: epochNonce=%v;", e.EpochNonce)
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

// DecodeParentVaultInvalidChainSelectorError decodes a ParentVault__InvalidChainSelector error from revert data.
func (c *ParentVault) DecodeParentVaultInvalidChainSelectorError(data []byte) (*ParentVaultInvalidChainSelector, error) {
	args := c.ABI.Errors["ParentVault__InvalidChainSelector"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	chainSelector, ok0 := values[0].(uint64)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for chainSelector in ParentVaultInvalidChainSelector error")
	}

	return &ParentVaultInvalidChainSelector{
		ChainSelector: chainSelector,
	}, nil
}

// Error implements the error interface for ParentVaultInvalidChainSelector.
func (e *ParentVaultInvalidChainSelector) Error() string {
	return fmt.Sprintf("ParentVaultInvalidChainSelector error: chainSelector=%v;", e.ChainSelector)
}

// DecodeParentVaultInvalidEpochNonceError decodes a ParentVault__InvalidEpochNonce error from revert data.
func (c *ParentVault) DecodeParentVaultInvalidEpochNonceError(data []byte) (*ParentVaultInvalidEpochNonce, error) {
	args := c.ABI.Errors["ParentVault__InvalidEpochNonce"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	epochNonce, ok0 := values[0].(*big.Int)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for epochNonce in ParentVaultInvalidEpochNonce error")
	}

	return &ParentVaultInvalidEpochNonce{
		EpochNonce: epochNonce,
	}, nil
}

// Error implements the error interface for ParentVaultInvalidEpochNonce.
func (e *ParentVaultInvalidEpochNonce) Error() string {
	return fmt.Sprintf("ParentVaultInvalidEpochNonce error: epochNonce=%v;", e.EpochNonce)
}

// DecodeParentVaultInvalidPendingProtocolIdError decodes a ParentVault__InvalidPendingProtocolId error from revert data.
func (c *ParentVault) DecodeParentVaultInvalidPendingProtocolIdError(data []byte) (*ParentVaultInvalidPendingProtocolId, error) {
	args := c.ABI.Errors["ParentVault__InvalidPendingProtocolId"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	protocolId, ok0 := values[0].([32]byte)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for protocolId in ParentVaultInvalidPendingProtocolId error")
	}

	return &ParentVaultInvalidPendingProtocolId{
		ProtocolId: protocolId,
	}, nil
}

// Error implements the error interface for ParentVaultInvalidPendingProtocolId.
func (e *ParentVaultInvalidPendingProtocolId) Error() string {
	return fmt.Sprintf("ParentVaultInvalidPendingProtocolId error: protocolId=%v;", e.ProtocolId)
}

// DecodeParentVaultInvalidProtocolIdError decodes a ParentVault__InvalidProtocolId error from revert data.
func (c *ParentVault) DecodeParentVaultInvalidProtocolIdError(data []byte) (*ParentVaultInvalidProtocolId, error) {
	args := c.ABI.Errors["ParentVault__InvalidProtocolId"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	protocolId, ok0 := values[0].([32]byte)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for protocolId in ParentVaultInvalidProtocolId error")
	}

	return &ParentVaultInvalidProtocolId{
		ProtocolId: protocolId,
	}, nil
}

// Error implements the error interface for ParentVaultInvalidProtocolId.
func (e *ParentVaultInvalidProtocolId) Error() string {
	return fmt.Sprintf("ParentVaultInvalidProtocolId error: protocolId=%v;", e.ProtocolId)
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

// DecodeParentVaultNoCompletedEpochError decodes a ParentVault__NoCompletedEpoch error from revert data.
func (c *ParentVault) DecodeParentVaultNoCompletedEpochError(data []byte) (*ParentVaultNoCompletedEpoch, error) {
	args := c.ABI.Errors["ParentVault__NoCompletedEpoch"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &ParentVaultNoCompletedEpoch{}, nil
}

// Error implements the error interface for ParentVaultNoCompletedEpoch.
func (e *ParentVaultNoCompletedEpoch) Error() string {
	return fmt.Sprintf("ParentVaultNoCompletedEpoch error:")
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

// DecodeParentVaultNoZeroProtocolIdError decodes a ParentVault__NoZeroProtocolId error from revert data.
func (c *ParentVault) DecodeParentVaultNoZeroProtocolIdError(data []byte) (*ParentVaultNoZeroProtocolId, error) {
	args := c.ABI.Errors["ParentVault__NoZeroProtocolId"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &ParentVaultNoZeroProtocolId{}, nil
}

// Error implements the error interface for ParentVaultNoZeroProtocolId.
func (e *ParentVaultNoZeroProtocolId) Error() string {
	return fmt.Sprintf("ParentVaultNoZeroProtocolId error:")
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

// DecodeParentVaultRebalanceTooSoonError decodes a ParentVault__RebalanceTooSoon error from revert data.
func (c *ParentVault) DecodeParentVaultRebalanceTooSoonError(data []byte) (*ParentVaultRebalanceTooSoon, error) {
	args := c.ABI.Errors["ParentVault__RebalanceTooSoon"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	rebalanceNonce, ok0 := values[0].(*big.Int)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for rebalanceNonce in ParentVaultRebalanceTooSoon error")
	}

	return &ParentVaultRebalanceTooSoon{
		RebalanceNonce: rebalanceNonce,
	}, nil
}

// Error implements the error interface for ParentVaultRebalanceTooSoon.
func (e *ParentVaultRebalanceTooSoon) Error() string {
	return fmt.Sprintf("ParentVaultRebalanceTooSoon error: rebalanceNonce=%v;", e.RebalanceNonce)
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

// DecodeParentVaultZeroPricePerShareError decodes a ParentVault__ZeroPricePerShare error from revert data.
func (c *ParentVault) DecodeParentVaultZeroPricePerShareError(data []byte) (*ParentVaultZeroPricePerShare, error) {
	args := c.ABI.Errors["ParentVault__ZeroPricePerShare"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &ParentVaultZeroPricePerShare{}, nil
}

// Error implements the error interface for ParentVaultZeroPricePerShare.
func (e *ParentVaultZeroPricePerShare) Error() string {
	return fmt.Sprintf("ParentVaultZeroPricePerShare error:")
}

// DecodeParentVaultZeroTvlWithOutstandingSharesError decodes a ParentVault__ZeroTvlWithOutstandingShares error from revert data.
func (c *ParentVault) DecodeParentVaultZeroTvlWithOutstandingSharesError(data []byte) (*ParentVaultZeroTvlWithOutstandingShares, error) {
	args := c.ABI.Errors["ParentVault__ZeroTvlWithOutstandingShares"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &ParentVaultZeroTvlWithOutstandingShares{}, nil
}

// Error implements the error interface for ParentVaultZeroTvlWithOutstandingShares.
func (e *ParentVaultZeroTvlWithOutstandingShares) Error() string {
	return fmt.Sprintf("ParentVaultZeroTvlWithOutstandingShares error:")
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

// DecodeUUPSUnauthorizedCallContextError decodes a UUPSUnauthorizedCallContext error from revert data.
func (c *ParentVault) DecodeUUPSUnauthorizedCallContextError(data []byte) (*UUPSUnauthorizedCallContext, error) {
	args := c.ABI.Errors["UUPSUnauthorizedCallContext"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &UUPSUnauthorizedCallContext{}, nil
}

// Error implements the error interface for UUPSUnauthorizedCallContext.
func (e *UUPSUnauthorizedCallContext) Error() string {
	return fmt.Sprintf("UUPSUnauthorizedCallContext error:")
}

// DecodeUUPSUnsupportedProxiableUUIDError decodes a UUPSUnsupportedProxiableUUID error from revert data.
func (c *ParentVault) DecodeUUPSUnsupportedProxiableUUIDError(data []byte) (*UUPSUnsupportedProxiableUUID, error) {
	args := c.ABI.Errors["UUPSUnsupportedProxiableUUID"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 1 {
		return nil, fmt.Errorf("expected 1 values, got %d", len(values))
	}

	slot, ok0 := values[0].([32]byte)
	if !ok0 {
		return nil, fmt.Errorf("unexpected type for slot in UUPSUnsupportedProxiableUUID error")
	}

	return &UUPSUnsupportedProxiableUUID{
		Slot: slot,
	}, nil
}

// Error implements the error interface for UUPSUnsupportedProxiableUUID.
func (e *UUPSUnsupportedProxiableUUID) Error() string {
	return fmt.Sprintf("UUPSUnsupportedProxiableUUID error: slot=%v;", e.Slot)
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
	case common.Bytes2Hex(c.ABI.Errors["AddressEmptyCode"].ID.Bytes()[:4]):
		return c.DecodeAddressEmptyCodeError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__DepositFailed"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultDepositFailedError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__DestinationVaultNotSet"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultDestinationVaultNotSetError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__EmptyInput"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultEmptyInputError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__InvalidAdapterVault"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultInvalidAdapterVaultError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__InvalidDestinationChainSelector"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultInvalidDestinationChainSelectorError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__InvalidInputLengths"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultInvalidInputLengthsError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__InvalidReceivedToken"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultInvalidReceivedTokenError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__InvalidSender"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultInvalidSenderError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__InvalidSourceChainSelector"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultInvalidSourceChainSelectorError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__InvalidTokenAmountsLength"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultInvalidTokenAmountsLengthError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__InvalidTxType"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultInvalidTxTypeError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__NoActiveAdapter"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultNoActiveAdapterError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__NoAdapterRegistered"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultNoAdapterRegisteredError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__NoPendingRecovery"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultNoPendingRecoveryError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__NoZeroAddress"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultNoZeroAddressError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__NoZeroAmount"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultNoZeroAmountError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__NoZeroChainSelector"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultNoZeroChainSelectorError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__OnlySelf"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultOnlySelfError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__RecoveryAlreadyPending"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultRecoveryAlreadyPendingError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__WithdrawFailed"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultWithdrawFailedError(data)
	case common.Bytes2Hex(c.ABI.Errors["BaseVault__ZeroRecoveryAmount"].ID.Bytes()[:4]):
		return c.DecodeBaseVaultZeroRecoveryAmountError(data)
	case common.Bytes2Hex(c.ABI.Errors["ERC1967InvalidImplementation"].ID.Bytes()[:4]):
		return c.DecodeERC1967InvalidImplementationError(data)
	case common.Bytes2Hex(c.ABI.Errors["ERC1967NonPayable"].ID.Bytes()[:4]):
		return c.DecodeERC1967NonPayableError(data)
	case common.Bytes2Hex(c.ABI.Errors["EnforcedPause"].ID.Bytes()[:4]):
		return c.DecodeEnforcedPauseError(data)
	case common.Bytes2Hex(c.ABI.Errors["ExpectedPause"].ID.Bytes()[:4]):
		return c.DecodeExpectedPauseError(data)
	case common.Bytes2Hex(c.ABI.Errors["FailedCall"].ID.Bytes()[:4]):
		return c.DecodeFailedCallError(data)
	case common.Bytes2Hex(c.ABI.Errors["InvalidInitialization"].ID.Bytes()[:4]):
		return c.DecodeInvalidInitializationError(data)
	case common.Bytes2Hex(c.ABI.Errors["InvalidRouter"].ID.Bytes()[:4]):
		return c.DecodeInvalidRouterError(data)
	case common.Bytes2Hex(c.ABI.Errors["NotInitializing"].ID.Bytes()[:4]):
		return c.DecodeNotInitializingError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__AmountTooSmall"].ID.Bytes()[:4]):
		return c.DecodeParentVaultAmountTooSmallError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__CannotRemoveActiveProtocol"].ID.Bytes()[:4]):
		return c.DecodeParentVaultCannotRemoveActiveProtocolError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__CannotRemovePendingProtocol"].ID.Bytes()[:4]):
		return c.DecodeParentVaultCannotRemovePendingProtocolError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__DepositWouldMintZeroShares"].ID.Bytes()[:4]):
		return c.DecodeParentVaultDepositWouldMintZeroSharesError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__EmptyEpoch"].ID.Bytes()[:4]):
		return c.DecodeParentVaultEmptyEpochError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__EpochExecuting"].ID.Bytes()[:4]):
		return c.DecodeParentVaultEpochExecutingError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__EpochNotClaimable"].ID.Bytes()[:4]):
		return c.DecodeParentVaultEpochNotClaimableError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__EpochNotExecuting"].ID.Bytes()[:4]):
		return c.DecodeParentVaultEpochNotExecutingError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__EpochNotNetDeposit"].ID.Bytes()[:4]):
		return c.DecodeParentVaultEpochNotNetDepositError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__EpochNotOpen"].ID.Bytes()[:4]):
		return c.DecodeParentVaultEpochNotOpenError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__EpochTooShort"].ID.Bytes()[:4]):
		return c.DecodeParentVaultEpochTooShortError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__InitialActiveProtocolAdapterAlreadySet"].ID.Bytes()[:4]):
		return c.DecodeParentVaultInitialActiveProtocolAdapterAlreadySetError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__InvalidChainSelector"].ID.Bytes()[:4]):
		return c.DecodeParentVaultInvalidChainSelectorError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__InvalidEpochNonce"].ID.Bytes()[:4]):
		return c.DecodeParentVaultInvalidEpochNonceError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__InvalidPendingProtocolId"].ID.Bytes()[:4]):
		return c.DecodeParentVaultInvalidPendingProtocolIdError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__InvalidProtocolId"].ID.Bytes()[:4]):
		return c.DecodeParentVaultInvalidProtocolIdError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__InvalidRebalanceNonce"].ID.Bytes()[:4]):
		return c.DecodeParentVaultInvalidRebalanceNonceError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__NoCompletedEpoch"].ID.Bytes()[:4]):
		return c.DecodeParentVaultNoCompletedEpochError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__NoDeposit"].ID.Bytes()[:4]):
		return c.DecodeParentVaultNoDepositError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__NoRebalanceInProgress"].ID.Bytes()[:4]):
		return c.DecodeParentVaultNoRebalanceInProgressError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__NoWithdraw"].ID.Bytes()[:4]):
		return c.DecodeParentVaultNoWithdrawError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__NoZeroAmount"].ID.Bytes()[:4]):
		return c.DecodeParentVaultNoZeroAmountError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__NoZeroProtocolId"].ID.Bytes()[:4]):
		return c.DecodeParentVaultNoZeroProtocolIdError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__RebalanceInProgress"].ID.Bytes()[:4]):
		return c.DecodeParentVaultRebalanceInProgressError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__RebalanceTooSoon"].ID.Bytes()[:4]):
		return c.DecodeParentVaultRebalanceTooSoonError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__SameStrategy"].ID.Bytes()[:4]):
		return c.DecodeParentVaultSameStrategyError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__ZeroPricePerShare"].ID.Bytes()[:4]):
		return c.DecodeParentVaultZeroPricePerShareError(data)
	case common.Bytes2Hex(c.ABI.Errors["ParentVault__ZeroTvlWithOutstandingShares"].ID.Bytes()[:4]):
		return c.DecodeParentVaultZeroTvlWithOutstandingSharesError(data)
	case common.Bytes2Hex(c.ABI.Errors["ReentrancyGuardReentrantCall"].ID.Bytes()[:4]):
		return c.DecodeReentrancyGuardReentrantCallError(data)
	case common.Bytes2Hex(c.ABI.Errors["SafeCastOverflowedUintDowncast"].ID.Bytes()[:4]):
		return c.DecodeSafeCastOverflowedUintDowncastError(data)
	case common.Bytes2Hex(c.ABI.Errors["SafeERC20FailedOperation"].ID.Bytes()[:4]):
		return c.DecodeSafeERC20FailedOperationError(data)
	case common.Bytes2Hex(c.ABI.Errors["UUPSUnauthorizedCallContext"].ID.Bytes()[:4]):
		return c.DecodeUUPSUnauthorizedCallContextError(data)
	case common.Bytes2Hex(c.ABI.Errors["UUPSUnsupportedProxiableUUID"].ID.Bytes()[:4]):
		return c.DecodeUUPSUnsupportedProxiableUUIDError(data)
	default:
		return nil, errors.New("unknown error selector")
	}
}

// ActiveProtocolAdapterClearedTrigger wraps the raw log trigger and provides decoded ActiveProtocolAdapterClearedDecoded data
type ActiveProtocolAdapterClearedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into ActiveProtocolAdapterCleared data
func (t *ActiveProtocolAdapterClearedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[ActiveProtocolAdapterClearedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeActiveProtocolAdapterCleared(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode ActiveProtocolAdapterCleared log: %w", err)
	}

	return &bindings.DecodedLog[ActiveProtocolAdapterClearedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerActiveProtocolAdapterClearedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []ActiveProtocolAdapterClearedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[ActiveProtocolAdapterClearedDecoded]], error) {
	event := c.ABI.Events["ActiveProtocolAdapterCleared"]
	topics, err := c.Codec.EncodeActiveProtocolAdapterClearedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for ActiveProtocolAdapterCleared: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &ActiveProtocolAdapterClearedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsActiveProtocolAdapterCleared(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.ActiveProtocolAdapterClearedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// ActiveProtocolAdapterSetTrigger wraps the raw log trigger and provides decoded ActiveProtocolAdapterSetDecoded data
type ActiveProtocolAdapterSetTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into ActiveProtocolAdapterSet data
func (t *ActiveProtocolAdapterSetTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[ActiveProtocolAdapterSetDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeActiveProtocolAdapterSet(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode ActiveProtocolAdapterSet log: %w", err)
	}

	return &bindings.DecodedLog[ActiveProtocolAdapterSetDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerActiveProtocolAdapterSetLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []ActiveProtocolAdapterSetTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[ActiveProtocolAdapterSetDecoded]], error) {
	event := c.ABI.Events["ActiveProtocolAdapterSet"]
	topics, err := c.Codec.EncodeActiveProtocolAdapterSetTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for ActiveProtocolAdapterSet: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &ActiveProtocolAdapterSetTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsActiveProtocolAdapterSet(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.ActiveProtocolAdapterSetLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
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

// CCIPReceivedTrigger wraps the raw log trigger and provides decoded CCIPReceivedDecoded data
type CCIPReceivedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into CCIPReceived data
func (t *CCIPReceivedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[CCIPReceivedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeCCIPReceived(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode CCIPReceived log: %w", err)
	}

	return &bindings.DecodedLog[CCIPReceivedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerCCIPReceivedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []CCIPReceivedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[CCIPReceivedDecoded]], error) {
	event := c.ABI.Events["CCIPReceived"]
	topics, err := c.Codec.EncodeCCIPReceivedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for CCIPReceived: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &CCIPReceivedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsCCIPReceived(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.CCIPReceivedLogHash()}},
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

// DepositForceCancelledTrigger wraps the raw log trigger and provides decoded DepositForceCancelledDecoded data
type DepositForceCancelledTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into DepositForceCancelled data
func (t *DepositForceCancelledTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[DepositForceCancelledDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeDepositForceCancelled(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode DepositForceCancelled log: %w", err)
	}

	return &bindings.DecodedLog[DepositForceCancelledDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerDepositForceCancelledLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []DepositForceCancelledTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[DepositForceCancelledDecoded]], error) {
	event := c.ABI.Events["DepositForceCancelled"]
	topics, err := c.Codec.EncodeDepositForceCancelledTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for DepositForceCancelled: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &DepositForceCancelledTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsDepositForceCancelled(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.DepositForceCancelledLogHash()}},
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

// EpochClaimable0Trigger wraps the raw log trigger and provides decoded EpochClaimable0Decoded data
type EpochClaimable0Trigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into EpochClaimable0 data
func (t *EpochClaimable0Trigger) Adapt(l *evm.Log) (*bindings.DecodedLog[EpochClaimable0Decoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeEpochClaimable0(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode EpochClaimable0 log: %w", err)
	}

	return &bindings.DecodedLog[EpochClaimable0Decoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerEpochClaimable0Log(chainSelector uint64, confidence evm.ConfidenceLevel, filters []EpochClaimable0Topics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[EpochClaimable0Decoded]], error) {
	event := c.ABI.Events["EpochClaimable0"]
	topics, err := c.Codec.EncodeEpochClaimable0Topics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for EpochClaimable0: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &EpochClaimable0Trigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsEpochClaimable0(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.EpochClaimable0LogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// EpochDepositExecutingTrigger wraps the raw log trigger and provides decoded EpochDepositExecutingDecoded data
type EpochDepositExecutingTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into EpochDepositExecuting data
func (t *EpochDepositExecutingTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[EpochDepositExecutingDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeEpochDepositExecuting(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode EpochDepositExecuting log: %w", err)
	}

	return &bindings.DecodedLog[EpochDepositExecutingDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerEpochDepositExecutingLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []EpochDepositExecutingTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[EpochDepositExecutingDecoded]], error) {
	event := c.ABI.Events["EpochDepositExecuting"]
	topics, err := c.Codec.EncodeEpochDepositExecutingTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for EpochDepositExecuting: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &EpochDepositExecutingTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsEpochDepositExecuting(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.EpochDepositExecutingLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// EpochDepositToStrategySuccessTrigger wraps the raw log trigger and provides decoded EpochDepositToStrategySuccessDecoded data
type EpochDepositToStrategySuccessTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into EpochDepositToStrategySuccess data
func (t *EpochDepositToStrategySuccessTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[EpochDepositToStrategySuccessDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeEpochDepositToStrategySuccess(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode EpochDepositToStrategySuccess log: %w", err)
	}

	return &bindings.DecodedLog[EpochDepositToStrategySuccessDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerEpochDepositToStrategySuccessLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []EpochDepositToStrategySuccessTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[EpochDepositToStrategySuccessDecoded]], error) {
	event := c.ABI.Events["EpochDepositToStrategySuccess"]
	topics, err := c.Codec.EncodeEpochDepositToStrategySuccessTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for EpochDepositToStrategySuccess: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &EpochDepositToStrategySuccessTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsEpochDepositToStrategySuccess(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.EpochDepositToStrategySuccessLogHash()}},
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

// EpochWithdrawAmountShort0Trigger wraps the raw log trigger and provides decoded EpochWithdrawAmountShort0Decoded data
type EpochWithdrawAmountShort0Trigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into EpochWithdrawAmountShort0 data
func (t *EpochWithdrawAmountShort0Trigger) Adapt(l *evm.Log) (*bindings.DecodedLog[EpochWithdrawAmountShort0Decoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeEpochWithdrawAmountShort0(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode EpochWithdrawAmountShort0 log: %w", err)
	}

	return &bindings.DecodedLog[EpochWithdrawAmountShort0Decoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerEpochWithdrawAmountShort0Log(chainSelector uint64, confidence evm.ConfidenceLevel, filters []EpochWithdrawAmountShort0Topics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[EpochWithdrawAmountShort0Decoded]], error) {
	event := c.ABI.Events["EpochWithdrawAmountShort0"]
	topics, err := c.Codec.EncodeEpochWithdrawAmountShort0Topics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for EpochWithdrawAmountShort0: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &EpochWithdrawAmountShort0Trigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsEpochWithdrawAmountShort0(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.EpochWithdrawAmountShort0LogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// EpochWithdrawExecutingTrigger wraps the raw log trigger and provides decoded EpochWithdrawExecutingDecoded data
type EpochWithdrawExecutingTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into EpochWithdrawExecuting data
func (t *EpochWithdrawExecutingTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[EpochWithdrawExecutingDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeEpochWithdrawExecuting(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode EpochWithdrawExecuting log: %w", err)
	}

	return &bindings.DecodedLog[EpochWithdrawExecutingDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerEpochWithdrawExecutingLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []EpochWithdrawExecutingTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[EpochWithdrawExecutingDecoded]], error) {
	event := c.ABI.Events["EpochWithdrawExecuting"]
	topics, err := c.Codec.EncodeEpochWithdrawExecutingTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for EpochWithdrawExecuting: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &EpochWithdrawExecutingTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsEpochWithdrawExecuting(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.EpochWithdrawExecutingLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// EpochWithdrawFromStrategySuccessTrigger wraps the raw log trigger and provides decoded EpochWithdrawFromStrategySuccessDecoded data
type EpochWithdrawFromStrategySuccessTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into EpochWithdrawFromStrategySuccess data
func (t *EpochWithdrawFromStrategySuccessTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[EpochWithdrawFromStrategySuccessDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeEpochWithdrawFromStrategySuccess(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode EpochWithdrawFromStrategySuccess log: %w", err)
	}

	return &bindings.DecodedLog[EpochWithdrawFromStrategySuccessDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerEpochWithdrawFromStrategySuccessLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []EpochWithdrawFromStrategySuccessTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[EpochWithdrawFromStrategySuccessDecoded]], error) {
	event := c.ABI.Events["EpochWithdrawFromStrategySuccess"]
	topics, err := c.Codec.EncodeEpochWithdrawFromStrategySuccessTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for EpochWithdrawFromStrategySuccess: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &EpochWithdrawFromStrategySuccessTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsEpochWithdrawFromStrategySuccess(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.EpochWithdrawFromStrategySuccessLogHash()}},
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

// InitializedTrigger wraps the raw log trigger and provides decoded InitializedDecoded data
type InitializedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into Initialized data
func (t *InitializedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[InitializedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeInitialized(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode Initialized log: %w", err)
	}

	return &bindings.DecodedLog[InitializedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerInitializedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []InitializedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[InitializedDecoded]], error) {
	event := c.ABI.Events["Initialized"]
	topics, err := c.Codec.EncodeInitializedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for Initialized: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &InitializedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsInitialized(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.InitializedLogHash()}},
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

// ManagementFeeCollected0Trigger wraps the raw log trigger and provides decoded ManagementFeeCollected0Decoded data
type ManagementFeeCollected0Trigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into ManagementFeeCollected0 data
func (t *ManagementFeeCollected0Trigger) Adapt(l *evm.Log) (*bindings.DecodedLog[ManagementFeeCollected0Decoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeManagementFeeCollected0(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode ManagementFeeCollected0 log: %w", err)
	}

	return &bindings.DecodedLog[ManagementFeeCollected0Decoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerManagementFeeCollected0Log(chainSelector uint64, confidence evm.ConfidenceLevel, filters []ManagementFeeCollected0Topics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[ManagementFeeCollected0Decoded]], error) {
	event := c.ABI.Events["ManagementFeeCollected0"]
	topics, err := c.Codec.EncodeManagementFeeCollected0Topics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for ManagementFeeCollected0: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &ManagementFeeCollected0Trigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsManagementFeeCollected0(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.ManagementFeeCollected0LogHash()}},
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

// RebalanceCompleted0Trigger wraps the raw log trigger and provides decoded RebalanceCompleted0Decoded data
type RebalanceCompleted0Trigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into RebalanceCompleted0 data
func (t *RebalanceCompleted0Trigger) Adapt(l *evm.Log) (*bindings.DecodedLog[RebalanceCompleted0Decoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeRebalanceCompleted0(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode RebalanceCompleted0 log: %w", err)
	}

	return &bindings.DecodedLog[RebalanceCompleted0Decoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerRebalanceCompleted0Log(chainSelector uint64, confidence evm.ConfidenceLevel, filters []RebalanceCompleted0Topics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[RebalanceCompleted0Decoded]], error) {
	event := c.ABI.Events["RebalanceCompleted0"]
	topics, err := c.Codec.EncodeRebalanceCompleted0Topics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for RebalanceCompleted0: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &RebalanceCompleted0Trigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsRebalanceCompleted0(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.RebalanceCompleted0LogHash()}},
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

// SupportedProtocolSetTrigger wraps the raw log trigger and provides decoded SupportedProtocolSetDecoded data
type SupportedProtocolSetTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into SupportedProtocolSet data
func (t *SupportedProtocolSetTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[SupportedProtocolSetDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeSupportedProtocolSet(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode SupportedProtocolSet log: %w", err)
	}

	return &bindings.DecodedLog[SupportedProtocolSetDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerSupportedProtocolSetLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []SupportedProtocolSetTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[SupportedProtocolSetDecoded]], error) {
	event := c.ABI.Events["SupportedProtocolSet"]
	topics, err := c.Codec.EncodeSupportedProtocolSetTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for SupportedProtocolSet: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &SupportedProtocolSetTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsSupportedProtocolSet(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.SupportedProtocolSetLogHash()}},
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

// UpgradedTrigger wraps the raw log trigger and provides decoded UpgradedDecoded data
type UpgradedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]              // Embed the raw trigger
	contract                        *ParentVault // Keep reference for decoding
}

// Adapt method that decodes the log into Upgraded data
func (t *UpgradedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[UpgradedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeUpgraded(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode Upgraded log: %w", err)
	}

	return &bindings.DecodedLog[UpgradedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *ParentVault) LogTriggerUpgradedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []UpgradedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[UpgradedDecoded]], error) {
	event := c.ABI.Events["Upgraded"]
	topics, err := c.Codec.EncodeUpgradedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for Upgraded: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &UpgradedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *ParentVault) FilterLogsUpgraded(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.UpgradedLogHash()}},
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

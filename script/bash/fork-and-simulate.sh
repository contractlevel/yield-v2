#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVM_DIR="$ROOT_DIR/evm"
CRE_DIR="$ROOT_DIR/cre"
LOG_DIR="$ROOT_DIR/script/bash/logs"
LOCAL_CONFIG="$CRE_DIR/workflow/config.local-fork.generated.json"
PID_FILE="$LOG_DIR/anvil-local-fork.pids"
KILL_ONLY=false
SIMULATE=false
TRIGGER_INDEX=0

usage() {
  cat <<'USAGE'
Usage: bash script/bash/fork-and-simulate.sh [--simulate] [--trigger-index N]
       bash script/bash/fork-and-simulate.sh --kill

Starts local Anvil mainnet forks, deploys Yieldcoin v2 contracts, writes
cre/workflow/config.local-fork.generated.json, and optionally dry-runs CRE simulation.

Options:
  --simulate         Run CRE workflow simulation after config generation.
  --trigger-index N  CRE handler index for --simulate. Defaults to 0.
  --kill             Stop Anvil processes recorded from the previous run.
  -h, --help         Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --kill)
      KILL_ONLY=true
      shift
      ;;
    --simulate)
      SIMULATE=true
      shift
      ;;
    --trigger-index)
      if [[ $# -lt 2 || ! "$2" =~ ^[0-9]+$ ]]; then
        echo "ERROR: --trigger-index requires a non-negative integer" >&2
        exit 1
      fi
      TRIGGER_INDEX="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: required command not found: $1" >&2
    exit 1
  fi
}

require_env() {
  if [[ -z "${!1:-}" ]]; then
    echo "ERROR: $1 must be set in evm/.env or the environment" >&2
    exit 1
  fi
}

load_env() {
  local env_file="$EVM_DIR/.env"
  if [[ ! -f "$env_file" ]]; then
    echo "ERROR: expected env file at $env_file" >&2
    exit 1
  fi

  set -a
  # shellcheck disable=SC1090
  . "$env_file"
  set +a
}

load_cre_env() {
  local env_file="$CRE_DIR/.env"
  if [[ ! -f "$env_file" ]]; then
    echo "ERROR: expected env file at $env_file" >&2
    exit 1
  fi

  set -a
  # shellcheck disable=SC1090
  . "$env_file"
  set +a
}

kill_recorded_anvils() {
  if [[ ! -f "$PID_FILE" ]]; then
    echo "No local fork PID file found at $PID_FILE"
    return 0
  fi

  while IFS= read -r pid; do
    if [[ -n "$pid" ]] && kill -0 "$pid" >/dev/null 2>&1; then
      echo "Stopping Anvil PID $pid..."
      kill "$pid" >/dev/null 2>&1 || true
    fi
  done <"$PID_FILE"

  rm -f "$PID_FILE"
}

warn_on_error() {
  echo
  if [[ "${#ANVIL_PIDS[@]}" -gt 0 ]]; then
    echo "Script failed. Anvil forks may still be running."
    echo "To stop them: bash script/bash/fork-and-simulate.sh --kill"
  else
    echo "Script failed before any forks were started."
  fi
}

cleanup_started_anvils() {
  if [[ "${#ANVIL_PIDS[@]}" -eq 0 ]]; then
    return 0
  fi

  echo
  echo "Stopping Anvil forks started by this run..."
  for pid in "${ANVIL_PIDS[@]}"; do
    if kill -0 "$pid" >/dev/null 2>&1; then
      kill "$pid" >/dev/null 2>&1 || true
    fi
  done
  rm -f "$PID_FILE"
}

on_interrupt() {
  cleanup_started_anvils
  exit 130
}

check_ports_available() {
  local ports=(8545 8546 8547 8548 8549)
  local port

  for port in "${ports[@]}"; do
    if lsof -ti:"$port" >/dev/null 2>&1; then
      echo "ERROR: port $port is already in use" >&2
      echo "Stop the process using it or choose different ports before running this script." >&2
      exit 1
    fi
  done
}

wait_for_anvil() {
  local port="$1"
  local max_attempts=30
  local attempt=0

  echo "Waiting for Anvil on port $port..."
  while [[ "$attempt" -lt "$max_attempts" ]]; do
    if curl -s -X POST "http://127.0.0.1:$port" \
      -H "Content-Type: application/json" \
      -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
      >/dev/null 2>&1; then
      echo "Anvil on port $port is ready."
      return 0
    fi
    attempt=$((attempt + 1))
    sleep 1
  done

  echo "ERROR: Anvil on port $port failed to become ready" >&2
  return 1
}

fund_deployer() {
  local port="$1"
  local balance_wei="0x3635c9adc5dea00000" # 1000 ETH

  curl -s -X POST "http://127.0.0.1:$port" \
    -H "Content-Type: application/json" \
    -d "{\"jsonrpc\":\"2.0\",\"method\":\"anvil_setBalance\",\"params\":[\"$DEPLOYER_ADDRESS\",\"$balance_wei\"],\"id\":1}" \
    >/dev/null
}

start_anvil() {
  local name="$1"
  local rpc_url="$2"
  local port="$3"
  local block_offset="$4"
  local log_file="$LOG_DIR/anvil-$name.log"
  local latest_block
  local fork_block

  latest_block="$(cast block-number --rpc-url "$rpc_url")"
  if (( latest_block <= block_offset )); then
    echo "ERROR: latest $name block $latest_block is too low for offset $block_offset" >&2
    exit 1
  fi
  fork_block="$((latest_block - block_offset))"

  echo "Starting $name fork on port $port at block $fork_block..."
  anvil --fork-url "$rpc_url" --fork-block-number "$fork_block" --port "$port" >"$log_file" 2>&1 &
  ANVIL_PIDS+=("$!")
  printf '%s\n' "${ANVIL_PIDS[@]}" >"$PID_FILE"
  wait_for_anvil "$port"
  fund_deployer "$port"
}

deploy_contracts() {
  local label="$1"
  local script_path="$2"
  local port="$3"
  local chain_id="$4"

  echo "Deploying $label on local port $port..."
  (
    cd "$EVM_DIR"
    forge script "$script_path" \
      --rpc-url "http://127.0.0.1:$port" \
      --private-key "$DEFAULT_ANVIL_PRIVATE_KEY" \
      --broadcast \
      --slow \
      --chain-id "$chain_id"
  )
}

read_address() {
  local deploy_file="$1"
  local contract_name="$2"
  local address

  if [[ ! -f "$deploy_file" ]]; then
    echo "ERROR: missing deploy artifact: $deploy_file" >&2
    exit 1
  fi

  address="$(jq -er --arg name "$contract_name" '
    .transactions[]
    | select(.contractName == $name and .contractAddress != null)
    | .contractAddress
  ' "$deploy_file" | tail -n 1 || true)"

  if [[ -z "$address" || "$address" == "null" || "$address" == "0x0000000000000000000000000000000000000000" ]]; then
    echo "ERROR: could not read $contract_name address from $deploy_file" >&2
    exit 1
  fi

  echo "$address"
}

# ParentVault and ChildVault are deployed as an implementation contract
# immediately followed by its ERC1967Proxy (DeployParent.s.sol / DeployChild.s.sol
# always emit `new X()` then `new ERC1967Proxy(address(x), ...)` back to back).
# The broadcast artifact records the proxy's CREATE under contractName
# "ERC1967Proxy", not the vault's name, so read_address() would otherwise return
# the unproxied implementation address instead of the live, stateful contract.
read_proxy_address() {
  local deploy_file="$1"
  local contract_name="$2"
  local address

  if [[ ! -f "$deploy_file" ]]; then
    echo "ERROR: missing deploy artifact: $deploy_file" >&2
    exit 1
  fi

  address="$(jq -er --arg name "$contract_name" '
    (.transactions | to_entries) as $entries
    | ($entries | map(select(.value.contractName == $name)) | last) as $impl
    | if $impl == null then empty
      else $entries[$impl.key + 1].value
        | select(.contractName == "ERC1967Proxy" and .contractAddress != null)
        | .contractAddress
      end
  ' "$deploy_file" || true)"

  if [[ -z "$address" || "$address" == "null" || "$address" == "0x0000000000000000000000000000000000000000" ]]; then
    echo "ERROR: could not read $contract_name proxy address from $deploy_file" >&2
    exit 1
  fi

  echo "$address"
}

restore_exact_chain_selectors() {
  local config_file="$1"
  local tmp_file="${config_file}.selectors.tmp"

  awk '
    /"chainName": "ethereum-mainnet-arbitrum-1"/ { selector = "4949039107694359620" }
    /"chainName": "avalanche-mainnet"/ { selector = "6433500567565415381" }
    /"chainName": "ethereum-mainnet"/ { selector = "5009297550715157269" }
    /"chainName": "ethereum-mainnet-base-1"/ { selector = "15971525489660198786" }
    /"chainName": "ethereum-mainnet-optimism-1"/ { selector = "3734403246176062136" }
    /"chainSelector":/ && selector != "" {
      sub(/"chainSelector": .*/, "\"chainSelector\": " selector ",")
      selector = ""
    }
    { print }
  ' "$config_file" >"$tmp_file"

  mv "$tmp_file" "$config_file"
}

write_local_cre_config() {
  local parent_vault="$1"
  local parent_router="$2"
  local avalanche_vault="$3"
  local avalanche_router="$4"
  local ethereum_vault="$5"
  local ethereum_router="$6"
  local base_vault="$7"
  local base_router="$8"
  local optimism_vault="$9"
  local optimism_router="${10}"
  local tmp_config

  tmp_config="$(mktemp "${LOCAL_CONFIG}.tmp.XXXXXX")"
  trap 'rm -f "$tmp_config"' RETURN

  jq \
    --arg parentVault "$parent_vault" \
    --arg parentRouter "$parent_router" \
    --arg avalancheVault "$avalanche_vault" \
    --arg avalancheRouter "$avalanche_router" \
    --arg ethereumVault "$ethereum_vault" \
    --arg ethereumRouter "$ethereum_router" \
    --arg baseVault "$base_vault" \
    --arg baseRouter "$base_router" \
    --arg optimismVault "$optimism_vault" \
    --arg optimismRouter "$optimism_router" \
    '
      .rebalanceSchedule = "* * * * * *"
      | .epochSchedule = "* * * * * *"
      | .evms |= map(select(.chainName != "polygon-mainnet"))
      | .evms |= map(
          if .chainName == "ethereum-mainnet-arbitrum-1" then
            .isParent = true
            | .vaultAddress = $parentVault
            | .workflowRouterAddress = $parentRouter
          elif .chainName == "avalanche-mainnet" then
            .isParent = false
            | .vaultAddress = $avalancheVault
            | .workflowRouterAddress = $avalancheRouter
          elif .chainName == "ethereum-mainnet" then
            .isParent = false
            | .vaultAddress = $ethereumVault
            | .workflowRouterAddress = $ethereumRouter
          elif .chainName == "ethereum-mainnet-base-1" then
            .isParent = false
            | .vaultAddress = $baseVault
            | .workflowRouterAddress = $baseRouter
          elif .chainName == "ethereum-mainnet-optimism-1" then
            .isParent = false
            | .vaultAddress = $optimismVault
            | .workflowRouterAddress = $optimismRouter
          else
            .
          end
        )
    ' "$CRE_DIR/workflow/config.staging.json" >"$tmp_config"
  restore_exact_chain_selectors "$tmp_config"
  mv "$tmp_config" "$LOCAL_CONFIG"
  trap - RETURN
}

run_simulation() {
  echo "Running CRE simulation with trigger index $TRIGGER_INDEX..."
  (
    cd "$CRE_DIR"
    cre workflow simulate workflow \
      --target local-fork-settings \
      --non-interactive \
      --trigger-index "$TRIGGER_INDEX"
  )
}

ANVIL_PIDS=()
trap on_interrupt INT TERM

if [[ "$KILL_ONLY" == true ]]; then
  mkdir -p "$LOG_DIR"
  kill_recorded_anvils
  exit 0
fi

trap warn_on_error ERR

load_env
if [[ "$SIMULATE" == true ]]; then
  load_cre_env
fi
DEFAULT_ANVIL_PRIVATE_KEY="${DEFAULT_ANVIL_PRIVATE_KEY:-0xac0974bec39a17e36ba4a6f4d238ff944bacb478cbed5efcae784d7bf4f2ff80}"

require_command anvil
require_command cast
require_command forge
require_command jq
require_command curl
if [[ "$SIMULATE" == true ]]; then
  require_command cre
fi

require_env ARBITRUM_MAINNET_RPC_URL
require_env AVALANCHE_MAINNET_RPC_URL
require_env ETHEREUM_MAINNET_RPC_URL
require_env BASE_MAINNET_RPC_URL
require_env OPTIMISM_MAINNET_RPC_URL
if [[ "$SIMULATE" == true ]]; then
  require_env YIELD_RELAY_TOKEN_VAR
fi

DEPLOYER_ADDRESS="$(cast wallet address --private-key "$DEFAULT_ANVIL_PRIVATE_KEY")"

mkdir -p "$LOG_DIR"
check_ports_available

start_anvil "arbitrum" "$ARBITRUM_MAINNET_RPC_URL" 8545 30000
start_anvil "avalanche" "$AVALANCHE_MAINNET_RPC_URL" 8546 12600
start_anvil "ethereum" "$ETHEREUM_MAINNET_RPC_URL" 8547 2100
start_anvil "base" "$BASE_MAINNET_RPC_URL" 8548 12600
start_anvil "optimism" "$OPTIMISM_MAINNET_RPC_URL" 8549 12600

deploy_contracts "ParentVault and modules" "script/deploy/DeployParent.s.sol" 8545 42161
deploy_contracts "Avalanche ChildVault and modules" "script/deploy/DeployChild.s.sol" 8546 43114
deploy_contracts "Ethereum ChildVault and modules" "script/deploy/DeployChild.s.sol" 8547 1
deploy_contracts "Base ChildVault and modules" "script/deploy/DeployChild.s.sol" 8548 8453
deploy_contracts "Optimism ChildVault and modules" "script/deploy/DeployChild.s.sol" 8549 10

ARBITRUM_DEPLOY_FILE="$EVM_DIR/broadcast/DeployParent.s.sol/42161/run-latest.json"
AVALANCHE_DEPLOY_FILE="$EVM_DIR/broadcast/DeployChild.s.sol/43114/run-latest.json"
ETHEREUM_DEPLOY_FILE="$EVM_DIR/broadcast/DeployChild.s.sol/1/run-latest.json"
BASE_DEPLOY_FILE="$EVM_DIR/broadcast/DeployChild.s.sol/8453/run-latest.json"
OPTIMISM_DEPLOY_FILE="$EVM_DIR/broadcast/DeployChild.s.sol/10/run-latest.json"

PARENT_VAULT_ADDRESS="$(read_proxy_address "$ARBITRUM_DEPLOY_FILE" "ParentVault")"
PARENT_ROUTER_ADDRESS="$(read_address "$ARBITRUM_DEPLOY_FILE" "WorkflowRouter")"
CHILD_VAULT_AVALANCHE_ADDRESS="$(read_proxy_address "$AVALANCHE_DEPLOY_FILE" "ChildVault")"
CHILD_ROUTER_AVALANCHE_ADDRESS="$(read_address "$AVALANCHE_DEPLOY_FILE" "WorkflowRouter")"
CHILD_VAULT_ETHEREUM_ADDRESS="$(read_proxy_address "$ETHEREUM_DEPLOY_FILE" "ChildVault")"
CHILD_ROUTER_ETHEREUM_ADDRESS="$(read_address "$ETHEREUM_DEPLOY_FILE" "WorkflowRouter")"
CHILD_VAULT_BASE_ADDRESS="$(read_proxy_address "$BASE_DEPLOY_FILE" "ChildVault")"
CHILD_ROUTER_BASE_ADDRESS="$(read_address "$BASE_DEPLOY_FILE" "WorkflowRouter")"
CHILD_VAULT_OPTIMISM_ADDRESS="$(read_proxy_address "$OPTIMISM_DEPLOY_FILE" "ChildVault")"
CHILD_ROUTER_OPTIMISM_ADDRESS="$(read_address "$OPTIMISM_DEPLOY_FILE" "WorkflowRouter")"

write_local_cre_config \
  "$PARENT_VAULT_ADDRESS" \
  "$PARENT_ROUTER_ADDRESS" \
  "$CHILD_VAULT_AVALANCHE_ADDRESS" \
  "$CHILD_ROUTER_AVALANCHE_ADDRESS" \
  "$CHILD_VAULT_ETHEREUM_ADDRESS" \
  "$CHILD_ROUTER_ETHEREUM_ADDRESS" \
  "$CHILD_VAULT_BASE_ADDRESS" \
  "$CHILD_ROUTER_BASE_ADDRESS" \
  "$CHILD_VAULT_OPTIMISM_ADDRESS" \
  "$CHILD_ROUTER_OPTIMISM_ADDRESS"

echo
echo "=========================================="
echo "  DEPLOYMENT SUMMARY"
echo "=========================================="
echo "Arbitrum parent:"
echo "  ParentVault:     $PARENT_VAULT_ADDRESS"
echo "  WorkflowRouter:  $PARENT_ROUTER_ADDRESS"
echo "Avalanche child:"
echo "  ChildVault:      $CHILD_VAULT_AVALANCHE_ADDRESS"
echo "  WorkflowRouter:  $CHILD_ROUTER_AVALANCHE_ADDRESS"
echo "Ethereum child:"
echo "  ChildVault:      $CHILD_VAULT_ETHEREUM_ADDRESS"
echo "  WorkflowRouter:  $CHILD_ROUTER_ETHEREUM_ADDRESS"
echo "Base child:"
echo "  ChildVault:      $CHILD_VAULT_BASE_ADDRESS"
echo "  WorkflowRouter:  $CHILD_ROUTER_BASE_ADDRESS"
echo "Optimism child:"
echo "  ChildVault:      $CHILD_VAULT_OPTIMISM_ADDRESS"
echo "  WorkflowRouter:  $CHILD_ROUTER_OPTIMISM_ADDRESS"
echo
echo "CRE config written to:"
echo "  $LOCAL_CONFIG"
echo
echo "Anvil forks are running:"
echo "  Arbitrum:   http://127.0.0.1:8545 (PID: ${ANVIL_PIDS[0]})"
echo "  Avalanche: http://127.0.0.1:8546 (PID: ${ANVIL_PIDS[1]})"
echo "  Ethereum:  http://127.0.0.1:8547 (PID: ${ANVIL_PIDS[2]})"
echo "  Base:      http://127.0.0.1:8548 (PID: ${ANVIL_PIDS[3]})"
echo "  Optimism:  http://127.0.0.1:8549 (PID: ${ANVIL_PIDS[4]})"
echo "=========================================="
echo
echo "To stop forks:"
echo "  bash script/bash/fork-and-simulate.sh --kill"
echo

if [[ "$SIMULATE" == true ]]; then
  run_simulation
else
  echo "To simulate:"
  echo "  cd cre && cre workflow simulate workflow --target local-fork-settings --non-interactive --trigger-index $TRIGGER_INDEX"
fi

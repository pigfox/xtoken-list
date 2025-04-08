#!/bin/bash
#set -x
set -e

clear
forge clean
#. ./.env

# Trap errors and display the line number
trap 'echo "Error at line $LINENO"; exit 1' ERR

export $(grep -v '^#' .env | xargs)

#contract="MsgSender"
#function="test_run"
contract="Arbitrage"
function="executeArbitrage"

# Ensure required addresses are set
if [ -z "$DEX1" ] || [ -z "$DEX2" ]; then
  echo "Error: DEX1 or DEX2 is not set. Check your environment variables."
  exit 1
fi

echo "Testing $contract::$function..."

#echo test --rpc-url "$SEPOLIA_HTTP_RPC_URL" --gas-report --verbosity --ffi --etherscan-api-key "$ETHERSCAN_API_KEY" --match-contract "$contract" --match-test "$function" -vvvv

#exit;
./empty_dex.sh
forge test --rpc-url "$SEPOLIA_HTTP_RPC_URL" --gas-report --verbosity --ffi --etherscan-api-key "$ETHERSCAN_API_KEY" --match-contract "$contract" -vvvv
#forge test --rpc-url "$SEPOLIA_HTTP_RPC_URL" --gas-report --verbosity --ffi --etherscan-api-key "$ETHERSCAN_API_KEY" --match-contract "$contract" --match-test "$function" -vvvv

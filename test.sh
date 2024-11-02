#!/bin/sh
set -x
set -e
clear
forge clean
. ./.env
#contract="Arbitrage"
#function="executeArbitrage"
contract="Arbitrage"
function="test_executeArbitrage"
rpc_url=$SEPOLIA_HTTP_RPC_URL
echo "Testing $contract::$function..."
forge test --rpc-url "$rpc_url" --gas-report --verbosity --etherscan-api-key "$ETHERSCAN_API_KEY" --match-contract "$contract" --match-test "$function" -vvvv
#forge test --rpc-url "$rpc_url" --gas-report --verbosity --etherscan-api-key "$ETHERSCAN_API_KEY" --match-contract "$contract" -vvvv
#forge test --fork-url "$rpc_url" --etherscan-api-key "$ETHERSCAN_API_KEY" --gas-report --verbosity --match-contract "$contract" --match-test "$function" -vvvv
#forge test --gas-report --verbosity --match-contract "$contract" --match-test "$function" -vvvv



#!/bin/sh
set +x
set +e
clear
forge clean
. ./.env
contract="Arbitrage"
function="swapTokens"
echo "Testing $contract::$function..."
#forge test --rpc-url "$SEPOLIA_RPC_URL" --gas-report --verbosity --match-contract "$contract" --match-test "$function" -vvvv
#forge test --fork-url "$SEPOLIA_RPC_URL" --fork-block-number 1 --etherscan-api-key "$ETHERSCAN_API_KEY" --gas-report --verbosity --match-contract "$contract" --match-test "$function" -vvvv
forge test --gas-report --verbosity --match-contract "$contract" --match-test "$function" -vvvv



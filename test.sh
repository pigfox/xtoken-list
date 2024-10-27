#!/bin/sh
set +x
set +e
clear
. ./.env
contract="Arbitrage"
function="swapTokens"
forge test --rpc-url "$SEPOLIA_RPC_URL" --gas-report --verbosity --match-contract "$contract" --match-test "$function" -vvvv



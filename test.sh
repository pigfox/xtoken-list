#!/bin/sh
set +x
set +e
clear
. ./.env
contract="Pigfox"
function="test_swap"
forge test --rpc-url "$SEPOLIA_RPC_URL" --gas-report --verbosity --match-contract "$contract" --match-test "$function" -vvvv



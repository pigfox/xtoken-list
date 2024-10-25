#!/bin/sh
set +x
set +e
clear
. ./.env
contract="Pigfox"
function="test_./wi swap"
forge test --fork-url http://127.0.0.1:8545 --gas-report --verbosity --match-contract "$contract" --match-test "$function" -vvvv



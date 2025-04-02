#!/bin/sh
set +x
set +e
clear
. ./.env
contract="Arbitrage"
forge flatten src/"$contract".sol --output flattened/"$contract"Flattened.sol

#!/bin/sh
set +x
set +e
clear
. ./.env
contract="Pigfox"
forge flatten src/"$contract".sol --output flattened/"$contract"Flattened.sol

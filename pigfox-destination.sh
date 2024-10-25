#!/bin/sh
set +x
set +e
clear
. ./.env
#forge clean

destination=$BRAVE_WALLET_ADDRESS
rpc_url=$SEPOLIA_RPC_URL
private_key=$PRIVATE_KEY
cast call "$Pigfox" "getDestination()" --rpc-url "$rpc_url"
cast send "$Pigfox" "setDestination(address)" "$destination" --rpc-url "$rpc_url" --private-key "$private_key"
cast call "$Pigfox" "getDestination()" --rpc-url "$rpc_url"
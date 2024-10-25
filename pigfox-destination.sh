#!/bin/sh
set +x
set +e
clear
. ./.env
#forge clean

destiation=$Dex2
rpc_url=$SEPOLIA_RPC_URL
private_key=$PRIVATE_KEY
cast call "$Pigfox" "getDestination()" --rpc-url "$rpc_url"
cast send "$Pigfox" "setDestination(address)" "$destiation" --rpc-url "$rpc_url" --private-key "$private_key"
cast call "$Pigfox" "getDestination()" --rpc-url "$rpc_url"
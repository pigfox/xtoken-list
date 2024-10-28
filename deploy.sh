#!/bin/sh
set +x
set +e
clear
. ./.env
forge clean
rpc_url="$SEPOLIA_RPC_URL"
private_key="$PRIVATE_KEY"
contract="Router"
echo "Deploying $contract..."
forge script script/"$contract".s.sol:"$contract"Script --rpc-url "$rpc_url" --private-key "$private_key" --broadcast --verify --optimize 200
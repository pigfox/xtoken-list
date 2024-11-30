#!/bin/sh
set -x
set -e
clear
. ./.env
forge clean
rpc_url="$SEPOLIA_HTTP_RPC_URL"
private_key="$PRIVATE_KEY"
contract="ProxyImplementation"
echo "Deploying $contract..."
output=$(forge script script/"$contract".s.sol:"$contract"Script --rpc-url "$rpc_url" --private-key "$private_key" --broadcast --verify --optimize 200)
#echo "------------------->Forge Output: $output"
address=$(echo "$output" | grep -oP 'ProxyImplementation deployed at: \K(0x[a-fA-F0-9]{40})')

cast send "$address" "setValue(uint256)" 42 --rpc-url "$rpc_url" --private-key "$private_key"
cast call "$address" "getValue()(uint256)" --rpc-url "$rpc_url"
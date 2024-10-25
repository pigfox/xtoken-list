#!/bin/sh
set +x
set +e
clear
. ./.env
forge clean
echo "Deploying..."
rpc_url="$SEPOLIA_RPC_URL"
private_key="$PRIVATE_KEY"
contract="Vault"
forge script script/"$contract".s.sol:"$contract"Script --rpc-url "$rpc_url" --private-key "$private_key" --broadcast --verify --optimize 200
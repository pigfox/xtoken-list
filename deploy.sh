#!/bin/sh
set +x
set +e
clear
. ./.env
forge clean
echo "Deploying..."
contract="ERC20Token"
forge script script/"$contract".s.sol:"$contract"Script --rpc-url "$SEPOLIA_RPC_URL" --private-key "$PRIVATE_KEY" --broadcast --verify --optimize 200
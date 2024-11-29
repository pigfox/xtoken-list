#!/bin/sh
set -x
set -e
clear
. ./.env
forge clean
rpc_url="$SEPOLIA_HTTP_RPC_URL"
private_key="$PRIVATE_KEY"
contract="Xnft"
echo "Deploying $contract..."
#forge script script/"$contract".s.sol:"$contract"Script --rpc-url "$rpc_url" --private-key "$private_key" --broadcast --verify --optimize 200
address="0xB058655E1b620ad779BB32a968248Ce8D30C09b2"
cast send "$address" "mint(address)" "$WALLET_ADDRESS" --rpc-url "$rpc_url" --private-key "$private_key"
cast call "$address" "ownerOf(uint256)" 0 --rpc-url "$rpc_url"

#!/bin/sh
set -x
set -e
clear
. ./.env
forge clean
supplied_tokens=60000000
approved_tokens=60000000
airdropped_tokens=10000

#https://etherscan.io/inputdatadecoder
echo "Getting token balance $PIGFOX_TOKEN of address $AIRDROP"
cast call "$PIGFOX_TOKEN" "balanceOf(address)" "$AIRDROP" --rpc-url "$SEPOLIA_HTTP_RPC_URL"

echo "Supplying $supplied_tokens token of $PIGFOX_TOKEN to address $AIRDROP"
cast send "$PIGFOX_TOKEN"  "supplyTokenTo(address,uint256)" "$AIRDROP" "$supplied_tokens" --rpc-url "$SEPOLIA_HTTP_RPC_URL" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"

echo "Getting token balance $PIGFOX_TOKEN of address $AIRDROP"
cast call "$PIGFOX_TOKEN" "balanceOf(address)" "$AIRDROP" --rpc-url "$SEPOLIA_HTTP_RPC_URL"

echo "Approving $PIGFOX_TOKEN to spend $approved_tokens tokens at $AIRDROP"
cast call "$PIGFOX_TOKEN" "approve(address,uint256)" "$AIRDROP" "$approved_tokens" --rpc-url "$SEPOLIA_HTTP_RPC_URL" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"

#echo "Getting token allowance $PIGFOX_TOKEN of address $WALLET_ADDRESS to $AIRDROP"
#cast call

echo "Airdropping $airdropped_tokens of $PIGFOX_TOKEN tokens to $WALLET_ADDRESS,$CHROME_WALLET from $AIRDROP"
cast call "$AIRDROP" "airdropTokens(address, address[],uint256)" "$PIGFOX_TOKEN" "[$WALLET_ADDRESS,$CHROME_WALLET]" "$airdropped_tokens" --rpc-url "$SEPOLIA_HTTP_RPC_URL" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY" -- --revert

echo "Getting token balance $PIGFOX_TOKEN of address $CHROME_WALLET"
cast call "$PIGFOX_TOKEN" "balanceOf(address)" "$CHROME_WALLET" --rpc-url "$SEPOLIA_HTTP_RPC_URL"

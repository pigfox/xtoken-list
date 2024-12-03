#!/bin/sh
set -x
set -e
clear
. ./.env
forge clean
supplied_tokens=600000000
approved_tokens=600000000
airdropped_tokens=100000
RPC_URL="$SEPOLIA_HTTP_RPC_URL"

cast send "$PIGFOX_TOKEN" "mint(uint256)" "$supplied_tokens" \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY"

cast send "$PIGFOX_TOKEN" "approveSpender(address,uint256)" "$AIRDROP" "$approved_tokens" \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY"

cast send "$PIGFOX_TOKEN" "transfer(address,uint256)" "$AIRDROP" "$approved_tokens" \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY"

cast send "$AIRDROP" "airdropTokens(address,address[],uint256)" "$PIGFOX_TOKEN" \
    "[$CHROME_WALLET,$WALLET_ADDRESS]" "$airdropped_tokens" \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY"



: << 'EOF'
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
cast call "$AIRDROP" "airdropTokens(address,address[],uint256)" "$PIGFOX_TOKEN" "[$WALLET_ADDRESS,$CHROME_WALLET]" "$airdropped_tokens" --rpc-url "$SEPOLIA_HTTP_RPC_URL" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY" -- --receipt

echo "Getting token balance $PIGFOX_TOKEN of address $CHROME_WALLET"
cast call "$PIGFOX_TOKEN" "balanceOf(address)" "$CHROME_WALLET" --rpc-url "$SEPOLIA_HTTP_RPC_URL"

EOF

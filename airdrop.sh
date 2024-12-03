#!/bin/sh
set -x
set -e
clear
. ./.env
forge clean
supplied_tokens=5000000000000000000000000
approved_tokens=5000000000000000000000000
airdropped_tokens=2000000000000000000000000
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

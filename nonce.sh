#!/bin/sh
set -x
set -e
clear
. ./.env
#get nonce
cast nonce "$PIGFOX_TOKEN" --rpc-url "$SEPOLIA_HTTP_RPC_URL"
#cast nonce "$FIREFOX_WALLET" --rpc-url "$SEPOLIA_HTTP_RPC_URL"
#cast nonce "$FIREFOX_WALLET" --rpc-url "$AVAX_HTTP_RPC_URL"
#set nonce
#cast send <CONTRACT_ADDRESS> "functionName(args)" \
 #    --rpc-url <RPC_URL> \
 #    --private-key <PRIVATE_KEY> \
 #    --nonce <NONCE> \

#cast send 0xAff8e5C19A00Bb6f65c47b787479bF803bF7eAb2 mint(uint256) 1000000000000000000 \
# --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
# --from 0xb04d6a4949fa623629e0ED6bd4Ecb78A8C847693 \
# --private-key zzzzzz \
# --nonce 2445 \
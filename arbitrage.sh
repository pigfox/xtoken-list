#!/bin/sh
set +x
set +e
clear
. ./.env
echo "Running arbitrage simulation"

#ERC20 to mint tokens to dex 1
cast send "$ERC20Token" "supplyToken(address,uint256)" "$Dex1" "7878" --rpc-url "$SEPOLIA_RPC_URL" --private-key "$PRIVATE_KEY"
#Pigfox will get N tokens from dex 1 transfer to dex 2
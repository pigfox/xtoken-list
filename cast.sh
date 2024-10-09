#!/bin/sh
set +x
set +e
clear
. ./.env
echo "Calling contract"
cast call "$Dex1" "getName()(string)" --rpc-url "$SEPOLIA_RPC_URL"  
cast send "$Dex1" "setName(string)" "0000000000" --rpc-url "$SEPOLIA_RPC_URL" --private-key "$PRIVATE_KEY"
cast call "$Dex1" "getName()(string)" --rpc-url "$SEPOLIA_RPC_URL" 
#$ cast send --private-key <Your Private Key> 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc $(cast from-utf8 "hello world") --rpc-url http://127.0.0.1:8545/


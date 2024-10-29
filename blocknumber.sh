#!/bin/sh
set +x
set +e
clear
. ./.env
echo "$SEPOLIA_RPC_URL"
curl -X POST "$SEPOLIA_HTTP_RPC_URL" \
-H "Content-Type: application/json" \
-d '{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}'
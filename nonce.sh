#!/bin/sh
set -x
set -e
clear
. ./.env

cast nonce "$WALLET_ADDRESS" --rpc-url "$SEPOLIA_HTTP_RPC_URL"
cast nonce "$WALLET_ADDRESS" --rpc-url "$AVAX_HTTP_RPC_URL"
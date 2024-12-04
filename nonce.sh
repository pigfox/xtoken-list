#!/bin/sh
set -x
set -e
clear
. ./.env

cast nonce "$FIREFOX_WALLET" --rpc-url "$SEPOLIA_HTTP_RPC_URL"
cast nonce "$FIREFOX_WALLET" --rpc-url "$AVAX_HTTP_RPC_URL"
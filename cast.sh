#!/bin/sh
#set -x
set -e
clear
forge clean
. ./.env
. functions.sh

rpc_url=https://ethereum-sepolia-rpc.publicnode.com

# Example usage
hex_value1=$(cast call "$XToken" "totalSupply()" --rpc-url "$rpc_url")
numerical_value1=$(hex2Int "$hex_value1")
echo "Total Supply1: $numerical_value1"

cast send "$XToken" "mint(uint256)" 100000088840000000000666 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"

hex_value2=$(cast call "$XToken" "totalSupply()" --rpc-url "$rpc_url")
numerical_value2=$(hex2Int "$hex_value2")
echo "Total Supply2: $numerical_value2"

echo "-------------------------------------------------------------------"


: '
This is a
very neat comment
in bash
'
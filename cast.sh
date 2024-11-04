#!/bin/sh
set -x
set -e
clear
forge clean
. ./.env

rpc_url=https://ethereum-sepolia-rpc.publicnode.com

hex2Int() {
    local hex_value="$1"

    # Clean the output by stripping '0x' and any extra whitespace
    hex_value=$(echo "$hex_value" | sed 's/^0x//' | tr -d '\n' | tr -d ' ')

    # Debugging: print hex_value to check its contents
    echo "Debug: hex_value after cleaning is '$hex_value'"

    # Check if the value is not empty and valid for conversion
    if [ -z "$hex_value" ] || ! echo "$hex_value" | grep -qE '^[0-9a-fA-F]+$'; then
        echo "Error: Invalid hexadecimal value" >&2
        return 1
    fi

    # Convert the hex value to decimal using Python
    numerical_value=$(python3 -c "print(int('$hex_value', 16))")

    # Debugging: check the result of Python conversion
    echo "Debug: numerical_value after Python conversion is '$numerical_value'"

    if [ -z "$numerical_value" ]; then
        echo "Error: Failed to convert hexadecimal to decimal" >&2
        return 1
    fi

    # Output the decimal value
    echo "$numerical_value"
}

# Example usage
hex_value1=$(cast call "$XToken" "totalSupply()" --rpc-url "$rpc_url")
numerical_value1=$(hex2Int "$hex_value1")
echo "Total Supply1: $numerical_value1"






#cast send "$XToken" "mint(uint256)" 10000008884000000000000 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"

#hex_value2=$(cast call "$XToken" "totalSupply()" --rpc-url "$rpc_url")
#numerical_value2=$(hex2Int "$hex_value2")
#echo "Total Supply2: $numerical_value2"

echo "-------------------------------------------------------------------"


: '
This is a
very neat comment
in bash
'
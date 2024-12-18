#!/bin/sh
#set -x
set -e
clear
forge clean
. ./.env

hex2Int() {
    local hex_value="$1"

    # Clean the output by stripping '0x' and any extra whitespace
    hex_value=$(echo "$hex_value" | sed 's/^0x//' | tr -d '\n' | tr -d ' ')

    # Debugging: print hex_value to check its contents
    #echo "Debug: hex_value after cleaning is '$hex_value'"

    # Check if the value is not empty and valid for conversion
    if [ -z "$hex_value" ] || ! echo "$hex_value" | grep -qE '^[0-9a-fA-F]+$'; then
        echo "Error: Invalid hexadecimal value" >&2
        return 1
    fi

    # Convert the hex value to decimal using Python
    numerical_value=$(python3 -c "print(int('$hex_value', 16))")

    # Debugging: check the result of Python conversion
    #echo "Debug: numerical_value after Python conversion is '$numerical_value'"

    if [ -z "$numerical_value" ]; then
        echo "Error: Failed to convert hexadecimal to decimal" >&2
        return 1
    fi

    # Trim the result to remove any extra spaces (if any)
    trimmed_value=$(echo "$numerical_value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Output the trimmed decimal value
    echo "$trimmed_value"
}

# Function to check if an address is a valid Ethereum address
is_valid_address() {
    if [[ "$1" =~ ^0x[a-fA-F0-9]{40}$ ]]; then
        return 0  # Valid address
    else
        return 1  # Invalid address
    fi
}

# Function to check if a value is greater than zero
is_greater_than_zero() {
  if [[ $(echo "$1 > 0" | bc) -eq 1 ]]; then
    return 0  # Greater than zero
  else
    return 1  # Not greater than zero
  fi
}

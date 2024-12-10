#!/bin/sh
set -x
set -e
clear
. ./.env
echo "Empty DEX"

# Fetch the balance (in base units, e.g., wei or smallest unit)
BALANCE_RAW=$(cast call "$PIGFOX_TOKEN" "balanceOf(address)(uint256)" "$DEX1" --rpc-url "$SEPOLIA_PUBLIC_NODE")

# Remove the '0x' prefix from the hexadecimal balance and clean any annotations
BALANCE_RAW_DECIMAL=$(echo "$BALANCE_RAW" | sed 's/^0x//')
BALANCE_RAW_DECIMAL_CLEAN=$(echo "$BALANCE_RAW_DECIMAL" | sed 's/\[.*\]//g' | sed 's/[[:space:]]//g')

# Ensure the cleaned value is valid hexadecimal
if ! echo "$BALANCE_RAW_DECIMAL_CLEAN" | grep -q '^[0-9a-fA-F]*$'; then
  echo "Error: Invalid hexadecimal balance"
  exit 1
fi

# Convert the raw balance from hex to decimal using `bc`
BALANCE_DECIMAL=$(echo "ibase=16; $BALANCE_RAW_DECIMAL_CLEAN" | bc)

# Assuming the token has 18 decimals (standard ERC20 token decimals)
DECIMALS=18

# Convert the raw balance to decimal (human-readable format) by dividing by 10^18
# For base units, we just need to use the integer portion
BALANCE_BASE_UNIT=$(echo "$BALANCE_DECIMAL * 10^$DECIMALS" | bc)

# Output the decimal balance and base unit balance
echo "Balance in decimals: $BALANCE_DECIMAL"
echo "Balance in base units: $BALANCE_BASE_UNIT"

# Send the transaction using the balance in base units (ensure it's an integer)
cast send "$PIGFOX_TOKEN" \
  "transfer(address,uint256)" \
  "$TRASH_CAN" \
  "$BALANCE_RAW_DECIMAL_CLEAN" \
  --rpc-url "$SEPOLIA_PUBLIC_NODE" \
  --private-key "$PRIVATE_KEY"

#!/bin/sh
set -x
set -e
clear
forge clean
. ./.env

#contract="MsgSender"
#function="test_run"
contract="Arbitrage"
function="executeArbitrage"

rpc_url=https://ethereum-sepolia-rpc.publicnode.com
echo "Testing $contract::$function..."
#cast send "$PIGFOX_TOKEN" "approve(address,uint256)" "$DEX1" 100 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
#exit
#cast call "$PIGFOX_TOKEN" "getTokenBalanceAt(address)" "$DEX1" --rpc-url "$rpc_url"
#cast send "$PIGFOX_TOKEN" "supplyTokenTo(address,uint256)" "$DEX1" 1000000000000000000 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY" --json
#cast call "$PIGFOX_TOKEN" --rpc-url "$rpc_url"
#cast send "$PIGFOX_TOKEN" "mint(uint256)" 1000000000000000000 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY" --nonce 2445
#cast call "$PIGFOX_TOKEN" "totalSupply()" --rpc-url "$rpc_url"
#cast send "$PIGFOX_TOKEN" "mint(uint256)" 1000000000000000000 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
#cast call "$PIGFOX_TOKEN" "totalSupply()" --rpc-url "$rpc_url"
#cast send "$PIGFOX_TOKEN" "mint(uint256)" 1000000000000000000 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
#cast send "$PIGFOX_TOKEN" "supplyTokenTo(address)(uint256)" "$Arbitrage" 1000000000000000000 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
#cast send "$PIGFOX_TOKEN" "approve(address,uint256)" "$Dex1" 1000000000000000000 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
#-----------
#cast send "$Dex1" "withdrawTokens(address,address,uint256)" "$PIGFOX_TOKEN" "$TrashCan" 100000 --json --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
#cast send "$Dex1" "withdrawTokens(address,address,uint256)" "$PIGFOX_TOKEN" "$TrashCan" 28000000000000000000 --json --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
#cast call "$Dex1" "getTokenBalanceOf(address)" "$PIGFOX_TOKEN" --rpc-url "$rpc_url"
#setTokenPrice(address _token, uint256 _balance)
#depositTokens(address token, uint256 amount)
#---set------------------------------------------------------------------------
: <<'EOF'
# 1. Mint tokens to the WALLET_ADDRESS (which is also the owner of the contract)
cast send "$PIGFOX_TOKEN" "mint(uint256)" 1000000000000000000 \
  --rpc-url "$rpc_url" \
  --from "$WALLET_ADDRESS" \
  --private-key "$PRIVATE_KEY"

# 2. Approve DEX1 to spend up to 1 token (1e18) on behalf of WALLET_ADDRESS
cast send "$PIGFOX_TOKEN" "approveSpender(address,uint256)" "$DEX1" 1000000000000000000 \
  --rpc-url "$rpc_url" \
  --from "$WALLET_ADDRESS" \
  --private-key "$PRIVATE_KEY"

# 3. Confirm the allowance for DEX1
cast call "$PIGFOX_TOKEN" "allowance(address,address)" "$WALLET_ADDRESS" "$DEX1" \
  --rpc-url "$rpc_url"

# 4. Supply tokens directly to DEX1 (mint to DEX1) if needed
cast send "$PIGFOX_TOKEN" "supplyTokenTo(address,uint256)" "$DEX1" 1000000000000000000 \
  --rpc-url "$rpc_url" \
  --from "$WALLET_ADDRESS" \
  --private-key "$PRIVATE_KEY"

# 5. Confirm the token balance at DEX1
cast call "$PIGFOX_TOKEN" "getTokenBalanceAt(address)" "$DEX1" \
  --rpc-url "$rpc_url"

# 6. Approve DEX2 to spend up to 1 token (1e18) on behalf of WALLET_ADDRESS
cast send "$PIGFOX_TOKEN" "approveSpender(address,uint256)" "$DEX2" 1000000000000000000 \
  --rpc-url "$rpc_url" \
  --from "$WALLET_ADDRESS" \
  --private-key "$PRIVATE_KEY"

# 7. Confirm the allowance for DEX2
cast call "$PIGFOX_TOKEN" "allowance(address,address)" "$WALLET_ADDRESS" "$DEX2" \
  --rpc-url "$rpc_url"

# 8. Supply tokens directly to DEX2 (mint to DEX2) if needed
cast send "$PIGFOX_TOKEN" "supplyTokenTo(address,uint256)" "$DEX2" 1000000000000000000 \
  --rpc-url "$rpc_url" \
  --from "$WALLET_ADDRESS" \
  --private-key "$PRIVATE_KEY"

# 9. Confirm the token balance at DEX2
cast call "$PIGFOX_TOKEN" "getTokenBalanceAt(address)" "$DEX2" \
  --rpc-url "$rpc_url"


#-------------------------------NOT Implemented below---------------------------
# 10. Execute arbitrage on the ARBITRAGE contract with tokens from DEX1 and DEX2
cast send "$ARBITRAGE" "executeArbitrage(address,address,uint256)" "$DEX1" "$DEX2" 1000000000000000000 \
  --rpc-url "$rpc_url" \
  --from "$WALLET_ADDRESS" \
  --private-key "$PRIVATE_KEY"

# 11. Confirm the arbitrage result from the ARBITRAGE contract
cast call "$ARBITRAGE" "getArbitrageResult()" \
  --rpc-url "$rpc_url"
EOF
: <<'EOF'
# 1. Mint tokens to the WALLET_ADDRESS (which is also the owner of the contract)
cast send "$PIGFOX_TOKEN" "mint(uint256)" 1000000000000000000 \
  --rpc-url "$rpc_url" \
  --from "$WALLET_ADDRESS" \
  --private-key "$PRIVATE_KEY"

# 2. Approve DEX1 to spend up to 1 token (1e18) on behalf of WALLET_ADDRESS
cast send "$PIGFOX_TOKEN" "approveSpender(address,uint256)" "$DEX1" 1000000000000000000 \
  --rpc-url "$rpc_url" \
  --from "$WALLET_ADDRESS" \
  --private-key "$PRIVATE_KEY"

# 3. Confirm the allowance for DEX1
cast call "$PIGFOX_TOKEN" "allowance(address,address)" "$WALLET_ADDRESS" "$DEX1" \
  --rpc-url "$rpc_url"

# 4. Supply tokens directly to DEX1 (mint to DEX1) if needed
cast send "$PIGFOX_TOKEN" "supplyTokenTo(address,uint256)" "$DEX1" 1000000000000000000 \
  --rpc-url "$rpc_url" \
  --from "$WALLET_ADDRESS" \
  --private-key "$PRIVATE_KEY"

# 5. Confirm the token balance at DEX1
cast call "$PIGFOX_TOKEN" "getTokenBalanceAt(address)" "$DEX1" \
  --rpc-url "$rpc_url"

EOF
#---set------------------------------------------------------------------------
#cast send "$PIGFOX_TOKEN" "supplyTokenTo(address,uint256)" "$SingleTokenDex1" 1000000000000000000 --json --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
#cast call "$PIGFOX_TOKEN" "balanceOf(address)" "$SingleTokenDex1" --rpc-url "$rpc_url"
#cast call "$SingleTokenDex1" "getReserve(address)" "$PIGFOX_TOKEN" --rpc-url "$rpc_url"
#cast call "$SingleTokenDex1" "getPrice(address)" "$PIGFOX_TOKEN" --rpc-url "$rpc_url"
#cast balance "$WALLET_ADDRESS" --rpc-url "$rpc_url"
#cast send "$PIGFOX_TOKEN" "supplyTokenTo(address,uint256)" "$Arbitrage" 1000000000000000000 --json --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
#cast call "$PIGFOX_TOKEN" "balanceOf(address)" "$WALLET_ADDRESS" --rpc-url "$rpc_url"
#cast send "$PIGFOX_TOKEN" "mint(uint256)" 100000088840000000000667 --json --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
#-----------
./empty_dex.sh
forge test --rpc-url "$rpc_url" --gas-report --verbosity --ffi --etherscan-api-key "$ETHERSCAN_API_KEY" --match-contract "$contract" --match-test "$function" -vvvv


#forge test --rpc-url "$rpc_url" --gas-report --verbosity --etherscan-api-key "$ETHERSCAN_API_KEY" --match-contract "$contract" --match-test "$function" -vvvv
#forge test --rpc-url "$rpc_url" --gas-report --verbosity --etherscan-api-key "$ETHERSCAN_API_KEY" --match-contract "$contract" -vvvv
#forge test --fork-url "http://127.0.0.1:8545" --etherscan-api-key "$ETHERSCAN_API_KEY" --gas-report --verbosity --match-contract "$contract" --match-test "$function" -vvvv
#forge test --gas-report --verbosity --match-contract "$contract" --match-test "$function" -vvvv


: '
You can refer to the Foundry docs regarding the usage of verbosity level, that says:

   2: Print logs for all tests
   3: Print execution traces for failing tests
   4: Print execution traces for all tests, and setup traces for failing tests
   5: Print execution and setup traces for all tests

    -v, --verbose
        Increase verbosity level. Can be used multiple times for increased verbosity.
    -q, --quiet
        Decrease verbosity level. Can be used multiple times for decreased verbosity.
    -vvvv
        Set verbosity level to maximum.
    -vvv
        Set verbosity level to high.
    -vv
        Set verbosity level to medium.
    -v
        Set verbosity level to low.
    -q
        Set verbosity level to quiet.
    -qq
        Set verbosity level to silent.
   Verbosity levels:

    -
'
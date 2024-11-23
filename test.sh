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
#cast call "$XToken" --rpc-url "$rpc_url"
#cast send "$XToken" "mint(uint256)(uint256)" 1000000000000000000 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
#cast call "$XToken" "totalSupply()" --rpc-url "$rpc_url"
#cast send "$XToken" "mint(uint256)" 1000000000000000000 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
#cast call "$XToken" "totalSupply()" --rpc-url "$rpc_url"
#cast send "$XToken" "mint(uint256)" 1000000000000000000 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
#cast send "$XToken" "supplyTokenTo(address)(uint256)" "$Arbitrage" 1000000000000000000 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
#cast send "$XToken" "approve(address,uint256)" "$Router1" 1000000000000000000 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
#-----------
#cast call "$Dex1" "getTokenBalanceOf(address)" "$XToken" --rpc-url "$rpc_url"
#setTokenPrice(address _token, uint256 _balance)
#depositTokens(address token, uint256 amount)
cast send "$Dex1" "depositTokens(address,uint256)" "$XToken" 1000000000000000000 --json --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
#cast send "$XToken" "supplyTokenTo(address,uint256)" "$SingleTokenDex1" 1000000000000000000 --json --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
#cast call "$XToken" "balanceOf(address)" "$SingleTokenDex1" --rpc-url "$rpc_url"
#cast call "$SingleTokenDex1" "getReserve(address)" "$XToken" --rpc-url "$rpc_url"
#cast call "$SingleTokenDex1" "getPrice(address)" "$XToken" --rpc-url "$rpc_url"
#cast balance "$WALLET_ADDRESS" --rpc-url "$rpc_url"
#cast send "$XToken" "supplyTokenTo(address,uint256)" "$Arbitrage" 1000000000000000000 --json --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
#cast call "$XToken" "balanceOf(address)" "$WALLET_ADDRESS" --rpc-url "$rpc_url"
#cast send "$XToken" "mint(uint256)" 100000088840000000000667 --json --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
#-----------
#forge test --rpc-url "$rpc_url" --gas-report --verbosity --ffi --etherscan-api-key "$ETHERSCAN_API_KEY" --match-contract "$contract" --match-test "$function" -vvvv
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
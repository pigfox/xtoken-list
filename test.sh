#!/bin/sh
set -x
set -e
clear
forge clean
. ./.env
#contract="Arbitrage"
#function="executeArbitrage"
contract="Arbitrage"
function="test_executeArbitrage"
rpc_url=https://ethereum-sepolia-rpc.publicnode.com
echo "Testing $contract::$function..."
#cast call "$XToken" --rpc-url "$rpc_url"
#cast send 0x7D6983bFB1625636b0e38Ae178a7315FaDe11295 "mint(uint256)(uint256)" 1000000000000000000 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
cast call "$XToken" "totalSupply()" --rpc-url "$rpc_url"
cast send "$XToken" "mint(uint256)" 1000000000000000000 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
cast call "$XToken" "totalSupply()" --rpc-url "$rpc_url"
#cast call 0xe34Ac9E64fb1db3b3bb30988462014Cb525de040 "getBalance()" --rpc-url https://ethereum-sepolia-rpc.publicnode.com
#cast send "$XToken" "mint(uint256)" 1000000000000000000 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"
#cast send "$XToken" "supplyTokenTo(address)(uint256)" "$Arbitrage" 1000000000000000000 --rpc-url "$rpc_url" --from "$WALLET_ADDRESS" --private-key "$PRIVATE_KEY"


#forge test --rpc-url "$rpc_url" --gas-report --verbosity --etherscan-api-key "$ETHERSCAN_API_KEY" --match-contract "$contract" --match-test "$function" -vvvv
#forge test --rpc-url "$rpc_url" --gas-report --verbosity --etherscan-api-key "$ETHERSCAN_API_KEY" --match-contract "$contract" -vvvv
#forge test --fork-url "http://127.0.0.1:8545" --etherscan-api-key "$ETHERSCAN_API_KEY" --gas-report --verbosity --match-contract "$contract" --match-test "$function" -vvvv
#forge test --gas-report --verbosity --match-contract "$contract" --match-test "$function" -vvvv



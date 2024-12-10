#!/bin/sh
#https://ethereum.stackexchange.com/questions/166984/attempting-to-create-a-proxy
set -x
set -e
clear
. ./.env
rpc_url="$SEPOLIA_HTTP_RPC_URL"
private_key="$PRIVATE_KEY"
wallet_address="$WALLET_ADDRESS"
zeppelin_proxy="$ZEPPELIN_PROXY"
zeppelin_impl_v2="$ZEPPELIN_IMPL_V2"
zeppelin_impl_v1="$ZEPPELIN_IMPL_V1"
actual_proxy="$ACTUAL_PROXY"

: <<'EOF'
First of all, your contract ZeppelinProxy deployed at 0x6956Cd3c767ffFCFe1077164aE204789DCE09C6B is not the TransparentUpgradeableProxy contract, instead it's the deployer of your TransparentUpgradeableProxy contract.
Your deployed TransparentUpgradeableProxy contract is 0x60Da46a609f92DA1aDE987e49abbEf25cBfB2C8E.
So, the correct command should be:
EOF

#cast send "$actual_proxy" "setValue(uint256)" 5000 --rpc-url "$rpc_url" --private-key "$private_key"

: <<'EOF'
NOTE: The value remains unchanged in the implementation contract because it doesn't use its own storage.
All storage operations are performed on the proxy.
This is by design and ensures the implementation contract can be replaced without losing or modifying state stored in the proxy.
You can check the same by fetching the value from the TransparentUpgradeableProxy contrac
EOF

#cast call "$actual_proxy" "value()" --rpc-url "$rpc_url" --json

contract="ZeppelinTest"
#function="testProxyFunctionality"
function="testAll"
forge test --rpc-url "$rpc_url" --gas-report --verbosity --ffi --etherscan-api-key "$ETHERSCAN_API_KEY" --match-contract "$contract" --match-test "$function" -vvvv

: <<'EOF'
Let me know if you face any difficulty in upgrading.
You just have to grab the address of the deployed ProxyAdmin contract from the AdminChanged event that
you can listen to at the time of deployment of Transparent Upgradable Proxy, that I did using vm.recordLogs function.
It’s the last log, therefore I accessed it using length-1 index.
Later on, the same address can be used to instantiate the ProxyAdmin contract and calling the upgradeAndCall function.

It’s not upgraded, because you haven’t called the upgradeAndCall function.
You can refer to this test function to see how you can call that on the ProxyAdmin contract.
EOF
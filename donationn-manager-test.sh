#!/bin/sh
set -x
set -e
clear
forge clean
. ./.env

#1
#a) Check the current owner
cast call $DONATION_MANAGER "owner()(address)" --rpc-url $RPC_URL

#b) Update the owner to $WALLET_ADDRESS (only callable by the current owner)
cast send $DONATION_MANAGER "updateOwner(address)" $WALLET_ADDRESS --from $WALLET_ADDRESS --rpc-url $RPC_URL --private-key $PRIVATE_KEY

#2 Reentrancy Attack Simulation
#a)  Deploy the malicious contract (replace MALICIOUS_CONTRACT with its address):
cast send $MALICIOUS_CONTRACT "attack(address)" $DONATION_MANAGER --from $WALLET_ADDRESS --rpc-url $RPC_URL --private-key $PRIVATE_KEY

#b) Verify the contract state to ensure reentrancy was prevented:
cast call $DONATION_MANAGER "getTotalDonatedValue()(uint256)" --rpc-url $RPC_URL

# 3. Deposit ETH
#a) Make a donation of 1 ETH
cast send $DONATION_MANAGER --value 1ether --from $WALLET_ADDRESS --rpc-url $RPC_URL --private-key $PRIVATE_KEY

#b) Confirm the donation
cast call $DONATION_MANAGER "getTotalDonatedValue()(uint256)" --rpc-url $RPC_URL


#c) Retrieve donation details by index
cast call $DONATION_MANAGER "getDonation(uint256)(address,uint256,uint256)" 0 --rpc-url $RPC_URL

#4 4. Withdrawal
#a) Send donations to $FIREFOX_WALLET (e.g., 0.5 ETH)
cast send $DONATION_MANAGER "sendDonations(address,uint256)" $FIREFOX_WALLET 500000000000000000 --from $WALLET_ADDRESS --rpc-url $RPC_URL --private-key $PRIVATE_KEY

#b) Verify the contract's balance after withdrawal
cast call $DONATION_MANAGER "getTotalDonatedValue()(uint256)" --rpc-url $RPC_URL


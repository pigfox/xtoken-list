// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Stake {
    IERC20 public token;
    uint256 public rewardRate;
    uint256 public totalStaked;

    struct Staker {
        uint256 amount;
        uint256 rewardDebt;
    }

    mapping(address => Staker) public stakers;

    constructor(address _tokenAddress, uint256 _rewardRate) {
        token = IERC20(_tokenAddress);
        rewardRate = _rewardRate;
    }

    function stake(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than zero");
        token.transferFrom(msg.sender, address(this), _amount);

        Staker storage staker = stakers[msg.sender];
        if (staker.amount == 0) {
            staker.rewardDebt = totalStaked * rewardRate / 1e18;
        }

        totalStaked += _amount;
        staker.amount += _amount;
    }

    function withdraw(uint256 _amount) external {
        Staker storage staker = stakers[msg.sender];
        require(_amount > 0, "Withdraw amount must be greater than zero");
        require(staker.amount >= _amount, "Insufficient staked amount");

        // Update staker's state
        staker.amount -= _amount;
        totalStaked -= _amount;

        // Transfer tokens back to the staker
        require(token.transfer(msg.sender, _amount), "Withdraw transfer failed");
    }

    function claimReward() external {
        Staker storage staker = stakers[msg.sender];
        require(staker.amount > 0, "No staked tokens to claim rewards");
        require(totalStaked > 0, "No tokens are staked");

        // Safe calculation of the accumulated reward
        uint256 accumulatedReward = (staker.amount * rewardRate) / 1e18;

        // Ensure accumulatedReward is greater than or equal to rewardDebt
        require(accumulatedReward >= staker.rewardDebt, "Invalid reward calculation");

        // Calculate the reward
        uint256 reward = accumulatedReward - staker.rewardDebt;

        // Ensure the reward is positive
        require(reward > 0, "No reward available to claim");

        // Update rewardDebt to the latest value
        staker.rewardDebt = accumulatedReward;

        // Transfer the reward to the staker
        require(token.transfer(msg.sender, reward), "Reward transfer failed");
    }

}

/*
1. Define Reward Rate Context
In your contract, rewardRate is likely the rate of reward tokens distributed per second or block.
Typically, it's expressed in terms of the fraction of total staked tokens or a fixed number of reward tokens.
2. Factors to Consider
Desired APY:
Calculate the annual percentage yield you want to provide. For example, if you want to offer 10% APY:
RewardRate (per second)
=
Total Staked
×
0.10
365
×
24
×
60
×
60
RewardRate (per second)=
365×24×60×60
Total Staked×0.10
​

Token Supply:
If your reward token supply is limited, ensure the rewardRate aligns with the project's longevity. For instance, if you plan to distribute rewards over 2 years:
RewardRate (per second)
=
Total Rewards
2
×
365
×
24
×
60
×
60
RewardRate (per second)=
2×365×24×60×60
Total Rewards
​

Block Interval Rewards:
If you base rewards on blocks, consider the average block time. For Ethereum, it’s roughly 12 seconds:
RewardRate (per block)
=
Total Rewards Per Second
×
12
RewardRate (per block)=Total Rewards Per Second×12
3. Example Scenarios
Fixed APY of 10%:
Suppose 1,000,000 tokens are staked, and you target a 10% APY:
RewardRate (per second)
=
1
,
000
,
000
×
0.10
365
×
24
×
60
×
60
≈
3.17
 
tokens/second
RewardRate (per second)=
365×24×60×60
1,000,000×0.10
​
 ≈3.17tokens/second
Fixed Total Rewards:
If you allocate 500,000 tokens for rewards over 1 year:
RewardRate (per second)
=
500
,
000
365
×
24
×
60
×
60
≈
15.85
 
tokens/second
RewardRate (per second)=
365×24×60×60
500,000
​
 ≈15.85tokens/second
4. Practical Values
Small Staking Pools: For smaller projects, rewardRate could be 1-10 tokens per second or block.
Larger Projects: For larger projects with higher staking totals, values between 0.01 and 1 token per second/block are typical.
5. Adjust for Sustainability
Ensure that rewardRate doesn’t deplete the reward pool prematurely.
Use dynamic reward rates that adjust based on staking activity, for instance:
RewardRate
=
Max Daily Rewards
Total Staked
RewardRate=
Total Staked
Max Daily Rewards
​

Let me know your project specifics, and I can suggest a tailored rate!
*/
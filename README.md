# Staking and Voting System

A decentralized staking and voting system with NFT token representations of vote results, built with Solidity and Foundry.

## Features

- **Token Staking**: Users can stake tokens for different time periods
- **Weighted Voting**: Voting power is calculated based on stake amount and duration
- **NFT Vote Records**: Each completed vote is minted as an NFT with detailed metadata
- **Threshold-Based Consensus**: Votes require minimum participation thresholds

## Contract Structure

1. **StakingContract**: Handles token staking functionality

   - Allows users to create multiple stakes with different durations
   - Manages stake withdrawals when they mature

2. **VoteContract**: Implements voting logic based on staking power

   - Voting power increases with stake amount and lock duration
   - Implements threshold requirements for vote completion
   - Votes can result in Yes, No, or Failed outcomes

3. **VoteTokenContract**: Creates NFTs representing completed votes
   - Mints an NFT when a vote is completed
   - NFT metadata includes vote details and voter participation

## Development Setup

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Git](https://git-scm.com/downloads)

### Installation

```bash
git clone https://github.com/your-username/staking-voting-system.git
cd staking-voting-system

# Install dependencies
forge install

# Build the project
forge build

# Run tests
forge test
```

## Deployment

The project is deployed on Sepolia testnet.

### Contract Addresses (Sepolia)

- TestToken: `0x5E9fD7Ba825C94E1f2bc55B38c1a3F57fEfE5E85`
- VoteTokenContract: `0x4d5DF6A7A95A84A1208cB51Cb9D878Dbf2F51c4A`

### How to Deploy

1. Set up environment variables:

   Create a `.env` file with:

   ```
   PRIVATE_KEY=your_private_key
   SEPOLIA_RPC_URL=your_sepolia_rpc_url
   VOTE_TOKEN_ADDRESS=your_vote_token_address //If not specified, an ERC20 test token will be created.
   ETHERSCAN_API_KEY=your_etherscan_api_key
   ```

2. Load the environment variables:

   ```bash
   source .env
   ```

3. Deploy:
   ```bash
   forge script script/Deploy.s.sol:DeployScript --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
   ```

## Usage

### Staking Tokens

```solidity
// Approve tokens first
IERC20(tokenAddress).approve(stakingContractAddress, amountToStake);

// Stake tokens for a period (in seconds)
StakingContract(stakingContractAddress).stake(amountToStake, stakingPeriod);
```

### Creating a Vote

```solidity
// Only contract owner can create votes
VoteContract(voteContractAddress).initiateVote("Should we implement feature X?", 60, block.timestamp + 7 days);
```

### Casting a Vote

```solidity
// Vote on proposal with ID 0 (true = Yes, false = No)
VoteContract(voteContractAddress).vote(0, true);
```

### Completing a Vote and Minting NFT

```solidity
// Complete vote with ID 0
VoteTokenContract(voteTokenContractAddress).finishVote(0);
```

### tokenURI

The voting information is transmitted directly to the url in the form of json:

```json
{
  "name": "Vote #0",
  "description": "Test NFT Minting on Vote Finish",
  "attributes": [
    {
      "trait_type": "Deadline",
      "value": "86401"
    },
    {
      "trait_type": "Threshold",
      "value": "50"
    },
    {
      "trait_type": "Total Votes",
      "value": "3"
    },
    {
      "trait_type": "Yes Votes",
      "value": "36951572736003000000000000000000000" //Voting power Yes
    },
    {
      "trait_type": "No Votes",
      "value": "26873866368001000000000000000000000" //Voting power No
    },
    {
      "trait_type": "Decision",
      "value": "Yes"
    }
  ],
  "voters": [
    {
      "address": "0x0000000000000000000000000000000000000002",
      "vote": "Yes"
    },
    {
      "address": "0x0000000000000000000000000000000000000003",
      "vote": "No"
    },
    {
      "address": "0x0000000000000000000000000000000000000004",
      "vote": "Yes"
    }
  ]
}
```

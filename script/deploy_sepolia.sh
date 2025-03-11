#!/bin/bash

# This script helps with deploying the contracts to Sepolia testnet
# Make sure to run chmod +x deploy_sepolia.sh to make it executable

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found. Please create it with PRIVATE_KEY, SEPOLIA_RPC_URL, and ETHERSCAN_API_KEY."
    exit 1
fi

# Check if required environment variables are set
if [ -z "$PRIVATE_KEY" ] || [ -z "$SEPOLIA_RPC_URL" ] || [ -z "$ETHERSCAN_API_KEY" ]; then
    echo "Error: One or more required environment variables are not set."
    echo "Please ensure PRIVATE_KEY, SEPOLIA_RPC_URL, and ETHERSCAN_API_KEY are set in your .env file."
    exit 1
fi

# Build the project
echo "Building the project..."
forge build

# Deploy to Sepolia testnet
echo "Deploying to Sepolia testnet..."
forge script script/Deploy.s.sol:DeployScript \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    -vvvv

echo "Deployment completed! Check the output above for contract addresses."
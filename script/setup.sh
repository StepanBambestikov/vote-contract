#!/bin/bash

# This script helps with initializing the project and installing dependencies
# Make sure to run chmod +x setup.sh to make it executable

echo "Setting up the project..."

# Check if Foundry is installed
if ! command -v forge &> /dev/null; then
    echo "Foundry not found. Installing Foundry..."
    curl -L https://foundry.paradigm.xyz | bash
    source ~/.bashrc
    foundryup
else
    echo "Foundry already installed. Updating to the latest version..."
    foundryup
fi

# Create .env file template if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file template..."
    cat > .env << EOF
# Private key for deployment (DO NOT SHARE)
PRIVATE_KEY=

# RPC URL for Sepolia testnet
SEPOLIA_RPC_URL=

# Etherscan API key for verification
ETHERSCAN_API_KEY=
EOF
    echo ".env template created! Please fill in your private key, RPC URL, and Etherscan API key."
fi

# Install dependencies
echo "Installing dependencies..."
forge install OpenZeppelin/openzeppelin-contracts

# Make deploy script executable
chmod +x deploy_sepolia.sh

echo "Setup completed successfully!"
echo "To deploy to Sepolia testnet, fill in your .env file and then run: ./deploy_sepolia.sh"
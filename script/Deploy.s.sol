// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/StdUtils.sol";
import "forge-std/console.sol";
import "../src/vote_token_contract.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// This token is for testing purposes
// In a production environment, you would use an existing token
contract TestToken is ERC20 {
    constructor() ERC20("Test Voting Token", "TVT") {
        _mint(msg.sender, 1000000 * 10**18); // Mint 1M tokens to the deployer
    }
}

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address tokenAddress;
        
        // Check if token address is already specified
        string memory existingTokenAddress = vm.envOr("VOTE_TOKEN_ADDRESS", string(""));
        bool hasExistingToken = bytes(existingTokenAddress).length > 0;
        
        vm.startBroadcast(deployerPrivateKey);
        
        // If token address is not specified, deploy a new one
        if (!hasExistingToken) {
            TestToken token = new TestToken();
            tokenAddress = address(token);
            console.log("New TestToken deployed at:", tokenAddress);
            console.log("Update your VOTE_TOKEN_ADDRESS environment variable with:", vm.toString(tokenAddress));
        } else {
            // Otherwise use the existing token
            tokenAddress = vm.parseAddress(existingTokenAddress);
            console.log("Using existing token at address:", tokenAddress);
        }
        
        // Deploy the voting contract with the specified token
        VoteTokenContract voteTokenContract = new VoteTokenContract(IERC20(tokenAddress));
        console.log("VoteTokenContract deployed at:", address(voteTokenContract));
        
        vm.stopBroadcast();
    }
}
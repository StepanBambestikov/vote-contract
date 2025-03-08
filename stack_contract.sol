// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract StakingContract is ReentrancyGuard, Ownable {

    uint256 private constant SECONDS_PER_YEAR = 365 days;
    uint256 private constant MAX_STAKING_PERIOD = 4 * SECONDS_PER_YEAR; 

    IERC20 public stakingToken;

    uint256 public totalStaked;

    
    mapping(address => Stake[]) internal userStaking;

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet internal users;
    
    struct Stake {
        uint256 stakedAmount;    
        uint256 withdrawDate;     
    }
    
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    
    
    constructor(IERC20 _stakingToken) Ownable(msg.sender) {
        stakingToken = _stakingToken;
    }
    
    function stake(uint256 amount, uint256 period) external nonReentrant {
        require(
            period > 0 && period <= MAX_STAKING_PERIOD, 
            "Staking period cannot exceed 4 years and must be greater than 0"
        );
        require(
            amount > 0, 
            "Amount must be greater than 0"
        );
        Stake memory newStake = Stake(amount, block.timestamp + period);
        userStaking[msg.sender].push(newStake);
        if (userStaking[msg.sender].length == 1){
            users.add(msg.sender);
        }

        bool success = stakingToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");
        totalStaked += amount;
        emit Staked(msg.sender, amount);
    }

    function withdraw() external nonReentrant {
        Stake[] memory userStack = userStaking[msg.sender];

        uint256 unstackAmount = 0;

        bool useHasActiveStack;
        for (uint i = 0; i < userStack.length; i++) {
            if (userStack[i].withdrawDate <= block.timestamp && userStack[i].stakedAmount > 0){
                unstackAmount += userStack[i].stakedAmount;
                userStaking[msg.sender][i] = Stake(0, 0);
            }
            if (!(userStack[i].withdrawDate <= block.timestamp) && userStack[i].stakedAmount > 0){
                useHasActiveStack = true;
            }
        }
        if (!useHasActiveStack){
            users.remove(msg.sender);
        }

        require(unstackAmount > 0, "No unstack amount");
        
        userStaking[msg.sender] = userStack;
        bool success = stakingToken.transfer(msg.sender, unstackAmount);
        require(success, "Transfer failed");

        totalStaked -= unstackAmount;
        
        emit Withdrawn(msg.sender, unstackAmount);
    }

    function getUserStake(address user) internal view returns(Stake[] memory) {
        return userStaking[user];
    }

    function getStake() public view returns(Stake[] memory) {
        return userStaking[msg.sender];
    }

    function getTotalStake() public view returns(uint256) {
        return totalStaked;
    }

}
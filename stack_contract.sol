// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract StakingContract is ReentrancyGuard, Ownable {

    IERC20 public stakingToken;

    uint256 public totalStaked;
    
    mapping(address => Stake[]) public userStaking;
    
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
        // require(
        //     userStaking[msg.sender].stakedAmount == 0 && userStaking[msg.sender].withdrawDate == 0,
        //     "user already has stacking"
        // );

        Stake memory newStack = Stake(amount, block.timestamp + period);
        
        // userStaking[msg.sender].stakedAmount = amount;
        // userStaking[msg.sender].withdrawDate = block.timestamp + period;

        userStaking[msg.sender].push(newStack);
        
        bool success = stakingToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");

        totalStaked += amount;
        
        emit Staked(msg.sender, amount);
    }

    function getStake() public view returns(Stake[] memory) {
        return userStaking[msg.sender];
    }

    function getTotalStake() public view returns(uint256) {
        return totalStaked;
    }
    
    function withdraw() external nonReentrant {
        Stake[] memory userStack = userStaking[msg.sender];
        //require(userStack.stakedAmount > 0, "Cannot withdraw 0");
        //require(userStack.withdrawDate <= block.timestamp, "Too early withdraw!");

        uint256 unstackAmount = 0;

        for (uint i = 0; i < userStack.length; i++) {
            if (userStack[i].withdrawDate > 0 && userStack[i].stakedAmount > 0){
                unstackAmount += userStack[i].stakedAmount;
                userStaking[msg.sender][i] = Stake(0, 0);
            }
        }
        
        bool success = stakingToken.transfer(msg.sender, unstackAmount);
        require(success, "Transfer failed");

        totalStaked -= unstackAmount;
        
        emit Withdrawn(msg.sender, unstackAmount);
    }

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "stack_contract.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor() ERC20("Mock Token", "MOCK") {
        _mint(msg.sender, 1000000 * 10**18);
    }
}

contract StakingContractTest is Test {
    StakingContract public stakingContract;
    MockToken public mockToken;
    address public owner;
    address public user1;
    address public user2;

    uint256 constant INITIAL_SUPPLY = 1000000 * 10**18;
    uint256 constant USER_BALANCE = 10000 * 10**18;
    uint256 constant STAKE_AMOUNT = 1000 * 10**18;
    uint256 constant STAKING_PERIOD = 7 days;
    
    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        
        mockToken = new MockToken();
        stakingContract = new StakingContract(address(mockToken));
        
        mockToken.transfer(user1, USER_BALANCE);
        mockToken.transfer(user2, USER_BALANCE);
        
        assertEq(mockToken.balanceOf(user1), USER_BALANCE);
        assertEq(mockToken.balanceOf(user2), USER_BALANCE);
    }
    
    function testInitialState() public {
        assertEq(address(stakingContract.stakingToken()), address(mockToken));
        assertEq(stakingContract.totalStaked(), 0);
        assertEq(stakingContract.owner(), owner);
    }
    
    function testStaking() public {
        vm.startPrank(user1);
        mockToken.approve(address(stakingContract), STAKE_AMOUNT);
        stakingContract.stake(STAKE_AMOUNT, STAKING_PERIOD);
        vm.stopPrank();
        
        assertEq(mockToken.balanceOf(address(stakingContract)), STAKE_AMOUNT);
        assertEq(mockToken.balanceOf(user1), USER_BALANCE - STAKE_AMOUNT);
        
        assertEq(stakingContract.totalStaked(), STAKE_AMOUNT);
        
        vm.startPrank(user1);
        StakingContract.Stake[] memory stakes = stakingContract.getStake();
        vm.stopPrank();
        
        assertEq(stakes.length, 1);
        assertEq(stakes[0].stakedAmount, STAKE_AMOUNT);
        assertEq(stakes[0].withdrawDate, block.timestamp + STAKING_PERIOD);
    }
    
    function testMultipleStaking() public {
        vm.startPrank(user1);
        mockToken.approve(address(stakingContract), STAKE_AMOUNT * 3);
        
        stakingContract.stake(STAKE_AMOUNT, STAKING_PERIOD);
        stakingContract.stake(STAKE_AMOUNT * 2, STAKING_PERIOD * 2);
        
        StakingContract.Stake[] memory stakes = stakingContract.getStake();
        vm.stopPrank();
        
        assertEq(stakes.length, 2);
        assertEq(stakes[0].stakedAmount, STAKE_AMOUNT);
        assertEq(stakes[1].stakedAmount, STAKE_AMOUNT * 2);
        
        assertEq(stakingContract.totalStaked(), STAKE_AMOUNT * 3);
    }
    
    function testWithdrawBeforePeriod() public {
        vm.startPrank(user1);
        mockToken.approve(address(stakingContract), STAKE_AMOUNT);
        stakingContract.stake(STAKE_AMOUNT, STAKING_PERIOD);
        
        stakingContract.withdraw();
        vm.stopPrank();
        
        assertEq(mockToken.balanceOf(address(stakingContract)), STAKE_AMOUNT);
        assertEq(mockToken.balanceOf(user1), USER_BALANCE - STAKE_AMOUNT);
        assertEq(stakingContract.totalStaked(), STAKE_AMOUNT);
    }
    
    function testWithdrawAfterPeriod() public {
        vm.startPrank(user1);
        mockToken.approve(address(stakingContract), STAKE_AMOUNT);
        stakingContract.stake(STAKE_AMOUNT, STAKING_PERIOD);
        vm.stopPrank();
        
        vm.warp(block.timestamp + STAKING_PERIOD + 1);
        
        vm.startPrank(user1);
        stakingContract.withdraw();
        vm.stopPrank();
        
        assertEq(mockToken.balanceOf(address(stakingContract)), 0);
        assertEq(mockToken.balanceOf(user1), USER_BALANCE);
        assertEq(stakingContract.totalStaked(), 0);
    }
    
    function testMultipleUsersStaking() public {
        vm.startPrank(user1);
        mockToken.approve(address(stakingContract), STAKE_AMOUNT);
        stakingContract.stake(STAKE_AMOUNT, STAKING_PERIOD);
        vm.stopPrank();
        
        vm.startPrank(user2);
        mockToken.approve(address(stakingContract), STAKE_AMOUNT * 2);
        stakingContract.stake(STAKE_AMOUNT * 2, STAKING_PERIOD * 2);
        vm.stopPrank();
        
        assertEq(stakingContract.totalStaked(), STAKE_AMOUNT * 3);
        
        vm.startPrank(user1);
        StakingContract.Stake[] memory stakes1 = stakingContract.getStake();
        vm.stopPrank();
        
        vm.startPrank(user2);
        StakingContract.Stake[] memory stakes2 = stakingContract.getStake();
        vm.stopPrank();
        
        assertEq(stakes1.length, 1);
        assertEq(stakes1[0].stakedAmount, STAKE_AMOUNT);
        
        assertEq(stakes2.length, 1);
        assertEq(stakes2[0].stakedAmount, STAKE_AMOUNT * 2);
    }
    
    function testFailTransferFromFail() public {
        vm.startPrank(user1);
        stakingContract.stake(STAKE_AMOUNT, STAKING_PERIOD);
        vm.stopPrank();
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/vote_contract.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor() ERC20("Mock Token", "MOCK") {
        _mint(msg.sender, 1000000 * 10 ** 18);
    }
}

contract VoteContractInnerTest is VoteContract {

    constructor(IERC20 _stakingToken) VoteContract(_stakingToken) {}
    function finishVote(uint256 voteID) public {
        innerFinishVote(voteID);
    }
}

contract VoteContractTest is Test {
    VoteContractInnerTest public voteContract;
    MockToken public stakingToken;

    address public owner = address(1);
    address public alice = address(2);
    address public bob = address(3);
    address public charlie = address(4);

    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18;
    uint256 public constant STAKE_AMOUNT = 1000 * 10 ** 18;
    uint256 public constant THRESHOLD = 50;
    uint256 public constant VOTE_DURATION = 7 days;

    function setUp() public {
        vm.startPrank(owner);

        stakingToken = new MockToken();
        voteContract = new VoteContractInnerTest(IERC20(address(stakingToken)));

        stakingToken.transfer(alice, STAKE_AMOUNT * 2);
        stakingToken.transfer(bob, STAKE_AMOUNT * 3);
        stakingToken.transfer(charlie, STAKE_AMOUNT * 4);

        vm.stopPrank();
    }

    function _setupStaking() internal {
        vm.startPrank(alice);
        stakingToken.approve(address(voteContract), STAKE_AMOUNT);
        voteContract.stake(STAKE_AMOUNT, 30 days);
        vm.stopPrank();

        vm.startPrank(bob);
        stakingToken.approve(address(voteContract), STAKE_AMOUNT);
        voteContract.stake(STAKE_AMOUNT, 60 days);
        vm.stopPrank();

        vm.startPrank(charlie);
        stakingToken.approve(address(voteContract), STAKE_AMOUNT * 2);
        voteContract.stake(STAKE_AMOUNT * 2, 45 days);
        vm.stopPrank();
    }

    //INITIATE VOTE-------------------------------------------------------------------------------------//

    function testNotAdminMakeVote() public {
        vm.startPrank(alice);
        string memory question = "Should we upgrade the protocol?";
        uint256 deadline = block.timestamp + VOTE_DURATION;

        vm.expectRevert();
        voteContract.initiateVote(
            question,
            THRESHOLD,
            deadline
        );
        vm.stopPrank();
    }

    function testInvalidThreshold() public {
        vm.startPrank(alice);
        string memory question = "Should we upgrade the protocol?";
        uint256 deadline = block.timestamp + VOTE_DURATION;

        vm.expectRevert();
        voteContract.initiateVote(question, 101, deadline);
        vm.stopPrank();
    }

    function testInitiateVote() public {
        vm.startPrank(owner);

        string memory question = "Should we upgrade the protocol?";
        uint256 deadline = block.timestamp + VOTE_DURATION;

        uint256 voteID = voteContract.initiateVote(
            question,
            THRESHOLD,
            deadline
        );

        VoteContract.Vote memory vote = voteContract.getVote(voteID);

        assertEq(vote.question, question);
        assertEq(vote.threshold, THRESHOLD);
        assertEq(vote.deadline, deadline);
        assertEq(
            uint(vote.finalDecision),
            uint(VoteContract.Decision.InProcess)
        );
        assertEq(vote.peopleVoted, 0);
        assertEq(vote.yesVote, 0);
        assertEq(vote.noVote, 0);
        assertEq(voteID, 0);

        vm.stopPrank();
    }

    function testInvalidVoteID() public {
        _setupStaking();
        vm.startPrank(alice);
        
        vm.expectRevert();
        voteContract.vote(0, true);
        vm.stopPrank();
    }

    //VOTE WORK-------------------------------------------------------------------------------------//

    function testVotingProcess() public {
        _setupStaking();

        vm.prank(owner);
        uint256 voteID = voteContract.initiateVote(
            "Should we approve this proposal?",
            THRESHOLD,
            block.timestamp + VOTE_DURATION
        );

        vm.prank(alice);
        voteContract.vote(voteID, true);

        vm.prank(bob);
        voteContract.vote(voteID, false);

        vm.prank(charlie);
        voteContract.vote(voteID, true);

        VoteContract.Vote memory voteData = voteContract.getVote(voteID);
        assertEq(voteData.peopleVoted, 3);
        assert(voteData.yesVote > voteData.noVote);
        assertEq(
            uint(voteData.finalDecision),
            uint(VoteContract.Decision.InProcess)
        );

        vm.prank(alice);
        vm.expectRevert("You have already voted.");
        voteContract.vote(voteID, false);
    }

    function testVotingPower() public {
        vm.startPrank(alice);
        stakingToken.approve(address(voteContract), STAKE_AMOUNT);
        voteContract.stake(STAKE_AMOUNT, 30 days);
        vm.stopPrank();

        vm.startPrank(bob);
        stakingToken.approve(address(voteContract), STAKE_AMOUNT);
        voteContract.stake(STAKE_AMOUNT, 90 days);
        vm.stopPrank();

        vm.prank(owner);
        uint256 voteID = voteContract.initiateVote(
            "Should we approve this proposal?",
            THRESHOLD,
            block.timestamp + VOTE_DURATION
        );

        vm.prank(alice);
        voteContract.vote(voteID, true);

        vm.prank(bob);
        voteContract.vote(voteID, false);

        VoteContract.Vote memory voteData = voteContract.getVote(voteID);

        assert(voteData.noVote > voteData.yesVote);
    }

    //VOTE FINISHED-------------------------------------------------------------------------------------//

    function testVoteFinish() public {
        _setupStaking();

        vm.prank(owner);
        uint256 voteID = voteContract.initiateVote(
            "Should we approve this proposal?",
            THRESHOLD,
            block.timestamp + 1 days
        );

        vm.prank(bob);
        voteContract.vote(voteID, false);

        vm.prank(charlie);
        voteContract.vote(voteID, true);

        vm.warp(block.timestamp + 2 days);

        vm.prank(owner);
        voteContract.finishVote(voteID);

        VoteContract.Vote memory voteData = voteContract.getVote(voteID);
        assertEq(uint(voteData.finalDecision), uint(VoteContract.Decision.Yes));

        vm.prank(alice);
        vm.expectRevert("Voting not in process");
        voteContract.vote(voteID, false);
    }

    function testVoteCantBeFinished() public {
        _setupStaking();

        vm.prank(owner);
        uint256 voteID = voteContract.initiateVote(
            "Should we approve this proposal?",
            THRESHOLD,
            block.timestamp + 1 days
        );

        vm.prank(owner);

        vm.expectRevert();
        voteContract.finishVote(voteID);
    }

    function testVoteFailed() public {
        vm.startPrank(alice);
        stakingToken.approve(address(voteContract), STAKE_AMOUNT);
        voteContract.stake(STAKE_AMOUNT, 30 days);
        vm.stopPrank();

        vm.startPrank(bob);
        stakingToken.approve(address(voteContract), STAKE_AMOUNT);
        voteContract.stake(STAKE_AMOUNT, 30 days);
        vm.stopPrank();

        vm.prank(owner);
        uint256 voteID = voteContract.initiateVote(
            "Should we approve this proposal?",
            75,
            block.timestamp + 1 days
        );

        vm.prank(alice);
        voteContract.vote(voteID, true);

        vm.warp(block.timestamp + 2 days);

        vm.prank(owner);
        voteContract.finishVote(voteID);

        VoteContract.Vote memory voteData = voteContract.getVote(voteID);
        assertEq(
            uint(voteData.finalDecision),
            uint(VoteContract.Decision.Failed)
        );
    }

    function testAliceVotedTooTimes() public {
        vm.startPrank(alice);
        stakingToken.approve(address(voteContract), STAKE_AMOUNT);
        voteContract.stake(STAKE_AMOUNT, 30 days);
        vm.stopPrank();

        vm.prank(owner);
        uint256 voteID = voteContract.initiateVote(
            "Should we approve this proposal?",
            THRESHOLD,
            block.timestamp + VOTE_DURATION
        );

        vm.prank(alice);
        voteContract.vote(voteID, true);

        vm.expectRevert();
        voteContract.vote(voteID, true);
        vm.stopPrank();
    }
}

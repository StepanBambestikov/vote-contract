// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/vote_token_contract.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor() ERC20("Mock Token", "MOCK") {
        _mint(msg.sender, 1000000 * 10 ** 18);
    }
}

contract VoteTokenContractTest is Test {
    VoteTokenContract public voteTokenContract;
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

        voteTokenContract = new VoteTokenContract(
            IERC20(address(stakingToken))
        );

        stakingToken.transfer(alice, STAKE_AMOUNT * 2);
        stakingToken.transfer(bob, STAKE_AMOUNT * 3);
        stakingToken.transfer(charlie, STAKE_AMOUNT * 4);

        vm.stopPrank();

        vm.startPrank(alice);
        stakingToken.approve(address(voteTokenContract), STAKE_AMOUNT);
        voteTokenContract.stake(STAKE_AMOUNT, 30 days);
        vm.stopPrank();

        vm.startPrank(bob);
        stakingToken.approve(address(voteTokenContract), STAKE_AMOUNT);
        voteTokenContract.stake(STAKE_AMOUNT, 60 days);
        vm.stopPrank();

        vm.startPrank(charlie);
        stakingToken.approve(address(voteTokenContract), STAKE_AMOUNT * 2);
        voteTokenContract.stake(STAKE_AMOUNT * 2, 45 days);
        vm.stopPrank();
    }

    function testTokenMetadata() public view {
        assertEq(voteTokenContract.name(), "VotingRecord");
        assertEq(voteTokenContract.symbol(), "VOTE");
    }

    function testTokenMintingOnVoteFinish() public {
        vm.startPrank(owner);
        uint256 voteID = voteTokenContract.initiateVote(
            "Test NFT Minting on Vote Finish",
            THRESHOLD,
            block.timestamp + 1 days
        );
        vm.stopPrank();

        vm.prank(alice);
        voteTokenContract.vote(voteID, true);

        vm.prank(bob);
        voteTokenContract.vote(voteID, false);

        vm.prank(charlie);
        voteTokenContract.vote(voteID, true);

        assertEq(voteTokenContract.balanceOf(owner), 0);

        vm.prank(owner);
        voteTokenContract.finishVote(voteID);

        assertEq(voteTokenContract.balanceOf(owner), 1);
        assertEq(voteTokenContract.ownerOf(voteID), owner);

        VoteContract.Vote memory voteData = voteTokenContract.getVote(voteID);
        assert(
            uint(voteData.finalDecision) !=
                uint(VoteContract.Decision.InProcess)
        );

        voteTokenContract.tokenURI(voteID);

        //assertEq(getSubstring(uri, 0, 29), "data:application/json;base64,");
    }

    function testMultipleVoteTokens() public {
        vm.startPrank(owner);
        uint256 voteID1 = voteTokenContract.initiateVote(
            "Proposal 1",
            1,
            block.timestamp + 1 days
        );
        uint256 voteID2 = voteTokenContract.initiateVote(
            "Proposal 2",
            1,
            block.timestamp + 1 days
        );
        uint256 voteID3 = voteTokenContract.initiateVote(
            "Proposal 3",
            1,
            block.timestamp + 1 days
        );
        vm.stopPrank();

        vm.prank(alice);
        voteTokenContract.vote(voteID1, true);

        vm.prank(alice);
        voteTokenContract.vote(voteID2, false);

        vm.prank(alice);
        voteTokenContract.vote(voteID3, true);

        vm.startPrank(owner);
        voteTokenContract.finishVote(voteID1);
        voteTokenContract.finishVote(voteID2);
        voteTokenContract.finishVote(voteID3);
        vm.stopPrank();

        assertEq(voteTokenContract.balanceOf(owner), 3);
        assertEq(voteTokenContract.ownerOf(voteID1), owner);
        assertEq(voteTokenContract.ownerOf(voteID2), owner);
        assertEq(voteTokenContract.ownerOf(voteID3), owner);

        string memory uri1 = voteTokenContract.tokenURI(voteID1);
        string memory uri2 = voteTokenContract.tokenURI(voteID2);
        string memory uri3 = voteTokenContract.tokenURI(voteID3);

        assertTrue(keccak256(bytes(uri1)) != keccak256(bytes(uri2)));
        assertTrue(keccak256(bytes(uri2)) != keccak256(bytes(uri3)));
        assertTrue(keccak256(bytes(uri1)) != keccak256(bytes(uri3)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "stack_contract.sol";


contract VoteContract is StakingContract {
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    
    Vote[] public voteHistory;
    mapping(uint256 => EnumerableMap.AddressToUintMap) internal txUserVote;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Vote {
        uint256 deadline;    
        uint256 threshold;     
        string question;
        uint256 peopleVoted;
        uint256 yesVote;  
        uint256 noVote;  
        Decision finalDecision;
    }

    enum Decision {
        InProcess,
        Yes,
        No,
        Failed
    }

    enum UserVote {
        NotVoted,
        Yes,
        No
    }

    event VoteCreated(string question, uint256 voteID);
    event VoteFinished(string question, uint256 voteID, Decision desition);

    constructor(IERC20 _stakingToken) StakingContract(_stakingToken){}

    modifier indexInBounds(uint256 index, uint256 arrayLength) {
        require(index < arrayLength, "Index out of bounds");
        _;
    }

    function initiateVote(string memory question, uint256 threshold, uint256 deadline) external onlyOwner returns(uint256){
        require(threshold > 0 && threshold < 100, "threshold must be in 0 - 100 range");

        voteHistory.push(
            Vote({
                deadline: deadline, 
                threshold: threshold, 
                question: question,
                peopleVoted: 0,
                yesVote: 0,  
                noVote: 0 ,    
                finalDecision: Decision.InProcess
            }));
        uint256 voteID = voteHistory.length - 1;
        emit VoteCreated(question, voteID);
        return voteID;
    }

    function _threshold_reached(Vote memory voteData) private view returns(bool){
        uint256 votingPower;
        for (uint i = 0; i < users.length(); i++) {
            Stake[] memory stake = getUserStake(users.at(i));
            votingPower += _calculateVotingPower(stake);
        }
        return voteData.yesVote + voteData.noVote > (votingPower * voteData.threshold/100);
    }

    function innerFinishVote(uint256 voteID) internal indexInBounds(voteID, voteHistory.length){
        Vote memory voteData = voteHistory[voteID];
        require(voteData.finalDecision == Decision.InProcess, "Already finished!");

        bool threshold_reached = _threshold_reached(voteData);

        if (voteData.deadline > block.timestamp && !threshold_reached){
            voteData.finalDecision = Decision.Failed;
            voteHistory[voteID] = voteData;
            emit VoteFinished(voteData.question, voteID, voteData.finalDecision);
            return;
        }

        require(
            threshold_reached,
             "The threshold has not been reached, and voting cannot be completed."
        );


        if (voteData.yesVote > voteData.noVote){
            voteData.finalDecision = Decision.Yes;
        } else{
            voteData.finalDecision = Decision.No;
        }

        voteHistory[voteID] = voteData;
        emit VoteFinished(voteData.question, voteID, voteData.finalDecision);
        return;
    }

    function getVote(uint256 voteID) external view indexInBounds(voteID, voteHistory.length) returns (Vote memory){
        return voteHistory[voteID];
    }

    function vote(uint256 voteID, bool yes) external indexInBounds(voteID, voteHistory.length){
        require(!txUserVote[voteID].contains(msg.sender), "You have already voted.");

        Vote memory voteData = voteHistory[voteID];
        require(voteData.deadline <= block.timestamp, "The deadline has passed");
        require(voteData.finalDecision == Decision.InProcess, "Voting not in process");


        Stake[] memory stake = getStake();
        uint256 votingPower = _calculateVotingPower(stake);
        require(votingPower != 0, "Zero voting power");

        if (yes){
            voteData.yesVote += votingPower;
            txUserVote[voteID].set(msg.sender, uint256(UserVote.Yes));
        } else{
            voteData.noVote += votingPower; 
            txUserVote[voteID].set(msg.sender, uint256(UserVote.No));
        } 

        voteData.peopleVoted++;
        voteHistory[voteID] = voteData;
    }

    function _calculateVotingPower(Stake[] memory stakeList) private pure returns (uint256){ 
        uint256 votingPower = 0;
        for (uint i = 0; i < stakeList.length; i++) {
            Stake memory stake = stakeList[i];
            votingPower += stake.stakedAmount * (stake.withdrawDate ** 2);
        }
        return votingPower;
    }

}
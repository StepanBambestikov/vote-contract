// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "src/vote_contract.sol";

// @dev The contract implements only the logic of the functioning of the NFT token,
// which is created for each completed vote
contract VoteTokenContract is VoteContract, ERC721 {
  using Strings for uint256;
  using EnumerableMap for EnumerableMap.AddressToUintMap;

  constructor(
      IERC20 _stakingToken
  ) VoteContract(_stakingToken) ERC721("VotingRecord", "VOTE") {}

  function finishVote(
      uint256 voteID
  ) public indexInBounds(voteID, voteHistory.length) {
      innerFinishVote(voteID);
      _mint(msg.sender, voteID);
      return;
  }

  function tokenURI(
    uint256 tokenId
) public view override returns (string memory) {
    //require(_exists(tokenId), "URI query for nonexistent token");

    string memory baseJSON = _baseTokenJSON(tokenId);
    string memory attributesJSON = _attributesJSON(tokenId);
    string memory votersJSON = _getVotersJSON(txUserVote[tokenId]);
    
    string memory fullJSON = string(abi.encodePacked(
        baseJSON,
        attributesJSON,
       ',"voters": [', votersJSON, ']}'
    ));
    
    return string(
        abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(fullJSON))
        )
    );
}

  function _baseTokenJSON(uint256 tokenId) private view returns (string memory) {
      Vote storage voteData = voteHistory[tokenId];
      
      return string(abi.encodePacked(
          '{',
          '"name": "Vote #', tokenId.toString(), '",',
          '"description": "', voteData.question, '"'
      ));
  }

  function _attributesJSON(uint256 tokenId) private view returns (string memory) {
    string memory part1 = _attributesPart1(tokenId);
    string memory part2 = _attributesPart2(tokenId);
    
    return string(abi.encodePacked(
        ',"attributes": [',
        part1,
        ',',
        part2,
        ']'
    ));
}

  function _attributesPart1(uint256 tokenId) private view returns (string memory) {
    Vote storage voteData = voteHistory[tokenId];
    
    return string(abi.encodePacked(
        '{',
            '"trait_type": "Deadline",',
            '"value": "', voteData.deadline.toString(), '"',
        '},',
        '{',
            '"trait_type": "Threshold",',
            '"value": "', voteData.threshold.toString(), '"',
        '},',
        '{',
            '"trait_type": "Total Votes",',
            '"value": "', voteData.peopleVoted.toString(), '"',
        '}'
    ));
  }

  function _attributesPart2(uint256 tokenId) private view returns (string memory) {
    Vote storage voteData = voteHistory[tokenId];
    
    return string(abi.encodePacked(
        '{',
            '"trait_type": "Yes Votes",',
            '"value": "', voteData.yesVote.toString(), '"',
        '},',
        '{',
            '"trait_type": "No Votes",',
            '"value": "', voteData.noVote.toString(), '"',
        '},',
        '{',
            '"trait_type": "Decision",',
            '"value": "', _getDecisionString(voteData.finalDecision), '"',
        '}'
    ));
  }

  function _getDecisionString(Decision decision) private pure returns (string memory) {
    if (decision == Decision.InProcess) return "Pending";
    if (decision == Decision.Failed) return "Failed";
    if (decision == Decision.Yes) return "Yes";
    if (decision == Decision.No) return "No";
    return "Invalid";
  }

  function _getVotersJSON(EnumerableMap.AddressToUintMap storage votedUsers) 
    private view returns (string memory) {
    
    string memory votersJSON = "";
    uint256 votersCount = EnumerableMap.length(votedUsers);
    
    for (uint256 i = 0; i < votersCount; i++) {
        (address voter, uint voteValue) = votedUsers.at(i);
        
        string memory voteString = "NotVoted";
        if (UserVote(voteValue) == UserVote.Yes) voteString = "Yes";
        if (UserVote(voteValue) == UserVote.No) voteString = "No";
        
        votersJSON = string(abi.encodePacked(
            votersJSON,
            '{',
                '"address": "', Strings.toHexString(uint160(voter), 20), '",',
                '"vote": "', voteString, '"',
            '}'
        ));
        
        // Add comma if not the last element
        if (i < votersCount - 1) {
            votersJSON = string(abi.encodePacked(votersJSON, ","));
        }
    }
    
    return votersJSON;
  }
}

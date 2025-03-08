// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "vote_contract.sol";


// @dev The contract implements only the logic of the functioning of the NFT token,
// which is created for each completed vote
contract VoteTokenContract is VoteContract, ERC721 {
    using Strings for uint256;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    constructor(IERC20 _stakingToken) VoteContract(_stakingToken) ERC721("VotingRecord", "VOTE") {}

    function finishVote(uint256 voteID) public indexInBounds(voteID, voteHistory.length){
        innerFinishVote(voteID);
        _mint(msg.sender, voteID);
        return;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        //require(_exists(tokenId), "URI query for nonexistent token"); TODO
        
        Vote storage voteData = voteHistory[tokenId];
        
        string memory decisionStr;
        if (voteData.finalDecision == Decision.Yes) {
            decisionStr = "Yes";
        } else if (voteData.finalDecision == Decision.No) {
            decisionStr = "No";
        } else {
            decisionStr = "InProcess";
        }
        
        string memory json = string(abi.encodePacked(
            '{"name": "Vote #', 
            tokenId.toString(), 
            '", "description": "', 
            voteData.question, 
            '", "attributes": [{"trait_type": "Yes Votes", "value": "', 
            voteData.yesVote.toString(), 
            '"}, {"trait_type": "No Votes", "value": "', 
            voteData.noVote.toString(), 
            '"}, {"trait_type": "People Voted", "value": "', 
            voteData.peopleVoted.toString(), 
            '"}, {"trait_type": "Decision", "value": "', 
            decisionStr, 
            '"}'
        ));
        
        uint256 voterCount = txUserVote[tokenId].length();
        if (voterCount > 0) {
            json = string(abi.encodePacked(json, ', {"trait_type": "Voters Detail", "value": "'));
            
            for (uint256 i = 0; i < voterCount; i++) {
                (address voter, uint256 voteWeight) = txUserVote[tokenId].at(i);
                
                if (i > 0) {
                    json = string(abi.encodePacked(json, ", "));
                }
                
                json = string(abi.encodePacked(
                    json,
                    toAsciiString(voter),
                    ": ",
                    voteWeight.toString()
                ));
                
                if (i >= 9 && voterCount > 10) {
                    json = string(abi.encodePacked(
                        json,
                        "",
                        (voterCount - 10).toString(),
                        ""
                    ));
                    break;
                }
            }
            
            json = string(abi.encodePacked(json, '"}'));
        }
        
        json = string(abi.encodePacked(json, "]}"));
        
        string memory encodedJson = Base64.encode(bytes(json));
        return string(abi.encodePacked("data:application/json;base64,", encodedJson));
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(42);
        s[0] = "0";
        s[1] = "x";
        
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i + 2] = char(hi);
            s[2 * i + 3] = char(lo);
        }
        
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1) {
        if (uint8(b) < 10) {
            return bytes1(uint8(b) + 0x30);
        } else {
            return bytes1(uint8(b) + 0x57);
        }
    }

}
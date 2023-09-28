// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VotingSystem is Ownable {

    struct Candidate {
        string name;
        uint256 voteCount;
    }

    IERC20 public votingToken;

    Candidate[] public candidates;

    mapping(address => bool) public hasVoted;

    mapping(address => uint256) public voteTimestamp;
    mapping(address => uint256) public voteBlockHeight;

    bool public electionOpen = false;

    modifier onlyOpenElection() {
        require(electionOpen, "Election is not open");
        _;
    }

    event ElectionOpened();

    event ElectionClosed();

    event Voted(address indexed voter, uint256 candidateIndex);

    constructor(address _votingToken) {
        votingToken = IERC20(_votingToken);
    }

    function addCandidate(string memory _name) external onlyOwner {
        candidates.push(Candidate(_name, 0));
    }

    function openElection() external onlyOwner {
        require(!electionOpen, "Election is already open");
        electionOpen = true;
        emit ElectionOpened();
    }

    function closeElection() external onlyOwner onlyOpenElection {
        electionOpen = false;
        emit ElectionClosed();
    }

    function vote(uint256 _candidateIndex) external onlyOpenElection {
        require(!hasVoted[msg.sender], "You have already voted");
        require(_candidateIndex < candidates.length, "Invalid candidate index");

        votingToken.transferFrom(msg.sender, address(this), 1);

        hasVoted[msg.sender] = true;
        candidates[_candidateIndex].voteCount++;
        voteTimestamp[msg.sender] = block.timestamp;
        voteBlockHeight[msg.sender] = block.number;

        emit Voted(msg.sender, _candidateIndex);
    }

    function getElectionResults() external view returns (uint256[] memory) {
        uint256[] memory results = new uint256[](candidates.length);
        for (uint256 i = 0; i < candidates.length; i++) {
            results[i] = candidates[i].voteCount;
        }
        return results;
    }

    function announceWinner() external view returns (string memory) {
        require(!electionOpen, "Election is still open");
        uint256 maxVotes = 0;
        uint256 winningCandidateIndex = 0;

        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > maxVotes) {
                maxVotes = candidates[i].voteCount;
                winningCandidateIndex = i;
            }
        }

        return candidates[winningCandidateIndex].name;
    }
}

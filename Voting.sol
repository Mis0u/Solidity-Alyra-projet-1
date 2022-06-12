// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import "./Status.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Voting is Status {

    mapping(address => Voter) public voters;

    mapping(uint => string) proposalList;

    mapping(address => uint) showingVotes;

    string[] proposalListArray;

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    Proposal[] public proposals;

    uint public winningProposalId;

    function whitetList(address _user) external onlyOwner {
        require(status == WorkflowStatus.RegisteringVoters, unicode'Désolé, les inscriptions sont terminées');
        require(voters[_user].isRegistered == false, unicode'Cette adresse est déjà inscrite sur la liste');
        voters[_user].isRegistered = true;
    }

    function proposalsRegistration(string memory _description) public {
        require(status == WorkflowStatus.ProposalsRegistrationStarted, unicode'Désolé, nous n\'acceptons plus de proposition');
        require(voters[msg.sender].isRegistered == true, unicode'Vous n\'êtes pas autorisé à faire des propositions');

        proposals.push(Proposal({description: _description, voteCount: 0}));

        uint proposalId = proposals.length - 1;

        proposalList[proposalId] = _description;

        string memory concat = concatenateStrings(Strings.toString(proposalId), ' => ', _description);
        proposalListArray.push(concat);
        emit ProposalRegistered(proposalId);
    }

    function getProposals() external view returns(string[] memory){
        return proposalListArray;
    }

    function voteRegistration(uint8 _id) public {
        require(status == WorkflowStatus.VotingSessionStarted, unicode'Désolé, nous n\'acceptons plus de vote !');
        require(voters[msg.sender].isRegistered == true, unicode'Vous n\'êtes pas autorisé à voter');
        require(_id < proposalListArray.length, unicode'Désolé cette proposition n\'existe pas');
        require(voters[msg.sender].hasVoted == false, 'Vous ne pouvez voter qu\'une seule fois');

        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _id;

        proposals[_id].voteCount++;

        showingVotes[msg.sender] = _id;

        emit VoterRegistered(msg.sender);
        emit Voted(msg.sender, _id);
    }

    function voteTalliedCount() public  {
        require(status == WorkflowStatus.VotingSessionEnded, unicode'Nous ne sommes pas encorer à cette étape');

        uint currentWinningProposalId;
        uint nbVotes;

        for (uint8 i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > nbVotes) {
                currentWinningProposalId = i;
                nbVotes = proposals[i].voteCount;
            }
        }

        winningProposalId = currentWinningProposalId;
    }

    function getWinningProposal() external view returns(string memory contentProposal, uint nbVotes) {
        require(status == WorkflowStatus.VotesTallied, 'Nous ne connaissons pas encore la proposition gagnante');

        return (
        proposals[winningProposalId].description,
        proposals[winningProposalId].voteCount
        );

    }

    function displayVotes(address _user) external view returns(string memory) {
        if (voters[_user].hasVoted) {
            return Strings.toString(showingVotes[_user]);
        }
        return 'Aucun vote concernant cet utilisateur';
    }

    function concatenateStrings(string memory s1, string memory s2, string memory s3) private pure returns(string memory) {
        return string.concat(s1,s2,s3);
    }
}

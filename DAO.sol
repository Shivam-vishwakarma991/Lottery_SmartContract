// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Dao{
    struct Proposal{
        uint id;
        string description;
        uint amount;
        address payable recepient;
        uint votes;
        uint proposalEnd;  //votetime
        bool isExecuted;
    }

    mapping (address=>bool) public isInvestor;
    mapping (address=> uint) public numOFshares;  //Jitne ether send honge utne hi in Wei shares honge
    mapping (address=>mapping (uint=>bool)) public HasVoted;
    mapping (address=>mapping (address=>bool)) public withdrawalStatus;
    mapping (uint=>Proposal) public proposals;

    address[] public InvestorsList;


    uint public totalShares;
    uint public AvailableFunds;  //fund in contract
    uint public ContributionTimeEnd;
    uint public Quorum;
    uint public VoteTime;
    uint public ProposalId;
    address public manager;


    constructor(uint _cotributionTimeEnd,uint _VoteTime, uint _Quorum ) {

        require(_Quorum>0 && _Quorum<100, "Not Valid");
        ContributionTimeEnd=block.timestamp+ _cotributionTimeEnd;
        VoteTime= _VoteTime;
        Quorum= _Quorum;
        manager= msg.sender;        
    }

    modifier onlyInvestor(){
        require(isInvestor[msg.sender]==true, "You are not an Investor");
    _;
    }

    modifier onlyManager(){
        require(manager==msg.sender, "YOU are not a manager");
    _;
    }

    function Contribution() public payable {
        require(ContributionTimeEnd>=block.timestamp, "Contribution time has been ended");
        require(msg.value>0, "Send more than zero ether");
        isInvestor[msg.sender]=true;  //Ye do steps agr pass hogyi to Adress ab investor ban gaya hai.sender
        numOFshares[msg.sender]+= msg.value;
        AvailableFunds+=msg.value;
        totalShares+= msg.value;
        InvestorsList.push(msg.sender);

    }

    function ReedemShare(uint shares) public  onlyInvestor(){
        require(numOFshares[msg.sender]>=shares, "You don't have enough shares");
        require(AvailableFunds>=shares,"Not enough funds in the contract");
        numOFshares[msg.sender]-=shares;
        if(numOFshares[msg.sender]==0){
            isInvestor[msg.sender]= false;
        }
        AvailableFunds-=shares;
        payable(msg.sender).transfer(shares);
    }
    
    function showInvestorsList() public view returns(address[] memory){
        return InvestorsList;
    }

    function transferShare(uint amount, address to) public onlyInvestor(){
        require(numOFshares[msg.sender]>=amount,"You don't have enough shares");
        require(AvailableFunds>=amount,"Not enough funds in the contract");
        numOFshares[msg.sender]-=amount;

        if(numOFshares[msg.sender]==0){
            isInvestor[msg.sender]=false;
        }
        AvailableFunds-=amount;
        numOFshares[to]+= amount;
        isInvestor[to]=true;

        InvestorsList.push(to);

    }

    function createProposal(string calldata description, uint amount, address payable recepient) public  onlyManager(){
        require(AvailableFunds>=amount, "Not Enough Balance");
        proposals[ProposalId]= Proposal(ProposalId, description, amount, recepient,0,block.timestamp+VoteTime,false);
        ProposalId++;
    }

    function VoteProposal(uint VoteProposalID) public  onlyInvestor() {

        Proposal storage proposalInstance= proposals[VoteProposalID];
        require(HasVoted[msg.sender][VoteProposalID]==false, "You have already voted");
        require(proposalInstance.proposalEnd>=block.timestamp, "Voting Time Ended");
        require(proposalInstance.isExecuted==false, "It is already executed");
        HasVoted[msg.sender][VoteProposalID]=true;
        proposalInstance.votes+=numOFshares[msg.sender];
    }

    function ExecuteProposal(uint _ProposalId) public onlyManager(){
         Proposal storage proposalInstance= proposals[_ProposalId];
         require(((proposalInstance.votes*100)/totalShares)>Quorum, "Majority  does not support");
         proposalInstance.isExecuted=true;
         AvailableFunds-= proposalInstance.amount;
         _transfer(proposalInstance.amount,proposalInstance.recepient);
    }

    function _transfer(uint amount, address payable recepient) public{
        recepient.transfer(amount);
    }
    
    function ProposalList()public view returns(Proposal[] memory){
         Proposal[] memory array= new Proposal[](ProposalId-1); //create emty array
         for(uint i=0; i<ProposalId;i++){
             array[i]= proposals[i];
         }
         return array;
    }

}

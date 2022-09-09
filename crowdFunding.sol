//SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 < 0.9.0;

contract Crowndfunding {

    mapping(address=> uint) public contributors;
    address public manager;
    uint public target;
    uint public deadline;
    uint public raisedAmount;
    uint public noofContributors;
    uint public minimumContribution;

    struct Request {
        string description;
        address payable recipient;
        uint value;
        bool completed; //check whether the request is pending or not
        uint noOfVoters;
        mapping(address=>bool) voters;  //will consist the address of the voters
    }
    mapping(uint=> Request) public requests;   //used in line 65 "requests"
    uint public Num_Request;

    constructor(uint _target, uint _deadline)
    {
        target =_target;
        deadline=block.timestamp + _deadline;   //jo bhi timechlra haiu usme we will add the deadline time if lets sat we want to end our funding in 1 hours than 
        manager= msg.sender; // curenttimestamp + 3600 sec
        minimumContribution= 1 ether;
    }

    function sendETH() public payable 
    {
        require(block.timestamp < deadline, "Deadline has Passed");
        require(msg.value>= minimumContribution, "You have to donate minimum 1 ether");

        if(contributors[msg.sender]==0){
        noofContributors++;
        }
        contributors[msg.sender] +=msg.value;
        raisedAmount+=msg.value;
    }
    function getRaisedAAmount() public view returns(uint)
    {
        return address(this).balance;
    }

    function refund() public 
    {
    require(block.timestamp > deadline && raisedAmount < target, "Ooopps seems like you have to wait for the deadline to pass");
    require(contributors[msg.sender]>0);
    address payable user= payable(msg.sender);
    user.transfer(contributors[msg.sender]); // contributors[msg.senders] pointing out to the address and address is mapped with uint i.e balance; 
    contributors[msg.sender]= 0;
    }

    modifier onlyManager(){
        require(msg.sender==manager, "Only the manager can have access to this function");
        _;
    }
    function createRequests(string memory _description, address payable _recipient,uint _value) public onlyManager  //we could  also write the requirre statement here.
    {
        Request storage newRequest= requests[Num_Request];
        Num_Request++;
        newRequest.description= _description;
        newRequest.recipient= _recipient;
        newRequest.value= _value;
        newRequest.completed= false;
        newRequest.noOfVoters= 0;
    }
      function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender]>0,"YOu must be contributor");
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.voters[msg.sender]==false,"You have already voted");
        thisRequest.voters[msg.sender]=true;
        thisRequest.noOfVoters++;
    }
    function makePayment(uint _requestNo) public onlyManager{
        require(raisedAmount>=target);
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.completed==false,"The request has been completed");
        require(thisRequest.noOfVoters > noofContributors/2,"Majority does not support");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed=true;
    }

}
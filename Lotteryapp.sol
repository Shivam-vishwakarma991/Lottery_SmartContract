// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Lottery
{
    address public manager = msg.sender;
    address payable[] public participants;

    receive() external payable
    {
        require(msg.value==1 ether);
        participants.push(payable(msg.sender));

    }
    function getbalance() public view returns(uint)
    {   
        require(msg.sender== manager);
        return address(this).balance;
    }

    function random() public view returns(uint)
    {
        return  uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, participants.length)));
    }

    function SelectWinner() public
    {
        require(msg.sender==manager);
        require(participants.length>=3);
        address payable winner;
        uint randomParticipant= random();
        uint participants_index= randomParticipant % participants.length;
        winner= participants[participants_index];
        winner.transfer(getbalance());
        participants= new address payable[](0);  
    } 
}

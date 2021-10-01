pragma solidity ^0.8.0;

contract Marshal{

    address[] public agreements;

    function addAgreement() public{
        agreements.push(msg.sender);
    }

    function voteForClient() public{}

    function voteForServiceProvider() public{}

    function _vote() internal{}
}
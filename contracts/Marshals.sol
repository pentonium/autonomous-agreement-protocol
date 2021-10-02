pragma solidity ^0.8.0;
import "./Escrow.sol";

contract Marshal{

    address[] public agreements;
    mapping(address => bool) public is_marshal;
    mapping(address => uint256) public client_votes;
    mapping(address => uint256) public service_provider_votes;
    mapping(address => uint256) public total_votes;

    function addAgreement() public{
        agreements.push(msg.sender);
    }

    function voteForClient(address agreement) public{
        require(total_votes[agreement] < 5, "Already 5 votes are there");
        client_votes[agreement]++;
        _vote(agreement);
    }

    function voteForServiceProvider(address agreement) public{
        require(total_votes[agreement] < 5, "Already 5 votes are there");
        service_provider_votes[agreement]++;
        _vote(agreement);
    }

    function _vote(address agreement) private{
        if(total_votes[agreement] == 5){

            if(client_votes[agreement] > service_provider_votes[agreement]){
                Escrow(agreement).clientWon();
            }else{
                Escrow(agreement).ServiceProvidertWon();();
            }
        }
    }

    function addMarshal(address user) public{
        is_marshal[user] = true;
    }

    function removeMarshal(address user) public{
        is_marshal[user] = false;
    }
}
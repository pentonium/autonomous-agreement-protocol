//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Escrow{

    address agreement;
    uint256 agId;

    constructor (address _agreement, uint256 _agId) public {
        
    }

     /** Order can be canceld after a day of no response */
    function cancelOrder() public {
    }

    /** Service provider can accept the order */
    function acceptOrder(string memory _service_provider_public, string memory _service_provider_private) public {
    }

    /** Service provider can reject the order */
    function rejectOrder() public {
    }

    /** Submit a deliver, requires ipfs hash of the chat */
    function deliver(string memory _ipfs_hash) public {
    }

    /** Accept the delivery and transfer the fund */
    function acceptDelivery() public {
    }


    /** Client Private & Public  */
    function getClientRequirements() public view returns (string memory, string memory, string memory){
    }

    /** Service Provider Private & Public  */
    function getServiceProviderRequirements() public view returns (string memory, string memory, string memory){
    }


    /** Create a dispute */
    function dispute() public {
    }


    /** Accept the dispute */
    function disputeAccept() public {
    }

}
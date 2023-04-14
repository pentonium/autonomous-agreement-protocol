//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./Escrow.sol";

contract Proxy{

    function placeOrder(address agreement, uint256 id, uint256 category_id, address client, address marshals, string memory public_key, string memory private_key) public returns (address){
        Escrow order = new Escrow(agreement, id, category_id, client, marshals, address(this), public_key, private_key);

        return address(order);
    }

    function updateMarshals(address marshals, address escrow) public{
        Escrow(escrow).updateMarshals(marshals);
    }
}
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IProxy{

    function placeOrder(address agreement, uint256 id, uint256 category_id, address client, address marshals, string memory public_key, string memory private_key) external returns (address);
}
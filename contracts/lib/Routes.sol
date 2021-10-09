//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Routes{

    mapping(address => address[]) public routes;


    function addNewRoute(address token, address[] memory path) public{
        routes[token] = path;
    }
}
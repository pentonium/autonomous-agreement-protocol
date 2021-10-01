//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./Escrow.sol";

contract AgreementToken is ERC721Enumerable {

    struct AgreementDetails{
        uint256 price;
        uint256 time;
        string ipfs_hash;
        bool is_public;
        address token;
        address owner;
        address client;
    }

    uint256 public tokenId;
    
    mapping(uint256 => AgreementDetails) public agreementDetail;

    constructor() ERC721("AgreementToken", "AGT") {
    }

    function nextTokenId() internal returns (uint256){
        tokenId++;
        return tokenId;
    }

    function transfer(address to, uint256 id) public{
        _transfer(address(msg.sender), to, id);
    }

    function generate(address to, string memory ipfs_hash, uint256 price, uint256 time, address token, address client, bool is_public) public{
        uint256 tid = nextTokenId();

        agreementDetail[tid] = AgreementDetails(price, time, ipfs_hash, is_public, token, msg.sender, client);

        _mint(to, tid);
    }

    function getAgreementDetails(uint256 id) public view returns(AgreementDetails memory){
        AgreementDetails memory agt = agreementDetail[id];

        if(agt.is_public) return agt;

        if(agt.client == msg.sender || agt.owner == msg.sender) return agt;
    }
    
    
    function updateAgreement(string memory ipfs_hash, uint256 price, uint256 time, uint256 id, address token) public{
         
         AgreementDetails memory agt = agreementDetail[id];
         agreementDetail[id] = AgreementDetails(price, time, ipfs_hash, agt.is_public, token, agt.owner, agt.client);
    }


    function placeOrder(uint256 id, uint256 category_id) public{
        Escrow order = new Escrow(address(this), id, category_id);
        AgreementDetails memory agt = agreementDetail[id];
        IERC20(agt.token).transferFrom(msg.sender, address(order), agt.price);
    }
}
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./interface/IProxy.sol";
import "./interface/IERC20.sol";
import "./interface/IAgreement.sol";

contract AgreementToken is ERC721Enumerable {

    mapping(uint256 => address[]) public gigOrders;
    mapping(address => address[]) public userOrders;
    mapping(address => address[]) public sellerOrders;
    mapping(uint256 => string) private _tokenURIs;

    uint256 public tokenId;
    uint256 public fee;
    IProxy public proxy;
    address public owner;
    address public marshals;

    mapping(uint256 => IAgreementToken.AgreementDetails) public agreementDetail;


    constructor(address _proxy) ERC721("AgreementToken", "AGT") {
        proxy = IProxy(_proxy);
        owner = msg.sender;
    }

    modifier onlyOwner {
      require(msg.sender == owner, "Only owner can invoke this function");
      _;
    }

    function nextTokenId() internal returns (uint256){
        tokenId++;
        return tokenId;
    }

    function updateOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function updateMarshalls(address _marshall) public onlyOwner {
        marshals = _marshall;
    }

    function generate(address to, string memory ipfs_hash, uint256 price, uint256 time, address token, address client, bool is_public) public{
        uint256 tid = nextTokenId();
        agreementDetail[tid] = IAgreementToken.AgreementDetails(price, time, fee, ipfs_hash, is_public, token, msg.sender, client);
        _mint(to, tid);
         _setTokenURI(tid, ipfs_hash);
    }

    function tokenURIs(uint256 id) public view returns(string memory){
        return _tokenURIs[id];
    }

    function _setTokenURI(uint256 _tokenId, string memory tokenURI) internal{
        _tokenURIs[_tokenId] = tokenURI;
    }

    function getAgreementDetails(uint256 id) public view returns(IAgreementToken.AgreementDetails memory){
        IAgreementToken.AgreementDetails memory agt = agreementDetail[id];
        if(agt.is_public) return agt;
        if(agt.client == msg.sender || agt.owner == msg.sender) return agt;
    }

    function updateAgreement(string memory ipfs_hash, uint256 price, uint256 time, uint256 id, address token) public{
         IAgreementToken.AgreementDetails memory agt = agreementDetail[id];
         require(agt.owner == msg.sender, "Only owner can update the agreement");
         agreementDetail[id] = IAgreementToken.AgreementDetails(price, time, fee, ipfs_hash, agt.is_public, token, agt.owner, agt.client);
    }

    function updateFee(uint256 _fee) public onlyOwner{
        fee = _fee;
    }

    function placeOrder(uint256 id, uint256 category_id, string memory public_key, string memory private_key) public{
        address order = proxy.placeOrder(address(this), id, category_id, msg.sender, marshals, public_key, private_key);
        IAgreementToken.AgreementDetails memory agt = agreementDetail[id];
        IERC20(agt.token).transferFrom(msg.sender, address(order), agt.price);

        gigOrders[id].push(order);
        userOrders[msg.sender].push(order);
        sellerOrders[agt.owner].push(order);
    }

    function getAllOrders(bool userType) public view returns(address[] memory){
        if(userType) return userOrders[msg.sender];
        else return sellerOrders[msg.sender];
    }

    function getGigOrders(uint256 id) public view returns(address[] memory){
        return gigOrders[id];
    }

    function burn(uint256 tokenId) public virtual {
        // solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}
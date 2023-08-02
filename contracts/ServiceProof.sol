//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interface/IEscrow.sol";
import "./interface/IClientProof.sol";

contract ServiceProof is ERC721PresetMinterPauserAutoId, Ownable {

    using Strings for uint256;

    using Counters for Counters.Counter;
    Counters.Counter public _tokenIDs;
    mapping(uint256 => address) public escrowUsed;
    address public clientProof;
    string private _baseTokenURI;

    constructor() ERC721PresetMinterPauserAutoId("ServiceProof", "SP", "") {
    }

    function mint(address escrow, address client, address service_provider, bool mode, string memory ipfs_hash, string memory skills, uint256 price, address token, uint256 deadline) public virtual returns(uint256){
        _tokenIDs.increment();

        uint256 currentTokenId =  _tokenIDs.current();
        escrowUsed[currentTokenId] = escrow;

        //let escrow know about this agreement
        IEscrow(escrow).createAgreement(address(this), currentTokenId, client, service_provider, mode, ipfs_hash, skills, price, token, deadline);

        IClientProof(clientProof).mint(currentTokenId, client, escrow);
        super._safeMint(service_provider, currentTokenId);
        return (currentTokenId);
    }

    function getAgreementDetails(uint256 id) public view returns(IEscrow.AgreementDetails memory){
        address contractUsed = escrowUsed[id];
        IEscrow.AgreementDetails memory selectedAgreement = IEscrow(contractUsed).getAgreementDetails(address(this), id);

        return selectedAgreement;
    }

    function setTokenURI(string memory token_uri) onlyOwner public{
        _baseTokenURI = token_uri;
    }

    function setClientProof(address _clientProof) public onlyOwner{
        clientProof = _clientProof;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(from == address(0) || to == address(0), "This a Soulbound token. It cannot be transferred. It can only be burned by the token owner.");
    }

}
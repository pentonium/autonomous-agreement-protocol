//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IEscrow.sol";

contract ClientProof is ERC721PresetMinterPauserAutoId, Ownable {

    address serviceProof;
    mapping(uint256 => address) public escrowUsed;
    string private _baseTokenURI;

    constructor() ERC721PresetMinterPauserAutoId("ClientProof", "CP", "") {
    }

    function mint(uint256 id, address client, address escrow) public virtual {
        require(serviceProof == msg.sender, "Only ServiceProof can mint this proof");
        escrowUsed[id] = escrow;
        super._safeMint(client, id);
    }

    function getAgreementDetails(uint256 id) public view returns(IEscrow.AgreementDetails memory){
        address contractUsed = escrowUsed[id];
        IEscrow.AgreementDetails memory selectedAgreement = IEscrow(contractUsed).getAgreementDetails(serviceProof, id);

        return selectedAgreement;
    }

    function setTokenURI(string memory token_uri) onlyOwner public{
        _baseTokenURI = token_uri;
    }

    function setServiceProof(address _serviceProof) public onlyOwner{
        serviceProof = _serviceProof;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(from == address(0) || to == address(0), "This a Soulbound token. It cannot be transferred. It can only be burned by the token owner.");
    }

}
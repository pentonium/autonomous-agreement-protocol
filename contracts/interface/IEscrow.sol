//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IEscrow{

    struct AgreementDetails{
        uint256 price;
        uint256 fee;
        uint256 status;
        uint256 deadline;
        string ipfs_hash;
        string skills;
        address token;
        address client;
        address service_provider;
        bool mode;
    }


    function createAgreement(address agreement, uint256 agreementId, address client, address service_provider, bool mode, string memory ipfs_hash, string memory skills, uint256 price, address token, uint256 deadline) external;

    function getAgreementDetails(address agreement, uint256 id) external view returns(AgreementDetails memory);
}
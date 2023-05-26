//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IEscrow{

    struct AgreementDetails{
        uint256 price;
        uint256 fee;
        uint256 status;
        string ipfs_hash;
        string skills;
        address token;
        address client;
        address service_provider;
        bool mode;
    }


    function createOrder(address agreement, uint256 agreementId, address client, address service_provider, bool mode, string memory ipfs_hash, string memory skills, uint256 price, address token) external;

    function getAgreementDetails(address agreement, uint256 id) external view returns(AgreementDetails memory);
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IAgreementToken {
    
    struct AgreementDetails{
        uint256 price;
        uint256 time;
        uint256 fee;
        string ipfs_hash;
        bool is_public;
        address token;
        address owner;
        address client;
    }

    function getAgreementDetails(uint256 id) external view returns(AgreementDetails memory);
}
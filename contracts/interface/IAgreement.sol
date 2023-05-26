// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IAgreementToken {
    
    struct AgreementDetails{
        uint256 price;
        uint256 fee;
        uint256 status;
        string ipfs_hash;
        address token;
        address from;
        address to;
        bool mode;
    }

    function getAgreementDetails(uint256 id) external view returns(AgreementDetails memory);
}
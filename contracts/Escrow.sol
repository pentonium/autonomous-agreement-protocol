//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./Agreement.sol";
import "./interface/IERC20.sol";
import "./lib/Routes.sol";

contract Escrow{

    struct AgreementDetails{
        uint256 price;
        uint256 time;
        string ipfs_hash;
        bool is_public;
        address token;
        address owner;
        address client;
    }

    struct UserKeys{
        string private_key;
        string public_key;
    }

    AgreementDetails public agreementDetails;
    AgreementDetails public propsalAgreement;
    UserKeys client_keys;
    UserKeys service_provider_keys;

    address agreement;
    uint256 agId;
    uint256 category_id;
    uint256 status;
    uint256 start_time;

    /**
    status: 100
     */

    constructor (address _agreement, uint256 _agId, uint256 _category_id){
        AgreementToken agreementContract = AgreementToken(_agreement);
        AgreementToken.AgreementDetails memory details = agreementContract.getAgreementDetails(_agId);
        agreementDetails = AgreementDetails(details.price, details.time, details.ipfs_hash, details.is_public, details.token, details.owner, msg.sender);
        status = 100;

        agreement = _agreement;
        agId = _agId;
        category_id = _category_id;
        start_time = block.timestamp;
    }

    modifier onlyClient {
      require(msg.sender == agreementDetails.client);
      _;
   }

    modifier onlyServiceProvider {
      require(msg.sender == agreementDetails.owner);
      _;
   }

   modifier bothParties {
      require(msg.sender == agreementDetails.owner || msg.sender == agreementDetails.client);
      _;
   }

     /** Order can be canceld after a day of no response */
    function cancelOrder() onlyClient public {
        status = 99;
        withdraw();
    }

    /** Service provider can accept the order */
    function acceptOrder(string memory _service_provider_public, string memory _service_provider_private) onlyServiceProvider public {
        require(status == 100, "Can not accept order");
        status = 101;
        // convert tokens to PTM
    }

    /** Service provider can reject the order */
    function rejectOrder() onlyServiceProvider public {
        status = 98;
        withdraw();
    }

    /** Submit a deliver, requires ipfs hash of the chat */
    function deliver(string memory _ipfs_hash) onlyServiceProvider public {
        require(status == 101, "Can not deliver order");
        status = 102;
    }

    /** Accept the delivery and transfer the fund */
    function acceptDelivery() onlyClient public {
        require(status == 102, "Can not accept delivery");
        status = 105;
    }

    /** Create a dispute */
    function dispute() bothParties public {
        require(status < 102 && status > 100, "Can not create dispute");
        status = 200;
    }

    /** Accept the dispute */
    function disputeAccept() bothParties public {
        require(status == 200, "Can not accept dispute");
        status = 201;
    }

    /** Client Private & Public  */
    function getClientRequirements() public view returns (string memory, string memory, string memory){
    }

    /** Service Provider Private & Public  */
    function getServiceProviderRequirements() public view returns (string memory, string memory, string memory){
    }

    function withdraw() private {
        IERC20(agreementDetails.token).transfer(agreementDetails.client, IERC20(agreementDetails.token).balanceOf(address(this)));
    }


    function propseAgreementUpdate(string memory ipfs_hash, uint256 time) bothParties public{
        propsalAgreement = AgreementDetails(agreementDetails.price, time, ipfs_hash, agreementDetails.is_public, agreementDetails.token, agreementDetails.owner, agreementDetails.client);
    }


    function acceptAgreementUpdate() bothParties public {
        status = 101;
        agreementDetails = propsalAgreement;
    }

}
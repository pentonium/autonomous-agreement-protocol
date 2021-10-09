//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./Agreement.sol";
import "./interface/IERC20.sol";
import "./lib/Routes.sol";
import "./interface/IMarshals.sol";

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

    address public agreement;
    address public marshals;
    uint256 public agId;
    uint256 public category_id;
    uint256 public status;
    uint256 public start_time;

    /**
    status: 100
     */

    constructor (address _agreement, uint256 _agId, uint256 _category_id, string memory public_key, string memory private_key){
        AgreementToken agreementContract = AgreementToken(_agreement);
        AgreementToken.AgreementDetails memory details = agreementContract.getAgreementDetails(_agId);
        agreementDetails = AgreementDetails(details.price, details.time, details.ipfs_hash, details.is_public, details.token, details.owner, msg.sender);
        status = 100;

        agreement = _agreement;
        agId = _agId;
        category_id = _category_id;
        start_time = block.timestamp;

        client_keys = UserKeys(public_key, private_key);
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
        require(status == 100, "Can not accept order");
        status = 99;
        withdraw(agreementDetails.client);
    }

    /** Service provider can accept the order */
    function acceptOrder(string memory public_key, string memory private_key) onlyServiceProvider public {
        require(status == 100, "Can not accept order");
        status = 101;
        service_provider_keys = UserKeys(public_key, private_key);
        // convert tokens to PTM
    }

    /** Service provider can reject the order */
    function rejectOrder() onlyServiceProvider public {
        require(status == 100, "Can not accept order");
        status = 98;
        withdraw(agreementDetails.client);
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
    function dispute(string memory mesage_copy) bothParties public {
        require(status < 102 && status > 100, "Can not create dispute");
        status = 200;
    }

    /** Accept the dispute */
    function disputeAccept(string memory mesage_copy) bothParties public {
        require(status == 200, "Can not accept dispute");
        status = 201;
        IMarshals arbitrator = IMarshals(marshals);
        arbitrator.addAgreement();
    }

    function clientWon() public{
        IMarshals arbitrator = IMarshals(marshals);
        require(arbitrator.is_marshal(msg.sender), "Only Marshals can do this");
        require(status == 201, "Can not win before dispute");
        withdraw(agreementDetails.client);
    }

    function ServiceProvidertWon() public{
        IMarshals arbitrator = IMarshals(marshals);
        require(arbitrator.is_marshal(msg.sender), "Only Marshals can do this");
        require(status == 201, "Can not win before dispute");
        withdraw(agreementDetails.owner);
    }

    /** Client Private & Public  */
    function getClientRequirements() onlyClient public view returns (string memory, string memory, string memory){
        return (client_keys.public_key, client_keys.private_key, service_provider_keys.public_key);
    }

    /** Service Provider Private & Public  */
    function getServiceProviderRequirements() onlyServiceProvider public view returns (string memory, string memory, string memory){
        return (service_provider_keys.public_key, service_provider_keys.private_key, client_keys.public_key);
    }

    function withdraw(address user) private {
        IERC20(agreementDetails.token).transfer(user, IERC20(agreementDetails.token).balanceOf(address(this)));
    }


    function propseAgreementUpdate(string memory ipfs_hash, uint256 time) bothParties public{
        propsalAgreement = AgreementDetails(agreementDetails.price, time, ipfs_hash, agreementDetails.is_public, agreementDetails.token, agreementDetails.owner, agreementDetails.client);
    }


    function acceptAgreementUpdate() bothParties public {
        status = 101;
        agreementDetails = propsalAgreement;
    }

}
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./interface/IAgreement.sol";
import "./interface/IERC20.sol";
import "./lib/Routes.sol";
import "./interface/IMarshals.sol";

contract Escrow{

    struct UserKeys{
        string private_key;
        string public_key;
    }

    IAgreementToken.AgreementDetails public agreementDetails;
    IAgreementToken.AgreementDetails public propsalAgreement;
    UserKeys client_keys;
    UserKeys service_provider_keys;

    address public agreement;
    address public marshals;
    address public proxy;

    string private ipfs_hash;
    string private dispute_message;
    string private dispute_confirm_message;

    uint256 public agId;
    uint256 public category_id;
    uint256 public status;
    uint256 public start_time;

    /**
    status: 100
     */

    constructor (address _agreement, uint256 _agId, uint256 _category_id, address client, address _marshals, address _proxy, string memory public_key, string memory private_key){
        IAgreementToken agreementContract = IAgreementToken(_agreement);
        IAgreementToken.AgreementDetails memory details = agreementContract.getAgreementDetails(_agId);
        agreementDetails = IAgreementToken.AgreementDetails(details.price, details.time, details.fee, details.ipfs_hash, details.is_public, details.token, details.owner, client);
        status = 100;

        agreement = _agreement;
        agId = _agId;
        category_id = _category_id;
        start_time = block.timestamp;
        marshals = _marshals;
        proxy = _proxy;

        client_keys = UserKeys(public_key, private_key);
    }

    modifier onlyClient {
      require(msg.sender == agreementDetails.client, "Only client can do it");
      _;
   }

    modifier onlyServiceProvider {
      require(msg.sender == agreementDetails.owner, "Only service provider can do it");
      _;
   }

   modifier bothParties {
      require(msg.sender == agreementDetails.owner || msg.sender == agreementDetails.client, "Only borth parties can do it");
      _;
   }

   modifier onlyProxy {
        require(msg.sender == proxy, "Only proxy contract can do this");
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
        ipfs_hash = _ipfs_hash;
        status = 102;
    }

    /** Accept the delivery and transfer the fund */
    function acceptDelivery() onlyClient public {
        require(status == 102, "Can not accept delivery");

        uint256 amount = IERC20(agreementDetails.token).balanceOf(address(this));

        uint256 fee = 5 * amount / 100;

        IERC20(agreementDetails.token).transfer(agreementDetails.owner, fee);
        IERC20(agreementDetails.token).transfer(agreementDetails.owner, amount - fee);
        status = 105;
    }

    /** Create a dispute */
    function dispute(string memory message_copy) bothParties public {
        require(status < 102 && status > 100, "Can not create dispute");
        dispute_message = message_copy;
        status = 200;
    }

    /** Accept the dispute */
    function disputeAccept(string memory message_copy) bothParties public {
        require(status == 200, "Can not accept dispute");
        status = 201;
        dispute_confirm_message = message_copy;
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


    function propseAgreementUpdate(string memory _ipfs_hash, uint256 time) bothParties public{
        propsalAgreement = IAgreementToken.AgreementDetails(agreementDetails.price, time, agreementDetails.fee, _ipfs_hash, agreementDetails.is_public, agreementDetails.token, agreementDetails.owner, agreementDetails.client);
    }


    function acceptAgreementUpdate() bothParties public {
        status = 101;
        agreementDetails = propsalAgreement;
    }

    function updateMarshals(address _marshals) onlyProxy public{
        marshals = _marshals;
    }

    function deliveryHash() public view returns (string memory){
        require(msg.sender == agreementDetails.owner || msg.sender == agreementDetails.client || msg.sender == marshals);
        return ipfs_hash;
    }

    function disputeMessage() public view returns (string memory){
        require(msg.sender == agreementDetails.owner || msg.sender == agreementDetails.client || msg.sender == marshals);
        return dispute_message;
    }

    function disputeMessageConfirm() public view returns (string memory){
        require(msg.sender == agreementDetails.owner || msg.sender == agreementDetails.client || msg.sender == marshals);
        return dispute_confirm_message;
    }

}
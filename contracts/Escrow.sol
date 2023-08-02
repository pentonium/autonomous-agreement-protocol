//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./interface/IEscrow.sol";
import "./interface/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Escrow is Ownable{

    // mode: true -> freelancer false -> Client

    mapping(address => mapping(uint256 => IEscrow.AgreementDetails)) agreementDetail;
    mapping(address => mapping(uint256 => string)) public deliveries;

    address public marshal;
    uint256 public fee;

    // 100, 99, 98, 101, 102 (Create, Cancel, Reject, Signed, Deliverd)
    // 200, 201 (Fund Released, Dispute Resolved)
    // 90 ( Disputed )
    uint256 public constant CREATED = 100;
    uint256 public constant CANCELLED = 99;
    uint256 public constant REJECTED = 98;
    uint256 public constant SIGNED = 101;
    uint256 public constant DELIVERD = 102;
    uint256 public constant RELEASED = 105;
    uint256 public constant DISPUTE_RESOLVED = 201;
    uint256 public constant DISPUTED = 200;

    /** Defining all the possible events */
    event AgreementUpdated(address agreement, uint256 agreementId, address client, address service_provider);

    constructor(){
        //setting dedault fee to be 5%
        fee = 500;
    }

   function createAgreement(address agreement, uint256 agreementId, address client,  address service_provider, bool mode, string memory ipfs_hash, string memory skills, uint256 price, address token, uint256 deadline) public{
        require(client != service_provider, "Can not create an agreement with yourself");
        if(!mode){
            require(IERC20(token).transferFrom(client, address(this), price), "Must transfer the funds");
        }
        agreementDetail[agreement][agreementId] = IEscrow.AgreementDetails(price, fee, CREATED, deadline, ipfs_hash, skills, token, client, service_provider, mode);

        emit AgreementUpdated(agreement, agreementId, client,  service_provider);
   }


    function cancelAgreement(address agreement, uint256 agreementId) public {
        IEscrow.AgreementDetails memory selectedAgreement = agreementDetail[agreement][agreementId];

        require(selectedAgreement.status == CREATED, "Only Created orders can be canceled");
        require(msg.sender == selectedAgreement.client, "Only Client can cancel it");

        if(!selectedAgreement.mode){
            IERC20(selectedAgreement.token).transfer(selectedAgreement.client, selectedAgreement.price);
        }

        _updateAgreement(CANCELLED, selectedAgreement.skills, agreement, agreementId);
    }


    function rejectAgreement(address agreement, uint256 agreementId) public {
        IEscrow.AgreementDetails memory selectedAgreement = agreementDetail[agreement][agreementId];
        require(selectedAgreement.status == CREATED, "Only Created orders can be canceled");
        require(msg.sender == selectedAgreement.service_provider, "Only Service provider can reject it");
        _updateAgreement(REJECTED, selectedAgreement.skills, agreement, agreementId);

        if(!selectedAgreement.mode){
            IERC20(selectedAgreement.token).transfer(selectedAgreement.client, selectedAgreement.price);
        }
    }


    function signAgreement(address agreement, uint256 agreementId, string memory skills) public {
        IEscrow.AgreementDetails memory selectedAgreement = agreementDetail[agreement][agreementId];
        require(selectedAgreement.status == CREATED, "Only Created orders can be accepted");

        if(selectedAgreement.mode){
            require(msg.sender == selectedAgreement.client, "Only Client can accept it");
            require(IERC20(selectedAgreement.token).transferFrom(selectedAgreement.client, address(this), selectedAgreement.price), "Must transfer the funds");
            _updateAgreement(SIGNED, selectedAgreement.skills, agreement, agreementId);

        }else{
            require(msg.sender == selectedAgreement.service_provider, "Only Service provider can accept it");
            _updateAgreement(SIGNED, skills, agreement, agreementId);
        }
    }

    /** Once signed by both parties, a proof of work can be submitted to the client */
    function submitDelivery(address agreement, uint256 agreementId, string memory delivery) public {
        IEscrow.AgreementDetails memory selectedAgreement = agreementDetail[agreement][agreementId];
        require(msg.sender == selectedAgreement.service_provider, "Only Service Provider can submit it");
        require(selectedAgreement.status == SIGNED || selectedAgreement.status == DELIVERD, "Only Accepted orders can be closed");

        deliveries[agreement][agreementId] = delivery;

        _updateAgreement(DELIVERD, selectedAgreement.skills, agreement, agreementId);
    }

    /** Accept the delivery and transfer the fund */
    function releaseFunds(address agreement, uint256 agreementId, string memory skills) public {
        IEscrow.AgreementDetails memory selectedAgreement = agreementDetail[agreement][agreementId];
        require(selectedAgreement.status == DELIVERD, "Only Deliverd orders can be closed");
        require(msg.sender == selectedAgreement.client, "Only Client can release funds");

        uint256 pentoniumFee = (fee * selectedAgreement.price) / 10000;

        IERC20(selectedAgreement.token).transfer(owner(), pentoniumFee);
        IERC20(selectedAgreement.token).transfer(selectedAgreement.service_provider, selectedAgreement.price - pentoniumFee);

        _updateAgreement(RELEASED, skills, agreement, agreementId);
    }


    function raiseDispute(address agreement, uint256 agreementId) public {
        IEscrow.AgreementDetails memory selectedAgreement = agreementDetail[agreement][agreementId];
        require(selectedAgreement.status == SIGNED || selectedAgreement.status == DELIVERD, "Only Accepted or Deliverd orders can be disputed");
        require(msg.sender == selectedAgreement.service_provider || msg.sender == selectedAgreement.client, "Only Clinent / Service Provider raise disputed");
        _updateAgreement(DISPUTED, selectedAgreement.skills, agreement, agreementId);
    }


    /** Marshal can resolve the dispute. */
    function resolveDispute(address agreement, uint256 agreementId, uint256 sendPercent) public {

        require(msg.sender == marshal, "Only a marshal can resolve this dispute");

        IEscrow.AgreementDetails memory selectedAgreement = agreementDetail[agreement][agreementId];
        require(selectedAgreement.status == DISPUTED, "Only release funds if disputed");

        uint256 pentoniumFee = (fee * selectedAgreement.price) / 10000;
        uint256 afterFee = selectedAgreement.price - pentoniumFee;

        uint256 serviceProviderAmount = (afterFee * sendPercent) / 10000;
        uint256 clienAmount = afterFee - serviceProviderAmount;
        
        IERC20(selectedAgreement.token).transfer(selectedAgreement.service_provider, serviceProviderAmount);
        IERC20(selectedAgreement.token).transfer(selectedAgreement.client, clienAmount);

        _updateAgreement(DISPUTE_RESOLVED, selectedAgreement.skills, agreement, agreementId);
    }

    function updateMarshals(address _marshal) onlyOwner public{
        marshal = _marshal;
    }

    function updateFees(uint256 _fee) onlyOwner public{
        fee = _fee;
    }

    function _updateAgreement(uint256 status, string memory skills, address agreement, uint256 id) private{
        IEscrow.AgreementDetails memory selectedAgreement = agreementDetail[agreement][id];

        agreementDetail[agreement][id] = IEscrow.AgreementDetails(
            selectedAgreement.price,
            selectedAgreement.fee,
            status,
            selectedAgreement.deadline,
            selectedAgreement.ipfs_hash,
            skills,
            selectedAgreement.token,
            selectedAgreement.client,
            selectedAgreement.service_provider,
            selectedAgreement.mode
        );

        emit AgreementUpdated(agreement, id, selectedAgreement.client, selectedAgreement.service_provider);
    }

    function getAgreementDetails(address agreement, uint256 id) public view returns(IEscrow.AgreementDetails memory){
        IEscrow.AgreementDetails memory selectedAgreement = agreementDetail[agreement][id];

        return selectedAgreement;
    }

    function hasAccessToDelivery(address agreement, uint256 id, address user) public view returns(bool){
        IEscrow.AgreementDetails memory selectedAgreement = agreementDetail[agreement][id];

        if(user == selectedAgreement.client) return true;
        else if(user == selectedAgreement.service_provider) return true;
        else if(user == marshal && selectedAgreement.status == 90) return true;
        else return false;
    }
}
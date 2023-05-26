//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./interface/IEscrow.sol";
import "./interface/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Escrow is Ownable{

    // mode: true -> freelancer false -> Client

    mapping(address => mapping(uint256 => IEscrow.AgreementDetails)) agreementDetail;
    mapping(address => bool) public whitelistedAgreements;

    address public marshal;
    uint256 public fee;

    /** Defining all the possible events */
    event AgreementCreated(address agreement, uint256 agreementId, address client,  address service_provider, bool mode, uint256 price, address token);
    event AgreementSigned(address agreement, uint256 agreementId, address signedBy, address agreementOf);
    event AgreementCancelled(address agreement, uint256 agreementId, address cancelledBy, address agreementOf);
    event AgreementSuccessfullyClosed(address agreement, uint256 agreementId, address client,  address service_provider);
    event DisputeRaised(address agreement, uint256 agreementId, address raisedBy, address against);
    event DisputeResolved(address agreement, uint256 agreementId, address client, address service_provider);

   function createOrder(address agreement, uint256 agreementId, address client,  address service_provider, bool mode, string memory ipfs_hash, string memory skills, uint256 price, address token) public{
        require(client != service_provider, "Can not create an agreement with yourself");
        if(!mode){
            require(IERC20(token).transferFrom(client, address(this), price), "Must transfer the funds");
        }
        agreementDetail[agreement][agreementId] = IEscrow.AgreementDetails(price, fee, 100, ipfs_hash, skills, token, client, service_provider, mode);

        emit AgreementCreated(agreement, agreementId, client,  service_provider, mode, price, token);
   }

     /** Order can be canceld after a day of no response */
    function cancelOrder(address agreement, uint256 agreementId) public {
        IEscrow.AgreementDetails memory selectedAgreement = agreementDetail[agreement][agreementId];

        require(selectedAgreement.status == 100, "Only Created orders can be canceled");
        require(msg.sender == selectedAgreement.client, "Only Client can cancel it");

        if(!selectedAgreement.mode){
            IERC20(selectedAgreement.token).transfer(selectedAgreement.client, selectedAgreement.price);
        }

        _setAgreementStatus(99, agreement, agreementId);
        emit AgreementCancelled(agreement, agreementId, selectedAgreement.client, selectedAgreement.service_provider);
    }

    /** Service provider can accept the order */
    function acceptOrder(address agreement, uint256 agreementId, string memory skills) public {
        IEscrow.AgreementDetails memory selectedAgreement = agreementDetail[agreement][agreementId];
        require(selectedAgreement.status == 100, "Only Created orders can be accepted");

        if(selectedAgreement.mode){
            require(msg.sender == selectedAgreement.client, "Only Client can accept it");
            require(IERC20(selectedAgreement.token).transferFrom(selectedAgreement.client, address(this), selectedAgreement.price), "Must transfer the funds");
            _setAgreementStatus(101, agreement, agreementId);

            emit AgreementSigned(agreement, agreementId, selectedAgreement.client, selectedAgreement.service_provider);
        }else{
            require(msg.sender == selectedAgreement.service_provider, "Only Service provider can accept it");
                agreementDetail[agreement][agreementId] = IEscrow.AgreementDetails(
                selectedAgreement.price,
                selectedAgreement.fee,
                101,
                selectedAgreement.ipfs_hash,
                skills,
                selectedAgreement.token,
                selectedAgreement.client,
                selectedAgreement.service_provider,
                selectedAgreement.mode
            );
            emit AgreementSigned(agreement, agreementId, selectedAgreement.service_provider, selectedAgreement.client);
        }
    }

    /** Service provider can reject the order */
    function rejectOrder(address agreement, uint256 agreementId) public {
        IEscrow.AgreementDetails memory selectedAgreement = agreementDetail[agreement][agreementId];
        require(selectedAgreement.status == 100, "Only Created orders can be canceled");
        require(msg.sender == selectedAgreement.service_provider, "Only Service provider can reject it");
        _setAgreementStatus(98, agreement, agreementId);

        if(!selectedAgreement.mode){
            IERC20(selectedAgreement.token).transfer(selectedAgreement.client, selectedAgreement.price);
        }
        emit AgreementCancelled(agreement, agreementId, selectedAgreement.service_provider, selectedAgreement.client);
    }

    /** Accept the delivery and transfer the fund */
    function releaseFunds(address agreement, uint256 agreementId, string memory skills) public {
        IEscrow.AgreementDetails memory selectedAgreement = agreementDetail[agreement][agreementId];
        require(selectedAgreement.status == 101, "Only Accepted orders can be closed");
        require(msg.sender == selectedAgreement.client, "Only Client can release funds");

        uint256 pentoniumFee = (2 * selectedAgreement.price) / 100;

        IERC20(selectedAgreement.token).transfer(owner(), pentoniumFee);
        IERC20(selectedAgreement.token).transfer(selectedAgreement.service_provider, selectedAgreement.price - pentoniumFee);

        agreementDetail[agreement][agreementId] = IEscrow.AgreementDetails(
                selectedAgreement.price,
                selectedAgreement.fee,
                105,
                selectedAgreement.ipfs_hash,
                skills,
                selectedAgreement.token,
                selectedAgreement.client,
                selectedAgreement.service_provider,
                selectedAgreement.mode
            );
        emit AgreementSuccessfullyClosed(agreement, agreementId, selectedAgreement.client,  selectedAgreement.service_provider);
    }

    /** Create a dispute */
    function raiseDispute(address agreement, uint256 agreementId) public {
        IEscrow.AgreementDetails memory selectedAgreement = agreementDetail[agreement][agreementId];
        require(selectedAgreement.status == 101, "Only Accepted orders can be disputed");
        require(msg.sender == selectedAgreement.service_provider || msg.sender == selectedAgreement.client, "Only Clinent / Service Provider raise disputed");
        _setAgreementStatus(200, agreement, agreementId);

        emit DisputeRaised(agreement, agreementId, msg.sender, msg.sender == selectedAgreement.service_provider ? selectedAgreement.client: selectedAgreement.service_provider);
    }

    /** Accept the dispute */
    function forceReleaseFunds(address agreement, uint256 agreementId, uint256 sendPercent) public {

        require(msg.sender == marshal, "Only a marshal can resolve this dispute");

        IEscrow.AgreementDetails memory selectedAgreement = agreementDetail[agreement][agreementId];
        require(selectedAgreement.status == 200, "Only release funds if disputed");

        uint256 serviceProviderAmount = (selectedAgreement.price * sendPercent) / 100;
        uint256 clienAmount = selectedAgreement.price - serviceProviderAmount;
        
        IERC20(selectedAgreement.token).transfer(selectedAgreement.service_provider, serviceProviderAmount);
        IERC20(selectedAgreement.token).transfer(selectedAgreement.client, clienAmount);

        _setAgreementStatus(201, agreement, agreementId);
        emit DisputeResolved(agreement, agreementId, selectedAgreement.client, selectedAgreement.service_provider);
    }

    function updateMarshals(address _marshal) onlyOwner public{
        marshal = _marshal;
    }

    function _setAgreementStatus(uint256 status, address agreement, uint256 id) private{
        IEscrow.AgreementDetails memory selectedAgreement = agreementDetail[agreement][id];

        agreementDetail[agreement][id] = IEscrow.AgreementDetails(
            selectedAgreement.price,
            selectedAgreement.fee,
            status,
            selectedAgreement.ipfs_hash,
            selectedAgreement.skills,
            selectedAgreement.token,
            selectedAgreement.client,
            selectedAgreement.service_provider,
            selectedAgreement.mode
        );
    }

    function getAgreementDetails(address agreement, uint256 id) public view returns(IEscrow.AgreementDetails memory){
        IEscrow.AgreementDetails memory selectedAgreement = agreementDetail[agreement][id];

        return selectedAgreement;
    }

}
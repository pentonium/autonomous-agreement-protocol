// Sources flattened with hardhat v2.6.1 https://hardhat.org

// File contracts/interface/IAgreement.sol

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


// File contracts/interface/IERC20.sol




/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/lib/Routes.sol




contract Routes{

    mapping(address => address[]) public routes;


    function addNewRoute(address token, address[] memory path) public{
        routes[token] = path;
    }
}


// File contracts/interface/IMarshals.sol



interface IMarshals{

    function is_marshal(address) external view returns (bool);

    function addAgreement() external;
}


// File contracts/Escrow.sol







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


// File contracts/Proxy.sol




contract Proxy{

    function placeOrder(address agreement, uint256 id, uint256 category_id, address client, address marshals, string memory public_key, string memory private_key) public returns (address){
        Escrow order = new Escrow(agreement, id, category_id, client, marshals, address(this), public_key, private_key);

        return address(order);
    }

    function updateMarshals(address marshals, address escrow) public{
        Escrow(escrow).updateMarshals(marshals);
    }
}

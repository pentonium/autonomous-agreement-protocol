// Sources flattened with hardhat v2.6.1 https://hardhat.org

// File contracts/interface/IEscrow.sol

//SPDX-License-Identifier: MIT
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


// File @openzeppelin/contracts/utils/Context.sol@v4.3.0





/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/Ownable.sol@v4.3.0





/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/Escrow.sol






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

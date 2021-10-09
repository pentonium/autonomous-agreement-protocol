pragma solidity ^0.8.0;

interface IMarshals{

    function is_marshal(address) external view returns (bool);

    function addAgreement() external;
}
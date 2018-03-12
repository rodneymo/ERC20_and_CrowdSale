pragma solidity ^0.4.18;


contract Ownable {

    event EventOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner returns (bool) {
        require(msg.sender != address(0));
        EventOwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }

}

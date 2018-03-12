pragma solidity ^0.4.18;

import "./Ownable.sol";
import "./SafeMath.sol";


contract MyToken is Ownable {
    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 public _totalSupply = 0; // 100 Million tokens
    string public  symbol = "OGP";
    string public  name = "OUR GREEN POWER";
    uint8 public  decimals = 0;
    //uint256 public exchangeRate =  476190476190476; // 1 EPG = 1/2100 ETHER = 476190476190476 wei

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    function MyToken() public {
    }

    function() public {
        revert();
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns(uint256) {
        return balances[_owner];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address _owner, address to) public view returns (uint256) {
        return allowed[_owner][to];
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {

        require(to != address(0));
        require(balances[from] >= value);
        require(allowed[from][msg.sender] >= value);
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        Transfer(from, to, value);
        return true;

    }

}

pragma solidity ^0.4.18;

import "./MyToken.sol";
import "./Ownable.sol";


contract MyMintableToken is Ownable, MyToken {
// TODO
// add safe SafeMath
    event Mint(address indexed to, uint256 amount);
    event MintDisabled();

    bool public mintEnabled = true;

    modifier canMint() {
        require(mintEnabled);
        _;
    }

    function minting(address _receiver, uint256 _amount)  public onlyOwner canMint returns(uint256) {
        balances[_receiver] = balances[_receiver].add(_amount);
        _totalSupply = _totalSupply.add(_amount);
        Mint(_receiver, _amount);
        return _amount;
    }

    function disableMinting() public onlyOwner canMint returns(bool) {
        mintEnabled = false;
        MintDisabled();
        return true;
    }

}

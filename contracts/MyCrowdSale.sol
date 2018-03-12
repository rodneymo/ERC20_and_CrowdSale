pragma solidity ^0.4.18;

import "./Ownable.sol";
import "./MyMintableToken.sol";
import "./SafeMath.sol";


contract MyCrowdSale is Ownable {


    using SafeMath for uint256;
    enum State { NotStarted, PreSale, GeneralSale, Successful, Refund, Closed }

    event TokensPurchase(address indexed _buyer, uint256 _weiAmount, uint256 _numTokens);
    event TokensCollected(address indexed buyer, uint256 amount);
    event RefundFundsLoaded(address indexed wallet, uint256 amount);
    event RefundProcessed(address indexed buyer, uint256 amount);
    event UpdatedSaleLimits(uint256, uint256);
    event UpdatedExchangeRates(uint256, uint256);
    event FundsTransferred(address indexed _wallet, uint256 _weiAmount);
    event PreSaleOpened();
    event PreSaleClosed();
    event GeneralSaleOpened();
    event GeneralSaleClosed();
    event CrowdSaleClosed();
    event FundingTargetReached();
    event FundingTargetFailed();
    event RefundingStarted();

// TODO
//add loadRefund logic. This accepts ETHER from external account in order to process refunds

    MyMintableToken public token;
    bool public halted;
    uint256 public preSaleStartTime = 0;
    uint256 public preSaleEndTime = 0;
    uint256 public generalSaleStartTime = 0;
    uint256 public generalSaleEndTime = 0;

    State public state = State.NotStarted;
    uint256 constant public GENERAL_SALE_DURATION = 90 * 1 days;
    uint256 constant public PRE_SALE_DURATION = 15 * 1 days;
    uint256  public minimumFunding = 400000000000000000000;    //1 million tokens = 400 ETHER
    uint256  public maximumFunding = 47543000000000000000000; // 100 million tokens
    uint256  public preSaleExchangeRateinWei = 400000000000000; // 1 EPG = 1/2500 ETHER = 476190476190476 wei
    uint256  public generalSaleExchangeRateinWei = 476190476190476; // 1 EPG = 1/2100 ETHER = 476190476190476 wei

    address public wallet = 0xa6746c27172bc4b23b33f4597cea5f10cc4f65fe; // address where funds will be during the crowdsale is closed

    uint256 internal fundsRaisedInWei = 0; // in wei
    uint256 internal totalRefundedInWei = 0;
    uint256 internal tokensIssued = 0;
    uint256 internal tokensCollected = 0;
    uint256 internal refundPool = 0;

    mapping (address => uint256) internal investedAmount;
    mapping (address => uint256) internal allocatedTokens;

    function MyCrowdSale(address _tokenAddress, uint256 _startTime) public {
        require(_startTime >= now);
        //require(endTime >= startTime);
        //require(exchangeRate > 0);
        require(state == State.NotStarted);
        token = MyMintableToken(_tokenAddress);
        preSaleStartTime = _startTime;
        preSaleEndTime = preSaleStartTime.add(PRE_SALE_DURATION);
        halted = false;
        state = State.NotStarted;
        //tokenContractOwner = _tokenContractOwner;
        //token = new MyMintableToken();
    }

    function() external payable {
        buyTokens(msg.sender, msg.value);
    }

    function haltSale()  public  onlyOwner returns(bool) {
        require(state != State.Closed);
        require(!halted);
        halted = true;
        return true;
    }

    function resumeSale()  public onlyOwner returns(bool) {
        require(state != State.Closed);
        require(halted);
        halted = false;
        return false;
    }

    function openPreSale() public onlyOwner {
        require(state == State.NotStarted);
        state = State.PreSale;
        PreSaleOpened();
    }

    // close pre-sale and open general sale
    function closePreSale() public onlyOwner {
        require(state == State.PreSale);
        state = State.GeneralSale;
        generalSaleStartTime = now;
        generalSaleEndTime = generalSaleStartTime.add(GENERAL_SALE_DURATION);
        PreSaleClosed();
        GeneralSaleOpened();
    }

    function closeGeneralSale() public onlyOwner {
        require(state == State.GeneralSale);
        //require(fundsRaised == 0); // can only close funding after tokens are moved
        if (fundsRaisedInWei >= minimumFunding) {
            state = State.Successful;
            FundingTargetReached();
        } else {
            state = State.Refund;
            FundingTargetFailed();
            RefundingStarted();
        }
        GeneralSaleClosed();
    }

    function closeCrowdSale() public onlyOwner {
        //require(fundsRaisedInWei == totalRefundedInWei); // can only close funding after tokens are collected
        require(state == State.Successful || state == State.Refund);
        if (state == State.Successful) {
            require(fundsRaisedInWei == 0); //sale can only be closed after all the funds are transferred.
            require(tokensCollected == tokensIssued);
        }
        if (state == State.Refund) {
            require(fundsRaisedInWei == totalRefundedInWei); // all funds have been returned
            require(tokensCollected == 0);
        }
        state == State.Closed;
        CrowdSaleClosed();
    }

    function updateSaleLimits(uint256 _softcap, uint256 _hardcap) public onlyOwner returns(bool) {
        require(state == State.PreSale || state == State.GeneralSale);
        require(halted);
        minimumFunding = _softcap;
        maximumFunding = _hardcap;
        UpdatedSaleLimits(_softcap, _hardcap);
        return true;
    }

    function updateExchangeRates(uint256 preSaleXRATE, uint256 generalSaleXRATE) public onlyOwner returns(bool) {
        require(state == State.PreSale || state == State.GeneralSale);
        require(halted);
        preSaleExchangeRateinWei = preSaleXRATE;
        generalSaleExchangeRateinWei = generalSaleXRATE;
        UpdatedExchangeRates(preSaleXRATE, generalSaleXRATE);
        return true;
    }

    function collectTokens() public returns(bool) {
        require(state == State.Successful);
        require(allocatedTokens[msg.sender] > 0);
        uint256 amount = allocatedTokens[msg.sender];
        if (token.minting(msg.sender, amount) == amount) {
            allocatedTokens[msg.sender] == 0;
            tokensCollected = tokensCollected.add(amount);
            TokensCollected(msg.sender, amount);
            return true;
        } else {
            return false;
        }
    }

    function loadRefund() public onlyOwner payable {
        require(state == State.Refund);
        wallet.transfer(msg.value);
        RefundFundsLoaded(wallet, msg.value);
    }

    function collectRefund() public payable {
        require(state == State.Refund);
        require(investedAmount[msg.sender] > 0);
        uint256 refundAmountInWei = investedAmount[msg.sender];
        (msg.sender).transfer(refundAmountInWei);
        RefundProcessed(msg.sender, refundAmountInWei);
    }

    function buyTokens(address buyer, uint256 weiAmount) public payable {
        require(checkPreSaleOn() || checkGeneralSaleOn());
        require(!halted);
        require(buyer != address(0));
        require(weiAmount > 0);
        require(weiAmount % 1 ether == 0); // only integer numbers
        uint256 numTokens;

        if (state == State.PreSale) {
            require(weiAmount <= 20000000000000000000); // max 20 ETHER
            numTokens = weiAmount.div(preSaleExchangeRateinWei);
        }
        if (state == State.GeneralSale) {
            require(weiAmount <= 20000000000000000000); // max 20 ETHER
            numTokens = weiAmount.div(generalSaleExchangeRateinWei);
        }

        investedAmount[buyer] = investedAmount[buyer].add(weiAmount);
        fundsRaisedInWei = fundsRaisedInWei.add(weiAmount);

        tokensIssued = tokensIssued.add(numTokens);
        allocatedTokens[buyer] = allocatedTokens[buyer].add(numTokens);
        TokensPurchase(buyer, weiAmount, numTokens);

        if (fundsRaisedInWei + weiAmount >= maximumFunding) {
            closePreSale();
            closeGeneralSale();
        }

        wallet.transfer(weiAmount);
    }

    function checkPreSaleOn() internal view returns(bool) {
        bool saleOn = (preSaleStartTime <= now && preSaleEndTime >= now);
        bool stateOK = (state == State.PreSale);
        bool capNotReached = (fundsRaisedInWei < maximumFunding);
        return saleOn && stateOK && capNotReached;
    }

    function checkGeneralSaleOn() internal view returns(bool) {
        bool saleOn = (generalSaleStartTime <= now && generalSaleEndTime >= now);
        bool stateOK = (state == State.GeneralSale);
        bool capNotReached = (fundsRaisedInWei < maximumFunding);
        return saleOn && stateOK && capNotReached;
    }



}

var Web3 = require('web3');
var sleep = require('sleep');
var assert = require('assert');

var web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));

const coinbase = web3.eth.coinbase;
const pwd = "123";
var numAccounts = web3.personal.listAccounts.length;
var numberOfNewAccounts = 4;
var txList = new Array();
console.log("Setting up test environment...");

if(isNaN(numAccounts)) {
	console.log('This is not number');
}
else {
	console.log("Number of existing accounts: " + numAccounts);
}

//setup accounts
for (i=0; i<numberOfNewAccounts; i++) {
	index = numAccounts + i;
	try {
		//create account
		account = web3.personal.newAccount(pwd);
		console.log("creating new account["+ index + "]: " + account);
		if (web3.personal.unlockAccount(account,pwd,2592000)) {
					console.log("Account " + account + " unlocked.");
		};
		//transfer 1000 ether from coinbase
		var tx = {from: coinbase, to: account, value: web3.toWei(1000, "ether") };
		txHash = web3.personal.sendTransaction(tx, pwd);
		txList.push(txHash);
		console.log("Load 1000 ether to new account. Tx: " + txHash);

	} catch(e) {
  		console.log(e);
  		return;
	}
}

for (i=0; i<txList.length; i++) {
	while (!(receipt = web3.eth.getTransactionReceipt(txList[i]))) {
			console.log("Waiting a mined block to include your contract... currently in block " + web3.eth.blockNumber);
			sleep.sleep(10);
	}
	console.log("Transaction "+ txList[i] +" has been processed");
	var _amount = web3.fromWei(web3.eth.getBalance(receipt.to),'ether').toNumber();
	console.log("Balance in " + receipt.to +": " + _amount);
	assert(_amount == 1000, "There's NO 1000 ether in " + receipt.to);
}

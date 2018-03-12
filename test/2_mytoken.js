const Token = artifacts.require("./contracts/MyMintableToken.sol");

contract('Token', async function(accounts) {
				// read total supply
				it("Should have 0 tokens in contract totalSupply", async function() {
			  		let instance = await Token.deployed();
						let supply = await instance._totalSupply.call();
						//console.log(supply.valueOf());
						assert.equal(supply.valueOf(), 0, "0 wasn't in the first account");
				});
				// mint tokens
				it("Owner should be able to mint tokens", async function() {
					 	let balance;
 			  		let instance = await Token.new();
						//console.log("Token address: "+ instance.address);
						//console.log("accounts[1]:" + accounts[1]);
						try {
								let tx = await instance.minting(accounts[1], 99);
								//console.log("Tx: "+tx);
								balance = await instance.balanceOf.call(accounts[1]);
						}
						catch(err) {
								//console.log(err);
								balance = 0;
						}
						//console.log("Amount minted: " + balance);
						assert.equal(balance.valueOf(), 99, "no tokens minted to account[1]");
				});
				// mint tokens
	 			it("Non-owner should NOT be able to mint tokens", async function() {
						let balance;
						let instance = await Token.new();
						try {
								await instance.minting(accounts[2], 99, {from: accounts[1]});
								balance = await instance.balanceOf.call(accounts[2]);
						}
						catch(err){
								balance = 0;
						}
						//console.log("Amount minted: " + );
						assert.equal(balance.valueOf(), 0, "tokens have been minted to account[2]");
		   	});
			 	// check contract owner
				it("Should have coinbase as owner", async function() {
 			  		let instance = await Token.new();
 						let _owner = await instance.owner.call();
 						//console.log(_owner);
 						assert.equal(accounts[0], _owner, "coinbase is not the owner");
 			  });
				// transfer ownership
				it("Should not allow non-owner to transfer ownership", async function() {
 			  		let instance = await Token.new();
 						try {
								await instance.transferOwnership(accounts[1], {from: accounts[1]});
						}
						catch(err){
								//console.log("Failed to transfer contract ownership");
						}
						let _owner = await instance.owner.call();
						//console.log(_owner);
						assert.equal(accounts[0], _owner, "coinbase is no longer the owner");
				});
				// transfer ownership
				it("Should change contract ownership to account[1]", async function() {
 			  		let instance = await Token.new();
 						await instance.transferOwnership(accounts[1], {from: accounts[0]});
						let _owner = await instance.owner.call();
 						//console.log(_owner);
 						assert.equal(accounts[1], _owner, "account[1] is the new owner");
						assert.notEqual(accounts[0], _owner, "account[0] is still the owner");
 			  });
				// test Transfer function
				it("Should transfer some tokens from coinbase to account[2]", async function(){
						let instance = await Token.new();
						await instance.minting(accounts[0],1000);
						await instance.transfer(accounts[2],100);
						let balance = await instance.balanceOf.call(accounts[2]);
						assert.equal(balance,100, "There are no 100 tokens in account[2]");
				});
				it("Cannot transfer from account[2] because it has no tokens", async function(){
						let balance;
						let instance = await Token.new();
						try {
								await instance.transfer(accounts[2],100, {from: accounts[1]});
								balance = await instance.balanceOf.call(accounts[2]);
						}
						catch(e) {
								balance = 0;
						}
						assert.equal(balance,0, "There are no 100 tokens in account[2]");
				});
				// test approve function
				it("account[0] approves account[2] as spender with a 100 allowance", async function() {
						let instance = await Token.new();
						let limit;
						await instance.approve(accounts[2],100);
						limit = await instance.allowance(accounts[0],accounts[2]);
						//console.log("allownace[0][1]=" + limit);
						assert.equal(limit,100,"allowance is NOT 100 tokens");
				});
				// test TransferFrom function
				it("account[2] transfers 50 token to account[3] on behalf of account[0]", async function() {
						let instance = await Token.new();
						let balance;
						let limit;
						await instance.minting(accounts[0],100);
						await instance.approve(accounts[2],100);
						limit = await instance.allowance(accounts[0],accounts[2]);
						//console.log("allownace[0][1]=" + limit);
						assert.equal(limit,100,"allowance is NOT 100 tokens");
						await instance.transferFrom(accounts[0],accounts[3],50, {from: accounts[2]});
						limit = await instance.allowance(accounts[0],accounts[2]);
						//console.log("allownace[0][2]=" + limit);
						assert.equal(limit,50,"allowance is NOT 50 tokens");
						balance = instance.balanceOf.call(accounts[0]);
						assert.equal(limit,50,"balance of account[0] is NOT 50 tokens");
						balance = instance.balanceOf.call(accounts[3]);
						assert.equal(limit,50,"balance of account[3] is NOT 50 tokens");
				});
				it("account[2] transfers 50 token to account[3] on behalf of account[0]", async function() {
						let instance = await Token.new();
						let balance;
						let limit;
						await instance.minting(accounts[0],100);
						await instance.approve(accounts[2],100);
						limit = await instance.allowance(accounts[0],accounts[2]);
						//console.log("allownace[0][1]=" + limit);
						assert.equal(limit,100,"allowance is NOT 100 tokens");
						try {
								await instance.transferFrom(accounts[0],accounts[3],50, {from: accounts[3]});
						}
						catch(e){
								limit = await instance.allowance(accounts[0],accounts[2]);
								assert.equal(limit,100,"allowance is NOT 100 tokens");
								balance = instance.balanceOf.call(accounts[0]);
								assert.equal(limit,100,"balance of account[0] is NOT 100 tokens");
								balance = instance.balanceOf.call(accounts[3]);
								assert.equal(limit,0,"balance of account[3] is NOT 0 tokens");
						}
				});
})

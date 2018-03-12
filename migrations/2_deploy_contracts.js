timeStamp = Math.floor(new Date()/1000);
timeStamp += 1000;

var token = artifacts.require("./MyMintableToken.sol");
var crowdsale = artifacts.require("./MyCrowdSaleV2.sol");


module.exports = function(deployer) {
  deployer.deploy(token).then(function(){
  		console.log("Start time: " + timeStamp);
  		console.log("Token address: " + token.address);
        deployer.deploy(crowdsale, token.address, timeStamp);
  });

// deploy contracts independetly
//deployer.deploy(token);
//deployer.deploy(crowdsale, 0x643C343c56F7D0EcE4C1CE50ee70E69dEEFe2Fd6, timeStamp);
};

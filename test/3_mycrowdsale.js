const CrowdSale = artifacts.require('./contracts/MyCrowdSaleV2.sol');

contract('CrowdSale', async function(accounts){
    it("Status should be Not Started", async function(){
        let instance = await CrowdSale.new();
    })
})

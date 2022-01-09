var Crowdsale = artifacts.require("./Crowdsale.sol");
var Queue = artifacts.require("./Queue.sol");
var Token = artifacts.require("./Token.sol");
var Migrations = artifacts.require("./Migrations.sol");

var currentTime = Math.floor(Date.now() / 1000);
var hours12inSeconds = 60*60*12;
var saleEndTime = currentTime+hours12inSeconds;
var initialSupply = 123456789;
var ratio = 10;	//  (1/10**17) ETHER = (1/10**8) GWEI = (10 WEI) = 1 TOKEN


var queueSize = 5;

// Since the Queue contract uses Crowdsale.address this 
// creates a race condition. The race is resolved by waiting
// for Crowdsale to deploy first and then deploy Queue.
// The same logic is used to deploy the Token contract. 
// These will probably change and maybe the Token and Queue
// contracts will not even get deployed from this deployer.
module.exports = function(deployer, network, accounts) {

	// 5 = queueSize = max num of Buyers
	deployer.deploy(Crowdsale, saleEndTime, initialSupply, ratio,	queueSize);

	// This is NOT NEEDED. It is only added for testing purposes.
	// Check the `test/testTemplate.js` file for more
	deployer.deploy(Queue, queueSize);
};

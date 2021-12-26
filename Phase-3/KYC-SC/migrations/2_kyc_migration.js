var KYCContract = artifacts.require("KYCContract");

module.exports = function(deployer) {
  // deployment steps
  deployer.deploy(KYCContract);
};
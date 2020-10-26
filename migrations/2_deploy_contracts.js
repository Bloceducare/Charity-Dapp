var Voting = artifacts.require("Voting");

module.exports = function(deployer) {
    deployer.deploy(Voting,'0xB0D5a36733886a4c5597849a05B315626aF5222E');//currently using the snowflake address on rinkeby
};
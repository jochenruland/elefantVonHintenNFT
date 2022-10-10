const ElefantVonHinten = artifacts.require("ElefantVonHinten");

module.exports = function (deployer) {
  deployer.deploy(ElefantVonHinten, 'ElefantVonHinten', 'EVH');
};

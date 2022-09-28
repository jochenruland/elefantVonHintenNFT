const ElefantVonHinten = artifacts.require("ElefantVonHinten");

module.exports = function (deployer) {
  deployer.deploy(ElefantVonHinten, 'ElefantVonHinten', 'EVH', 'www.elefantvonhinten.de', 5, 2, 1000);
};

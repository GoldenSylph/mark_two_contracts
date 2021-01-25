const BedrinArbitrageur = artifacts.require("BedrinArbitrageur");
const BedrinBeneficiary = artifacts.require("BedrinBeneficiary");
const BedrinStorage = artifacts.require("BedrinStorage");
const BedrinSwapper = artifacts.require("BedrinSwapper");

//Mocks
const MockTokenA = artifacts.require("MockTokenA");
const MockTokenB = artifacts.require("MockTokenB");
const MockBaseToken = artifacts.require("MockBaseToken");
const OneSplitMultiMock = artifacts.require("OneSplitMultiMock");
const MockChiToken = artifacts.require("MockChiToken");

require('chai').use(require('chai-as-promised')).should();

const { BN, ZERO, ONE, ether } = require('./helpers.js');

contract('BedrinStorage', (accounts) => {

});

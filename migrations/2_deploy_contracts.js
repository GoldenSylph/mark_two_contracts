const BedrinArbitrageur = artifacts.require("BedrinArbitrageur");
const BedrinBeneficiary = artifacts.require("BedrinBeneficiary");
const BedrinStorage = artifacts.require("BedrinStorage");
const BedrinSwapper = artifacts.require("BedrinSwapper");

// Mocks
const OneSplitMultiMock = artifacts.require("OneSplitMultiMock");
const MockTokenA = artifacts.require("MockTokenA");
const MockTokenB = artifacts.require("MockTokenB");
const MockBaseToken = artifacts.require("MockBaseToken");
const MockABaseToken = artifacts.require("MockABaseToken");
const MockAEth = artifacts.require("MockAEth");
const MockAaveAddressesProvider = artifacts.require("MockAaveAddressesProvider");
const MockLendingPool = artifacts.require("MockLendingPool");
const MockChiToken = artifacts.require("MockChiToken");

module.exports = function(deployer, network, accounts) {
  console.log('Beginning migrations...');

  const ethAddress = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
  const oneSplitMultiAddress = '0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e';
  const oneSplitMultiApproveAddress = '0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e';
  const provider = '0x24a42fD28C976A61Df5D00D0599C34c4f90748c8';
  const gasToken = '0x0000000000004946c0e9F43F4Dee607b0eF1fA1c';
  const aaveUsdt = '0x71fc860F7D3A592A4a98740e39dB31d25db65ae8';
  const usdt = '0xdAC17F958D2ee523a2206206994597C13D831ec7';

  const referralCode = 96;
  const beneficiaryTransferFundsGasLimit = 3000000;
  // Slippage when converting tokens to base tokens
  const slippage = 300;
  const parts = 100;
  const flags = 0;

  if (network == 'mainnet_infura_storage_only') {
    console.log(`CAUTION: DEPLOYING ONLY STORAGE TO THE ${network}!!!`);

    const bedrinBeneficiaryAddress = '0xDEfE4d10Bb27B3b8a86e0a659eCe5DDB12476609';
    const bedrinArbitrageurAddress = '0xEA802747736E080741002191bD50ef9806858eB3';
    const bedrinSwapperAddress = '0xc8B989F6E004421B7F835Ae31A52c77Cbf1A0087';

    deployer.deploy(
      BedrinStorage,
      [
        oneSplitMultiAddress,
        oneSplitMultiApproveAddress,
        gasToken,
        bedrinBeneficiaryAddress,
        bedrinSwapperAddress,
        bedrinArbitrageurAddress,
        provider,
        ethAddress,
        usdt,
        aaveUsdt
      ],
      [
        beneficiaryTransferFundsGasLimit,
        slippage,
        parts,
        flags
      ],
      referralCode
    ).then(function(instance) {
      console.log(`BedrinStorage deployed at: ${instance.address}`);
    });
  }


  if (
    network == 'mainnet_local_node' ||
    network == 'mainnet_infura' ||
    network == 'kovan_local_node' ||
    network == 'kovan_infura'
  ) {
    console.log(`CAUTION: DEPLOYING TO THE ${network}!!!`);
    let bedrinBeneficiaryAddress;
    let bedrinArbitrageurAddress;
    let bedrinSwapperAddress;

    deployer.deploy(BedrinBeneficiary, {overwrite: false})
    .then(function(instance) {
      bedrinBeneficiaryAddress = instance.address;
      console.log("deployed bedrin beneficiary");
      return deployer.deploy(BedrinArbitrageur, provider, {overwrite: false});
    }).then(function(instance) {
      bedrinArbitrageurAddress = instance.address;
      console.log("deployed bedrin arbitrageur");
      return deployer.deploy(BedrinSwapper, {overwrite: false});
    }).then(function(instance) {
      bedrinSwapperAddress = instance.address;
      console.log("deployed bedrin swapper");
      return deployer.deploy(
        BedrinStorage,
        [
          oneSplitMultiAddress,
          oneSplitMultiApproveAddress,
          gasToken,
          bedrinBeneficiaryAddress,
          bedrinSwapperAddress,
          bedrinArbitrageurAddress,
          provider,
          ethAddress,
          usdt,
          aaveUsdt
        ],
        [
          beneficiaryTransferFundsGasLimit,
          slippage,
          parts,
          flags
        ],
        referralCode,
        {overwrite: false}
      );
    }).then(function(instance) {
      console.log("deployed bedrin storage");
      console.log(`BedrinStorage deployed at: ${instance.address}`);
      console.log(`BedrinArbitrageur deployed at: ${bedrinArbitrageurAddress}`);
      console.log(`BedrinSwapper deployed at: ${bedrinSwapperAddress}`);
      console.log(`BedrinBeneficiary deployed at: ${bedrinBeneficiaryAddress}`);
    });

  }
  if (network == 'development') {
    const referralCode = 96;
    const beneficiaryTransferFundsGasLimit = 3000000;
    // Slippage when converting tokens to base tokens
    const slippage = 1;
    const parts = 100;
    const flags = 0;
    const ethAddress = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';

    deployer.deploy(MockTokenA).then(function() {
      console.log("deployed A token");
      return deployer.deploy(MockTokenB);
    }).then(function() {
      console.log("deployed B token");
      return deployer.deploy(MockBaseToken);
    }).then(function() {
      console.log("deployed Base token");
      return deployer.deploy(MockABaseToken, MockBaseToken.address);
    }).then(function() {
      console.log("deployed ABase token");
      return deployer.deploy(MockAEth);
    }).then(function() {
      console.log("deployed AEth token");
      return deployer.deploy(
        MockLendingPool,
        MockTokenA.address,
        MockBaseToken.address,
        MockABaseToken.address,
        MockAEth.address
      );
    }).then(function() {
      console.log("deployed mock lending pool");
      return deployer.deploy(MockAaveAddressesProvider, MockLendingPool.address);
    }).then(function() {
      console.log("deployed mock aave addresses provider token");
      return deployer.deploy(
        OneSplitMultiMock,
        MockTokenA.address,
        MockTokenB.address,
        MockBaseToken.address,
        MockLendingPool.address
      );
    }).then(function() {
      console.log("deployed one split multi mock");
      return deployer.deploy(MockChiToken);
    }).then(function() {
      console.log("deployed mock chi token");
      return deployer.deploy(BedrinBeneficiary);
    }).then(function() {
      console.log("deployed bedrin beneficiary");
      return deployer.deploy(BedrinArbitrageur, MockAaveAddressesProvider.address);
    }).then(function() {
      console.log("deployed bedrin arbitrageur");
      return deployer.deploy(BedrinSwapper);
    }).then(function() {
      console.log("deployed bedrin swapper");
      return deployer.deploy(
        BedrinStorage,
        [
          OneSplitMultiMock.address,
          OneSplitMultiMock.address,
          MockChiToken.address,
          BedrinBeneficiary.address,
          BedrinSwapper.address,
          BedrinArbitrageur.address,
          MockAaveAddressesProvider.address,
          ethAddress,
          MockBaseToken.address,
          MockABaseToken.address
        ],
        [
          beneficiaryTransferFundsGasLimit,
          slippage,
          parts,
          flags
        ],
        referralCode
      );
    }).then(function(instance) {
      console.log("deployed bedrin storage");
      console.log(`BedrinArbitrageur deployed at: ${BedrinArbitrageur.address}`);
      console.log(`BedrinStorage deployed at: ${BedrinStorage.address}`);
      console.log(`BedrinSwapper deployed at: ${BedrinSwapper.address}`);
      console.log(`BedrinBeneficiary deployed at: ${BedrinBeneficiary.address}`);
    });
  }
};

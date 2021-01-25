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
const MockABaseToken = artifacts.require("MockABaseToken");
const MockLendingPool = artifacts.require("MockLendingPool");

require('chai').use(require('chai-as-promised')).should();

const {
  BN,
  ZERO,
  ONE,
  ether,
  checkOnDeposit,
  checkOnWithdraw,
  checkOnEvent,
  getReturnAndMetadata,
  generateFlagsForOneExchange,
  checkOnOpportunityExecuted,
  checkOnReceivedEth,
  checkOnSuccessfulFlashloan,
  checkOnSentRevenue,
  prepareCalldata
 } = require('./helpers.js');

contract('BedrinArbitrageur', ([deployer, donator]) => {

  let fromToken;
  let destToken;
  let baseToken;
  let mockChiToken;
  let oneSplitMultiMocked;
  let mockLendingPool;
  let arbitrageur;

  let ETHER_ADDRESS;
  let flags;

  before(async () => {

    fromToken = await MockTokenA.deployed();
    destToken = await MockTokenB.deployed();
    baseToken = await MockBaseToken.deployed();
    mockChiToken = await MockChiToken.deployed();
    mockABaseToken = await MockABaseToken.deployed();
    oneSplitMultiMocked = await OneSplitMultiMock.deployed();
    mockLendingPool = await MockLendingPool.deployed();
    arbitrageur = await BedrinArbitrageur.deployed();

    await fromToken.init(OneSplitMultiMock.address);
    await destToken.init(OneSplitMultiMock.address);
    await baseToken.init(OneSplitMultiMock.address);

    // await mockChiToken.distribute(BedrinArbitrageur.address);
    // console.log("Chi tokens distributed...");

    ETHER_ADDRESS = await mockLendingPool.ethAddress();

    flags = [
      // WARNING: THIS FLAGS LIST IS NOT FULL
      await oneSplitMultiMocked.FLAG_DISABLE_UNISWAP(),
      await oneSplitMultiMocked.FLAG_DISABLE_BANCOR(),
      await oneSplitMultiMocked.FLAG_DISABLE_OASIS(),
      await oneSplitMultiMocked.FLAG_DISABLE_COMPOUND(),
      await oneSplitMultiMocked.FLAG_DISABLE_FULCRUM(),
      await oneSplitMultiMocked.FLAG_DISABLE_CHAI(),
      await oneSplitMultiMocked.FLAG_DISABLE_AAVE(),
      await oneSplitMultiMocked.FLAG_DISABLE_SMART_TOKEN(),
      await oneSplitMultiMocked.FLAG_DISABLE_BDAI(),
      await oneSplitMultiMocked.FLAG_DISABLE_IEARN(),
      await oneSplitMultiMocked.FLAG_DISABLE_CURVE_COMPOUND(),
      await oneSplitMultiMocked.FLAG_DISABLE_CURVE_USDT(),
      await oneSplitMultiMocked.FLAG_DISABLE_CURVE_Y(),
      await oneSplitMultiMocked.FLAG_DISABLE_CURVE_BINANCE(),
      await oneSplitMultiMocked.FLAG_DISABLE_CURVE_SYNTHETIX(),
      await oneSplitMultiMocked.FLAG_DISABLE_WETH(),
      await oneSplitMultiMocked.FLAG_DISABLE_UNISWAP_COMPOUND(),
      await oneSplitMultiMocked.FLAG_DISABLE_UNISWAP_CHAI(),
      await oneSplitMultiMocked.FLAG_DISABLE_UNISWAP_AAVE(),
      await oneSplitMultiMocked.FLAG_DISABLE_IDLE(),
      await oneSplitMultiMocked.FLAG_DISABLE_MOONISWAP(),
      await oneSplitMultiMocked.FLAG_DISABLE_UNISWAP_V2(),
      await oneSplitMultiMocked.FLAG_DISABLE_UNISWAP_V2_ETH(),
      await oneSplitMultiMocked.FLAG_DISABLE_UNISWAP_V2_DAI(),
      await oneSplitMultiMocked.FLAG_DISABLE_UNISWAP_V2_USDC(),
      await oneSplitMultiMocked.FLAG_DISABLE_CURVE_PAX(),
      await oneSplitMultiMocked.FLAG_DISABLE_CURVE_RENBTC(),
      await oneSplitMultiMocked.FLAG_DISABLE_CURVE_TBTC(),
      await oneSplitMultiMocked.FLAG_DISABLE_DFORCE_SWAP(),
      await oneSplitMultiMocked.FLAG_DISABLE_SHELL(),
      await oneSplitMultiMocked.FLAG_DISABLE_MSTABLE_MUSD(),
      await oneSplitMultiMocked.FLAG_DISABLE_CURVE_SBTC(),
      await oneSplitMultiMocked.FLAG_DISABLE_DMM(),
      await oneSplitMultiMocked.FLAG_DISABLE_BALANCER_1(),
      await oneSplitMultiMocked.FLAG_DISABLE_BALANCER_2(),
      await oneSplitMultiMocked.FLAG_DISABLE_BALANCER_3(),
      await oneSplitMultiMocked.FLAG_DISABLE_KYBER_1(),
      await oneSplitMultiMocked.FLAG_DISABLE_KYBER_2(),
      await oneSplitMultiMocked.FLAG_DISABLE_KYBER_3(),
      await oneSplitMultiMocked.FLAG_DISABLE_KYBER_4()
    ];
  });

  describe('deposit and withdraw', () => {

    let amount;

    before(async () => {
      // prepare balances
      // mint to main account some A tokens
      await fromToken.init(deployer);
      amount = ether(1);
    })

    describe('deposit eth', () => {

      let result;

      before(async () => {
        result = await arbitrageur.sendTransaction({value: amount, from: deployer});
      });

      it(`the arbitrageur must have correct eth balance`, async () => {
        const balance = await web3.eth.getBalance(arbitrageur.address);
        balance.toString().should.equal(amount.toString(), `eth balance of arbitrageur is not sufficient`);
      });

      it('should emit SentToThisContract as deposit eth event', async () => {
        checkOnDeposit(result, ETHER_ADDRESS, deployer, amount);
      });
    });

    describe('deposit tokens', async () => {

      let oldBalance;
      let result;

      before(async () => {
        // send tokens
        oldBalance = await fromToken.balanceOf(arbitrageur.address, {from: deployer});
        await fromToken.approve(arbitrageur.address, amount, {from: deployer});
        result = await arbitrageur.depositTokens(fromToken.address, amount, {from: deployer});
      });

      it(`the arbitrageur must have correct tokens balance`, async () => {
        const newBalance = await fromToken.balanceOf(arbitrageur.address, {from: deployer});
        newBalance.toString().should.equal((new BN(oldBalance).add(new BN(amount))).toString(), `New balance is not sufficient`);
      });

      it('should emit SentToThisContract as deposit tokens event', async () => {
        checkOnDeposit(result, fromToken.address, deployer, amount);
      });
    });

    describe('withdraw eth', async () => {

      let oldDeployersBalance;
      let result;

      before(async () => {
        //withdraw eth
        oldDeployersBalance = await web3.eth.getBalance(deployer);
        result = await arbitrageur.withdrawEth(deployer, amount, {from: deployer});
      });

      it(`the arbitrageur balance must be equal to 0 and deployers balance must be greater than the old`, async () => {
        const balance = await web3.eth.getBalance(arbitrageur.address);
        balance.toString().should.equal('0',
          `The deployers balance must be equal to 0`);
        const newDeployerBalance = await web3.eth.getBalance(deployer);
        parseInt(oldDeployersBalance).should.be.lessThan(parseInt(newDeployerBalance),
          "The old balance of deployer should be less than new.");
      });

      it('should emit SentToThisContract as withdraw eth event', async () => {
        checkOnWithdraw(result, ETHER_ADDRESS, deployer, amount);
      });
    });

    describe('withdraw tokens', () => {

      let oldDeployersBalance;
      let result;

      before(async () => {
        //withdraw tokens
        oldDeployersBalance = await fromToken.balanceOf(deployer, {from: deployer});
        result = await arbitrageur.withdrawTokens(fromToken.address, deployer, amount, {from: deployer});
      });

      it(`the deployer must have new correct balance`, async () => {
        const newBalance = await fromToken.balanceOf(deployer, {from: deployer});
        newBalance.toString().should.equal((new BN(oldDeployersBalance).add(new BN(amount))).toString(), `New balance is not sufficient`);
      });

      it('should emit SentToThisContract as withdraw tokens event', async () => {
        checkOnWithdraw(result, fromToken.address, deployer, amount);
      });
    });
  });

  const referralCode = 96;
  const beneficiaryTransferFundsGasLimit = 3000000;
  // Slippage when converting tokens to base tokens
  const slippage = ONE;
  const parts = 100;
  const ethAddress = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
  const defaultFlag = 0;
  const amountGasTokenToBurn = 0;
  const amount = new BN(ether(0.01));
  const bnGasPrice = new BN(53000000000);

  describe('opportunity execution with tokens', async () => {

    let packedCalldata;

    before(async () => {
      packedCalldata = await prepareCalldata(
        fromToken.address,
        destToken.address,
        amount,
        parts,
        defaultFlag,
        bnGasPrice,
        flags,
        slippage,
        oneSplitMultiMocked,
        arbitrageur
      );
    });

    describe('with flashloan', () => {

      let result;
      let ownerBalanceABaseToken;
      let oldOwnerBalanceABaseToken;

      before(async () => {
        oldOwnerBalanceABaseToken = await mockABaseToken.balanceOf(deployer);
        result = await arbitrageur.executeOpportunity(
          packedCalldata.calldata,
          packedCalldata.rawCalldata.inFrom,
          fromToken.address,
          amountGasTokenToBurn,
          true,
          {from: deployer}
        );
        ownerBalanceABaseToken = await mockABaseToken.balanceOf(deployer);
      });

      it('should execute successfully', () => {
        parseInt(ownerBalanceABaseToken).should.be.greaterThan(parseInt(oldOwnerBalanceABaseToken),
          "Owners balance of aave base token a must be greater than the old.")
      });

      it('should emit SuccessfulFlashloan event', () => {
        checkOnSuccessfulFlashloan(result, packedCalldata.rawCalldata.inFrom);
      });

      it('should emit SentRevenue event', () => {
        const income = packedCalldata.rawCalldata.income;
        const inFrom = packedCalldata.rawCalldata.inFrom;
        checkOnSentRevenue(result, fromToken.address,
          income.sub(inFrom.add(inFrom.mul(new BN(9)).div(new BN(10000)))));
      });
    });

    describe('without flashloan', () => {

      let result;
      let ownerBalanceABaseToken;
      let oldOwnerBalanceABaseToken;

      before(async () => {
        oldOwnerBalanceABaseToken = await mockABaseToken.balanceOf(deployer);
        await fromToken.mintForFlashloanEmulation(arbitrageur.address, packedCalldata.rawCalldata.inFrom);
        result = await arbitrageur.executeOpportunity(
          packedCalldata.calldata,
          packedCalldata.rawCalldata.inFrom,
          fromToken.address,
          amountGasTokenToBurn,
          false,
          {from: deployer}
        );
        ownerBalanceABaseToken = await mockABaseToken.balanceOf(deployer);
      });

      it('should execute successfully', () => {
        parseInt(ownerBalanceABaseToken).should.be.greaterThan(parseInt(oldOwnerBalanceABaseToken),
          "Owners balance of aave base token a must be greater than the old.")
      });

      it('should emit SentRevenue event', () => {
        checkOnSentRevenue(result, fromToken.address,
            packedCalldata.rawCalldata.income.sub(packedCalldata.rawCalldata.inFrom));
      });
    });
  });

  describe('opportunity execution with ether', async () => {

    let packedCalldata;

    before(async () => {
      packedCalldata = await prepareCalldata(
        ETHER_ADDRESS,
        fromToken.address,
        amount,
        parts,
        defaultFlag,
        bnGasPrice,
        flags,
        slippage,
        oneSplitMultiMocked,
        arbitrageur
      );
    });

    describe('with flashloan', () => {

      let result;
      let ownerBalanceABaseToken;
      let oldOwnerBalanceABaseToken;

      before(async () => {
        oldOwnerBalanceABaseToken = await mockABaseToken.balanceOf(deployer);

        //add to lending pool and one split ether
        await mockLendingPool.sendTransaction({value: ether(1), from: donator});
        await oneSplitMultiMocked.sendTransaction({value: ether(1), from: donator});

        result = await arbitrageur.executeOpportunity(
          packedCalldata.calldata,
          packedCalldata.rawCalldata.inFrom,
          ETHER_ADDRESS,
          amountGasTokenToBurn,
          true
        );

        ownerBalanceABaseToken = await mockABaseToken.balanceOf(deployer);
      });

      it('should execute successfully', () => {
        parseInt(ownerBalanceABaseToken).should.be.greaterThan(parseInt(oldOwnerBalanceABaseToken),
          "Owners balance of aave base token must be greater than the old.")
      });

      it('should emit SuccessfulFlashloan event', () => {
        checkOnSuccessfulFlashloan(result, packedCalldata.rawCalldata.inFrom);
      });

      it('should emit SentRevenue event', () => {
        const income = packedCalldata.rawCalldata.income;
        const inFrom = packedCalldata.rawCalldata.inFrom;
        checkOnSentRevenue(result, ETHER_ADDRESS,
          income.sub(inFrom.add(inFrom.mul(new BN(9)).div(new BN(10000)))));
      });
    });

    describe('without flashloan', () => {

      let result;
      let ownerBalanceABaseToken;
      let oldOwnerBalanceABaseToken;

      before(async () => {
        //add to arbitrageur ether
        oldOwnerBalanceABaseToken = await mockABaseToken.balanceOf(deployer);
        await arbitrageur.sendTransaction({value: ether(1), from: donator});
        result = await arbitrageur.executeOpportunity(
          packedCalldata.calldata,
          packedCalldata.rawCalldata.inFrom,
          ETHER_ADDRESS,
          amountGasTokenToBurn,
          false
        );
        ownerBalanceABaseToken = await mockABaseToken.balanceOf(deployer);
      });

      it('should execute successfully', () => {
        parseInt(ownerBalanceABaseToken).should.be.greaterThan(parseInt(oldOwnerBalanceABaseToken),
          "Owners balance of aave base token must be greater than the old.")
      });

      it('should emit SentRevenue event', () => {
        checkOnSentRevenue(result, ETHER_ADDRESS,
          packedCalldata.rawCalldata.income.sub(packedCalldata.rawCalldata.inFrom));
      });
    });
  });

});

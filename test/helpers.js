const BN = web3.utils.BN;
const ZERO = new web3.utils.BN(0);
const ONE = new web3.utils.BN(1);

function checkOnEvent(result, eventName, processArgs) {
  if (result == null) {
    throw new Error(`Result of tx is: ${result}`);
  }
  const filteredLogs = result.logs.filter(l => l.event === eventName);
  filteredLogs.length.should.be.greaterThan(0, "The event with given name was not found.");
  const eventArgs = filteredLogs[0].args;
  processArgs(eventArgs);
}

function checkOnSentToThisContractEvent(result, token, user, amount, inOrOut) {
  checkOnEvent(result, "SentToThisContract", (eventArgs) => {
    eventArgs.token.should.equal(token, `token parameter ${eventArgs.token} is not as valid value ${token}`);
    eventArgs.user.should.equal(user, `user parameter ${eventArgs.user} is not as valid value ${user}`);
    eventArgs.amount.toString().should.equal(amount.toString(), `amount parameter ${eventArgs.amount} is not as valid value ${amount}`);
    eventArgs.inOrOut.should.equal(inOrOut, `the operation must be marked as ${inOrOut ? "deposit" : "withdraw"}`);
  });
}

function checkOnDeposit(result, token, user, amount) {
  checkOnSentToThisContractEvent(result, token, user, amount, true);
}

function checkOnWithdraw(result, token, user, amount) {
  checkOnSentToThisContractEvent(result, token, user, amount, false);
}

function checkOnOpportunityExecuted(
  result,
  from,
  to,
  amount,
  minDistribution,
  maxDistribution
) {
  //
  // event OpportunityExecuted(
  //   address indexed from,
  //   address indexed to,
  //   uint256 indexed amount,
  //   uint256[] minDistribution,
  //   uint256[] maxDistribution
  // );
  checkOnEvent(result, "OpportunityExecuted", (eventArgs) => {
    eventArgs.from.should.equal(from, "The from token address must be valid.");
    eventArgs.to.should.equal(to, "The to token address must be valid.");
    eventArgs.amount.toString().should.equal(amount.toString(), "The amount must be valid.");
    for (let i = 0; i < eventArgs.minDistribution.length; i++) {
      eventArgs.minDistribution[i].toString().should.equal(minDistribution[i].toString(),
        `The exhange of index ${i} must be valid.`);
    }
    for (let i = 0; i < eventArgs.maxDistribution.length; i++) {
      eventArgs.maxDistribution[i].toString().should.equal(maxDistribution[i].toString(),
        `The exhange of index ${i} must be valid.`);
    }
  });
}

function checkOnReceivedEth(result, who, amount) {
  // event ReceivedEth(address indexed who, uint256 amount);
  checkOnEvent(result, "ReceivedEth", (eventArgs) => {
    eventArgs.who.should.equal(who, "The who address must be valid.");
    eventArgs.amount.toString().should.equal(amount.toString(), "The amount must be valid.");
  });
}

function checkOnSuccessfulFlashloan(result, amount) {
  // event SuccessfulFlashloan(uint256 indexed amount);
  checkOnEvent(result, "SuccessfulFlashloan", (eventArgs) => {
    eventArgs.amount.toString().should.equal(amount.toString(), "The amount of flashloan must be valid.");
  });
}

function checkOnSentRevenue(result, token, revenue) {
  // event SentRevenue(address indexed token, uint256 revenue);
  checkOnEvent(result, "SentRevenue", (eventArgs) => {
    eventArgs.token.should.equal(token, "The token address must be valid.");
    eventArgs.revenue.toString().should.equal(revenue.toString(), "The revenue amount must be valid.");
  });
}

async function getReturnAndMetadata(oneSplitMultiMocked, fromTokenAddress, destTokenAddress, amount, parts, flags, gasPrice) {
  returnWithoutGasMetadata = await oneSplitMultiMocked.getExpectedReturn(
    fromTokenAddress,
    destTokenAddress,
    amount,
    parts,
    flags
  );
  returnMetadataWithGas = await oneSplitMultiMocked.getExpectedReturnWithGas(
    fromTokenAddress,
    destTokenAddress,
    amount,
    parts,
    flags,
    returnWithoutGasMetadata['0'].mul(gasPrice)
  );
  return returnMetadataWithGas;
};

function generateFlagsForOneExchange(flags, exchangeFlag) {
  let resultFlags = ZERO;
  const bnFlagsLength = new BN(flags.length);
  for (let i = ZERO; i.lt(bnFlagsLength); i.iadd(ONE)) {
    var tempFlags = flags[i];
    if (!tempFlags.eq(exchangeFlag)) {
      resultFlags.iadd(tempFlags);
    }
  }
  return resultFlags;
};

// Prepared calldata is using Max Mask strategy flags generation.
async function prepareCalldata(
  f,
  d,
  amount,
  parts,
  defaultFlag,
  bnGasPrice,
  flags,
  slippage,
  oneSplitMultiMocked,
  arbitrageur
) {

  const defaultFlagReturnMetadata = await getReturnAndMetadata(oneSplitMultiMocked, f, d, amount, parts, defaultFlag, bnGasPrice);
  let maxFlags = ZERO;
  let tempMinReturnB = defaultFlagReturnMetadata['0'];
  for (var i = ZERO; i.lt(new BN(flags.length)); i.iadd(ONE)) {
    let tempFlags = generateFlagsForOneExchange(flags, flags[i]);
    const tempReturnBMetadata = await getReturnAndMetadata(oneSplitMultiMocked, f, d, amount, parts, tempFlags, bnGasPrice);
    let tempReturnB = tempReturnBMetadata['0'];
    if (tempMinReturnB.lt(tempReturnB)) {
      tempMinReturnB = tempReturnB;
      maxFlags = tempFlags;
    }
  }

  // console.log(`In: ${web3.utils.fromWei(amount)}`);
  const returnBMetadata = await getReturnAndMetadata(oneSplitMultiMocked, f, d, amount, parts, maxFlags, bnGasPrice);
  const returnB = returnBMetadata['0'];
  const estimateGasAmountForReturnB = returnBMetadata['1'];
  const returnBDistribution = returnBMetadata['2'];
  // console.log(`A -> B: ${web3.utils.fromWei(returnB)}`);

  const returnAMetadata = await getReturnAndMetadata(oneSplitMultiMocked, d, f, returnB, parts, defaultFlag, bnGasPrice);
  const returnA = returnAMetadata['0'];
  const estimateGasAmountForReturnA = returnAMetadata['1'];
  const returnADistribution = returnAMetadata['2'];
  // console.log(`B -> A: ${web3.utils.fromWei(returnA)}`);


  let rawCalldata = {
    fromToken: f,
    destToken: d,
    income: returnA,
    firstTradeFlags: maxFlags,
    secondTradeFlags: defaultFlag,
    inFrom: amount,
    minFromToDest: amount.sub(amount.div(new BN(10000)).mul(slippage)),
    inDest: returnB,
    minDestToFrom: returnB.sub(amount.div(new BN(10000)).mul(slippage)),
    distributionFromToDest: returnBDistribution,
    distributionDestToFrom: returnADistribution
  }

  let calldata = await arbitrageur.prepareCalldataForOpportunity(
    rawCalldata.fromToken,
    rawCalldata.destToken,
    rawCalldata.firstTradeFlags,
    rawCalldata.secondTradeFlags,
    rawCalldata.inFrom,
    rawCalldata.minFromToDest,
    rawCalldata.inDest,
    rawCalldata.minDestToFrom,
    rawCalldata.distributionFromToDest,
    rawCalldata.distributionDestToFrom
  );

  return {
    rawCalldata,
    calldata
  };
};

module.exports = {
  ETHER_ADDRESS: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
  EVM_REVERT: 'VM Exception while processing transaction: revert',
  wait: function(seconds) {
    const millis = seconds * 1000;
    return new Promise(resolve => setTimeout(resolve, millis));
  },
  ether: function(n) {
    return web3.utils.toWei(n.toString(), 'ether');
  },
  checkOnEvent,
  checkOnDeposit,
  checkOnWithdraw,
  checkOnOpportunityExecuted,
  checkOnReceivedEth,
  checkOnSuccessfulFlashloan,
  checkOnSentRevenue,
  getReturnAndMetadata,
  generateFlagsForOneExchange,
  prepareCalldata,
  BN,
  ZERO,
  ONE
}

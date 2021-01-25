// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./ILendingPoolAddressesProvider.sol";
import "./ILendingPool.sol";
import "./FlashLoanReceiverBase.sol";
import "./BedrinBeneficiary.sol";
import "./BedrinSwapper.sol";
import "./UsingBedrinStorageWithCHI.sol";
import "./interfaces/IBedrinArbitrageur.sol";
import "./interfaces/IBedrinSwapper.sol";
import "./interfaces/IBedrinBeneficiary.sol";

contract BedrinArbitrageur is Ownable, FlashLoanReceiverBase, UsingBedrinStorageWithCHI, IBedrinArbitrageur {

  using SafeMath for uint256;

  event SentToThisContract(address indexed token, address indexed user, uint256 amount, bool inOrOut);
  event SentRevenue(address indexed token, uint256 revenue);
  event SuccessfulFlashloan(uint256 indexed amount);

  constructor(address _provider)
    FlashLoanReceiverBase(ILendingPoolAddressesProvider(_provider))
    public
  {}

  function depositTokens(address _token, uint256 _amount) public override {
    require(IERC20(_token).transferFrom(msg.sender, address(this), _amount),
      "Cannot deposit tokens, maybe approve is missed?");
    emit SentToThisContract(_token, msg.sender, _amount, true);
  }

  function withdrawTokens(address _token, address _to, uint256 _amount)
    public
    onlyOwner
    override
  {
    require(IERC20(_token).balanceOf(address(this)) >= _amount,
      "The withdrawable amount of token must be lower or equal to the balance.");
    require(IERC20(_token).transfer(_to, _amount), "Cannot transfer tokens.");
    emit SentToThisContract(_token, _to, _amount, false);
  }

  receive() external payable {
    emit SentToThisContract(getAddress(keccak256("ethAddress")), msg.sender, msg.value, true);
  }

  fallback() external {
    revert("The function you are calling is unknown to this contract.");
  }

  function withdrawEth(address _to, uint256 _amount)
    public
    payable
    onlyOwner
    override
  {
    require(_amount <= address(this).balance, "Cannot withdraw eth that is greater of current balance.");
    (bool success,) = _to.call{value: _amount}("");
    require(success, "Cannot withdraw ether from the contract.");
    emit SentToThisContract(getAddress(keccak256("ethAddress")), _to, _amount, false);
  }

  function prepareCalldataForOpportunity(
    address _fromToken,
    address _destToken,
    uint256 _flagsOfFirstTrade,
    uint256 _flagsOfSecondTrade,
    uint256 _inFrom,
    uint256 _minFromToDest,
    uint256 _inDest,
    uint256 _minDestToFrom,
    uint256[] calldata _distributionFromToDest,
    uint256[] calldata _distributionDestToFrom
  )
    external
    override
    pure
    returns(bytes memory params)
  {
    params = abi.encode(
      _fromToken,
      _destToken,
      [
        _flagsOfFirstTrade,
        _flagsOfSecondTrade,
        _inFrom,
        _minFromToDest,
        _inDest,
        _minDestToFrom
      ],
      _distributionFromToDest,
      _distributionDestToFrom
    );
  }

  function executeOpportunity(
    bytes calldata _params,
    uint256 _inFrom,
    address _fromToken,
    uint256 _amountGasTokenToBurn,
    bool _usingFlashloan
  )
    onlyOwner
    discountCHI(_amountGasTokenToBurn, address(this))
    payable
    override
    external
  {
    if (!_usingFlashloan) {
      address swapperAddress = getAddress(keccak256("swapperAddress"));
      transferToSwapper(_fromToken, swapperAddress, _inFrom);
      uint256 income = IBedrinSwapper(payable(swapperAddress)).executeSwaps(_params);
      require(income > _inFrom,
        "Income from deal without leverage must be greater than initial amount.");
      transferRevenueToBeneficiary(_fromToken, income.sub(_inFrom,
          "Without flashloaned opportunity: Income subtraction from total debt has overflowed."));
    } else {
      ILendingPool(addressesProvider.getLendingPool()).flashLoan(
        address(this),
        _fromToken,
        _inFrom,
        _params
      );
    }
  }

  /**
      This function is called after your contract has received the flash loaned amount
   */
  function executeOperation(
    address _reserve,
    uint256 _amount,
    uint256 _fee,
    bytes calldata _params
  )
    external
    override
  {
    require(_amount <= getBalanceInternal(address(this), _reserve),
      "Invalid balance, was the flashLoan successful?");
    emit SuccessfulFlashloan(_amount);
    address swapperAddress = getAddress(keccak256("swapperAddress"));
    transferToSwapper(_reserve, swapperAddress, _amount);
    uint256 income = IBedrinSwapper(payable(swapperAddress)).executeSwaps(_params);
    uint256 totalDebt = _amount.add(_fee);
    require(income > totalDebt, "Income is not big enough.");
    transferRevenueToBeneficiary(_reserve, income.sub(totalDebt,
      "Flashloaned opportunity: Income subtraction from total debt has overflowed."));
    transferFundsBackToPoolInternal(_reserve, totalDebt);
  }

  function transferToSwapper(address _reserve, address _swapperAddress, uint256 _amount) internal {
    if (_reserve == getAddress(keccak256("ethAddress"))) {
      (bool success,) = _swapperAddress.call{value: _amount}("");
      require(success, "Cannot send ether to swapper.");
    } else {
      IERC20(_reserve).transfer(_swapperAddress, _amount);
    }
  }

  function transferRevenueToBeneficiary(address _token, uint256 _revenue) internal {
    address payable beneficiaryAddress = payable(getAddress(keccak256("beneficiaryAddress")));
    if (_token == getAddress(keccak256("ethAddress"))) {
      (bool success, ) = beneficiaryAddress.call{value: _revenue, gas: getUint256(keccak256("beneficiaryTransferFundsGasLimit"))}("");
      require(success, "Cannot send from tokens to beneficiary after executing opportunity without flashloan.");
    } else {
      IERC20(_token).transfer(beneficiaryAddress, _revenue);
      IBedrinBeneficiary(beneficiaryAddress).convertAndSendRevenueToOwner(_token, _revenue);
    }
    emit SentRevenue(_token, _revenue);
  }
}

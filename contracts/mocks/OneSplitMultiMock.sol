// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./MockedIOneSplitMulti.sol";
import "./MockLendingPool.sol";

contract OneSplitMultiMock is MockedIOneSplitMulti {

  using SafeMath for uint256;

  IERC20 public mockTokenA;
  IERC20 public mockTokenB;
  IERC20 public mockBaseToken;
  MockLendingPool public mockLendingPool;

  constructor(
    address _mockTokenA,
    address _mockTokenB,
    address _mockBaseToken,
    address payable _mockLendingPool
  ) public {
    mockTokenA = IERC20(_mockTokenA);
    mockTokenB = IERC20(_mockTokenB);
    mockBaseToken = IERC20(_mockBaseToken);
    mockLendingPool = MockLendingPool(_mockLendingPool);
  }

  receive() external payable {}

  fallback() external {
    revert("The function you are calling is unknown to this contract.");
  }

  function getExpectedReturnWithGasMulti(
    IERC20[] memory tokens,
    uint256 amount,
    uint256[] memory parts,
    uint256[] memory flags,
    uint256[] memory destTokenEthPriceTimesGasPrices
  )
    public
    view
    override
    returns(
      uint256[] memory returnAmounts,
      uint256 estimateGasAmount,
      uint256[] memory distribution
    )
  {
    revert("Mocked error");
  }

  function swapMulti(
    IERC20[] memory tokens,
    uint256 amount,
    uint256 minReturn,
    uint256[] memory distribution,
    uint256[] memory flags
  )
    public
    payable
    override
    returns(uint256 returnAmount)
  {
    revert("Mocked error");
  }

  function getPrice(IERC20 from, IERC20 dest, bool minMax) internal view returns(uint256) {
    // For A to B opportunity testing
    if (address(from) == address(mockTokenA) && address(dest) == address(mockTokenB)) {
      if (minMax) {
        return 2;
      } else {
        return 3;
      }
    }
    if (address(from) == address(mockTokenB) && address(dest) == address(mockTokenA)) {
      if (minMax) {
        return 2;
      } else {
        return 3;
      }
    }
    // For A to eth opportunity testing
    if (address(from) == address(mockTokenA) && address(dest) == mockLendingPool.ethAddress()) {
      if (minMax) {
        return 2;
      } else {
        return 3;
      }
    }
    if (address(from) == address(mockLendingPool.ethAddress()) && address(dest) == address(mockTokenA)) {
      if (minMax) {
        return 5;
      } else {
        return 10;
      }
    }
    // For B to eth opportunity testing
    if (address(from) == address(mockTokenB) && address(dest) == mockLendingPool.ethAddress()) {
      if (minMax) {
        return 2;
      } else {
        return 3;
      }
    }
    if (address(from) == mockLendingPool.ethAddress() && address(dest) == address(mockTokenB)) {
      if (minMax) {
        return 3;
      } else {
        return 4;
      }
    }
    // For beneficiary deposit testing
    if (address(from) == mockLendingPool.ethAddress() && address(dest) == address(mockBaseToken)) {
      if (minMax) {
        return 3;
      } else {
        return 4;
      }
    }
    if (address(from) == address(mockBaseToken) && address(dest) == mockLendingPool.ethAddress()) {
      if (minMax) {
        return 1;
      } else {
        return 2;
      }
    }
    if (address(from) == address(mockTokenA) && address(dest) == address(mockBaseToken)) {
      if (minMax) {
        return 2;
      } else {
        return 4;
      }
    }
    if (address(from) == address(mockTokenB) && address(dest) == address(mockBaseToken)) {
      if (minMax) {
        return 3;
      } else {
        return 8;
      }
    }
    if (address(from) == address(mockBaseToken) && address(dest) == address(mockTokenA)) {
      if (minMax) {
        return 2;
      } else {
        return 4;
      }
    }
    if (address(from) == address(mockBaseToken) && address(dest) == address(mockTokenB)) {
      if (minMax) {
        return 3;
      } else {
        return 8;
      }
    }
    revert("invalid tokens are not permitted");
  }

  function getExpectedReturn(
    IERC20 fromToken,
    IERC20 destToken,
    uint256 amount,
    uint256 parts,
    uint256 flags // See constants in IOneSplit.sol
  )
    public
    view
    override
    returns(
      uint256 returnAmount,
      uint256[] memory distribution
    )
  {
    bool isFlagsDefault = flags == 0x0;
    returnAmount = amount.mul(getPrice(fromToken, destToken, isFlagsDefault));
    distribution = new uint256[](40);
    if (isFlagsDefault) {
      distribution[0] = 50;
      distribution[1] = 50;
    } else {
      distribution[3] = 100;
    }
  }

  function getExpectedReturnWithGas(
    IERC20 fromToken,
    IERC20 destToken,
    uint256 amount,
    uint256 parts,
    uint256 flags, // See constants in IOneSplit.sol
    uint256 destTokenEthPriceTimesGasPrice
  )
    public
    view
    override
    returns(
      uint256 returnAmount,
      uint256 estimateGasAmount,
      uint256[] memory distribution
    )
  {
    (returnAmount, distribution) = getExpectedReturn(fromToken, destToken, amount, parts, flags);
    estimateGasAmount = 300000;
  }

  function swap(
    IERC20 fromToken,
    IERC20 destToken,
    uint256 amount,
    uint256 minReturn,
    uint256[] memory distribution,
    uint256 flags
  )
    public
    override
    payable
    returns(uint256 returnAmount)
  {
    returnAmount = amount.mul(getPrice(fromToken, destToken, flags == 0x0));
    if (address(fromToken) == mockLendingPool.ethAddress()) {
      destToken.transfer(msg.sender, returnAmount);
    } else if (address(destToken) == mockLendingPool.ethAddress()) {
      SafeERC20.safeTransferFrom(fromToken, msg.sender, address(this), amount);
      require(address(this).balance >= returnAmount, "test");
      (bool success,) = msg.sender.call{value: returnAmount}("");
      require(success, "Cannot in swap method send ether to sender.");
    } else {
      SafeERC20.safeTransferFrom(fromToken, msg.sender, address(this), amount);
      destToken.transfer(msg.sender, returnAmount);
    }
  }
}

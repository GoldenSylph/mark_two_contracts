// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../BedrinArbitrageur.sol";
import "./MockTokenA.sol";
import "./MockBaseToken.sol";
import "./MockABaseToken.sol";
import "./MockAEth.sol";

contract MockLendingPool {

  using SafeMath for uint256;

  address public constant ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address public mockTokenA;
  address public mockBaseToken;
  address public mockABaseToken;
  address public mockAEth;

  constructor(
    address _mockTokenA,
    address _mockBaseToken,
    address _mockABaseToken,
    address _mockAEth
  ) public {
    mockTokenA = _mockTokenA;
    mockBaseToken = _mockBaseToken;
    mockABaseToken = _mockABaseToken;
    mockAEth = _mockAEth;
  }

  receive() external payable {}

  fallback() external {
    revert("The function you are calling is unknown to this contract.");
  }


  function deposit(
    address _reserve,
    uint256 _amount,
    uint16 _referralCode
  ) external payable {
    if (_reserve == mockBaseToken) {
      SafeERC20.safeTransferFrom(IERC20(_reserve), msg.sender, mockABaseToken, _amount);
      MockABaseToken(mockABaseToken).mintSome(msg.sender, _amount);
    } else if (_reserve == ethAddress) {
      payable(mockAEth).transfer(msg.value);
      MockAEth(mockAEth).mintSome(msg.sender, _amount);
    } else {
      revert("This reserve is no supported.");
    }
  }

  function flashLoan(
    address _receiver,
    address _reserve,
    uint256 _amount,
    bytes calldata _params
  ) external {
    // give reserve tokens in amount
    uint256 fee = _amount.mul(9).div(10000);
    if (_reserve == mockTokenA) {
      MockTokenA(mockTokenA).mintForFlashloanEmulation(address(this), _amount);
      IERC20(mockTokenA).transfer(_receiver, _amount);
      BedrinArbitrageur(payable(_receiver)).executeOperation(_reserve, _amount, fee, _params);
      // check if balance is sufficient
      require(MockTokenA(mockTokenA).balanceOf(address(this)) == _amount.add(fee), "Tokens amounts must be returned with fees.");
    } else if (_reserve == ethAddress) {
      (bool success,) = _receiver.call{value: _amount}("");
      require(success, "Cannot send ether for flashloan.");
      uint256 mlpOldEtherBalance = address(this).balance;
      BedrinArbitrageur(payable(_receiver)).executeOperation(_reserve, _amount, fee, _params);
      // check if balance is sufficient
      require(address(this).balance.sub(mlpOldEtherBalance) == _amount.add(fee), "Ether amounts must be returned with fees.");
    } else {
      revert("Flashloaning asset must either be Mock Token A or ether.");
    }
  }
}

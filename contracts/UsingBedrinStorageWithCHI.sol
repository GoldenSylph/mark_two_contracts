// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/IBedrinStorage.sol";
import "./IGasToken.sol";

contract UsingBedrinStorageWithCHI {

  using SafeMath for uint256;

  address public bedrinStorage;

  event FreedUpGasTokens(uint256 indexed amountToFreeUpTo, uint256 actualGasSpent);

  modifier discountCHI(uint256 _chiTokenAmountToBurn, address holder) {
    IGasToken chiToken = IGasToken(getAddress(keccak256("chiTokenAddress")));
    if (_chiTokenAmountToBurn == 0 || chiToken.balanceOf(holder) == 0) {
      _;
    } else {
      uint256 gasStart = gasleft();
      _;
      uint256 gasSpent = gasStart.add(21000).sub(gasleft().add(16).mul(msg.data.length), "Subtraction overflow in gas discount function.");
      uint256 freedUpCHI = gasSpent.add(14154).div(41947);
      if (_chiTokenAmountToBurn >= freedUpCHI) {
        chiToken.freeUpTo(freedUpCHI);
        emit FreedUpGasTokens(freedUpCHI, gasSpent);
      }
    }
  }

  function getAddress(bytes32 name) internal view returns(address) {
    return IBedrinStorage(bedrinStorage).getAddressProperty(name);
  }

  function getUint256(bytes32 name) internal view returns(uint256) {
    return IBedrinStorage(bedrinStorage).getUIntProperty(name);
  }

  function setStorage(address newStorage) public {
    if (bedrinStorage == address(0)) {
      bedrinStorage = newStorage;
    } else {
      require(msg.sender == bedrinStorage, "Only storage can inject itself.");
      require(bedrinStorage != newStorage, "New storage must differ from the old.");
      bedrinStorage = newStorage;
    }
  }
}

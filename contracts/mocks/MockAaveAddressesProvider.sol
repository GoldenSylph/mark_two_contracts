// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

contract MockAaveAddressesProvider {

  address public mockedLendingPool;

  constructor(address _mockedLendingPool) public {
    mockedLendingPool = _mockedLendingPool;
  }

  function getLendingPool() public view returns (address) {
    return mockedLendingPool;
  }

  function getLendingPoolCore() public view returns (address) {
    return mockedLendingPool;
  }
}

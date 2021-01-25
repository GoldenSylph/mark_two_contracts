// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

interface IBedrinSwapper {
  function executeSwaps(bytes calldata _params) external returns(uint256 amountOut);
}

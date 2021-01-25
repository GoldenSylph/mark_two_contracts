// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

interface IBedrinArbitrageur {
  function depositTokens(address _token, uint256 _amount) external;
  function withdrawTokens(address _token, address _to, uint256 _amount) external;
  function withdrawEth(address _to, uint256 _amount) external payable;
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
    pure
    returns(bytes memory params);
  function executeOpportunity(
    bytes calldata _params,
    uint256 _inFrom,
    address _fromToken,
    uint256 _amountGasTokenToBurn,
    bool _usingFlashloan
  ) external payable;
}

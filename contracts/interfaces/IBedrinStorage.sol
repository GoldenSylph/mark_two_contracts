// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

interface IBedrinStorage {
  function injectStorage(address _to) external;
  function setUIntProperty(bytes32 _name, uint256 _value) external;
  function setAddressProperty(bytes32 _name, address _value) external;
  function getUIntProperty(bytes32 _name) external view returns(uint256);
  function getAddressProperty(bytes32 _name) external view returns(address);
}

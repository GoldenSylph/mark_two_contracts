// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./UsingBedrinStorageWithCHI.sol";
import "./interfaces/IBedrinStorage.sol";

// Eternal Storage Pattern
contract BedrinStorage is Ownable, IBedrinStorage {

  // Enumeration from top to bottom: top element is 0, bottom is 8, addresses array contains:
  // address _oneSplitMultiAddress,
  // address _oneSplitMultiApprovalAddress,
  // address _chiTokenAddress,
  // address _beneficiaryAddress,
  // address _swapperAddress,
  // address _arbitrageurAddress,
  // address _lendingPoolAddressesProviderAddress,
  // address _ethAddress,
  // address _baseTokenAddress,
  // address _aBaseTokenAddress,

  // Enumeration from top to bottom: top element is 0, bottom is 3, metadata array contains:
  // uint256 _beneficiaryTransferFundsGasLimit,
  // uint256 _slippage,
  // uint256 _parts,
  // uint256 _flags,

  constructor(
    address[] memory addresses,
    uint256[] memory metadata,
    uint16 _referralCode
  ) public {
    setAddressPropertyInternal(keccak256("oneSplitMultiAddress"), addresses[0]);
    setAddressPropertyInternal(keccak256("oneSplitMultiApprovalAddress"), addresses[1]);
    setAddressPropertyInternal(keccak256("chiTokenAddress"), addresses[2]);
    setAddressPropertyInternal(keccak256("beneficiaryAddress"), addresses[3]);
    setAddressPropertyInternal(keccak256("swapperAddress"), addresses[4]);
    setAddressPropertyInternal(keccak256("arbitrageurAddress"), addresses[5]);
    setAddressPropertyInternal(keccak256("lendingPoolAddressesProviderAddress"), addresses[6]);
    setAddressPropertyInternal(keccak256("ethAddress"), addresses[7]);
    setAddressPropertyInternal(keccak256("baseTokenAddress"), addresses[8]);
    setAddressPropertyInternal(keccak256("aBaseTokenAddress"), addresses[9]);
    setUIntPropertyInternal(keccak256("beneficiaryTransferFundsGasLimit"), metadata[0]);
    setUIntPropertyInternal(keccak256("slippage"), metadata[1]);
    setUIntPropertyInternal(keccak256("parts"), metadata[2]);
    setUIntPropertyInternal(keccak256("flags"), metadata[3]);
    setUIntPropertyInternal(keccak256("referralCode"), uint256(_referralCode));
    injectStorageInternal(addresses[5]);
    injectStorageInternal(addresses[3]);
    injectStorageInternal(addresses[4]);
  }

  mapping(bytes32 => uint256) private uInt256Storage;
  mapping(bytes32 => address) private addressStorage;

  function injectStorageInternal(address _to) internal {
    UsingBedrinStorageWithCHI(_to).setStorage(address(this));
  }

  function injectStorage(address _to)
    public
    onlyOwner
    override
  {
    injectStorageInternal(_to);
  }

  function getUIntProperty(bytes32 _name)
    external
    override
    view
    returns(uint256)
  {
    return uInt256Storage[_name];
  }

  function getAddressProperty(bytes32 _name)
    external
    override
    view
    returns(address)
  {
    return addressStorage[_name];
  }

  function setUIntProperty(bytes32 _name, uint256 _value)
    external
    onlyOwner
    override
  {
    setUIntPropertyInternal(_name, _value);
  }

  function setAddressProperty(bytes32 _name, address _value)
    external
    onlyOwner
    override
  {
    setAddressPropertyInternal(_name, _value);
  }

  function setAddressPropertyInternal(bytes32 _name, address _value) internal {
    addressStorage[_name] = _value;
  }

  function setUIntPropertyInternal(bytes32 _name, uint256 _value) internal {
    uInt256Storage[_name] = _value;
  }
}

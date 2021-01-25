// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";
import "../IAToken.sol";

contract MockAEth is ERC20PresetMinterPauser, IAToken {

  constructor()
    public
    ERC20PresetMinterPauser("Mock ABase Token", "ABASE")
  {}

  function mintSome(address _to, uint256 _amount) public payable {
    _mint(_to, _amount);
  }

  function isTransferAllowed(address _user, uint256 _amount) external override view returns (bool) {
    return _amount > 0;
  }

  function redeem(uint256 _amount) external override {
    (bool success, ) = msg.sender.call{value: _amount}("");
    require(success, "Cannot redeem aeth.");
    _burn(msg.sender, _amount);
  }

}

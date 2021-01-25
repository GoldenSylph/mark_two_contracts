// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";

contract MockTokenA is ERC20PresetMinterPauser {

  constructor()
    public
    ERC20PresetMinterPauser("Mock Token A", "A")
  {}

  function init(address _to) public {
    _mint(_to, 200 ether);
  }

  function mintForFlashloanEmulation(address _to, uint256 _amount) public {
    _mint(_to, _amount);
  }

}

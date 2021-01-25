// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";

contract MockBaseToken is ERC20PresetMinterPauser {

  constructor()
    public
    ERC20PresetMinterPauser("Mock Base Token", "BASE")
  {}

  function init(address oneSplitMultiMocked) public {
    _mint(oneSplitMultiMocked, 200 ether);
  }

}

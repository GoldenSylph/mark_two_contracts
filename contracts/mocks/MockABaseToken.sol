// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../IAToken.sol";

contract MockABaseToken is ERC20PresetMinterPauser, IAToken {

  address public mockBaseToken;

  constructor(address _mockBaseToken)
    public
    ERC20PresetMinterPauser("Mock ABase Token", "ABASE")
  {
    mockBaseToken = _mockBaseToken;
  }

  function mintSome(address to, uint256 amount) public {
    _mint(to, amount);
  }

  function isTransferAllowed(address _user, uint256 _amount) external view override returns(bool) {
    return _amount > 0;
  }

  function redeem(uint256 _amount) external override {
    SafeERC20.safeApprove(IERC20(mockBaseToken), msg.sender, _amount);
    SafeERC20.safeTransferFrom(IERC20(mockBaseToken), address(this), msg.sender, _amount);
    _burn(msg.sender, _amount);
  }

}

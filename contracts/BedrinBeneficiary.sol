// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";

import "./ILendingPoolAddressesProvider.sol";
import "./ILendingPool.sol";
import "./IAToken.sol";
import "./IOneSplitMulti.sol";
import "./UsingBedrinStorageWithCHI.sol";
import "./interfaces/IBedrinBeneficiary.sol";

contract BedrinBeneficiary is Ownable, UsingBedrinStorageWithCHI, IBedrinBeneficiary {

  using SafeMath for uint256;

  event TransferredEth(
    address indexed who,
    uint256 amount,
    uint256 aTokensTransferred
  );

  event TransferredTokens(
    address indexed token,
    address indexed who,
    uint256 amount,
    uint256 aTokensTransferred
  );

  receive() external payable {
    require(msg.value > 0,
      "Cannot convert and send revenue because the balance of eth is equal to 0.");
    uint256 baseTokenOut = swapEthToBaseTokens(msg.value);
    depositToAave(getAddress(keccak256("baseTokenAddress")), baseTokenOut);
    transferToOwnerATokens();
    emit TransferredEth(msg.sender, msg.value, baseTokenOut);
  }

  fallback() external {
    revert("The function you are calling is unknown to this contract.");
  }

  function convertAndSendRevenueToOwner(address _token, uint256 _revenue)
    public
    override
  {
    uint256 baseTokenOut = swapTokensToBaseToken(_token, _revenue);
    depositToAave(getAddress(keccak256("baseTokenAddress")), baseTokenOut);
    transferToOwnerATokens();
    emit TransferredTokens(_token, msg.sender, _revenue, baseTokenOut);
  }

  function swapTokensToBaseToken(address _token, uint256 _amount)
    internal
    returns(uint256 baseTokenOut)
  {
    address baseTokenAddress = getAddress(keccak256("baseTokenAddress"));
    uint256 parts = getUint256(keccak256("parts"));
    uint256 flags = getUint256(keccak256("flags"));
    IOneSplitMulti oneSplitMulti = IOneSplitMulti(getAddress(keccak256("oneSplitMultiAddress")));
    (uint256 returnAmount, uint256[] memory distribution) = oneSplitMulti.getExpectedReturn(
      IERC20(_token),
      IERC20(baseTokenAddress),
      _amount,
      parts,
      flags
    );
    SafeERC20.safeApprove(
      IERC20(_token),
      getAddress(keccak256("oneSplitMultiApprovalAddress")),
      _amount
    );
    baseTokenOut = oneSplitMulti.swap(
      IERC20(_token),
      IERC20(baseTokenAddress),
      _amount,
      returnAmount.sub(returnAmount.div(10000).mul(getUint256(keccak256("slippage"))), "pidarok"),
      distribution,
      flags
    );
  }

  function swapEthToBaseTokens(uint256 ethAmount) internal returns(uint256 baseTokenOut) {
    address baseTokenAddress = getAddress(keccak256("baseTokenAddress"));
    address ethAddress = getAddress(keccak256("ethAddress"));
    uint256 parts = getUint256(keccak256("parts"));
    uint256 flags = getUint256(keccak256("flags"));
    IOneSplitMulti oneSplitMulti = IOneSplitMulti(getAddress(keccak256("oneSplitMultiAddress")));
    (uint256 returnAmount, uint256[] memory distribution) = oneSplitMulti.getExpectedReturn(
      IERC20(ethAddress),
      IERC20(baseTokenAddress),
      ethAmount,
      parts,
      flags
    );
    baseTokenOut = oneSplitMulti.swap{value: ethAmount}(
      IERC20(ethAddress),
      IERC20(baseTokenAddress),
      ethAmount,
      returnAmount.sub(returnAmount.div(10000).mul(getUint256(keccak256("slippage"))), "pizda"),
      distribution,
      flags
    );
  }

  function depositToAave(address _reserve, uint256 _amount) internal {
    ILendingPoolAddressesProvider addressesProvider =
      ILendingPoolAddressesProvider(getAddress(keccak256("lendingPoolAddressesProviderAddress")));
    uint16 referralCode = SafeCast.toUint16(getUint256(keccak256("referralCode")));
    ILendingPool lendingPool = ILendingPool(addressesProvider.getLendingPool());
    if (getAddress(keccak256("ethAddress")) == _reserve) {
      lendingPool.deposit{value: _amount}(_reserve, _amount, referralCode);
    } else {
      SafeERC20.safeApprove(
        IERC20(_reserve),
        addressesProvider.getLendingPoolCore(),
        _amount
      );
      lendingPool.deposit(_reserve, _amount, referralCode);
    }
  }

  function transferToOwnerATokens() internal {
    IAToken aTokenInstance = IAToken(getAddress(keccak256("aBaseTokenAddress")));
    address ownerAddr = owner();
    uint256 aTokenBalance = aTokenInstance.balanceOf(address(this));
    require(aTokenBalance > 0, "A token balance must be greater then 0.");
    require(aTokenInstance.isTransferAllowed(ownerAddr, aTokenBalance),
      "A transfer/redeem will fail if the resulting Health Factor of the user performing the action will end up being below 1.");
    aTokenInstance.transfer(ownerAddr, aTokenBalance);
  }
}

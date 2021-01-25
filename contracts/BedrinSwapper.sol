// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./BedrinStorage.sol";
import "./UsingBedrinStorageWithCHI.sol";
import "./IOneSplitMulti.sol";
import "./interfaces/IBedrinSwapper.sol";

contract BedrinSwapper is Ownable, UsingBedrinStorageWithCHI, IBedrinSwapper {

  event ReceivedEth(address indexed who, uint256 amount);

  event OpportunityExecuted(
    address indexed from,
    address indexed to,
    uint256 indexed amount,
    uint256[] minDistribution,
    uint256[] maxDistribution
  );

  receive() external payable {
    emit ReceivedEth(msg.sender, msg.value);
  }

  fallback() external {
    revert("The function you are calling is unknown to this contract.");
  }

  function executeSwaps(bytes calldata _params)
    external
    override
    returns(uint256 amountOut)
  {
    (
      // this is tradeParameters array, enumeration is from top to bottom: top is 0, bottom is 5
      // uint256 _flagsOfFirstTrade,
      // uint256 _flagsOfSecondTrade,
      // uint256 _inFrom,
      // uint256 _minFromToDest,
      // uint256 _inDest,
      // uint256 _minDestToFrom
      address _fromToken,
      address _destToken,
      uint256[6] memory tradeParameters,
      uint256[] memory _distributionFromToDest,
      uint256[] memory _distributionDestToFrom
    ) = abi.decode(_params,
      (
        address,
        address,
        uint256[6],
        uint256[],
        uint256[]
      )
    );

    IERC20 fromTokenWrapped = IERC20(_fromToken);
    IERC20 destTokenWrapped = IERC20(_destToken);
    IOneSplitMulti oneSplitMulti = IOneSplitMulti(getAddress(keccak256("oneSplitMultiAddress")));
    address oneSplitMultiApprovalAddress = getAddress(keccak256("oneSplitMultiApprovalAddress"));
    address ethAddress = getAddress(keccak256("ethAddress"));

    if (_fromToken == ethAddress) {
      oneSplitMulti.swap{value: tradeParameters[2]}(
        fromTokenWrapped,
        destTokenWrapped,
        tradeParameters[2],
        tradeParameters[3],
        _distributionFromToDest,
        tradeParameters[0]
      );
      SafeERC20.safeApprove(
        destTokenWrapped,
        oneSplitMultiApprovalAddress,
        tradeParameters[4]
      );
      amountOut = oneSplitMulti.swap(
        destTokenWrapped,
        fromTokenWrapped,
        tradeParameters[4],
        tradeParameters[5],
        _distributionDestToFrom,
        tradeParameters[1]
      );
      (bool success, ) = msg.sender.call{value: amountOut}("");
      require(success, "Cannot send ether from swapper to arbitrageur.");
    } else if (_destToken == ethAddress) {
      SafeERC20.safeApprove(
        fromTokenWrapped,
        oneSplitMultiApprovalAddress,
        tradeParameters[2]
      );
      oneSplitMulti.swap(
        fromTokenWrapped,
        destTokenWrapped,
        tradeParameters[2],
        tradeParameters[3],
        _distributionFromToDest,
        tradeParameters[0]
      );
      amountOut = oneSplitMulti.swap{value: tradeParameters[4]}(
        destTokenWrapped,
        fromTokenWrapped,
        tradeParameters[4],
        tradeParameters[5],
        _distributionDestToFrom,
        tradeParameters[1]
      );
      fromTokenWrapped.transfer(msg.sender, amountOut);
    } else {
      SafeERC20.safeApprove(
        fromTokenWrapped,
        oneSplitMultiApprovalAddress,
        tradeParameters[2]
      );
      oneSplitMulti.swap(
        fromTokenWrapped,
        destTokenWrapped,
        tradeParameters[2],
        tradeParameters[3],
        _distributionFromToDest,
        tradeParameters[0]
      );
      SafeERC20.safeApprove(
        destTokenWrapped,
        oneSplitMultiApprovalAddress,
        tradeParameters[4]
      );
      amountOut = oneSplitMulti.swap(
        destTokenWrapped,
        fromTokenWrapped,
        tradeParameters[4],
        tradeParameters[5],
        _distributionDestToFrom,
        tradeParameters[1]
      );
      fromTokenWrapped.transfer(msg.sender, amountOut);
    }
    emit OpportunityExecuted(
      _fromToken,
      _destToken,
      amountOut,
      _distributionFromToDest,
      _distributionDestToFrom
    );
  }
}

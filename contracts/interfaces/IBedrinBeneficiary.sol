// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

interface IBedrinBeneficiary {
  function convertAndSendRevenueToOwner(address _token, uint256 _revenue) external;
}

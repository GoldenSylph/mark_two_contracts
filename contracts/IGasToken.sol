// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGasToken is IERC20 {
    // Mints `value` new sub-tokens (e.g. cents, pennies, ...) by creating `value`
    // new child contracts. The minted tokens are owned by the caller of this
    // function.
    function mint(uint256 value) external;

    // Frees `value` sub-tokens (e.g. cents, pennies, ...) belonging to the
    // caller of this function by destroying `value` child contracts, which
    // will trigger a partial gas refund.
    // You should ensure that you pass at least 25710 + `value` * (1148 + 5722 + 150) gas
    // when calling this function. For details, see the comment above `destroyChildren`.
    function free(uint256 value) external returns (bool success);

    // Frees up to `value` sub-tokens. Returns how many tokens were freed.
    // Otherwise, identical to free.
    // You should ensure that you pass at least 25710 + `value` * (1148 + 5722 + 150) gas
    // when calling this function. For details, see the comment above `destroyChildren`.
    function freeUpTo(uint256 value) external returns (uint256 freed);

    // Frees `value` sub-tokens owned by address `from`. Requires that `msg.sender`
    // has been approved by `from`.
    // You should ensure that you pass at least 25710 + `value` * (1148 + 5722 + 150) gas
    // when calling this function. For details, see the comment above `destroyChildren`.
    function freeFrom(address from, uint256 value) external returns (bool success);

    // Frees up to `value` sub-tokens owned by address `from`. Returns how many tokens were freed.
    // Otherwise, identical to `freeFrom`.
    // You should ensure that you pass at least 25710 + `value` * (1148 + 5722 + 150) gas
    // when calling this function. For details, see the comment above `destroyChildren`.
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

//   ╔═╗ ┬ ┬┌─┐┌─┐┌┬┐╔═╗┬ ┬┌─┐┬┌┐┌┌─┐
//   ║═╬╗│ │├┤ └─┐ │ ║  ├─┤├─┤││││└─┐
//   ╚═╝╚└─┘└─┘└─┘ ┴ ╚═╝┴ ┴┴ ┴┴┘└┘└─┘

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

// solhint-disable-next-line no-empty-blocks
interface IERC20Token is IERC20, IERC20Permit {}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.26;

//   ╔═╗ ┬ ┬┌─┐┌─┐┌┬┐╔═╗┬ ┬┌─┐┬┌┐┌┌─┐
//   ║═╬╗│ │├┤ └─┐ │ ║  ├─┤├─┤││││└─┐
//   ╚═╝╚└─┘└─┘└─┘ ┴ ╚═╝┴ ┴┴ ┴┴┘└┘└─┘

import {ERC20Permit, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract MockERC20Token is ERC20Permit {
    // solhint-disable-next-line no-empty-blocks
    constructor() ERC20Permit("token") ERC20("token", "TOKEN") {}

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }

    function setBalanceOf(address _account, uint256 _amount) external {
        uint256 currentBalance = balanceOf(_account);
        if (_amount > currentBalance) {
            _mint(_account, _amount - currentBalance);
        } else {
            _burn(_account, currentBalance - _amount);
        }
    }
}

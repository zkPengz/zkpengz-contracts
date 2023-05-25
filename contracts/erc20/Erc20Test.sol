// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Erc20Test is ERC20, Ownable {
    constructor() ERC20("Erc20Test", "ERCT"){}

    function issueToken(uint256 count) public onlyOwner {
        _mint(msg.sender, count);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts@v4.9.3/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@v4.9.3/token/ERC20/extensions/ERC20Burnable.sol";
import "interfaces.sol";

contract TOKEN is AccessBase, ERC20, ERC20Burnable {
    constructor(string memory name) ERC20(name, name) {}

    function mint(address to, uint256 amount) external onlyOp {
        _mint(to, amount);
    }

    function burn(address user, uint256 amount) external onlyOp {
        _burn(user, amount);
    } 
}

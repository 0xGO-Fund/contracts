// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract ZEROToken is ERC20, Ownable, ERC20Permit {
    bool private initialized;
    address public deployer;

    constructor()
        ERC20("0XGO Token", "0XGO")
        ERC20Permit("0XGO Token")
        Ownable(msg.sender)
    {
        deployer = msg.sender;
    }

    function setupMasterChef(address masterChef) public onlyOwner {
        require(!initialized, "MasterChef Setup Completed");
        initialized = true;

        _transferOwnership(masterChef);
        _mint(masterChef, 100_000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(initialized, "Missing MasterChef Setup");

        _mint(to, amount);
    }
}

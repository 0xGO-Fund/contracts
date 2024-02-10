// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MasterChef is AccessControl {
    address public deployer;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address public token;

    constructor(address defaultMinter, address managedToken) {
        // Setup minter + admin roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        // Setup minter role to masterchef contract
        _grantRole(MINTER_ROLE, defaultMinter);

        token = managedToken;
        deployer = msg.sender;
    }

    function mint(
        address to,
        uint256 amount
    ) public onlyRole(MINTER_ROLE) returns (bool) {
        (bool success, ) = token.call(
            abi.encodeWithSignature("mint(address,uint256)", to, amount)
        );
        return success;
    }

    function grantMinterRole(
        address _user
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, _user);
    }

    function revokeMinterRole(
        address _user
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(MINTER_ROLE, _user);
    }

    function sweepToken(address _token) public onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20 tokenOut = IERC20(_token);
        uint256 balance = tokenOut.balanceOf(address(this));

        require(tokenOut.approve(msg.sender, balance), "ApproveFailed");
        require(tokenOut.transfer(msg.sender, balance), "TransferFailed");
    }
}

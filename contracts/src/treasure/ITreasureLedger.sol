// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ITreasureLedger
 * @dev Interface for TreasureLedger contract with minting capability
 */
interface ITreasureLedger is IERC20 {
    function mint(address to, uint256 amount) external;
}

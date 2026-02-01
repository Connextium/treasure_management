// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/**
 * @title TreasureLedger
 * @dev TreasureLedger for Letter of Credit settlement and treasure repository management
 * Features:
 * - ERC20 standard token
 * - Burnable: tokens can be burned
 * - Pausable: contract can be paused by owner
 * - Permit: gas-less approvals via EIP-2612
 * - Role-based access control for minting
 */
contract TreasureLedger is ERC20, ERC20Burnable, ERC20Pausable, Ownable, ERC20Permit {
    // Minter role for controlled issuance
    mapping(address => bool) public minters;

    // Events
    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);
    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);
    event TokensTransferred(address indexed from, address indexed to, uint256 amount);
    event AllowanceApproved(address indexed owner, address indexed spender, uint256 amount);
    event AllowanceIncreased(address indexed owner, address indexed spender, uint256 addedValue);
    event AllowanceDecreased(address indexed owner, address indexed spender, uint256 subtractedValue);

    // Modifiers
    modifier onlyMinter() {
        require(minters[msg.sender] || msg.sender == owner(), "TreasureLedger: caller is not a minter");
        _;
    }

    constructor() ERC20("Treasure Ledger", "CDSC") Ownable(msg.sender) ERC20Permit("Treasure Ledger") {
        minters[msg.sender] = true;
    }

    /**
     * @dev Mint new tokens (only minters)
     * @param to Recipient address
     * @param amount Token amount to mint
     */
    function mint(address to, uint256 amount) public onlyMinter {
        require(to != address(0), "TreasureLedger: mint to zero address");
        require(amount > 0, "TreasureLedger: mint amount must be greater than 0");

        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    /**
     * @dev Approve tokens for spending (explicit override)
     * @param spender Address allowed to spend tokens
     * @param amount Token amount approved
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        require(spender != address(0), "TreasureLedger: approve to zero address");
        require(msg.sender != spender, "TreasureLedger: approve to self");

        _approve(msg.sender, spender, amount);
        emit AllowanceApproved(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Increase allowance for spender
     * @param spender Address allowed to spend tokens
     * @param addedValue Additional amount to approve
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0), "TreasureLedger: approve to zero address");
        require(addedValue > 0, "TreasureLedger: increase amount must be greater than 0");

        uint256 currentAllowance = allowance(msg.sender, spender);
        _approve(msg.sender, spender, currentAllowance + addedValue);
        emit AllowanceIncreased(msg.sender, spender, addedValue);
        return true;
    }

    /**
     * @dev Decrease allowance for spender
     * @param spender Address allowed to spend tokens
     * @param subtractedValue Amount to reduce from approval
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0), "TreasureLedger: approve to zero address");
        require(subtractedValue > 0, "TreasureLedger: decrease amount must be greater than 0");

        uint256 currentAllowance = allowance(msg.sender, spender);
        require(currentAllowance >= subtractedValue, "TreasureLedger: decreased allowance below zero");

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        emit AllowanceDecreased(msg.sender, spender, subtractedValue);
        return true;
    }

    /**
     * @dev Transfer tokens to a specified address
     * @param to Recipient address
     * @param amount Token amount to transfer
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        require(to != address(0), "TreasureLedger: transfer to zero address");
        require(amount > 0, "TreasureLedger: transfer amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "TreasureLedger: insufficient balance");

        _update(msg.sender, to, amount);
        emit TokensTransferred(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another (on behalf of)
     * @param from Sender address
     * @param to Recipient address
     * @param amount Token amount to transfer
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(from != address(0), "TreasureLedger: transfer from zero address");
        require(to != address(0), "TreasureLedger: transfer to zero address");
        require(amount > 0, "TreasureLedger: transfer amount must be greater than 0");
        require(balanceOf(from) >= amount, "TreasureLedger: insufficient balance");

        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _update(from, to, amount);
        emit TokensTransferred(from, to, amount);
        return true;
    }

    /**
     * @dev Pause the contract (only owner)
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract (only owner)
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Add a minter role (only owner)
     */
    function addMinter(address account) public onlyOwner {
        require(account != address(0), "TreasureLedger: zero address");
        minters[account] = true;
        emit MinterAdded(account);
    }

    /**
     * @dev Remove a minter role (only owner)
     */
    function removeMinter(address account) public onlyOwner {
        minters[account] = false;
        emit MinterRemoved(account);
    }

    /**
     * @dev Check if an address is a minter
     */
    function isMinter(address account) public view returns (bool) {
        return minters[account];
    }

    /**
     * @dev Override _update to check if contract is paused
     */
    function _update(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Pausable)
        whenNotPaused
    {
        super._update(from, to, amount);
    }

    /**
     * @dev Override nonces for EIP-2612 permit
     */
    function nonces(address owner)
        public
        view
        override(ERC20Permit)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}
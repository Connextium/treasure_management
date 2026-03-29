// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "./ITreasureLedger.sol";
import "../letterofcredit/LocManagement.sol";


/**
 * @title TreasureLedger
 * @dev TreasureLedger for Letter of Credit settlement and treasure repository management
 * Features:
 * - ERC20 standard token
 * - Burnable: tokens can be burned
 * - Pausable: contract can be paused by owner
 * - Permit: gas-less approvals via EIP-2612
 * - Bitmask-based participant role model (ROLE_MINT)
 * - Implements ITreasureLedger interface for standardized minting and burning
 */
contract TreasureLedger is ITreasureLedger, ERC20, ERC20Burnable, ERC20Pausable, ERC20Permit, Ownable {
    // ================================================================
    // │                    Role-Based Access Control                   │
    // ================================================================

    /// @dev ROLE_MINT: external participants (banks, FIs) — can mint and burn their own tokens
    uint8 public constant ROLE_MINT = 1 << 0;       // 0x01

    /// @dev ACTIVE flag: bit 7 marks a participant as active. Roles are preserved when disabled.
    uint8 private constant ACTIVE = 1 << 7;           // 0x80

    /// @dev Bitmask of (ACTIVE flag | roles) per participant address
    mapping(address => uint8) public participants;

    /// @dev Admin address for participant and role management
    address public admin;

    // ================================================================
    // │                  LocManagement Factory                         │
    // ================================================================

    /// @dev Track all LocManagement contracts per issuing bank
    mapping(address => address[]) public bankLocManagers;
    address[] public allLocManagers;

    // Events
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event ParticipantAdded(address indexed account);
    event ParticipantEnabled(address indexed account);
    event ParticipantDisabled(address indexed account);
    event RolesGranted(address indexed account, uint8 roles);
    event RolesRevoked(address indexed account, uint8 roles);
    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);
    event TokensTransferred(address indexed from, address indexed to, uint256 amount);
    event AllowanceApproved(address indexed owner, address indexed spender, uint256 amount);
    event AllowanceIncreased(address indexed owner, address indexed spender, uint256 addedValue);
    event AllowanceDecreased(address indexed owner, address indexed spender, uint256 subtractedValue);
    event LocManagementCreated(
        address indexed issuingBank,
        address indexed locManagement,
        address indexed creator
    );

    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "TreasureLedger: caller is not admin");
        _;
    }

    modifier onlyRole(uint8 role) {
        require(
            (participants[msg.sender] & (ACTIVE | role)) == (ACTIVE | role) || msg.sender == owner(),
            "TreasureLedger: caller lacks required role"
        );
        _;
    }

    modifier onlyParticipant() {
        require(isParticipant(msg.sender), "TreasureLedger: caller is not a participant");
        _;
    }

    /// @notice Constructor sets deployer as owner and admin
    constructor()
        ERC20("Treasure Ledger", "CDSC")
        ERC20Permit("Treasure Ledger")
        Ownable(msg.sender)
    {
        admin = msg.sender;
    }

    /**
     * @dev Mint new tokens (only ROLE_MINT participants)
     * Implements ITreasureLedger.mint
     * @param to Recipient address
     * @param amount Token amount to mint
     */
    function mint(address to, uint256 amount) external onlyRole(ROLE_MINT) {
        require(to != address(0), "TreasureLedger: mint to zero address");
        require(amount > 0, "TreasureLedger: mint amount must be greater than 0");

        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    /**
     * @dev Burn tokens from caller's account (only ROLE_MINT participants)
     * Participants can burn their own tokens to reduce supply.
     * Implements ITreasureLedger.burnFrom
     * @param amount Token amount to burn
     */
    function burnFrom(uint256 amount) external onlyRole(ROLE_MINT) {
        require(amount > 0, "TreasureLedger: burn amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "TreasureLedger: insufficient balance");

        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }

    /**
     * @dev Approve tokens for spending (explicit override)
     * Mitigates the ERC-20 approve race condition by requiring the current
     * allowance to be zero before setting a new non-zero value.
     * To change an existing allowance: first set to 0, then set to new value.
     * @param spender Address allowed to spend tokens
     * @param amount Token amount approved
     */
    function approve(address spender, uint256 amount) public override(ERC20, IERC20) returns (bool) {
        require(spender != address(0), "TreasureLedger: approve to zero address");
        require(msg.sender != spender, "TreasureLedger: approve to self");
        require(
            amount == 0 || allowance(msg.sender, spender) == 0,
            "TreasureLedger: reset allowance to zero first"
        );

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
    function transfer(address to, uint256 amount) public override(ERC20, IERC20) returns (bool) {
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
    function transferFrom(address from, address to, uint256 amount) public override(ERC20, IERC20) returns (bool) {
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
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract (only owner)
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // ================================================================
    // │                      Admin Management                         │
    // ================================================================

    /**
     * @dev Set admin address (only owner)
     * @param _newAdmin New admin address
     */
    function setAdmin(address _newAdmin) external onlyOwner {
        require(_newAdmin != address(0), "TreasureLedger: zero address");
        address oldAdmin = admin;
        admin = _newAdmin;
        emit AdminChanged(oldAdmin, _newAdmin);
    }

    // ================================================================
    // │                  Participant Management                        │
    // ================================================================

    /**
     * @dev Register a new participant (only admin)
     * @param account Participant address to register
     */
    function addParticipant(address account) external onlyAdmin {
        require(account != address(0), "TreasureLedger: zero address");
        require(!isParticipant(account), "TreasureLedger: already a participant");
        participants[account] = participants[account] | ACTIVE;
        emit ParticipantAdded(account);
    }

    /**
     * @dev Enable a previously disabled participant (only admin)
     * Restores access to all previously granted roles.
     * @param account Participant address to enable
     */
    function enableParticipant(address account) external onlyAdmin {
        require(participants[account] != 0, "TreasureLedger: not a participant");
        require(!isParticipant(account), "TreasureLedger: already active");
        participants[account] = participants[account] | ACTIVE;
        emit ParticipantEnabled(account);
    }

    /**
     * @dev Disable a participant (only admin)
     * Clears ACTIVE flag but preserves role bits for re-enabling.
     * @param account Participant address to disable
     */
    function disableParticipant(address account) external onlyAdmin {
        require(isParticipant(account), "TreasureLedger: not an active participant");
        participants[account] = participants[account] & ~ACTIVE;
        emit ParticipantDisabled(account);
    }

    /**
     * @dev Check if an address is an active participant
     * @param account Address to check
     */
    function isParticipant(address account) public view returns (bool) {
        return (participants[account] & ACTIVE) == ACTIVE;
    }

    // ================================================================
    // │                    Role Admin Functions                        │
    // ================================================================

    /**
     * @dev Grant roles to an active participant (only admin)
     * @param account Participant address
     * @param roles Bitmask of roles to grant (e.g., ROLE_MINT | ROLE_APPROVE)
     */
    function grantRoles(address account, uint8 roles) external onlyAdmin {
        require(isParticipant(account), "TreasureLedger: not an active participant");
        require(roles > 0, "TreasureLedger: no roles specified");
        participants[account] = participants[account] | roles;
        emit RolesGranted(account, roles);
    }

    /**
     * @dev Revoke roles from a participant (only admin)
     * @param account Participant address
     * @param roles Bitmask of roles to revoke
     */
    function revokeRoles(address account, uint8 roles) external onlyAdmin {
        require(isParticipant(account), "TreasureLedger: not an active participant");
        require(roles > 0, "TreasureLedger: no roles specified");
        participants[account] = participants[account] & ~roles;
        emit RolesRevoked(account, roles);
    }

    /**
     * @dev Check if a participant has a specific role
     * @param account Participant address
     * @param role Role bit to check
     */
    function hasRole(address account, uint8 role) public view returns (bool) {
        return (participants[account] & (ACTIVE | role)) == (ACTIVE | role);
    }

    /**
     * @dev Get all roles for a participant (excludes ACTIVE flag)
     * @param account Participant address
     */
    function getRoles(address account) public view returns (uint8) {
        return participants[account] & ~ACTIVE;
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

    // ================================================================
    // │              LocManagement Factory Functions                   │
    // ================================================================

    /**
     * @dev Create a new LocManagement instance for an issuing bank
     * @param _issuingBank Address of the issuing bank
     * @return Address of the newly created LocManagement contract
     */
    function createLocManagement(address _issuingBank) external onlyParticipant returns (address) {
        require(_issuingBank != address(0), "TreasureLedger: zero address");

        // Deploy new LocManagement (immutably bound to issuing bank)
        LocManagement locMgmt = new LocManagement(
            address(this),
            _issuingBank
        );

        address locMgmtAddr = address(locMgmt);

        // Track the new LocManagement
        bankLocManagers[_issuingBank].push(locMgmtAddr);
        allLocManagers.push(locMgmtAddr);

        emit LocManagementCreated(_issuingBank, locMgmtAddr, msg.sender);
        return locMgmtAddr;
    }

    /**
     * @dev Get all LocManagement contracts for an issuing bank
     * @param _issuingBank Address of the issuing bank
     * @return Array of LocManagement contract addresses
     */
    function getLocManagers(address _issuingBank) external view returns (address[] memory) {
        return bankLocManagers[_issuingBank];
    }

    /**
     * @dev Get count of LocManagement contracts for an issuing bank
     * @param _issuingBank Address of the issuing bank
     * @return Number of LocManagement contracts
     */
    function getLocManagerCount(address _issuingBank) external view returns (uint256) {
        return bankLocManagers[_issuingBank].length;
    }

    /**
     * @dev Get all LocManagement contracts created by this TreasureLedger
     * @return Array of all LocManagement contract addresses
     */
    function getAllLocManagers() external view returns (address[] memory) {
        return allLocManagers;
    }

    /**
     * @dev Activate a Letter of Credit by minting tokens, approving allowance, and activating LC
     * This consolidates three steps into one transaction:
     * 1. Find the bank's LocManagement contract (first element in bankLocManagers)
     * 2. Get LC data to retrieve amount and Loc contract address
     * 3. Mint tokens to the issuing bank
     * 4. Approve allowance from issuing bank to Loc contract
     * 5. Call activateLC on the LocManagement contract
     * @param _locNo LC number to activate
     */
    function activateLoc(uint256 _locNo) external onlyRole(ROLE_MINT) {
        // Step 1: Get the bank's LocManagement (first element for the calling bank)
        require(bankLocManagers[msg.sender].length > 0, "TreasureLedger: no LocManagement found for bank");
        address locManagementAddr = bankLocManagers[msg.sender][0];
        LocManagement locMgmt = LocManagement(locManagementAddr);

        // Step 2: Get LC data from LocManagement
        Loc.LocData memory locData = locMgmt.getLocData(_locNo);
        address locAddress = locMgmt.getLocContractAddress(_locNo);
        uint256 amount = locData.amount;

        require(amount > 0, "TreasureLedger: zero amount");
        require(locAddress != address(0), "TreasureLedger: zero Loc address");

        // Step 3: Mint tokens to the caller (issuing bank)
        _mint(msg.sender, amount);
        emit TokensMinted(msg.sender, amount);

        // Step 4: Approve allowance from issuing bank to Loc contract
        _approve(msg.sender, locAddress, amount);
        emit AllowanceApproved(msg.sender, locAddress, amount);

        // Step 5: Call activateLC on LocManagement with bank address for verification
        // Security: Pass msg.sender to enable defense-in-depth validation in LocManagement
        locMgmt.activateLC(_locNo, msg.sender);
    }

}
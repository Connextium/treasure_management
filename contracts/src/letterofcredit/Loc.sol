// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Loc
 * @dev Letter of Credit contract for individual LC settlement
 */
contract Loc is Ownable {
    // LC Data Structure
    struct LocData {
        uint256 locNo;
        address buyerAcc;
        address sellerAcc;
        uint256 amount;
        bytes2 status; // "IS" = Issued, "AC" = Active, "EX" = Expired, "ST" = Settled
        uint256 dateOfIssue;
        uint256 dateOfExpiry;
        address treasureLedgerAddress;
        uint256 createdAt;
        uint256 settledAt;
    }

    // State variables
    LocData public locData;
    IERC20 public treasureLedger;
    address public issuingBank;

    // Events
    event LocActivated(uint256 indexed locNo, uint256 timestamp);
    event LocSettled(uint256 indexed locNo, address indexed beneficiary, uint256 amount, uint256 timestamp);
    event LocExpired(uint256 indexed locNo, uint256 timestamp);
    event FundsReleased(address indexed recipient, uint256 amount, uint256 timestamp);

    // Status constants
    bytes2 constant STATUS_ISSUED = "IS";
    bytes2 constant STATUS_ACTIVE = "AC";
    bytes2 constant STATUS_EXPIRED = "EX";
    bytes2 constant STATUS_SETTLED = "ST";

    // Modifiers
    modifier onlyIssuingBank() {
        require(msg.sender == issuingBank, "Loc: caller is not the issuing bank");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == locData.sellerAcc, "Loc: caller is not the seller");
        _;
    }

    /**
     * @dev Initialize the Loc contract
     * @param _locNo Letter of Credit number
     * @param _buyerAcc Buyer account address
     * @param _sellerAcc Seller account address
     * @param _amount LC amount
     * @param _dateOfIssue Date of issue (timestamp)
     * @param _dateOfExpiry Date of expiry (timestamp)
     * @param _treasureLedgerAddress Address of TreasureLedger contract
     * @param _issuingBankAddr Address of issuing bank
     */
    constructor(
        uint256 _locNo,
        address _buyerAcc,
        address _sellerAcc,
        uint256 _amount,
        uint256 _dateOfIssue,
        uint256 _dateOfExpiry,
        address _treasureLedgerAddress,
        address _issuingBankAddr
    ) Ownable(msg.sender) {
        require(_buyerAcc != address(0), "Loc: invalid buyer address");
        require(_sellerAcc != address(0), "Loc: invalid seller address");
        require(_treasureLedgerAddress != address(0), "Loc: invalid treasury address");
        require(_issuingBankAddr != address(0), "Loc: invalid issuing bank address");
        require(_amount > 0, "Loc: amount must be greater than 0");
        require(_dateOfExpiry > _dateOfIssue, "Loc: expiry date must be after issue date");

        locData = LocData({
            locNo: _locNo,
            buyerAcc: _buyerAcc,
            sellerAcc: _sellerAcc,
            amount: _amount,
            status: STATUS_ISSUED,
            dateOfIssue: _dateOfIssue,
            dateOfExpiry: _dateOfExpiry,
            treasureLedgerAddress: _treasureLedgerAddress,
            createdAt: block.timestamp,
            settledAt: 0
        });

        treasureLedger = IERC20(_treasureLedgerAddress);
        issuingBank = _issuingBankAddr;
    }

    /**
     * @dev Get LC data
     */
    function getLocData() public view returns (LocData memory) {
        return locData;
    }

    /**
     * @dev Get LC status
     */
    function getStatus() public view returns (bytes2) {
        return locData.status;
    }

    /**
     * @dev Get LC status as string
     */
    function getStatusString() public view returns (string memory) {
        if (locData.status == STATUS_ISSUED) return "Issued";
        if (locData.status == STATUS_ACTIVE) return "Active";
        if (locData.status == STATUS_EXPIRED) return "Expired";
        if (locData.status == STATUS_SETTLED) return "Settled";
        return "Unknown";
    }

    /**
     * @dev Check if LC is expired
     */
    function isExpired() public view returns (bool) {
        return block.timestamp > locData.dateOfExpiry;
    }

    /**
     * @dev Activate the LC (only issuing bank)
     * Requires issuing bank to have approved fund spending by this contract
     * Minting is done by LocManagement before calling this
     */
    function activateLC() public onlyOwner {
        require(locData.status == STATUS_ISSUED, "Loc: LC must be in Issued status");
        require(!isExpired(), "Loc: LC has already expired");

        // Verify that issuing bank has approved this contract to spend the LC amount
        uint256 currentAllowance = treasureLedger.allowance(issuingBank, address(this));
        require(currentAllowance >= locData.amount, "Loc: insufficient allowance for LC activation");

        // Update status to Active
        locData.status = STATUS_ACTIVE;

        emit LocActivated(locData.locNo, block.timestamp);
    }

    /**
     * @dev Settle the LC (only seller can invoke)
     * Transfers the LC amount from issuing bank to the seller (beneficiary)
     */
    function settleLC() public {
        require(msg.sender == locData.sellerAcc || msg.sender == owner(), "Loc: caller is not the seller or owner");
        require(locData.status == STATUS_ACTIVE, "Loc: LC must be in Active status");
        require(!isExpired(), "Loc: LC has expired");

        // Verify issuing bank has approved sufficient amount
        uint256 currentAllowance = treasureLedger.allowance(issuingBank, address(this));
        require(currentAllowance >= locData.amount, "Loc: insufficient allowance to settle");

        // Update status to Settled
        locData.status = STATUS_SETTLED;
        locData.settledAt = block.timestamp;

        // Transfer funds from issuing bank directly to seller (beneficiary)
        bool success = treasureLedger.transferFrom(issuingBank, locData.sellerAcc, locData.amount);
        require(success, "Loc: fund transfer to seller failed");

        emit LocSettled(locData.locNo, locData.sellerAcc, locData.amount, block.timestamp);
        emit FundsReleased(locData.sellerAcc, locData.amount, block.timestamp);
    }

    /**
     * @dev Expire the LC (only owner/LocManagement)
     * If LC is not settled by expiry date, issuing bank can mark it as expired
     */
    function expireLC() public onlyOwner {
        require(locData.status == STATUS_ACTIVE || locData.status == STATUS_ISSUED, "Loc: LC cannot be expired in current status");
        require(isExpired(), "Loc: LC has not yet expired");

        // Update status to Expired
        locData.status = STATUS_EXPIRED;

        emit LocExpired(locData.locNo, block.timestamp);
    }

    /**
     * @dev Get current allowance approved to this LC contract
     */
    function getAllowance() public view returns (uint256) {
        return treasureLedger.allowance(issuingBank, address(this));
    }

    /**
     * @dev Get issuing bank's current balance
     */
    function getIssuingBankBalance() public view returns (uint256) {
        return treasureLedger.balanceOf(issuingBank);
    }

    /**
     * @dev Check if LC can be settled (issuing bank has approved allowance)
     */
    function canFundLC() public view returns (bool) {
        uint256 allowance = treasureLedger.allowance(issuingBank, address(this));
        return allowance >= locData.amount;
    }

    /**
     * @dev Get funding status details
     */
    function getFundingStatus() public view returns (uint256 allowance, uint256 required, bool isFunded) {
        allowance = treasureLedger.allowance(issuingBank, address(this));
        required = locData.amount;
        isFunded = allowance >= required;
    }
}

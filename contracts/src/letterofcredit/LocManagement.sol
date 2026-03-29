// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Loc.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ReceiverTemplate.sol";
import "../treasure/ITreasureLedger.sol";

/**
 * @title LocManagement
 * @dev Manages the creation, activation, settlement, and expiration of Letters of Credit
 * Each LocManagement is bound to a specific issuing bank (immutable)
 */
contract LocManagement is ReceiverTemplate {
    // Custom errors
    error InvalidAddress();
    error LCAlreadyExists();
    error LCDoesNotExist();
    error InvalidAmount();
    error InvalidDateRange();
    error NotIssuingBank();
    error NotAuthorized();

    // State variables
    ITreasureLedger public immutable treasureLedger;
    address public immutable issuingBank;

    // Mapping of LC number to LC contract address
    mapping(uint256 => address) public locContracts;

    // Events
    event LCIssued(
        uint256 indexed locNo,
        address indexed buyerAcc,
        address indexed sellerAcc,
        uint256 amount,
        address locContractAddress
    );
    event LCApproved(uint256 indexed locNo);
    event LCActivated(uint256 indexed locNo);
    event LCSettled(uint256 indexed locNo);
    event LCExpired(uint256 indexed locNo);

    // Modifiers

    modifier onlyIssuingBank() {
        if (msg.sender != issuingBank) revert NotIssuingBank();
        _;
    }

    modifier onlyTreasure() {
        if (msg.sender != address(treasureLedger)) revert NotAuthorized();
        _;
    }

    modifier locMustExist(uint256 _locNo) {
        if (locContracts[_locNo] == address(0)) revert LCDoesNotExist();
        _;
    }

    /**
     * @dev Initialize LocManagement contract
     * @param _treasureLedgerAddress Address of TreasureLedger contract
     * @param _issuingBankAddr Address of issuing bank (immutable)
     * @param _forwarderAddress Address of the Chainlink Forwarder contract (for CRE)
     */
    constructor(
        address _treasureLedgerAddress,
        address _issuingBankAddr,
        address _forwarderAddress
    ) ReceiverTemplate(_forwarderAddress) {
        if (_treasureLedgerAddress == address(0)) revert InvalidAddress();
        if (_issuingBankAddr == address(0)) revert InvalidAddress();

        treasureLedger = ITreasureLedger(_treasureLedgerAddress);
        issuingBank = _issuingBankAddr;
    }

    // --- CRE Adapter Selectors ---
    bytes4 private constant ISSUE_LC_SELECTOR = bytes4(keccak256("issueLC(uint256,address,address,uint256,uint256,uint256)"));
    bytes4 private constant APPROVE_LC_SELECTOR = bytes4(keccak256("approveLC(uint256)"));
    bytes4 private constant SETTLE_LC_SELECTOR = bytes4(keccak256("settleLC(uint256)"));
    bytes4 private constant EXPIRE_LC_SELECTOR = bytes4(keccak256("expireLC(uint256)"));

    /**
     * @dev CRE entry point: routes CRE workflow calls to the correct method
     * @param report Encoded CRE report (selector + params)
     */
    function _processReport(bytes calldata report) internal override {
        require(report.length >= 4, "Invalid report length");
        bytes4 selector = bytes4(report[0:4]);
        if (selector == ISSUE_LC_SELECTOR) {
            (uint256 locNo, address buyerAcc, address sellerAcc, uint256 amount, uint256 dateOfIssue, uint256 dateOfExpiry) = abi.decode(report[4:], (uint256, address, address, uint256, uint256, uint256));
            // Call internal logic, bypassing onlyIssuingBank
            _issueLCFromCRE(locNo, buyerAcc, sellerAcc, amount, dateOfIssue, dateOfExpiry);
            return;
        }
        if (selector == APPROVE_LC_SELECTOR) {
            uint256 locNo = abi.decode(report[4:], (uint256));
            _approveLCFromCRE(locNo);
            return;
        }
        if (selector == SETTLE_LC_SELECTOR) {
            uint256 locNo = abi.decode(report[4:], (uint256));
            _settleLCFromCRE(locNo);
            return;
        }
        if (selector == EXPIRE_LC_SELECTOR) {
            uint256 locNo = abi.decode(report[4:], (uint256));
            _expireLCFromCRE(locNo);
            return;
        }
        revert("Invalid CRE selector");
    }

    // --- Internal CRE logic wrappers (bypass onlyIssuingBank, onlyTreasure, etc. as needed) ---
    function _issueLCFromCRE(
        uint256 _locNo,
        address _buyerAcc,
        address _sellerAcc,
        uint256 _amount,
        uint256 _dateOfIssue,
        uint256 _dateOfExpiry
    ) internal {
        if (locContracts[_locNo] != address(0)) revert LCAlreadyExists();
        if (_buyerAcc == address(0) || _sellerAcc == address(0)) revert InvalidAddress();
        if (_amount == 0) revert InvalidAmount();
        if (_dateOfExpiry <= _dateOfIssue) revert InvalidDateRange();
        Loc locContract = new Loc(
            _locNo,
            _buyerAcc,
            _sellerAcc,
            _amount,
            _dateOfIssue,
            _dateOfExpiry,
            address(treasureLedger),
            issuingBank,
            address(this)
        );
        locContracts[_locNo] = address(locContract);
        emit LCIssued(_locNo, _buyerAcc, _sellerAcc, _amount, address(locContract));
    }

    function _approveLCFromCRE(uint256 _locNo) internal {
        Loc locContract = Loc(locContracts[_locNo]);
        Loc.LocData memory locData = locContract.getLocData();
        require(locData.status == "IS", "LocManagement: LC must be in Issued status");
        require(block.timestamp <= locData.dateOfExpiry, "LocManagement: LC has expired");
        locContract.setStatus("AP");
        emit LCApproved(_locNo);
    }

    function _settleLCFromCRE(uint256 _locNo) internal {
        Loc locContract = Loc(locContracts[_locNo]);
        Loc.LocData memory locData = locContract.getLocData();
        // For CRE, allow any authorized workflow to settle (optionally add more checks)
        locContract.settleLC();
        emit LCSettled(_locNo);
    }

    function _expireLCFromCRE(uint256 _locNo) internal {
        Loc locContract = Loc(locContracts[_locNo]);
        Loc.LocData memory locData = locContract.getLocData();
        require(locData.status == "IS" || locData.status == "AC", "LocManagement: LC cannot be expired in current status");
        require(block.timestamp > locData.dateOfExpiry, "LocManagement: LC has not yet expired");
        locContract.setStatus("EX");
        emit LCExpired(_locNo);
    }

    /**
     * @dev Issue a new Letter of Credit
     * @param _locNo Letter of Credit number (must be unique)
     * @param _buyerAcc Buyer account address
     * @param _sellerAcc Seller account address
     * @param _amount LC amount
     * @param _dateOfIssue Date of issue (timestamp)
     * @param _dateOfExpiry Date of expiry (timestamp)
     */
    function issueLC(
        uint256 _locNo,
        address _buyerAcc,
        address _sellerAcc,
        uint256 _amount,
        uint256 _dateOfIssue,
        uint256 _dateOfExpiry
    ) external onlyIssuingBank {
        if (locContracts[_locNo] != address(0)) revert LCAlreadyExists();
        if (_buyerAcc == address(0) || _sellerAcc == address(0)) revert InvalidAddress();
        if (_amount == 0) revert InvalidAmount();
        if (_dateOfExpiry <= _dateOfIssue) revert InvalidDateRange();

        // Create new Loc contract
        Loc locContract = new Loc(
            _locNo,
            _buyerAcc,
            _sellerAcc,
            _amount,
            _dateOfIssue,
            _dateOfExpiry,
            address(treasureLedger),
            issuingBank,
            address(this) // Pass LocManagement address for registry validation
        );

        // Store reference to Loc contract
        locContracts[_locNo] = address(locContract);

        emit LCIssued(_locNo, _buyerAcc, _sellerAcc, _amount, address(locContract));
    }

    /**
     * @dev Activate a Letter of Credit (called by TreasureLedger only)
     * Validates and activates LC status
     * Note: TreasureLedger handles minting and approval before calling this
     * @param _locNo Letter of Credit number
     * @param _bank Address of the issuing bank (passed from TreasureLedger for validation)
     */
    function activateLC(uint256 _locNo, address _bank) external onlyTreasure locMustExist(_locNo) {
        // Security Enhancement: Defense-in-depth validation to ensure TreasureLedger
        // is activating LC for the correct bank, preventing logic bugs
        if (_bank != issuingBank) revert NotIssuingBank();
        
        Loc locContract = Loc(locContracts[_locNo]);
        Loc.LocData memory locData = locContract.getLocData();
        
        // Validate LC can be activated
        require(locData.status == "AP", "LocManagement: LC must be in Approved status");
        require(block.timestamp <= locData.dateOfExpiry, "LocManagement: LC has expired");
        
        // Set status to Active
        locContract.setStatus("AC");
        emit LCActivated(_locNo);
    }

    /**
     * @dev Approve LC funds (only issuing bank)
     * Step 1: Issuing bank calls this to set LC status to Approved
     * Step 2: Issuing bank must then mint tokens and approve allowance to Loc contract
     * Step 3: Call activateLC to set status to Active
     * @param _locNo Letter of Credit number
     */
    function approveLC(uint256 _locNo) external onlyIssuingBank locMustExist(_locNo) {
        Loc locContract = Loc(locContracts[_locNo]);
        Loc.LocData memory locData = locContract.getLocData();
        
        // Validate LC can be approved
        require(locData.status == "IS", 
                "LocManagement: LC must be in Issued status");
        require(block.timestamp <= locData.dateOfExpiry, "LocManagement: LC has expired");
        
        // Set status to Approved
        locContract.setStatus("AP");
        emit LCApproved(_locNo);
        
        // After this, issuing bank should call:
        // treasureLedger.activateLoc(_locNo) to mint, approve and activate in one transaction
    }

    /**
     * @dev Settle a Letter of Credit
     * Note: Seller should call settleLC directly on the Loc contract
     * This function is kept for event emission and tracking
     * @param _locNo Letter of Credit number
     */
    function settleLC(uint256 _locNo) public locMustExist(_locNo) {
        Loc locContract = Loc(locContracts[_locNo]);
        Loc.LocData memory locData = locContract.getLocData();
        
        // Only allow if called by seller
        if (msg.sender != locData.sellerAcc) revert NotAuthorized();
        
        // Seller calls Loc.settleLC directly
        locContract.settleLC();
        emit LCSettled(_locNo);
    }

    /**
     * @dev Expire a Letter of Credit (only issuing bank)
     * Returns funds to issuing bank if LC was not settled
     * @param _locNo Letter of Credit number
     */
    function expireLC(uint256 _locNo) external onlyIssuingBank locMustExist(_locNo) {
        Loc locContract = Loc(locContracts[_locNo]);
        Loc.LocData memory locData = locContract.getLocData();
        
        // Validate LC can be expired
        require(locData.status == "IS" || locData.status == "AC", 
                "LocManagement: LC cannot be expired in current status");
        require(block.timestamp > locData.dateOfExpiry, "LocManagement: LC has not yet expired");
        
        // Set status to Expired
        locContract.setStatus("EX");
        emit LCExpired(_locNo);
    }

    /**
     * @dev Get LC contract address
     * @param _locNo Letter of Credit number
     */
    function getLocContractAddress(uint256 _locNo) public view locMustExist(_locNo) returns (address) {
        return locContracts[_locNo];
    }

    /**
     * @dev Get LC data
     * @param _locNo Letter of Credit number
     */
    function getLocData(uint256 _locNo) public view locMustExist(_locNo) returns (Loc.LocData memory) {
        Loc locContract = Loc(locContracts[_locNo]);
        return locContract.getLocData();
    }

    /**
     * @dev Get LC status
     * @param _locNo Letter of Credit number
     */
    function getLocStatus(uint256 _locNo) public view locMustExist(_locNo) returns (string memory) {
        Loc locContract = Loc(locContracts[_locNo]);
        return locContract.getStatusString();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Loc.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../treasure/ITreasureLedger.sol";
import {ReceiverTemplate} from "../interfaces/ReceiverTemplate.sol";

/**
 * @title LocManagement
 * @dev Manages the creation, activation, settlement, and expiration of Letters of Credit
 * Features CRE integration via ReceiverTemplate (provides Ownable) for automated LC operations
 */
contract LocManagement is ReceiverTemplate {
    // State variables
    ITreasureLedger public treasureLedger;
    address public issuingBank;

    // Mapping of LC number to LC contract address
    mapping(uint256 => address) public locContracts;
    mapping(uint256 => bool) public locExists;

    // Array to track all LC numbers
    uint256[] public allLocNumbers;

    // Events
    event LCIssued(
        uint256 indexed locNo,
        address indexed buyerAcc,
        address indexed sellerAcc,
        uint256 amount,
        address locContractAddress,
        uint256 timestamp
    );
    event LCActivated(uint256 indexed locNo, uint256 timestamp);
    event LCSettled(uint256 indexed locNo, uint256 timestamp);
    event LCExpired(uint256 indexed locNo, uint256 timestamp);
    event LCFundsMinted(uint256 indexed locNo, address indexed issuingBank, uint256 amount, uint256 timestamp);

    // Modifiers
    modifier onlyIssuingBank() {
        require(msg.sender == issuingBank, "LocManagement: caller is not the issuing bank");
        _;
    }

    modifier locMustExist(uint256 _locNo) {
        require(locExists[_locNo], "LocManagement: LC does not exist");
        _;
    }

    /**
     * @dev Initialize LocManagement contract
     * @param _treasureLedgerAddress Address of TreasureLedger contract
     * @param _issuingBankAddr Address of issuing bank
     * @param _forwarderAddress The address of the Chainlink KeystoneForwarder contract
     */
    constructor(address _treasureLedgerAddress, address _issuingBankAddr, address _forwarderAddress) 
        ReceiverTemplate(_forwarderAddress)
    {
        require(_treasureLedgerAddress != address(0), "LocManagement: invalid treasury address");
        require(_issuingBankAddr != address(0), "LocManagement: invalid issuing bank address");

        treasureLedger = ITreasureLedger(_treasureLedgerAddress);
        issuingBank = _issuingBankAddr;
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
    ) public onlyIssuingBank {
        require(!locExists[_locNo], "LocManagement: LC already exists");
        require(_buyerAcc != address(0), "LocManagement: invalid buyer address");
        require(_sellerAcc != address(0), "LocManagement: invalid seller address");
        require(_amount > 0, "LocManagement: amount must be greater than 0");
        require(_dateOfExpiry > _dateOfIssue, "LocManagement: expiry date must be after issue date");

        // Create new Loc contract
        Loc locContract = new Loc(
            _locNo,
            _buyerAcc,
            _sellerAcc,
            _amount,
            _dateOfIssue,
            _dateOfExpiry,
            address(treasureLedger),
            issuingBank
        );

        // Store reference to Loc contract
        locContracts[_locNo] = address(locContract);
        locExists[_locNo] = true;
        allLocNumbers.push(_locNo);

        emit LCIssued(_locNo, _buyerAcc, _sellerAcc, _amount, address(locContract), block.timestamp);
    }

    /**
     * @dev Activate a Letter of Credit
     * Mints funds to issuing bank and validates allowance
     * @param _locNo Letter of Credit number
     */
    function activateLC(uint256 _locNo) public onlyIssuingBank locMustExist(_locNo) {
        Loc locContract = Loc(locContracts[_locNo]);
        Loc.LocData memory locData = locContract.getLocData();
        
        // Mint the LC amount to issuing bank
        treasureLedger.mint(msg.sender, locData.amount);
        emit LCFundsMinted(_locNo, msg.sender, locData.amount, block.timestamp);
        
        // Activate the LC contract (validates allowance)
        locContract.activateLC();
        emit LCActivated(_locNo, block.timestamp);
    }

    /**
     * @dev Settle a Letter of Credit
     * Transfers funds from escrow to seller
     * @param _locNo Letter of Credit number
     */
    function settleLC(uint256 _locNo) public locMustExist(_locNo) {
        Loc locContract = Loc(locContracts[_locNo]);
        Loc.LocData memory locData = locContract.getLocData();
        
        // Verify caller is the seller or contract owner
        require(
            msg.sender == locData.sellerAcc || msg.sender == owner(),
            "LocManagement: caller is not authorized to settle"
        );
        
        locContract.settleLC();
        emit LCSettled(_locNo, block.timestamp);
    }

    /**
     * @dev Expire a Letter of Credit
     * Returns funds to issuing bank if LC was not settled
     * @param _locNo Letter of Credit number
     */
    function expireLC(uint256 _locNo) public onlyIssuingBank locMustExist(_locNo) {
        Loc locContract = Loc(locContracts[_locNo]);
        locContract.expireLC();
        emit LCExpired(_locNo, block.timestamp);
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

    /**
     * @dev Get all LC numbers
     */
    function getAllLocNumbers() public view returns (uint256[] memory) {
        return allLocNumbers;
    }

    /**
     * @dev Get total number of LCs
     */
    function getTotalLocCount() public view returns (uint256) {
        return allLocNumbers.length;
    }

    /**
     * @dev Update issuing bank address (only owner)
     */
    function setIssuingBank(address _newIssuingBank) public onlyOwner {
        require(_newIssuingBank != address(0), "LocManagement: invalid issuing bank address");
        issuingBank = _newIssuingBank;
    }

    // ================================================================
    // │                      CRE Entry Point                         │
    // ================================================================

    /// @inheritdoc ReceiverTemplate
    /// @dev Routes based on function selector for CRE-triggered LC operations.
    ///      - ISSUE_LC_SELECTOR → Issue new LC
    ///      - ACTIVATE_LC_SELECTOR → Activate LC
    ///      - SETTLE_LC_SELECTOR → Settle LC
    ///      - EXPIRE_LC_SELECTOR → Expire LC
    function _processReport(bytes calldata report) internal override {
        if (report.length >= 4) {
            bytes4 selector = bytes4(report[0:4]);
            if (selector == ISSUE_LC_SELECTOR) {
                (
                    uint256 locNo,
                    address buyerAcc,
                    address sellerAcc,
                    uint256 amount,
                    uint256 dateOfIssue,
                    uint256 dateOfExpiry
                ) = abi.decode(report[4:], (uint256, address, address, uint256, uint256, uint256));
                issueLC(locNo, buyerAcc, sellerAcc, amount, dateOfIssue, dateOfExpiry);
                return;
            }
            if (selector == ACTIVATE_LC_SELECTOR) {
                uint256 locNo = abi.decode(report[4:], (uint256));
                activateLC(locNo);
                return;
            }
            if (selector == SETTLE_LC_SELECTOR) {
                uint256 locNo = abi.decode(report[4:], (uint256));
                settleLC(locNo);
                return;
            }
            if (selector == EXPIRE_LC_SELECTOR) {
                uint256 locNo = abi.decode(report[4:], (uint256));
                expireLC(locNo);
                return;
            }
        }
        revert("LocManagement: Invalid selector");
    }

    /// @dev Function selectors for CRE report routing
    bytes4 private constant ISSUE_LC_SELECTOR = bytes4(keccak256("issueLC(uint256,address,address,uint256,uint256,uint256)"));
    bytes4 private constant ACTIVATE_LC_SELECTOR = bytes4(keccak256("activateLC(uint256)"));
    bytes4 private constant SETTLE_LC_SELECTOR = bytes4(keccak256("settleLC(uint256)"));
    bytes4 private constant EXPIRE_LC_SELECTOR = bytes4(keccak256("expireLC(uint256)"));
}

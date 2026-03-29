// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {TreasureLedger} from "../src/treasure/TreasureLedger.sol";
import {LocManagement} from "../src/letterofcredit/LocManagement.sol";
import {Loc} from "../src/letterofcredit/Loc.sol";

contract LocManagementTest is Test {
    TreasureLedger public treasureLedger;
    LocManagement public locManagement;

    address issuingBank = address(1);
    address buyer = address(2);
    address seller = address(3);
    address owner = address(4);
    address admin = address(5);

    uint256 constant LC_AMOUNT = 10000e18;
    uint256 constant LC_NO = 1001;

    function setUp() public {
        vm.prank(owner);
        treasureLedger = new TreasureLedger();

        // Set admin for treasureLedger
        vm.prank(owner);
        treasureLedger.setAdmin(admin);

        // Cache role constants (avoid vm.prank being consumed by getter calls)
        uint8 roleMint = treasureLedger.ROLE_MINT();

        // Register and grant issuing bank ROLE_MINT (external participant)
        vm.prank(admin);
        treasureLedger.addParticipant(issuingBank);
        vm.prank(admin);
        treasureLedger.grantRoles(issuingBank, roleMint);

        // Create LocManagement via TreasureLedger factory
        vm.prank(issuingBank);
        // Pass both required arguments to createLocManagement (e.g., issuingBank and owner)
        address locMgmtAddr = treasureLedger.createLocManagement(issuingBank, owner);
        locManagement = LocManagement(locMgmtAddr);

        // Register and grant LocManagement ROLE_MINT (internal operator)
        vm.prank(admin);
        treasureLedger.addParticipant(address(locManagement));
        vm.prank(admin);
        treasureLedger.grantRoles(address(locManagement), roleMint);

        // Mint tokens for issuing bank
        vm.prank(owner);
        treasureLedger.mint(issuingBank, LC_AMOUNT * 2);
    }

    function test_IssueLC() public {
        uint256 dateOfIssue = block.timestamp;
        uint256 dateOfExpiry = block.timestamp + 30 days;

        vm.prank(issuingBank);
        locManagement.issueLC(LC_NO, buyer, seller, LC_AMOUNT, dateOfIssue, dateOfExpiry);

        address locAddress = locManagement.getLocContractAddress(LC_NO);
        assertNotEq(locAddress, address(0));
    }

    function test_IssueLCOnlyIssuingBank() public {
        uint256 dateOfIssue = block.timestamp;
        uint256 dateOfExpiry = block.timestamp + 30 days;

        vm.prank(buyer);
        vm.expectRevert(LocManagement.NotIssuingBank.selector);
        locManagement.issueLC(LC_NO, buyer, seller, LC_AMOUNT, dateOfIssue, dateOfExpiry);
    }

    function test_ActivateLC() public {
        uint256 dateOfIssue = block.timestamp;
        uint256 dateOfExpiry = block.timestamp + 30 days;

        // Issue LC
        vm.prank(issuingBank);
        locManagement.issueLC(LC_NO, buyer, seller, LC_AMOUNT, dateOfIssue, dateOfExpiry);

        address locAddress = locManagement.getLocContractAddress(LC_NO);

        // Approve LC
        vm.prank(issuingBank);
        locManagement.approveLC(LC_NO);

        // Activate LC via TreasureLedger
        vm.prank(issuingBank);
        treasureLedger.activateLoc(LC_NO);

        Loc locContract = Loc(locAddress);
        assertEq(locContract.getStatus(), "AC");
        assertEq(locContract.getAllowance(), LC_AMOUNT);
    }

    function test_SettleLC() public {
        uint256 dateOfIssue = block.timestamp;
        uint256 dateOfExpiry = block.timestamp + 30 days;

        // Issue LC
        vm.prank(issuingBank);
        locManagement.issueLC(LC_NO, buyer, seller, LC_AMOUNT, dateOfIssue, dateOfExpiry);

        address locAddress = locManagement.getLocContractAddress(LC_NO);

        // Approve LC
        vm.prank(issuingBank);
        locManagement.approveLC(LC_NO);

        // Activate LC via TreasureLedger
        vm.prank(issuingBank);
        treasureLedger.activateLoc(LC_NO);

        // Settle LC directly on Loc contract (seller initiates)
        uint256 sellerBalanceBefore = treasureLedger.balanceOf(seller);
        Loc locContract = Loc(locAddress);
        vm.prank(seller);
        locContract.settleLC();

        uint256 sellerBalanceAfter = treasureLedger.balanceOf(seller);
        assertEq(sellerBalanceAfter - sellerBalanceBefore, LC_AMOUNT);

        assertEq(locContract.getStatus(), "ST");
    }

    function test_ExpireLC() public {
        uint256 dateOfIssue = block.timestamp;
        uint256 dateOfExpiry = block.timestamp + 1 days;

        // Issue and activate LC
        vm.prank(issuingBank);
        locManagement.issueLC(LC_NO, buyer, seller, LC_AMOUNT, dateOfIssue, dateOfExpiry);

        address locAddress = locManagement.getLocContractAddress(LC_NO);

        // Approve LC
        vm.prank(issuingBank);
        locManagement.approveLC(LC_NO);

        // Activate LC via TreasureLedger
        vm.prank(issuingBank);
        treasureLedger.activateLoc(LC_NO);

        // Fast forward time past expiry
        vm.warp(block.timestamp + 2 days);

        // Expire LC
        vm.prank(issuingBank);
        locManagement.expireLC(LC_NO);

        Loc locContract = Loc(locManagement.getLocContractAddress(LC_NO));
        assertEq(locContract.getStatus(), "EX");
    }

    function test_GetLocData() public {
        uint256 dateOfIssue = block.timestamp;
        uint256 dateOfExpiry = block.timestamp + 30 days;

        vm.prank(issuingBank);
        locManagement.issueLC(LC_NO, buyer, seller, LC_AMOUNT, dateOfIssue, dateOfExpiry);

        Loc.LocData memory locData = locManagement.getLocData(LC_NO);
        assertEq(locData.locNo, LC_NO);
        assertEq(locData.buyerAcc, buyer);
        assertEq(locData.sellerAcc, seller);
        assertEq(locData.amount, LC_AMOUNT);
    }

    function test_DuplicateLCNo() public {
        uint256 dateOfIssue = block.timestamp;
        uint256 dateOfExpiry = block.timestamp + 30 days;

        vm.prank(issuingBank);
        locManagement.issueLC(LC_NO, buyer, seller, LC_AMOUNT, dateOfIssue, dateOfExpiry);

        vm.prank(issuingBank);
        vm.expectRevert(LocManagement.LCAlreadyExists.selector);
        locManagement.issueLC(LC_NO, buyer, seller, LC_AMOUNT, dateOfIssue, dateOfExpiry);
    }
}

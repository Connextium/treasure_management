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

    uint256 constant LC_AMOUNT = 10000e18;
    uint256 constant LC_NO = 1001;

    function setUp() public {
        vm.prank(owner);
        treasureLedger = new TreasureLedger();

        vm.prank(owner);
        locManagement = new LocManagement(address(treasureLedger), issuingBank);

        // Mint tokens for issuing bank
        vm.prank(owner);
        treasureLedger.mint(issuingBank, LC_AMOUNT * 2);
    }

    function test_IssueLC() public {
        uint256 dateOfIssue = block.timestamp;
        uint256 dateOfExpiry = block.timestamp + 30 days;

        vm.prank(issuingBank);
        locManagement.issueLC(LC_NO, buyer, seller, LC_AMOUNT, dateOfIssue, dateOfExpiry);

        assertTrue(locManagement.locExists(LC_NO));
        address locAddress = locManagement.getLocContractAddress(LC_NO);
        assertNotEq(locAddress, address(0));
    }

    function test_IssueLCOnlyIssuingBank() public {
        uint256 dateOfIssue = block.timestamp;
        uint256 dateOfExpiry = block.timestamp + 30 days;

        vm.prank(buyer);
        vm.expectRevert("LocManagement: caller is not the issuing bank");
        locManagement.issueLC(LC_NO, buyer, seller, LC_AMOUNT, dateOfIssue, dateOfExpiry);
    }

    function test_ActivateLC() public {
        uint256 dateOfIssue = block.timestamp;
        uint256 dateOfExpiry = block.timestamp + 30 days;

        // Issue LC
        vm.prank(issuingBank);
        locManagement.issueLC(LC_NO, buyer, seller, LC_AMOUNT, dateOfIssue, dateOfExpiry);

        address locAddress = locManagement.getLocContractAddress(LC_NO);

        // Approve funds for LC contract
        vm.prank(issuingBank);
        treasureLedger.approve(locAddress, LC_AMOUNT);

        // Activate LC
        vm.prank(issuingBank);
        locManagement.activateLC(LC_NO);

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

        // Approve and activate LC
        vm.prank(issuingBank);
        treasureLedger.approve(locAddress, LC_AMOUNT);

        vm.prank(issuingBank);
        locManagement.activateLC(LC_NO);

        // Settle LC (seller initiates)
        uint256 sellerBalanceBefore = treasureLedger.balanceOf(seller);
        vm.prank(seller);
        locManagement.settleLC(LC_NO);

        uint256 sellerBalanceAfter = treasureLedger.balanceOf(seller);
        assertEq(sellerBalanceAfter - sellerBalanceBefore, LC_AMOUNT);

        Loc locContract = Loc(locAddress);
        assertEq(locContract.getStatus(), "ST");
    }

    function test_ExpireLC() public {
        uint256 dateOfIssue = block.timestamp;
        uint256 dateOfExpiry = block.timestamp + 1 days;

        // Issue and activate LC
        vm.prank(issuingBank);
        locManagement.issueLC(LC_NO, buyer, seller, LC_AMOUNT, dateOfIssue, dateOfExpiry);

        address locAddress = locManagement.getLocContractAddress(LC_NO);

        vm.prank(issuingBank);
        treasureLedger.approve(locAddress, LC_AMOUNT);

        vm.prank(issuingBank);
        locManagement.activateLC(LC_NO);

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

    function test_GetAllLocNumbers() public {
        uint256 dateOfIssue = block.timestamp;
        uint256 dateOfExpiry = block.timestamp + 30 days;

        vm.prank(issuingBank);
        locManagement.issueLC(1001, buyer, seller, LC_AMOUNT, dateOfIssue, dateOfExpiry);

        vm.prank(issuingBank);
        locManagement.issueLC(1002, buyer, seller, LC_AMOUNT, dateOfIssue, dateOfExpiry);

        uint256[] memory allLocs = locManagement.getAllLocNumbers();
        assertEq(allLocs.length, 2);
        assertEq(allLocs[0], 1001);
        assertEq(allLocs[1], 1002);
    }

    function test_DuplicateLCNo() public {
        uint256 dateOfIssue = block.timestamp;
        uint256 dateOfExpiry = block.timestamp + 30 days;

        vm.prank(issuingBank);
        locManagement.issueLC(LC_NO, buyer, seller, LC_AMOUNT, dateOfIssue, dateOfExpiry);

        vm.prank(issuingBank);
        vm.expectRevert("LocManagement: LC already exists");
        locManagement.issueLC(LC_NO, buyer, seller, LC_AMOUNT, dateOfIssue, dateOfExpiry);
    }

    function test_SetIssuingBank() public {
        address newIssuingBank = address(5);

        vm.prank(owner);
        locManagement.setIssuingBank(newIssuingBank);

        assertEq(locManagement.issuingBank(), newIssuingBank);
    }
}

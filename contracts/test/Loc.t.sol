// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {TreasureLedger} from "../src/treasure/TreasureLedger.sol";
import {Loc} from "../src/letterofcredit/Loc.sol";

contract LocTest is Test {
    TreasureLedger public treasureLedger;
    Loc public loc;

    address owner = address(this);
    address issuingBank = address(1);
    address buyer = address(2);
    address seller = address(3);
    address forwarder = address(0x15fC6ae953E024d975e77382eEeC56A9101f9F88); // Mock forwarder address

    uint256 constant LC_NO = 1001;
    uint256 constant LC_AMOUNT = 10000e18;
    uint256 dateOfIssue;
    uint256 dateOfExpiry;

    function setUp() public {
        treasureLedger = new TreasureLedger(forwarder);
        
        dateOfIssue = block.timestamp;
        dateOfExpiry = block.timestamp + 30 days;

        // Create Loc contract (owner is this contract)
        loc = new Loc(
            LC_NO,
            buyer,
            seller,
            LC_AMOUNT,
            dateOfIssue,
            dateOfExpiry,
            address(treasureLedger),
            issuingBank
        );

        // Mint tokens to issuing bank
        treasureLedger.mint(issuingBank, LC_AMOUNT * 2);
    }

    function test_Constructor() public view {
        Loc.LocData memory data = loc.getLocData();
        
        assertEq(data.locNo, LC_NO);
        assertEq(data.buyerAcc, buyer);
        assertEq(data.sellerAcc, seller);
        assertEq(data.amount, LC_AMOUNT);
        assertEq(data.status, "IS");
        assertEq(data.dateOfIssue, dateOfIssue);
        assertEq(data.dateOfExpiry, dateOfExpiry);
        assertEq(data.treasureLedgerAddress, address(treasureLedger));
    }

    function test_GetStatus() public view {
        assertEq(loc.getStatus(), "IS");
        assertEq(loc.getStatusString(), "Issued");
    }

    function test_IsExpired() public {
        assertFalse(loc.isExpired());
        
        vm.warp(block.timestamp + 31 days);
        assertTrue(loc.isExpired());
    }

    function test_ActivateLC() public {
        // Approve allowance from issuing bank
        vm.prank(issuingBank);
        treasureLedger.approve(address(loc), LC_AMOUNT);

        // Activate LC (only owner can call)
        loc.activateLC();

        assertEq(loc.getStatus(), "AC");
        assertEq(loc.getStatusString(), "Active");
    }

    function test_ActivateLCOnlyOwner() public {
        vm.prank(issuingBank);
        treasureLedger.approve(address(loc), LC_AMOUNT);

        vm.prank(issuingBank);
        vm.expectRevert();
        loc.activateLC();
    }

    function test_ActivateLCRequiresIssuedStatus() public {
        vm.prank(issuingBank);
        treasureLedger.approve(address(loc), LC_AMOUNT);

        loc.activateLC();

        vm.expectRevert("Loc: LC must be in Issued status");
        loc.activateLC();
    }

    function test_ActivateLCRequiresNotExpired() public {
        vm.prank(issuingBank);
        treasureLedger.approve(address(loc), LC_AMOUNT);

        vm.warp(block.timestamp + 31 days);

        vm.expectRevert("Loc: LC has already expired");
        loc.activateLC();
    }

    function test_ActivateLCRequiresSufficientAllowance() public {
        vm.prank(issuingBank);
        treasureLedger.approve(address(loc), LC_AMOUNT - 1);

        vm.expectRevert("Loc: insufficient allowance for LC activation");
        loc.activateLC();
    }

    function test_SettleLCBySeller() public {
        // Activate LC first
        vm.prank(issuingBank);
        treasureLedger.approve(address(loc), LC_AMOUNT);
        loc.activateLC();

        // Seller settles LC
        uint256 sellerBalanceBefore = treasureLedger.balanceOf(seller);
        
        vm.prank(seller);
        loc.settleLC();

        uint256 sellerBalanceAfter = treasureLedger.balanceOf(seller);
        assertEq(sellerBalanceAfter - sellerBalanceBefore, LC_AMOUNT);
        assertEq(loc.getStatus(), "ST");
        assertEq(loc.getStatusString(), "Settled");
    }

    function test_SettleLCByOwner() public {
        // Activate LC first
        vm.prank(issuingBank);
        treasureLedger.approve(address(loc), LC_AMOUNT);
        loc.activateLC();

        // Owner settles LC
        uint256 sellerBalanceBefore = treasureLedger.balanceOf(seller);
        
        loc.settleLC();

        uint256 sellerBalanceAfter = treasureLedger.balanceOf(seller);
        assertEq(sellerBalanceAfter - sellerBalanceBefore, LC_AMOUNT);
        assertEq(loc.getStatus(), "ST");
    }

    function test_SettleLCUnauthorized() public {
        vm.prank(issuingBank);
        treasureLedger.approve(address(loc), LC_AMOUNT);
        loc.activateLC();

        vm.prank(buyer);
        vm.expectRevert("Loc: caller is not the seller or owner");
        loc.settleLC();
    }

    function test_SettleLCRequiresActiveStatus() public {
        vm.prank(seller);
        vm.expectRevert("Loc: LC must be in Active status");
        loc.settleLC();
    }

    function test_SettleLCRequiresNotExpired() public {
        vm.prank(issuingBank);
        treasureLedger.approve(address(loc), LC_AMOUNT);
        loc.activateLC();

        vm.warp(block.timestamp + 31 days);

        vm.prank(seller);
        vm.expectRevert("Loc: LC has expired");
        loc.settleLC();
    }

    function test_ExpireLC() public {
        vm.prank(issuingBank);
        treasureLedger.approve(address(loc), LC_AMOUNT);
        loc.activateLC();

        vm.warp(block.timestamp + 31 days);

        loc.expireLC();

        assertEq(loc.getStatus(), "EX");
        assertEq(loc.getStatusString(), "Expired");
    }

    function test_ExpireLCOnlyOwner() public {
        vm.prank(issuingBank);
        treasureLedger.approve(address(loc), LC_AMOUNT);
        loc.activateLC();

        vm.warp(block.timestamp + 31 days);

        vm.prank(issuingBank);
        vm.expectRevert();
        loc.expireLC();
    }

    function test_ExpireLCRequiresExpired() public {
        vm.prank(issuingBank);
        treasureLedger.approve(address(loc), LC_AMOUNT);
        loc.activateLC();

        vm.expectRevert("Loc: LC has not yet expired");
        loc.expireLC();
    }

    function test_ExpireLCFromIssuedStatus() public {
        vm.warp(block.timestamp + 31 days);

        loc.expireLC();

        assertEq(loc.getStatus(), "EX");
    }

    function test_ExpireLCInvalidStatus() public {
        vm.prank(issuingBank);
        treasureLedger.approve(address(loc), LC_AMOUNT);
        loc.activateLC();

        vm.prank(seller);
        loc.settleLC();

        vm.warp(block.timestamp + 31 days);

        vm.expectRevert("Loc: LC cannot be expired in current status");
        loc.expireLC();
    }

    function test_GetAllowance() public {
        assertEq(loc.getAllowance(), 0);

        vm.prank(issuingBank);
        treasureLedger.approve(address(loc), LC_AMOUNT);

        assertEq(loc.getAllowance(), LC_AMOUNT);
    }

    function test_GetIssuingBankBalance() public view {
        assertEq(loc.getIssuingBankBalance(), LC_AMOUNT * 2);
    }

    function test_CanFundLC() public {
        assertFalse(loc.canFundLC());

        vm.prank(issuingBank);
        treasureLedger.approve(address(loc), LC_AMOUNT);

        assertTrue(loc.canFundLC());
    }

    function test_GetFundingStatus() public {
        (uint256 allowance, uint256 required, bool isFunded) = loc.getFundingStatus();
        
        assertEq(allowance, 0);
        assertEq(required, LC_AMOUNT);
        assertFalse(isFunded);

        vm.prank(issuingBank);
        treasureLedger.approve(address(loc), LC_AMOUNT);

        (allowance, required, isFunded) = loc.getFundingStatus();
        
        assertEq(allowance, LC_AMOUNT);
        assertEq(required, LC_AMOUNT);
        assertTrue(isFunded);
    }

    function test_ConstructorInvalidBuyerAddress() public {
        vm.expectRevert("Loc: invalid buyer address");
        new Loc(
            LC_NO,
            address(0),
            seller,
            LC_AMOUNT,
            dateOfIssue,
            dateOfExpiry,
            address(treasureLedger),
            issuingBank
        );
    }

    function test_ConstructorInvalidSellerAddress() public {
        vm.expectRevert("Loc: invalid seller address");
        new Loc(
            LC_NO,
            buyer,
            address(0),
            LC_AMOUNT,
            dateOfIssue,
            dateOfExpiry,
            address(treasureLedger),
            issuingBank
        );
    }

    function test_ConstructorInvalidTreasuryAddress() public {
        vm.expectRevert("Loc: invalid treasury address");
        new Loc(
            LC_NO,
            buyer,
            seller,
            LC_AMOUNT,
            dateOfIssue,
            dateOfExpiry,
            address(0),
            issuingBank
        );
    }

    function test_ConstructorInvalidIssuingBankAddress() public {
        vm.expectRevert("Loc: invalid issuing bank address");
        new Loc(
            LC_NO,
            buyer,
            seller,
            LC_AMOUNT,
            dateOfIssue,
            dateOfExpiry,
            address(treasureLedger),
            address(0)
        );
    }

    function test_ConstructorInvalidAmount() public {
        vm.expectRevert("Loc: amount must be greater than 0");
        new Loc(
            LC_NO,
            buyer,
            seller,
            0,
            dateOfIssue,
            dateOfExpiry,
            address(treasureLedger),
            issuingBank
        );
    }

    function test_ConstructorInvalidExpiryDate() public {
        vm.expectRevert("Loc: expiry date must be after issue date");
        new Loc(
            LC_NO,
            buyer,
            seller,
            LC_AMOUNT,
            dateOfIssue,
            dateOfIssue - 1,
            address(treasureLedger),
            issuingBank
        );
    }

    function test_FullLifecycleSettlement() public {
        // 1. Check initial state
        assertEq(loc.getStatusString(), "Issued");
        
        // 2. Approve and activate
        vm.prank(issuingBank);
        treasureLedger.approve(address(loc), LC_AMOUNT);
        loc.activateLC();
        assertEq(loc.getStatusString(), "Active");
        
        // 3. Settle
        vm.prank(seller);
        loc.settleLC();
        assertEq(loc.getStatusString(), "Settled");
        
        // 4. Verify funds transferred
        assertEq(treasureLedger.balanceOf(seller), LC_AMOUNT);
    }

    function test_FullLifecycleExpiry() public {
        // 1. Check initial state
        assertEq(loc.getStatusString(), "Issued");
        
        // 2. Approve and activate
        vm.prank(issuingBank);
        treasureLedger.approve(address(loc), LC_AMOUNT);
        loc.activateLC();
        assertEq(loc.getStatusString(), "Active");
        
        // 3. Warp past expiry
        vm.warp(block.timestamp + 31 days);
        
        // 4. Expire
        loc.expireLC();
        assertEq(loc.getStatusString(), "Expired");
        
        // 5. Verify funds stayed with issuing bank
        assertEq(treasureLedger.balanceOf(seller), 0);
        assertEq(treasureLedger.balanceOf(issuingBank), LC_AMOUNT * 2);
    }
}
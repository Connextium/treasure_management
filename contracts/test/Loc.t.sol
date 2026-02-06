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

    uint256 constant LC_NO = 1001;
    uint256 constant LC_AMOUNT = 10000e18;
    uint256 dateOfIssue;
    uint256 dateOfExpiry;

    // Mock LocManagement registry for testing
    mapping(uint256 => address) public locContracts;

    function setUp() public {
        treasureLedger = new TreasureLedger();
        
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
            issuingBank,
            address(this) // Mock LocManagement address
        );

        // Register LC in mock registry for validation
        locContracts[LC_NO] = address(loc);

        // Register and grant this contract (mock LocManagement) ROLE_MINT
        treasureLedger.addParticipant(address(this));
        treasureLedger.grantRoles(address(this), treasureLedger.ROLE_MINT());

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
        loc.setStatus("AC");

        assertEq(loc.getStatus(), "AC");
        assertEq(loc.getStatusString(), "Active");
    }

    function test_ActivateLCOnlyOwner() public {
        vm.prank(issuingBank);
        treasureLedger.approve(address(loc), LC_AMOUNT);

        vm.prank(issuingBank);
        vm.expectRevert();
        loc.setStatus("AC");
    }

    function test_SettleLCBySeller() public {
        // Activate LC first
        vm.prank(issuingBank);
        treasureLedger.approve(address(loc), LC_AMOUNT);
        loc.setStatus("AC");

        // Seller settles LC
        uint256 sellerBalanceBefore = treasureLedger.balanceOf(seller);
        
        vm.prank(seller);
        loc.settleLC();

        uint256 sellerBalanceAfter = treasureLedger.balanceOf(seller);
        assertEq(sellerBalanceAfter - sellerBalanceBefore, LC_AMOUNT);
        assertEq(loc.getStatus(), "ST");
        assertEq(loc.getStatusString(), "Settled");
    }

    function test_SettleLCUnauthorized() public {
        vm.prank(issuingBank);
        treasureLedger.approve(address(loc), LC_AMOUNT);
        loc.setStatus("AC");

        vm.prank(buyer);
        vm.expectRevert("Loc: caller is not the seller");
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
        loc.setStatus("AC");

        vm.warp(block.timestamp + 31 days);

        vm.prank(seller);
        vm.expectRevert("Loc: LC has expired");
        loc.settleLC();
    }

    function test_ExpireLC() public {
        vm.prank(issuingBank);
        treasureLedger.approve(address(loc), LC_AMOUNT);
        loc.setStatus("AC");

        vm.warp(block.timestamp + 31 days);

        loc.setStatus("EX");

        assertEq(loc.getStatus(), "EX");
        assertEq(loc.getStatusString(), "Expired");
    }

    function test_ExpireLCOnlyOwner() public {
        vm.prank(issuingBank);
        treasureLedger.approve(address(loc), LC_AMOUNT);
        loc.setStatus("AC");

        vm.warp(block.timestamp + 31 days);

        vm.prank(issuingBank);
        vm.expectRevert();
        loc.setStatus("EX");
    }

    function test_ExpireLCFromIssuedStatus() public {
        vm.warp(block.timestamp + 31 days);

        loc.setStatus("EX");

        assertEq(loc.getStatus(), "EX");
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
            issuingBank,
            address(this)
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
            issuingBank,
            address(this)
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
            issuingBank,
            address(this)
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
            address(0),
            address(this)
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
            issuingBank,
            address(this)
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
            issuingBank,
            address(this)
        );
    }

    function test_FullLifecycleSettlement() public {
        // 1. Check initial state
        assertEq(loc.getStatusString(), "Issued");
        
        // 2. Approve and activate
        vm.prank(issuingBank);
        treasureLedger.approve(address(loc), LC_AMOUNT);
        loc.setStatus("AC");
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
        loc.setStatus("AC");
        assertEq(loc.getStatusString(), "Active");
        
        // 3. Warp past expiry
        vm.warp(block.timestamp + 31 days);
        
        // 4. Expire
        loc.setStatus("EX");
        assertEq(loc.getStatusString(), "Expired");
        
        // 5. Verify funds stayed with issuing bank
        assertEq(treasureLedger.balanceOf(seller), 0);
        assertEq(treasureLedger.balanceOf(issuingBank), LC_AMOUNT * 2);
    }

    // ================================================================
    // │           SECURITY TESTS: Registry-Based Validation          │
    // ================================================================

    function test_ConstructorInvalidLocManagementAddress() public {
        vm.expectRevert("Loc: invalid LocManagement address");
        new Loc(
            LC_NO,
            buyer,
            seller,
            LC_AMOUNT,
            dateOfIssue,
            dateOfExpiry,
            address(treasureLedger),
            issuingBank,
            address(0) // Invalid LocManagement address
        );
    }

    function test_SettleLCRequiresRegistration() public {
        // Create a malicious LC with attacker as seller, NOT registered in LocManagement
        address attacker = address(0x999);
        uint256 maliciousLcNo = 9999;
        
        // Attacker creates their own LC contract
        Loc maliciousLoc = new Loc(
            maliciousLcNo,
            buyer,
            attacker, // Attacker sets themselves as seller
            LC_AMOUNT,
            dateOfIssue,
            dateOfExpiry,
            address(treasureLedger),
            issuingBank,
            address(this) // Uses same LocManagement address
        );
        
        // NOTE: Attacker does NOT register in locContracts mapping
        // locContracts[maliciousLcNo] = address(maliciousLoc); // <-- NOT DONE
        
        // Approve funds for the malicious LC (simulating LocManagement approving)
        vm.prank(issuingBank);
        treasureLedger.approve(address(maliciousLoc), LC_AMOUNT);
        
        // Activate the malicious LC
        vm.prank(address(this)); // Owner (LocManagement) can activate
        maliciousLoc.setStatus("AC");
        
        // Attacker tries to settle and steal funds
        vm.prank(attacker);
        vm.expectRevert("Loc: not registered in LocManagement");
        maliciousLoc.settleLC();
        
        // Verify attacker got no funds
        assertEq(treasureLedger.balanceOf(attacker), 0);
        assertEq(treasureLedger.balanceOf(issuingBank), LC_AMOUNT * 2); // Funds stay with bank
    }

    function test_OnlyRegisteredLCCanSettle() public {
        // Verify legitimate LC IS registered
        assertEq(locContracts[LC_NO], address(loc));
        
        // Activate and settle legitimate LC - should work
        vm.prank(issuingBank);
        treasureLedger.approve(address(loc), LC_AMOUNT);
        loc.setStatus("AC");
        
        vm.prank(seller);
        loc.settleLC(); // Should succeed because it's registered
        
        assertEq(loc.getStatus(), "ST");
        assertEq(treasureLedger.balanceOf(seller), LC_AMOUNT);
    }

    function test_UnregisteringLCPreventsSettlement() public {
        // Setup: Activate LC first
        vm.prank(issuingBank);
        treasureLedger.approve(address(loc), LC_AMOUNT);
        loc.setStatus("AC");
        
        // Simulate unregistering the LC (e.g., malicious registry manipulation)
        locContracts[LC_NO] = address(0);
        
        // Now settlement should fail
        vm.prank(seller);
        vm.expectRevert("Loc: not registered in LocManagement");
        loc.settleLC();
    }

    function test_WrongRegistryEntryPreventsSettlement() public {
        // Setup: Activate LC first
        vm.prank(issuingBank);
        treasureLedger.approve(address(loc), LC_AMOUNT);
        loc.setStatus("AC");
        
        // Attacker tries to register a different address for the same LC number
        address fakeLocAddress = address(0xdead);
        locContracts[LC_NO] = fakeLocAddress;
        
        // Now settlement should fail because registry points to different address
        vm.prank(seller);
        vm.expectRevert("Loc: not registered in LocManagement");
        loc.settleLC();
    }

    function test_LocManagementAddressIsImmutable() public view {
        // Verify locManagement is set correctly
        assertEq(loc.locManagement(), address(this));
        
        // Note: Being immutable, it cannot be changed after deployment
        // This test verifies the address is stored correctly
    }

    function test_MultipleUnregisteredLCsCannotStealFunds() public {
        // Simulate multiple attackers creating malicious LCs
        address attacker1 = address(0xBAD1);
        address attacker2 = address(0xBAD2);
        
        Loc maliciousLoc1 = new Loc(
            8888,
            buyer,
            attacker1,
            LC_AMOUNT / 2,
            dateOfIssue,
            dateOfExpiry,
            address(treasureLedger),
            issuingBank,
            address(this)
        );
        
        Loc maliciousLoc2 = new Loc(
            7777,
            buyer,
            attacker2,
            LC_AMOUNT / 2,
            dateOfIssue,
            dateOfExpiry,
            address(treasureLedger),
            issuingBank,
            address(this)
        );
        
        // Approve funds
        vm.prank(issuingBank);
        treasureLedger.approve(address(maliciousLoc1), LC_AMOUNT / 2);
        vm.prank(issuingBank);
        treasureLedger.approve(address(maliciousLoc2), LC_AMOUNT / 2);
        
        // Activate both
        vm.prank(address(this));
        maliciousLoc1.setStatus("AC");
        vm.prank(address(this));
        maliciousLoc2.setStatus("AC");
        
        // Both settlement attempts should fail
        vm.prank(attacker1);
        vm.expectRevert("Loc: not registered in LocManagement");
        maliciousLoc1.settleLC();
        
        vm.prank(attacker2);
        vm.expectRevert("Loc: not registered in LocManagement");
        maliciousLoc2.settleLC();
        
        // Verify no funds stolen
        assertEq(treasureLedger.balanceOf(attacker1), 0);
        assertEq(treasureLedger.balanceOf(attacker2), 0);
        assertEq(treasureLedger.balanceOf(issuingBank), LC_AMOUNT * 2);
    }
}
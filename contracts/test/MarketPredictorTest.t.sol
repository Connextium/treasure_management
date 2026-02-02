// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MarketPredictor} from "../src/market_predictor/MarketPredictor.sol";

contract MarketPredictorTest is Test {
    MarketPredictor public marketPredictor;
    
    address owner = address(this);
    address creator = address(1);
    address predictor1 = address(2);
    address predictor2 = address(3);
    address forwarder = address(0x15fC6ae953E024d975e77382eEeC56A9101f9F88);
    
    uint256 constant BET_AMOUNT = 1 ether;
    
    function setUp() public {
        marketPredictor = new MarketPredictor(forwarder);
    }
    
    // ========== Market Creation Tests ==========
    
    function test_CreateMarket() public {
        vm.prank(creator);
        uint256 marketId = marketPredictor.createMarket("Will BTC reach $100k?");
        
        assertEq(marketId, 0);
        MarketPredictor.Market memory market = marketPredictor.getMarket(marketId);
        assertEq(market.creator, creator);
        assertEq(market.question, "Will BTC reach $100k?");
        assertFalse(market.settled);
        assertEq(market.totalYesPool, 0);
        assertEq(market.totalNoPool, 0);
    }
    
    function test_CreateMultipleMarkets() public {
        vm.startPrank(creator);
        uint256 market1 = marketPredictor.createMarket("Question 1");
        uint256 market2 = marketPredictor.createMarket("Question 2");
        vm.stopPrank();
        
        assertEq(market1, 0);
        assertEq(market2, 1);
    }
    
    // ========== Prediction Tests ==========
    
    function test_PredictYes() public {
        vm.prank(creator);
        uint256 marketId = marketPredictor.createMarket("Test question");
        
        vm.deal(predictor1, BET_AMOUNT);
        vm.prank(predictor1);
        marketPredictor.predict{value: BET_AMOUNT}(marketId, MarketPredictor.Prediction.Yes);
        
        MarketPredictor.Market memory market = marketPredictor.getMarket(marketId);
        assertEq(market.totalYesPool, BET_AMOUNT);
        assertEq(market.totalNoPool, 0);
        
        MarketPredictor.UserPrediction memory userPred = marketPredictor.getPrediction(marketId, predictor1);
        assertEq(userPred.amount, BET_AMOUNT);
        assertEq(uint(userPred.prediction), uint(MarketPredictor.Prediction.Yes));
        assertFalse(userPred.claimed);
    }
    
    function test_PredictNo() public {
        vm.prank(creator);
        uint256 marketId = marketPredictor.createMarket("Test question");
        
        vm.deal(predictor1, BET_AMOUNT);
        vm.prank(predictor1);
        marketPredictor.predict{value: BET_AMOUNT}(marketId, MarketPredictor.Prediction.No);
        
        MarketPredictor.Market memory market = marketPredictor.getMarket(marketId);
        assertEq(market.totalYesPool, 0);
        assertEq(market.totalNoPool, BET_AMOUNT);
    }
    
    function test_MultiplePredictions() public {
        vm.prank(creator);
        uint256 marketId = marketPredictor.createMarket("Test question");
        
        vm.deal(predictor1, BET_AMOUNT);
        vm.prank(predictor1);
        marketPredictor.predict{value: BET_AMOUNT}(marketId, MarketPredictor.Prediction.Yes);
        
        vm.deal(predictor2, BET_AMOUNT * 2);
        vm.prank(predictor2);
        marketPredictor.predict{value: BET_AMOUNT * 2}(marketId, MarketPredictor.Prediction.No);
        
        MarketPredictor.Market memory market = marketPredictor.getMarket(marketId);
        assertEq(market.totalYesPool, BET_AMOUNT);
        assertEq(market.totalNoPool, BET_AMOUNT * 2);
    }
    
    function test_RevertPredictNonexistentMarket() public {
        vm.deal(predictor1, BET_AMOUNT);
        vm.prank(predictor1);
        vm.expectRevert(MarketPredictor.MarketDoesNotExist.selector);
        marketPredictor.predict{value: BET_AMOUNT}(999, MarketPredictor.Prediction.Yes);
    }
    
    function test_RevertPredictZeroAmount() public {
        vm.prank(creator);
        uint256 marketId = marketPredictor.createMarket("Test question");
        
        vm.prank(predictor1);
        vm.expectRevert(MarketPredictor.InvalidAmount.selector);
        marketPredictor.predict{value: 0}(marketId, MarketPredictor.Prediction.Yes);
    }
    
    function test_RevertPredictTwice() public {
        vm.prank(creator);
        uint256 marketId = marketPredictor.createMarket("Test question");
        
        vm.deal(predictor1, BET_AMOUNT * 2);
        vm.startPrank(predictor1);
        marketPredictor.predict{value: BET_AMOUNT}(marketId, MarketPredictor.Prediction.Yes);
        
        vm.expectRevert(MarketPredictor.AlreadyPredicted.selector);
        marketPredictor.predict{value: BET_AMOUNT}(marketId, MarketPredictor.Prediction.Yes);
        vm.stopPrank();
    }
    
    // ========== Settlement Request Tests ==========
    
    function test_RequestSettlement() public {
        vm.prank(creator);
        uint256 marketId = marketPredictor.createMarket("Test question");
        
        vm.expectEmit(true, true, true, true);
        emit MarketPredictor.SettlementRequested(marketId, "Test question");
        
        marketPredictor.requestSettlement(marketId);
    }
    
    function test_RevertRequestSettlementNonexistent() public {
        vm.expectRevert(MarketPredictor.MarketDoesNotExist.selector);
        marketPredictor.requestSettlement(999);
    }
    
    // ========== CRE Settlement Tests ==========
    
    function test_SettleMarketViaProcessReport() public {
        vm.prank(creator);
        uint256 marketId = marketPredictor.createMarket("Test question");
        
        // Encode settlement data with function selector
        bytes4 selector = bytes4(keccak256("settleMarket(uint256,uint8,uint16)"));
        bytes memory report = abi.encodePacked(
            selector,
            abi.encode(marketId, MarketPredictor.Prediction.Yes, uint16(95))
        );
        
        vm.prank(forwarder);
        marketPredictor.onReport("", report);
        
        MarketPredictor.Market memory market = marketPredictor.getMarket(marketId);
        assertTrue(market.settled);
        assertEq(uint(market.outcome), uint(MarketPredictor.Prediction.Yes));
        assertEq(market.confidence, 95);
    }
    
    function test_CreateMarketViaProcessReport() public {
        bytes4 selector = bytes4(keccak256("createMarket(string)"));
        bytes memory report = abi.encodePacked(
            selector,
            abi.encode("CRE Created Market")
        );
        
        vm.prank(forwarder);
        marketPredictor.onReport("", report);
        
        MarketPredictor.Market memory market = marketPredictor.getMarket(0);
        assertEq(market.question, "CRE Created Market");
        assertEq(market.creator, forwarder);
    }
    
    function test_RevertInvalidSelector() public {
        bytes memory report = abi.encodePacked(bytes4(0x12345678), abi.encode("test"));
        
        vm.prank(forwarder);
        vm.expectRevert(MarketPredictor.InvalidSelector.selector);
        marketPredictor.onReport("", report);
    }
    
    function test_RevertSettleAlreadySettled() public {
        vm.prank(creator);
        uint256 marketId = marketPredictor.createMarket("Test question");
        
        bytes4 selector = bytes4(keccak256("settleMarket(uint256,uint8,uint16)"));
        bytes memory report = abi.encodePacked(
            selector,
            abi.encode(marketId, MarketPredictor.Prediction.Yes, uint16(95))
        );
        
        vm.prank(forwarder);
        marketPredictor.onReport("", report);
        
        vm.prank(forwarder);
        vm.expectRevert(MarketPredictor.MarketAlreadySettled.selector);
        marketPredictor.onReport("", report);
    }
    
    function test_RevertPredictOnSettledMarket() public {
        vm.prank(creator);
        uint256 marketId = marketPredictor.createMarket("Test question");
        
        // Settle market
        bytes4 selector = bytes4(keccak256("settleMarket(uint256,uint8,uint16)"));
        bytes memory report = abi.encodePacked(
            selector,
            abi.encode(marketId, MarketPredictor.Prediction.Yes, uint16(95))
        );
        vm.prank(forwarder);
        marketPredictor.onReport("", report);
        
        // Try to predict
        vm.deal(predictor1, BET_AMOUNT);
        vm.prank(predictor1);
        vm.expectRevert(MarketPredictor.MarketAlreadySettled.selector);
        marketPredictor.predict{value: BET_AMOUNT}(marketId, MarketPredictor.Prediction.Yes);
    }
    
    // ========== CRE Predict Tests ==========
    
    function test_PredictViaProcessReport() public {
        vm.prank(creator);
        uint256 marketId = marketPredictor.createMarket("Test question");
        
        // Encode prediction data with function selector
        bytes4 selector = bytes4(keccak256("predict(uint256,uint8)"));
        bytes memory report = abi.encodePacked(
            selector,
            abi.encode(marketId, MarketPredictor.Prediction.Yes)
        );
        
        // Send prediction via CRE forwarder with ETH
        vm.deal(forwarder, BET_AMOUNT);
        vm.prank(forwarder);
        marketPredictor.onReport{value: BET_AMOUNT}("", report);
        
        // Verify prediction was recorded
        MarketPredictor.UserPrediction memory userPred = marketPredictor.getPrediction(marketId, forwarder);
        assertEq(userPred.amount, BET_AMOUNT);
        assertEq(uint(userPred.prediction), uint(MarketPredictor.Prediction.Yes));
        assertFalse(userPred.claimed);
        
        // Verify pool updated
        MarketPredictor.Market memory market = marketPredictor.getMarket(marketId);
        assertEq(market.totalYesPool, BET_AMOUNT);
        assertEq(market.totalNoPool, 0);
    }
    
    function test_PredictNoViaProcessReport() public {
        vm.prank(creator);
        uint256 marketId = marketPredictor.createMarket("Test question");
        
        bytes4 selector = bytes4(keccak256("predict(uint256,uint8)"));
        bytes memory report = abi.encodePacked(
            selector,
            abi.encode(marketId, MarketPredictor.Prediction.No)
        );
        
        vm.deal(forwarder, BET_AMOUNT);
        vm.prank(forwarder);
        marketPredictor.onReport{value: BET_AMOUNT}("", report);
        
        MarketPredictor.UserPrediction memory userPred = marketPredictor.getPrediction(marketId, forwarder);
        assertEq(uint(userPred.prediction), uint(MarketPredictor.Prediction.No));
        
        MarketPredictor.Market memory market = marketPredictor.getMarket(marketId);
        assertEq(market.totalYesPool, 0);
        assertEq(market.totalNoPool, BET_AMOUNT);
    }
    
    function test_RevertPredictViaProcessReportZeroAmount() public {
        vm.prank(creator);
        uint256 marketId = marketPredictor.createMarket("Test question");
        
        bytes4 selector = bytes4(keccak256("predict(uint256,uint8)"));
        bytes memory report = abi.encodePacked(
            selector,
            abi.encode(marketId, MarketPredictor.Prediction.Yes)
        );
        
        vm.prank(forwarder);
        vm.expectRevert(MarketPredictor.InvalidAmount.selector);
        marketPredictor.onReport{value: 0}("", report);
    }
    
    function test_RevertPredictViaProcessReportNonexistentMarket() public {
        bytes4 selector = bytes4(keccak256("predict(uint256,uint8)"));
        bytes memory report = abi.encodePacked(
            selector,
            abi.encode(999, MarketPredictor.Prediction.Yes)
        );
        
        vm.deal(forwarder, BET_AMOUNT);
        vm.prank(forwarder);
        vm.expectRevert(MarketPredictor.MarketDoesNotExist.selector);
        marketPredictor.onReport{value: BET_AMOUNT}("", report);
    }
    
    function test_RevertPredictViaProcessReportTwice() public {
        vm.prank(creator);
        uint256 marketId = marketPredictor.createMarket("Test question");
        
        bytes4 selector = bytes4(keccak256("predict(uint256,uint8)"));
        bytes memory report = abi.encodePacked(
            selector,
            abi.encode(marketId, MarketPredictor.Prediction.Yes)
        );
        
        vm.deal(forwarder, BET_AMOUNT * 2);
        vm.prank(forwarder);
        marketPredictor.onReport{value: BET_AMOUNT}("", report);
        
        vm.prank(forwarder);
        vm.expectRevert(MarketPredictor.AlreadyPredicted.selector);
        marketPredictor.onReport{value: BET_AMOUNT}("", report);
    }
    
    function test_PredictViaProcessReportAndClaim() public {
        vm.prank(creator);
        uint256 marketId = marketPredictor.createMarket("Test question");
        
        // Predict via CRE
        bytes4 predictSelector = bytes4(keccak256("predict(uint256,uint8)"));
        bytes memory predictReport = abi.encodePacked(
            predictSelector,
            abi.encode(marketId, MarketPredictor.Prediction.Yes)
        );
        
        vm.deal(forwarder, BET_AMOUNT);
        vm.prank(forwarder);
        marketPredictor.onReport{value: BET_AMOUNT}("", predictReport);
        
        // Settle market
        bytes4 settleSelector = bytes4(keccak256("settleMarket(uint256,uint8,uint16)"));
        bytes memory settleReport = abi.encodePacked(
            settleSelector,
            abi.encode(marketId, MarketPredictor.Prediction.Yes, uint16(95))
        );
        
        vm.prank(forwarder);
        marketPredictor.onReport("", settleReport);
        
        // Claim winnings
        uint256 balanceBefore = forwarder.balance;
        vm.prank(forwarder);
        marketPredictor.claim(marketId);
        uint256 balanceAfter = forwarder.balance;
        
        assertEq(balanceAfter - balanceBefore, BET_AMOUNT);
    }
    
    // ========== Claim Winnings Tests ==========
    
    function test_ClaimWinnings() public {
        vm.prank(creator);
        uint256 marketId = marketPredictor.createMarket("Test question");
        
        // Two predictors bet
        vm.deal(predictor1, BET_AMOUNT);
        vm.prank(predictor1);
        marketPredictor.predict{value: BET_AMOUNT}(marketId, MarketPredictor.Prediction.Yes);
        
        vm.deal(predictor2, BET_AMOUNT);
        vm.prank(predictor2);
        marketPredictor.predict{value: BET_AMOUNT}(marketId, MarketPredictor.Prediction.No);
        
        // Settle market - Yes wins
        bytes4 selector = bytes4(keccak256("settleMarket(uint256,uint8,uint16)"));
        bytes memory report = abi.encodePacked(
            selector,
            abi.encode(marketId, MarketPredictor.Prediction.Yes, uint16(90))
        );
        vm.prank(forwarder);
        marketPredictor.onReport("", report);
        
        // Winner claims
        uint256 balanceBefore = predictor1.balance;
        vm.prank(predictor1);
        marketPredictor.claim(marketId);
        uint256 balanceAfter = predictor1.balance;
        
        assertEq(balanceAfter - balanceBefore, BET_AMOUNT * 2); // Won entire pool
    }
    
    function test_ClaimProportionalWinnings() public {
        vm.prank(creator);
        uint256 marketId = marketPredictor.createMarket("Test question");
        
        // Multiple Yes predictions
        vm.deal(predictor1, BET_AMOUNT);
        vm.prank(predictor1);
        marketPredictor.predict{value: BET_AMOUNT}(marketId, MarketPredictor.Prediction.Yes);
        
        address predictor3 = address(4);
        vm.deal(predictor3, BET_AMOUNT);
        vm.prank(predictor3);
        marketPredictor.predict{value: BET_AMOUNT}(marketId, MarketPredictor.Prediction.Yes);
        
        // One No prediction
        vm.deal(predictor2, BET_AMOUNT * 2);
        vm.prank(predictor2);
        marketPredictor.predict{value: BET_AMOUNT * 2}(marketId, MarketPredictor.Prediction.No);
        
        // Settle - Yes wins
        bytes4 selector = bytes4(keccak256("settleMarket(uint256,uint8,uint16)"));
        bytes memory report = abi.encodePacked(
            selector,
            abi.encode(marketId, MarketPredictor.Prediction.Yes, uint16(90))
        );
        vm.prank(forwarder);
        marketPredictor.onReport("", report);
        
        // Each winner gets proportional share
        vm.prank(predictor1);
        marketPredictor.claim(marketId);
        assertEq(predictor1.balance, BET_AMOUNT * 2); // (1 ETH / 2 ETH) * 4 ETH total = 2 ETH
    }
    
    function test_RevertClaimNotSettled() public {
        vm.prank(creator);
        uint256 marketId = marketPredictor.createMarket("Test question");
        
        vm.deal(predictor1, BET_AMOUNT);
        vm.prank(predictor1);
        marketPredictor.predict{value: BET_AMOUNT}(marketId, MarketPredictor.Prediction.Yes);
        
        vm.prank(predictor1);
        vm.expectRevert(MarketPredictor.MarketNotSettled.selector);
        marketPredictor.claim(marketId);
    }
    
    function test_RevertClaimNoPrediction() public {
        vm.prank(creator);
        uint256 marketId = marketPredictor.createMarket("Test question");
        
        // Settle without predictions
        bytes4 selector = bytes4(keccak256("settleMarket(uint256,uint8,uint16)"));
        bytes memory report = abi.encodePacked(
            selector,
            abi.encode(marketId, MarketPredictor.Prediction.Yes, uint16(90))
        );
        vm.prank(forwarder);
        marketPredictor.onReport("", report);
        
        vm.prank(predictor1);
        vm.expectRevert(MarketPredictor.NothingToClaim.selector);
        marketPredictor.claim(marketId);
    }
    
    function test_RevertClaimLosingPrediction() public {
        vm.prank(creator);
        uint256 marketId = marketPredictor.createMarket("Test question");
        
        vm.deal(predictor1, BET_AMOUNT);
        vm.prank(predictor1);
        marketPredictor.predict{value: BET_AMOUNT}(marketId, MarketPredictor.Prediction.No);
        
        // Settle - Yes wins
        bytes4 selector = bytes4(keccak256("settleMarket(uint256,uint8,uint16)"));
        bytes memory report = abi.encodePacked(
            selector,
            abi.encode(marketId, MarketPredictor.Prediction.Yes, uint16(90))
        );
        vm.prank(forwarder);
        marketPredictor.onReport("", report);
        
        vm.prank(predictor1);
        vm.expectRevert(MarketPredictor.NothingToClaim.selector);
        marketPredictor.claim(marketId);
    }
    
    function test_RevertClaimTwice() public {
        vm.prank(creator);
        uint256 marketId = marketPredictor.createMarket("Test question");
        
        vm.deal(predictor1, BET_AMOUNT);
        vm.prank(predictor1);
        marketPredictor.predict{value: BET_AMOUNT}(marketId, MarketPredictor.Prediction.Yes);
        
        // Settle - Yes wins
        bytes4 selector = bytes4(keccak256("settleMarket(uint256,uint8,uint16)"));
        bytes memory report = abi.encodePacked(
            selector,
            abi.encode(marketId, MarketPredictor.Prediction.Yes, uint16(90))
        );
        vm.prank(forwarder);
        marketPredictor.onReport("", report);
        
        vm.startPrank(predictor1);
        marketPredictor.claim(marketId);
        
        vm.expectRevert(MarketPredictor.AlreadyClaimed.selector);
        marketPredictor.claim(marketId);
        vm.stopPrank();
    }
    
    // Make contract able to receive ETH
    receive() external payable {}
}
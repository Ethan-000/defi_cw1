// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/TradingPlatform.sol";
import "../src/PokemonCards.sol";

contract TradingPlatformTest is Test {
    TradingPlatform public tradingPlatform;
    PokemonCards public pokemonCards;
    
    address public owner;
    address public user1;
    address public user2;
    address public user3;

    // Events from the contract to test
    event Listed(uint256 indexed tokenId, address indexed seller, uint256 price, bool isAuction);
    event Sale(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);
    event AuctionBid(uint256 indexed tokenId, address indexed bidder, uint256 bid);
    event ListingCancelled(uint256 indexed tokenId);

    function setUp() public {
        owner = address(this);
        user1 = address(0x123);
        user2 = address(0x456);
        user3 = address(0x789);

        vm.label(user1, "User 1");
        vm.label(user2, "User 2");
        vm.label(user3, "User 3");

        // Deploy PokemonCards contract
        pokemonCards = new PokemonCards("ipfs://test/");

        // Deploy TradingPlatform contract
        tradingPlatform = new TradingPlatform(address(pokemonCards));

        // Mint some tokens to users for testing
        pokemonCards.flipSaleState();
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);

        vm.startPrank(user1);
        pokemonCards.mintPokemonCards{value: 0.00008 ether}(1);
        vm.stopPrank();

        vm.startPrank(user2);
        pokemonCards.mintPokemonCards{value: 0.00008 ether}(1);
        vm.stopPrank();
    }

    // Test listing a card for sale
    function testListCard() public {
    uint256 tokenId = 0;
    uint256 price = 1 ether;

    vm.startPrank(user1);
    pokemonCards.approve(address(tradingPlatform), tokenId);
    vm.expectEmit(true, true, true, true);
    emit Listed(tokenId, user1, price, false);
    tradingPlatform.listCard(tokenId, price);
    vm.stopPrank();

    // Destructure the tuple returned by listings(tokenId)
    (
        address seller,
        ,  // tokenId
        uint256 listingPrice,
        ,  // deadline
        bool isAuction,
        ,  // highestBidder
        ,  // highestBid
        bool active
    ) = tradingPlatform.listings(tokenId);

    // Assertions
    assertEq(seller, user1);
    assertEq(listingPrice, price);
    assertEq(isAuction, false);
    assertEq(active, true);
}

    // Test purchasing a listed card
    function testPurchaseCard() public {
    uint256 tokenId = 0;
    uint256 price = 1 ether;

    vm.startPrank(user1);
    pokemonCards.approve(address(tradingPlatform), tokenId);
    tradingPlatform.listCard(tokenId, price);
    vm.stopPrank();

    vm.startPrank(user2);
    vm.expectEmit(true, true, true, true);
    emit Sale(tokenId, user1, user2, price);
    tradingPlatform.purchaseCard{value: price}(tokenId);
    vm.stopPrank();

    // Destructure the tuple to get the active status
    (,,,,,,,bool active) = tradingPlatform.listings(tokenId);

    assertEq(pokemonCards.ownerOf(tokenId), user2);
    assertEq(active, false);
}

    // Test creating an auction
    function testCreateAuction() public {
    uint256 tokenId = 0;
    uint256 startingPrice = 0.5 ether;
    uint256 duration = 1 days;

    vm.startPrank(user1);
    pokemonCards.approve(address(tradingPlatform), tokenId);
    vm.expectEmit(true, true, true, true);
    emit Listed(tokenId, user1, startingPrice, true);
    tradingPlatform.createAuction(tokenId, startingPrice, duration);
    vm.stopPrank();

    // Destructure the tuple returned by listings(tokenId)
    (
        address seller,
        ,  // tokenId
        uint256 price,
        uint256 deadline,
        bool isAuction,
        ,  // highestBidder
        ,  // highestBid
        bool active
    ) = tradingPlatform.listings(tokenId);

    assertEq(seller, user1);
    assertEq(price, startingPrice);
    assertEq(isAuction, true);
    assertEq(active, true);
    assertEq(deadline, block.timestamp + duration);
}

    // Test placing a bid in an auction
    function testPlaceBid() public {
    uint256 tokenId = 0;
    uint256 startingPrice = 0.5 ether;
    uint256 duration = 1 days;

    vm.startPrank(user1);
    pokemonCards.approve(address(tradingPlatform), tokenId);
    tradingPlatform.createAuction(tokenId, startingPrice, duration);
    vm.stopPrank();

    vm.startPrank(user2);
    vm.expectEmit(true, true, true, true);
    emit AuctionBid(tokenId, user2, 1 ether);
    tradingPlatform.placeBid{value: 1 ether}(tokenId);
    vm.stopPrank();

    // Destructure the tuple returned by listings(tokenId)
    (
        ,  // seller
        ,  // tokenId
        ,  // price
        ,  // deadline
        ,  // isAuction
        address highestBidder,
        uint256 highestBid,
        // active
    ) = tradingPlatform.listings(tokenId);

    assertEq(highestBidder, user2);
    assertEq(highestBid, 1 ether);
}

    // Test finalizing an auction
    function testFinalizeAuction() public {
        uint256 tokenId = 0;
        uint256 startingPrice = 0.5 ether;
        uint256 duration = 1 days;

        vm.startPrank(user1);
        pokemonCards.approve(address(tradingPlatform), tokenId);
        tradingPlatform.createAuction(tokenId, startingPrice, duration);
        vm.stopPrank();

        vm.startPrank(user2);
        tradingPlatform.placeBid{value: 1 ether}(tokenId);
        vm.stopPrank();

        vm.warp(block.timestamp + duration + 1); // Fast forward time to end the auction

        vm.startPrank(user1);
        vm.expectEmit(true, true, true, true);
        emit Sale(tokenId, user1, user2, 1 ether);
        tradingPlatform.finalizeAuction(tokenId);
        vm.stopPrank();

        (,,,,,,,bool active) = tradingPlatform.listings(tokenId);

        assertEq(pokemonCards.ownerOf(tokenId), user2);
        assertEq(active, false);
    }

    // Test withdrawing pending returns
    function testWithdraw() public {
    uint256 tokenId = 0;
    uint256 startingPrice = 0.5 ether;
    uint256 duration = 1 days;

    vm.startPrank(user1);
    pokemonCards.approve(address(tradingPlatform), tokenId);
    tradingPlatform.createAuction(tokenId, startingPrice, duration);
    vm.stopPrank();

    vm.startPrank(user2);
    tradingPlatform.placeBid{value: 1 ether}(tokenId);
    vm.stopPrank();

    vm.startPrank(user3);
    tradingPlatform.placeBid{value: 2 ether}(tokenId);
    vm.stopPrank();

    uint256 initialBalance = user2.balance;

    vm.startPrank(user2);
    tradingPlatform.withdraw();
    vm.stopPrank();

    // Account for gas costs by allowing a small difference
    assertApproxEqAbs(user2.balance, initialBalance + 1 ether, 0.01 ether);
}

    // Test pausing and unpausing the contract
    function testPauseUnpause() public {
        vm.startPrank(owner);
        tradingPlatform.pause();
        assertTrue(tradingPlatform.paused());

        tradingPlatform.unpause();
        assertFalse(tradingPlatform.paused());
        vm.stopPrank();
    }

    // Test reverts
    function testFailPurchaseCardInactiveListing() public {
        uint256 tokenId = 0;
        uint256 price = 1 ether;

        vm.startPrank(user1);
        pokemonCards.approve(address(tradingPlatform), tokenId);
        tradingPlatform.listCard(tokenId, price);
        tradingPlatform.pause(); // Pause the contract to make the listing inactive
        vm.stopPrank();

        vm.startPrank(user2);
        tradingPlatform.purchaseCard{value: price}(tokenId); // This should fail
        vm.stopPrank();
    }

    function testFailPlaceBidAfterDeadline() public {
        uint256 tokenId = 0;
        uint256 startingPrice = 0.5 ether;
        uint256 duration = 1 days;

        vm.startPrank(user1);
        pokemonCards.approve(address(tradingPlatform), tokenId);
        tradingPlatform.createAuction(tokenId, startingPrice, duration);
        vm.stopPrank();

        vm.warp(block.timestamp + duration + 1); // Fast forward time to end the auction

        vm.startPrank(user2);
        tradingPlatform.placeBid{value: 1 ether}(tokenId); // This should fail
        vm.stopPrank();
    }
}
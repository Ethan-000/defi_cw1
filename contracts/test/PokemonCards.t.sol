// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/PokemonCards.sol";

contract PokemonCardsTest is Test {
    PokemonCards public pokemonCards;
    address public owner;
    address public user1;
    address public user2;
    
    // Events from the contract to test
    event ProvenanceHashUpdated(string newHash);
    event SaleStateUpdated(bool isActive);
    event BaseURIUpdated(string newBaseURI);
    event WhitelistUpdated(address indexed user, bool isTwoTokens);
    event TokensMinted(address indexed to, uint256 numberOfTokens, uint256 price);

    receive() external payable {}

    function setUp() public {
        owner = address(this);
        user1 = address(0x123);
        user2 = address(0x456);
        vm.label(user1, "User 1");
        vm.label(user2, "User 2");
        
        pokemonCards = new PokemonCards("ipfs://test/");
    }

    function testInitialState() public view {
        assertEq(pokemonCards.saleIsActive(), false);
        assertEq(pokemonCards.standardPokemonCardsCount(), 0);
        assertEq(pokemonCards.PokemonCards_PROVENANCE(), "");
        assertEq(pokemonCards.isContractPaused(), false);
    }

    function testSetProvenanceHash() public {
        string memory newHash = "testHash123";
        vm.expectEmit(true, true, true, true);
        emit ProvenanceHashUpdated(newHash);
        pokemonCards.setProvenanceHash(newHash);
        assertEq(pokemonCards.PokemonCards_PROVENANCE(), newHash);
    }

    function testSetProvenanceHashRevertOnEmpty() public {
        vm.expectRevert("Empty hash not allowed");
        pokemonCards.setProvenanceHash("");
    }

    function testFlipSaleState() public {
        vm.expectEmit(true, true, true, true);
        emit SaleStateUpdated(true);
        pokemonCards.flipSaleState();
        assertTrue(pokemonCards.saleIsActive());

        vm.expectEmit(true, true, true, true);
        emit SaleStateUpdated(false);
        pokemonCards.flipSaleState();
        assertFalse(pokemonCards.saleIsActive());
    }

    function testWhitelistOperations() public {
        address[] memory addresses = new address[](2);
        addresses[0] = user1;
        addresses[1] = user2;

        // Test whitelist one
        vm.expectEmit(true, true, true, true);
        emit WhitelistUpdated(user1, false);
        pokemonCards.editWhitelistOne(addresses);
        assertTrue(pokemonCards.whitelistOneMint(user1));
        assertTrue(pokemonCards.whitelistOneMint(user2));

        // Test whitelist two
        vm.expectEmit(true, true, true, true);
        emit WhitelistUpdated(user1, true);
        pokemonCards.editWhitelistTwo(addresses);
        assertTrue(pokemonCards.whitelistTwoMint(user1));
        assertTrue(pokemonCards.whitelistTwoMint(user2));
    }

    function testWhitelistMinting() public {
        address[] memory addresses = new address[](1);
        addresses[0] = user1;
        pokemonCards.editWhitelistTwo(addresses);

        vm.startPrank(user1);
        pokemonCards.reserveMintPokemonCards();
        assertEq(pokemonCards.balanceOf(user1), 2);
        assertFalse(pokemonCards.whitelistTwoMint(user1));
        vm.stopPrank();
    }

    function testPriceCalculation() public view {
        assertEq(pokemonCards.calculatePrice(10), 0.00006 ether);
        assertEq(pokemonCards.calculatePrice(6), 0.00007 ether);
        assertEq(pokemonCards.calculatePrice(3), 0.000075 ether);
        assertEq(pokemonCards.calculatePrice(1), 0.00008 ether);
    }

    function testMinting() public {
        pokemonCards.flipSaleState();
        uint256 tokensToMint = 5;
        uint256 pricePerToken = pokemonCards.calculatePrice(tokensToMint);
        uint256 totalPrice = pricePerToken * tokensToMint;

        vm.startPrank(user1);
        vm.deal(user1, totalPrice);
        
        vm.expectEmit(true, true, true, true);
        emit TokensMinted(user1, tokensToMint, totalPrice);
        pokemonCards.mintPokemonCards{value: totalPrice}(tokensToMint);
        
        assertEq(pokemonCards.balanceOf(user1), tokensToMint);
        assertEq(pokemonCards.standardPokemonCardsCount(), tokensToMint);
        vm.stopPrank();
    }

    function testFailMintingWhenPaused() public {
        pokemonCards.flipSaleState();
        pokemonCards.setPaused(true);
        
        uint256 tokensToMint = 1;
        uint256 pricePerToken = pokemonCards.calculatePrice(tokensToMint);

        vm.startPrank(user1);
        vm.deal(user1, pricePerToken);
        pokemonCards.mintPokemonCards{value: pricePerToken}(tokensToMint);
        vm.expectRevert("Contract is paused");
        vm.stopPrank();
    }

    function testWithdraw() public {
        // First mint some tokens to get ETH in the contract
        pokemonCards.flipSaleState();
        uint256 tokensToMint = 5;
        uint256 pricePerToken = pokemonCards.calculatePrice(tokensToMint);
        uint256 totalPrice = pricePerToken * tokensToMint;

        vm.deal(user1, totalPrice);
        vm.prank(user1);
        pokemonCards.mintPokemonCards{value: totalPrice}(tokensToMint);

        // Test withdrawal
        uint256 initialBalance = address(owner).balance;
        pokemonCards.withdraw();
        assertEq(address(pokemonCards).balance, 0);
        assertEq(address(owner).balance, initialBalance + totalPrice);
    }

    function testMaxSupply() public {
        pokemonCards.flipSaleState();
        uint256 tokensToMint = 1;
        uint256 pricePerToken = pokemonCards.calculatePrice(tokensToMint);
        uint256 totalPrice = pricePerToken * tokensToMint;

        // Try to mint more than max supply
        vm.deal(user1, totalPrice * 251); // Enough for 251 tokens
        vm.startPrank(user1);
        
        for(uint256 i = 0; i < 250; i++) {
            pokemonCards.mintPokemonCards{value: totalPrice}(tokensToMint);
        }
        
        // This should fail as it would exceed max supply
        vm.expectRevert("Would exceed max supply");
        pokemonCards.mintPokemonCards{value: totalPrice}(tokensToMint);
        vm.stopPrank();

        assertEq(pokemonCards.totalSupply(), 250);
    }
}
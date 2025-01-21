// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../src/PokemonCards.sol"; // Adjust the path if needed

contract PokemonCardsTest is Test {
    PokemonCards public pokemonCards;
    address public owner;
    address public user1;
    address public user2;

    // Constants for testing
    uint256 public constant MAX_POKEMON_CARDS = 10000;
    uint256 public constant MAX_PURCHASE = 10;

    function setUp() public {
        // Deploy the contract
        owner = address(this); // The test contract will be the owner
        user1 = address(0x123);
        user2 = address(0x456);
        
        pokemonCards = new PokemonCards();
    }

    function testInitialState() public view {
        // Test initial conditions
        assertEq(pokemonCards.saleIsActive(), false);
        assertEq(pokemonCards.standardPokemonCardsCount(), 0);
        assertEq(pokemonCards.PokemonCards_PROVENANCE(), "");
    }

    function testFlipSaleState() public {
        // Test the flipping of sale state
        pokemonCards.flipSaleState();
        assertEq(pokemonCards.saleIsActive(), true);

        pokemonCards.flipSaleState();
        assertEq(pokemonCards.saleIsActive(), false);
    }

    function testMinting() public {
        pokemonCards.flipSaleState(); // Activate sale
        uint256 tokensToMint = 5;

        // Simulate a minting process from user1
        vm.startPrank(user1);
        uint256 pricePerToken = 0.08 ether;
        uint256 totalPrice = pricePerToken * tokensToMint;
        vm.deal(user1, totalPrice); // Send Ether to user1
        pokemonCards.mintPokemonCards{value: totalPrice}(tokensToMint);
        assertEq(pokemonCards.balanceOf(user1), tokensToMint);
        vm.stopPrank();

        // Check the standardPokemonCardsCount
        assertEq(pokemonCards.standardPokemonCardsCount(), tokensToMint);
    }

    function testMaxPurchaseLimit() public {
        // Activate sale and try minting more than allowed tokens
        pokemonCards.flipSaleState();
        uint256 tokensToMint = 10;

        uint256 pricePerToken = 0.075 ether;
        uint256 totalPrice = pricePerToken * tokensToMint;

        // Send enough ether for the purchase
        vm.deal(user1, totalPrice);
        vm.startPrank(user1);
        pokemonCards.mintPokemonCards{value: totalPrice}(tokensToMint);

        // Ensure user can only mint 10 tokens at most
        assertEq(pokemonCards.balanceOf(user1), 10);
        vm.stopPrank();
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/PokemonCards.sol";

contract PokemonCardsTest is Test {
    PokemonCards public pokemonCards;
    address public owner;
    address public user1;
    address public user2;
    address public user3;

    uint256 public mintPrice;

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        user3 = address(0x3);

        pokemonCards = new PokemonCards();
    }

    function testInitialValues() public {
        assertEq(pokemonCards.PokemonCards_PROVENANCE(), "");
        assertEq(pokemonCards.saleIsActive(), false);
        assertEq(pokemonCards.standardPokemonCardsCount(), 0);
    }

    // function testSetProvenanceHash() public {
    //     pokemonCards.setProvenanceHash("new-provenance-hash");
    //     assertEq(pokemonCards.PokemonCards_PROVENANCE(), "new-provenance-hash");
    // }

    // function testFlipSaleState() public {
    //     pokemonCards.flipSaleState();
    //     assertEq(pokemonCards.saleIsActive(), true);
    //     pokemonCards.flipSaleState();
    //     assertEq(pokemonCards.saleIsActive(), false);
    // }

    // function testWithdraw() public {
    //     uint256 initialBalance = address(this).balance;
    //     uint256 contractBalance = address(pokemonCards).balance;
        
    //     // Send some ether to the contract
    //     payable(address(pokemonCards)).transfer(1 ether);

    //     // Check the contract balance after transfer
    //     assertEq(address(pokemonCards).balance, contractBalance + 1 ether);

    //     // Withdraw and check the contract balance after withdraw
    //     pokemonCards.withdraw();

    //     assertEq(address(pokemonCards).balance, 0);
    //     assertEq(address(this).balance, initialBalance + 1 ether);
    // }

    // function testMintPokemonCards() public {
    //     pokemonCards.flipSaleState(); // Activate sale
        
    //     // user1 mints 3 tokens (price = 0.08 ETH each)
    //     uint256 mintAmount = 3;
    //     uint256 price = 80000000000000000 * mintAmount; // 0.08 ETH * 3 = 0.24 ETH

    //     vm.prank(user1);
    //     pokemonCards.mintPokemonCards{value: price}(mintAmount);
        
    //     assertEq(pokemonCards.balanceOf(user1), 3);
    // }

    // function testMintTooManyPokemonCards() public {
    //     pokemonCards.flipSaleState(); // Activate sale
        
    //     // user1 tries to mint 11 cards, but the max per transaction is 10
    //     uint256 mintAmount = 11;
    //     uint256 price = 80000000000000000 * mintAmount; // 0.08 ETH * 11 = 0.88 ETH
        
    //     vm.expectRevert("Can only mint up to 10 tokens at a time");
    //     vm.prank(user1);
    //     pokemonCards.mintPokemonCards{value: price}(mintAmount);
    // }

    // function testMintExceedsMaxSupply() public {
    //     pokemonCards.flipSaleState(); // Activate sale

    //     // Mint all cards (10,000 total supply)
    //     uint256 mintAmount = 10000;
    //     uint256 price = 80000000000000000 * mintAmount; // 0.08 ETH * 10000

    //     vm.prank(user1);
    //     pokemonCards.mintPokemonCards{value: price}(mintAmount);

    //     // Try to mint an additional card, which should fail
    //     vm.expectRevert("Purchase would exceed max supply of PokemonCards");
    //     vm.prank(user1);
    //     pokemonCards.mintPokemonCards{value: 80000000000000000}(1);
    // }

    // function testInvalidEtherValue() public {
    //     pokemonCards.flipSaleState(); // Activate sale

    //     // user3 tries to mint 3 cards but sends less ether
    //     uint256 mintAmount = 3;
    //     uint256 price = 80000000000000000 * mintAmount; // 0.08 ETH * 3 = 0.24 ETH

    //     vm.expectRevert("Ether value sent is not correct");
    //     vm.prank(user3);
    //     pokemonCards.mintPokemonCards{value: price - 1000000000000000}(mintAmount); // Send slightly less
    // }
}

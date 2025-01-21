// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "forge-std/Test.sol";
import "../src/PokemonCards.sol";
import {Vm} from "forge-std/Vm.sol";

contract PokemonCardsTest is Test {
    PokemonCards public pokemonCards;
    address public owner;
    address public addr1 = address(0x123);
    address public addr2 = address(0x456);
    address public addr3 = address(0x789);

    uint256 public constant MINT_PRICE = 0.08 ether;

    function setUp() public {
        owner = address(this);
        pokemonCards = new PokemonCards();
    }

    // 1. Test that the initial values are set correctly.
    function testInitialValues() public {
        assertEq(pokemonCards.PokemonCards_PROVENANCE(), "");
        assertEq(pokemonCards.saleIsActive(), false);
        assertEq(pokemonCards.standardPokemonCardsCount(), 0);
    }

    // 2. Test the whitelist functionality
    function testWhitelistFunctionality() public {
        // Add addr1 to whitelistOneMint
        pokemonCards.editWhitelistOne([addr1]);
        assertTrue(pokemonCards.whitelistOneMint(addr1));

        // Add addr2 to whitelistTwoMint
        pokemonCards.editWhitelistTwo([addr2]);
        assertTrue(pokemonCards.whitelistTwoMint(addr2));

        // Test reserve mint for addr1 (should mint 1 card)
        vm.prank(addr1);
        pokemonCards.reserveMintPokemonCards();
        assertEq(pokemonCards.balanceOf(addr1), 1);

        // Test reserve mint for addr2 (should mint 2 cards)
        vm.prank(addr2);
        pokemonCards.reserveMintPokemonCards();
        assertEq(pokemonCards.balanceOf(addr2), 2);
    }

    // 3. Test flipSaleState function
    function testSaleStateToggle() public {
        assertEq(pokemonCards.saleIsActive(), false);

        // Toggle sale state
        pokemonCards.flipSaleState();
        assertEq(pokemonCards.saleIsActive(), true);

        // Toggle sale state again
        pokemonCards.flipSaleState();
        assertEq(pokemonCards.saleIsActive(), false);
    }

    // 4. Test minting functionality (normal minting)
    function testMint() public {
        uint256 mintAmount = 3;

        // Ensure sale is active
        pokemonCards.flipSaleState();

        // Mint tokens with 0.24 ETH (0.08 * 3)
        vm.deal(addr3, 1 ether);
        vm.prank(addr3);
        pokemonCards.mintPokemonCards{value: mintAmount * MINT_PRICE}(mintAmount);

        assertEq(pokemonCards.balanceOf(addr3), mintAmount);
    }

    // 5. Test minting with exceeding amount
    function testMintExceedsMaxPurchase() public {
        uint256 maxPurchase = 10;

        // Ensure sale is active
        pokemonCards.flipSaleState();

        vm.deal(addr3, 1 ether);

        // Should revert with error "Can only mint up to 10 tokens at a time"
        vm.expectRevert("Can only mint up to 10 tokens at a time");
        vm.prank(addr3);
        pokemonCards.mintPokemonCards{value: maxPurchase * MINT_PRICE}(maxPurchase + 1);
    }

    // 6. Test minting with invalid Ether value
    function testMintInvalidPrice() public {
        uint256 mintAmount = 3;

        // Ensure sale is active
        pokemonCards.flipSaleState();

        // Mint with less ETH than required
        vm.deal(addr3, 1 ether);
        vm.prank(addr3);
        vm.expectRevert("Ether value sent is not correct");
        pokemonCards.mintPokemonCards{value: mintAmount * MINT_PRICE - 1}(mintAmount);
    }

    // 7. Test withdraw functionality (only owner)
    function testWithdraw() public {
        uint256 initialBalance = address(this).balance;

        // Send some ether to contract
        vm.deal(address(pokemonCards), 1 ether);

        uint256 contractBalance = address(pokemonCards).balance;
        assertEq(contractBalance, 1 ether);

        // Attempt to withdraw
        uint256 balanceBeforeWithdraw = address(owner).balance;
        pokemonCards.withdraw();

        uint256 balanceAfterWithdraw = address(owner).balance;
        assertEq(balanceAfterWithdraw, balanceBeforeWithdraw + contractBalance);
    }

    // 8. Test only owner can withdraw
    function testWithdrawNotOwner() public {
        vm.prank(addr1); // Make addr1 the caller
        vm.expectRevert("Ownable: caller is not the owner");
        pokemonCards.withdraw();
    }

    // 9. Test setProvenanceHash functionality
    function testSetProvenanceHash() public {
        string memory newProvenance = "new_hash_123";

        // Ensure only owner can set provenance
        pokemonCards.setProvenanceHash(newProvenance);
        assertEq(pokemonCards.PokemonCards_PROVENANCE(), newProvenance);

        // Non-owner should not be able to set provenance
        vm.prank(addr1);
        vm.expectRevert("Ownable: caller is not the owner");
        pokemonCards.setProvenanceHash(newProvenance);
    }
}

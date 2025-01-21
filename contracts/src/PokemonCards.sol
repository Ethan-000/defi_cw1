// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PokemonCards is ERC721, Ownable {
    string public PokemonCards_PROVENANCE = "";
    uint public constant maxPokemonCardsPurchase = 10;
    uint256 public constant MAX_PokemonCards = 10000;
    bool public saleIsActive = false;
    uint256 public standardPokemonCardsCount = 0;
    uint256 private _tokenIds;
    string _baseTokenURI;

    mapping(address => bool) public whitelistOneMint;
    mapping(address => bool) public whitelistTwoMint;

    constructor() ERC721("PokemonCards", "PKMN") Ownable(msg.sender) {}

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        PokemonCards_PROVENANCE = provenanceHash;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    function editWhitelistOne(address[] memory array) public onlyOwner {
        for(uint256 i = 0; i < array.length; i++) {
            address addressElement = array[i];
            whitelistOneMint[addressElement] = true;
        }
    }

    function editWhitelistTwo(address[] memory array) public onlyOwner {
        for(uint256 i = 0; i < array.length; i++) {
            address addressElement = array[i];
            whitelistTwoMint[addressElement] = true;
        }
    }

    function reserveMintPokemonCards() public {
        require(whitelistTwoMint[msg.sender] || whitelistOneMint[msg.sender], "sender not whitelisted");
        uint mintAmount;
        if (whitelistTwoMint[msg.sender]) {
            whitelistTwoMint[msg.sender] = false;
            mintAmount = 2;
        } else {
            whitelistOneMint[msg.sender] = false;
            mintAmount = 1;
        }
        uint i;
        for (i = 0; i < mintAmount && _tokenIds < 10000; i++) {
            uint supply = _tokenIds;
            _safeMint(msg.sender, supply);
        }
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function mintPokemonCards(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint PokemonCardss");
        require(numberOfTokens <= maxPokemonCardsPurchase, "Can only mint up to 10 tokens at a time");
        require(standardPokemonCardsCount + numberOfTokens <= MAX_PokemonCards, "Purchase would exceed max supply of PokemonCards");
        uint256 PokemonCardsPrice;
        if (numberOfTokens == 10) {
            PokemonCardsPrice = 60000000000000000; // 0.06 ETH
            require(PokemonCardsPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        } else if (numberOfTokens >= 6) {
            PokemonCardsPrice = 70000000000000000; // 0.07 ETH
            require(PokemonCardsPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        } else if (numberOfTokens >= 3) {
            PokemonCardsPrice = 75000000000000000; // 0.075 ETH
            require(PokemonCardsPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        } else {
            PokemonCardsPrice = 80000000000000000; // 0.08 ETH
            require(PokemonCardsPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        }

        for(uint i = 0; i < numberOfTokens; i++) {
            if (standardPokemonCardsCount < MAX_PokemonCards) {
                _tokenIds++;
                _safeMint(msg.sender, _tokenIds);
                standardPokemonCardsCount++;
            }
        }
    }

}


// SPDX-License-Identifier: MIT

// Adapted from Milady Contract https://etherscan.io/address/0x5af0d9827e0c53e4799bb226655a1de152a425a5
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract PokemonCards is ERC721Enumerable, Ownable, ReentrancyGuard {
    // Events
    event ProvenanceHashUpdated(string newHash);
    event SaleStateUpdated(bool isActive);
    event WhitelistUpdated(address indexed user, bool isTwoTokens);
    event TokensMinted(address indexed to, uint256 numberOfTokens, uint256 price);
    
    string public PokemonCards_PROVENANCE = "";
    uint256 public constant MAX_POKEMON_CARDS_PURCHASE = 10;
    uint256 public constant MAX_POKEMON_CARDS = 250;
    uint256 public constant PRICE_TEN_TOKENS = 0.00006 ether;    // Price for 10 tokens
    uint256 public constant PRICE_SIX_TO_NINE = 0.00007 ether;   // Price for 6-9 tokens
    uint256 public constant PRICE_THREE_TO_FIVE = 0.000075 ether; // Price for 3-5 tokens
    uint256 public constant PRICE_ONE_TO_TWO = 0.00008 ether;    // Price for 1-2 tokens
    
    bool public saleIsActive = false;
    bool public isContractPaused = false;
    uint256 public standardPokemonCardsCount = 0;
    string private _baseTokenURI;

    mapping(address => bool) public whitelistOneMint;
    mapping(address => bool) public whitelistTwoMint;

    modifier whenNotPaused() {
        require(!isContractPaused, "Contract is paused");
        _;
    }

    constructor(string memory baseURI) ERC721("PokemonCards", "PKMN") Ownable(msg.sender) {
        require(bytes(baseURI).length > 0, "Empty URI not allowed");
        _baseTokenURI = baseURI;
    }

    function setProvenanceHash(string calldata provenanceHash) external onlyOwner {
        require(bytes(provenanceHash).length > 0, "Empty hash not allowed");
        PokemonCards_PROVENANCE = provenanceHash;
        emit ProvenanceHashUpdated(provenanceHash);
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Transfer failed");
    }

    function editWhitelistOne(address[] calldata array) external onlyOwner {
        require(array.length > 0, "Empty array not allowed");
        require(array.length <= 1000, "Too many addresses at once");
        
        for(uint256 i = 0; i < array.length; i++) {
            address addressElement = array[i];
            require(addressElement != address(0), "Invalid address");
            whitelistOneMint[addressElement] = true;
            emit WhitelistUpdated(addressElement, false);
        }
    }

    function editWhitelistTwo(address[] calldata array) external onlyOwner {
        require(array.length > 0, "Empty array not allowed");
        require(array.length <= 1000, "Too many addresses at once");
        
        for(uint256 i = 0; i < array.length; i++) {
            address addressElement = array[i];
            require(addressElement != address(0), "Invalid address");
            whitelistTwoMint[addressElement] = true;
            emit WhitelistUpdated(addressElement, true);
        }
    }

    function reserveMintPokemonCards() external whenNotPaused nonReentrant {
        require(whitelistTwoMint[msg.sender] || whitelistOneMint[msg.sender], "Not whitelisted");
        require(totalSupply() < MAX_POKEMON_CARDS, "Max supply reached");
        
        uint256 mintAmount;
        if (whitelistTwoMint[msg.sender]) {
            whitelistTwoMint[msg.sender] = false;
            mintAmount = 2;
        } else {
            whitelistOneMint[msg.sender] = false;
            mintAmount = 1;
        }

        uint i;
        for (i = 0; i < mintAmount && totalSupply() < MAX_POKEMON_CARDS; i++) {
            uint supply = totalSupply();
            _safeMint(msg.sender, supply);
        }
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
        emit SaleStateUpdated(saleIsActive);
    }

    function setPaused(bool _paused) external onlyOwner {
        isContractPaused = _paused;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function calculatePrice(uint256 numberOfTokens) public pure returns (uint256) {
        require(numberOfTokens > 0 && numberOfTokens <= MAX_POKEMON_CARDS_PURCHASE, "Invalid number of tokens");
        
        if (numberOfTokens == 10) return PRICE_TEN_TOKENS;
        if (numberOfTokens >= 6) return PRICE_SIX_TO_NINE;
        if (numberOfTokens >= 3) return PRICE_THREE_TO_FIVE;
        return PRICE_ONE_TO_TWO;
    }

    function mintPokemonCards(uint256 numberOfTokens) external payable whenNotPaused nonReentrant {
        require(saleIsActive, "Sale must be active to mint");
        require(numberOfTokens > 0, "Must mint at least one token");
        require(numberOfTokens <= MAX_POKEMON_CARDS_PURCHASE, "Exceeds max tokens per transaction");
        require(standardPokemonCardsCount + numberOfTokens <= MAX_POKEMON_CARDS, "Would exceed max supply");

        uint256 pokemonCardsPrice = calculatePrice(numberOfTokens);
        uint256 totalPrice = pokemonCardsPrice * numberOfTokens;
        require(msg.value == totalPrice, "Incorrect payment amount");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            if (standardPokemonCardsCount < MAX_POKEMON_CARDS) {
                _safeMint(msg.sender, totalSupply());
                standardPokemonCardsCount++;
            }
        }
        
        emit TokensMinted(msg.sender, numberOfTokens, totalPrice);
    }

}
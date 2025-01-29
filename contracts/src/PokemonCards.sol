// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract PokemonCards is ERC721, Ownable, ReentrancyGuard {
    // Events
    event ProvenanceHashUpdated(string newHash);
    event SaleStateUpdated(bool isActive);
    event BaseURIUpdated(string newBaseURI);
    event WhitelistUpdated(address indexed user, bool isTwoTokens);
    event TokensMinted(address indexed to, uint256 numberOfTokens, uint256 price);
    
    string public PokemonCards_PROVENANCE = "";
    uint256 public constant MAX_POKEMON_CARDS_PURCHASE = 10;
    uint256 public constant MAX_POKEMON_CARDS = 10000;
    uint256 public constant PRICE_TEN_TOKENS = 0.000006 ether;    // Price for 10 tokens
    uint256 public constant PRICE_SIX_TO_NINE = 0.000007 ether;   // Price for 6-9 tokens
    uint256 public constant PRICE_THREE_TO_FIVE = 0.0000075 ether; // Price for 3-5 tokens
    uint256 public constant PRICE_ONE_TO_TWO = 0.000008 ether;    // Price for 1-2 tokens
    
    bool public saleIsActive = false;
    bool public isContractPaused = false;
    uint256 public standardPokemonCardsCount = 0;
    uint256 private _tokenIds;
    string private _baseTokenURI;

    mapping(address => bool) public whitelistOneMint;
    mapping(address => bool) public whitelistTwoMint;

    modifier whenNotPaused() {
        require(!isContractPaused, "Contract is paused");
        _;
    }

    constructor() ERC721("PokemonCards", "PKMN") Ownable(msg.sender) {}

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
        require(_tokenIds < MAX_POKEMON_CARDS, "Max supply reached");
        
        uint256 mintAmount;
        if (whitelistTwoMint[msg.sender]) {
            whitelistTwoMint[msg.sender] = false;
            mintAmount = 2;
        } else {
            whitelistOneMint[msg.sender] = false;
            mintAmount = 1;
        }

        // Ensure we don't exceed max supply
        mintAmount = _tokenIds + mintAmount > MAX_POKEMON_CARDS ? 
            MAX_POKEMON_CARDS - _tokenIds : 
            mintAmount;

        for (uint256 i = 0; i < mintAmount; i++) {
            _tokenIds++;
            _safeMint(msg.sender, _tokenIds);
            standardPokemonCardsCount++;
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

    function setBaseURI(string calldata baseURI) external onlyOwner {
        require(bytes(baseURI).length > 0, "Empty URI not allowed");
        _baseTokenURI = baseURI;
        emit BaseURIUpdated(baseURI);
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
            _tokenIds++;
            _safeMint(msg.sender, _tokenIds);
            standardPokemonCardsCount++;
        }
        
        emit TokensMinted(msg.sender, numberOfTokens, totalPrice);
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIds;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract PokemonCards is ERC721, ERC721URIStorage, Ownable, ReentrancyGuard, Pausable {
    // State variables
    uint256 private _tokenIds;
    mapping(uint256 => PokemonCard) public pokemonCards;
    
    struct PokemonCard {
        string name;
        uint8 level;
        string pokemonType;
        uint256 attack;
        uint256 defense;
        bool isHolographic;
    }
    
    // Events
    event PokemonCardMinted(uint256 indexed tokenId, address indexed owner, string name);
    event MetadataUpdated(uint256 indexed tokenId, string newUri);
    
    constructor() ERC721("PokemonCards", "PKMN") {}
    
    // Mint new Pokemon card with metadata
    function mintPokemonCard(
        address recipient,
        string memory name,
        uint8 level,
        string memory pokemonType,
        uint256 attack,
        uint256 defense,
        bool isHolographic,
        string memory tokenURI
    ) public onlyOwner whenNotPaused nonReentrant returns (uint256) {
        _tokenIds++;
        uint256 newTokenId = _tokenIds;
        
        pokemonCards[newTokenId] = PokemonCard(
            name,
            level,
            pokemonType,
            attack,
            defense,
            isHolographic
        );
        
        _safeMint(recipient, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        
        emit PokemonCardMinted(newTokenId, recipient, name);
        
        return newTokenId;
    }
    
    // Emergency pause
    function pause() public onlyOwner {
        _pause();
    }
    
    // Resume operations
    function unpause() public onlyOwner {
        _unpause();
    }
    
    // Override required functions
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage)
        returns (string memory) {
        return super.tokenURI(tokenId);
    }
    
    // View functions
    function getPokemonCard(uint256 tokenId) public view returns (PokemonCard memory) {
        require(_exists(tokenId), "Token does not exist");
        return pokemonCards[tokenId];
    }
}
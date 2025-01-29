// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract TradingPlatform is ReentrancyGuard, Pausable {
    // State variables
    struct Listing {
        address seller;
        uint256 tokenId;
        uint256 price;
        uint256 deadline;
        bool isAuction;
        address highestBidder;
        uint256 highestBid;
        bool active;
    }
    
    IERC721 public pokemonCards;
    mapping(uint256 => Listing) public listings;
    mapping(address => uint256) public pendingReturns;
    
    // Events
    event Listed(uint256 indexed tokenId, address indexed seller, uint256 price, bool isAuction);
    event Sale(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);
    event AuctionBid(uint256 indexed tokenId, address indexed bidder, uint256 bid);
    event ListingCancelled(uint256 indexed tokenId);

    // Constructor
    constructor(address _pokemonCards) {
        pokemonCards = IERC721(_pokemonCards);
    }
    
    // List a card for fixed price sale
    function listCard(uint256 tokenId, uint256 price) external whenNotPaused {
        require(pokemonCards.ownerOf(tokenId) == msg.sender, "Not owner");
        require(price > 0, "Price must be greater than 0");
        
        listings[tokenId] = Listing({
            seller: msg.sender,
            tokenId: tokenId,
            price: price,
            deadline: 0,
            isAuction: false,
            highestBidder: address(0),
            highestBid: 0,
            active: true
        });
        
        pokemonCards.transferFrom(msg.sender, address(this), tokenId);
        emit Listed(tokenId, msg.sender, price, false);
    }
    
    // List a card for auction
    function createAuction(uint256 tokenId, uint256 startingPrice, uint256 duration) 
        external 
        whenNotPaused 
    {
        require(pokemonCards.ownerOf(tokenId) == msg.sender, "Not owner");
        require(startingPrice > 0, "Starting price must be greater than 0");
        require(duration > 0, "Duration must be greater than 0");
        
        listings[tokenId] = Listing({
            seller: msg.sender,
            tokenId: tokenId,
            price: startingPrice,
            deadline: block.timestamp + duration,
            isAuction: true,
            highestBidder: address(0),
            highestBid: 0,
            active: true
        });
        
        pokemonCards.transferFrom(msg.sender, address(this), tokenId);
        emit Listed(tokenId, msg.sender, startingPrice, true);
    }
    
    // Purchase a fixed price listing
    function purchaseCard(uint256 tokenId) external payable nonReentrant whenNotPaused {
        Listing storage listing = listings[tokenId];
        require(listing.active, "Listing not active");
        require(!listing.isAuction, "Item is in auction");
        require(msg.value == listing.price, "Incorrect payment amount");
        
        listing.active = false;
        address seller = listing.seller;
        
        pokemonCards.transferFrom(address(this), msg.sender, tokenId);
        (bool sent, ) = payable(seller).call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        
        emit Sale(tokenId, seller, msg.sender, msg.value);
    }
    
    // Place a bid in an auction
    function placeBid(uint256 tokenId) external payable nonReentrant whenNotPaused {
        Listing storage listing = listings[tokenId];
        require(listing.active && listing.isAuction, "Not an active auction");
        require(block.timestamp < listing.deadline, "Auction ended");
        require(msg.value > listing.highestBid, "Bid too low");
        
        address previousBidder = listing.highestBidder;
        uint256 previousBid = listing.highestBid;
        
        if (previousBidder != address(0)) {
            pendingReturns[previousBidder] += previousBid;
        }
        
        listing.highestBidder = msg.sender;
        listing.highestBid = msg.value;
        
        emit AuctionBid(tokenId, msg.sender, msg.value);
    }
    
    // Withdraw pending returns
    function withdraw() external nonReentrant {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "No funds to withdraw");
        
        pendingReturns[msg.sender] = 0;
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
    
    // Finish auction
    function finalizeAuction(uint256 tokenId) external nonReentrant {
        Listing storage listing = listings[tokenId];
        require(listing.active && listing.isAuction, "Not an active auction");
        require(block.timestamp >= listing.deadline, "Auction not ended");
        
        listing.active = false;
        
        if (listing.highestBidder != address(0)) {
            pokemonCards.transferFrom(address(this), listing.highestBidder, tokenId);
            (bool sent, ) = payable(listing.seller).call{value: listing.highestBid}("");
            require(sent, "Failed to send Ether");
            emit Sale(tokenId, listing.seller, listing.highestBidder, listing.highestBid);
        } else {
            pokemonCards.transferFrom(address(this), listing.seller, tokenId);
        }
    }
    
    // Emergency functions
    function pause() external {
        _pause();
    }
    
    function unpause() external {
        _unpause();
    }
}
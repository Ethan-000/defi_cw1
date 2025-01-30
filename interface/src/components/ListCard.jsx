import React, { useState } from 'react';
import { ethers } from 'ethers';

const ListCard = ({ pokemonCards, tradingPlatform, account }) => {
  const [tokenId, setTokenId] = useState('');
  const [price, setPrice] = useState('');
  const [duration, setDuration] = useState('');
  const [isAuction, setIsAuction] = useState(false);

  const handleList = async (e) => {
    e.preventDefault();
    if (isAuction) {
      await tradingPlatform.createAuction(
        tokenId,
        ethers.parseEther(price),
        duration * 86400 // Convert days to seconds
      );
    } else {
      await tradingPlatform.listCard(
        tokenId,
        ethers.parseEther(price)
      );
    }
  };

  return (
    <div className="list-form">
      <h2>List Your Pokémon Card</h2>
      <form onSubmit={handleList}>
        <input
          type="number"
          placeholder="Token ID"
          value={tokenId}
          onChange={(e) => setTokenId(e.target.value)}
        />
        <input
          type="number"
          step="0.01"
          placeholder="Price in ETH"
          value={price}
          onChange={(e) => setPrice(e.target.value)}
        />
        <label>
          <input
            type="checkbox"
            checked={isAuction}
            onChange={(e) => setIsAuction(e.target.checked)}
          />
          Auction
        </label>
        {isAuction && (
          <input
            type="number"
            placeholder="Duration (days)"
            value={duration}
            onChange={(e) => setDuration(e.target.value)}
          />
        )}
        <button type="submit" disabled={!account}>
          List Card
        </button>
      </form>
    </div>
  );
};

export default ListCard;
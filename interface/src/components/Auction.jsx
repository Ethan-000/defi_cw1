import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { useParams } from 'react-router-dom';

const Auction = ({ tradingPlatform, account }) => {
  const { tokenId } = useParams();
  const [auction, setAuction] = useState(null);
  const [bidAmount, setBidAmount] = useState('');

  useEffect(() => {
    const loadAuction = async () => {
      const listing = await tradingPlatform.listings(tokenId);
      setAuction(listing);
    };
    loadAuction();
  }, [tradingPlatform, tokenId]);

  const placeBid = async (e) => {
    e.preventDefault();
    try {
      const tx = await tradingPlatform.placeBid(tokenId, {
        value: ethers.parseEther(bidAmount)
      });
      await tx.wait();
    } catch (error) {
      console.error(error);
    }
  };

  return (
    <div className="auction">
      {auction && (
        <>
          <h2>Auction for Card #{tokenId}</h2>
          <p>Current Bid: {ethers.formatEther(auction.highestBid)} ETH</p>
          <p>Ends at: {new Date(auction.deadline * 1000).toLocaleString()}</p>
          
          <form onSubmit={placeBid}>
            <input
              type="number"
              step="0.01"
              placeholder="Bid amount in ETH"
              value={bidAmount}
              onChange={(e) => setBidAmount(e.target.value)}
            />
            <button type="submit" disabled={!account}>
              Place Bid
            </button>
          </form>
        </>
      )}
    </div>
  );
};

export default Auction;
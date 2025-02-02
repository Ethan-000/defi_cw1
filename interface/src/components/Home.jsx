import React from 'react';
import { Link } from 'react-router-dom';

const Home = ({ listings, pokemonCards, tradingPlatform, account }) => {
  const handlePurchase = async (tokenId, price) => {
    try {
      const tx = await tradingPlatform.purchaseCard(tokenId, {
        value: ethers.parseEther(price.toString()),
      });
      await tx.wait();
    } catch (error) {
      console.error(error);
    }
  };

  return (
    <div className="marketplace">
      <h1>Pokémon Card Marketplace</h1>
      <div className="listings-grid">
        {listings.map((listing) => (
          <div key={listing.tokenId} className="card-listing">
            <h3>Card #{listing.tokenId}</h3>
            {listing.isAuction ? (
              <>
                <p>Highest Bid: {ethers.formatEther(listing.highestBid)} ETH</p>
                <Link to={`/auction/${listing.tokenId}`}>View Auction</Link>
              </>
            ) : (
              <>
                <p>Price: {ethers.formatEther(listing.price)} ETH</p>
                <button
                  onClick={() => handlePurchase(listing.tokenId, listing.price)}
                  disabled={!account}
                >
                  Buy Now
                </button>
              </>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};

export default Home;

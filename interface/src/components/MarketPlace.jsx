import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { convertIPFSURI } from './utils';
import PropTypes from 'prop-types';

const Marketplace = ({ pokemonCards, tradingPlatform, account }) => {
  const [listings, setListings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  // Fetch all active listings
  useEffect(() => {
    const fetchListings = async () => {
      try {
        setLoading(true);
        const listedTokens = [];

        // Get total supply of Pokémon cards
        const totalSupply = await pokemonCards.totalSupply();

        // Check each token ID for active listings
        for (let i = 0; i < totalSupply; i++) {
          const tokenId = await pokemonCards.tokenByIndex(i);
          const listing = await tradingPlatform.listings(tokenId);

          if (listing.active) {
            // Get token metadata
            const tokenURI = await pokemonCards.tokenURI(tokenId);

            const pathSegments = convertIPFSURI(tokenURI);
            const response = await fetch(
              `https://ipfs.io/ipfs/${pathSegments}`
            );
            const metadata = await response.json();

            listedTokens.push({
              tokenId,
              metadata,
              price: ethers.formatEther(listing.price),
              isAuction: listing.isAuction,
              seller: listing.seller,
            });
          }
        }

        setListings(listedTokens);
        setLoading(false);
      } catch (err) {
        setError('Failed to load listings');
        console.error(err);
      }
    };

    if (pokemonCards && tradingPlatform) {
      fetchListings();
    }
  }, [pokemonCards, tradingPlatform]);

  const handlePurchase = async (tokenId, price) => {
    try {
      setError('');
      // Convert price to wei
      const priceWei = ethers.parseEther(price.toString());

      // Execute purchase
      const tx = await tradingPlatform.purchaseCard(tokenId, {
        value: priceWei,
      });
      await tx.wait();

      // Refresh listings after purchase
      setListings(listings.filter((item) => item.tokenId !== tokenId));
    } catch (err) {
      setError(err.reason || 'Purchase failed');
      console.error(err);
    }
  };

  if (loading) return <div className="loading">Loading marketplace...</div>;
  if (error) return <div className="error">{error}</div>;

  return (
    <div className="marketplace">
      <h2>Pokémon Card Marketplace</h2>
      <div className="listings-grid">
        {listings.map((listing) => (
          <div key={listing.tokenId} className="listing-card">
            <img
              src={listing.metadata.image.replace(
                'ipfs://',
                'https://ipfs.io/ipfs/'
              )}
              alt={listing.metadata.name}
              className="card-image"
            />
            <div className="card-details">
              <h3>{listing.metadata.name}</h3>
              <p className="price">{listing.price} ETH</p>
              <p className="seller">
                Seller: {listing.seller.slice(0, 6)}...
                {listing.seller.slice(-4)}
              </p>
              {listing.isAuction ? (
                <button disabled className="auction-badge">
                  Auction
                </button>
              ) : (
                <button
                  onClick={() => handlePurchase(listing.tokenId, listing.price)}
                  disabled={!account}
                  className="buy-button"
                >
                  {account ? 'Buy Now' : 'Connect Wallet'}
                </button>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};
Marketplace.propTypes = {
  pokemonCards: PropTypes.object.isRequired,
  tradingPlatform: PropTypes.object.isRequired,
  account: PropTypes.string,
};

export default Marketplace;

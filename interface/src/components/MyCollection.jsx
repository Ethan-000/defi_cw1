import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import PropTypes from 'prop-types';
import { convertIPFSURI } from './utils';

const MyCollection = ({ pokemonCards, tradingPlatform, account }) => {
  const [ownedTokens, setOwnedTokens] = useState([]);
  const [showListingForm, setShowListingForm] = useState(false);
  const [selectedToken, setSelectedToken] = useState(null);
  const [formData, setFormData] = useState({
    price: '',
    duration: '',
    isAuction: false,
  });
  const [txStatus, setTxStatus] = useState('');

  useEffect(() => {
    const fetchOwnedTokens = async () => {
      if (pokemonCards && account) {
        const balance = await pokemonCards.balanceOf(account);
        const tokens = [];

        for (let i = 0; i < balance; i++) {
          const tokenId = await pokemonCards.tokenOfOwnerByIndex(account, i);
          const tokenURI = await pokemonCards.tokenURI(tokenId);

          // Handle IPFS path adjustment
          // const ipfsPath = tokenURI.replace('ipfs://', '');
          // const pathSegments = ipfsPath.split('/');
          // const lastSegment = pathSegments[pathSegments.length - 1];

          // if (!isNaN(lastSegment)) {
          //   pathSegments[pathSegments.length - 1] = (
          //     parseInt(lastSegment) + 1
          //   ).toString();
          // } else {
          //   pathSegments.push('1');
          // }

          const pathSegments = convertIPFSURI(tokenURI);

          const metadata = await fetch(
            `https://ipfs.io/ipfs/${pathSegments}`
          ).then((res) => res.json());

          tokens.push({ tokenId, metadata });
        }
        setOwnedTokens(tokens);
      }
    };
    fetchOwnedTokens();
  }, [pokemonCards, account]);

  const initiateListing = (tokenId) => {
    setSelectedToken(tokenId);
    setShowListingForm(true);
  };

  const handleListSubmit = async (e) => {
    e.preventDefault();
    setTxStatus('Processing...');

    try {

      const tradingPlatformAddress = await tradingPlatform.getAddress();
      // Check if tradingPlatform is defined
      if (!tradingPlatform || !tradingPlatformAddress) {
        throw new Error('Trading platform contract is not available');
      }

      // First approve the trading platform to transfer the token
      setTxStatus('Approving token transfer...');
      const approveTx = await pokemonCards.approve(
        tradingPlatformAddress,
        selectedToken
      );
      await approveTx.wait();

      // Then create the listing
      setTxStatus('Creating listing...');

      if (formData.isAuction) {
        await tradingPlatform.createAuction(
          selectedToken,
          ethers.parseEther(formData.price),
          formData.duration * 86400 // Convert days to seconds
        );
      } else {
        await tradingPlatform.listCard(
          selectedToken,
          ethers.parseEther(formData.price)
        );
      }

      setTxStatus('Listing successful!');
      setShowListingForm(false);
      // Refresh the list after successful listing
      setTimeout(() => window.location.reload(), 2000);
    } catch (error) {
      console.error('Listing error:', error);
      setTxStatus(`Error: ${error.reason || error.message}`);
    }
  };

  return (
    <div className="collection">
      <h2>My Pokémon Cards</h2>
      <div className="cards-grid">
        {ownedTokens.map(({ tokenId, metadata }) => (
          <div key={tokenId.toString()} className="card-item">
            <h3>{metadata.name}</h3>
            <img
              src={metadata.image.replace('ipfs://', 'https://ipfs.io/ipfs/')}
              alt={metadata.name}
              className="card-image"
            />
            <p className="token-id">Token ID: {tokenId.toString()}</p>
            <button
              onClick={() => initiateListing(tokenId)}
              className="list-button"
            >
              List Card
            </button>
          </div>
        ))}
      </div>

      {/* Listing Form Modal */}
      {showListingForm && (
        <div className="listing-modal">
          <div className="modal-content">
            <h3>List Token #{selectedToken.toString()}</h3>
            <form onSubmit={handleListSubmit}>
              <div className="form-group">
                <label>Price (ETH):</label>
                <input
                  type="number"
                  step="0.0001"
                  min="0.0001"
                  value={formData.price}
                  onChange={(e) =>
                    setFormData({ ...formData, price: e.target.value })
                  }
                  required
                />
              </div>

              <div className="form-group">
                <label>
                  <input
                    type="checkbox"
                    checked={formData.isAuction}
                    onChange={(e) =>
                      setFormData({ ...formData, isAuction: e.target.checked })
                    }
                  />
                  Auction Listing
                </label>
              </div>

              {formData.isAuction && (
                <div className="form-group">
                  <label>Duration (days):</label>
                  <input
                    type="number"
                    min="1"
                    value={formData.duration}
                    onChange={(e) =>
                      setFormData({ ...formData, duration: e.target.value })
                    }
                    required
                  />
                </div>
              )}

              <div className="form-actions">
                <button
                  type="button"
                  onClick={() => setShowListingForm(false)}
                  className="cancel-button"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="submit-button"
                  disabled={txStatus.includes('Processing') || !tradingPlatform}
                >
                  {txStatus ? txStatus : 'Confirm Listing'}
                </button>
              </div>

              {txStatus.includes('Error') && (
                <div className="error-message">{txStatus}</div>
              )}
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

MyCollection.propTypes = {
  pokemonCards: PropTypes.object.isRequired,
  tradingPlatform: PropTypes.object, // Made optional for safety
  account: PropTypes.string.isRequired,
};

export default MyCollection;

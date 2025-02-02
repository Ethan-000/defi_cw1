// components/MintPokemonCard.jsx
import { useState } from 'react';
import PropTypes from 'prop-types';

const MintPokemonCard = ({ pokemonCards, account }) => {
  const [numberOfTokens, setNumberOfTokens] = useState(1);
  const [isMinting, setIsMinting] = useState(false);
  const [mintStatus, setMintStatus] = useState('');

  const handleMint = async () => {
    if (!pokemonCards || !account) {
      alert('Please connect your wallet first.');
      return;
    }

    try {
      setIsMinting(true);
      setMintStatus('Minting...');

      // Calculate the price based on the number of tokens
      const price = await pokemonCards.calculatePrice(numberOfTokens);
      const totalPrice = price * BigInt(numberOfTokens);

      // Call the mint function in the smart contract
      const tx = await pokemonCards.mintPokemonCards(numberOfTokens, {
        value: totalPrice,
      });
      await tx.wait();

      setMintStatus('Minting successful!');
    } catch (error) {
      console.error(error);
      setMintStatus('Minting failed. Please try again.');
    } finally {
      setIsMinting(false);
    }
  };

  return (
    <div className="mint-card">
      <h2>Mint Pokémon Cards</h2>
      <div className="mint-form">
        <label>
          Number of Tokens to Mint:
          <input
            type="number"
            min="1"
            max="10"
            value={numberOfTokens}
            onChange={(e) => setNumberOfTokens(Number(e.target.value))}
          />
        </label>
        <button onClick={handleMint} disabled={isMinting || !account}>
          {isMinting ? 'Minting...' : 'Mint Cards'}
        </button>
        {mintStatus && <p>{mintStatus}</p>}
      </div>
    </div>
  );
};
MintPokemonCard.propTypes = {
  pokemonCards: PropTypes.shape({
    calculatePrice: PropTypes.func.isRequired,
    mintPokemonCards: PropTypes.func.isRequired,
  }).isRequired,
  account: PropTypes.string,
};

export default MintPokemonCard;

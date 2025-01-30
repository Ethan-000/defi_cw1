import React, { useState, useEffect } from 'react';

const MyCollection = ({ pokemonCards, account }) => {
  const [ownedTokens, setOwnedTokens] = useState([]);

  useEffect(() => {
    const fetchOwnedTokens = async () => {
      if (pokemonCards && account) {
        const balance = await pokemonCards.balanceOf(account);
        const tokens = [];
        for (let i = 0; i < balance; i++) {
          const tokenId = await pokemonCards.tokenOfOwnerByIndex(account, i);
          tokens.push(tokenId);
        }
        setOwnedTokens(tokens);
      }
    };
    fetchOwnedTokens();
  }, [pokemonCards, account]);

  return (
    <div className="collection">
      <h2>My Pokémon Cards</h2>
      <div className="cards-grid">
        {ownedTokens.map(tokenId => (
          <div key={tokenId} className="card-item">
            <h3>Card #{tokenId.toString()}</h3>
            {/* Add card metadata display here */}
          </div>
        ))}
      </div>
    </div>
  );
};

export default MyCollection;
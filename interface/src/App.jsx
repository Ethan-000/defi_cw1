import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { BrowserRouter as Router, Route, Routes, Link } from 'react-router-dom';
import './App.css';

// Components
import Home from './components/Home';
import MyCollection from './components/MyCollection';
import Marketplace from './components/MarketPlace';
import MintPokemonCard from './components/MintPokemonCard';

// Contract ABIs
import PokemonCardsABI from '../../contracts/out/PokemonCards.sol/PokemonCards.json';
import TradingPlatformABI from '../../contracts/out/TradingPlatform.sol/TradingPlatform.json';

const CONTRACT_ADDRESSES = {
  pokemonCards: '0xC3062018402e0A74f74090C1e8c420aDb7452f94',
  tradingPlatform: '0xE7bEC2A1377d671B06a148EB3cc257fF0197FAb7',
};

function App() {
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [account, setAccount] = useState(null);
  const [pokemonCards, setPokemonCards] = useState(null);
  const [tradingPlatform, setTradingPlatform] = useState(null);
  const [listings, setListings] = useState([]);

  const connectWallet = async () => {
    if (window.ethereum) {
      try {
        await window.ethereum.request({ method: 'eth_requestAccounts' });
        const web3Provider = new ethers.BrowserProvider(window.ethereum);
        const signer = await web3Provider.getSigner();
        const account = await signer.getAddress();

        const pokemonCardsContract = new ethers.Contract(
          CONTRACT_ADDRESSES.pokemonCards,
          PokemonCardsABI.abi,
          signer
        );

        const tradingPlatformContract = new ethers.Contract(
          CONTRACT_ADDRESSES.tradingPlatform,
          TradingPlatformABI.abi,
          signer
        );

        setProvider(web3Provider);
        setSigner(signer);
        setAccount(account);
        setPokemonCards(pokemonCardsContract);
        setTradingPlatform(tradingPlatformContract);

        // Listen for account changes
        window.ethereum.on('accountsChanged', (accounts) => {
          setAccount(accounts[0]);
        });
      } catch (error) {
        console.error(error);
      }
    }
  };

  useEffect(() => {
    const loadListings = async () => {
      if (tradingPlatform) {
        const listedEvents = await tradingPlatform.queryFilter('Listed');
        const activeListings = await Promise.all(
          listedEvents.map(async (event) => {
            const listing = await tradingPlatform.listings(event.args.tokenId);
            return { ...listing, tokenId: event.args.tokenId };
          })
        );
        setListings(activeListings.filter((l) => l.active));
      }
    };
    loadListings();
  }, [tradingPlatform]);

  return (
    <Router>
      <div className="app-container">
        {/* Top Navigation Bar */}
        <div className="navbar">
          <h1>Pokémon Trading</h1>
          <nav>
            <Link to="/">Home</Link>
            <Link to="/market-place">Market Place</Link>
            <Link to="/my-collection">My Collection</Link>
            <Link to="/mint-card">Mint Card</Link> {/* Add Mint Card link */}
          </nav>
          <div className="wallet-info">
            {!account ? (
              <button onClick={connectWallet} className="connect-button">
                Connect Wallet
              </button>
            ) : (
              <button className="connected-address" disabled>
                {`${account.slice(0, 6)}...${account.slice(-4)}`}
              </button>
            )}
          </div>
        </div>

        {/* Main Content */}
        <div className="main-content">
          <Routes>
            <Route
              path="/"
              element={
                <Home
                  listings={listings}
                  pokemonCards={pokemonCards}
                  tradingPlatform={tradingPlatform}
                  account={account}
                />
              }
            />
            <Route
              path="/my-collection"
              element={
                <MyCollection
                  pokemonCards={pokemonCards}
                  tradingPlatform={tradingPlatform} // Pass the tradingPlatform prop
                  account={account}
                />
              }
            />
            <Route
              path="/market-place"
              element={
                <Marketplace
                  pokemonCards={pokemonCards}
                  tradingPlatform={tradingPlatform}
                  account={account}
                />
              }
            />
            <Route
              path="/mint-card"
              element={
                <MintPokemonCard
                  pokemonCards={pokemonCards}
                  account={account}
                />
              }
            />
          </Routes>
        </div>
      </div>
    </Router>
  );
}

export default App;

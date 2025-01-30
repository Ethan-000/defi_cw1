import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { BrowserRouter as Router, Route, Routes, Link } from 'react-router-dom';
import './App.css';

// Components
import Home from './components/Home';
import MyCollection from './components/MyCollection';
import ListCard from './components/ListCard';
import Auction from './components/Auction';
import MintPokemonCard from './components/MintPokemonCard'; // Import the new component

// Contract ABIs
import PokemonCardsABI from '../../contracts/out/PokemonCards.sol/PokemonCards.json';
import TradingPlatformABI from '../../contracts/out/TradingPlatform.sol/TradingPlatform.json';

const CONTRACT_ADDRESSES = {
  pokemonCards: "0x5Fb...", // Your deployed address
  tradingPlatform: "0x3A4..." // Your deployed address
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
          PokemonCardsABI,
          signer
        );

        const tradingPlatformContract = new ethers.Contract(
          CONTRACT_ADDRESSES.tradingPlatform,
          TradingPlatformABI,
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
        setListings(activeListings.filter(l => l.active));
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
            <Link to="/my-collection">My Collection</Link>
            <Link to="/list-card">List Card</Link>
            <Link to="/mint-card">Mint Card</Link> {/* Add Mint Card link */}
          </nav>
          <div className="wallet-info">
            {!account ? (
              <button onClick={connectWallet}>Connect Wallet</button>
            ) : (
              <span>Connected: {account.slice(0, 6)}...{account.slice(-4)}</span>
            )}
          </div>
        </div>

        {/* Main Content */}
        <div className="main-content">
          <Routes>
            <Route path="/" element={
              <Home 
                listings={listings}
                pokemonCards={pokemonCards}
                tradingPlatform={tradingPlatform}
                account={account}
              />
            } />
            <Route path="/my-collection" element={
              <MyCollection 
                pokemonCards={pokemonCards}
                account={account}
              />
            } />
            <Route path="/list-card" element={
              <ListCard 
                pokemonCards={pokemonCards}
                tradingPlatform={tradingPlatform}
                account={account}
              />
            } />
            <Route path="/auction/:tokenId" element={
              <Auction 
                tradingPlatform={tradingPlatform}
                account={account}
              />
            } />
            <Route path="/mint-card" element={
              <MintPokemonCard 
                pokemonCards={pokemonCards}
                account={account}
              />
            } />
          </Routes>
        </div>
      </div>
    </Router>
  );
}

export default App;
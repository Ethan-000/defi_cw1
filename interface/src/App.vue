<template>
  <div class="min-h-screen bg-gray-100">
    <nav class="bg-white shadow-lg p-4">
      <div class="container mx-auto flex justify-between items-center">
        <h1 class="text-2xl font-bold text-blue-600">Pokémon Card Trading</h1>
        <div
          v-if="!account"
          @click="connectWallet"
          class="cursor-pointer bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
        >
          Connect Wallet
        </div>
        <div v-else class="text-gray-600">
          {{ shortenAddress(account) }}
        </div>
      </div>
    </nav>

    <main class="container mx-auto p-4">
      <!-- Wallet not connected warning -->
      <div v-if="!account" class="text-center py-10">
        <h2 class="text-xl">Please connect your wallet to access the trading platform</h2>
      </div>

      <div v-else>
        <!-- Tabs -->
        <div class="mb-6 border-b border-gray-200">
          <nav class="flex space-x-4">
            <button
              @click="activeTab = 'marketplace'"
              :class="[
                'py-2 px-4',
                activeTab === 'marketplace'
                  ? 'border-b-2 border-blue-500 text-blue-600'
                  : 'text-gray-500',
              ]"
            >
              Marketplace
            </button>
            <button
              @click="activeTab = 'myCards'"
              :class="[
                'py-2 px-4',
                activeTab === 'myCards'
                  ? 'border-b-2 border-blue-500 text-blue-600'
                  : 'text-gray-500',
              ]"
            >
              My Cards
            </button>
          </nav>
        </div>

        <!-- Content -->
        <div v-if="activeTab === 'marketplace'">
          <marketplace-view
            :account="account"
            :tradingContract="tradingContract"
            :pokemonContract="pokemonContract"
          />
        </div>
        <div v-else>
          <my-cards-view
            :account="account"
            :tradingContract="tradingContract"
            :pokemonContract="pokemonContract"
          />
        </div>
      </div>
    </main>
  </div>
</template>

<script lang="ts">
import { ref, onMounted } from 'vue'
import { ethers } from 'ethers'
import PokemonCards from '../contracts/PokemonCards.json'
import TradingPlatform from '../contracts/TradingPlatform.json'

export default {
  name: 'App',
  setup() {
    const account = ref(null)
    const provider = ref(null)
    const pokemonContract = ref(null)
    const tradingContract = ref(null)
    const activeTab = ref('marketplace')

    const connectWallet = async () => {
      try {
        if (window.ethereum) {
          const accounts = await window.ethereum.request({
            method: 'eth_requestAccounts',
          })
          account.value = accounts[0]
          await initializeContracts()
        } else {
          alert('Please install MetaMask!')
        }
      } catch (error) {
        console.error('Error connecting wallet:', error)
      }
    }

    const initializeContracts = async () => {
      provider.value = new ethers.BrowserProvider(window.ethereum)
      const signer = await provider.value.getSigner()

      pokemonContract.value = new ethers.Contract(
        'YOUR_POKEMON_CONTRACT_ADDRESS',
        PokemonCards.abi,
        signer,
      )

      tradingContract.value = new ethers.Contract(
        'YOUR_TRADING_CONTRACT_ADDRESS',
        TradingPlatform.abi,
        signer,
      )
    }

    const shortenAddress = (address) => {
      return `${address.slice(0, 6)}...${address.slice(-4)}`
    }

    onMounted(() => {
      // Check if already connected
      if (window.ethereum) {
        window.ethereum.request({ method: 'eth_accounts' }).then((accounts) => {
          if (accounts.length > 0) {
            account.value = accounts[0]
            initializeContracts()
          }
        })
      }
    })

    return {
      account,
      activeTab,
      pokemonContract,
      tradingContract,
      connectWallet,
      shortenAddress,
    }
  },
}
</script>

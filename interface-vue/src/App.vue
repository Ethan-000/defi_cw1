<script lang="ts">
import { ref, onMounted } from 'vue'

import { MetaMaskInpageProvider } from '@metamask/providers'

declare global {
  interface Window {
    ethereum?: MetaMaskInpageProvider
  }
}

import { ethers } from 'ethers'
import PokemonCards from '../../contracts/out/PokemonCards.sol/PokemonCards.json'
import TradingPlatform from '../../contracts/out/TradingPlatform.sol/TradingPlatform.json'

import MarketplaceView from './components/MarketplaceView.vue'
import MyCardsView from './components/MyCardsView.vue'
import type { Contract } from 'ethers'
import { markRaw } from 'vue';

export default {
  name: 'App',
  components: {
    MarketplaceView,
    MyCardsView,
  },
  setup() {
    const account = ref<string | null>(null)
    const provider = ref<ethers.providers.Web3Provider | null>(null)
    const pokemonContract = ref<Contract | null>(null)
    const tradingContract = ref<Contract | null>(null)
    const activeTab = ref('marketplace')
    const contractsInitialized = ref(false)

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
      if (window.ethereum) {
        provider.value = new ethers.providers.Web3Provider(window.ethereum as MetaMaskInpageProvider)
      } else {
        throw new Error('MetaMask is not installed')
      }
      provider.value = markRaw(provider.value)
      let signer = await provider.value.getSigner()
      signer = markRaw(signer)

      pokemonContract.value = new ethers.Contract(
        '0xaD94c8809A9a070a9DA47C6818c6390A7225D49a',
        PokemonCards.abi,
        signer,
      )

      console.log("here")

      tradingContract.value = new ethers.Contract(
        '0x9A4eE25f90dFdaf3c19e55825f2ed6228d5718Cc',
        TradingPlatform.abi,
        signer,
      )

      contractsInitialized.value = true
    }

    const shortenAddress = (address: string) => {
      return `${address.slice(0, 6)}...${address.slice(-4)}`
    }

    onMounted(() => {
      // Check if already connected
      if (window.ethereum) {
        window.ethereum.request({ method: 'eth_accounts' }).then((accounts: string[]) => {
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
      contractsInitialized,
    }
  },
}
</script>

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
        <div v-if="contractsInitialized && activeTab === 'marketplace'">
          <marketplace-view
            :account="account"
            :tradingContract="tradingContract || {}"
            :pokemonContract="pokemonContract || {}"
          />
        </div>
        <div v-else>
          <my-cards-view
            :account="account"
            :tradingContract="tradingContract || {}"
            :pokemonContract="pokemonContract || {}"
          />
        </div>
      </div>
    </main>
  </div>
</template>


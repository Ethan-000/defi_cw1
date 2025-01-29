<template>
  <div>
    <div class="mb-6 space-y-4">
      <h2 class="text-xl font-semibold">Mint New Cards</h2>
      <div class="flex space-x-4 items-center">
        <input
          v-model="mintAmount"
          type="number"
          min="1"
          max="10"
          class="border rounded px-3 py-2 w-24"
        />
        <button
          @click="mintCards"
          class="bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600"
        >
          Mint Cards
        </button>
      </div>
    </div>

    <h2 class="text-xl font-semibold mb-4">My Cards</h2>
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div v-for="card in myCards" :key="card.tokenId" class="bg-white rounded-lg shadow-md p-4">
        <div class="mb-4">
          <img :src="card.imageUrl" alt="Pokemon Card" class="w-full h-48 object-contain" />
        </div>
        <div class="space-y-2">
          <h3 class="text-lg font-semibold">Token #{{ card.tokenId }}</h3>

          <!-- List Card Form -->
          <div v-if="!card.isListed" class="space-y-2">
            <input
              v-model="card.listingPrice"
              type="number"
              step="0.001"
              placeholder="Price in ETH"
              class="w-full border rounded px-3 py-2"
            />
            <div class="flex space-x-2">
              <button
                @click="listCard(card, false)"
                class="flex-1 bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
              >
                List for Sale
              </button>
              <button
                @click="listCard(card, true)"
                class="flex-1 bg-purple-500 text-white px-4 py-2 rounded hover:bg-purple-600"
              >
                Create Auction
              </button>
            </div>
          </div>

          <p v-else class="text-green-600">Listed for sale</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { ref, onMounted } from 'vue'
import { ethers } from 'ethers'

export default {
  name: 'MyCardsView',
  props: {
    account: String,
    tradingContract: {
      type: Object,
      required: true,
    },
    pokemonContract: {
      type: Object,
      required: true,
    },
  },
  setup(props) {
    interface Card {
      tokenId: number;
      imageUrl: string;
      isListed: boolean;
      listingPrice: string;
    }

    const myCards = ref<Card[]>([])
    const mintAmount = ref(1)

    const loadMyCards = async () => {
      console.log("pokemonContract", props.pokemonContract.address)
      const balance = await props.pokemonContract.balanceOf(props.account)
      const cards = []

      for (let i = 0; i < balance; i++) {
        const tokenId = await props.pokemonContract.tokenOfOwnerByIndex(props.account, i)
        const tokenURI = await props.pokemonContract.tokenURI(tokenId)

        cards.push({
          tokenId,
          imageUrl: `${tokenURI}/image`, // Adjust based on your metadata structure
          isListed: false,
          listingPrice: '',
        })
      }

      myCards.value = cards
    }

    const mintCards = async () => {
      try {
        const price = await props.pokemonContract.calculatePrice(mintAmount.value)

        console.log('Minting', mintAmount.value, 'cards for', price, 'ETH')

        const tx = await props.pokemonContract.mintPokemonCards(mintAmount.value, {
          value: price * mintAmount.value,
        })
        await tx.wait()
        await loadMyCards()
      } catch (error) {
        console.error('Error minting cards:', error)
      }
    }

    const listCard = async (card: Card, isAuction: boolean) => {
      try {
        // Approve trading contract if not already approved
        const isApproved = await props.pokemonContract.isApprovedForAll(
          props.account,
          props.tradingContract.address,
        )

        if (!isApproved) {
          const approveTx = await props.pokemonContract.setApprovalForAll(
            props.tradingContract.address,
            true,
          )
          await approveTx.wait()
        }

        const priceInWei = ethers.parseEther(card.listingPrice)

        let tx
        if (isAuction) {
          const duration = 7 * 24 * 60 * 60 // 7 days in seconds
          tx = await props.tradingContract.createAuction(card.tokenId, priceInWei, duration)
        } else {
          tx = await props.tradingContract.listCard(card.tokenId, priceInWei)
        }

        await tx.wait()
        card.isListed = true
        await loadMyCards()
      } catch (error) {
        console.error('Error listing card:', error)
      }
    }

    onMounted(() => {
      if (props.pokemonContract) {
        loadMyCards()
      }
    })

    return {
      myCards,
      mintAmount,
      mintCards,
      listCard,
    }
  },
}
</script>

<template>
  <div>
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div
        v-for="listing in listings"
        :key="listing.tokenId"
        class="bg-white rounded-lg shadow-md p-4"
      >
        <div class="mb-4">
          <img :src="listing.imageUrl" alt="Pokemon Card" class="w-full h-48 object-contain" />
        </div>
        <div class="space-y-2">
          <h3 class="text-lg font-semibold">Token #{{ listing.tokenId }}</h3>
          <p class="text-gray-600">Seller: {{ shortenAddress(listing.seller) }}</p>
          <p class="text-gray-600">Price: {{ ethers.formatEther(listing.price) }} ETH</p>
          <p v-if="listing.isAuction" class="text-gray-600">
            Ends: {{ formatDate(listing.deadline) }}
          </p>
          <button
            @click="listing.isAuction ? placeBid(listing) : purchaseCard(listing)"
            class="w-full bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
          >
            {{ listing.isAuction ? 'Place Bid' : 'Purchase' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { ref, onMounted } from 'vue'
import { ethers } from 'ethers'

export default {
  name: 'MarketplaceView',
  props: {
    account: String,
    tradingContract: Object,
    pokemonContract: Object,
  },
  setup(props) {
    const listings = ref([])

    const loadListings = async () => {
      // Implementation would depend on your event handling strategy
      // This is a simplified version
      const filter = props.tradingContract.filters.Listed()
      const events = await props.tradingContract.queryFilter(filter)

      const activeListings = await Promise.all(
        events.map(async (event) => {
          const listing = await props.tradingContract.listings(event.args.tokenId)
          if (listing.active) {
            const tokenURI = await props.pokemonContract.tokenURI(event.args.tokenId)
            return {
              ...listing,
              tokenId: event.args.tokenId,
              imageUrl: `${tokenURI}/image`, // Adjust based on your metadata structure
            }
          }
          return null
        }),
      )

      listings.value = activeListings.filter((l) => l !== null)
    }

    const purchaseCard = async (listing) => {
      try {
        const tx = await props.tradingContract.purchaseCard(listing.tokenId, {
          value: listing.price,
        })
        await tx.wait()
        await loadListings()
      } catch (error) {
        console.error('Error purchasing card:', error)
      }
    }

    const placeBid = async (listing) => {
      try {
        const bidAmount = prompt('Enter bid amount in ETH:')
        if (!bidAmount) return

        const tx = await props.tradingContract.placeBid(listing.tokenId, {
          value: ethers.parseEther(bidAmount),
        })
        await tx.wait()
        await loadListings()
      } catch (error) {
        console.error('Error placing bid:', error)
      }
    }

    const formatDate = (timestamp) => {
      return new Date(timestamp * 1000).toLocaleString()
    }

    const shortenAddress = (address) => {
      return `${address.slice(0, 6)}...${address.slice(-4)}`
    }

    onMounted(() => {
      if (props.tradingContract) {
        loadListings()
      }
    })

    return {
      listings,
      purchaseCard,
      placeBid,
      formatDate,
      shortenAddress,
      ethers,
    }
  },
}
</script>

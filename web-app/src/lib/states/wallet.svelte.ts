import 'viem/window' // Polyfill ethereum property in the window object
import {
    createWalletClient,
    custom,
    publicActions,
    type WalletClient,
    type PublicClient,
    parseAbi,
} from 'viem'
import { arbitrum } from 'viem/chains'
import { browser } from '$app/environment'
import { toast } from 'svelte-sonner'

type Address = `0x${string}`

const TOKEN_ADDRESS: Address = '0xaf88d065e77c8cC2239327C5EDb3A432268e5831'

class WalletConnection {
    // Reactive states
    address = $state<Address | null>(null)
    balance = $state<BigInt | null | string>(null)
    connected = $state<boolean>(false)

    // Non reactive states
    client!: WalletClient & PublicClient

    constructor() {
        if (browser) {
            if (!window.ethereum) {
                return
            }

            this.client = createWalletClient({
                chain: arbitrum,
                transport: custom(window.ethereum as any),
            }).extend(publicActions)

            // If we have already requested access then great, let's populate the address
            this.client.getAddresses().then(([address]) => {
                this.address = address
                if (address != null) {
                    this.connected = true
                    this.readTokenBalance()
                }
            })
        }
    }

    async disconnect() {
        this.address = null
        this.balance = null
        this.connected = false

        toast.info('Disconnect from wallet to revoke permissions!', {
            description: 'Revoking permissions from wallet after use is a good security practice.',
        })
    }

    async connect() {
        if (!window.ethereum) {
            toast.error('Browser wallet not found!', {
                description: 'Please install a browser wallet to continue.',
            })
            return
        }
        await this.requestAddressOnceIfNecessary()
        if (this.address != null) {
            this.connected = true
            this.readTokenBalance()
        }
    }

    async requestAddressOnceIfNecessary() {
        if (this.address) {
            return
        }
        ;[this.address] = await this.client.requestAddresses()
    }

    async readTokenBalance() {
        if (!this.address) {
            return
        }
        await this.client.switchChain({ id: arbitrum.id })
        const tokenBalance = await this.client.readContract({
            abi: parseAbi(['function balanceOf(address) view returns (uint256)']),
            address: TOKEN_ADDRESS,
            functionName: 'balanceOf',
            args: [this.address],
        })
        const decimals = await this.client.readContract({
            abi: parseAbi(['function decimals() returns (uint8)']),
            address: TOKEN_ADDRESS,
            functionName: 'decimals',
        })
        const totalValue = Number(tokenBalance) / 10 ** decimals
        this.balance = totalValue.toFixed(4)
    }
}

export let walletConnectionState = new WalletConnection()

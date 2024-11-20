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

// ABI imports
import { faucetAbi } from '$lib/abis/faucet'
import { wenAbi } from '$lib/abis/wen'
import { tokenAbi } from '$lib/abis/token'

type Address = `0x${string}`

// Arbitrum logs
// Deployer: 0x4069EfF36C2106C813aCa57C64a6194f3b4290CB
// Token deployment: 0x405DEbce0c54Df382B82d2B227d54cc1cDEe5A92
// Deployer rewarded: 1000000000000000000000000000
// Faucet deployment: 0x16D218938416d58C58CaC586D57F27fD8CAfBec1
// Facuet rewarded: 20000 $ILTMUELC tokens
//
// Found out from block explorer:
// Wen addres: 0xF008aa381a575E1b4F909a16D9f1784b25221193

const TOKEN_ADDRESS: Address = '0x405DEbce0c54Df382B82d2B227d54cc1cDEe5A92';
const FAUCET_ADDRESS: Address = '0x16D218938416d58C58CaC586D57F27fD8CAfBec1';
const WEN_ADDRESS: Address = '0xF008aa381a575E1b4F909a16D9f1784b25221193';

type WenGameGuess = ReadonlyArray<BigInt>;

class WalletConnection {
    // Reactive states
    address = $state<Address | null>(null)
    balance = $state<BigInt | null | string>(null)
    balanceIncludingDecimals = $state<BigInt | null>(null)
    decimals = $state<BigInt | null>(null)
    connected = $state<boolean>(false)

    faucetUsersLastMintedTime = $state<BigInt | null>(null)
    faucetMintInterval = $state<BigInt | null>(null)
    faucetMintAmount = $state<BigInt | null>(null)
    faucetPaused = $state<boolean | null>(null)

    // Wen Game states that always have a meaning
    wenGameName = $state<string | null>(null)
    wenStartDate = $state<BigInt | null>(null) // block.timestamp 
    wenParticipationFee = $state<BigInt | null>(null)
    wenGameEnded = $state<boolean | null>(null)
    wenDidUserParticipate = $state<boolean | null>(null)

    // Wen Game states that have meaning only in playing phase
    wenUserGuess = $state<WenGameGuess | null>(null)

    // Wen Game states that have meaning only in ending phase (i.e, after game has ended)
    wenEndDate = $state<BigInt | null>(null) // 0 initially, then later I set the block.timestamp
    wenCorrectAnswer = $state<WenGameGuess | null>(null)
    wenIsThereWinner = $state<boolean | null>(null)
    wenIndividualReward = $state<BigInt | null>(null)
    wenDidUserGetPaid = $state<boolean | null>(null)


    // TODO : wenParticipants can be an expensive function, later to be included in stats

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
                    this.readFaucetConditions()
                    this.readWenGameConditions()
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
            await this.readTokenBalance()
            await this.readFaucetConditions()
            await this.readWenGameConditions()
        }
    }

    async requestAddressOnceIfNecessary() {
        if (this.address) {
            return
        }
        [this.address] = await this.client.requestAddresses();
    }

    async readTokenBalance() {
        if (!this.address) {
            return
        }
        await this.client.switchChain({ id: arbitrum.id })
        this.balanceIncludingDecimals = await this.client.readContract({
            abi: parseAbi(['function balanceOf(address) view returns (uint256)']),
            address: TOKEN_ADDRESS,
            functionName: 'balanceOf',
            args: [this.address],
        })
        this.decimals = await this.client.readContract({
            abi: parseAbi(['function decimals() returns (uint8)']),
            address: TOKEN_ADDRESS,
            functionName: 'decimals',
        })
        const totalValue = Number(this.balanceIncludingDecimals) / 10 ** this.decimals
        this.balance = totalValue.toFixed(4)
    }

    async readFaucetConditions() {
        await this.client.switchChain({ id: arbitrum.id })
        this.faucetMintInterval = await this.client.readContract({
            abi: faucetAbi,
            address: FAUCET_ADDRESS,
            functionName: 's_mintInterval',
        })
        this.faucetMintAmount = await this.client.readContract({
            abi: faucetAbi,
            address: FAUCET_ADDRESS,
            functionName: 's_mintAmount',
        })
        this.faucetPaused = await this.client.readContract({
            abi: faucetAbi,
            address: FAUCET_ADDRESS,
            functionName: 'paused'
        })
        if (this.address) {
            this.faucetUsersLastMintedTime = await this.client.readContract({
                abi: faucetAbi,
                address: FAUCET_ADDRESS,
                functionName: 's_lastMintedTime',
                args: [this.address],
            })
        }
    }

    async readWenGameConditions() {
        await this.client.switchChain({ id: arbitrum.id })
        this.wenStartDate = await this.client.readContract({
            abi: wenAbi,
            address: WEN_ADDRESS,
            functionName: 'i_startDate'
        })
        this.wenEndDate = await this.client.readContract({
            abi: wenAbi,
            address: WEN_ADDRESS,
            functionName: 's_endDate'
        })
        this.wenGameName = await this.client.readContract({
            abi: wenAbi,
            address: WEN_ADDRESS,
            functionName: 's_gameName'
        })
        this.wenGameEnded = await this.client.readContract({
            abi: wenAbi,
            address: WEN_ADDRESS,
            functionName: 's_gameEnded'
        })
        this.wenParticipationFee = await this.client.readContract({
            abi: wenAbi,
            address: WEN_ADDRESS,
            functionName: 's_participationFee'
        })
        if (this.address !== null) {
            this.wenUserGuess = await this.client.readContract({
                abi: wenAbi,
                address: WEN_ADDRESS,
                functionName: 's_guess',
                args: [this.address]
            })
            this.wenDidUserParticipate = await this.client.readContract({
                abi: wenAbi,
                address: WEN_ADDRESS,
                functionName: 's_participated',
                args: [this.address]
            })
            this.wenDidUserGetPaid = await this.client.readContract({
                abi: wenAbi,
                address: WEN_ADDRESS,
                functionName: 's_paid',
                args: [this.address]
            })
        }
        this.wenCorrectAnswer = await this.client.readContract({
            abi: wenAbi,
            address: WEN_ADDRESS,
            functionName: 's_correctAns'
        })
        this.wenIndividualReward = await this.client.readContract({
            abi: wenAbi,
            address: WEN_ADDRESS,
            functionName: 's_individualReward'
        })
        this.wenIsThereWinner = await this.client.readContract({
            abi: wenAbi,
            address: WEN_ADDRESS,
            functionName: 's_thereIsAWinner'
        })
    }

    async playWenGame(date: bigint, month: bigint, year: bigint) {
        if (!this.address) {
            return;
        }
        await this.client.switchChain({ id: arbitrum.id })

        try {

            const allowance = await this.client.readContract({
                abi: tokenAbi,
                address: TOKEN_ADDRESS,
                functionName: 'allowance',
                args: [this.address, WEN_ADDRESS]
            }) ?? 0n;

            const participationFee = this.wenParticipationFee?.valueOf();

            if (participationFee) {
                if (allowance.valueOf() < (this.wenParticipationFee?.valueOf() ?? 1)) {
                    // First ask for approval
                    const hash = await this.client.writeContract({
                        abi: tokenAbi,
                        address: TOKEN_ADDRESS,
                        functionName: 'approve',
                        chain: arbitrum,
                        account: this.address,
                        args: [WEN_ADDRESS, participationFee]
                    })

                    toast.info('Transaction succeeded', {
                        description: hash
                    })
                }
            }
            const hash = await this.client.writeContract({
                abi: wenAbi,
                address: WEN_ADDRESS,
                functionName: 'play',
                chain: arbitrum,
                account: this.address,
                args: [{
                    date, month, year
                }]
            })

            toast.info('Transaction succeeded', {
                description: hash
            })

            this.readTokenBalance()
            this.readFaucetConditions()
            this.readWenGameConditions()
        } catch (e) {
            toast.error('Transaction failed', {
                description: 'Error processing your transaction. Try again later'
            })
        }
    }

    async claimRewards() {
        if (!this.address) {
            return;
        }
        this.client.switchChain({ id: arbitrum.id })

        try {
            const hash = await this.client.writeContract({
                abi: wenAbi,
                address: WEN_ADDRESS,
                functionName: 'claim',
                chain: arbitrum,
                account: this.address,
            })

            toast.info('Transaction succeeded', {
                description: hash
            })

            this.readTokenBalance()
            this.readFaucetConditions()
            this.readWenGameConditions()
        } catch (e) {
            toast.error('Transaction failed', {
                description: 'Error processing your transaction. Try again later'
            })
        }

    }

    async mintTokensFromFaucet() {
        if (!this.address) {
            return;
        }
        await this.client.switchChain({ id: arbitrum.id })

        try {
            const hash = await this.client.writeContract({
                abi: faucetAbi,
                address: FAUCET_ADDRESS,
                functionName: 'mint',
                chain: arbitrum,
                account: this.address,
            })
            toast.info('Transaction succeeded', {
                description: hash
            })
            this.readTokenBalance()
            this.readFaucetConditions()
            this.readWenGameConditions()
        } catch (e) {
            toast.error('Transaction failed', {
                description: 'Error processing transaction. Try again later'
            })
        }
    }
}

export let walletConnectionState = new WalletConnection()

<script lang="ts">
    // State libraries
    import { walletConnectionState } from '$lib/states/wallet.svelte'

    // Svelte
    import Button from '$lib/components/ui/button/button.svelte'
    import * as Tooltip from '$lib/components/ui/tooltip/index.js'
    import { HandCoinsIcon } from 'lucide-svelte'
    import * as AlertDialog from '$lib/components/ui/alert-dialog/index.js'
    import LoaderCircle from 'lucide-svelte/icons/loader-circle'
    import { cn } from '$lib/utils'

    let addressMsg = $derived(walletConnectionState.address ?? 'Waiting for wallet connection ...')
    let tokenBalanceMsg = $derived(walletConnectionState.balance ?? 'Loading ...')
    let decimals = $derived(Number(walletConnectionState.decimals ?? 1n))

    let mintIntervalInSeconds = $derived(walletConnectionState.faucetMintInterval ?? 1n)
    let mintIntervalInHours = $derived(Number(mintIntervalInSeconds.valueOf()) / (60 * 60))
    let lastMintedTimeInSeconds = $derived(walletConnectionState.faucetUsersLastMintedTime ?? 0n)
    let mintAmount = $derived(Number(walletConnectionState.faucetMintAmount) / 10 ** decimals)
    let isFaucetPaused = $derived(walletConnectionState.faucetPaused ?? false)

    let timeLeftToMintInSeconds = $derived.by(() => {
        const currentTimeInSeconds = BigInt(Math.round(Date.now() / 1000)).valueOf()
        const timeElapsedInSeconds = currentTimeInSeconds - lastMintedTimeInSeconds.valueOf()
        return Math.max(0, Number(mintIntervalInSeconds.valueOf() - timeElapsedInSeconds))
    })
    let timeLeftToMintInHours = $derived(Number(timeLeftToMintInSeconds.valueOf()) / (60 * 60))
    let isMintDisabled = $derived(timeLeftToMintInSeconds > 0)
    let reasonForDisabledMint = $derived(
        isMintDisabled ? `Try again after ${Math.round(timeLeftToMintInHours) + 1} hours !` : '',
    )
    let isOpen = $state(false)
    let isBeingMinted = $state(false)

    async function handleMintRequest() {
        isBeingMinted = true
        await walletConnectionState.mintTokensFromFaucet()
        isBeingMinted = false
        isOpen = false
    }
</script>

<div class="m-10 lg:m-20">
    <h1 class="scroll-m-20 text-4xl font-extrabold tracking-tight lg:text-5xl">Mint</h1>
    <p class="leading-7 text-muted-foreground [&:not(:first-child)]:mt-6">$ILTMUELC</p>

    <p class="leading-7 [&:not(:first-child)]:mt-6"></p>
    <blockquote class="mt-6 border-l-2 pl-6 italic">
        "Greatness belongs to the brave… and the finest champions are those who mint their tokens
        boldly."
    </blockquote>

    <div class="mt-9 flex h-64 items-center justify-center border-4 border-dotted border-gray-100">
        <div class="flex flex-col items-center text-center">
            <div>Your Address:</div>
            <div class="text-wrap break-all text-lg md:ml-2 md:font-semibold">
                {addressMsg}
            </div>
            {#if walletConnectionState.connected}
                <div class="mt-9">$ILTMUELC Balance:</div>
                <div class="text-wrap break-all text-lg md:ml-2 md:font-semibold">
                    {tokenBalanceMsg}
                </div>
            {/if}
        </div>
    </div>

    <div class="flex items-center justify-center">
        {#if walletConnectionState.connected}
            <Button class="mt-6" onclick={() => walletConnectionState.disconnect()}>
                Disconnect
            </Button>
            <div class="ml-4 mt-6">
                <AlertDialog.Root bind:open={isOpen}>
                    <AlertDialog.Trigger
                        disabled={isMintDisabled}
                        class={cn({ 'cursor-not-allowed': isMintDisabled })}
                    >
                        <Tooltip.Root>
                            <Tooltip.Trigger class={cn({ 'cursor-not-allowed': isMintDisabled })}>
                                <Button disabled={isMintDisabled} variant="destructive">
                                    Mint
                                    <HandCoinsIcon />
                                </Button>
                            </Tooltip.Trigger>

                            {#if isMintDisabled}
                                <Tooltip.Content>
                                    <p>{reasonForDisabledMint}</p>
                                </Tooltip.Content>
                            {/if}
                        </Tooltip.Root>
                    </AlertDialog.Trigger>
                    <AlertDialog.Content>
                        <AlertDialog.Header>
                            <AlertDialog.Title>Are you sure to receive?</AlertDialog.Title>
                            <AlertDialog.Description>
                                You can claim {mintAmount} $ILTMUELC tokens every {mintIntervalInHours}
                                hours from the faucet.
                            </AlertDialog.Description>
                        </AlertDialog.Header>
                        <AlertDialog.Footer>
                            <AlertDialog.Cancel>Cancel</AlertDialog.Cancel>
                            <AlertDialog.Action
                                onclick={handleMintRequest}
                                disabled={isBeingMinted}
                            >
                                {#if !isBeingMinted}
                                    Continue
                                {:else}
                                    <LoaderCircle class="mr-2 h-4 w-4 animate-spin" />
                                    Minting
                                {/if}
                            </AlertDialog.Action>
                        </AlertDialog.Footer>
                    </AlertDialog.Content>
                </AlertDialog.Root>
            </div>
        {:else}
            <Button class="mt-6" onclick={() => walletConnectionState.connect()}>Connect</Button>
        {/if}
    </div>
</div>
{#if isFaucetPaused}
    <div class="absolute bottom-0 flex w-full bg-yellow-200 py-2 text-gray-600">
        <p class="mx-auto">
            Faucet is under maintenance. Tokens are being added! Please check back in an hour to
            mint.
        </p>
    </div>
{/if}

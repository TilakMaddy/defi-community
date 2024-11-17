<script lang="ts">
    // State libraries
    import { walletConnectionState } from '$lib/states/wallet.svelte'

    // Svelte
    import Button from '$lib/components/ui/button/button.svelte'
    import { HandCoinsIcon } from 'lucide-svelte'

    let addressMsg = $derived(walletConnectionState.address ?? 'Waiting for wallet connection ...')
    let tokenBalanceMsg = $derived(walletConnectionState.balance ?? 'Loading ...')
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
            <Button class="mt-6" onclick={() => walletConnectionState.disconnect()}
                >Disconnect</Button
            >
            <Button class="ml-4 mt-6">Mint <HandCoinsIcon /></Button>
        {:else}
            <Button class="mt-6" onclick={() => walletConnectionState.connect()}>Connect</Button>
        {/if}
    </div>
</div>

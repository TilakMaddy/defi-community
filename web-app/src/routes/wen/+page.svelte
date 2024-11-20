<script lang="ts">
    // State libraries
    import { walletConnectionState } from '$lib/states/wallet.svelte'
    import { getLocalTimeZone, today } from '@internationalized/date'
    import { Calendar } from '$lib/components/ui/calendar/index.js'
    import { Button } from '$lib/components/ui/button'
    import { cn } from '$lib/utils'
    import * as Tooltip from '$lib/components/ui/tooltip/index.js'

    let value = $state(today(getLocalTimeZone()))

    let gameName = $derived(walletConnectionState.wenGameName ?? ' retrieving name ... ')
    let decimals = $derived(Number(walletConnectionState.decimals ?? 1n))
    let participationFee = $derived(
        Number(walletConnectionState.wenParticipationFee ?? 1) / 10 ** decimals,
    )
    let [d, m, y] = $derived([value.day, value.month, value.year])
    let didUserParticipate = $derived(walletConnectionState.wenDidUserParticipate ?? true)
    let userGuess = $derived.by(() => {
        const [guessDay, guessMonth, guessYear] = walletConnectionState.wenUserGuess ?? [1, 1, 2024]
        return `${guessDay}/${guessMonth}/${guessYear}`
    })
    let gameHasEnded = $derived(walletConnectionState.wenGameEnded ?? false)
    let correctAnswer = $derived.by(() => {
        const [corrDay, corrMonth, corrYear] = walletConnectionState.wenCorrectAnswer ?? [
            1, 1, 2024,
        ]
        return `${corrDay}/${corrMonth}/${corrYear}`
    })
    let gameEndedDate = $derived.by(() => {
        const wenEndDateInMilliseconds = walletConnectionState.wenEndDate ?? new Date().getTime()
        const wenEndDate = new Date(Number(wenEndDateInMilliseconds))
        return `${wenEndDate.getDay()}/${wenEndDate.getMonth()}/${wenEndDate.getFullYear()}`
    })
    let gameHasWinner = $derived(walletConnectionState.wenIsThereWinner ?? false)
    let individualReward = $derived(
        Number(walletConnectionState.wenIndividualReward ?? 1) / 10 ** decimals,
    )
    let didUserGetPaid = $derived(walletConnectionState.wenDidUserGetPaid ?? true)
    let userGuessedCorrectly = $derived(correctAnswer === userGuess)
</script>

<div class="m-10 lg:m-20">
    <h1 class="scroll-m-20 text-4xl font-extrabold tracking-tight lg:text-5xl">Wen</h1>
    <p class="leading-7 text-muted-foreground [&:not(:first-child)]:mt-6">$ILTMUELC</p>

    <p class="leading-7 [&:not(:first-child)]:mt-6"></p>
    <blockquote class="mb-10 mt-6 border-l-2 pl-6 italic">
        "Good things come to those who wait… and even better results come to those who refresh
        obsessively."~ Mr.Nobody
    </blockquote>

    {#if walletConnectionState.connected}
        <h2 class="m-8" style="line-height: 1.8;">
            Pick a date for when you think the appeals reviews phase will end for <b>{gameName}</b>.
            If you do so correctly, when that date comes you can win all the $ILTMUELC tokens paid
            by other users! No platform fee 💯, remember 😁 !
        </h2>

        <div class="m-8 flex items-center justify-center">
            <Calendar type="single" bind:value class="rounded-md border" />
        </div>

        <div class="flex justify-center">
            <Tooltip.Root>
                <Tooltip.Trigger class={cn({ 'cursor-not-allowed': didUserParticipate })}>
                    <Button
                        class={cn('bg-green-500 text-white dark:text-black')}
                        disabled={didUserParticipate}
                        onclick={async () => {
                            await walletConnectionState.playWenGame(BigInt(d), BigInt(m), BigInt(y))
                        }}
                    >
                        Play {participationFee} $ILTMUELC
                    </Button>
                </Tooltip.Trigger>

                {#if didUserParticipate}
                    <Tooltip.Content>
                        <p>You have already made a guess for {userGuess}, mate!</p>
                    </Tooltip.Content>
                {/if}
            </Tooltip.Root>
        </div>

        {#if gameHasEnded}
            <h2 class="m-8">
                Game has ended on {gameEndedDate} and the correct answer was <b>{correctAnswer}</b>.
                {#if !gameHasWinner}
                    No one guessed correctly!
                {/if}
                {#if didUserGetPaid}
                    You have collected a reward of {individualReward} $ILTMUELC
                {:else if gameHasWinner && userGuessedCorrectly}
                    Claim your reward of {individualReward} $ILTMUELC!
                {:else if !gameHasWinner}
                    Get back your tokens {individualReward} $ILTMUELC
                {/if}
            </h2>

            <div class="m-8">
                {#if !didUserGetPaid}
                    <Button
                        class="bg-[goldenrod] text-white dark:text-black"
                        onclick={async () => {
                            await walletConnectionState.claimRewards()
                        }}>Claim</Button
                    >
                {/if}
            </div>
        {/if}
    {:else}
        <Button class="mt-6" onclick={() => walletConnectionState.connect()}>Connect</Button>
    {/if}
</div>

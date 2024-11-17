<script>
    let arrowSize = $state('scale-0')

    function showArrow() {
        arrowSize = 'scale-55'
    }

    function hideArrow() {
        arrowSize = 'scale-0'
    }
</script>

<div class="m-10 lg:m-20">
    <h1 class="scroll-m-20 text-4xl font-extrabold tracking-tight lg:text-5xl">
        Cheesy Web3 Games
    </h1>
    <p class="leading-7 [&:not(:first-child)]:mt-6">Just that. Cringe Maxxxing</p>
    <h2
        class="mt-10 scroll-m-20 border-b pb-2 text-3xl font-semibold tracking-tight transition-colors first:mt-0"
    >
        👀
    </h2>
    <p class="leading-7 [&:not(:first-child)]:mt-6">
        Joining the Cyfrin Discord channel has been a blast, and I wanted to add to the fun.
        Questions like “Wen Payout?” and “Wen’s the next Codehawks contest?” pop up all the time, so
        I decided to build some games around them to keep the vibe playful! Plus, I’ve been meaning
        to <a
            href="https://svelte.dev/blog/svelte-5-is-alive"
            class="font-medium text-primary underline underline-offset-4"
        >
            learn Svelte 5
        </a>
        — heard a ton of good things about it — so I figured this open-source project would be the perfect
        way to dive in.
    </p>
    <blockquote class="mt-6 border-l-2 pl-6 italic">
        "Good things come to those who wait… and even better results come to those who refresh
        obsessively."~ Mr.Nobody
    </blockquote>
    <h3 class="mt-8 scroll-m-20 text-2xl font-semibold tracking-tight">Plan</h3>
    <p class="leading-7 [&:not(:first-child)]:mt-6">
        $ILTMUELC is the participation token for the games. Initially the tokens can be minted for
        free by anyone on the internet who can use a keyboard and is not totally blind. Later these
        tokens will be minted in exchange for real money. Sponsors can mint bulk tokens with no
        limits and the sponsor money will be used in supplying rewards for game participants.
        Sponsors will qualify for receiving a share in $ILTMUELC
    </p>
    <h3 class="mt-8 scroll-m-20 text-2xl font-semibold tracking-tight">Tech Stack</h3>
    <ul class="my-6 ml-6 list-disc [&>li]:mt-2">
        <li>Frontend : Svelte 5</li>
        <li>Backend : Svelte Kit 2</li>
        <li>Contracts : Foundry's forge</li>
    </ul>
    <p class="leading-7 [&:not(:first-child)]:mt-6">
        Please contribute <a
            href="http://github.com/tilakmaddy"
            class="relative font-medium text-primary underline underline-offset-4 hover:no-underline"
            onmouseenter={showArrow}
            onmouseleave={hideArrow}
        >
            <span
                class="absolute bottom-[4px] right-[-16px] {arrowSize} rotate-[-10deg] transition-transform"
            >
                ↗️
            </span>
            here
        </a>
    </p>
    <h3 class="mt-8 scroll-m-20 text-2xl font-semibold tracking-tight">Game Ideas</h3>
    <p class="leading-7 [&:not(:first-child)]:mt-6">
        Github Issues / Discussions would be the ideal place to discuss it. Share wins on discord !
    </p>
</div>

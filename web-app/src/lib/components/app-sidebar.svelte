<script lang="ts">
    import House from 'lucide-svelte/icons/house'
    import * as Sidebar from '$lib/components/ui/sidebar/index.js'
    import {
        ChartNoAxesCombinedIcon,
        CircleDollarSignIcon,
        HandCoinsIcon,
        LucideBird,
    } from 'lucide-svelte'

    type MenuLabel = string
    type MenuItem = {
        title: string
        url: string
        icon: any
    }
    type MenuContents = MenuItem[]

    const menu: Array<[MenuLabel, MenuContents]> = [
        [
            'Application',
            [
                {
                    title: 'Home',
                    url: '/',
                    icon: House,
                },
                {
                    title: 'Mint $ILTMUELC',
                    url: '/mint',
                    icon: HandCoinsIcon,
                },
                {
                    title: 'Stats',
                    url: '#',
                    icon: ChartNoAxesCombinedIcon,
                },
            ],
        ],
        [
            'Games',
            [
                {
                    title: 'Wen Codehawk Results',
                    url: '#',
                    icon: LucideBird,
                },
            ],
        ],
        [
            'Sponsor',
            [
                {
                    title: 'Sponsor',
                    url: '#',
                    icon: CircleDollarSignIcon,
                },
            ],
        ],
    ]
</script>

<Sidebar.Root>
    <Sidebar.Content>
        {#each menu as menuGroup (menuGroup[0])}
            <Sidebar.Group>
                <Sidebar.GroupLabel>{menuGroup[0]}</Sidebar.GroupLabel>
                <Sidebar.GroupContent>
                    <Sidebar.Menu>
                        {#each menuGroup[1] as item (item.title)}
                            <Sidebar.MenuItem>
                                <Sidebar.MenuButton>
                                    {#snippet child({ props })}
                                        <a href={item.url} {...props}>
                                            <item.icon />
                                            <span>{item.title}</span>
                                        </a>
                                    {/snippet}
                                </Sidebar.MenuButton>
                            </Sidebar.MenuItem>
                        {/each}
                    </Sidebar.Menu>
                </Sidebar.GroupContent>
            </Sidebar.Group>
        {/each}
    </Sidebar.Content>
</Sidebar.Root>

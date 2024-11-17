<script lang="ts">
    import '../app.css'
    import { ModeWatcher } from 'mode-watcher'
    import * as Sidebar from '$lib/components/ui/sidebar/index.js'
    import AppSidebar from '$lib/components/app-sidebar.svelte'
    import { Button } from '$lib/components/ui/button/index'
    import { Moon, Sun } from 'lucide-svelte/icons'
    import { toggleMode } from 'mode-watcher'
    import { Toaster } from '$lib/components/ui/sonner/index.js'

    let { children } = $props()
</script>

<svelte:head>
    <title>Games</title>
</svelte:head>

<ModeWatcher />

<Toaster />

<Sidebar.Provider>
    <AppSidebar />
    <main class="w-full">
        <Sidebar.Trigger />
        {@render children?.()}
    </main>
</Sidebar.Provider>

<Button onclick={toggleMode} variant="outline" size="icon" class="fixed right-6 top-6">
    <Sun
        class="h-[1.2rem] w-[1.2rem] rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0"
    />
    <Moon
        class="absolute h-[1.2rem] w-[1.2rem] rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100"
    />
    <span class="sr-only">Toggle theme</span>
</Button>

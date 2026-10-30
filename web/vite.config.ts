import { defineConfig } from 'vite';
import { svelte } from '@sveltejs/vite-plugin-svelte';

// NUI pages load from nui://, so every asset path has to be relative
export default defineConfig({
    plugins: [svelte()],
    base: './',
    build: {
        target: 'chrome90',
        outDir: 'dist',
        emptyOutDir: true,
        assetsInlineLimit: 0,
    },
});

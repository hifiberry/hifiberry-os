import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import vueDevTools from 'vite-plugin-vue-devtools'

// A vite plugin that remove all the specified console types in the production environment
// https://www.npmjs.com/package/vite-plugin-remove-console
import removeConsole from 'vite-plugin-remove-console'

// https://vite.dev/config/
export default defineConfig({
  base: '/ui/',
  plugins: [vue(), vueDevTools(), removeConsole()],
  build: {
    rollupOptions: {
      output: {
        // Option 1: Remove hashes entirely (static filenames)
        entryFileNames: 'assets/[name].js',
        chunkFileNames: 'assets/[name].js',
        assetFileNames: 'assets/[name].[ext]',
        
        // Option 2: Use more predictable hashes (uncomment to use instead)
        // entryFileNames: 'assets/[name].[hash:8].js',
        // chunkFileNames: 'assets/[name].[hash:8].js',
        // assetFileNames: 'assets/[name].[hash:8].[ext]',
      }
    }
  },
  css: {
    preprocessorOptions: {
      scss: {
        additionalData:
          '@use "@/assets/scss/variables.scss" as *; @use "@/assets/scss/mixins.scss" as *; @use "@/assets/scss/variables/colors.scss" as *; @use "@/assets/scss/themes.scss" as *;',
      },
    },
  },
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
})

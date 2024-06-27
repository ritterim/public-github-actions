import {resolve} from 'path'
import { defineConfig } from 'vite'
import { builtinModules } from 'module'
import dts from 'vite-plugin-dts'

export default defineConfig({
  define: {
    global: {}
  },
  build: {
    rollupOptions: {
      external: builtinModules,
      input: {
        main: resolve(__dirname, 'src/index.ts')
      },
      output: {
        entryFileNames: 'index.js'
      }
    },
    assetsDir: './',
    minify: true
  },
  plugins: [dts()]
})

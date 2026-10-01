import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { viteSingleFile } from 'vite-plugin-singlefile'
import path from 'path'

export default defineConfig({
  plugins: [
    vue(),
    viteSingleFile()
  ],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  build: {
    outDir: path.resolve(__dirname, '../dn1c_time_project2/dn1c_time_project2/ui'),
    emptyOutDir: false,
    target: 'esnext',
    minify: true,
  },
})

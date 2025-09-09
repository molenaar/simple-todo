import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: [],
    include: [
      'src/**/*.test.ts',
      'src/**/*.test.tsx'
    ],
    exclude: [
      'node_modules/**',
      'dist/**',
      '.astro/**'
    ]
  },
  resolve: {
    alias: {
      '~/': new URL('./src/', import.meta.url).pathname
    }
  }
});

export default {
  test: {
    // Client tests need happy-dom and run via pnpm --filter @veins/client test.
    // Exclude them here so the root npx vitest run stays in Node environment.
    exclude: ['src/client/**', '**/node_modules/**'],
  },
};

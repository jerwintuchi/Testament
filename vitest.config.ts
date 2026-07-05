import { defineConfig, configDefaults } from 'vitest/config';

export default defineConfig({
  test: {
    // Server + shared run in the Node environment. The Godot client has its own
    // test tooling and lives outside this TypeScript workspace.
    //
    // Extend (don't replace) the vitest defaults so build output stays excluded:
    // the shared/server `build` scripts emit compiled `*.test.js` into `dist/`,
    // and a bare `exclude: ['**/node_modules/**']` would drop the default
    // `**/dist/**` and run every test twice (once from src, once from dist).
    exclude: [...configDefaults.exclude],
  },
});

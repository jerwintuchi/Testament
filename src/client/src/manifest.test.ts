// @vitest-environment node
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { join, dirname } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
// __dirname is src/client/src; index.html and public/ are one level up in src/client/
const indexHtml = readFileSync(join(__dirname, '../index.html'), 'utf-8');

const manifest = JSON.parse(
  readFileSync(join(__dirname, '../public/manifest.json'), 'utf-8')
) as Record<string, unknown>;

describe('PWA manifest.json (T7, R1)', () => {
  it('has display: standalone', () => {
    expect(manifest.display).toBe('standalone');
  });

  it('has name and short_name', () => {
    expect(typeof manifest.name).toBe('string');
    expect(typeof manifest.short_name).toBe('string');
  });

  it('has a start_url', () => {
    expect(typeof manifest.start_url).toBe('string');
  });

  it('has theme_color and background_color', () => {
    expect(typeof manifest.theme_color).toBe('string');
    expect(typeof manifest.background_color).toBe('string');
  });

  it('has an icons array with at least one entry', () => {
    expect(Array.isArray(manifest.icons)).toBe(true);
    const icons = manifest.icons as unknown[];
    expect(icons.length).toBeGreaterThan(0);
  });
});

describe('index.html PWA meta tags (T7, R1)', () => {
  it('links to /manifest.json', () => {
    expect(indexHtml).toContain('href="/manifest.json"');
  });

  it('has apple-mobile-web-app-capable meta tag', () => {
    expect(indexHtml).toContain('apple-mobile-web-app-capable');
  });

  it('has apple-mobile-web-app-status-bar-style meta tag', () => {
    expect(indexHtml).toContain('apple-mobile-web-app-status-bar-style');
  });

  it('has theme-color meta tag', () => {
    expect(indexHtml).toContain('theme-color');
  });
});

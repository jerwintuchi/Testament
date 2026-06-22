// @vitest-environment happy-dom
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent, act } from '@testing-library/react';
import type { RefObject } from 'react';
import { DescendPanel } from './DescendPanel.js';

function makeSocket() {
  const handlers = new Map<string, (...args: unknown[]) => void>();
  const emits: Array<{ event: string; payload: unknown }> = [];
  return {
    on: vi.fn((event: string, handler: (...args: unknown[]) => void) => {
      handlers.set(event, handler);
    }),
    off: vi.fn(),
    emit: vi.fn((event: string, payload?: unknown) => {
      emits.push({ event, payload });
    }),
    handlers,
    emits,
  };
}

type FakeSocket = ReturnType<typeof makeSocket>;

function makeRef(socket: FakeSocket): RefObject<FakeSocket> {
  return { current: socket } as unknown as RefObject<FakeSocket>;
}

describe('DescendPanel (T1, R1–R4)', () => {
  it('renders descend-panel when phase === loot (R1)', () => {
    const socket = makeSocket();
    render(<DescendPanel socketRef={makeRef(socket) as never} phase="loot" />);
    expect(screen.getByTestId('descend-panel')).not.toBeNull();
  });

  it('returns null when phase === combat (R1)', () => {
    const socket = makeSocket();
    render(<DescendPanel socketRef={makeRef(socket) as never} phase="combat" />);
    expect(screen.queryByTestId('descend-panel')).toBeNull();
  });

  it('descend-btn click emits descend (R2)', () => {
    const socket = makeSocket();
    render(<DescendPanel socketRef={makeRef(socket) as never} phase="loot" />);
    fireEvent.click(screen.getByTestId('descend-btn'));
    expect(socket.emits.find(e => e.event === 'descend')).toBeDefined();
  });

  it('extract-btn click emits extract (R3)', () => {
    const socket = makeSocket();
    render(<DescendPanel socketRef={makeRef(socket) as never} phase="loot" />);
    fireEvent.click(screen.getByTestId('extract-btn'));
    expect(socket.emits.find(e => e.event === 'extract')).toBeDefined();
  });

  it('both buttons are disabled after click (R4)', () => {
    const socket = makeSocket();
    render(<DescendPanel socketRef={makeRef(socket) as never} phase="loot" />);
    fireEvent.click(screen.getByTestId('descend-btn'));
    expect((screen.getByTestId('descend-btn') as HTMLButtonElement).disabled).toBe(true);
    expect((screen.getByTestId('extract-btn') as HTMLButtonElement).disabled).toBe(true);
  });

  it('buttons re-enable on FLOOR_ADVANCED (R4)', async () => {
    const socket = makeSocket();
    render(<DescendPanel socketRef={makeRef(socket) as never} phase="loot" />);
    fireEvent.click(screen.getByTestId('descend-btn'));
    await act(async () => { socket.handlers.get('FLOOR_ADVANCED')!({}); });
    expect((screen.getByTestId('descend-btn') as HTMLButtonElement).disabled).toBe(false);
  });

  it('buttons re-enable on RUN_ENDED (R4)', async () => {
    const socket = makeSocket();
    render(<DescendPanel socketRef={makeRef(socket) as never} phase="loot" />);
    fireEvent.click(screen.getByTestId('extract-btn'));
    await act(async () => { socket.handlers.get('RUN_ENDED')!({}); });
    expect((screen.getByTestId('extract-btn') as HTMLButtonElement).disabled).toBe(false);
  });

  it('LOBBY_ERROR shows error and re-enables buttons (R4)', async () => {
    const socket = makeSocket();
    render(<DescendPanel socketRef={makeRef(socket) as never} phase="loot" />);
    fireEvent.click(screen.getByTestId('descend-btn'));
    await act(async () => {
      socket.handlers.get('LOBBY_ERROR')!({ code: 'WRONG_PHASE', message: 'Cannot descend now.' });
    });
    expect(screen.getByTestId('descend-error').textContent).toContain('Cannot descend now.');
    expect((screen.getByTestId('descend-btn') as HTMLButtonElement).disabled).toBe(false);
  });
});

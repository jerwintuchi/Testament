// @vitest-environment happy-dom
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen, act } from '@testing-library/react';
import type { RefObject } from 'react';
import { PhaseToast } from './PhaseToast.js';

function makeSocket() {
  const handlers = new Map<string, (...args: unknown[]) => void>();
  return {
    on: vi.fn((event: string, handler: (...args: unknown[]) => void) => {
      handlers.set(event, handler);
    }),
    off: vi.fn(),
    emit: vi.fn(),
    handlers,
  };
}

type FakeSocket = ReturnType<typeof makeSocket>;

function makeRef(socket: FakeSocket): RefObject<FakeSocket> {
  return { current: socket } as unknown as RefObject<FakeSocket>;
}

describe('PhaseToast (T1, R1)', () => {
  beforeEach(() => vi.useFakeTimers());
  afterEach(() => vi.useRealTimers());

  it('no toast on initial render', () => {
    const socket = makeSocket();
    render(<PhaseToast socketRef={makeRef(socket) as never} />);
    expect(screen.queryByTestId('phase-toast')).toBeNull();
  });

  it('PHASE_CHANGED combat → toast shows COMBAT (R1)', async () => {
    const socket = makeSocket();
    render(<PhaseToast socketRef={makeRef(socket) as never} />);
    await act(async () => {
      socket.handlers.get('PHASE_CHANGED')!({ phase: 'combat' });
    });
    expect(screen.getByTestId('phase-toast').textContent).toContain('COMBAT');
  });

  it('PHASE_CHANGED loot → toast shows FLOOR CLEARED (R1)', async () => {
    const socket = makeSocket();
    render(<PhaseToast socketRef={makeRef(socket) as never} />);
    await act(async () => {
      socket.handlers.get('PHASE_CHANGED')!({ phase: 'loot' });
    });
    expect(screen.getByTestId('phase-toast').textContent).toContain('FLOOR CLEARED');
  });

  it('FLOOR_ADVANCED → toast shows floor number (R1)', async () => {
    const socket = makeSocket();
    render(<PhaseToast socketRef={makeRef(socket) as never} />);
    await act(async () => {
      socket.handlers.get('FLOOR_ADVANCED')!({ floor: 3 });
    });
    const text = screen.getByTestId('phase-toast').textContent ?? '';
    expect(text).toContain('FLOOR');
    expect(text).toContain('3');
  });

  it('toast auto-dismisses after 2.5s (R1)', async () => {
    const socket = makeSocket();
    render(<PhaseToast socketRef={makeRef(socket) as never} />);
    await act(async () => {
      socket.handlers.get('PHASE_CHANGED')!({ phase: 'combat' });
    });
    expect(screen.getByTestId('phase-toast')).not.toBeNull();
    await act(async () => { vi.advanceTimersByTime(2500); });
    expect(screen.queryByTestId('phase-toast')).toBeNull();
  });

  it('new event replaces message and resets timer (R1)', async () => {
    const socket = makeSocket();
    render(<PhaseToast socketRef={makeRef(socket) as never} />);
    await act(async () => {
      socket.handlers.get('PHASE_CHANGED')!({ phase: 'combat' });
    });
    await act(async () => { vi.advanceTimersByTime(1500); });
    await act(async () => {
      socket.handlers.get('PHASE_CHANGED')!({ phase: 'loot' });
    });
    expect(screen.getByTestId('phase-toast').textContent).toContain('FLOOR CLEARED');
    // Original 2.5s from first event has passed (1500 + 1500 = 3000ms total) but new timer resets
    await act(async () => { vi.advanceTimersByTime(1500); });
    expect(screen.getByTestId('phase-toast')).not.toBeNull();
    await act(async () => { vi.advanceTimersByTime(1000); });
    expect(screen.queryByTestId('phase-toast')).toBeNull();
  });
});

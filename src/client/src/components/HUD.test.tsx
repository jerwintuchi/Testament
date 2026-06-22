// @vitest-environment happy-dom
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen, act } from '@testing-library/react';
import type { RefObject } from 'react';
import { HUD } from './HUD.js';
import { PLAYER_MAX_HP } from '@veins/shared';
import { sceneStore } from '../game/SceneStore.js';

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

beforeEach(() => {
  act(() => {
    sceneStore.emitBleedTick(1000, 1000);
    sceneStore.emitFloorChanged(1);
    sceneStore.emitPhaseChanged('loot');
  });
});

describe('HUD (T8, R8)', () => {
  it('renders without crashing', () => {
    const { container } = render(<HUD />);
    expect(container).toBeTruthy();
  });

  it('bar width reflects bleed ratio (50% → width 50%)', () => {
    const { getByTestId } = render(<HUD />);
    act(() => { sceneStore.emitBleedTick(500, 1000); });
    const fill = getByTestId('bleed-fill') as HTMLElement;
    expect(fill.style.width).toBe('50%');
  });

  it('shows floor number', () => {
    const { getByText } = render(<HUD />);
    act(() => { sceneStore.emitFloorChanged(3); });
    expect(getByText(/Floor 3/)).toBeTruthy();
  });

  it('shows COMBAT phase in red-ish text', () => {
    const { getByText } = render(<HUD />);
    act(() => { sceneStore.emitPhaseChanged('combat'); });
    const span = getByText('COMBAT');
    expect(span).toBeTruthy();
    expect(span.style.color).toContain('#e44');
  });

  it('shows LOOT phase in green-ish text', () => {
    const { getByText } = render(<HUD />);
    act(() => { sceneStore.emitPhaseChanged('loot'); });
    const span = getByText('LOOT');
    expect(span.style.color).toContain('#4a4');
  });
});

describe('HUD — player HP (T2, R2, R3)', () => {
  it('player-hp element is rendered', () => {
    render(<HUD />);
    expect(screen.getByTestId('player-hp')).not.toBeNull();
  });

  it('shows PLAYER_MAX_HP initially', () => {
    const socket = makeSocket();
    const ref = makeRef(socket);
    render(<HUD socketRef={ref as never} localPlayerId="p1" />);
    expect(screen.getByTestId('player-hp').textContent).toContain(String(PLAYER_MAX_HP));
  });

  it('PLAYER_DAMAGED for localId updates HP', async () => {
    const socket = makeSocket();
    const ref = makeRef(socket);
    render(<HUD socketRef={ref as never} localPlayerId="p1" />);
    await act(async () => {
      socket.handlers.get('PLAYER_DAMAGED')!({ playerId: 'p1', hp: 80 });
    });
    expect(screen.getByTestId('player-hp').textContent).toContain('80');
  });

  it('PLAYER_DAMAGED for other player is ignored', async () => {
    const socket = makeSocket();
    const ref = makeRef(socket);
    render(<HUD socketRef={ref as never} localPlayerId="p1" />);
    await act(async () => {
      socket.handlers.get('PLAYER_DAMAGED')!({ playerId: 'p2', hp: 5 });
    });
    expect(screen.getByTestId('player-hp').textContent).toContain(String(PLAYER_MAX_HP));
  });

  it('PLAYER_DOWNED for localId shows 0', async () => {
    const socket = makeSocket();
    const ref = makeRef(socket);
    render(<HUD socketRef={ref as never} localPlayerId="p1" />);
    await act(async () => {
      socket.handlers.get('PLAYER_DOWNED')!({ playerId: 'p1' });
    });
    expect(screen.getByTestId('player-hp').textContent).toContain('0');
  });

  it('RUN_STARTED resets HP to PLAYER_MAX_HP', async () => {
    const socket = makeSocket();
    const ref = makeRef(socket);
    render(<HUD socketRef={ref as never} localPlayerId="p1" />);
    await act(async () => {
      socket.handlers.get('PLAYER_DAMAGED')!({ playerId: 'p1', hp: 20 });
    });
    await act(async () => {
      socket.handlers.get('RUN_STARTED')!({});
    });
    expect(screen.getByTestId('player-hp').textContent).toContain(String(PLAYER_MAX_HP));
  });
});

describe('HUD — enemy count (T1, R1)', () => {
  it('enemy-count element is rendered', () => {
    render(<HUD />);
    expect(screen.getByTestId('enemy-count')).not.toBeNull();
  });

  it('ENEMY_SPAWNED increments enemy-count', async () => {
    const socket = makeSocket();
    const ref = makeRef(socket);
    render(<HUD socketRef={ref as never} localPlayerId="p1" />);
    await act(async () => { socket.handlers.get('ENEMY_SPAWNED')!({}); });
    await act(async () => { socket.handlers.get('ENEMY_SPAWNED')!({}); });
    expect(screen.getByTestId('enemy-count').textContent).toContain('2');
  });

  it('ENEMY_DIED decrements enemy-count, floors at 0', async () => {
    const socket = makeSocket();
    const ref = makeRef(socket);
    render(<HUD socketRef={ref as never} localPlayerId="p1" />);
    await act(async () => { socket.handlers.get('ENEMY_SPAWNED')!({}); });
    await act(async () => { socket.handlers.get('ENEMY_DIED')!({}); });
    expect(screen.getByTestId('enemy-count').textContent).toContain('0');
    // Extra ENEMY_DIED should not go negative.
    await act(async () => { socket.handlers.get('ENEMY_DIED')!({}); });
    expect(screen.getByTestId('enemy-count').textContent).toContain('0');
  });

  it('FLOOR_ADVANCED resets count to 0', async () => {
    const socket = makeSocket();
    const ref = makeRef(socket);
    render(<HUD socketRef={ref as never} localPlayerId="p1" />);
    await act(async () => { socket.handlers.get('ENEMY_SPAWNED')!({}); });
    await act(async () => { socket.handlers.get('FLOOR_ADVANCED')!({}); });
    expect(screen.getByTestId('enemy-count').textContent).toContain('0');
  });

  it('PHASE_CHANGED loot resets count to 0', async () => {
    const socket = makeSocket();
    const ref = makeRef(socket);
    render(<HUD socketRef={ref as never} localPlayerId="p1" />);
    await act(async () => { socket.handlers.get('ENEMY_SPAWNED')!({}); });
    await act(async () => { socket.handlers.get('PHASE_CHANGED')!({ phase: 'loot' }); });
    expect(screen.getByTestId('enemy-count').textContent).toContain('0');
  });

  it('RUN_STARTED resets count to 0', async () => {
    const socket = makeSocket();
    const ref = makeRef(socket);
    render(<HUD socketRef={ref as never} localPlayerId="p1" />);
    await act(async () => { socket.handlers.get('ENEMY_SPAWNED')!({}); });
    await act(async () => { socket.handlers.get('RUN_STARTED')!({}); });
    expect(screen.getByTestId('enemy-count').textContent).toContain('0');
  });
});

describe('HUD — teammate HP (T1, R2, R3)', () => {
  it('renders teammate-hp-{id} for each player other than local', () => {
    const socket = makeSocket();
    const ref = makeRef(socket);
    render(<HUD socketRef={ref as never} localPlayerId="p1" players={['p1', 'p2', 'p3']} />);
    expect(screen.getByTestId('teammate-hp-p2')).not.toBeNull();
    expect(screen.getByTestId('teammate-hp-p3')).not.toBeNull();
    // p1 is local — no teammate element for self
    expect(screen.queryByTestId('teammate-hp-p1')).toBeNull();
  });

  it('PLAYER_DAMAGED updates correct teammate element', async () => {
    const socket = makeSocket();
    const ref = makeRef(socket);
    render(<HUD socketRef={ref as never} localPlayerId="p1" players={['p1', 'p2']} />);
    await act(async () => { socket.handlers.get('PLAYER_DAMAGED')!({ playerId: 'p2', hp: 55 }); });
    expect(screen.getByTestId('teammate-hp-p2').textContent).toContain('55');
  });

  it('PLAYER_DOWNED sets teammate hp to 0', async () => {
    const socket = makeSocket();
    const ref = makeRef(socket);
    render(<HUD socketRef={ref as never} localPlayerId="p1" players={['p1', 'p2']} />);
    await act(async () => { socket.handlers.get('PLAYER_DOWNED')!({ playerId: 'p2' }); });
    expect(screen.getByTestId('teammate-hp-p2').textContent).toContain('0');
  });

  it('PLAYER_REVIVED restores teammate hp to PLAYER_MAX_HP', async () => {
    const socket = makeSocket();
    const ref = makeRef(socket);
    render(<HUD socketRef={ref as never} localPlayerId="p1" players={['p1', 'p2']} />);
    await act(async () => { socket.handlers.get('PLAYER_DOWNED')!({ playerId: 'p2' }); });
    await act(async () => { socket.handlers.get('PLAYER_REVIVED')!({ playerId: 'p2', hp: PLAYER_MAX_HP }); });
    expect(screen.getByTestId('teammate-hp-p2').textContent).toContain(String(PLAYER_MAX_HP));
  });

  it('PLAYER_DAMAGED for local player still updates player-hp (R2 backwards compat)', async () => {
    const socket = makeSocket();
    const ref = makeRef(socket);
    render(<HUD socketRef={ref as never} localPlayerId="p1" players={['p1', 'p2']} />);
    await act(async () => { socket.handlers.get('PLAYER_DAMAGED')!({ playerId: 'p1', hp: 40 }); });
    expect(screen.getByTestId('player-hp').textContent).toContain('40');
  });
});

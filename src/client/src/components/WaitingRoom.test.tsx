// @vitest-environment happy-dom
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, act } from '@testing-library/react';
import type { RefObject } from 'react';
import { WaitingRoom } from './WaitingRoom.js';
import type { RoomSummary } from '@veins/shared';

function makeSocket() {
  const handlers = new Map<string, (...args: unknown[]) => void>();
  const emits: Array<{ event: string; payload: unknown }> = [];
  return {
    on: vi.fn((event: string, handler: (...args: unknown[]) => void) => { handlers.set(event, handler); }),
    off: vi.fn(),
    emit: vi.fn((event: string, payload: unknown) => { emits.push({ event, payload }); }),
    handlers,
    emits,
  };
}

type FakeSocket = ReturnType<typeof makeSocket>;
function makeRef(s: FakeSocket): RefObject<FakeSocket> {
  return { current: s } as unknown as RefObject<FakeSocket>;
}

const HOST_ID = 'host-player';
const GUEST_ID = 'guest-player';

const BASE_ROOM: RoomSummary = {
  code: 'ABCD12',
  status: 'lobby',
  hostId: HOST_ID,
  players: [HOST_ID, GUEST_ID],
};

describe('WaitingRoom (T2, R2)', () => {
  beforeEach(() => {
    Object.defineProperty(navigator, 'clipboard', {
      value: { writeText: vi.fn().mockResolvedValue(undefined) },
      writable: true,
      configurable: true,
    });
  });
  it('displays the room code', () => {
    const socket = makeSocket();
    render(<WaitingRoom socketRef={makeRef(socket) as never} room={BASE_ROOM} localPlayerId={HOST_ID} />);
    expect(screen.getByTestId('room-code').textContent).toBe('ABCD12');
  });

  it('renders all players in the player list', () => {
    const socket = makeSocket();
    render(<WaitingRoom socketRef={makeRef(socket) as never} room={BASE_ROOM} localPlayerId={HOST_ID} />);
    const list = screen.getByTestId('player-list');
    expect(list.textContent).toContain('You');
    expect(list.textContent).toContain(GUEST_ID);
  });

  it('shows Start Run button when localPlayerId === hostId', () => {
    const socket = makeSocket();
    render(<WaitingRoom socketRef={makeRef(socket) as never} room={BASE_ROOM} localPlayerId={HOST_ID} />);
    expect(screen.getByTestId('start-run-btn')).toBeTruthy();
  });

  it('hides Start Run button when localPlayerId !== hostId', () => {
    const socket = makeSocket();
    render(<WaitingRoom socketRef={makeRef(socket) as never} room={BASE_ROOM} localPlayerId={GUEST_ID} />);
    expect(screen.queryByTestId('start-run-btn')).toBeNull();
  });

  it('clicking Start Run emits start-run', () => {
    const socket = makeSocket();
    render(<WaitingRoom socketRef={makeRef(socket) as never} room={BASE_ROOM} localPlayerId={HOST_ID} />);
    fireEvent.click(screen.getByTestId('start-run-btn'));
    expect(socket.emits.some(e => e.event === 'start-run')).toBe(true);
  });

  it('clicking Leave Room emits leave-room', () => {
    const socket = makeSocket();
    render(<WaitingRoom socketRef={makeRef(socket) as never} room={BASE_ROOM} localPlayerId={HOST_ID} />);
    fireEvent.click(screen.getByTestId('leave-btn'));
    expect(socket.emits.some(e => e.event === 'leave-room')).toBe(true);
  });

  it('ROOM_UPDATE event updates the player list', async () => {
    const socket = makeSocket();
    render(<WaitingRoom socketRef={makeRef(socket) as never} room={BASE_ROOM} localPlayerId={HOST_ID} />);
    const newRoom: RoomSummary = { ...BASE_ROOM, players: [HOST_ID, GUEST_ID, 'player-3'] };
    await act(async () => {
      socket.handlers.get('ROOM_UPDATE')!({ room: newRoom });
    });
    expect(screen.getByTestId('player-list').textContent).toContain('player-3');
  });

  it('copy-code-btn is rendered', () => {
    const socket = makeSocket();
    render(<WaitingRoom socketRef={makeRef(socket) as never} room={BASE_ROOM} localPlayerId={HOST_ID} />);
    expect(screen.getByTestId('copy-code-btn')).not.toBeNull();
  });

  it('copy-code-btn calls navigator.clipboard.writeText with room code', async () => {
    const socket = makeSocket();
    render(<WaitingRoom socketRef={makeRef(socket) as never} room={BASE_ROOM} localPlayerId={HOST_ID} />);
    await act(async () => { fireEvent.click(screen.getByTestId('copy-code-btn')); });
    expect(navigator.clipboard.writeText).toHaveBeenCalledWith('ABCD12');
  });

  it('copy-code-btn shows "Copied!" briefly after click', async () => {
    vi.useFakeTimers();
    const socket = makeSocket();
    render(<WaitingRoom socketRef={makeRef(socket) as never} room={BASE_ROOM} localPlayerId={HOST_ID} />);
    await act(async () => { fireEvent.click(screen.getByTestId('copy-code-btn')); });
    expect(screen.getByTestId('copy-code-btn').textContent).toBe('Copied!');
    await act(async () => { vi.advanceTimersByTime(1500); });
    expect(screen.getByTestId('copy-code-btn').textContent).toBe('Copy Code');
    vi.useRealTimers();
  });
});

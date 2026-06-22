// @vitest-environment happy-dom
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent, act } from '@testing-library/react';
import type { RefObject } from 'react';
import { LobbyScreen } from './LobbyScreen.js';

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

describe('LobbyScreen (T1, R1)', () => {
  it('renders with data-testid="lobby-screen"', () => {
    const socket = makeSocket();
    render(<LobbyScreen socketRef={makeRef(socket) as never} />);
    expect(screen.getByTestId('lobby-screen')).toBeTruthy();
  });

  it('clicking Create Room emits create-room', () => {
    const socket = makeSocket();
    render(<LobbyScreen socketRef={makeRef(socket) as never} />);
    fireEvent.click(screen.getByTestId('create-room-btn'));
    expect(socket.emits.some(e => e.event === 'create-room')).toBe(true);
  });

  it('typing a code and clicking Join Room emits join-room with the code', () => {
    const socket = makeSocket();
    render(<LobbyScreen socketRef={makeRef(socket) as never} />);
    fireEvent.change(screen.getByTestId('code-input'), { target: { value: 'abc123' } });
    fireEvent.click(screen.getByTestId('join-room-btn'));
    const ev = socket.emits.find(e => e.event === 'join-room');
    expect(ev).toBeDefined();
    expect((ev!.payload as { code: string }).code).toBe('ABC123');
  });

  it('LOBBY_ERROR event shows an error with role=alert', async () => {
    const socket = makeSocket();
    render(<LobbyScreen socketRef={makeRef(socket) as never} />);
    await act(async () => {
      socket.handlers.get('LOBBY_ERROR')!({ code: 'ROOM_NOT_FOUND', message: 'No room with that code.' });
    });
    const alert = screen.getByRole('alert');
    expect(alert.textContent).toContain('No room with that code.');
  });

  it('error clears when Create Room is clicked', async () => {
    const socket = makeSocket();
    render(<LobbyScreen socketRef={makeRef(socket) as never} />);
    await act(async () => {
      socket.handlers.get('LOBBY_ERROR')!({ code: 'ROOM_NOT_FOUND', message: 'No room.' });
    });
    expect(screen.getByTestId('lobby-error')).toBeTruthy();
    fireEvent.click(screen.getByTestId('create-room-btn'));
    expect(screen.queryByTestId('lobby-error')).toBeNull();
  });

  it('Join Room does not emit if code is empty', () => {
    const socket = makeSocket();
    render(<LobbyScreen socketRef={makeRef(socket) as never} />);
    fireEvent.click(screen.getByTestId('join-room-btn'));
    expect(socket.emits.find(e => e.event === 'join-room')).toBeUndefined();
  });
});

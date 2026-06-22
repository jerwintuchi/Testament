import { useState, useEffect } from 'react';
import type { RefObject } from 'react';
import type { Socket } from 'socket.io-client';
import type { GamePhase } from '@veins/shared';

type Props = {
  socketRef: RefObject<Socket | null>;
  phase: GamePhase;
};

export function DescendPanel({ socketRef, phase }: Props) {
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const socket = socketRef.current;
    if (!socket) return;

    function onFloorAdvanced() { setPending(false); setError(null); }
    function onRunEnded()      { setPending(false); setError(null); }
    function onLobbyError(ev: { message: string }) {
      setPending(false);
      setError(ev.message);
    }

    socket.on('FLOOR_ADVANCED', onFloorAdvanced);
    socket.on('RUN_ENDED',      onRunEnded);
    socket.on('LOBBY_ERROR',    onLobbyError);
    return () => {
      socket.off('FLOOR_ADVANCED', onFloorAdvanced);
      socket.off('RUN_ENDED',      onRunEnded);
      socket.off('LOBBY_ERROR',    onLobbyError);
    };
  }, [socketRef]);

  if (phase !== 'loot') return null;

  function handleDescend() {
    setPending(true);
    setError(null);
    socketRef.current?.emit('descend');
  }

  function handleExtract() {
    setPending(true);
    setError(null);
    socketRef.current?.emit('extract');
  }

  return (
    <div
      data-testid="descend-panel"
      style={{
        position: 'absolute',
        bottom: '16px',
        right: '16px',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'flex-end',
        gap: '8px',
        pointerEvents: 'auto',
      }}
    >
      <div style={{ display: 'flex', gap: '8px' }}>
        <button
          data-testid="extract-btn"
          disabled={pending}
          onClick={handleExtract}
          style={{
            padding: '10px 20px',
            fontSize: '14px',
            cursor: pending ? 'not-allowed' : 'pointer',
            background: '#1a3a1a',
            color: '#88ff88',
            border: '2px solid #44aa44',
            borderRadius: '6px',
            opacity: pending ? 0.6 : 1,
          }}
        >
          Extract ↑
        </button>
        <button
          data-testid="descend-btn"
          disabled={pending}
          onClick={handleDescend}
          style={{
            padding: '10px 20px',
            fontSize: '14px',
            cursor: pending ? 'not-allowed' : 'pointer',
            background: '#1a1a3a',
            color: '#8888ff',
            border: '2px solid #4444aa',
            borderRadius: '6px',
            opacity: pending ? 0.6 : 1,
          }}
        >
          Descend ↓
        </button>
      </div>
      {error && (
        <div
          data-testid="descend-error"
          style={{ color: '#ff5555', fontSize: '12px', fontFamily: 'monospace' }}
        >
          {error}
        </div>
      )}
    </div>
  );
}

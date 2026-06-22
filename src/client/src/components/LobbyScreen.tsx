import { useState, useEffect } from 'react';
import type { RefObject } from 'react';
import type { Socket } from 'socket.io-client';
import type { LobbyErrorEvent } from '@veins/shared';

type Props = {
  socketRef: RefObject<Socket | null>;
};

export function LobbyScreen({ socketRef }: Props) {
  const [code, setCode] = useState('');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const socket = socketRef.current;
    if (!socket) return;

    function onError(ev: LobbyErrorEvent) {
      setError(ev.message);
    }

    socket.on('LOBBY_ERROR', onError);
    return () => socket.off('LOBBY_ERROR', onError);
  }, [socketRef]);

  function createRoom() {
    setError(null);
    socketRef.current?.emit('create-room', undefined);
  }

  function joinRoom() {
    if (!code.trim()) return;
    socketRef.current?.emit('join-room', { code: code.trim() });
  }

  return (
    <div
      data-testid="lobby-screen"
      style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        width: '100vw',
        height: '100vh',
        background: '#0d0d0d',
        color: '#ffffff',
        gap: '16px',
      }}
    >
      <h1 style={{ fontSize: '3rem', color: '#cc2222', margin: 0 }}>Veins</h1>

      <button
        data-testid="create-room-btn"
        onClick={createRoom}
        style={btnStyle}
      >
        Create Room
      </button>

      <div style={{ display: 'flex', gap: '8px' }}>
        <input
          data-testid="code-input"
          value={code}
          onChange={e => setCode(e.target.value.toUpperCase())}
          placeholder="ROOM CODE"
          maxLength={6}
          style={{
            padding: '8px 12px',
            fontSize: '1rem',
            background: '#1a1a1a',
            color: '#fff',
            border: '1px solid #555',
            borderRadius: '4px',
            textTransform: 'uppercase',
            letterSpacing: '2px',
          }}
        />
        <button
          data-testid="join-room-btn"
          onClick={joinRoom}
          style={btnStyle}
        >
          Join Room
        </button>
      </div>

      {error && (
        <p
          data-testid="lobby-error"
          role="alert"
          style={{ color: '#ff4444', margin: 0 }}
        >
          {error}
        </p>
      )}
    </div>
  );
}

const btnStyle: React.CSSProperties = {
  padding: '10px 24px',
  fontSize: '1rem',
  cursor: 'pointer',
  background: '#333',
  color: '#fff',
  border: '1px solid #666',
  borderRadius: '4px',
};

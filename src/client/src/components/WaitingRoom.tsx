import { useState, useEffect, useCallback } from 'react';
import type { RefObject } from 'react';
import type { Socket } from 'socket.io-client';
import type { RoomSummary, RoomUpdateEvent } from '@veins/shared';

type Props = {
  socketRef: RefObject<Socket | null>;
  room: RoomSummary;
  localPlayerId: string;
};

export function WaitingRoom({ socketRef, room: initialRoom, localPlayerId }: Props) {
  const [room, setRoom] = useState<RoomSummary>(initialRoom);

  useEffect(() => {
    const socket = socketRef.current;
    if (!socket) return;

    function onRoomUpdate(ev: RoomUpdateEvent) {
      setRoom(ev.room);
    }

    socket.on('ROOM_UPDATE', onRoomUpdate);
    return () => socket.off('ROOM_UPDATE', onRoomUpdate);
  }, [socketRef]);

  const [copied, setCopied] = useState(false);

  const isHost = localPlayerId === room.hostId;

  function startRun() {
    socketRef.current?.emit('start-run', undefined);
  }

  function leaveRoom() {
    socketRef.current?.emit('leave-room', undefined);
  }

  const copyCode = useCallback(() => {
    navigator.clipboard.writeText(room.code).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    });
  }, [room.code]);

  return (
    <div
      data-testid="waiting-room"
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
      <h1 style={{ fontSize: '2rem', color: '#cc2222', margin: 0 }}>Veins</h1>

      <div style={{ textAlign: 'center' }}>
        <p style={{ color: '#888', margin: 0, fontSize: '0.85rem' }}>ROOM CODE</p>
        <p
          data-testid="room-code"
          style={{ fontSize: '2rem', fontWeight: 'bold', letterSpacing: '6px', margin: '4px 0' }}
        >
          {room.code}
        </p>
        <button
          data-testid="copy-code-btn"
          onClick={copyCode}
          style={{ ...btnStyle, fontSize: '0.8rem', padding: '6px 16px' }}
        >
          {copied ? 'Copied!' : 'Copy Code'}
        </button>
      </div>

      <ul
        data-testid="player-list"
        style={{ listStyle: 'none', padding: 0, margin: 0, textAlign: 'center' }}
      >
        {room.players.map(p => (
          <li key={p} style={{ padding: '4px 0' }}>
            {p === localPlayerId ? 'You' : p}
            {p === room.hostId ? ' ★' : ''}
          </li>
        ))}
      </ul>

      <p style={{ color: '#555', margin: 0 }}>{room.players.length}/4 players</p>

      {isHost && (
        <button
          data-testid="start-run-btn"
          onClick={startRun}
          disabled={room.players.length < 2}
          style={{ ...btnStyle, background: room.players.length < 2 ? '#222' : '#550000' }}
        >
          Start Run
        </button>
      )}

      <button data-testid="leave-btn" onClick={leaveRoom} style={btnStyle}>
        Leave Room
      </button>
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

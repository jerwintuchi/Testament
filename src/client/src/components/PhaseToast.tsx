import { useState, useEffect, useRef } from 'react';
import type { RefObject } from 'react';
import type { Socket } from 'socket.io-client';

const TOAST_DURATION_MS = 2500;
const DOCTRINE_TOAST_DURATION_MS = 5000;

type Props = {
  socketRef: RefObject<Socket | null>;
};

export function PhaseToast({ socketRef }: Props) {
  const [message, setMessage] = useState<string | null>(null);
  const [isDoctrine, setIsDoctrine] = useState(false);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  function show(msg: string, duration = TOAST_DURATION_MS, doctrine = false) {
    if (timerRef.current !== null) clearTimeout(timerRef.current);
    setMessage(msg);
    setIsDoctrine(doctrine);
    timerRef.current = setTimeout(() => {
      setMessage(null);
      setIsDoctrine(false);
      timerRef.current = null;
    }, duration);
  }

  useEffect(() => {
    const socket = socketRef.current;
    if (!socket) return;

    function onPhaseChanged(ev: { phase: string }) {
      if (ev.phase === 'combat') show('COMBAT');
      else if (ev.phase === 'loot') show('FLOOR CLEARED');
    }
    function onFloorAdvanced(ev: { floor: number }) {
      show(`FLOOR ${ev.floor}`);
    }
    function onDoctrineShift(ev: { flavor: string }) {
      show(ev.flavor, DOCTRINE_TOAST_DURATION_MS, true);
    }

    socket.on('PHASE_CHANGED',       onPhaseChanged);
    socket.on('FLOOR_ADVANCED',      onFloorAdvanced);
    socket.on('BOARD_DOCTRINE_SHIFT', onDoctrineShift);
    return () => {
      socket.off('PHASE_CHANGED',       onPhaseChanged);
      socket.off('FLOOR_ADVANCED',      onFloorAdvanced);
      socket.off('BOARD_DOCTRINE_SHIFT', onDoctrineShift);
      if (timerRef.current !== null) clearTimeout(timerRef.current);
    };
  }, [socketRef]);

  if (!message) return null;

  return (
    <div
      data-testid="phase-toast"
      style={{
        position: 'absolute',
        top: '80px',
        left: '50%',
        transform: 'translateX(-50%)',
        background: isDoctrine ? 'rgba(20,5,5,0.92)' : 'rgba(0,0,0,0.8)',
        color: isDoctrine ? '#c87070' : '#fff',
        fontFamily: 'monospace',
        fontSize: isDoctrine ? '14px' : '22px',
        fontWeight: 'bold',
        letterSpacing: '0.05em',
        padding: '10px 28px',
        borderRadius: '8px',
        border: isDoctrine ? '2px solid #7a2020' : '2px solid #555',
        pointerEvents: 'none',
        maxWidth: '420px',
        whiteSpace: isDoctrine ? 'normal' : 'nowrap',
        textAlign: 'center',
      }}
    >
      {message}
    </div>
  );
}

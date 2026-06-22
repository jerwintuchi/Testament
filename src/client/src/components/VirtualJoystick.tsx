import { useRef, useCallback } from 'react';

// Pixel radius of the outer ring. The inner knob stays within this circle.
const JOYSTICK_RADIUS = 60;

type Props = {
  onMove: (dx: number, dy: number) => void;
  onAim:  (dx: number, dy: number) => void;
};

type TouchState = {
  moveId:  number | null;
  aimId:   number | null;
  moveOrigin: { x: number; y: number } | null;
  aimOrigin:  { x: number; y: number } | null;
  // Separate boolean so the "is rAF scheduled?" check isn't confused by the
  // synchronous-stub timing problem (stub fires callback before handle is assigned).
  rafMovePending: boolean;
  rafAimPending:  boolean;
  pendingMove: { dx: number; dy: number } | null;
  pendingAim:  { dx: number; dy: number } | null;
};

// Split-screen virtual joystick layout.
//   Left half of screen → movement joystick (bottom-left quadrant, touch-only).
//   Right half of screen → aim joystick (bottom-right quadrant, touch-only).
// Both use rAF throttling to avoid flooding the socket per frame.
export function VirtualJoystick({ onMove, onAim }: Props) {
  const state = useRef<TouchState>({
    moveId: null, aimId: null,
    moveOrigin: null, aimOrigin: null,
    rafMovePending: false, rafAimPending: false,
    pendingMove: null, pendingAim: null,
  });

  const flushMove = useCallback(() => {
    const s = state.current;
    s.rafMovePending = false;
    if (s.pendingMove) {
      onMove(s.pendingMove.dx, s.pendingMove.dy);
      s.pendingMove = null;
    }
  }, [onMove]);

  const flushAim = useCallback(() => {
    const s = state.current;
    s.rafAimPending = false;
    if (s.pendingAim) {
      onAim(s.pendingAim.dx, s.pendingAim.dy);
      s.pendingAim = null;
    }
  }, [onAim]);

  const scheduleMove = useCallback((dx: number, dy: number) => {
    const s = state.current;
    s.pendingMove = { dx, dy };
    if (!s.rafMovePending) {
      s.rafMovePending = true;
      requestAnimationFrame(flushMove);
    }
  }, [flushMove]);

  const scheduleAim = useCallback((dx: number, dy: number) => {
    const s = state.current;
    s.pendingAim = { dx, dy };
    if (!s.rafAimPending) {
      s.rafAimPending = true;
      requestAnimationFrame(flushAim);
    }
  }, [flushAim]);

  const onTouchStart = useCallback((e: React.TouchEvent) => {
    for (let i = 0; i < e.changedTouches.length; i++) {
      const t = e.changedTouches[i]!;
      const isLeft = t.clientX < window.innerWidth / 2;
      const s = state.current;
      if (isLeft && s.moveId === null) {
        s.moveId = t.identifier;
        s.moveOrigin = { x: t.clientX, y: t.clientY };
      } else if (!isLeft && s.aimId === null) {
        s.aimId = t.identifier;
        s.aimOrigin = { x: t.clientX, y: t.clientY };
      }
    }
  }, []);

  const onTouchMove = useCallback((e: React.TouchEvent) => {
    for (let i = 0; i < e.changedTouches.length; i++) {
      const t = e.changedTouches[i]!;
      const s = state.current;
      if (t.identifier === s.moveId && s.moveOrigin) {
        const rawDx = t.clientX - s.moveOrigin.x;
        const rawDy = t.clientY - s.moveOrigin.y;
        const mag = Math.sqrt(rawDx * rawDx + rawDy * rawDy);
        const clamped = Math.min(mag, JOYSTICK_RADIUS);
        const dx = mag === 0 ? 0 : (rawDx / mag) * clamped;
        const dy = mag === 0 ? 0 : (rawDy / mag) * clamped;
        scheduleMove(dx / JOYSTICK_RADIUS, dy / JOYSTICK_RADIUS);
      } else if (t.identifier === s.aimId && s.aimOrigin) {
        const rawDx = t.clientX - s.aimOrigin.x;
        const rawDy = t.clientY - s.aimOrigin.y;
        const mag = Math.sqrt(rawDx * rawDx + rawDy * rawDy);
        const clamped = Math.min(mag, JOYSTICK_RADIUS);
        const dx = mag === 0 ? 0 : (rawDx / mag) * clamped;
        const dy = mag === 0 ? 0 : (rawDy / mag) * clamped;
        scheduleAim(dx / JOYSTICK_RADIUS, dy / JOYSTICK_RADIUS);
      }
    }
  }, [scheduleMove, scheduleAim]);

  const onTouchEnd = useCallback((e: React.TouchEvent) => {
    for (let i = 0; i < e.changedTouches.length; i++) {
      const t = e.changedTouches[i]!;
      const s = state.current;
      if (t.identifier === s.moveId) {
        s.moveId = null; s.moveOrigin = null;
        scheduleMove(0, 0);
      } else if (t.identifier === s.aimId) {
        s.aimId = null; s.aimOrigin = null;
        scheduleAim(0, 0);
      }
    }
  }, [scheduleMove, scheduleAim]);

  return (
    <div
      data-testid="virtual-joystick"
      style={{ position: 'fixed', inset: 0, touchAction: 'none' }}
      onTouchStart={onTouchStart}
      onTouchMove={onTouchMove}
      onTouchEnd={onTouchEnd}
      onTouchCancel={onTouchEnd}
    />
  );
}

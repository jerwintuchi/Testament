import { useState, useEffect } from 'react';
import type { RefObject } from 'react';
import type { Socket } from 'socket.io-client';
import type { GamePhase } from '@veins/shared';
import { PLAYER_MAX_HP } from '@veins/shared';
import { sceneStore } from '../game/SceneStore.js';

function bleedColor(ratio: number): string {
  const r = Math.round(0x22 + (0xcc - 0x22) * (1 - ratio));
  const g = Math.round(0x88 - (0x88 - 0x22) * (1 - ratio));
  const b = 0x22;
  return `rgb(${r},${g},${b})`;
}

type Props = {
  socketRef?: RefObject<Socket | null>;
  localPlayerId?: string;
  players?: string[];
};

export function HUD({ socketRef, localPlayerId, players = [] }: Props = {}) {
  const [bleed, setBleed] = useState({ current: 0, max: 1 });
  const [floor, setFloor] = useState(1);
  const [phase, setPhase] = useState<GamePhase>('loot');
  const [enemyCount, setEnemyCount] = useState(0);
  // Map of playerId → current hp
  const [hpMap, setHpMap] = useState<Map<string, number>>(new Map());

  useEffect(() => {
    const offBleed = sceneStore.onBleedTick(p => setBleed({ current: p.current, max: p.max }));
    const offFloor = sceneStore.onFloorChanged(p => setFloor(p.floor));
    const offPhase = sceneStore.onPhaseChanged(p => setPhase(p.phase));
    return () => { offBleed(); offFloor(); offPhase(); };
  }, []);

  useEffect(() => {
    const socket = socketRef?.current;
    if (!socket) return;

    function onRunStarted() {
      setEnemyCount(0);
      setHpMap(new Map(players.map(id => [id, PLAYER_MAX_HP])));
    }
    function onEnemySpawned() {
      setEnemyCount(n => n + 1);
    }
    function onEnemyDied() {
      setEnemyCount(n => Math.max(0, n - 1));
    }
    function onFloorAdvanced() {
      setEnemyCount(0);
    }
    function onPhaseChanged(ev: { phase: GamePhase }) {
      if (ev.phase === 'loot') setEnemyCount(0);
    }
    function onPlayerDamaged(ev: { playerId: string; hp: number }) {
      setHpMap(prev => {
        const next = new Map(prev);
        next.set(ev.playerId, ev.hp);
        return next;
      });
    }
    function onPlayerDowned(ev: { playerId: string }) {
      setHpMap(prev => {
        const next = new Map(prev);
        next.set(ev.playerId, 0);
        return next;
      });
    }
    function onPlayerRevived(ev: { playerId: string }) {
      setHpMap(prev => {
        const next = new Map(prev);
        next.set(ev.playerId, PLAYER_MAX_HP);
        return next;
      });
    }

    socket.on('RUN_STARTED',    onRunStarted);
    socket.on('ENEMY_SPAWNED',  onEnemySpawned);
    socket.on('ENEMY_DIED',     onEnemyDied);
    socket.on('FLOOR_ADVANCED', onFloorAdvanced);
    socket.on('PHASE_CHANGED',  onPhaseChanged);
    socket.on('PLAYER_DAMAGED', onPlayerDamaged);
    socket.on('PLAYER_DOWNED',  onPlayerDowned);
    socket.on('PLAYER_REVIVED', onPlayerRevived);
    return () => {
      socket.off('RUN_STARTED',    onRunStarted);
      socket.off('ENEMY_SPAWNED',  onEnemySpawned);
      socket.off('ENEMY_DIED',     onEnemyDied);
      socket.off('FLOOR_ADVANCED', onFloorAdvanced);
      socket.off('PHASE_CHANGED',  onPhaseChanged);
      socket.off('PLAYER_DAMAGED', onPlayerDamaged);
      socket.off('PLAYER_DOWNED',  onPlayerDowned);
      socket.off('PLAYER_REVIVED', onPlayerRevived);
    };
  }, [socketRef, players]);

  const ratio = bleed.max > 0 ? Math.max(0, bleed.current / bleed.max) : 0;
  const localHp = localPlayerId ? (hpMap.get(localPlayerId) ?? PLAYER_MAX_HP) : PLAYER_MAX_HP;

  return (
    <div style={{
      position: 'absolute', top: 0, left: 0, right: 0,
      pointerEvents: 'none', padding: '8px 12px',
      display: 'flex', flexDirection: 'column', gap: '4px',
    }}>
      {/* Bleed Clock bar */}
      <div style={{
        background: '#333', borderRadius: '4px', height: '12px',
        width: '240px', overflow: 'hidden',
      }}>
        <div data-testid="bleed-fill" style={{
          height: '100%', width: `${ratio * 100}%`,
          background: bleedColor(ratio),
          transition: 'width 0.2s linear, background 0.4s linear',
        }} />
      </div>

      {/* Floor + Phase */}
      <div style={{ color: '#ccc', fontSize: '12px', fontFamily: 'monospace' }}>
        Floor {floor} — <span style={{ color: phase === 'combat' ? '#e44' : '#4a4' }}>
          {phase.toUpperCase()}
        </span>
      </div>

      {/* Local player HP (backwards-compatible testid) */}
      <div data-testid="player-hp" style={{ color: '#fff', fontSize: '12px', fontFamily: 'monospace' }}>
        HP {localHp} / {PLAYER_MAX_HP}
      </div>

      {/* Teammate HP rows */}
      {players.filter(id => id !== localPlayerId).map(id => (
        <div
          key={id}
          data-testid={`teammate-hp-${id}`}
          style={{ color: '#aaa', fontSize: '11px', fontFamily: 'monospace' }}
        >
          {id.slice(0, 6)} HP {hpMap.get(id) ?? PLAYER_MAX_HP} / {PLAYER_MAX_HP}
        </div>
      ))}

      {/* Enemy count */}
      <div data-testid="enemy-count" style={{ color: '#f88', fontSize: '12px', fontFamily: 'monospace' }}>
        {enemyCount} {enemyCount === 1 ? 'enemy' : 'enemies'}
      </div>
    </div>
  );
}

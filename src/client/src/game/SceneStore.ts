import type { GamePhase } from '@veins/shared';
import type Phaser from 'phaser';
import type { PlayerId } from '@veins/shared';

type Listener = (...args: unknown[]) => void;

// Minimal typed event bus used by GameScene to push render state to React
// (HUD, App.tsx). Avoids pulling in an EventEmitter library — this bus only
// needs the handful of events below.
class TypedEmitter {
  private listeners = new Map<string, Set<Listener>>();

  on(event: string, fn: Listener): void {
    if (!this.listeners.has(event)) this.listeners.set(event, new Set());
    this.listeners.get(event)!.add(fn);
  }

  off(event: string, fn: Listener): void {
    this.listeners.get(event)?.delete(fn);
  }

  emit(event: string, ...args: unknown[]): void {
    for (const fn of this.listeners.get(event) ?? []) fn(...args);
  }
}

export type BleedTickPayload  = { current: number; max: number };
export type PhasePayload      = { phase: GamePhase };
export type FloorPayload      = { floor: number };
export type PlayerMovedPayload = { playerId: PlayerId; x: number; y: number };

export class SceneStore extends TypedEmitter {
  // Set by GameScene once the camera is ready; read by App.tsx for world-coord aim.
  camera: Phaser.Cameras.Scene2D.Camera | null = null;
  // Local player's last-known world position; read by App.tsx for aim-player events.
  localPlayerPos: { x: number; y: number } | null = null;

  emitBleedTick(current: number, max: number): void {
    this.emit('bleed-tick', { current, max } satisfies BleedTickPayload);
  }

  emitPhaseChanged(phase: GamePhase): void {
    this.emit('phase-changed', { phase } satisfies PhasePayload);
  }

  emitFloorChanged(floor: number): void {
    this.emit('floor-changed', { floor } satisfies FloorPayload);
  }

  onBleedTick(fn: (p: BleedTickPayload) => void): () => void {
    const wrapped = (p: unknown) => fn(p as BleedTickPayload);
    this.on('bleed-tick', wrapped);
    return () => this.off('bleed-tick', wrapped);
  }

  onPhaseChanged(fn: (p: PhasePayload) => void): () => void {
    const wrapped = (p: unknown) => fn(p as PhasePayload);
    this.on('phase-changed', wrapped);
    return () => this.off('phase-changed', wrapped);
  }

  onFloorChanged(fn: (p: FloorPayload) => void): () => void {
    const wrapped = (p: unknown) => fn(p as FloorPayload);
    this.on('floor-changed', wrapped);
    return () => this.off('floor-changed', wrapped);
  }
}

// Singleton — import this wherever game/React integration is needed.
export const sceneStore = new SceneStore();

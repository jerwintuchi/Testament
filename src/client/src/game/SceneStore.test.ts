// @vitest-environment node
import { describe, it, expect, vi } from 'vitest';
import { SceneStore } from './SceneStore.js';

describe('SceneStore (T1, R1)', () => {
  it('starts with camera and localPlayerPos as null', () => {
    const store = new SceneStore();
    expect(store.camera).toBeNull();
    expect(store.localPlayerPos).toBeNull();
  });

  it('emitBleedTick notifies subscribers with current and max', () => {
    const store = new SceneStore();
    const fn = vi.fn();
    store.onBleedTick(fn);
    store.emitBleedTick(500, 1000);
    expect(fn).toHaveBeenCalledWith({ current: 500, max: 1000 });
  });

  it('emitPhaseChanged notifies subscribers with the phase', () => {
    const store = new SceneStore();
    const fn = vi.fn();
    store.onPhaseChanged(fn);
    store.emitPhaseChanged('combat');
    expect(fn).toHaveBeenCalledWith({ phase: 'combat' });
  });

  it('emitFloorChanged notifies subscribers with the floor number', () => {
    const store = new SceneStore();
    const fn = vi.fn();
    store.onFloorChanged(fn);
    store.emitFloorChanged(3);
    expect(fn).toHaveBeenCalledWith({ floor: 3 });
  });

  it('unsubscribe via returned cleanup stops receiving events', () => {
    const store = new SceneStore();
    const fn = vi.fn();
    const off = store.onBleedTick(fn);
    off();
    store.emitBleedTick(100, 1000);
    expect(fn).not.toHaveBeenCalled();
  });

  it('multiple subscribers all receive the event', () => {
    const store = new SceneStore();
    const a = vi.fn(), b = vi.fn();
    store.onBleedTick(a);
    store.onBleedTick(b);
    store.emitBleedTick(1, 100);
    expect(a).toHaveBeenCalledTimes(1);
    expect(b).toHaveBeenCalledTimes(1);
  });
});

// @vitest-environment happy-dom
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, fireEvent } from '@testing-library/react';
import { VirtualJoystick } from './VirtualJoystick.js';

// rAF is not implemented in jsdom — stub it so scheduleMove/Aim fires immediately.
beforeEach(() => {
  vi.stubGlobal('requestAnimationFrame', (cb: FrameRequestCallback) => {
    cb(0);
    return 0;
  });
  vi.stubGlobal('cancelAnimationFrame', () => {});
});

function makeTouch(id: number, x: number, y: number): Touch {
  return { identifier: id, clientX: x, clientY: y } as Touch;
}

function touchStart(el: Element, ...touches: Touch[]) {
  fireEvent(el, new TouchEvent('touchstart', {
    changedTouches: touches, bubbles: true, cancelable: true,
  }));
}
function touchMove(el: Element, ...touches: Touch[]) {
  fireEvent(el, new TouchEvent('touchmove', {
    changedTouches: touches, bubbles: true, cancelable: true,
  }));
}
function touchEnd(el: Element, ...touches: Touch[]) {
  fireEvent(el, new TouchEvent('touchend', {
    changedTouches: touches, bubbles: true, cancelable: true,
  }));
}

describe('VirtualJoystick (T9, R3)', () => {
  beforeEach(() => {
    // Viewport: 800×600.
    Object.defineProperty(window, 'innerWidth', { value: 800, configurable: true });
    Object.defineProperty(window, 'innerHeight', { value: 600, configurable: true });
  });

  it('renders without crashing', () => {
    const { getByTestId } = render(
      <VirtualJoystick onMove={() => {}} onAim={() => {}} />
    );
    expect(getByTestId('virtual-joystick')).toBeTruthy();
  });

  it('calls onMove with a normalised vector when the left-side touch moves', () => {
    const onMove = vi.fn();
    const { getByTestId } = render(
      <VirtualJoystick onMove={onMove} onAim={() => {}} />
    );
    const el = getByTestId('virtual-joystick');
    touchStart(el, makeTouch(1, 100, 400)); // left side
    touchMove(el,  makeTouch(1, 160, 400)); // 60px right = full magnitude at JOYSTICK_RADIUS
    expect(onMove).toHaveBeenCalledWith(expect.closeTo(1, 1), expect.closeTo(0, 1));
  });

  it('calls onAim with a normalised vector when the right-side touch moves', () => {
    const onAim = vi.fn();
    const { getByTestId } = render(
      <VirtualJoystick onMove={() => {}} onAim={onAim} />
    );
    const el = getByTestId('virtual-joystick');
    touchStart(el, makeTouch(2, 600, 400)); // right side
    touchMove(el,  makeTouch(2, 600, 460)); // 60px down
    expect(onAim).toHaveBeenCalledWith(expect.closeTo(0, 1), expect.closeTo(1, 1));
  });

  it('calls onMove with (0,0) when the left-side touch ends', () => {
    const onMove = vi.fn();
    const { getByTestId } = render(
      <VirtualJoystick onMove={onMove} onAim={() => {}} />
    );
    const el = getByTestId('virtual-joystick');
    touchStart(el, makeTouch(1, 100, 400));
    touchMove(el,  makeTouch(1, 160, 400));
    onMove.mockClear();
    touchEnd(el, makeTouch(1, 160, 400));
    expect(onMove).toHaveBeenCalledWith(0, 0);
  });

  it('does not trigger onMove for right-side touches', () => {
    const onMove = vi.fn();
    const { getByTestId } = render(
      <VirtualJoystick onMove={onMove} onAim={() => {}} />
    );
    const el = getByTestId('virtual-joystick');
    touchStart(el, makeTouch(3, 600, 400)); // right side only
    touchMove(el,  makeTouch(3, 660, 400));
    expect(onMove).not.toHaveBeenCalled();
  });
});

// @vitest-environment happy-dom
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { PostRunScreen } from './PostRunScreen.js';

describe('PostRunScreen (T1, R2, R3)', () => {
  it('shows WIPED for wiped outcome', () => {
    render(<PostRunScreen outcome="wiped" finalFloor={3} enemiesKilled={0} onReturnToLobby={() => {}} />);
    expect(screen.getByTestId('run-outcome').textContent).toContain('WIPED');
  });

  it('shows EXTRACTED for extracted outcome', () => {
    render(<PostRunScreen outcome="extracted" finalFloor={5} enemiesKilled={12} onReturnToLobby={() => {}} />);
    expect(screen.getByTestId('run-outcome').textContent).toContain('EXTRACTED');
  });

  it('shows final floor number', () => {
    render(<PostRunScreen outcome="wiped" finalFloor={7} enemiesKilled={3} onReturnToLobby={() => {}} />);
    expect(screen.getByTestId('run-floor').textContent).toContain('7');
  });

  it('shows enemiesKilled count', () => {
    render(<PostRunScreen outcome="extracted" finalFloor={4} enemiesKilled={17} onReturnToLobby={() => {}} />);
    expect(screen.getByTestId('run-enemies-killed').textContent).toContain('17');
  });

  it('uses singular "enemy" when count is 1', () => {
    render(<PostRunScreen outcome="extracted" finalFloor={1} enemiesKilled={1} onReturnToLobby={() => {}} />);
    expect(screen.getByTestId('run-enemies-killed').textContent).toContain('enemy');
    expect(screen.getByTestId('run-enemies-killed').textContent).not.toContain('enemies');
  });

  it('calls onReturnToLobby when button clicked', () => {
    const fn = vi.fn();
    render(<PostRunScreen outcome="extracted" finalFloor={2} enemiesKilled={0} onReturnToLobby={fn} />);
    fireEvent.click(screen.getByTestId('return-to-lobby-btn'));
    expect(fn).toHaveBeenCalledOnce();
  });
});

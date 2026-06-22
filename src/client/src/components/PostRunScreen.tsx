type Props = {
  outcome: 'wiped' | 'extracted';
  finalFloor: number;
  enemiesKilled: number;
  onReturnToLobby: () => void;
};

export function PostRunScreen({ outcome, finalFloor, enemiesKilled, onReturnToLobby }: Props) {
  const outcomeText = outcome === 'wiped' ? 'WIPED' : 'EXTRACTED';
  const outcomeColor = outcome === 'wiped' ? '#cc4444' : '#44cc88';
  return (
    <div
      data-testid="post-run-screen"
      style={{
        position: 'absolute', inset: 0,
        display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
        background: '#0d0d0d', color: '#ffffff', fontFamily: 'monospace', gap: '16px',
      }}
    >
      <div data-testid="run-outcome" style={{ fontSize: '48px', fontWeight: 'bold', color: outcomeColor }}>
        {outcomeText}
      </div>
      <div data-testid="run-floor" style={{ fontSize: '20px', color: '#aaaaaa' }}>
        Floor {finalFloor}
      </div>
      <div data-testid="run-enemies-killed" style={{ fontSize: '16px', color: '#888888' }}>
        {enemiesKilled} {enemiesKilled === 1 ? 'enemy' : 'enemies'} slain
      </div>
      <button
        data-testid="return-to-lobby-btn"
        onClick={onReturnToLobby}
        style={{
          marginTop: '24px', padding: '10px 24px', fontSize: '16px',
          background: '#222', color: '#fff', border: '2px solid #555', borderRadius: '6px', cursor: 'pointer',
        }}
      >
        Return to Lobby
      </button>
    </div>
  );
}

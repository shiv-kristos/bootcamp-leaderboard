import Avatar from './Avatar';
const borderColors = ['var(--gold)', 'var(--silver)', 'var(--bronze)'];
const barHeights = [52, 32, 20];

export default function LeaderboardHero({ topThree = [], batchName, batchDay }) {
  if (topThree.length === 0) return null;
  const podiumOrder = [topThree[1], topThree[0], topThree[2]].filter(Boolean);
  const podiumRanks = topThree.length >= 2 ? [2, 1, 3] : [1];

  function shortName(fullName) {
    if (!fullName) return '';
    const parts = fullName.trim().split(' ');
    if (parts.length === 1) return parts[0];
    return parts[0] + ' ' + parts[parts.length - 1];
  }

  return (
    <div style={{ background: 'linear-gradient(160deg, #1B2A5E 0%, #0F1A3D 100%)', padding: '32px 28px 0', position: 'relative', overflow: 'hidden' }}>
      <div style={{ position: 'absolute', top: -80, right: -80, width: 280, height: 280, background: 'rgba(194,24,91,0.1)', borderRadius: '50%', pointerEvents: 'none' }} />
      <div style={{ position: 'absolute', bottom: -60, left: '20%', width: 200, height: 200, background: 'rgba(0,137,123,0.07)', borderRadius: '50%', pointerEvents: 'none' }} />
      <div style={{ textAlign: 'center', marginBottom: 28, position: 'relative', zIndex: 1 }}>
        {batchName && <p style={{ fontSize: 11, color: 'rgba(255,255,255,0.45)', letterSpacing: '0.1em', textTransform: 'uppercase', marginBottom: 4 }}>{batchName}</p>}
        <h1 style={{ fontFamily: 'var(--font-display)', fontSize: 26, color: '#fff', fontWeight: 700 }}>Leaderboard</h1>
      </div>
      <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'center', gap: 20, position: 'relative', zIndex: 1 }}>
        {podiumOrder.map((trainee, i) => {
          if (!trainee) return null;
          const rank = podiumRanks[i];
          const isFirst = rank === 1;
          const avatarSize = isFirst ? 88 : 70;
          const borderColor = borderColors[rank - 1];
          return (
            <div key={trainee.trainee_id} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
              <div style={{ position: 'relative' }}>
                {isFirst && <div style={{ position: 'absolute', top: -20, left: '50%', transform: 'translateX(-50%)', fontSize: 22, zIndex: 2 }}>👑</div>}
                <div style={{ border: `3px solid ${borderColor}`, borderRadius: '50%', padding: 2 }}>
                  <Avatar name={trainee.trainee_name} photoUrl={trainee.photo_url} size={avatarSize} />
                </div>
                <div style={{ position: 'absolute', bottom: -10, left: '50%', transform: 'translateX(-50%)', width: isFirst ? 28 : 24, height: isFirst ? 28 : 24, borderRadius: '50%', background: borderColor, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: isFirst ? 13 : 11, fontWeight: 700, color: '#fff', border: '2px solid rgba(255,255,255,0.3)', zIndex: 2 }}>{rank}</div>
              </div>
              <div style={{ marginTop: 18, textAlign: 'center' }}>
                <p style={{ fontSize: isFirst ? 14 : 12, fontWeight: 600, color: '#fff', fontFamily: 'var(--font-display)', maxWidth: isFirst ? 140 : 110, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                  {shortName(trainee.trainee_name)}
                </p>
                <p style={{ fontSize: isFirst ? 20 : 16, fontWeight: 700, color: borderColor, marginTop: 2 }}>{Number(trainee.overall_score).toLocaleString()}</p>
                <p style={{ fontSize: 10, color: 'rgba(255,255,255,0.35)', marginTop: 1 }}>points</p>
              </div>
              <div style={{ marginTop: 12, width: isFirst ? 110 : 88, height: barHeights[rank - 1], background: rank === 1 ? 'rgba(245,166,35,0.2)' : rank === 2 ? 'rgba(140,150,168,0.15)' : 'rgba(160,113,79,0.15)', borderRadius: '6px 6px 0 0' }} />
            </div>
          );
        })}
      </div>
    </div>
  );
}

#!/bin/bash
set -e
cd /workspaces/bootcamp-leaderboard/bootcamp-app

cat > src/pages/LeaderboardPage.js << 'EOF'
import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import LeaderboardHero from '../components/LeaderboardHero';
import ProfileDrawer from '../components/ProfileDrawer';
import Avatar from '../components/Avatar';

export default function LeaderboardPage({ batch }) {
  const [overallScores, setOverallScores] = useState([]);
  const [categories, setCategories] = useState([]);
  const [categoryScores, setCategoryScores] = useState([]);
  const [activeTab, setActiveTab] = useState('overall');
  const [selectedTrainee, setSelectedTrainee] = useState(null);
  const [loading, setLoading] = useState(true);
  const [trainees, setTrainees] = useState([]);

  useEffect(() => { if (batch) loadData(); }, [batch]);

  async function loadData() {
    setLoading(true);
    const [overallRes, catRes, catScoresRes, traineesRes] = await Promise.all([
      supabase.from('trainee_overall_scores').select('*').eq('batch_id', batch.id).order('overall_score', { ascending: false }),
      supabase.from('categories').select('*').eq('batch_id', batch.id).order('sort_order'),
      supabase.from('trainee_category_scores').select('*').eq('batch_id', batch.id),
      supabase.from('trainees').select('*').eq('batch_id', batch.id).eq('is_active', true),
    ]);
    if (overallRes.data) setOverallScores(overallRes.data);
    if (catRes.data) setCategories(catRes.data);
    if (catScoresRes.data) setCategoryScores(catScoresRes.data);
    if (traineesRes.data) setTrainees(traineesRes.data);
    setLoading(false);
  }

  function getDisplayList() {
    if (activeTab === 'overall') return overallScores;
    if (activeTab === 'ab') return [];
    const cat = categories.find(c => c.id === activeTab);
    if (!cat) return [];
    if (cat.type === 'display') return trainees.map(t => ({ trainee_id: t.id, trainee_name: t.name, photo_url: t.photo_url, overall_score: '—' }));
    return categoryScores.filter(cs => cs.category_id === activeTab)
      .sort((a, b) => Number(b.category_score) - Number(a.category_score))
      .map(cs => ({ trainee_id: cs.trainee_id, trainee_name: cs.trainee_name, photo_url: null, overall_score: cs.category_score }));
  }

  const displayList = getDisplayList();
  const topScore = displayList.length > 0 ? Math.max(...displayList.map(r => Number(r.overall_score) || 0)) : 1;
  const topThree = overallScores.slice(0, 3).map(s => ({
    ...s, photo_url: trainees.find(t => t.id === s.trainee_id)?.photo_url || null
  }));

  if (loading) return <div className="page-loading"><div className="spinner spinner-lg" /><p>Loading leaderboard...</p></div>;
  if (!batch) return <div className="empty-state" style={{ marginTop: 80 }}><h3>No batch selected</h3><p>Create a batch in the admin panel to get started.</p></div>;

  return (
    <div>
      <LeaderboardHero topThree={topThree} batchName={batch.name} />

      {/* Category tabs */}
      <div style={{ background: '#fff', borderBottom: '1px solid var(--border)', padding: '0 28px', overflowX: 'auto' }}>
        <div className="tabs" style={{ borderBottom: 'none', flexWrap: 'nowrap' }}>
          <button className={`tab-btn ${activeTab === 'overall' ? 'active' : ''}`} onClick={() => setActiveTab('overall')}>Overall</button>
          {categories.map(cat => (
            <button key={cat.id} className={`tab-btn ${activeTab === cat.id ? 'active' : ''}`} onClick={() => setActiveTab(cat.id)}>{cat.name}</button>
          ))}
          <button className={`tab-btn ${activeTab === 'ab' ? 'active' : ''}`} onClick={() => setActiveTab('ab')}>Above & Beyond</button>
        </div>
      </div>

      {/* Ranked list */}
      <div style={{ padding: '20px 28px' }}>
        {activeTab === 'ab' ? (
          <div className="empty-state">
            <h3>Above & Beyond</h3>
            <p>Click any trainee on the Overall tab to see their A&B entries in their profile.</p>
          </div>
        ) : displayList.length === 0 ? (
          <div className="empty-state"><h3>No scores yet</h3><p>Scores will appear here once entered in the admin panel.</p></div>
        ) : (
          <div style={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 'var(--radius-lg)', overflow: 'hidden', boxShadow: 'var(--shadow-sm)' }}>
            {/* Header */}
            <div style={{ display: 'flex', alignItems: 'center', padding: '10px 20px', background: 'var(--bg)', borderBottom: '1px solid var(--border)', gap: 12 }}>
              <span style={{ width: 32, fontSize: 11, color: 'var(--text-muted)', fontWeight: 600 }}>#</span>
              <span style={{ width: 220, fontSize: 11, color: 'var(--text-muted)', fontWeight: 600 }}>Trainee</span>
              <span style={{ flex: 1, fontSize: 11, color: 'var(--text-muted)', fontWeight: 600 }}>Score vs top</span>
              <span style={{ width: 80, fontSize: 11, color: 'var(--text-muted)', fontWeight: 600, textAlign: 'right' }}>
                {activeTab === 'overall' ? 'Total' : 'Score'}
              </span>
            </div>

            {displayList.map((row, i) => {
              const traineeData = trainees.find(t => t.id === row.trainee_id);
              const score = Number(row.overall_score) || 0;
              const pct = topScore > 0 ? Math.round((score / topScore) * 100) : 0;
              return (
                <div
                  key={row.trainee_id}
                  onClick={() => setSelectedTrainee(traineeData || { id: row.trainee_id, name: row.trainee_name })}
                  style={{ display: 'flex', alignItems: 'center', padding: '14px 20px', borderBottom: i < displayList.length - 1 ? '1px solid var(--border-light)' : 'none', cursor: 'pointer', gap: 12 }}
                  onMouseEnter={e => e.currentTarget.style.background = '#F7F9FF'}
                  onMouseLeave={e => e.currentTarget.style.background = 'transparent'}
                >
                  {/* Rank */}
                  <span style={{ width: 32, fontSize: 16, fontWeight: 700, flexShrink: 0, color: i === 0 ? 'var(--gold)' : i === 1 ? 'var(--silver)' : i === 2 ? 'var(--bronze)' : 'var(--text-muted)' }}>
                    {i + 1}
                  </span>

                  {/* Trainee */}
                  <div style={{ width: 220, display: 'flex', alignItems: 'center', gap: 10, flexShrink: 0 }}>
                    <Avatar name={row.trainee_name} photoUrl={traineeData?.photo_url} size={38} />
                    <div>
                      <p style={{ fontSize: 13, fontWeight: 600, color: 'var(--navy)' }}>{row.trainee_name}</p>
                      {traineeData?.department && <p style={{ fontSize: 11, color: 'var(--text-muted)' }}>{traineeData.department}</p>}
                    </div>
                  </div>

                  {/* Score bar */}
                  <div style={{ flex: 1 }}>
                    <div style={{ height: 6, background: 'var(--border-light)', borderRadius: 3, marginBottom: 4 }}>
                      <div style={{ height: '100%', width: `${pct}%`, background: i === 0 ? 'var(--gold)' : i === 1 ? 'var(--silver)' : i === 2 ? 'var(--bronze)' : 'var(--navy)', borderRadius: 3, transition: 'width 0.4s ease' }} />
                    </div>
                    <p style={{ fontSize: 11, color: 'var(--text-muted)' }}>{pct}% of top score</p>
                  </div>

                  {/* Score */}
                  <div style={{ width: 80, textAlign: 'right', flexShrink: 0 }}>
                    <p style={{ fontSize: 18, fontWeight: 700, color: 'var(--navy)' }}>
                      {row.overall_score === '—' ? '—' : Number(row.overall_score).toLocaleString()}
                    </p>
                    <p style={{ fontSize: 11, color: 'var(--text-muted)' }}>pts</p>
                  </div>
                </div>
              );
            })}
          </div>
        )}
        <p style={{ textAlign: 'center', fontSize: 12, color: 'var(--text-muted)', marginTop: 12 }}>
          Click any row to view full profile
        </p>
      </div>

      {selectedTrainee && (
        <ProfileDrawer trainee={selectedTrainee} batchId={batch.id} onClose={() => setSelectedTrainee(null)} />
      )}
    </div>
  );
}
EOF

# Fix LeaderboardHero - fix duplicate name issue
cat > src/components/LeaderboardHero.js << 'EOF'
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
EOF

cd /workspaces/bootcamp-leaderboard && git add . && git commit -m "Fix layout: score bar, duplicate name, remove extra AB tab" && git push
echo "ALL DONE"

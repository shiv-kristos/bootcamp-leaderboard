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
        {displayList.length === 0 && activeTab !== 'ab' ? (
          <div className="empty-state"><h3>No scores yet</h3><p>Scores will appear here once entered in the admin panel.</p></div>
        ) : activeTab === 'ab' ? (
          <div className="empty-state"><h3>Above & Beyond</h3><p>Click any trainee row on the Overall tab to see their A&B entries in their profile.</p></div>
        ) : (
          <div style={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 'var(--radius-lg)', overflow: 'hidden', boxShadow: 'var(--shadow-sm)' }}>
            {/* Table header */}
            <div style={{ display: 'grid', gridTemplateColumns: '48px 1fr 120px', padding: '10px 20px', background: 'var(--bg)', borderBottom: '1px solid var(--border)' }}>
              <span style={{ fontSize: 11, color: 'var(--text-muted)', fontWeight: 600 }}>#</span>
              <span style={{ fontSize: 11, color: 'var(--text-muted)', fontWeight: 600 }}>Trainee</span>
              <span style={{ fontSize: 11, color: 'var(--text-muted)', fontWeight: 600, textAlign: 'right' }}>
                {activeTab === 'overall' ? 'Total score' : 'Score'}
              </span>
            </div>

            {displayList.map((row, i) => {
              const traineeData = trainees.find(t => t.id === row.trainee_id);
              return (
                <div
                  key={row.trainee_id}
                  onClick={() => setSelectedTrainee(traineeData || { id: row.trainee_id, name: row.trainee_name })}
                  style={{ display: 'grid', gridTemplateColumns: '48px 1fr 120px', padding: '14px 20px', borderBottom: i < displayList.length - 1 ? '1px solid var(--border-light)' : 'none', cursor: 'pointer', alignItems: 'center', transition: 'background 0.12s' }}
                  onMouseEnter={e => e.currentTarget.style.background = '#F7F9FF'}
                  onMouseLeave={e => e.currentTarget.style.background = 'transparent'}
                >
                  <span style={{ fontSize: 15, fontWeight: 700, color: i === 0 ? 'var(--gold)' : i === 1 ? 'var(--silver)' : i === 2 ? 'var(--bronze)' : 'var(--text-muted)' }}>
                    {i + 1}
                  </span>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                    <Avatar name={row.trainee_name} photoUrl={traineeData?.photo_url} size={40} />
                    <div>
                      <p style={{ fontSize: 14, fontWeight: 600, color: 'var(--navy)' }}>{row.trainee_name}</p>
                      {traineeData?.department && <p style={{ fontSize: 12, color: 'var(--text-muted)' }}>{traineeData.department}</p>}
                    </div>
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <span style={{ fontSize: 18, fontWeight: 700, color: 'var(--navy)' }}>
                      {row.overall_score === '—' ? '—' : Number(row.overall_score).toLocaleString()}
                    </span>
                    {activeTab === 'overall' && <p style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 1 }}>points</p>}
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
        <ProfileDrawer
          trainee={selectedTrainee}
          batchId={batch.id}
          onClose={() => setSelectedTrainee(null)}
        />
      )}
    </div>
  );
}
EOF

cat > src/components/ProfileDrawer.js << 'EOF'
import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import Avatar from './Avatar';

const SUB_COLORS = {
  'Extra project': { bg: '#EEF1FB', color: '#1B2A5E' },
  'External event': { bg: '#E0F2F1', color: '#00695C' },
  'External webinar': { bg: '#F3E5F5', color: '#6A1B9A' },
  'Extra course': { bg: '#FFF8E1', color: '#E65100' },
  'Expert session': { bg: '#FCE4EC', color: '#880E4F' },
};

export default function ProfileDrawer({ trainee, batchId, onClose }) {
  const [categoryScores, setCategoryScores] = useState([]);
  const [attendance, setAttendance] = useState(null);
  const [streaks, setStreaks] = useState([]);
  const [taskDetails, setTaskDetails] = useState([]);
  const [abEntries, setAbEntries] = useState([]);
  const [rank, setRank] = useState(null);
  const navigate = useNavigate();

  useEffect(() => { if (trainee) loadData(); }, [trainee]);

  async function loadData() {
    const [catRes, attRes, streakRes, rankRes, abRes] = await Promise.all([
      supabase.from('trainee_category_scores').select('*').eq('trainee_id', trainee.id),
      supabase.from('trainee_attendance_summary').select('*').eq('trainee_id', trainee.id).single(),
      supabase.from('streak_entries').select('*, categories(name)').eq('trainee_id', trainee.id).eq('completed', true),
      supabase.from('trainee_overall_scores').select('*').eq('batch_id', batchId).order('overall_score', { ascending: false }),
      supabase.from('above_and_beyond').select('*').eq('trainee_id', trainee.id).order('created_at', { ascending: false }),
    ]);

    if (catRes.data) {
      const scored = catRes.data.filter(c => c.category_type !== 'display');
      const maxScore = Math.max(...scored.map(c => Number(c.category_score)), 1);
      setCategoryScores(scored.map(c => ({ ...c, pct: Math.round((Number(c.category_score) / maxScore) * 100) })));
    }
    if (attRes.data) setAttendance(attRes.data);
    if (streakRes.data) {
      const grouped = {};
      streakRes.data.forEach(e => { const name = e.categories?.name || 'Streak'; grouped[name] = (grouped[name] || 0) + 1; });
      setStreaks(Object.entries(grouped).map(([name, count]) => ({ name, count })));
    }
    if (rankRes.data) setRank(rankRes.data.findIndex(t => t.trainee_id === trainee.id) + 1);
    if (abRes.data) setAbEntries(abRes.data);

    const itemsRes = await supabase.from('category_items')
      .select('*, categories(name, type), scores!inner(score, submission_score)')
      .eq('scores.trainee_id', trainee.id).limit(5);
    if (itemsRes.data) setTaskDetails(itemsRes.data);
  }

  const catTotal = categoryScores.reduce((s, c) => s + Number(c.category_score), 0);
  const abTotal = abEntries.reduce((s, e) => s + Number(e.points), 0);
  const totalScore = catTotal + abTotal;
  const maxScore = Math.max(...categoryScores.map(c => Number(c.category_score)), abTotal, 1);

  if (!trainee) return null;

  return (
    <>
      <div
        style={{ position: 'fixed', inset: 0, background: 'rgba(15,26,61,0.4)', zIndex: 900 }}
        onClick={onClose}
      />
      <div style={{ position: 'fixed', right: 0, top: 0, bottom: 0, width: 420, background: 'var(--surface)', boxShadow: '-8px 0 40px rgba(27,42,94,0.14)', zIndex: 901, overflowY: 'auto', animation: 'slideInRight 0.25s ease' }}>

        {/* Header */}
        <div style={{ background: 'linear-gradient(135deg, #1B2A5E 0%, #0F1A3D 100%)', padding: '20px 20px 0', position: 'relative', overflow: 'hidden' }}>
          <div style={{ position: 'absolute', top: -40, right: -40, width: 140, height: 140, background: 'rgba(194,24,91,0.12)', borderRadius: '50%' }} />
          <button
            onClick={onClose}
            style={{ position: 'absolute', top: 14, right: 14, width: 32, height: 32, borderRadius: '50%', background: 'rgba(255,255,255,0.15)', border: 'none', color: '#fff', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18, zIndex: 2, lineHeight: 1 }}
          >
            ✕
          </button>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, position: 'relative', zIndex: 1 }}>
            <div style={{ border: '3px solid rgba(255,255,255,0.25)', borderRadius: '50%', padding: 2 }}>
              <Avatar name={trainee.name} photoUrl={trainee.photo_url} size={72} />
            </div>
            <div style={{ paddingBottom: 4 }}>
              <p style={{ fontSize: 17, fontWeight: 700, color: '#fff', fontFamily: 'var(--font-display)', marginBottom: 3 }}>{trainee.name}</p>
              <p style={{ fontSize: 12, color: 'rgba(255,255,255,0.5)', marginBottom: 8 }}>
                {trainee.employee_id && `ID: ${trainee.employee_id}`}
                {trainee.employee_id && trainee.department && ' · '}
                {trainee.department && `Dept: ${trainee.department}`}
              </p>
              {rank > 0 && (
                <span style={{ background: 'rgba(245,166,35,0.2)', color: '#F5A623', fontSize: 12, padding: '3px 10px', borderRadius: 20, fontWeight: 600 }}>
                  🏅 Rank #{rank} Overall
                </span>
              )}
            </div>
          </div>
          <div style={{ display: 'flex', borderTop: '1px solid rgba(255,255,255,0.08)', marginTop: 16 }}>
            {[
              { val: totalScore.toLocaleString(), label: 'Total pts' },
              { val: attendance ? `${attendance.attendance_pct || 0}%` : '—', label: 'Attendance' },
              { val: streaks.reduce((s, k) => s + k.count, 0), label: 'Streak days' },
            ].map((s, i) => (
              <div key={i} style={{ flex: 1, padding: '12px 8px', textAlign: 'center', borderRight: i < 2 ? '1px solid rgba(255,255,255,0.07)' : 'none' }}>
                <p style={{ fontSize: 16, fontWeight: 700, color: '#fff' }}>{s.val}</p>
                <p style={{ fontSize: 10, color: 'rgba(255,255,255,0.4)', marginTop: 1 }}>{s.label}</p>
              </div>
            ))}
          </div>
        </div>

        {/* Body */}
        <div style={{ padding: '16px 20px' }}>

          {/* Score breakdown */}
          <p style={{ fontSize: 11, fontWeight: 600, color: 'var(--text-muted)', letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 12 }}>Score breakdown</p>
          {categoryScores.map(cat => (
            <div key={cat.category_id} style={{ marginBottom: 12 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 5 }}>
                <span style={{ fontSize: 13, color: 'var(--text-primary)' }}>{cat.category_name}</span>
                <span style={{ fontSize: 14, fontWeight: 600, color: 'var(--navy)' }}>{Number(cat.category_score).toLocaleString()}</span>
              </div>
              <div style={{ height: 5, background: 'var(--border-light)', borderRadius: 3 }}>
                <div style={{ height: '100%', width: `${Math.round((Number(cat.category_score) / maxScore) * 100)}%`, background: 'var(--navy)', borderRadius: 3 }} />
              </div>
            </div>
          ))}

          {/* A&B in score breakdown */}
          {abEntries.length > 0 && (
            <div style={{ marginBottom: 12 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 5 }}>
                <span style={{ fontSize: 13, color: 'var(--text-primary)' }}>Above & Beyond</span>
                <span style={{ fontSize: 14, fontWeight: 600, color: '#C2185B' }}>{abTotal.toLocaleString()}</span>
              </div>
              <div style={{ height: 5, background: 'var(--border-light)', borderRadius: 3 }}>
                <div style={{ height: '100%', width: `${Math.round((abTotal / maxScore) * 100)}%`, background: '#C2185B', borderRadius: 3 }} />
              </div>
            </div>
          )}

          {/* A&B entries detail */}
          {abEntries.length > 0 && (
            <>
              <div style={{ height: 1, background: 'var(--border-light)', margin: '16px 0' }} />
              <p style={{ fontSize: 11, fontWeight: 600, color: 'var(--text-muted)', letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 10 }}>Above & Beyond entries</p>
              {abEntries.map(entry => (
                <div key={entry.id} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px 0', borderBottom: '1px solid var(--border-light)' }}>
                  <span style={{ fontSize: 11, padding: '2px 8px', borderRadius: 20, fontWeight: 500, whiteSpace: 'nowrap', background: SUB_COLORS[entry.sub_category]?.bg, color: SUB_COLORS[entry.sub_category]?.color }}>
                    {entry.sub_category}
                  </span>
                  <p style={{ fontSize: 12, color: 'var(--text-secondary)', flex: 1 }}>{entry.description}</p>
                  <span style={{ fontSize: 13, fontWeight: 700, color: 'var(--navy)', whiteSpace: 'nowrap' }}>{entry.points} pts</span>
                </div>
              ))}
            </>
          )}

          {/* Streaks */}
          {streaks.length > 0 && (
            <>
              <div style={{ height: 1, background: 'var(--border-light)', margin: '16px 0' }} />
              <p style={{ fontSize: 11, fontWeight: 600, color: 'var(--text-muted)', letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 10 }}>Streaks</p>
              {streaks.map(s => (
                <div key={s.name} style={{ background: '#FFF8E1', borderRadius: 10, padding: '10px 14px', marginBottom: 8, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <p style={{ fontSize: 13, fontWeight: 600, color: '#333' }}>{s.name}</p>
                    <p style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 1 }}>{s.count} days completed</p>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                    <span style={{ fontSize: 20 }}>🔥</span>
                    <span style={{ fontSize: 22, fontWeight: 700, color: '#E65100' }}>{s.count}</span>
                  </div>
                </div>
              ))}
            </>
          )}

          {/* Recent scores */}
          {taskDetails.length > 0 && (
            <>
              <div style={{ height: 1, background: 'var(--border-light)', margin: '16px 0' }} />
              <p style={{ fontSize: 11, fontWeight: 600, color: 'var(--text-muted)', letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 10 }}>Recent scores</p>
              {taskDetails.map(item => (
                <div key={item.id} style={{ background: 'var(--bg)', borderRadius: 8, padding: '9px 12px', marginBottom: 6 }}>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                    <span style={{ fontSize: 12, color: 'var(--text-secondary)', flex: 1, marginRight: 8, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{item.name}</span>
                    <div style={{ display: 'flex', gap: 4 }}>
                      {item.has_submission_score && (
                        <span style={{ fontSize: 11, padding: '2px 7px', borderRadius: 6, background: 'var(--teal-light)', color: 'var(--teal)', fontWeight: 600 }}>
                          Sub: {item.scores[0]?.submission_score ?? '—'}
                        </span>
                      )}
                      <span style={{ fontSize: 11, padding: '2px 7px', borderRadius: 6, background: 'var(--navy-light)', color: 'var(--navy)', fontWeight: 600 }}>
                        {item.scores[0]?.score ?? '—'}{item.max_score ? `/${item.max_score}` : ''}
                      </span>
                    </div>
                  </div>
                </div>
              ))}
            </>
          )}

          {/* Attendance */}
          {attendance && (
            <>
              <div style={{ height: 1, background: 'var(--border-light)', margin: '16px 0' }} />
              <p style={{ fontSize: 11, fontWeight: 600, color: 'var(--text-muted)', letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 10 }}>Attendance</p>
              <div style={{ display: 'flex', gap: 16, marginBottom: 12 }}>
                {[{ val: attendance.days_present, label: 'Present', color: 'var(--navy)' }, { val: attendance.days_absent, label: 'Absent', color: '#B91C1C' }, { val: `${attendance.attendance_pct || 0}%`, label: 'Rate', color: 'var(--teal)' }].map((s, i) => (
                  <div key={i} style={{ flex: 1, background: 'var(--bg)', borderRadius: 8, padding: '10px 12px', textAlign: 'center' }}>
                    <p style={{ fontSize: 18, fontWeight: 700, color: s.color }}>{s.val}</p>
                    <p style={{ fontSize: 11, color: 'var(--text-muted)' }}>{s.label}</p>
                  </div>
                ))}
              </div>
            </>
          )}

          <button
            onClick={() => { navigate(`/trainee/${trainee.id}`); onClose(); }}
            className="btn btn-secondary w-full"
            style={{ justifyContent: 'center', marginTop: 8 }}
          >
            View full profile page →
          </button>
        </div>
      </div>
    </>
  );
}
EOF

cd /workspaces/bootcamp-leaderboard && git add . && git commit -m "Fix leaderboard table, drawer close, A&B in drawer" && git push
echo "ALL DONE"

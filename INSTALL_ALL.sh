#!/bin/bash
set -e

# LeaderboardHero
cat > src/components/LeaderboardHero.js << 'EOF'
import Avatar from './Avatar';
const borderColors = ['var(--gold)', 'var(--silver)', 'var(--bronze)'];
const barHeights = [52, 32, 20];
export default function LeaderboardHero({ topThree = [], batchName, batchDay }) {
  if (topThree.length === 0) return null;
  const podiumOrder = [topThree[1], topThree[0], topThree[2]].filter(Boolean);
  const podiumRanks = topThree.length >= 2 ? [2, 1, 3] : [1];
  return (
    <div style={{ background: 'linear-gradient(160deg, #1B2A5E 0%, #0F1A3D 100%)', padding: '32px 28px 0', position: 'relative', overflow: 'hidden' }}>
      <div style={{ position: 'absolute', top: -80, right: -80, width: 280, height: 280, background: 'rgba(194,24,91,0.1)', borderRadius: '50%', pointerEvents: 'none' }} />
      <div style={{ position: 'absolute', bottom: -60, left: '20%', width: 200, height: 200, background: 'rgba(0,137,123,0.07)', borderRadius: '50%', pointerEvents: 'none' }} />
      <div style={{ textAlign: 'center', marginBottom: 28, position: 'relative', zIndex: 1 }}>
        {batchDay && <p style={{ fontSize: 11, color: 'rgba(255,255,255,0.45)', letterSpacing: '0.1em', textTransform: 'uppercase', marginBottom: 4 }}>{batchName} · Day {batchDay}</p>}
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
                <p style={{ fontSize: isFirst ? 14 : 12, fontWeight: 600, color: '#fff', fontFamily: 'var(--font-display)', maxWidth: isFirst ? 130 : 110, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                  {trainee.trainee_name.split(' ')[0]} {trainee.trainee_name.split(' ').slice(-1)[0]}
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

# ProfileDrawer
cat > src/components/ProfileDrawer.js << 'EOF'
import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import Avatar from './Avatar';
export default function ProfileDrawer({ trainee, batchId, onClose }) {
  const [categoryScores, setCategoryScores] = useState([]);
  const [attendance, setAttendance] = useState(null);
  const [streaks, setStreaks] = useState([]);
  const [taskDetails, setTaskDetails] = useState([]);
  const [rank, setRank] = useState(null);
  const navigate = useNavigate();
  useEffect(() => { if (trainee) loadData(); }, [trainee]);
  async function loadData() {
    const [catRes, attRes, streakRes, rankRes] = await Promise.all([
      supabase.from('trainee_category_scores').select('*').eq('trainee_id', trainee.id),
      supabase.from('trainee_attendance_summary').select('*').eq('trainee_id', trainee.id).single(),
      supabase.from('streak_entries').select('*, categories(name)').eq('trainee_id', trainee.id).eq('completed', true),
      supabase.from('trainee_overall_scores').select('*').eq('batch_id', batchId).order('overall_score', { ascending: false }),
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
    const itemsRes = await supabase.from('category_items').select('*, categories(name, type), scores!inner(score, submission_score)').eq('scores.trainee_id', trainee.id).limit(6);
    if (itemsRes.data) setTaskDetails(itemsRes.data);
  }
  const totalScore = categoryScores.reduce((s, c) => s + Number(c.category_score), 0);
  if (!trainee) return null;
  return (
    <>
      <div className="drawer-overlay" onClick={onClose} />
      <div className="drawer">
        <div style={{ background: 'linear-gradient(135deg, #1B2A5E 0%, #0F1A3D 100%)', padding: '20px 20px 0', position: 'relative', overflow: 'hidden' }}>
          <div style={{ position: 'absolute', top: -40, right: -40, width: 140, height: 140, background: 'rgba(194,24,91,0.12)', borderRadius: '50%' }} />
          <button onClick={onClose} style={{ position: 'absolute', top: 14, right: 14, width: 28, height: 28, borderRadius: '50%', background: 'rgba(255,255,255,0.1)', border: 'none', color: 'rgba(255,255,255,0.8)', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 16, zIndex: 1 }}>✕</button>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, position: 'relative', zIndex: 1 }}>
            <div style={{ border: '3px solid rgba(255,255,255,0.25)', borderRadius: '50%', padding: 2 }}>
              <Avatar name={trainee.name} photoUrl={trainee.photo_url} size={72} />
            </div>
            <div style={{ paddingBottom: 4 }}>
              <p style={{ fontSize: 17, fontWeight: 700, color: '#fff', fontFamily: 'var(--font-display)', marginBottom: 3 }}>{trainee.name}</p>
              <p style={{ fontSize: 12, color: 'rgba(255,255,255,0.5)', marginBottom: 8 }}>{trainee.employee_id && `ID: ${trainee.employee_id}`}{trainee.employee_id && trainee.department && ' · '}{trainee.department && `Dept: ${trainee.department}`}</p>
              {rank > 0 && <span style={{ background: 'rgba(245,166,35,0.2)', color: '#F5A623', fontSize: 12, padding: '3px 10px', borderRadius: 20, fontWeight: 600 }}>🏅 Rank #{rank} Overall</span>}
            </div>
          </div>
          <div style={{ display: 'flex', borderTop: '1px solid rgba(255,255,255,0.08)', marginTop: 16 }}>
            {[{ val: totalScore.toLocaleString(), label: 'Total pts' }, { val: attendance ? `${attendance.attendance_pct || 0}%` : '—', label: 'Attendance' }, { val: streaks.reduce((s, k) => s + k.count, 0), label: 'Streak days' }].map((s, i) => (
              <div key={i} style={{ flex: 1, padding: '12px 8px', textAlign: 'center', borderRight: i < 2 ? '1px solid rgba(255,255,255,0.07)' : 'none' }}>
                <p style={{ fontSize: 16, fontWeight: 700, color: '#fff' }}>{s.val}</p>
                <p style={{ fontSize: 10, color: 'rgba(255,255,255,0.4)', marginTop: 1 }}>{s.label}</p>
              </div>
            ))}
          </div>
        </div>
        <div style={{ padding: '16px 20px' }}>
          <p style={{ fontSize: 11, fontWeight: 600, color: 'var(--text-muted)', letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 12 }}>Score breakdown</p>
          {categoryScores.map(cat => (
            <div key={cat.category_id} style={{ marginBottom: 12 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 5 }}>
                <span style={{ fontSize: 13, color: 'var(--text-primary)' }}>{cat.category_name}</span>
                <span style={{ fontSize: 14, fontWeight: 600, color: 'var(--navy)' }}>{Number(cat.category_score).toLocaleString()}</span>
              </div>
              <div style={{ height: 5, background: 'var(--border-light)', borderRadius: 3 }}>
                <div style={{ height: '100%', width: `${cat.pct}%`, background: 'var(--navy)', borderRadius: 3 }} />
              </div>
            </div>
          ))}
          {streaks.length > 0 && (<>
            <div className="divider" />
            <p style={{ fontSize: 11, fontWeight: 600, color: 'var(--text-muted)', letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 12 }}>Streaks</p>
            {streaks.map(s => (
              <div key={s.name} style={{ background: '#FFF8E1', borderRadius: 10, padding: '10px 14px', marginBottom: 8, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div><p style={{ fontSize: 13, fontWeight: 600, color: '#333' }}>{s.name}</p><p style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 1 }}>{s.count} days completed</p></div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}><span style={{ fontSize: 20 }}>🔥</span><span style={{ fontSize: 22, fontWeight: 700, color: '#E65100' }}>{s.count}</span></div>
              </div>
            ))}
          </>)}
          {taskDetails.length > 0 && (<>
            <div className="divider" />
            <p style={{ fontSize: 11, fontWeight: 600, color: 'var(--text-muted)', letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 12 }}>Recent scores</p>
            {taskDetails.map(item => (
              <div key={item.id} style={{ background: 'var(--bg)', borderRadius: 8, padding: '9px 12px', marginBottom: 6 }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <span style={{ fontSize: 12, color: 'var(--text-secondary)', flex: 1, marginRight: 8, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{item.name}</span>
                  <div style={{ display: 'flex', gap: 4 }}>
                    {item.has_submission_score && <span style={{ fontSize: 11, padding: '2px 7px', borderRadius: 6, background: 'var(--teal-light)', color: 'var(--teal)', fontWeight: 600 }}>Sub: {item.scores[0]?.submission_score ?? '—'}</span>}
                    <span style={{ fontSize: 11, padding: '2px 7px', borderRadius: 6, background: 'var(--navy-light)', color: 'var(--navy)', fontWeight: 600 }}>{item.scores[0]?.score ?? '—'}{item.max_score ? `/${item.max_score}` : ''}</span>
                  </div>
                </div>
              </div>
            ))}
          </>)}
          {attendance && (<>
            <div className="divider" />
            <p style={{ fontSize: 11, fontWeight: 600, color: 'var(--text-muted)', letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 12 }}>Attendance</p>
            <div style={{ display: 'flex', gap: 16, marginBottom: 12 }}>
              {[{ val: attendance.days_present, label: 'Present', color: 'var(--navy)' }, { val: attendance.days_absent, label: 'Absent', color: '#B91C1C' }, { val: `${attendance.attendance_pct || 0}%`, label: 'Rate', color: 'var(--teal)' }].map((s, i) => (
                <div key={i} style={{ flex: 1, background: 'var(--bg)', borderRadius: 8, padding: '10px 12px', textAlign: 'center' }}>
                  <p style={{ fontSize: 18, fontWeight: 700, color: s.color }}>{s.val}</p>
                  <p style={{ fontSize: 11, color: 'var(--text-muted)' }}>{s.label}</p>
                </div>
              ))}
            </div>
          </>)}
          <button onClick={() => { navigate(`/trainee/${trainee.id}`); onClose(); }} className="btn btn-secondary w-full" style={{ justifyContent: 'center', marginTop: 8 }}>View full profile page →</button>
        </div>
      </div>
    </>
  );
}
EOF

# LeaderboardPage
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
    const cat = categories.find(c => c.id === activeTab);
    if (!cat) return [];
    if (cat.type === 'display') return trainees.map(t => ({ trainee_id: t.id, trainee_name: t.name, photo_url: t.photo_url, overall_score: '—' }));
    return categoryScores.filter(cs => cs.category_id === activeTab).sort((a, b) => Number(b.category_score) - Number(a.category_score)).map(cs => ({ trainee_id: cs.trainee_id, trainee_name: cs.trainee_name, photo_url: null, overall_score: cs.category_score }));
  }
  const displayList = getDisplayList();
  const topThree = overallScores.slice(0, 3).map(s => ({ ...s, photo_url: trainees.find(t => t.id === s.trainee_id)?.photo_url || null }));
  if (loading) return <div className="page-loading"><div className="spinner spinner-lg" /><p>Loading leaderboard...</p></div>;
  if (!batch) return <div className="empty-state" style={{ marginTop: 80 }}><h3>No batch selected</h3><p>Create a batch in the admin panel to get started.</p></div>;
  return (
    <div>
      <LeaderboardHero topThree={topThree} batchName={batch.name} />
      <div style={{ background: '#fff', borderBottom: '1px solid var(--border)', padding: '0 28px', overflowX: 'auto' }}>
        <div className="tabs" style={{ borderBottom: 'none', flexWrap: 'nowrap' }}>
          <button className={`tab-btn ${activeTab === 'overall' ? 'active' : ''}`} onClick={() => setActiveTab('overall')}>Overall</button>
          {categories.map(cat => <button key={cat.id} className={`tab-btn ${activeTab === cat.id ? 'active' : ''}`} onClick={() => setActiveTab(cat.id)}>{cat.name}</button>)}
        </div>
      </div>
      <div style={{ padding: '20px 28px', maxWidth: 900, margin: '0 auto' }}>
        {displayList.length === 0 ? (
          <div className="empty-state"><h3>No scores yet</h3><p>Scores will appear here once entered in the admin panel.</p></div>
        ) : (
          <div style={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 'var(--radius-lg)', overflow: 'hidden', boxShadow: 'var(--shadow-sm)' }}>
            <div style={{ display: 'grid', gridTemplateColumns: activeTab === 'overall' ? '40px 1fr repeat(4,80px) 90px' : '40px 1fr 100px', padding: '8px 20px', background: 'var(--bg)', borderBottom: '1px solid var(--border)' }}>
              <span style={{ fontSize: 11, color: 'var(--text-muted)', fontWeight: 600 }}>#</span>
              <span style={{ fontSize: 11, color: 'var(--text-muted)', fontWeight: 600 }}>Trainee</span>
              {activeTab === 'overall' ? (<>
                {categories.filter(c => c.type !== 'display').slice(0, 3).map(c => <span key={c.id} style={{ fontSize: 11, color: 'var(--text-muted)', fontWeight: 600, textAlign: 'right' }}>{c.name}</span>)}
                {categories.filter(c => c.type !== 'display').length > 3 && <span style={{ fontSize: 11, color: 'var(--text-muted)', fontWeight: 600, textAlign: 'right' }}>+More</span>}
                <span style={{ fontSize: 11, color: 'var(--text-muted)', fontWeight: 600, textAlign: 'right' }}>Total</span>
              </>) : <span style={{ fontSize: 11, color: 'var(--text-muted)', fontWeight: 600, textAlign: 'right' }}>Score</span>}
            </div>
            {displayList.map((row, i) => {
              const traineeData = trainees.find(t => t.id === row.trainee_id);
              const catScoresForRow = categoryScores.filter(cs => cs.trainee_id === row.trainee_id);
              return (
                <div key={row.trainee_id} onClick={() => setSelectedTrainee(traineeData || { id: row.trainee_id, name: row.trainee_name })}
                  style={{ display: 'grid', gridTemplateColumns: activeTab === 'overall' ? '40px 1fr repeat(4,80px) 90px' : '40px 1fr 100px', padding: '12px 20px', borderBottom: i < displayList.length - 1 ? '1px solid var(--border-light)' : 'none', cursor: 'pointer', alignItems: 'center' }}
                  onMouseEnter={e => e.currentTarget.style.background = '#F7F9FF'} onMouseLeave={e => e.currentTarget.style.background = 'transparent'}>
                  <span style={{ fontSize: 14, fontWeight: 600, color: i === 0 ? 'var(--gold)' : i === 1 ? 'var(--silver)' : i === 2 ? 'var(--bronze)' : 'var(--text-muted)' }}>{i + 1}</span>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <Avatar name={row.trainee_name} photoUrl={traineeData?.photo_url} size={36} />
                    <div><p style={{ fontSize: 13, fontWeight: 600, color: 'var(--navy)' }}>{row.trainee_name}</p>{traineeData?.department && <p style={{ fontSize: 11, color: 'var(--text-muted)' }}>{traineeData.department}</p>}</div>
                  </div>
                  {activeTab === 'overall' ? (<>
                    {categories.filter(c => c.type !== 'display').slice(0, 3).map(c => {
                      const cs = catScoresForRow.find(s => s.category_id === c.id);
                      return <span key={c.id} style={{ fontSize: 12, color: c.type === 'streak' ? '#E65100' : 'var(--text-secondary)', textAlign: 'right', fontWeight: c.type === 'streak' ? 600 : 400 }}>{c.type === 'streak' ? `🔥 ${cs ? Number(cs.category_score) : 0}` : cs ? Number(cs.category_score).toLocaleString() : '—'}</span>;
                    })}
                    {categories.filter(c => c.type !== 'display').length > 3 && <span style={{ fontSize: 11, color: 'var(--text-muted)', textAlign: 'right' }}>...</span>}
                    <span style={{ fontSize: 14, fontWeight: 700, color: 'var(--navy)', textAlign: 'right' }}>{Number(row.overall_score).toLocaleString()}</span>
                  </>) : <span style={{ fontSize: 14, fontWeight: 700, color: 'var(--navy)', textAlign: 'right' }}>{row.overall_score === '—' ? '—' : Number(row.overall_score).toLocaleString()}</span>}
                </div>
              );
            })}
          </div>
        )}
        <p style={{ textAlign: 'center', fontSize: 12, color: 'var(--text-muted)', marginTop: 12 }}>Click any row to view trainee profile</p>
      </div>
      {selectedTrainee && <ProfileDrawer trainee={selectedTrainee} batchId={batch.id} onClose={() => setSelectedTrainee(null)} />}
    </div>
  );
}
EOF

# TraineePage
cat > src/pages/TraineePage.js << 'EOF'
import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import Avatar from '../components/Avatar';
import { format, parseISO } from 'date-fns';
export default function TraineePage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [trainee, setTrainee] = useState(null);
  const [categoryScores, setCategoryScores] = useState([]);
  const [itemScores, setItemScores] = useState([]);
  const [attendance, setAttendance] = useState([]);
  const [attendanceSummary, setAttendanceSummary] = useState(null);
  const [streaks, setStreaks] = useState([]);
  const [rank, setRank] = useState(null);
  const [loading, setLoading] = useState(true);
  useEffect(() => { loadData(); }, [id]);
  async function loadData() {
    setLoading(true);
    const [traineeRes, catRes, itemsRes, attRes, attSumRes, streakRes] = await Promise.all([
      supabase.from('trainees').select('*').eq('id', id).single(),
      supabase.from('trainee_category_scores').select('*').eq('trainee_id', id),
      supabase.from('scores').select('*, category_items(name, max_score, has_submission_score, categories(name, type))').eq('trainee_id', id),
      supabase.from('attendance').select('*').eq('trainee_id', id).order('entry_date'),
      supabase.from('trainee_attendance_summary').select('*').eq('trainee_id', id).single(),
      supabase.from('streak_entries').select('*, categories(name)').eq('trainee_id', id).order('entry_date'),
    ]);
    if (traineeRes.data) {
      setTrainee(traineeRes.data);
      const rankRes = await supabase.from('trainee_overall_scores').select('trainee_id').eq('batch_id', traineeRes.data.batch_id).order('overall_score', { ascending: false });
      if (rankRes.data) setRank(rankRes.data.findIndex(t => t.trainee_id === id) + 1);
    }
    if (catRes.data) setCategoryScores(catRes.data.filter(c => c.category_type !== 'display'));
    if (itemsRes.data) setItemScores(itemsRes.data);
    if (attRes.data) setAttendance(attRes.data);
    if (attSumRes.data) setAttendanceSummary(attSumRes.data);
    if (streakRes.data) {
      const grouped = {};
      streakRes.data.forEach(e => { const name = e.categories?.name || 'Streak'; if (!grouped[name]) grouped[name] = []; grouped[name].push(e); });
      setStreaks(Object.entries(grouped).map(([name, entries]) => ({ name, total: entries.filter(e => e.completed).length, entries })));
    }
    setLoading(false);
  }
  if (loading) return <div className="page-loading"><div className="spinner spinner-lg" /><p>Loading profile...</p></div>;
  if (!trainee) return <div className="empty-state" style={{ marginTop: 80 }}><h3>Trainee not found</h3></div>;
  const totalScore = categoryScores.reduce((s, c) => s + Number(c.category_score), 0);
  const maxCatScore = Math.max(...categoryScores.map(c => Number(c.category_score)), 1);
  const byCategory = {};
  itemScores.forEach(s => { const catName = s.category_items?.categories?.name || 'Other'; if (!byCategory[catName]) byCategory[catName] = []; byCategory[catName].push(s); });
  return (
    <div style={{ maxWidth: 780, margin: '0 auto', padding: '24px 20px' }}>
      <button onClick={() => navigate(-1)} className="btn btn-secondary btn-sm" style={{ marginBottom: 20 }}>← Back</button>
      <div className="card" style={{ marginBottom: 16, background: 'linear-gradient(135deg, #1B2A5E 0%, #0F1A3D 100%)', border: 'none' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 20 }}>
          <div style={{ border: '3px solid rgba(255,255,255,0.25)', borderRadius: '50%', padding: 3 }}><Avatar name={trainee.name} photoUrl={trainee.photo_url} size={80} /></div>
          <div>
            <h1 style={{ fontFamily: 'var(--font-display)', fontSize: 22, color: '#fff', marginBottom: 4 }}>{trainee.name}</h1>
            <p style={{ fontSize: 13, color: 'rgba(255,255,255,0.5)', marginBottom: 10 }}>{[trainee.employee_id && `ID: ${trainee.employee_id}`, trainee.department && `Dept: ${trainee.department}`, trainee.email].filter(Boolean).join(' · ')}</p>
            {rank > 0 && <span style={{ background: 'rgba(245,166,35,0.2)', color: '#F5A623', fontSize: 12, padding: '3px 12px', borderRadius: 20, fontWeight: 600 }}>🏅 Rank #{rank} Overall</span>}
          </div>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 1, background: 'rgba(255,255,255,0.08)', borderRadius: 10, overflow: 'hidden' }}>
          {[{ val: totalScore.toLocaleString(), label: 'Total score' }, { val: attendanceSummary ? `${attendanceSummary.attendance_pct || 0}%` : '—', label: 'Attendance' }, { val: streaks.reduce((s, k) => s + k.total, 0), label: 'Streak days' }].map((s, i) => (
            <div key={i} style={{ padding: '14px 8px', textAlign: 'center', background: 'rgba(255,255,255,0.04)' }}>
              <p style={{ fontSize: 20, fontWeight: 700, color: '#fff' }}>{s.val}</p>
              <p style={{ fontSize: 11, color: 'rgba(255,255,255,0.4)', marginTop: 2 }}>{s.label}</p>
            </div>
          ))}
        </div>
      </div>
      <div className="grid-2" style={{ marginBottom: 16 }}>
        <div className="card">
          <p className="card-title">Score breakdown</p>
          {categoryScores.length === 0 ? <p className="text-sm text-muted">No scores yet</p> : categoryScores.map(cat => (
            <div key={cat.category_id} style={{ marginBottom: 14 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 5 }}>
                <span style={{ fontSize: 13 }}>{cat.category_name}</span>
                <span style={{ fontSize: 14, fontWeight: 600, color: 'var(--navy)' }}>{Number(cat.category_score).toLocaleString()}</span>
              </div>
              <div style={{ height: 5, background: 'var(--border-light)', borderRadius: 3 }}>
                <div style={{ height: '100%', width: `${Math.round((Number(cat.category_score) / maxCatScore) * 100)}%`, background: 'var(--navy)', borderRadius: 3 }} />
              </div>
            </div>
          ))}
        </div>
        <div className="card">
          <p className="card-title">Streaks</p>
          {streaks.length === 0 ? <p className="text-sm text-muted">No streaks tracked yet</p> : streaks.map(s => (
            <div key={s.name} style={{ background: '#FFF8E1', borderRadius: 10, padding: '12px 14px', marginBottom: 10 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div><p style={{ fontSize: 14, fontWeight: 600 }}>{s.name}</p><p style={{ fontSize: 11, color: 'var(--text-muted)' }}>{s.total} of {s.entries.length} days completed</p></div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}><span style={{ fontSize: 24 }}>🔥</span><span style={{ fontSize: 26, fontWeight: 700, color: '#E65100' }}>{s.total}</span></div>
              </div>
            </div>
          ))}
        </div>
      </div>
      {Object.entries(byCategory).map(([catName, items]) => (
        <div key={catName} className="card" style={{ marginBottom: 16 }}>
          <p className="card-title">{catName}</p>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13 }}>
            <thead><tr style={{ borderBottom: '1px solid var(--border-light)' }}>
              <th style={{ textAlign: 'left', padding: '6px 8px', fontSize: 11, color: 'var(--text-muted)', fontWeight: 600 }}>Item</th>
              {items[0]?.category_items?.has_submission_score && <th style={{ textAlign: 'right', padding: '6px 8px', fontSize: 11, color: 'var(--text-muted)', fontWeight: 600 }}>Submission</th>}
              <th style={{ textAlign: 'right', padding: '6px 8px', fontSize: 11, color: 'var(--text-muted)', fontWeight: 600 }}>Score</th>
            </tr></thead>
            <tbody>{items.map(item => (
              <tr key={item.id} style={{ borderBottom: '1px solid var(--border-light)' }}>
                <td style={{ padding: '9px 8px' }}>{item.category_items?.name}</td>
                {item.category_items?.has_submission_score && <td style={{ padding: '9px 8px', textAlign: 'right' }}><span className="badge badge-teal">{item.submission_score ?? '—'}</span></td>}
                <td style={{ padding: '9px 8px', textAlign: 'right' }}><span className="badge badge-navy">{item.score ?? '—'}{item.category_items?.max_score ? `/${item.category_items.max_score}` : ''}</span></td>
              </tr>
            ))}</tbody>
          </table>
        </div>
      ))}
      {attendance.length > 0 && (
        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
            <p className="card-title" style={{ marginBottom: 0 }}>Attendance</p>
            {attendanceSummary && <div style={{ display: 'flex', gap: 8 }}><span className="badge badge-green">Present: {attendanceSummary.days_present}</span><span className="badge badge-red">Absent: {attendanceSummary.days_absent}</span><span className="badge badge-navy">{attendanceSummary.attendance_pct}%</span></div>}
          </div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
            {attendance.map(a => <div key={a.id} title={`${format(parseISO(a.entry_date), 'dd MMM yyyy')} — ${a.present ? 'Present' : 'Absent'}`} style={{ width: 16, height: 16, borderRadius: 3, background: a.present ? 'var(--navy)' : '#FEE2E2' }} />)}
          </div>
          <div style={{ display: 'flex', gap: 16, marginTop: 10 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}><div style={{ width: 12, height: 12, borderRadius: 2, background: 'var(--navy)' }} /><span style={{ fontSize: 11, color: 'var(--text-muted)' }}>Present</span></div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}><div style={{ width: 12, height: 12, borderRadius: 2, background: '#FEE2E2' }} /><span style={{ fontSize: 11, color: 'var(--text-muted)' }}>Absent</span></div>
          </div>
        </div>
      )}
    </div>
  );
}
EOF

echo "COMPONENTS DONE"
#!/bin/bash
set -e

# AdminLogin
cat > src/pages/AdminLogin.js << 'EOF'
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
export default function AdminLogin() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { signIn } = useAuth();
  const navigate = useNavigate();
  const handleSubmit = async e => {
    e.preventDefault(); setLoading(true); setError('');
    const { error } = await signIn(email, password);
    if (error) { setError('Invalid email or password'); setLoading(false); }
    else navigate('/admin');
  };
  return (
    <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'var(--bg)' }}>
      <div style={{ width: '100%', maxWidth: 380, padding: '0 20px' }}>
        <div style={{ textAlign: 'center', marginBottom: 32 }}>
          <div style={{ width: 48, height: 48, background: 'var(--navy)', borderRadius: 12, display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 14px' }}>
            <span style={{ color: '#fff', fontSize: 16, fontWeight: 700, fontFamily: 'var(--font-display)' }}>EX</span>
          </div>
          <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 22, color: 'var(--navy)', marginBottom: 4 }}>Admin panel</h2>
          <p style={{ fontSize: 13, color: 'var(--text-muted)' }}>Excelra Bootcamp Leaderboard</p>
        </div>
        <div className="card">
          <form onSubmit={handleSubmit}>
            <div className="form-group" style={{ marginBottom: 12 }}>
              <label className="form-label">Email</label>
              <input className="form-input" type="email" value={email} onChange={e => setEmail(e.target.value)} required placeholder="your@email.com" />
            </div>
            <div className="form-group" style={{ marginBottom: 16 }}>
              <label className="form-label">Password</label>
              <input className="form-input" type="password" value={password} onChange={e => setPassword(e.target.value)} required placeholder="••••••••" />
            </div>
            {error && <p className="form-error" style={{ marginBottom: 12 }}>{error}</p>}
            <button className="btn btn-primary w-full btn-lg" style={{ justifyContent: 'center' }} disabled={loading}>
              {loading ? <span className="spinner" style={{ width: 16, height: 16 }} /> : 'Sign in'}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
EOF

# AdminLayout
cat > src/pages/AdminLayout.js << 'EOF'
import { useNavigate, useLocation, Outlet } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
const navItems = [
  { label: 'Dashboard', path: '/admin', icon: '⊞', exact: true },
  { label: 'Batches', path: '/admin/batches', icon: '◫' },
  { label: 'Trainees', path: '/admin/trainees', icon: '◉' },
  { label: 'Categories', path: '/admin/categories', icon: '◈' },
  { label: 'Enter scores', path: '/admin/scores', icon: '✎' },
  { label: 'Streaks', path: '/admin/streaks', icon: '⚡' },
  { label: 'Attendance', path: '/admin/attendance', icon: '◻' },
  { label: 'Export', path: '/admin/export', icon: '↓' },
];
export default function AdminLayout() {
  const { isAdmin } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  if (!isAdmin) { navigate('/admin/login'); return null; }
  const isActive = (path, exact) => exact ? location.pathname === path : location.pathname.startsWith(path);
  return (
    <div style={{ display: 'flex', minHeight: 'calc(100vh - 56px)' }}>
      <aside style={{ width: 200, background: '#fff', borderRight: '1px solid var(--border)', padding: '16px 0', flexShrink: 0 }}>
        {navItems.map(item => (
          <button key={item.path} onClick={() => navigate(item.path)} style={{ width: '100%', textAlign: 'left', padding: '9px 20px', fontSize: 13, cursor: 'pointer', border: 'none', background: isActive(item.path, item.exact) ? 'var(--navy-light)' : 'transparent', color: isActive(item.path, item.exact) ? 'var(--navy)' : 'var(--text-secondary)', fontWeight: isActive(item.path, item.exact) ? 600 : 400, fontFamily: 'var(--font-body)', borderRight: isActive(item.path, item.exact) ? '2px solid var(--navy)' : '2px solid transparent', display: 'flex', alignItems: 'center', gap: 10 }}>
            <span style={{ fontSize: 15 }}>{item.icon}</span>{item.label}
          </button>
        ))}
      </aside>
      <main style={{ flex: 1, padding: '24px 28px', overflowY: 'auto', background: 'var(--bg)' }}><Outlet /></main>
    </div>
  );
}
EOF

# AdminDashboard
cat > src/pages/admin/AdminDashboard.js << 'EOF'
import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../../lib/supabase';
export default function AdminDashboard() {
  const [stats, setStats] = useState({ batches: 0, trainees: 0, categories: 0, scores: 0 });
  const [recentBatches, setRecentBatches] = useState([]);
  const navigate = useNavigate();
  useEffect(() => {
    Promise.all([
      supabase.from('batches').select('*', { count: 'exact', head: true }),
      supabase.from('trainees').select('*', { count: 'exact', head: true }).eq('is_active', true),
      supabase.from('categories').select('*', { count: 'exact', head: true }),
      supabase.from('scores').select('*', { count: 'exact', head: true }),
      supabase.from('batches').select('id,name,created_at,is_active').order('created_at', { ascending: false }).limit(5),
    ]).then(([b, t, c, s, rb]) => {
      setStats({ batches: b.count || 0, trainees: t.count || 0, categories: c.count || 0, scores: s.count || 0 });
      if (rb.data) setRecentBatches(rb.data);
    });
  }, []);
  const quickLinks = [
    { label: 'New batch', desc: 'Start a new bootcamp', path: '/admin/batches', color: 'var(--navy)' },
    { label: 'Add trainees', desc: 'Add people to a batch', path: '/admin/trainees', color: 'var(--teal)' },
    { label: 'Enter scores', desc: 'Update scores', path: '/admin/scores', color: 'var(--magenta)' },
    { label: 'Add category', desc: 'New scoring dimension', path: '/admin/categories', color: '#E65100' },
  ];
  return (
    <div>
      <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 20, color: 'var(--navy)', marginBottom: 4 }}>Dashboard</h2>
      <p style={{ fontSize: 13, color: 'var(--text-muted)', marginBottom: 24 }}>Overview of all bootcamp data</p>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 12, marginBottom: 24 }}>
        {[{ label: 'Batches', val: stats.batches }, { label: 'Active trainees', val: stats.trainees }, { label: 'Categories', val: stats.categories }, { label: 'Score entries', val: stats.scores }].map(s => (
          <div key={s.label} style={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 'var(--radius-lg)', padding: '16px 20px' }}>
            <p style={{ fontSize: 26, fontWeight: 700, color: 'var(--navy)', fontFamily: 'var(--font-display)' }}>{s.val}</p>
            <p style={{ fontSize: 12, color: 'var(--text-muted)', marginTop: 2 }}>{s.label}</p>
          </div>
        ))}
      </div>
      <h3 style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-secondary)', marginBottom: 12, textTransform: 'uppercase', letterSpacing: '0.06em' }}>Quick actions</h3>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 12, marginBottom: 28 }}>
        {quickLinks.map(l => (
          <button key={l.path} onClick={() => navigate(l.path)} style={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 'var(--radius-lg)', padding: 16, textAlign: 'left', cursor: 'pointer', transition: 'all 0.15s' }}
            onMouseEnter={e => { e.currentTarget.style.borderColor = l.color; e.currentTarget.style.transform = 'translateY(-1px)'; }} onMouseLeave={e => { e.currentTarget.style.borderColor = 'var(--border)'; e.currentTarget.style.transform = 'none'; }}>
            <div style={{ width: 32, height: 32, background: l.color, borderRadius: 8, marginBottom: 10, opacity: 0.15 }} />
            <p style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-primary)', marginBottom: 2 }}>{l.label}</p>
            <p style={{ fontSize: 12, color: 'var(--text-muted)' }}>{l.desc}</p>
          </button>
        ))}
      </div>
      {recentBatches.length > 0 && (<>
        <h3 style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-secondary)', marginBottom: 12, textTransform: 'uppercase', letterSpacing: '0.06em' }}>Recent batches</h3>
        <div className="card" style={{ padding: 0 }}>
          {recentBatches.map((b, i) => (
            <div key={b.id} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 20px', borderBottom: i < recentBatches.length - 1 ? '1px solid var(--border-light)' : 'none' }}>
              <div><p style={{ fontSize: 14, fontWeight: 600, color: 'var(--navy)' }}>{b.name}</p><p style={{ fontSize: 12, color: 'var(--text-muted)' }}>{new Date(b.created_at).toLocaleDateString()}</p></div>
              <span className={`badge ${b.is_active ? 'badge-green' : 'badge-gray'}`}>{b.is_active ? 'Active' : 'Inactive'}</span>
            </div>
          ))}
        </div>
      </>)}
    </div>
  );
}
EOF

echo "ADMIN PAGES 1 DONE"
#!/bin/bash
set -e

# AdminBatches
cat > src/pages/admin/AdminBatches.js << 'EOF'
import { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { useToast } from '../../context/ToastContext';
export default function AdminBatches() {
  const [batches, setBatches] = useState([]);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ name: '', description: '', start_date: '' });
  const [saving, setSaving] = useState(false);
  const { addToast } = useToast();
  useEffect(() => { load(); }, []);
  async function load() { const { data } = await supabase.from('batches').select('*').order('created_at', { ascending: false }); if (data) setBatches(data); }
  async function save() {
    if (!form.name.trim()) return; setSaving(true);
    const { error } = await supabase.from('batches').insert({ name: form.name.trim(), description: form.description, start_date: form.start_date || null });
    if (error) { addToast(error.message, 'error'); } else { addToast('Batch created!'); setShowForm(false); setForm({ name: '', description: '', start_date: '' }); load(); }
    setSaving(false);
  }
  async function toggleActive(batch) { await supabase.from('batches').update({ is_active: !batch.is_active }).eq('id', batch.id); load(); }
  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div><h2 style={{ fontFamily: 'var(--font-display)', fontSize: 20, color: 'var(--navy)' }}>Batches</h2><p style={{ fontSize: 13, color: 'var(--text-muted)', marginTop: 2 }}>Manage your bootcamp batches</p></div>
        <button className="btn btn-primary" onClick={() => setShowForm(!showForm)}>+ New batch</button>
      </div>
      {showForm && (
        <div className="card" style={{ marginBottom: 20 }}>
          <p className="card-title">Create new batch</p>
          <div className="grid-2" style={{ marginBottom: 12 }}>
            <div className="form-group"><label className="form-label">Batch name *</label><input className="form-input" placeholder="e.g. Tech Batch 10" value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} /></div>
            <div className="form-group"><label className="form-label">Start date</label><input className="form-input" type="date" value={form.start_date} onChange={e => setForm({ ...form, start_date: e.target.value })} /></div>
          </div>
          <div className="form-group" style={{ marginBottom: 16 }}><label className="form-label">Description (optional)</label><input className="form-input" placeholder="Brief description..." value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} /></div>
          <div style={{ display: 'flex', gap: 8, justifyContent: 'flex-end' }}>
            <button className="btn btn-secondary" onClick={() => setShowForm(false)}>Cancel</button>
            <button className="btn btn-primary" onClick={save} disabled={saving || !form.name.trim()}>{saving ? <span className="spinner" style={{ width: 14, height: 14 }} /> : 'Create batch'}</button>
          </div>
        </div>
      )}
      {batches.length === 0 ? <div className="empty-state"><h3>No batches yet</h3><p>Create your first batch above.</p></div> : (
        <div className="card" style={{ padding: 0 }}>
          {batches.map((b, i) => (
            <div key={b.id} style={{ display: 'flex', alignItems: 'center', padding: '14px 20px', borderBottom: i < batches.length - 1 ? '1px solid var(--border-light)' : 'none' }}>
              <div style={{ flex: 1 }}><p style={{ fontSize: 14, fontWeight: 600, color: 'var(--navy)' }}>{b.name}</p>{b.description && <p style={{ fontSize: 12, color: 'var(--text-muted)', marginTop: 2 }}>{b.description}</p>}{b.start_date && <p style={{ fontSize: 12, color: 'var(--text-muted)', marginTop: 2 }}>Started: {new Date(b.start_date).toLocaleDateString()}</p>}</div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}><span className={`badge ${b.is_active ? 'badge-green' : 'badge-gray'}`}>{b.is_active ? 'Active' : 'Inactive'}</span><button className="btn btn-secondary btn-sm" onClick={() => toggleActive(b)}>{b.is_active ? 'Deactivate' : 'Activate'}</button></div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
EOF

# AdminTrainees
cat > src/pages/admin/AdminTrainees.js << 'EOF'
import { useEffect, useState, useRef } from 'react';
import { supabase } from '../../lib/supabase';
import { useToast } from '../../context/ToastContext';
import Avatar from '../../components/Avatar';
export default function AdminTrainees() {
  const [batches, setBatches] = useState([]);
  const [selectedBatch, setSelectedBatch] = useState('');
  const [trainees, setTrainees] = useState([]);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ name: '', employee_id: '', department: '', email: '' });
  const [photoFile, setPhotoFile] = useState(null);
  const [photoPreview, setPhotoPreview] = useState(null);
  const [saving, setSaving] = useState(false);
  const fileRef = useRef();
  const { addToast } = useToast();
  useEffect(() => { supabase.from('batches').select('id,name').order('created_at', { ascending: false }).then(({ data }) => { if (data) { setBatches(data); if (data.length > 0) setSelectedBatch(data[0].id); } }); }, []);
  useEffect(() => { if (selectedBatch) loadTrainees(); }, [selectedBatch]);
  async function loadTrainees() { const { data } = await supabase.from('trainees').select('*').eq('batch_id', selectedBatch).order('name'); if (data) setTrainees(data); }
  function handlePhoto(e) { const file = e.target.files[0]; if (!file) return; setPhotoFile(file); setPhotoPreview(URL.createObjectURL(file)); }
  async function save() {
    if (!form.name.trim() || !selectedBatch) return; setSaving(true);
    let photo_url = null;
    if (photoFile) {
      const ext = photoFile.name.split('.').pop();
      const path = `${selectedBatch}/${Date.now()}.${ext}`;
      const { error: upErr } = await supabase.storage.from('trainee-photos').upload(path, photoFile);
      if (!upErr) { const { data: urlData } = supabase.storage.from('trainee-photos').getPublicUrl(path); photo_url = urlData.publicUrl; }
    }
    const { error } = await supabase.from('trainees').insert({ batch_id: selectedBatch, name: form.name.trim(), employee_id: form.employee_id, department: form.department, email: form.email, photo_url });
    if (error) { addToast(error.message, 'error'); } else { addToast('Trainee added!'); setShowForm(false); setForm({ name: '', employee_id: '', department: '', email: '' }); setPhotoFile(null); setPhotoPreview(null); loadTrainees(); }
    setSaving(false);
  }
  async function toggleActive(t) { await supabase.from('trainees').update({ is_active: !t.is_active }).eq('id', t.id); loadTrainees(); }
  async function updatePhoto(traineeId, file) {
    const ext = file.name.split('.').pop(); const path = `${selectedBatch}/${traineeId}.${ext}`;
    const { error: upErr } = await supabase.storage.from('trainee-photos').upload(path, file, { upsert: true });
    if (upErr) { addToast('Photo upload failed', 'error'); return; }
    const { data: urlData } = supabase.storage.from('trainee-photos').getPublicUrl(path);
    await supabase.from('trainees').update({ photo_url: urlData.publicUrl }).eq('id', traineeId);
    addToast('Photo updated!'); loadTrainees();
  }
  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div><h2 style={{ fontFamily: 'var(--font-display)', fontSize: 20, color: 'var(--navy)' }}>Trainees</h2><p style={{ fontSize: 13, color: 'var(--text-muted)', marginTop: 2 }}>Add and manage trainees per batch</p></div>
        <button className="btn btn-primary" onClick={() => setShowForm(!showForm)}>+ Add trainee</button>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 20 }}>
        <label className="form-label" style={{ margin: 0, whiteSpace: 'nowrap' }}>Batch:</label>
        <select className="form-select" style={{ width: 'auto' }} value={selectedBatch} onChange={e => setSelectedBatch(e.target.value)}>{batches.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}</select>
        <span className="badge badge-navy">{trainees.length} trainees</span>
      </div>
      {showForm && (
        <div className="card" style={{ marginBottom: 20 }}>
          <p className="card-title">Add new trainee</p>
          <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 16 }}>
            <div onClick={() => fileRef.current.click()} style={{ cursor: 'pointer', position: 'relative' }}>
              {photoPreview ? <img src={photoPreview} alt="preview" style={{ width: 64, height: 64, borderRadius: '50%', objectFit: 'cover', border: '2px solid var(--border)' }} /> : <div style={{ width: 64, height: 64, borderRadius: '50%', background: 'var(--bg)', border: '2px dashed var(--border)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 11, color: 'var(--text-muted)', textAlign: 'center', lineHeight: 1.3 }}>Add photo</div>}
              <div style={{ position: 'absolute', bottom: 0, right: 0, width: 20, height: 20, background: 'var(--navy)', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '2px solid #fff' }}><span style={{ color: '#fff', fontSize: 10 }}>+</span></div>
            </div>
            <p style={{ fontSize: 12, color: 'var(--text-muted)' }}>Click to upload photo<br />(optional)</p>
            <input ref={fileRef} type="file" accept="image/*" style={{ display: 'none' }} onChange={handlePhoto} />
          </div>
          <div className="grid-2" style={{ marginBottom: 12 }}>
            <div className="form-group"><label className="form-label">Full name *</label><input className="form-input" placeholder="Full name" value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} /></div>
            <div className="form-group"><label className="form-label">Employee ID</label><input className="form-input" placeholder="e.g. CI189" value={form.employee_id} onChange={e => setForm({ ...form, employee_id: e.target.value })} /></div>
          </div>
          <div className="grid-2" style={{ marginBottom: 16 }}>
            <div className="form-group"><label className="form-label">Department</label><input className="form-input" placeholder="e.g. DE, DCG, AE" value={form.department} onChange={e => setForm({ ...form, department: e.target.value })} /></div>
            <div className="form-group"><label className="form-label">Email</label><input className="form-input" type="email" placeholder="email@company.com" value={form.email} onChange={e => setForm({ ...form, email: e.target.value })} /></div>
          </div>
          <div style={{ display: 'flex', gap: 8, justifyContent: 'flex-end' }}>
            <button className="btn btn-secondary" onClick={() => { setShowForm(false); setPhotoPreview(null); setPhotoFile(null); }}>Cancel</button>
            <button className="btn btn-primary" onClick={save} disabled={saving || !form.name.trim()}>{saving ? <span className="spinner" style={{ width: 14, height: 14 }} /> : 'Add trainee'}</button>
          </div>
        </div>
      )}
      {trainees.length === 0 ? <div className="empty-state"><h3>No trainees yet</h3><p>Add trainees to this batch above.</p></div> : (
        <div className="card" style={{ padding: 0 }}>
          {trainees.map((t, i) => (
            <div key={t.id} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 20px', borderBottom: i < trainees.length - 1 ? '1px solid var(--border-light)' : 'none' }}>
              <div style={{ position: 'relative', cursor: 'pointer' }} onClick={() => { const inp = document.createElement('input'); inp.type='file'; inp.accept='image/*'; inp.onchange=e=>updatePhoto(t.id, e.target.files[0]); inp.click(); }}>
                <Avatar name={t.name} photoUrl={t.photo_url} size={42} />
                <div style={{ position: 'absolute', bottom: -2, right: -2, width: 16, height: 16, background: 'var(--navy)', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '1.5px solid #fff' }}><span style={{ color: '#fff', fontSize: 9 }}>✎</span></div>
              </div>
              <div style={{ flex: 1 }}><p style={{ fontSize: 13, fontWeight: 600, color: 'var(--navy)' }}>{t.name}</p><p style={{ fontSize: 11, color: 'var(--text-muted)' }}>{[t.employee_id, t.department, t.email].filter(Boolean).join(' · ')}</p></div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}><span className={`badge ${t.is_active ? 'badge-green' : 'badge-gray'}`}>{t.is_active ? 'Active' : 'Inactive'}</span><button className="btn btn-secondary btn-sm" onClick={() => toggleActive(t)}>{t.is_active ? 'Deactivate' : 'Activate'}</button></div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
EOF

echo "ADMIN PAGES 2 DONE"
#!/bin/bash
set -e

# AdminCategories
cat > src/pages/admin/AdminCategories.js << 'EOF'
import { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { useToast } from '../../context/ToastContext';
const TYPE_INFO = { points: { label: 'Points', badge: 'badge-navy', desc: 'Named items with scores' }, streak: { label: 'Streak', badge: 'badge-amber', desc: 'Daily completion tracking' }, display: { label: 'Display only', badge: 'badge-gray', desc: 'Shown on profile, never scored' } };
export default function AdminCategories() {
  const [batches, setBatches] = useState([]); const [selectedBatch, setSelectedBatch] = useState(''); const [categories, setCategories] = useState([]); const [showForm, setShowForm] = useState(false); const [form, setForm] = useState({ name: '', type: 'points', include_in_overall: true }); const [saving, setSaving] = useState(false); const { addToast } = useToast();
  useEffect(() => { supabase.from('batches').select('id,name').order('created_at', { ascending: false }).then(({ data }) => { if (data) { setBatches(data); if (data.length > 0) setSelectedBatch(data[0].id); } }); }, []);
  useEffect(() => { if (selectedBatch) load(); }, [selectedBatch]);
  async function load() { const { data } = await supabase.from('categories').select('*').eq('batch_id', selectedBatch).order('sort_order'); if (data) setCategories(data); }
  function handleTypeChange(type) { setForm({ ...form, type, include_in_overall: type !== 'display' }); }
  async function save() {
    if (!form.name.trim() || !selectedBatch) return; setSaving(true);
    const maxOrder = categories.length > 0 ? Math.max(...categories.map(c => c.sort_order)) + 1 : 0;
    const { error } = await supabase.from('categories').insert({ batch_id: selectedBatch, name: form.name.trim(), type: form.type, include_in_overall: form.include_in_overall, sort_order: maxOrder });
    if (error) { addToast(error.message, 'error'); } else { addToast('Category created! It will now appear on the leaderboard.'); setShowForm(false); setForm({ name: '', type: 'points', include_in_overall: true }); load(); }
    setSaving(false);
  }
  async function toggleOverall(cat) { await supabase.from('categories').update({ include_in_overall: !cat.include_in_overall }).eq('id', cat.id); addToast(`"${cat.name}" updated`); load(); }
  async function deleteCategory(cat) { if (!window.confirm(`Delete "${cat.name}"? All scores will also be deleted.`)) return; await supabase.from('categories').delete().eq('id', cat.id); addToast('Category deleted'); load(); }
  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div><h2 style={{ fontFamily: 'var(--font-display)', fontSize: 20, color: 'var(--navy)' }}>Categories</h2><p style={{ fontSize: 13, color: 'var(--text-muted)', marginTop: 2 }}>Add new scoring dimensions anytime</p></div>
        <button className="btn btn-primary" onClick={() => setShowForm(!showForm)}>+ Add category</button>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 20 }}>
        <label className="form-label" style={{ margin: 0 }}>Batch:</label>
        <select className="form-select" style={{ width: 'auto' }} value={selectedBatch} onChange={e => setSelectedBatch(e.target.value)}>{batches.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}</select>
      </div>
      {showForm && (
        <div className="card" style={{ marginBottom: 20 }}>
          <p className="card-title">New category</p>
          <div className="form-group" style={{ marginBottom: 16 }}><label className="form-label">Category name *</label><input className="form-input" placeholder="e.g. Assessment, Public Speaking..." value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} /></div>
          <div className="form-group" style={{ marginBottom: 16 }}>
            <label className="form-label">Type</label>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 8 }}>
              {Object.entries(TYPE_INFO).map(([type, info]) => (
                <div key={type} onClick={() => handleTypeChange(type)} style={{ padding: 12, borderRadius: 'var(--radius-md)', cursor: 'pointer', border: `2px solid ${form.type === type ? 'var(--navy)' : 'var(--border)'}`, background: form.type === type ? 'var(--navy-light)' : 'var(--surface)' }}>
                  <p style={{ fontSize: 13, fontWeight: 600, color: form.type === type ? 'var(--navy)' : 'var(--text-primary)', marginBottom: 3 }}>{info.label}</p>
                  <p style={{ fontSize: 11, color: 'var(--text-muted)', lineHeight: 1.4 }}>{info.desc}</p>
                </div>
              ))}
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 16 }}>
            <div className={`toggle ${form.include_in_overall ? 'on' : ''}`} onClick={() => setForm({ ...form, include_in_overall: !form.include_in_overall })} />
            <div><p style={{ fontSize: 13, fontWeight: 500 }}>Include in overall score</p><p style={{ fontSize: 11, color: 'var(--text-muted)' }}>{form.include_in_overall ? 'Will affect leaderboard rankings' : 'Shown but not counted in totals'}</p></div>
          </div>
          <div style={{ display: 'flex', gap: 8, justifyContent: 'flex-end' }}>
            <button className="btn btn-secondary" onClick={() => setShowForm(false)}>Cancel</button>
            <button className="btn btn-primary" onClick={save} disabled={saving || !form.name.trim()}>{saving ? <span className="spinner" style={{ width: 14, height: 14 }} /> : 'Create category'}</button>
          </div>
        </div>
      )}
      {categories.length === 0 ? <div className="empty-state"><h3>No categories yet</h3><p>Add your first scoring category above.</p></div> : (
        <div className="card" style={{ padding: 0 }}>
          {categories.map((cat, i) => (
            <div key={cat.id} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '14px 20px', borderBottom: i < categories.length - 1 ? '1px solid var(--border-light)' : 'none' }}>
              <div style={{ flex: 1 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}><p style={{ fontSize: 14, fontWeight: 600, color: 'var(--navy)' }}>{cat.name}</p><span className={`badge ${TYPE_INFO[cat.type]?.badge}`}>{TYPE_INFO[cat.type]?.label}</span>{cat.include_in_overall && <span className="badge badge-teal">Counts in overall</span>}</div>
                <p style={{ fontSize: 11, color: 'var(--text-muted)' }}>{TYPE_INFO[cat.type]?.desc}</p>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                {cat.type !== 'display' && <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}><div className={`toggle ${cat.include_in_overall ? 'on' : ''}`} onClick={() => toggleOverall(cat)} style={{ transform: 'scale(0.85)' }} /><span style={{ fontSize: 11, color: 'var(--text-muted)' }}>Overall</span></div>}
                <button className="btn btn-danger btn-sm" onClick={() => deleteCategory(cat)}>Delete</button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
EOF

# AdminScores
cat > src/pages/admin/AdminScores.js << 'EOF'
import { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { useToast } from '../../context/ToastContext';
export default function AdminScores() {
  const [batches, setBatches] = useState([]); const [selectedBatch, setSelectedBatch] = useState(''); const [categories, setCategories] = useState([]); const [selectedCat, setSelectedCat] = useState(''); const [items, setItems] = useState([]); const [selectedItem, setSelectedItem] = useState(''); const [trainees, setTrainees] = useState([]); const [scores, setScores] = useState({}); const [subScores, setSubScores] = useState({}); const [showItemForm, setShowItemForm] = useState(false); const [itemForm, setItemForm] = useState({ name: '', max_score: '', has_submission_score: false, submission_max: '' }); const [saving, setSaving] = useState(false); const [savingItem, setSavingItem] = useState(false); const { addToast } = useToast();
  useEffect(() => { supabase.from('batches').select('id,name').order('created_at', { ascending: false }).then(({ data }) => { if (data) { setBatches(data); if (data[0]) setSelectedBatch(data[0].id); } }); }, []);
  useEffect(() => { if (!selectedBatch) return; supabase.from('categories').select('*').eq('batch_id', selectedBatch).eq('type', 'points').order('sort_order').then(({ data }) => { if (data) { setCategories(data); setSelectedCat(data[0]?.id || ''); } }); supabase.from('trainees').select('*').eq('batch_id', selectedBatch).eq('is_active', true).order('name').then(({ data }) => { if (data) setTrainees(data); }); }, [selectedBatch]);
  useEffect(() => { if (!selectedCat) return; supabase.from('category_items').select('*').eq('category_id', selectedCat).order('sort_order').then(({ data }) => { if (data) { setItems(data); setSelectedItem(data[0]?.id || ''); } }); }, [selectedCat]);
  useEffect(() => { if (!selectedItem || trainees.length === 0) return; supabase.from('scores').select('*').eq('item_id', selectedItem).then(({ data }) => { const s = {}, sub = {}; if (data) data.forEach(r => { s[r.trainee_id] = r.score ?? ''; sub[r.trainee_id] = r.submission_score ?? ''; }); setScores(s); setSubScores(sub); }); }, [selectedItem, trainees]);
  const currentItem = items.find(i => i.id === selectedItem);
  const currentCat = categories.find(c => c.id === selectedCat);
  async function addItem() {
    if (!itemForm.name.trim()) return; setSavingItem(true);
    const maxOrder = items.length > 0 ? Math.max(...items.map(i => i.sort_order)) + 1 : 0;
    const { data, error } = await supabase.from('category_items').insert({ category_id: selectedCat, name: itemForm.name.trim(), max_score: itemForm.max_score ? Number(itemForm.max_score) : null, has_submission_score: itemForm.has_submission_score, submission_max: itemForm.submission_max ? Number(itemForm.submission_max) : null, sort_order: maxOrder }).select().single();
    if (error) { addToast(error.message, 'error'); } else { addToast('Item added!'); setShowItemForm(false); setItemForm({ name: '', max_score: '', has_submission_score: false, submission_max: '' }); const { data: newItems } = await supabase.from('category_items').select('*').eq('category_id', selectedCat).order('sort_order'); if (newItems) { setItems(newItems); setSelectedItem(data.id); } }
    setSavingItem(false);
  }
  async function saveScores() {
    if (!selectedItem) return; setSaving(true);
    const upserts = trainees.map(t => ({ trainee_id: t.id, item_id: selectedItem, score: scores[t.id] !== '' && scores[t.id] != null ? Number(scores[t.id]) : null, submission_score: currentItem?.has_submission_score && subScores[t.id] !== '' && subScores[t.id] != null ? Number(subScores[t.id]) : null }));
    const { error } = await supabase.from('scores').upsert(upserts, { onConflict: 'trainee_id,item_id' });
    if (error) { addToast(error.message, 'error'); } else { addToast('Scores saved! Leaderboard updated.'); }
    setSaving(false);
  }
  return (
    <div>
      <div style={{ marginBottom: 24 }}><h2 style={{ fontFamily: 'var(--font-display)', fontSize: 20, color: 'var(--navy)' }}>Enter scores</h2><p style={{ fontSize: 13, color: 'var(--text-muted)', marginTop: 2 }}>Select a batch, category, and item to enter scores</p></div>
      <div className="card" style={{ marginBottom: 20 }}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 12 }}>
          <div className="form-group"><label className="form-label">Batch</label><select className="form-select" value={selectedBatch} onChange={e => setSelectedBatch(e.target.value)}>{batches.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}</select></div>
          <div className="form-group"><label className="form-label">Category</label><select className="form-select" value={selectedCat} onChange={e => setSelectedCat(e.target.value)}>{categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}</select></div>
          <div className="form-group"><label className="form-label">Item</label><select className="form-select" value={selectedItem} onChange={e => setSelectedItem(e.target.value)}>{items.map(i => <option key={i.id} value={i.id}>{i.name}</option>)}</select></div>
        </div>
        {currentCat && <div style={{ marginTop: 12, display: 'flex', justifyContent: 'flex-end' }}><button className="btn btn-secondary btn-sm" onClick={() => setShowItemForm(!showItemForm)}>+ Add new item to "{currentCat.name}"</button></div>}
      </div>
      {showItemForm && (
        <div className="card" style={{ marginBottom: 20 }}>
          <p className="card-title">New item for "{currentCat?.name}"</p>
          <div className="form-group" style={{ marginBottom: 12 }}><label className="form-label">Item name *</label><input className="form-input" placeholder="e.g. Day 7 Assessment, Task 3 — Python" value={itemForm.name} onChange={e => setItemForm({ ...itemForm, name: e.target.value })} /></div>
          <div className="grid-2" style={{ marginBottom: 12 }}><div className="form-group"><label className="form-label">Max score (optional)</label><input className="form-input" type="number" placeholder="e.g. 100" value={itemForm.max_score} onChange={e => setItemForm({ ...itemForm, max_score: e.target.value })} /></div></div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: itemForm.has_submission_score ? 12 : 16 }}>
            <div className={`toggle ${itemForm.has_submission_score ? 'on' : ''}`} onClick={() => setItemForm({ ...itemForm, has_submission_score: !itemForm.has_submission_score })} />
            <div><p style={{ fontSize: 13, fontWeight: 500 }}>Track submission score separately</p><p style={{ fontSize: 11, color: 'var(--text-muted)' }}>Enable dual scoring: submission + task score</p></div>
          </div>
          {itemForm.has_submission_score && <div className="form-group" style={{ marginBottom: 16, maxWidth: 200 }}><label className="form-label">Submission max (optional)</label><input className="form-input" type="number" placeholder="e.g. 50" value={itemForm.submission_max} onChange={e => setItemForm({ ...itemForm, submission_max: e.target.value })} /></div>}
          <div style={{ display: 'flex', gap: 8, justifyContent: 'flex-end' }}><button className="btn btn-secondary" onClick={() => setShowItemForm(false)}>Cancel</button><button className="btn btn-primary" onClick={addItem} disabled={savingItem || !itemForm.name.trim()}>{savingItem ? <span className="spinner" style={{ width: 14, height: 14 }} /> : 'Add item'}</button></div>
        </div>
      )}
      {selectedItem && trainees.length > 0 && currentItem && (
        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
            <div><p style={{ fontSize: 15, fontWeight: 600, color: 'var(--navy)' }}>{currentItem.name}</p><p style={{ fontSize: 12, color: 'var(--text-muted)' }}>{currentItem.max_score ? `Max: ${currentItem.max_score}` : 'No fixed max'}{currentItem.has_submission_score && ` · Dual score (Sub max: ${currentItem.submission_max || '—'})`}</p></div>
            <button className="btn btn-primary" onClick={saveScores} disabled={saving}>{saving ? <span className="spinner" style={{ width: 14, height: 14 }} /> : 'Save all scores'}</button>
          </div>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead><tr style={{ borderBottom: '1px solid var(--border)' }}>
              <th style={{ textAlign: 'left', padding: 8, fontSize: 11, color: 'var(--text-muted)', fontWeight: 600 }}>Trainee</th>
              {currentItem.has_submission_score && <th style={{ textAlign: 'center', padding: 8, fontSize: 11, color: 'var(--text-muted)', fontWeight: 600 }}>Submission {currentItem.submission_max ? `(/${currentItem.submission_max})` : ''}</th>}
              <th style={{ textAlign: 'center', padding: 8, fontSize: 11, color: 'var(--text-muted)', fontWeight: 600 }}>Score {currentItem.max_score ? `(/${currentItem.max_score})` : ''}</th>
            </tr></thead>
            <tbody>{trainees.map(t => (
              <tr key={t.id} style={{ borderBottom: '1px solid var(--border-light)' }}>
                <td style={{ padding: '10px 8px' }}><div style={{ display: 'flex', alignItems: 'center', gap: 8 }}><div style={{ width: 28, height: 28, borderRadius: '50%', background: 'var(--navy-light)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 10, fontWeight: 600, color: 'var(--navy)', flexShrink: 0 }}>{t.name.split(' ').map(p => p[0]).join('').substring(0, 2).toUpperCase()}</div><span style={{ fontSize: 13, fontWeight: 500 }}>{t.name}</span></div></td>
                {currentItem.has_submission_score && <td style={{ padding: '10px 8px', textAlign: 'center' }}><input type="number" min="0" style={{ width: 80, padding: '6px 8px', border: '1px solid var(--border)', borderRadius: 8, fontSize: 13, textAlign: 'center', fontFamily: 'var(--font-body)' }} placeholder="—" value={subScores[t.id] ?? ''} onChange={e => setSubScores({ ...subScores, [t.id]: e.target.value })} /></td>}
                <td style={{ padding: '10px 8px', textAlign: 'center' }}><input type="number" min="0" style={{ width: 80, padding: '6px 8px', border: '1px solid var(--border)', borderRadius: 8, fontSize: 13, textAlign: 'center', fontFamily: 'var(--font-body)' }} placeholder="—" value={scores[t.id] ?? ''} onChange={e => setScores({ ...scores, [t.id]: e.target.value })} /></td>
              </tr>
            ))}</tbody>
          </table>
          <div style={{ marginTop: 16, display: 'flex', justifyContent: 'flex-end' }}><button className="btn btn-primary" onClick={saveScores} disabled={saving}>{saving ? <span className="spinner" style={{ width: 14, height: 14 }} /> : 'Save all scores'}</button></div>
        </div>
      )}
      {categories.length === 0 && <div className="empty-state"><h3>No categories yet</h3><p>Add categories first before entering scores.</p></div>}
    </div>
  );
}
EOF

echo "ADMIN PAGES 3 DONE"
#!/bin/bash
set -e

# AdminStreaks
cat > src/pages/admin/AdminStreaks.js << 'EOF'
import { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { useToast } from '../../context/ToastContext';
import { format } from 'date-fns';
export default function AdminStreaks() {
  const [batches, setBatches] = useState([]); const [selectedBatch, setSelectedBatch] = useState(''); const [streakCats, setStreakCats] = useState([]); const [selectedCat, setSelectedCat] = useState(''); const [trainees, setTrainees] = useState([]); const [entries, setEntries] = useState({}); const [selectedDate, setSelectedDate] = useState(format(new Date(), 'yyyy-MM-dd')); const [saving, setSaving] = useState(false); const { addToast } = useToast();
  useEffect(() => { supabase.from('batches').select('id,name').order('created_at', { ascending: false }).then(({ data }) => { if (data) { setBatches(data); if (data[0]) setSelectedBatch(data[0].id); } }); }, []);
  useEffect(() => { if (!selectedBatch) return; supabase.from('categories').select('*').eq('batch_id', selectedBatch).eq('type', 'streak').then(({ data }) => { if (data) { setStreakCats(data); setSelectedCat(data[0]?.id || ''); } }); supabase.from('trainees').select('*').eq('batch_id', selectedBatch).eq('is_active', true).order('name').then(({ data }) => { if (data) setTrainees(data); }); }, [selectedBatch]);
  useEffect(() => { if (selectedCat && selectedDate) loadEntries(); }, [selectedCat, selectedDate, trainees]);
  async function loadEntries() { const { data } = await supabase.from('streak_entries').select('*').eq('category_id', selectedCat).eq('entry_date', selectedDate); const map = {}; if (data) data.forEach(e => { map[e.trainee_id] = e.completed; }); setEntries(map); }
  async function saveEntries() {
    if (!selectedCat || !selectedDate) return; setSaving(true);
    const upserts = trainees.map(t => ({ trainee_id: t.id, category_id: selectedCat, entry_date: selectedDate, completed: !!entries[t.id] }));
    const { error } = await supabase.from('streak_entries').upsert(upserts, { onConflict: 'trainee_id,category_id,entry_date' });
    if (error) { addToast(error.message, 'error'); } else { addToast('Streak entries saved!'); }
    setSaving(false);
  }
  const currentCat = streakCats.find(c => c.id === selectedCat);
  const completedCount = trainees.filter(t => entries[t.id]).length;
  return (
    <div>
      <div style={{ marginBottom: 24 }}><h2 style={{ fontFamily: 'var(--font-display)', fontSize: 20, color: 'var(--navy)' }}>Streaks</h2><p style={{ fontSize: 13, color: 'var(--text-muted)', marginTop: 2 }}>Mark daily streak completion — enter any date, no gaps required</p></div>
      <div className="card" style={{ marginBottom: 20 }}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 12 }}>
          <div className="form-group"><label className="form-label">Batch</label><select className="form-select" value={selectedBatch} onChange={e => setSelectedBatch(e.target.value)}>{batches.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}</select></div>
          <div className="form-group"><label className="form-label">Streak app</label><select className="form-select" value={selectedCat} onChange={e => setSelectedCat(e.target.value)}>{streakCats.length === 0 ? <option value="">No streak categories</option> : streakCats.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}</select></div>
          <div className="form-group"><label className="form-label">Date</label><input className="form-input" type="date" value={selectedDate} onChange={e => setSelectedDate(e.target.value)} /></div>
        </div>
      </div>
      {streakCats.length === 0 ? <div className="empty-state"><h3>No streak categories</h3><p>Add a streak-type category first.</p></div> : selectedCat && trainees.length > 0 ? (
        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
            <div><p style={{ fontSize: 15, fontWeight: 600, color: 'var(--navy)' }}>{currentCat?.name} — {format(new Date(selectedDate + 'T00:00:00'), 'dd MMM yyyy')}</p><p style={{ fontSize: 12, color: 'var(--text-muted)' }}>{completedCount} of {trainees.length} completed</p></div>
            <div style={{ display: 'flex', gap: 8 }}>
              <button className="btn btn-secondary btn-sm" onClick={() => { const all = {}; trainees.forEach(t => { all[t.id] = true; }); setEntries(all); }}>Mark all</button>
              <button className="btn btn-secondary btn-sm" onClick={() => setEntries({})}>Clear all</button>
              <button className="btn btn-primary btn-sm" onClick={saveEntries} disabled={saving}>{saving ? <span className="spinner" style={{ width: 14, height: 14 }} /> : 'Save'}</button>
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2,1fr)', gap: 8 }}>
            {trainees.map(t => (
              <div key={t.id} onClick={() => setEntries({ ...entries, [t.id]: !entries[t.id] })} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px', borderRadius: 'var(--radius-md)', cursor: 'pointer', border: `2px solid ${entries[t.id] ? 'var(--teal)' : 'var(--border)'}`, background: entries[t.id] ? 'var(--teal-light)' : 'var(--bg)' }}>
                <div style={{ width: 24, height: 24, borderRadius: 6, flexShrink: 0, background: entries[t.id] ? 'var(--teal)' : 'var(--border)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{entries[t.id] && <span style={{ color: '#fff', fontSize: 13 }}>✓</span>}</div>
                <div><p style={{ fontSize: 13, fontWeight: 600, color: entries[t.id] ? 'var(--teal)' : 'var(--text-primary)' }}>{t.name}</p>{t.department && <p style={{ fontSize: 11, color: 'var(--text-muted)' }}>{t.department}</p>}</div>
                {entries[t.id] && <span style={{ marginLeft: 'auto', fontSize: 16 }}>🔥</span>}
              </div>
            ))}
          </div>
          <div style={{ marginTop: 16, display: 'flex', justifyContent: 'flex-end' }}><button className="btn btn-primary" onClick={saveEntries} disabled={saving}>{saving ? <span className="spinner" style={{ width: 14, height: 14 }} /> : 'Save streak entries'}</button></div>
        </div>
      ) : null}
    </div>
  );
}
EOF

# AdminAttendance
cat > src/pages/admin/AdminAttendance.js << 'EOF'
import { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { useToast } from '../../context/ToastContext';
import { format } from 'date-fns';
export default function AdminAttendance() {
  const [batches, setBatches] = useState([]); const [selectedBatch, setSelectedBatch] = useState(''); const [trainees, setTrainees] = useState([]); const [entries, setEntries] = useState({}); const [selectedDate, setSelectedDate] = useState(format(new Date(), 'yyyy-MM-dd')); const [saving, setSaving] = useState(false); const { addToast } = useToast();
  useEffect(() => { supabase.from('batches').select('id,name').order('created_at', { ascending: false }).then(({ data }) => { if (data) { setBatches(data); if (data[0]) setSelectedBatch(data[0].id); } }); }, []);
  useEffect(() => { if (!selectedBatch) return; supabase.from('trainees').select('*').eq('batch_id', selectedBatch).eq('is_active', true).order('name').then(({ data }) => { if (data) setTrainees(data); }); }, [selectedBatch]);
  useEffect(() => { if (selectedDate && trainees.length > 0) loadEntries(); }, [selectedDate, trainees]);
  async function loadEntries() { const ids = trainees.map(t => t.id); const { data } = await supabase.from('attendance').select('*').in('trainee_id', ids).eq('entry_date', selectedDate); const map = {}; trainees.forEach(t => { map[t.id] = true; }); if (data) data.forEach(e => { map[e.trainee_id] = e.present; }); setEntries(map); }
  async function save() {
    setSaving(true);
    const upserts = trainees.map(t => ({ trainee_id: t.id, entry_date: selectedDate, present: entries[t.id] !== false }));
    const { error } = await supabase.from('attendance').upsert(upserts, { onConflict: 'trainee_id,entry_date' });
    if (error) { addToast(error.message, 'error'); } else { addToast('Attendance saved!'); }
    setSaving(false);
  }
  const presentCount = trainees.filter(t => entries[t.id] !== false).length;
  return (
    <div>
      <div style={{ marginBottom: 24 }}><h2 style={{ fontFamily: 'var(--font-display)', fontSize: 20, color: 'var(--navy)' }}>Attendance</h2><p style={{ fontSize: 13, color: 'var(--text-muted)', marginTop: 2 }}>Mark daily attendance — not scored, shown on trainee profiles</p></div>
      <div className="card" style={{ marginBottom: 20 }}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
          <div className="form-group"><label className="form-label">Batch</label><select className="form-select" value={selectedBatch} onChange={e => setSelectedBatch(e.target.value)}>{batches.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}</select></div>
          <div className="form-group"><label className="form-label">Date</label><input className="form-input" type="date" value={selectedDate} onChange={e => setSelectedDate(e.target.value)} /></div>
        </div>
      </div>
      {trainees.length > 0 && (
        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
            <div><p style={{ fontSize: 15, fontWeight: 600, color: 'var(--navy)' }}>{format(new Date(selectedDate + 'T00:00:00'), 'EEEE, dd MMM yyyy')}</p><p style={{ fontSize: 12, color: 'var(--text-muted)' }}><span style={{ color: 'var(--teal)', fontWeight: 600 }}>{presentCount} present</span> · <span style={{ color: '#B91C1C', fontWeight: 600 }}>{trainees.length - presentCount} absent</span></p></div>
            <div style={{ display: 'flex', gap: 8 }}>
              <button className="btn btn-secondary btn-sm" onClick={() => { const all = {}; trainees.forEach(t => { all[t.id] = true; }); setEntries(all); }}>All present</button>
              <button className="btn btn-secondary btn-sm" onClick={() => { const all = {}; trainees.forEach(t => { all[t.id] = false; }); setEntries(all); }}>All absent</button>
              <button className="btn btn-primary btn-sm" onClick={save} disabled={saving}>{saving ? <span className="spinner" style={{ width: 14, height: 14 }} /> : 'Save'}</button>
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2,1fr)', gap: 8 }}>
            {trainees.map(t => { const present = entries[t.id] !== false; return (
              <div key={t.id} onClick={() => setEntries({ ...entries, [t.id]: !present })} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px', borderRadius: 'var(--radius-md)', cursor: 'pointer', border: `2px solid ${present ? 'var(--teal)' : '#FCA5A5'}`, background: present ? 'var(--teal-light)' : '#FFF5F5' }}>
                <div style={{ width: 24, height: 24, borderRadius: 6, flexShrink: 0, background: present ? 'var(--teal)' : '#EF4444', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><span style={{ color: '#fff', fontSize: 13 }}>{present ? '✓' : '✗'}</span></div>
                <div><p style={{ fontSize: 13, fontWeight: 600, color: present ? 'var(--teal)' : '#B91C1C' }}>{t.name}</p>{t.department && <p style={{ fontSize: 11, color: 'var(--text-muted)' }}>{t.department}</p>}</div>
                <span style={{ marginLeft: 'auto', fontSize: 12, fontWeight: 600, color: present ? 'var(--teal)' : '#B91C1C' }}>{present ? 'Present' : 'Absent'}</span>
              </div>
            ); })}
          </div>
          <div style={{ marginTop: 16, display: 'flex', justifyContent: 'flex-end' }}><button className="btn btn-primary" onClick={save} disabled={saving}>{saving ? <span className="spinner" style={{ width: 14, height: 14 }} /> : 'Save attendance'}</button></div>
        </div>
      )}
    </div>
  );
}
EOF

# AdminExport
cat > src/pages/admin/AdminExport.js << 'EOF'
import { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { useToast } from '../../context/ToastContext';
export default function AdminExport() {
  const [batches, setBatches] = useState([]); const [selectedBatch, setSelectedBatch] = useState(''); const [exporting, setExporting] = useState(false); const { addToast } = useToast();
  useEffect(() => { supabase.from('batches').select('id,name').order('created_at', { ascending: false }).then(({ data }) => { if (data) { setBatches(data); if (data[0]) setSelectedBatch(data[0].id); } }); }, []);
  async function exportCSV() {
    if (!selectedBatch) return; setExporting(true);
    try {
      const [overallRes, catRes] = await Promise.all([supabase.from('trainee_overall_scores').select('*').eq('batch_id', selectedBatch).order('overall_score', { ascending: false }), supabase.from('trainee_category_scores').select('*').eq('batch_id', selectedBatch)]);
      const overall = overallRes.data || []; const catScores = catRes.data || []; const catNames = [...new Set(catScores.map(c => c.category_name))];
      const rows = overall.map((t, i) => { const row = { Rank: i + 1, Name: t.trainee_name, Department: t.department || '', 'Total Score': t.overall_score }; catNames.forEach(cat => { const cs = catScores.find(c => c.trainee_id === t.trainee_id && c.category_name === cat); row[cat] = cs ? cs.category_score : 0; }); return row; });
      const headers = Object.keys(rows[0] || {}); const csv = [headers.join(','), ...rows.map(r => headers.map(h => `"${r[h] ?? ''}"`).join(','))].join('\n');
      const blob = new Blob([csv], { type: 'text/csv' }); const url = URL.createObjectURL(blob); const a = document.createElement('a'); a.href = url;
      const batchName = batches.find(b => b.id === selectedBatch)?.name || 'batch'; a.download = `${batchName.replace(/\s+/g, '_')}_leaderboard.csv`; a.click(); URL.revokeObjectURL(url);
      addToast('CSV exported!');
    } catch (e) { addToast('Export failed', 'error'); }
    setExporting(false);
  }
  return (
    <div>
      <div style={{ marginBottom: 24 }}><h2 style={{ fontFamily: 'var(--font-display)', fontSize: 20, color: 'var(--navy)' }}>Export</h2><p style={{ fontSize: 13, color: 'var(--text-muted)', marginTop: 2 }}>Download leaderboard data as CSV</p></div>
      <div className="card" style={{ maxWidth: 480 }}>
        <p className="card-title">Export leaderboard</p>
        <div className="form-group" style={{ marginBottom: 16 }}><label className="form-label">Select batch</label><select className="form-select" value={selectedBatch} onChange={e => setSelectedBatch(e.target.value)}>{batches.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}</select></div>
        <p style={{ fontSize: 12, color: 'var(--text-muted)', marginBottom: 16 }}>Exports: Rank, Name, Department, Total Score, and score per category.</p>
        <button className="btn btn-primary" onClick={exportCSV} disabled={exporting || !selectedBatch}>{exporting ? <span className="spinner" style={{ width: 14, height: 14 }} /> : '↓ Download CSV'}</button>
      </div>
    </div>
  );
}
EOF

# App.js
cat > src/App.js << 'EOF'
import { useEffect, useState } from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import { ToastProvider } from './context/ToastContext';
import Topbar from './components/Topbar';
import LeaderboardPage from './pages/LeaderboardPage';
import TraineePage from './pages/TraineePage';
import AdminLogin from './pages/AdminLogin';
import AdminLayout from './pages/AdminLayout';
import AdminDashboard from './pages/admin/AdminDashboard';
import AdminBatches from './pages/admin/AdminBatches';
import AdminTrainees from './pages/admin/AdminTrainees';
import AdminCategories from './pages/admin/AdminCategories';
import AdminScores from './pages/admin/AdminScores';
import AdminStreaks from './pages/admin/AdminStreaks';
import AdminAttendance from './pages/admin/AdminAttendance';
import AdminExport from './pages/admin/AdminExport';
import { supabase } from './lib/supabase';
import './styles/global.css';
function PublicLayout() {
  const [selectedBatch, setSelectedBatch] = useState(null);
  useEffect(() => { supabase.from('batches').select('id,name').eq('is_active', true).order('created_at', { ascending: false }).limit(1).then(({ data }) => { if (data && data[0]) setSelectedBatch(data[0]); }); }, []);
  return (<><Topbar selectedBatch={selectedBatch} onBatchChange={setSelectedBatch} /><Routes><Route path="/" element={<LeaderboardPage batch={selectedBatch} />} /><Route path="/trainee/:id" element={<TraineePage />} /></Routes></>);
}
function AdminRoutes() {
  return (<><Topbar /><Routes><Route path="login" element={<AdminLogin />} /><Route path="" element={<AdminLayout />}><Route index element={<AdminDashboard />} /><Route path="batches" element={<AdminBatches />} /><Route path="trainees" element={<AdminTrainees />} /><Route path="categories" element={<AdminCategories />} /><Route path="scores" element={<AdminScores />} /><Route path="streaks" element={<AdminStreaks />} /><Route path="attendance" element={<AdminAttendance />} /><Route path="export" element={<AdminExport />} /></Route></Routes></>);
}
export default function App() {
  return (<BrowserRouter><AuthProvider><ToastProvider><Routes><Route path="/admin/*" element={<AdminRoutes />} /><Route path="/*" element={<PublicLayout />} /></Routes></ToastProvider></AuthProvider></BrowserRouter>);
}
EOF

# index.js
cat > src/index.js << 'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<React.StrictMode><App /></React.StrictMode>);
EOF

# Clean up default files
rm -f src/App.css src/App.test.js src/logo.svg src/reportWebVitals.js src/setupTests.js

echo "ALL FILES DONE"

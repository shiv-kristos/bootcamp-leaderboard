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

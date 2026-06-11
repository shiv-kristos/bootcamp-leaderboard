import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import Avatar from '../components/Avatar';
import { format, parseISO } from 'date-fns';
const SUB_COLORS = { 'Extra project': { bg: '#EEF1FB', color: '#1B2A5E' }, 'External event': { bg: '#E0F2F1', color: '#00695C' }, 'External webinar': { bg: '#F3E5F5', color: '#6A1B9A' }, 'Extra course': { bg: '#FFF8E1', color: '#E65100' }, 'Expert session': { bg: '#FCE4EC', color: '#880E4F' } };
export default function TraineePage() {
  const { id } = useParams(); const navigate = useNavigate();
  const [trainee, setTrainee] = useState(null); const [categoryScores, setCategoryScores] = useState([]); const [itemScores, setItemScores] = useState([]); const [attendance, setAttendance] = useState([]); const [attendanceSummary, setAttendanceSummary] = useState(null); const [streaks, setStreaks] = useState([]); const [rank, setRank] = useState(null); const [abEntries, setAbEntries] = useState([]); const [loading, setLoading] = useState(true);
  useEffect(() => { loadData(); }, [id]);
  async function loadData() {
    setLoading(true);
    const [traineeRes, catRes, itemsRes, attRes, attSumRes, streakRes, abRes] = await Promise.all([
      supabase.from('trainees').select('*').eq('id', id).single(),
      supabase.from('trainee_category_scores').select('*').eq('trainee_id', id),
      supabase.from('scores').select('*, category_items(name, max_score, has_submission_score, categories(name, type))').eq('trainee_id', id),
      supabase.from('attendance').select('*').eq('trainee_id', id).order('entry_date'),
      supabase.from('trainee_attendance_summary').select('*').eq('trainee_id', id).single(),
      supabase.from('streak_entries').select('*, categories(name)').eq('trainee_id', id).order('entry_date'),
      supabase.from('above_and_beyond').select('*').eq('trainee_id', id).order('created_at', { ascending: false }),
    ]);
    if (traineeRes.data) { setTrainee(traineeRes.data); const rankRes = await supabase.from('trainee_overall_scores').select('trainee_id').eq('batch_id', traineeRes.data.batch_id).order('overall_score', { ascending: false }); if (rankRes.data) setRank(rankRes.data.findIndex(t => t.trainee_id === id) + 1); }
    if (catRes.data) setCategoryScores(catRes.data.filter(c => c.category_type !== 'display'));
    if (itemsRes.data) setItemScores(itemsRes.data);
    if (attRes.data) setAttendance(attRes.data);
    if (attSumRes.data) setAttendanceSummary(attSumRes.data);
    if (streakRes.data) { const grouped = {}; streakRes.data.forEach(e => { const name = e.categories?.name || 'Streak'; if (!grouped[name]) grouped[name] = []; grouped[name].push(e); }); setStreaks(Object.entries(grouped).map(([name, entries]) => ({ name, total: entries.filter(e => e.completed).length, entries }))); }
    if (abRes.data) setAbEntries(abRes.data);
    setLoading(false);
  }
  if (loading) return <div className="page-loading"><div className="spinner spinner-lg" /><p>Loading profile...</p></div>;
  if (!trainee) return <div className="empty-state" style={{ marginTop: 80 }}><h3>Trainee not found</h3></div>;
  const totalScore = categoryScores.reduce((s, c) => s + Number(c.category_score), 0) + abEntries.reduce((s, e) => s + Number(e.points), 0);
  const maxCatScore = Math.max(...categoryScores.map(c => Number(c.category_score)), abEntries.reduce((s,e) => s + Number(e.points), 0), 1);
  const byCategory = {};
  itemScores.forEach(s => { const catName = s.category_items?.categories?.name || 'Other'; if (!byCategory[catName]) byCategory[catName] = []; byCategory[catName].push(s); });
  const abTotal = abEntries.reduce((s, e) => s + Number(e.points), 0);
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
          {categoryScores.length === 0 && abEntries.length === 0 ? <p className="text-sm text-muted">No scores yet</p> : <>
            {categoryScores.map(cat => (
              <div key={cat.category_id} style={{ marginBottom: 14 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 5 }}><span style={{ fontSize: 13 }}>{cat.category_name}</span><span style={{ fontSize: 14, fontWeight: 600, color: 'var(--navy)' }}>{Number(cat.category_score).toLocaleString()}</span></div>
                <div style={{ height: 5, background: 'var(--border-light)', borderRadius: 3 }}><div style={{ height: '100%', width: `${Math.round((Number(cat.category_score) / maxCatScore) * 100)}%`, background: 'var(--navy)', borderRadius: 3 }} /></div>
              </div>
            ))}
            {abEntries.length > 0 && (
              <div style={{ marginBottom: 14 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 5 }}><span style={{ fontSize: 13 }}>Above & Beyond</span><span style={{ fontSize: 14, fontWeight: 600, color: 'var(--navy)' }}>{abTotal.toLocaleString()}</span></div>
                <div style={{ height: 5, background: 'var(--border-light)', borderRadius: 3 }}><div style={{ height: '100%', width: `${Math.round((abTotal / maxCatScore) * 100)}%`, background: '#C2185B', borderRadius: 3 }} /></div>
              </div>
            )}
          </>}
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
            <thead><tr style={{ borderBottom: '1px solid var(--border-light)' }}><th style={{ textAlign: 'left', padding: '6px 8px', fontSize: 11, color: 'var(--text-muted)', fontWeight: 600 }}>Item</th>{items[0]?.category_items?.has_submission_score && <th style={{ textAlign: 'right', padding: '6px 8px', fontSize: 11, color: 'var(--text-muted)', fontWeight: 600 }}>Submission</th>}<th style={{ textAlign: 'right', padding: '6px 8px', fontSize: 11, color: 'var(--text-muted)', fontWeight: 600 }}>Score</th></tr></thead>
            <tbody>{items.map(item => (<tr key={item.id} style={{ borderBottom: '1px solid var(--border-light)' }}><td style={{ padding: '9px 8px' }}>{item.category_items?.name}</td>{item.category_items?.has_submission_score && <td style={{ padding: '9px 8px', textAlign: 'right' }}><span className="badge badge-teal">{item.submission_score ?? '—'}</span></td>}<td style={{ padding: '9px 8px', textAlign: 'right' }}><span className="badge badge-navy">{item.score ?? '—'}{item.category_items?.max_score ? `/${item.category_items.max_score}` : ''}</span></td></tr>))}</tbody>
          </table>
        </div>
      ))}
      {abEntries.length > 0 && (
        <div className="card" style={{ marginBottom: 16 }}>
          <p className="card-title">Above & Beyond — {abTotal} pts total</p>
          {abEntries.map((entry, i) => (
            <div key={entry.id} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 0', borderBottom: i < abEntries.length - 1 ? '1px solid var(--border-light)' : 'none' }}>
              <span style={{ fontSize: 11, padding: '2px 8px', borderRadius: 20, fontWeight: 500, whiteSpace: 'nowrap', background: SUB_COLORS[entry.sub_category]?.bg, color: SUB_COLORS[entry.sub_category]?.color }}>{entry.sub_category}</span>
              <p style={{ fontSize: 13, color: 'var(--text-secondary)', flex: 1 }}>{entry.description}</p>
              <span style={{ fontSize: 14, fontWeight: 700, color: 'var(--navy)', whiteSpace: 'nowrap' }}>{entry.points} pts</span>
            </div>
          ))}
        </div>
      )}
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

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

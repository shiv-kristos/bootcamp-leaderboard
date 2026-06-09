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

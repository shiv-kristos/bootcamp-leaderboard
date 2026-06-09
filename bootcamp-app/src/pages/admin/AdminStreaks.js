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

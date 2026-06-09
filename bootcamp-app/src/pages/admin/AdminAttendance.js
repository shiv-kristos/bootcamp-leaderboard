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

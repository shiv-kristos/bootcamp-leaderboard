import { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { useToast } from '../../context/ToastContext';

const SUB_CATEGORIES = [
  'Extra project',
  'External event',
  'External webinar',
  'Extra course',
  'Expert session',
];

export default function AdminAboveAndBeyond() {
  const [batches, setBatches] = useState([]);
  const [selectedBatch, setSelectedBatch] = useState('');
  const [trainees, setTrainees] = useState([]);
  const [entries, setEntries] = useState([]);
  const [filterTrainee, setFilterTrainee] = useState('all');
  const [form, setForm] = useState({ trainee_id: '', sub_category: 'Extra project', description: '', points: '' });
  const [saving, setSaving] = useState(false);
  const { addToast } = useToast();

  useEffect(() => {
    supabase.from('batches').select('id,name').order('created_at', { ascending: false }).then(({ data }) => {
      if (data) { setBatches(data); if (data[0]) setSelectedBatch(data[0].id); }
    });
  }, []);

  useEffect(() => {
    if (!selectedBatch) return;
    supabase.from('trainees').select('*').eq('batch_id', selectedBatch).eq('is_active', true).order('name').then(({ data }) => {
      if (data) { setTrainees(data); if (data[0]) setForm(f => ({ ...f, trainee_id: data[0].id })); }
    });
    loadEntries();
  }, [selectedBatch]);

  async function loadEntries() {
    const { data } = await supabase.from('above_and_beyond').select('*, trainees(name)').eq('batch_id', selectedBatch).order('created_at', { ascending: false });
    if (data) setEntries(data);
  }

  async function save() {
    if (!form.trainee_id || !form.description.trim() || !form.points) return;
    setSaving(true);
    const { error } = await supabase.from('above_and_beyond').insert({
      batch_id: selectedBatch,
      trainee_id: form.trainee_id,
      sub_category: form.sub_category,
      description: form.description.trim(),
      points: Number(form.points),
    });
    if (error) { addToast(error.message, 'error'); }
    else { addToast('Entry added!'); setForm(f => ({ ...f, description: '', points: '' })); loadEntries(); }
    setSaving(false);
  }

  async function deleteEntry(id) {
    if (!window.confirm('Delete this entry?')) return;
    await supabase.from('above_and_beyond').delete().eq('id', id);
    addToast('Entry deleted'); loadEntries();
  }

  const filtered = filterTrainee === 'all' ? entries : entries.filter(e => e.trainee_id === filterTrainee);

  const totalsByTrainee = trainees.map(t => ({
    ...t,
    total: entries.filter(e => e.trainee_id === t.id).reduce((s, e) => s + Number(e.points), 0),
    count: entries.filter(e => e.trainee_id === t.id).length,
  })).filter(t => t.count > 0).sort((a, b) => b.total - a.total);

  const SUB_COLORS = {
    'Extra project': { bg: '#EEF1FB', color: '#1B2A5E' },
    'External event': { bg: '#E0F2F1', color: '#00695C' },
    'External webinar': { bg: '#F3E5F5', color: '#6A1B9A' },
    'Extra course': { bg: '#FFF8E1', color: '#E65100' },
    'Expert session': { bg: '#FCE4EC', color: '#880E4F' },
  };

  return (
    <div>
      <div style={{ marginBottom: 24 }}>
        <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 20, color: 'var(--navy)' }}>Above & Beyond</h2>
        <p style={{ fontSize: 13, color: 'var(--text-muted)', marginTop: 2 }}>Log individual achievements — one entry per person per activity</p>
      </div>

      {/* Batch selector */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 20 }}>
        <label className="form-label" style={{ margin: 0 }}>Batch:</label>
        <select className="form-select" style={{ width: 'auto' }} value={selectedBatch} onChange={e => setSelectedBatch(e.target.value)}>
          {batches.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}
        </select>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 20 }}>
        {/* Entry form */}
        <div className="card">
          <p className="card-title">Add entry</p>
          <div className="form-group" style={{ marginBottom: 12 }}>
            <label className="form-label">Trainee *</label>
            <select className="form-select" value={form.trainee_id} onChange={e => setForm({ ...form, trainee_id: e.target.value })}>
              {trainees.map(t => <option key={t.id} value={t.id}>{t.name}</option>)}
            </select>
          </div>
          <div className="form-group" style={{ marginBottom: 12 }}>
            <label className="form-label">Sub-category *</label>
            <select className="form-select" value={form.sub_category} onChange={e => setForm({ ...form, sub_category: e.target.value })}>
              {SUB_CATEGORIES.map(s => <option key={s} value={s}>{s}</option>)}
            </select>
          </div>
          <div className="form-group" style={{ marginBottom: 12 }}>
            <label className="form-label">Description *</label>
            <input className="form-input" placeholder="e.g. Kafka pipeline automation project" value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} />
          </div>
          <div className="form-group" style={{ marginBottom: 16 }}>
            <label className="form-label">Points *</label>
            <input className="form-input" type="number" min="0" placeholder="e.g. 50" value={form.points} onChange={e => setForm({ ...form, points: e.target.value })} />
          </div>
          <button className="btn btn-primary w-full" style={{ justifyContent: 'center' }} onClick={save} disabled={saving || !form.trainee_id || !form.description.trim() || !form.points}>
            {saving ? <span className="spinner" style={{ width: 14, height: 14 }} /> : '+ Add entry'}
          </button>
        </div>

        {/* Summary per trainee */}
        <div className="card">
          <p className="card-title">Summary</p>
          {totalsByTrainee.length === 0 ? (
            <p style={{ fontSize: 13, color: 'var(--text-muted)' }}>No entries yet</p>
          ) : totalsByTrainee.map((t, i) => (
            <div key={t.id} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '8px 0', borderBottom: i < totalsByTrainee.length - 1 ? '1px solid var(--border-light)' : 'none' }}>
              <div>
                <p style={{ fontSize: 13, fontWeight: 600, color: 'var(--navy)' }}>{t.name}</p>
                <p style={{ fontSize: 11, color: 'var(--text-muted)' }}>{t.count} {t.count === 1 ? 'entry' : 'entries'}</p>
              </div>
              <span style={{ fontSize: 16, fontWeight: 700, color: 'var(--navy)' }}>{t.total} pts</span>
            </div>
          ))}
        </div>
      </div>

      {/* Log */}
      <div className="card" style={{ padding: 0 }}>
        <div style={{ padding: '14px 20px', borderBottom: '1px solid var(--border-light)', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <p style={{ fontSize: 14, fontWeight: 600, color: 'var(--navy)' }}>All entries ({entries.length})</p>
          <select className="form-select" style={{ width: 'auto', fontSize: 12 }} value={filterTrainee} onChange={e => setFilterTrainee(e.target.value)}>
            <option value="all">All trainees</option>
            {trainees.map(t => <option key={t.id} value={t.id}>{t.name}</option>)}
          </select>
        </div>
        {filtered.length === 0 ? (
          <div className="empty-state"><h3>No entries yet</h3><p>Add your first Above & Beyond entry above.</p></div>
        ) : filtered.map((entry, i) => (
          <div key={entry.id} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 20px', borderBottom: i < filtered.length - 1 ? '1px solid var(--border-light)' : 'none' }}>
            <div style={{ flex: 1 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 3 }}>
                <span style={{ fontSize: 11, padding: '2px 8px', borderRadius: 20, fontWeight: 500, background: SUB_COLORS[entry.sub_category]?.bg, color: SUB_COLORS[entry.sub_category]?.color }}>
                  {entry.sub_category}
                </span>
                <span style={{ fontSize: 13, fontWeight: 600, color: 'var(--navy)' }}>{entry.trainees?.name}</span>
              </div>
              <p style={{ fontSize: 12, color: 'var(--text-secondary)' }}>{entry.description}</p>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <span style={{ fontSize: 16, fontWeight: 700, color: 'var(--navy)' }}>{entry.points} pts</span>
              <button className="btn btn-danger btn-sm" onClick={() => deleteEntry(entry.id)}>Delete</button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

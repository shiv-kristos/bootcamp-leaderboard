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

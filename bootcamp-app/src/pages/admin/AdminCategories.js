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

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

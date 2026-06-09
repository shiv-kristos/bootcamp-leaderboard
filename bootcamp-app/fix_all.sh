#!/bin/bash
set -e
cd /workspaces/bootcamp-leaderboard/bootcamp-app

cat > src/components/Avatar.js << 'EOF'
import { useState } from 'react';
const COLORS = [{ bg: '#FFF3E0', text: '#E65100' },{ bg: '#E8EAF6', text: '#283593' },{ bg: '#FCE4EC', text: '#880E4F' },{ bg: '#E0F2F1', text: '#00695C' },{ bg: '#F3E5F5', text: '#6A1B9A' },{ bg: '#E3F2FD', text: '#1565C0' },{ bg: '#FFF8E1', text: '#F57F17' },{ bg: '#E8F5E9', text: '#2E7D32' }];
function getColor(name) { let hash = 0; for (let i = 0; i < name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash); return COLORS[Math.abs(hash) % COLORS.length]; }
function getInitials(name) { const parts = name.trim().split(' '); if (parts.length === 1) return parts[0].substring(0, 2).toUpperCase(); return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase(); }
export default function Avatar({ name = '', photoUrl, size = 40, fontSize }) {
  const [imgError, setImgError] = useState(false);
  const color = getColor(name); const initials = getInitials(name);
  const fs = fontSize || Math.max(10, Math.floor(size * 0.35));
  return (
    <div className="avatar" style={{ width: size, height: size, background: color.bg, color: color.text, fontSize: fs, flexShrink: 0 }}>
      {photoUrl && !imgError
        ? <img src={photoUrl} alt={name} style={{ width: '100%', height: '100%', objectFit: 'cover', borderRadius: '50%' }} onError={() => setImgError(true)} />
        : initials}
    </div>
  );
}
EOF

cat > src/pages/admin/AdminCategories.js << 'EOF'
import { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { useToast } from '../../context/ToastContext';
const TYPE_INFO = { points: { label: 'Points', badge: 'badge-navy', desc: 'Named items with scores' }, streak: { label: 'Streak', badge: 'badge-amber', desc: 'Daily completion tracking' }, display: { label: 'Display only', badge: 'badge-gray', desc: 'Shown on profile, never scored' } };
function CategoryForm({ initial, onSave, onCancel, saving }) {
  const [form, setForm] = useState(initial || { name: '', type: 'points', include_in_overall: true });
  function handleTypeChange(type) { setForm(f => ({ ...f, type, include_in_overall: type !== 'display' })); }
  return (
    <div className="card" style={{ marginBottom: 20 }}>
      <p className="card-title">{initial ? 'Edit category' : 'New category'}</p>
      <div className="form-group" style={{ marginBottom: 16 }}><label className="form-label">Category name *</label><input className="form-input" placeholder="e.g. Assessment, Public Speaking..." value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} /></div>
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
        <div className={`toggle ${form.include_in_overall ? 'on' : ''}`} onClick={() => setForm(f => ({ ...f, include_in_overall: !f.include_in_overall }))} />
        <div><p style={{ fontSize: 13, fontWeight: 500 }}>Include in overall score</p><p style={{ fontSize: 11, color: 'var(--text-muted)' }}>{form.include_in_overall ? 'Will affect leaderboard rankings' : 'Shown but not counted in totals'}</p></div>
      </div>
      <div style={{ display: 'flex', gap: 8, justifyContent: 'flex-end' }}>
        <button className="btn btn-secondary" onClick={onCancel}>Cancel</button>
        <button className="btn btn-primary" onClick={() => onSave(form)} disabled={saving || !form.name.trim()}>{saving ? <span className="spinner" style={{ width: 14, height: 14 }} /> : initial ? 'Save changes' : 'Create category'}</button>
      </div>
    </div>
  );
}
function ItemForm({ initial, onSave, onCancel, saving }) {
  const [form, setForm] = useState(initial || { name: '', max_score: '', has_submission_score: false, submission_max: '' });
  return (
    <div style={{ background: 'var(--bg)', borderRadius: 'var(--radius-md)', padding: 14, marginBottom: 8, border: '1px solid var(--border)' }}>
      <div className="form-group" style={{ marginBottom: 10 }}><label className="form-label">Item name *</label><input className="form-input" placeholder="e.g. Day 7 Assessment, Task 3 — Python" value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} /></div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 10 }}>
        <div className="form-group"><label className="form-label">Max score (optional)</label><input className="form-input" type="number" placeholder="e.g. 100" value={form.max_score} onChange={e => setForm(f => ({ ...f, max_score: e.target.value }))} /></div>
        {form.has_submission_score && <div className="form-group"><label className="form-label">Submission max (optional)</label><input className="form-input" type="number" placeholder="e.g. 50" value={form.submission_max} onChange={e => setForm(f => ({ ...f, submission_max: e.target.value }))} /></div>}
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 12 }}>
        <div className={`toggle ${form.has_submission_score ? 'on' : ''}`} onClick={() => setForm(f => ({ ...f, has_submission_score: !f.has_submission_score }))} />
        <p style={{ fontSize: 12, color: 'var(--text-secondary)' }}>Track submission score separately (dual score)</p>
      </div>
      <div style={{ display: 'flex', gap: 8, justifyContent: 'flex-end' }}>
        <button className="btn btn-secondary btn-sm" onClick={onCancel}>Cancel</button>
        <button className="btn btn-primary btn-sm" onClick={() => onSave(form)} disabled={saving || !form.name.trim()}>{saving ? <span className="spinner" style={{ width: 12, height: 12 }} /> : initial ? 'Save' : 'Add item'}</button>
      </div>
    </div>
  );
}
export default function AdminCategories() {
  const [batches, setBatches] = useState([]); const [selectedBatch, setSelectedBatch] = useState(''); const [categories, setCategories] = useState([]); const [showForm, setShowForm] = useState(false); const [editingCat, setEditingCat] = useState(null); const [saving, setSaving] = useState(false); const [expandedCat, setExpandedCat] = useState(null); const [items, setItems] = useState({}); const [editingItem, setEditingItem] = useState(null); const [addingItemFor, setAddingItemFor] = useState(null); const [savingItem, setSavingItem] = useState(false); const { addToast } = useToast();
  useEffect(() => { supabase.from('batches').select('id,name').order('created_at', { ascending: false }).then(({ data }) => { if (data) { setBatches(data); if (data.length > 0) setSelectedBatch(data[0].id); } }); }, []);
  useEffect(() => { if (selectedBatch) load(); }, [selectedBatch]);
  async function load() { const { data } = await supabase.from('categories').select('*').eq('batch_id', selectedBatch).order('sort_order'); if (data) setCategories(data); }
  async function loadItems(catId) { const { data } = await supabase.from('category_items').select('*').eq('category_id', catId).order('sort_order'); if (data) setItems(prev => ({ ...prev, [catId]: data })); }
  function toggleExpand(catId) { if (expandedCat === catId) { setExpandedCat(null); } else { setExpandedCat(catId); loadItems(catId); } }
  async function saveCategory(form) {
    setSaving(true);
    if (editingCat) { const { error } = await supabase.from('categories').update({ name: form.name.trim(), type: form.type, include_in_overall: form.include_in_overall }).eq('id', editingCat.id); if (error) { addToast(error.message, 'error'); } else { addToast('Category updated!'); setEditingCat(null); load(); } }
    else { const maxOrder = categories.length > 0 ? Math.max(...categories.map(c => c.sort_order)) + 1 : 0; const { error } = await supabase.from('categories').insert({ batch_id: selectedBatch, name: form.name.trim(), type: form.type, include_in_overall: form.include_in_overall, sort_order: maxOrder }); if (error) { addToast(error.message, 'error'); } else { addToast('Category created!'); setShowForm(false); load(); } }
    setSaving(false);
  }
  async function deleteCategory(cat) { if (!window.confirm(`Delete "${cat.name}"? All scores will also be deleted.`)) return; await supabase.from('categories').delete().eq('id', cat.id); addToast('Category deleted'); load(); }
  async function saveItem(form, catId) {
    setSavingItem(true);
    const payload = { name: form.name.trim(), max_score: form.max_score ? Number(form.max_score) : null, has_submission_score: form.has_submission_score, submission_max: form.submission_max ? Number(form.submission_max) : null };
    if (editingItem) { const { error } = await supabase.from('category_items').update(payload).eq('id', editingItem.id); if (error) { addToast(error.message, 'error'); } else { addToast('Item updated!'); setEditingItem(null); loadItems(catId); } }
    else { const existingItems = items[catId] || []; const maxOrder = existingItems.length > 0 ? Math.max(...existingItems.map(i => i.sort_order)) + 1 : 0; const { error } = await supabase.from('category_items').insert({ ...payload, category_id: catId, sort_order: maxOrder }); if (error) { addToast(error.message, 'error'); } else { addToast('Item added!'); setAddingItemFor(null); loadItems(catId); } }
    setSavingItem(false);
  }
  async function deleteItem(item, catId) { if (!window.confirm(`Delete "${item.name}"?`)) return; await supabase.from('category_items').delete().eq('id', item.id); addToast('Item deleted'); loadItems(catId); }
  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div><h2 style={{ fontFamily: 'var(--font-display)', fontSize: 20, color: 'var(--navy)' }}>Categories</h2><p style={{ fontSize: 13, color: 'var(--text-muted)', marginTop: 2 }}>Add and edit scoring dimensions anytime</p></div>
        <button className="btn btn-primary" onClick={() => { setShowForm(true); setEditingCat(null); }}>+ Add category</button>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 20 }}>
        <label className="form-label" style={{ margin: 0 }}>Batch:</label>
        <select className="form-select" style={{ width: 'auto' }} value={selectedBatch} onChange={e => setSelectedBatch(e.target.value)}>{batches.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}</select>
      </div>
      {(showForm && !editingCat) && <CategoryForm onSave={saveCategory} onCancel={() => setShowForm(false)} saving={saving} />}
      {categories.length === 0 ? <div className="empty-state"><h3>No categories yet</h3><p>Add your first scoring category above.</p></div> : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {categories.map(cat => (
            <div key={cat.id} style={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 'var(--radius-lg)', overflow: 'hidden' }}>
              {editingCat?.id === cat.id ? <div style={{ padding: 16 }}><CategoryForm initial={editingCat} onSave={saveCategory} onCancel={() => setEditingCat(null)} saving={saving} /></div> : (
                <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '14px 20px' }}>
                  <div style={{ flex: 1 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 3 }}><p style={{ fontSize: 14, fontWeight: 600, color: 'var(--navy)' }}>{cat.name}</p><span className={`badge ${TYPE_INFO[cat.type]?.badge}`}>{TYPE_INFO[cat.type]?.label}</span>{cat.include_in_overall && <span className="badge badge-teal">Counts in overall</span>}</div>
                    <p style={{ fontSize: 11, color: 'var(--text-muted)' }}>{TYPE_INFO[cat.type]?.desc}</p>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    {cat.type === 'points' && <button className="btn btn-secondary btn-sm" onClick={() => toggleExpand(cat.id)}>{expandedCat === cat.id ? 'Hide ▲' : 'Items ▼'}</button>}
                    <button className="btn btn-secondary btn-sm" onClick={() => { setEditingCat(cat); setShowForm(false); }}>Edit</button>
                    <button className="btn btn-danger btn-sm" onClick={() => deleteCategory(cat)}>Delete</button>
                  </div>
                </div>
              )}
              {expandedCat === cat.id && cat.type === 'points' && (
                <div style={{ borderTop: '1px solid var(--border-light)', padding: '12px 20px', background: 'var(--bg)' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
                    <p style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.06em' }}>Items in "{cat.name}"</p>
                    <button className="btn btn-primary btn-sm" onClick={() => { setAddingItemFor(cat.id); setEditingItem(null); }}>+ Add item</button>
                  </div>
                  {addingItemFor === cat.id && !editingItem && <ItemForm onSave={form => saveItem(form, cat.id)} onCancel={() => setAddingItemFor(null)} saving={savingItem} />}
                  {(items[cat.id] || []).length === 0 && addingItemFor !== cat.id && <p style={{ fontSize: 12, color: 'var(--text-muted)', padding: '8px 0' }}>No items yet — add one above.</p>}
                  {(items[cat.id] || []).map(item => (
                    <div key={item.id}>
                      {editingItem?.id === item.id ? <ItemForm initial={{ name: item.name, max_score: item.max_score ?? '', has_submission_score: item.has_submission_score, submission_max: item.submission_max ?? '' }} onSave={form => saveItem(form, cat.id)} onCancel={() => setEditingItem(null)} saving={savingItem} /> : (
                        <div style={{ display: 'flex', alignItems: 'center', padding: '9px 12px', background: 'var(--surface)', borderRadius: 8, marginBottom: 6, border: '1px solid var(--border-light)' }}>
                          <div style={{ flex: 1 }}><p style={{ fontSize: 13, fontWeight: 500 }}>{item.name}</p><p style={{ fontSize: 11, color: 'var(--text-muted)' }}>{item.max_score ? `Max: ${item.max_score}` : 'No max'}{item.has_submission_score && ` · Dual score`}</p></div>
                          <div style={{ display: 'flex', gap: 6 }}>
                            <button className="btn btn-secondary btn-sm" onClick={() => { setEditingItem(item); setAddingItemFor(null); }}>Edit</button>
                            <button className="btn btn-danger btn-sm" onClick={() => deleteItem(item, cat.id)}>Delete</button>
                          </div>
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
EOF

cat > src/pages/admin/AdminTrainees.js << 'EOF'
import { useEffect, useState, useRef } from 'react';
import { supabase } from '../../lib/supabase';
import { useToast } from '../../context/ToastContext';
import Avatar from '../../components/Avatar';
export default function AdminTrainees() {
  const [batches, setBatches] = useState([]); const [selectedBatch, setSelectedBatch] = useState(''); const [trainees, setTrainees] = useState([]); const [showForm, setShowForm] = useState(false); const [editingTrainee, setEditingTrainee] = useState(null); const [form, setForm] = useState({ name: '', employee_id: '', department: '', email: '' }); const [photoFile, setPhotoFile] = useState(null); const [photoPreview, setPhotoPreview] = useState(null); const [saving, setSaving] = useState(false); const fileRef = useRef(); const { addToast } = useToast();
  useEffect(() => { supabase.from('batches').select('id,name').order('created_at', { ascending: false }).then(({ data }) => { if (data) { setBatches(data); if (data.length > 0) setSelectedBatch(data[0].id); } }); }, []);
  useEffect(() => { if (selectedBatch) loadTrainees(); }, [selectedBatch]);
  async function loadTrainees() { const { data } = await supabase.from('trainees').select('*').eq('batch_id', selectedBatch).order('name'); if (data) setTrainees(data); }
  function handlePhoto(e) { const file = e.target.files[0]; if (!file) return; setPhotoFile(file); setPhotoPreview(URL.createObjectURL(file)); }
  function openForm(trainee = null) { setEditingTrainee(trainee); setForm(trainee ? { name: trainee.name, employee_id: trainee.employee_id || '', department: trainee.department || '', email: trainee.email || '' } : { name: '', employee_id: '', department: '', email: '' }); setPhotoFile(null); setPhotoPreview(trainee?.photo_url || null); setShowForm(true); }
  async function uploadPhoto(traineeId) {
    if (!photoFile) return null;
    const ext = photoFile.name.split('.').pop(); const path = `${selectedBatch}/${traineeId}_${Date.now()}.${ext}`;
    const { error: upErr } = await supabase.storage.from('trainee-photos').upload(path, photoFile, { upsert: true });
    if (upErr) { addToast('Photo upload failed: ' + upErr.message, 'error'); return null; }
    const { data } = supabase.storage.from('trainee-photos').getPublicUrl(path);
    return data.publicUrl;
  }
  async function save() {
    if (!form.name.trim() || !selectedBatch) return; setSaving(true);
    try {
      if (editingTrainee) {
        let photo_url = editingTrainee.photo_url;
        if (photoFile) { const url = await uploadPhoto(editingTrainee.id); if (url) photo_url = url; }
        const { error } = await supabase.from('trainees').update({ name: form.name.trim(), employee_id: form.employee_id, department: form.department, email: form.email, photo_url }).eq('id', editingTrainee.id);
        if (error) { addToast(error.message, 'error'); } else { addToast('Trainee updated!'); setShowForm(false); loadTrainees(); }
      } else {
        const { data: newTrainee, error } = await supabase.from('trainees').insert({ batch_id: selectedBatch, name: form.name.trim(), employee_id: form.employee_id, department: form.department, email: form.email }).select().single();
        if (error) { addToast(error.message, 'error'); } else { let photo_url = null; if (photoFile) photo_url = await uploadPhoto(newTrainee.id); if (photo_url) await supabase.from('trainees').update({ photo_url }).eq('id', newTrainee.id); addToast('Trainee added!'); setShowForm(false); loadTrainees(); }
      }
    } catch (e) { addToast('Something went wrong', 'error'); }
    setSaving(false);
  }
  async function toggleActive(t) { await supabase.from('trainees').update({ is_active: !t.is_active }).eq('id', t.id); loadTrainees(); }
  async function updatePhotoInline(traineeId, file) {
    const ext = file.name.split('.').pop(); const path = `${selectedBatch}/${traineeId}_${Date.now()}.${ext}`;
    const { error: upErr } = await supabase.storage.from('trainee-photos').upload(path, file, { upsert: true });
    if (upErr) { addToast('Photo upload failed: ' + upErr.message, 'error'); return; }
    const { data } = supabase.storage.from('trainee-photos').getPublicUrl(path);
    await supabase.from('trainees').update({ photo_url: data.publicUrl }).eq('id', traineeId);
    addToast('Photo updated!'); loadTrainees();
  }
  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div><h2 style={{ fontFamily: 'var(--font-display)', fontSize: 20, color: 'var(--navy)' }}>Trainees</h2><p style={{ fontSize: 13, color: 'var(--text-muted)', marginTop: 2 }}>Add and manage trainees per batch</p></div>
        <button className="btn btn-primary" onClick={() => openForm()}>+ Add trainee</button>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 20 }}>
        <label className="form-label" style={{ margin: 0, whiteSpace: 'nowrap' }}>Batch:</label>
        <select className="form-select" style={{ width: 'auto' }} value={selectedBatch} onChange={e => setSelectedBatch(e.target.value)}>{batches.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}</select>
        <span className="badge badge-navy">{trainees.length} trainees</span>
      </div>
      {showForm && (
        <div className="card" style={{ marginBottom: 20 }}>
          <p className="card-title">{editingTrainee ? `Edit — ${editingTrainee.name}` : 'Add new trainee'}</p>
          <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 16 }}>
            <div onClick={() => fileRef.current.click()} style={{ cursor: 'pointer', position: 'relative' }}>
              {photoPreview ? <img src={photoPreview} alt="preview" style={{ width: 64, height: 64, borderRadius: '50%', objectFit: 'cover', border: '2px solid var(--border)' }} onError={e => e.target.style.display='none'} /> : <div style={{ width: 64, height: 64, borderRadius: '50%', background: 'var(--bg)', border: '2px dashed var(--border)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 11, color: 'var(--text-muted)', textAlign: 'center' }}>Add photo</div>}
              <div style={{ position: 'absolute', bottom: 0, right: 0, width: 20, height: 20, background: 'var(--navy)', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '2px solid #fff' }}><span style={{ color: '#fff', fontSize: 10 }}>✎</span></div>
            </div>
            <p style={{ fontSize: 12, color: 'var(--text-muted)' }}>Click to {editingTrainee ? 'change' : 'upload'} photo<br />(optional)</p>
            <input ref={fileRef} type="file" accept="image/*" style={{ display: 'none' }} onChange={handlePhoto} />
          </div>
          <div className="grid-2" style={{ marginBottom: 12 }}>
            <div className="form-group"><label className="form-label">Full name *</label><input className="form-input" placeholder="Full name" value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} /></div>
            <div className="form-group"><label className="form-label">Employee ID</label><input className="form-input" placeholder="e.g. CI189" value={form.employee_id} onChange={e => setForm({ ...form, employee_id: e.target.value })} /></div>
          </div>
          <div className="grid-2" style={{ marginBottom: 16 }}>
            <div className="form-group"><label className="form-label">Department</label><input className="form-input" placeholder="e.g. DE, DCG, AE" value={form.department} onChange={e => setForm({ ...form, department: e.target.value })} /></div>
            <div className="form-group"><label className="form-label">Email</label><input className="form-input" type="email" placeholder="email@company.com" value={form.email} onChange={e => setForm({ ...form, email: e.target.value })} /></div>
          </div>
          <div style={{ display: 'flex', gap: 8, justifyContent: 'flex-end' }}>
            <button className="btn btn-secondary" onClick={() => { setShowForm(false); setEditingTrainee(null); }}>Cancel</button>
            <button className="btn btn-primary" onClick={save} disabled={saving || !form.name.trim()}>{saving ? <span className="spinner" style={{ width: 14, height: 14 }} /> : editingTrainee ? 'Save changes' : 'Add trainee'}</button>
          </div>
        </div>
      )}
      {trainees.length === 0 ? <div className="empty-state"><h3>No trainees yet</h3><p>Add trainees to this batch above.</p></div> : (
        <div className="card" style={{ padding: 0 }}>
          {trainees.map((t, i) => (
            <div key={t.id} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 20px', borderBottom: i < trainees.length - 1 ? '1px solid var(--border-light)' : 'none' }}>
              <div style={{ position: 'relative', cursor: 'pointer', flexShrink: 0 }} onClick={() => { const inp = document.createElement('input'); inp.type='file'; inp.accept='image/*'; inp.onchange=e=>updatePhotoInline(t.id, e.target.files[0]); inp.click(); }}>
                <Avatar name={t.name} photoUrl={t.photo_url} size={44} />
                <div style={{ position: 'absolute', bottom: -2, right: -2, width: 16, height: 16, background: 'var(--navy)', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '1.5px solid #fff' }}><span style={{ color: '#fff', fontSize: 9 }}>✎</span></div>
              </div>
              <div style={{ flex: 1 }}>
                <p style={{ fontSize: 13, fontWeight: 600, color: 'var(--navy)' }}>{t.name}</p>
                <p style={{ fontSize: 11, color: 'var(--text-muted)' }}>{[t.employee_id, t.department, t.email].filter(Boolean).join(' · ')}</p>
                {t.photo_url && <p style={{ fontSize: 10, color: 'var(--teal)', marginTop: 2 }}>✓ Photo uploaded</p>}
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span className={`badge ${t.is_active ? 'badge-green' : 'badge-gray'}`}>{t.is_active ? 'Active' : 'Inactive'}</span>
                <button className="btn btn-secondary btn-sm" onClick={() => openForm(t)}>Edit</button>
                <button className="btn btn-secondary btn-sm" onClick={() => toggleActive(t)}>{t.is_active ? 'Deactivate' : 'Activate'}</button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
EOF

cd /workspaces/bootcamp-leaderboard && git add . && git commit -m "Fix: edit categories, edit items, fix photos" && git push
echo "ALL DONE - Netlify will redeploy automatically"

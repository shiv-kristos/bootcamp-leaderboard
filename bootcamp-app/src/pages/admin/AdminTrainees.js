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

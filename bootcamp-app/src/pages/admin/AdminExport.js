import { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { useToast } from '../../context/ToastContext';
export default function AdminExport() {
  const [batches, setBatches] = useState([]); const [selectedBatch, setSelectedBatch] = useState(''); const [exporting, setExporting] = useState(false); const { addToast } = useToast();
  useEffect(() => { supabase.from('batches').select('id,name').order('created_at', { ascending: false }).then(({ data }) => { if (data) { setBatches(data); if (data[0]) setSelectedBatch(data[0].id); } }); }, []);
  async function exportCSV() {
    if (!selectedBatch) return; setExporting(true);
    try {
      const [overallRes, catRes] = await Promise.all([supabase.from('trainee_overall_scores').select('*').eq('batch_id', selectedBatch).order('overall_score', { ascending: false }), supabase.from('trainee_category_scores').select('*').eq('batch_id', selectedBatch)]);
      const overall = overallRes.data || []; const catScores = catRes.data || []; const catNames = [...new Set(catScores.map(c => c.category_name))];
      const rows = overall.map((t, i) => { const row = { Rank: i + 1, Name: t.trainee_name, Department: t.department || '', 'Total Score': t.overall_score }; catNames.forEach(cat => { const cs = catScores.find(c => c.trainee_id === t.trainee_id && c.category_name === cat); row[cat] = cs ? cs.category_score : 0; }); return row; });
      const headers = Object.keys(rows[0] || {}); const csv = [headers.join(','), ...rows.map(r => headers.map(h => `"${r[h] ?? ''}"`).join(','))].join('\n');
      const blob = new Blob([csv], { type: 'text/csv' }); const url = URL.createObjectURL(blob); const a = document.createElement('a'); a.href = url;
      const batchName = batches.find(b => b.id === selectedBatch)?.name || 'batch'; a.download = `${batchName.replace(/\s+/g, '_')}_leaderboard.csv`; a.click(); URL.revokeObjectURL(url);
      addToast('CSV exported!');
    } catch (e) { addToast('Export failed', 'error'); }
    setExporting(false);
  }
  return (
    <div>
      <div style={{ marginBottom: 24 }}><h2 style={{ fontFamily: 'var(--font-display)', fontSize: 20, color: 'var(--navy)' }}>Export</h2><p style={{ fontSize: 13, color: 'var(--text-muted)', marginTop: 2 }}>Download leaderboard data as CSV</p></div>
      <div className="card" style={{ maxWidth: 480 }}>
        <p className="card-title">Export leaderboard</p>
        <div className="form-group" style={{ marginBottom: 16 }}><label className="form-label">Select batch</label><select className="form-select" value={selectedBatch} onChange={e => setSelectedBatch(e.target.value)}>{batches.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}</select></div>
        <p style={{ fontSize: 12, color: 'var(--text-muted)', marginBottom: 16 }}>Exports: Rank, Name, Department, Total Score, and score per category.</p>
        <button className="btn btn-primary" onClick={exportCSV} disabled={exporting || !selectedBatch}>{exporting ? <span className="spinner" style={{ width: 14, height: 14 }} /> : '↓ Download CSV'}</button>
      </div>
    </div>
  );
}

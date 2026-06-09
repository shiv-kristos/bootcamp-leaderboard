import { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { useAuth } from '../context/AuthContext';
export default function Topbar({ selectedBatch, onBatchChange }) {
  const [batches, setBatches] = useState([]);
  const { isAdmin, signOut } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const isAdminRoute = location.pathname.startsWith('/admin');
  useEffect(() => {
    supabase.from('batches').select('id, name').order('created_at', { ascending: false })
      .then(({ data }) => { if (data) setBatches(data); });
  }, []);
  const handleSignOut = async () => { await signOut(); navigate('/'); };
  return (
    <nav style={{ background: '#fff', borderBottom: '1px solid var(--border)', padding: '0 28px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', height: 56, position: 'sticky', top: 0, zIndex: 100 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer' }} onClick={() => navigate('/')}>
          <div style={{ width: 30, height: 30, background: 'var(--navy)', borderRadius: 8, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <span style={{ color: '#fff', fontSize: 11, fontWeight: 700, fontFamily: 'var(--font-display)' }}>EX</span>
          </div>
          <span style={{ fontFamily: 'var(--font-display)', fontSize: 15, color: 'var(--navy)', fontWeight: 600 }}>Excelra Bootcamp</span>
        </div>
        {!isAdminRoute && batches.length > 0 && (
          <select className="form-select" style={{ width: 'auto', fontSize: 12, padding: '5px 10px' }} value={selectedBatch?.id || ''}
            onChange={e => { const b = batches.find(b => b.id === e.target.value); if (b) onBatchChange(b); }}>
            {batches.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}
          </select>
        )}
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        {isAdmin && isAdminRoute ? (
          <>
            <span className="badge badge-navy">Admin</span>
            <button className="btn btn-secondary btn-sm" onClick={() => navigate('/')}>Public view</button>
            <button className="btn btn-secondary btn-sm" onClick={handleSignOut}>Sign out</button>
          </>
        ) : isAdmin ? (
          <button className="btn btn-secondary btn-sm" onClick={() => navigate('/admin')}>Admin panel</button>
        ) : (
          <button className="btn btn-secondary btn-sm" onClick={() => navigate('/admin/login')}>🔒 Admin</button>
        )}
      </div>
    </nav>
  );
}

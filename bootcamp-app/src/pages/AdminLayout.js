import { useNavigate, useLocation, Outlet } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
const navItems = [
  { label: 'Dashboard', path: '/admin', icon: '⊞', exact: true },
  { label: 'Batches', path: '/admin/batches', icon: '◫' },
  { label: 'Trainees', path: '/admin/trainees', icon: '◉' },
  { label: 'Categories', path: '/admin/categories', icon: '◈' },
  { label: 'Enter scores', path: '/admin/scores', icon: '✎' },
  { label: 'Streaks', path: '/admin/streaks', icon: '⚡' },
  { label: 'Attendance', path: '/admin/attendance', icon: '◻' },
  { label: 'Export', path: '/admin/export', icon: '↓' },
];
export default function AdminLayout() {
  const { isAdmin } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  if (!isAdmin) { navigate('/admin/login'); return null; }
  const isActive = (path, exact) => exact ? location.pathname === path : location.pathname.startsWith(path);
  return (
    <div style={{ display: 'flex', minHeight: 'calc(100vh - 56px)' }}>
      <aside style={{ width: 200, background: '#fff', borderRight: '1px solid var(--border)', padding: '16px 0', flexShrink: 0 }}>
        {navItems.map(item => (
          <button key={item.path} onClick={() => navigate(item.path)} style={{ width: '100%', textAlign: 'left', padding: '9px 20px', fontSize: 13, cursor: 'pointer', border: 'none', background: isActive(item.path, item.exact) ? 'var(--navy-light)' : 'transparent', color: isActive(item.path, item.exact) ? 'var(--navy)' : 'var(--text-secondary)', fontWeight: isActive(item.path, item.exact) ? 600 : 400, fontFamily: 'var(--font-body)', borderRight: isActive(item.path, item.exact) ? '2px solid var(--navy)' : '2px solid transparent', display: 'flex', alignItems: 'center', gap: 10 }}>
            <span style={{ fontSize: 15 }}>{item.icon}</span>{item.label}
          </button>
        ))}
      </aside>
      <main style={{ flex: 1, padding: '24px 28px', overflowY: 'auto', background: 'var(--bg)' }}><Outlet /></main>
    </div>
  );
}

import { useEffect, useState } from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import { ToastProvider } from './context/ToastContext';
import Topbar from './components/Topbar';
import LeaderboardPage from './pages/LeaderboardPage';
import TraineePage from './pages/TraineePage';
import AdminLogin from './pages/AdminLogin';
import AdminLayout from './pages/AdminLayout';
import AdminDashboard from './pages/admin/AdminDashboard';
import AdminBatches from './pages/admin/AdminBatches';
import AdminTrainees from './pages/admin/AdminTrainees';
import AdminCategories from './pages/admin/AdminCategories';
import AdminScores from './pages/admin/AdminScores';
import AdminAboveAndBeyond from './pages/admin/AdminAboveAndBeyond';
import AdminStreaks from './pages/admin/AdminStreaks';
import AdminAttendance from './pages/admin/AdminAttendance';
import AdminExport from './pages/admin/AdminExport';
import { supabase } from './lib/supabase';
import './styles/global.css';
function PublicLayout() {
  const [selectedBatch, setSelectedBatch] = useState(null);
  useEffect(() => { supabase.from('batches').select('id,name').eq('is_active', true).order('created_at', { ascending: false }).limit(1).then(({ data }) => { if (data && data[0]) setSelectedBatch(data[0]); }); }, []);
  return (<><Topbar selectedBatch={selectedBatch} onBatchChange={setSelectedBatch} /><Routes><Route path="/" element={<LeaderboardPage batch={selectedBatch} />} /><Route path="/trainee/:id" element={<TraineePage />} /></Routes></>);
}
function AdminRoutes() {
  return (<><Topbar /><Routes><Route path="login" element={<AdminLogin />} /><Route path="" element={<AdminLayout />}><Route index element={<AdminDashboard />} /><Route path="batches" element={<AdminBatches />} /><Route path="trainees" element={<AdminTrainees />} /><Route path="categories" element={<AdminCategories />} /><Route path="scores" element={<AdminScores />} /><Route path="above-and-beyond" element={<AdminAboveAndBeyond />} /><Route path="streaks" element={<AdminStreaks />} /><Route path="attendance" element={<AdminAttendance />} /><Route path="export" element={<AdminExport />} /></Route></Routes></>);
}
export default function App() {
  return (<BrowserRouter><AuthProvider><ToastProvider><Routes><Route path="/admin/*" element={<AdminRoutes />} /><Route path="/*" element={<PublicLayout />} /></Routes></ToastProvider></AuthProvider></BrowserRouter>);
}

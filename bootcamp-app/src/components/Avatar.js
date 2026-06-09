const COLORS = [
  { bg: '#FFF3E0', text: '#E65100' },
  { bg: '#E8EAF6', text: '#283593' },
  { bg: '#FCE4EC', text: '#880E4F' },
  { bg: '#E0F2F1', text: '#00695C' },
  { bg: '#F3E5F5', text: '#6A1B9A' },
  { bg: '#E3F2FD', text: '#1565C0' },
  { bg: '#FFF8E1', text: '#F57F17' },
  { bg: '#E8F5E9', text: '#2E7D32' },
];
function getColor(name) {
  let hash = 0;
  for (let i = 0; i < name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash);
  return COLORS[Math.abs(hash) % COLORS.length];
}
function getInitials(name) {
  const parts = name.trim().split(' ');
  if (parts.length === 1) return parts[0].substring(0, 2).toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}
export default function Avatar({ name = '', photoUrl, size = 40, fontSize }) {
  const color = getColor(name);
  const initials = getInitials(name);
  const fs = fontSize || Math.max(10, Math.floor(size * 0.35));
  return (
    <div className="avatar" style={{ width: size, height: size, background: color.bg, color: color.text, fontSize: fs }}>
      {photoUrl ? <img src={photoUrl} alt={name} onError={e => { e.target.style.display = 'none'; }} /> : initials}
    </div>
  );
}

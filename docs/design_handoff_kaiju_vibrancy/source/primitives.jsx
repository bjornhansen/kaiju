// Kaiju shared primitives — icons, avatars, status pills, helpers.
// All icons are stroke-based, sized by `size`, color by `currentColor`.

const Icon = ({ d, size = 14, fill = "none", stroke = 1.6, ...rest }) => (
  <svg width={size} height={size} viewBox="0 0 16 16" fill={fill}
       stroke="currentColor" strokeWidth={stroke}
       strokeLinecap="round" strokeLinejoin="round" {...rest}>
    {d}
  </svg>
);

const Icons = {
  Search:    (p) => <Icon {...p} d={<><circle cx="7" cy="7" r="4.5"/><path d="M10.5 10.5L13.5 13.5"/></>}/>,
  Plus:      (p) => <Icon {...p} d={<><path d="M8 3v10M3 8h10"/></>}/>,
  Filter:    (p) => <Icon {...p} d={<><path d="M2.5 4h11M5 8h6M7 12h2"/></>}/>,
  Sort:      (p) => <Icon {...p} d={<><path d="M4 3v10M4 13l-2-2M4 13l2-2M12 13V3M12 3l-2 2M12 3l2 2"/></>}/>,
  Inbox:     (p) => <Icon {...p} d={<><path d="M2 9l1.5-5h9L14 9v3.5a.5.5 0 0 1-.5.5h-11a.5.5 0 0 1-.5-.5V9z"/><path d="M2 9h3l1 1.5h4L11 9h3"/></>}/>,
  Assigned:  (p) => <Icon {...p} d={<><circle cx="8" cy="6" r="2.5"/><path d="M3 13.5c.5-2.5 2.5-4 5-4s4.5 1.5 5 4"/></>}/>,
  Created:   (p) => <Icon {...p} d={<><path d="M3.5 2.5h6L12.5 5.5v8a.5.5 0 0 1-.5.5h-8.5a.5.5 0 0 1-.5-.5v-11a.5.5 0 0 1 .5-.5z"/><path d="M9.5 2.5v3h3"/></>}/>,
  Subscribed:(p) => <Icon {...p} d={<><path d="M3 11.5h10l-1.5-2V7a3.5 3.5 0 1 0-7 0v2.5L3 11.5z"/><path d="M6.5 13.5a1.5 1.5 0 0 0 3 0"/></>}/>,
  Board:     (p) => <Icon {...p} d={<><rect x="2.5" y="2.5" width="11" height="11" rx="1"/><path d="M6 2.5v11M10 2.5v11"/></>}/>,
  List:      (p) => <Icon {...p} d={<><path d="M2.5 4h11M2.5 8h11M2.5 12h7"/></>}/>,
  Sprint:    (p) => <Icon {...p} d={<><circle cx="8" cy="8" r="5.5"/><path d="M8 5v3l2 1.5"/></>}/>,
  Roadmap:   (p) => <Icon {...p} d={<><path d="M2.5 5.5h3M2.5 8h7M2.5 10.5h5"/><circle cx="12" cy="5.5" r="1"/><circle cx="12" cy="8" r="1"/><circle cx="12" cy="10.5" r="1"/></>}/>,
  Projects:  (p) => <Icon {...p} d={<><path d="M2.5 5l1.5-2h4l1.5 2h4v8.5a.5.5 0 0 1-.5.5h-11a.5.5 0 0 1-.5-.5V5z"/></>}/>,
  Team:      (p) => <Icon {...p} d={<><circle cx="6" cy="6" r="2"/><circle cx="11" cy="7" r="1.5"/><path d="M2 13c.5-2 2-3 4-3s3.5 1 4 3M10 13c.3-1.5 1.2-2.3 2.5-2.3"/></>}/>,
  Star:      (p) => <Icon {...p} d={<path d="M8 2.5l1.7 3.4 3.8.5-2.7 2.7.6 3.7L8 11l-3.4 1.8.6-3.7L2.5 6.4l3.8-.5L8 2.5z"/>}/>,
  Cmd:       (p) => <Icon {...p} d={<><path d="M5 5h6v6H5z"/><path d="M5 5V3.5a1.5 1.5 0 1 0-1.5 1.5H5zM11 5V3.5A1.5 1.5 0 1 1 12.5 5H11zM5 11v1.5a1.5 1.5 0 1 1-1.5-1.5H5zM11 11v1.5a1.5 1.5 0 1 0 1.5-1.5H11z"/></>}/>,
  Chevron:   (p) => <Icon {...p} d={<path d="M5.5 6.5L8 9l2.5-2.5"/>}/>,
  ChevronR:  (p) => <Icon {...p} d={<path d="M6.5 4.5L9 7 6.5 9.5"/>}/>,
  Comment:   (p) => <Icon {...p} d={<path d="M2.5 8a5.5 5 0 1 1 2.5 4.2L2.5 13l.6-2.3A5 5 0 0 1 2.5 8z"/>}/>,
  Calendar:  (p) => <Icon {...p} d={<><rect x="2.5" y="3.5" width="11" height="10" rx="1"/><path d="M2.5 6.5h11M5.5 2v3M10.5 2v3"/></>}/>,
  Bug:       (p) => <Icon {...p} d={<><rect x="5" y="5" width="6" height="7" rx="3"/><path d="M5 7L3 6M11 7l2-1M5 11l-2 1M11 11l2 1M8 5V3M6 4l-1-1M10 4l1-1"/></>}/>,
  Dot:       (p) => <Icon {...p} d={<circle cx="8" cy="8" r="2"/>}/>,
  Lightning: (p) => <Icon {...p} d={<path d="M9.5 2L4 9h3.5l-1 5L13 7H9.5l1-5z"/>}/>,
  Settings:  (p) => <Icon {...p} d={<><circle cx="8" cy="8" r="2"/><path d="M8 1.5v2M8 12.5v2M14.5 8h-2M3.5 8h-2M12.6 3.4l-1.4 1.4M4.8 11.2l-1.4 1.4M12.6 12.6l-1.4-1.4M4.8 4.8L3.4 3.4"/></>}/>,
  More:      (p) => <Icon {...p} d={<><circle cx="3.5" cy="8" r=".8" fill="currentColor"/><circle cx="8" cy="8" r=".8" fill="currentColor"/><circle cx="12.5" cy="8" r=".8" fill="currentColor"/></>}/>,
  Link:      (p) => <Icon {...p} d={<><path d="M7 9l2-2"/><path d="M6 6l-1.5 1.5a2.1 2.1 0 0 0 3 3L9 9"/><path d="M10 10l1.5-1.5a2.1 2.1 0 0 0-3-3L7 7"/></>}/>,
  Branch:    (p) => <Icon {...p} d={<><circle cx="4" cy="3.5" r="1.5"/><circle cx="4" cy="12.5" r="1.5"/><circle cx="12" cy="6" r="1.5"/><path d="M4 5v6M4 9c0-2 8-1 8-3"/></>}/>,
  Close:     (p) => <Icon {...p} d={<path d="M4 4l8 8M12 4l-8 8"/>}/>,
  ArrowUp:   (p) => <Icon {...p} d={<path d="M8 12V4M4.5 7.5L8 4l3.5 3.5"/>}/>,
  Sparkle:   (p) => <Icon {...p} d={<><path d="M8 2v3M8 11v3M2 8h3M11 8h3M4 4l2 2M10 10l2 2M4 12l2-2M10 6l2-2"/></>}/>,
};

// Avatar — circular monogram
function Avatar({ user, size = 20, ring = false }) {
  if (!user) return null;
  const fontSize = Math.max(8, Math.round(size * 0.42));
  return (
    <div style={{
      width: size, height: size, borderRadius: "50%",
      background: user.color, color: "#fff", flexShrink: 0,
      display: "flex", alignItems: "center", justifyContent: "center",
      fontSize, fontWeight: 600, letterSpacing: -0.2,
      boxShadow: ring ? "0 0 0 2px var(--surface, #fff)" : "inset 0 0 0 0.5px rgba(0,0,0,0.1)",
      fontFamily: "-apple-system, BlinkMacSystemFont, sans-serif",
    }}>{user.initials}</div>
  );
}

function AvatarStack({ users, size = 18, max = 3 }) {
  const shown = users.slice(0, max);
  return (
    <div style={{ display: "flex" }}>
      {shown.map((u, i) => (
        <div key={u.id} style={{ marginLeft: i === 0 ? 0 : -size * 0.35, position: "relative", zIndex: shown.length - i }}>
          <Avatar user={u} size={size} ring />
        </div>
      ))}
    </div>
  );
}

// Status indicator — small filled circle (like Linear)
function StatusDot({ status, size = 12 }) {
  const s = KAIJU_STATUSES.find(x => x.id === status);
  if (!s) return null;
  // donut: progress increases with status rank
  const idx = KAIJU_STATUSES.indexOf(s);
  const pct = idx / (KAIJU_STATUSES.length - 1);
  return (
    <svg width={size} height={size} viewBox="0 0 16 16" style={{ flexShrink: 0 }}>
      <circle cx="8" cy="8" r="6" fill="none" stroke={s.color} strokeWidth="1.5" opacity="0.4"/>
      {pct > 0 && pct < 1 && (
        <circle cx="8" cy="8" r="3" fill="none" stroke={s.color} strokeWidth="6"
                strokeDasharray={`${pct * 18.85} 18.85`} transform="rotate(-90 8 8)"/>
      )}
      {pct === 1 && (
        <>
          <circle cx="8" cy="8" r="6" fill={s.color}/>
          <path d="M5 8l2 2 4-4" stroke="#fff" strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
        </>
      )}
    </svg>
  );
}

// Priority — bar chart icon (Linear style)
function PriorityIcon({ priority, size = 12 }) {
  const p = KAIJU_PRIORITIES[priority];
  if (!p) return null;
  if (priority === "urgent") {
    return (
      <svg width={size} height={size} viewBox="0 0 16 16" style={{ flexShrink: 0 }}>
        <rect x="1.5" y="1.5" width="13" height="13" rx="3" fill={p.color}/>
        <path d="M8 4.5v4.5M8 11v.5" stroke="#fff" strokeWidth="1.6" strokeLinecap="round"/>
      </svg>
    );
  }
  if (priority === "none") {
    return (
      <svg width={size} height={size} viewBox="0 0 16 16" style={{ flexShrink: 0, opacity: 0.5 }}>
        <path d="M3 8h10" stroke={p.color} strokeWidth="1.5" strokeLinecap="round" strokeDasharray="1.8 1.8"/>
      </svg>
    );
  }
  // bars: low=1, med=2, high=3
  const bars = priority === "high" ? 3 : priority === "med" ? 2 : 1;
  return (
    <svg width={size} height={size} viewBox="0 0 16 16" style={{ flexShrink: 0 }}>
      {[0, 1, 2].map(i => (
        <rect key={i} x={2 + i * 4} y={11 - i * 3} width="2.5" height={2 + i * 3}
              rx="0.5" fill={p.color} opacity={i < bars ? 1 : 0.25}/>
      ))}
    </svg>
  );
}

// Label chip — colored dot + text
function LabelChip({ labelKey, size = "sm" }) {
  const l = KAIJU_LABELS[labelKey];
  if (!l) return null;
  const fs = size === "xs" ? 10 : 11;
  return (
    <span style={{
      display: "inline-flex", alignItems: "center", gap: 5,
      height: 18, padding: "0 7px",
      borderRadius: 9, fontSize: fs, fontWeight: 500,
      color: l.color,
      background: `color-mix(in oklch, ${l.color} 12%, transparent)`,
      border: `0.5px solid color-mix(in oklch, ${l.color} 25%, transparent)`,
      whiteSpace: "nowrap",
    }}>
      <span style={{ width: 5, height: 5, borderRadius: "50%", background: l.color }}/>
      {l.name}
    </span>
  );
}

// Lookup helpers
const findUser  = (id) => KAIJU_USERS.find(u => u.id === id);
const findIssue = (id) => KAIJU_ISSUES.find(i => i.id === id);

// Stable reorder helper (used during drag)
function moveItem(arr, from, to) {
  const next = [...arr];
  const [item] = next.splice(from, 1);
  next.splice(to, 0, item);
  return next;
}

Object.assign(window, {
  Icons, Avatar, AvatarStack, StatusDot, PriorityIcon, LabelChip,
  findUser, findIssue, moveItem,
});

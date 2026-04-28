// Kaiju app shell — shared state & interactions across all 3 variations.

// `var` allows redeclaration across sibling Babel scripts (each transpiles to
// the same global scope). `const` would throw "already declared".
var useState = React.useState;
var useEffect = React.useEffect;
var useRef = React.useRef;
var useMemo = React.useMemo;
var useCallback = React.useCallback;

// ─────────────────────────────────────────────────────────────
// Drag and drop hook — uses HTML5 dragstart/over/drop
// ─────────────────────────────────────────────────────────────
function useBoardDnD(issues, setIssues) {
  const [dragId, setDragId] = useState(null);
  const [hoverCol, setHoverCol] = useState(null);

  const onDragStart = (e, id) => {
    setDragId(id);
    e.dataTransfer.effectAllowed = "move";
    try { e.dataTransfer.setData("text/plain", id); } catch (_) {}
  };
  const onDragEnd = () => { setDragId(null); setHoverCol(null); };
  const onDragOverCol = (e, statusId) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = "move";
    if (hoverCol !== statusId) setHoverCol(statusId);
  };
  const onDropCol = (e, statusId) => {
    e.preventDefault();
    if (!dragId) return;
    setIssues(prev => prev.map(i => i.id === dragId ? { ...i, status: statusId } : i));
    setDragId(null); setHoverCol(null);
  };
  return { dragId, hoverCol, onDragStart, onDragEnd, onDragOverCol, onDropCol };
}

// ─────────────────────────────────────────────────────────────
// Command palette — fuzzy filter over issues + actions
// ─────────────────────────────────────────────────────────────
function CommandPalette({ open, onClose, issues, onJump, onAction, dark }) {
  const [q, setQ] = useState("");
  const [sel, setSel] = useState(0);
  const inputRef = useRef(null);

  useEffect(() => {
    if (open) { setQ(""); setSel(0); setTimeout(() => inputRef.current?.focus(), 30); }
  }, [open]);

  const actions = [
    { id: "act-new",      icon: "Plus",      label: "New issue",                hint: "C" },
    { id: "act-search",   icon: "Search",    label: "Search everything",        hint: "/" },
    { id: "act-filter",   icon: "Filter",    label: "Filter board…",            hint: "F" },
    { id: "act-theme",    icon: "Sparkle",   label: "Toggle appearance",        hint: "⌘⇧L" },
  ];

  const matches = useMemo(() => {
    const ql = q.toLowerCase().trim();
    const issueMatches = issues.filter(i =>
      !ql || i.id.toLowerCase().includes(ql) || i.title.toLowerCase().includes(ql)
    ).slice(0, 8).map(i => ({ kind: "issue", item: i }));
    const actionMatches = actions.filter(a =>
      !ql || a.label.toLowerCase().includes(ql)
    ).map(a => ({ kind: "action", item: a }));
    return [...actionMatches, ...issueMatches];
  }, [q, issues]);

  const onKey = (e) => {
    if (e.key === "Escape") { e.preventDefault(); onClose(); }
    else if (e.key === "ArrowDown") { e.preventDefault(); setSel(s => Math.min(s + 1, matches.length - 1)); }
    else if (e.key === "ArrowUp")   { e.preventDefault(); setSel(s => Math.max(s - 1, 0)); }
    else if (e.key === "Enter") {
      e.preventDefault();
      const m = matches[sel];
      if (!m) return;
      if (m.kind === "issue") { onJump(m.item.id); onClose(); }
      else { onAction(m.item.id); onClose(); }
    }
  };

  if (!open) return null;
  const fg = dark ? "rgba(255,255,255,0.94)" : "rgba(0,0,0,0.86)";
  const muted = dark ? "rgba(255,255,255,0.55)" : "rgba(0,0,0,0.5)";
  const hairline = dark ? "rgba(255,255,255,0.08)" : "rgba(0,0,0,0.06)";
  const selBg = dark ? "rgba(255,255,255,0.08)" : "rgba(0,0,0,0.05)";

  return (
    <div onClick={onClose} style={{
      position: "absolute", inset: 0, zIndex: 50,
      display: "flex", alignItems: "flex-start", justifyContent: "center",
      paddingTop: 110, background: "rgba(0,0,0,0.18)",
      backdropFilter: "blur(2px)", WebkitBackdropFilter: "blur(2px)",
    }}>
      <div onClick={e => e.stopPropagation()} style={{
        width: 560, maxHeight: 460, overflow: "hidden",
        borderRadius: 14, color: fg,
        background: dark ? "rgba(38,38,42,0.78)" : "rgba(255,255,255,0.82)",
        backdropFilter: "blur(40px) saturate(180%)",
        WebkitBackdropFilter: "blur(40px) saturate(180%)",
        border: `0.5px solid ${dark ? "rgba(255,255,255,0.12)" : "rgba(0,0,0,0.08)"}`,
        boxShadow: "0 20px 60px rgba(0,0,0,0.35), 0 0 0 0.5px rgba(0,0,0,0.05)",
      }}>
        <div style={{
          display: "flex", alignItems: "center", gap: 10,
          padding: "14px 16px", borderBottom: `0.5px solid ${hairline}`,
        }}>
          <div style={{ color: muted }}><Icons.Search size={16}/></div>
          <input ref={inputRef} value={q} onChange={e => { setQ(e.target.value); setSel(0); }} onKeyDown={onKey}
                 placeholder="Search issues, run command…"
                 style={{
                   flex: 1, background: "transparent", border: "none", outline: "none",
                   fontSize: 15, color: fg, fontFamily: "inherit",
                 }}/>
          <kbd style={{
            padding: "2px 6px", borderRadius: 4, fontSize: 11,
            background: hairline, color: muted, fontFamily: "inherit",
          }}>esc</kbd>
        </div>
        <div style={{ maxHeight: 380, overflow: "auto", padding: 6 }}>
          {matches.length === 0 && (
            <div style={{ padding: 20, textAlign: "center", color: muted, fontSize: 13 }}>No results</div>
          )}
          {matches.map((m, idx) => {
            const selected = idx === sel;
            const item = m.item;
            return (
              <div key={`${m.kind}-${item.id}`} onMouseEnter={() => setSel(idx)}
                   onClick={() => { if (m.kind === "issue") { onJump(item.id); onClose(); } else { onAction(item.id); onClose(); } }}
                   style={{
                     display: "flex", alignItems: "center", gap: 10,
                     padding: "8px 10px", borderRadius: 8, cursor: "pointer",
                     background: selected ? selBg : "transparent",
                   }}>
                {m.kind === "issue" ? (
                  <>
                    <StatusDot status={item.status} size={14}/>
                    <span style={{ fontSize: 11, fontVariantNumeric: "tabular-nums", color: muted, minWidth: 56 }}>{item.id}</span>
                    <span style={{ flex: 1, fontSize: 13, color: fg, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{item.title}</span>
                    <PriorityIcon priority={item.priority} size={12}/>
                  </>
                ) : (
                  <>
                    <div style={{ color: muted }}>{Icons[item.icon]?.({ size: 14 })}</div>
                    <span style={{ flex: 1, fontSize: 13, color: fg }}>{item.label}</span>
                    <kbd style={{ fontSize: 10, color: muted, padding: "1px 5px", borderRadius: 3, background: hairline }}>{item.hint}</kbd>
                  </>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Inspector — slide-in right panel for an issue
// ─────────────────────────────────────────────────────────────
function Inspector({ issue, onClose, dark, accent, onStatusChange }) {
  const [statusOpen, setStatusOpen] = useState(false);
  if (!issue) return null;
  const u = findUser(issue.assignee);
  const fg     = dark ? "rgba(255,255,255,0.94)" : "rgba(0,0,0,0.86)";
  const muted  = dark ? "rgba(255,255,255,0.55)" : "rgba(0,0,0,0.5)";
  const subtle = dark ? "rgba(255,255,255,0.42)" : "rgba(0,0,0,0.42)";
  const hairline = dark ? "rgba(255,255,255,0.08)" : "rgba(0,0,0,0.07)";
  const surface  = dark ? "rgba(28,28,30,0.86)"   : "rgba(255,255,255,0.85)";
  const fieldBg  = dark ? "rgba(255,255,255,0.05)" : "rgba(0,0,0,0.03)";

  const status = KAIJU_STATUSES.find(s => s.id === issue.status);

  const Field = ({ label, children }) => (
    <div style={{ display: "flex", alignItems: "center", gap: 8, padding: "6px 0", fontSize: 12 }}>
      <div style={{ width: 88, color: muted, flexShrink: 0 }}>{label}</div>
      <div style={{ flex: 1, display: "flex", alignItems: "center", gap: 6, color: fg }}>{children}</div>
    </div>
  );

  return (
    <div style={{
      position: "absolute", top: 0, right: 0, bottom: 0,
      width: 360, zIndex: 30,
      background: surface,
      backdropFilter: "blur(40px) saturate(180%)",
      WebkitBackdropFilter: "blur(40px) saturate(180%)",
      borderLeft: `0.5px solid ${hairline}`,
      boxShadow: "-8px 0 32px rgba(0,0,0,0.12)",
      display: "flex", flexDirection: "column", color: fg,
      animation: "kjSlideIn 0.22s cubic-bezier(.2,.7,.3,1)",
    }}>
      <style>{`@keyframes kjSlideIn { from { transform: translateX(20px); opacity: 0; } to { transform: translateX(0); opacity: 1; } }`}</style>

      {/* Header */}
      <div style={{
        display: "flex", alignItems: "center", gap: 8,
        padding: "12px 14px", borderBottom: `0.5px solid ${hairline}`,
      }}>
        <span style={{ fontSize: 11, fontVariantNumeric: "tabular-nums", color: muted, fontWeight: 500 }}>{issue.id}</span>
        <div style={{ flex: 1 }}/>
        <button onClick={onClose} style={{
          width: 22, height: 22, borderRadius: 5, border: "none", cursor: "pointer",
          background: "transparent", color: muted,
          display: "flex", alignItems: "center", justifyContent: "center",
        }}><Icons.Close size={12}/></button>
      </div>

      {/* Body */}
      <div style={{ flex: 1, overflow: "auto", padding: "16px 18px" }}>
        <h2 style={{ fontSize: 18, fontWeight: 600, lineHeight: 1.3, margin: "0 0 14px", letterSpacing: -0.2 }}>
          {issue.title}
        </h2>

        {/* Properties */}
        <div style={{ marginBottom: 18, padding: "4px 0", borderTop: `0.5px solid ${hairline}`, borderBottom: `0.5px solid ${hairline}` }}>
          <Field label="Status">
            <div style={{ position: "relative" }}>
              <button onClick={() => setStatusOpen(o => !o)} style={{
                display: "flex", alignItems: "center", gap: 6, padding: "3px 8px 3px 6px",
                background: fieldBg, border: "none", borderRadius: 6, cursor: "pointer",
                color: fg, fontSize: 12, fontFamily: "inherit",
              }}>
                <StatusDot status={issue.status} size={12}/>
                {status.name}
                <Icons.Chevron size={10}/>
              </button>
              {statusOpen && (
                <>
                  <div onClick={() => setStatusOpen(false)} style={{ position: "fixed", inset: 0, zIndex: 1 }}/>
                  <div style={{
                    position: "absolute", top: "100%", left: 0, marginTop: 4, zIndex: 2,
                    minWidth: 160, padding: 4, borderRadius: 8,
                    background: dark ? "rgba(48,48,52,0.95)" : "rgba(255,255,255,0.96)",
                    backdropFilter: "blur(30px)",
                    border: `0.5px solid ${hairline}`,
                    boxShadow: "0 8px 24px rgba(0,0,0,0.18)",
                  }}>
                    {KAIJU_STATUSES.map(s => (
                      <button key={s.id} onClick={() => { onStatusChange(issue.id, s.id); setStatusOpen(false); }} style={{
                        display: "flex", alignItems: "center", gap: 8, width: "100%",
                        padding: "5px 8px", border: "none", background: s.id === issue.status ? fieldBg : "transparent",
                        borderRadius: 5, cursor: "pointer", color: fg, fontSize: 12, fontFamily: "inherit",
                      }}>
                        <StatusDot status={s.id} size={12}/>{s.name}
                      </button>
                    ))}
                  </div>
                </>
              )}
            </div>
          </Field>
          <Field label="Priority">
            <PriorityIcon priority={issue.priority} size={12}/>
            {KAIJU_PRIORITIES[issue.priority].name}
          </Field>
          <Field label="Assignee">
            {u && <Avatar user={u} size={18}/>}
            {u?.name}
          </Field>
          <Field label="Labels">
            <div style={{ display: "flex", flexWrap: "wrap", gap: 4 }}>
              {issue.labels.map(l => <LabelChip key={l} labelKey={l}/>)}
            </div>
          </Field>
          <Field label="Estimate">{issue.estimate} pts</Field>
          <Field label="Created">{issue.created}</Field>
        </div>

        {/* Description */}
        <div style={{ fontSize: 13, lineHeight: 1.6, whiteSpace: "pre-wrap", color: fg }}>
          {KAIJU_DETAIL_DESCRIPTION.split("\n").map((p, i) => <p key={i} style={{ margin: "0 0 12px" }}>{p}</p>)}
        </div>

        {/* Activity */}
        <div style={{ marginTop: 24, fontSize: 11, color: muted, fontWeight: 600, letterSpacing: 0.5, textTransform: "uppercase" }}>Activity</div>
        <div style={{ marginTop: 10, display: "flex", flexDirection: "column", gap: 10 }}>
          {KAIJU_ACTIVITY.map((a, i) => {
            const who = findUser(a.who);
            return (
              <div key={i} style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 12 }}>
                <Avatar user={who} size={18}/>
                <span style={{ color: fg, fontWeight: 500 }}>{who.name.split(" ")[0]}</span>
                <span style={{ color: muted }}>{a.what}</span>
                {a.meta && <span style={{ padding: "1px 6px", background: fieldBg, borderRadius: 4, fontSize: 11, color: fg }}>{a.meta}</span>}
                <div style={{ flex: 1 }}/>
                <span style={{ color: subtle }}>{a.when}</span>
              </div>
            );
          })}
        </div>
      </div>

      {/* Comment composer */}
      <div style={{ padding: 12, borderTop: `0.5px solid ${hairline}` }}>
        <div style={{
          display: "flex", alignItems: "center", gap: 8, padding: "8px 10px",
          background: fieldBg, borderRadius: 8,
          border: `0.5px solid ${hairline}`,
        }}>
          <Avatar user={KAIJU_USERS[0]} size={18}/>
          <input placeholder="Leave a comment…" style={{
            flex: 1, background: "transparent", border: "none", outline: "none",
            fontSize: 12, color: fg, fontFamily: "inherit",
          }}/>
          <span style={{ color: muted, display: "flex" }}><Icons.ArrowUp size={12}/></span>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { useBoardDnD, CommandPalette, Inspector });

// ─────────────────────────────────────────────────────────────
// Kaiju · Variation 2 — Monochrome Minimal (Things-3 inspired)
// Calm warm grays, lots of whitespace, hairline dividers,
// content over chrome. Sidebar is a floating panel but quieter.
// ─────────────────────────────────────────────────────────────

function MonoApp({ dark = false, accent = "#1F1F1F" }) {
  const [issues, setIssues] = useState(KAIJU_ISSUES);
  const [activeNav, setActiveNav] = useState("board");
  const [paletteOpen, setPaletteOpen] = useState(false);
  const [selectedId, setSelectedId] = useState(null);
  const [filter, setFilter] = useState("");

  useEffect(() => {
    const onKey = (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") { e.preventDefault(); setPaletteOpen(true); }
      if (e.key === "Escape") { setPaletteOpen(false); setSelectedId(null); }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  const dnd = useBoardDnD(issues, setIssues);
  const setStatus = (id, status) => setIssues(prev => prev.map(i => i.id === id ? { ...i, status } : i));

  const filtered = filter
    ? issues.filter(i => i.title.toLowerCase().includes(filter.toLowerCase()) || i.id.toLowerCase().includes(filter.toLowerCase()))
    : issues;

  // Warm-tinted neutrals
  const bg     = dark ? "#1c1b1a" : "#f6f4f0";
  const sideBg = dark ? "rgba(40,38,36,0.7)" : "rgba(252,250,247,0.65)";
  const cardBg = dark ? "#27262410" : "#ffffff";
  const fg     = dark ? "rgba(255,250,240,0.92)" : "rgba(28,24,20,0.88)";
  const muted  = dark ? "rgba(255,250,240,0.5)"  : "rgba(28,24,20,0.5)";
  const subtle = dark ? "rgba(255,250,240,0.32)" : "rgba(28,24,20,0.32)";
  const hair   = dark ? "rgba(255,250,240,0.07)" : "rgba(28,24,20,0.07)";
  const colBg  = dark ? "transparent" : "transparent";
  const accentEffective = dark ? "#F5F1EA" : accent;

  const selected = issues.find(i => i.id === selectedId);

  return (
    <div style={{
      width: "100%", height: "100%", display: "flex", position: "relative",
      background: bg, fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif',
      color: fg, overflow: "hidden",
    }}>
      {/* Sidebar */}
      <div style={{
        width: 220, padding: "10px 0", flexShrink: 0,
        background: sideBg,
        borderRight: `0.5px solid ${hair}`,
        display: "flex", flexDirection: "column",
        backdropFilter: "blur(40px)", WebkitBackdropFilter: "blur(40px)",
      }}>
        <div style={{ padding: "4px 14px 18px", display: "flex", gap: 8 }}>
          <div style={{ width: 12, height: 12, borderRadius: "50%", background: "#ff5f57", border: "0.5px solid rgba(0,0,0,0.1)" }}/>
          <div style={{ width: 12, height: 12, borderRadius: "50%", background: "#febc2e", border: "0.5px solid rgba(0,0,0,0.1)" }}/>
          <div style={{ width: 12, height: 12, borderRadius: "50%", background: "#28c840", border: "0.5px solid rgba(0,0,0,0.1)" }}/>
        </div>

        <div style={{ padding: "0 18px 16px" }}>
          <div style={{ fontSize: 18, fontWeight: 700, letterSpacing: -0.4, color: fg }}>Kaiju</div>
          <div style={{ fontSize: 11, color: muted, marginTop: 2 }}>Acme · Web Platform</div>
        </div>

        <div style={{ padding: "0 12px" }}>
          {KAIJU_SIDEBAR.myWork.map(n => (
            <MonoNavRow key={n.id} item={n} active={activeNav === n.id} onClick={() => setActiveNav(n.id)}
                        fg={fg} muted={muted} accent={accentEffective}/>
          ))}
        </div>

        <div style={{ height: 18 }}/>
        <div style={{ padding: "0 18px 6px", fontSize: 10, fontWeight: 600, letterSpacing: 0.7, textTransform: "uppercase", color: subtle }}>Workspace</div>
        <div style={{ padding: "0 12px" }}>
          {KAIJU_SIDEBAR.workspaceItems.map(n => (
            <MonoNavRow key={n.id} item={n} active={activeNav === n.id} onClick={() => setActiveNav(n.id)}
                        fg={fg} muted={muted} accent={accentEffective}/>
          ))}
        </div>

        <div style={{ height: 18 }}/>
        <div style={{ padding: "0 18px 6px", fontSize: 10, fontWeight: 600, letterSpacing: 0.7, textTransform: "uppercase", color: subtle }}>Saved filters</div>
        <div style={{ padding: "0 12px" }}>
          {KAIJU_SIDEBAR.filters.map(f => (
            <div key={f.id} style={{ display: "flex", alignItems: "center", gap: 9, padding: "5px 8px", fontSize: 12.5, color: fg, cursor: "pointer", borderRadius: 5 }}>
              <div style={{ width: 6, height: 6, borderRadius: "50%", background: f.color }}/>
              <span>{f.label}</span>
            </div>
          ))}
        </div>

        <div style={{ flex: 1 }}/>

        <div style={{ padding: "12px 18px", borderTop: `0.5px solid ${hair}`, display: "flex", alignItems: "center", gap: 9 }}>
          <Avatar user={KAIJU_USERS[0]} size={22}/>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 12, fontWeight: 600, color: fg }}>{KAIJU_USERS[0].name}</div>
            <div style={{ fontSize: 10.5, color: muted }}>Online</div>
          </div>
        </div>
      </div>

      {/* Main */}
      <div style={{ flex: 1, display: "flex", flexDirection: "column", position: "relative", minWidth: 0 }}>
        {/* Toolbar */}
        <div style={{
          display: "flex", alignItems: "center", gap: 14,
          padding: "16px 28px 10px", flexShrink: 0,
        }}>
          <div>
            <h1 style={{ margin: 0, fontSize: 22, fontWeight: 700, letterSpacing: -0.5, color: fg }}>Board</h1>
            <div style={{ fontSize: 12, color: muted, marginTop: 2 }}>{issues.length} issues · Sprint 24 · Apr 22 — May 6</div>
          </div>

          <div style={{ flex: 1 }}/>

          <div style={{
            display: "flex", alignItems: "center", gap: 6, height: 28, padding: "0 10px",
            borderRadius: 7, background: cardBg, border: `0.5px solid ${hair}`, minWidth: 220,
          }}>
            <span style={{ color: muted, display: "flex" }}><Icons.Search size={12}/></span>
            <input value={filter} onChange={e => setFilter(e.target.value)}
                   placeholder="Filter…" style={{
              flex: 1, background: "transparent", border: "none", outline: "none",
              fontSize: 12, color: fg, fontFamily: "inherit",
            }}/>
            <kbd style={{ fontSize: 10, color: subtle, padding: "0 4px", border: `0.5px solid ${hair}`, borderRadius: 3 }}>/</kbd>
          </div>

          <button onClick={() => setPaletteOpen(true)} style={{
            display: "flex", alignItems: "center", gap: 5, height: 28, padding: "0 10px",
            borderRadius: 7, border: `0.5px solid ${hair}`, background: cardBg,
            cursor: "pointer", color: muted, fontFamily: "inherit", fontSize: 11,
          }}>
            <Icons.Cmd size={11}/>K
          </button>

          <button style={{
            display: "flex", alignItems: "center", gap: 5, height: 28, padding: "0 12px",
            borderRadius: 7, border: "none", cursor: "pointer",
            background: accentEffective, color: dark ? "#1c1b1a" : "#f6f4f0",
            fontSize: 12, fontWeight: 600, fontFamily: "inherit",
          }}>
            <Icons.Plus size={11}/>New issue
          </button>
        </div>

        {/* Board */}
        <div style={{
          flex: 1, display: "grid", gridAutoFlow: "column", gridAutoColumns: "minmax(260px, 1fr)",
          gap: 1, overflow: "auto", padding: "12px 0 16px",
          background: hair,
          margin: "0 28px",
          borderRadius: 10,
          border: `0.5px solid ${hair}`,
        }}>
          {KAIJU_STATUSES.map((s, idx) => {
            const colIssues = filtered.filter(i => i.status === s.id);
            const isHover = dnd.hoverCol === s.id;
            return (
              <div key={s.id}
                   onDragOver={(e) => dnd.onDragOverCol(e, s.id)}
                   onDrop={(e) => dnd.onDropCol(e, s.id)}
                   style={{
                     display: "flex", flexDirection: "column",
                     background: isHover ? (dark ? "rgba(255,255,255,0.02)" : "rgba(0,0,0,0.015)") : bg,
                     transition: "background 0.12s",
                     borderRadius: idx === 0 ? "10px 0 0 10px" : idx === KAIJU_STATUSES.length - 1 ? "0 10px 10px 0" : 0,
                     minHeight: 0,
                   }}>
                {/* Column header */}
                <div style={{
                  display: "flex", alignItems: "center", gap: 8, padding: "14px 16px 10px",
                }}>
                  <span style={{ fontSize: 12, fontWeight: 600, letterSpacing: -0.1, color: fg }}>{s.name}</span>
                  <span style={{ fontSize: 11, color: subtle, fontVariantNumeric: "tabular-nums" }}>{colIssues.length}</span>
                  <div style={{ flex: 1 }}/>
                  <button style={{
                    width: 18, height: 18, borderRadius: 4, border: "none",
                    background: "transparent", cursor: "pointer", color: muted,
                    display: "flex", alignItems: "center", justifyContent: "center", opacity: 0.7,
                  }}><Icons.Plus size={11}/></button>
                </div>
                <div style={{ height: 1, background: hair, margin: "0 12px" }}/>

                <div style={{ padding: "8px 12px 12px", display: "flex", flexDirection: "column", gap: 1, overflow: "auto", flex: 1 }}>
                  {colIssues.map(issue => (
                    <MonoCard key={issue.id} issue={issue}
                              onClick={() => setSelectedId(issue.id)}
                              dnd={dnd} fg={fg} muted={muted} subtle={subtle} hair={hair} dark={dark}/>
                  ))}
                  {colIssues.length === 0 && (
                    <div style={{ padding: "16px 8px", textAlign: "center", color: subtle, fontSize: 11 }}>—</div>
                  )}
                </div>
              </div>
            );
          })}
        </div>

        <Inspector issue={selected} onClose={() => setSelectedId(null)} dark={dark} accent={accentEffective} onStatusChange={setStatus}/>
        <CommandPalette open={paletteOpen} onClose={() => setPaletteOpen(false)} issues={issues}
                        onJump={setSelectedId} onAction={() => {}} dark={dark}/>
      </div>
    </div>
  );
}

function MonoNavRow({ item, active, onClick, fg, muted, accent }) {
  return (
    <button onClick={onClick} style={{
      display: "flex", alignItems: "center", gap: 9,
      width: "100%", height: 28, padding: "0 8px",
      borderRadius: 5, cursor: "pointer", border: "none", textAlign: "left",
      background: active ? "rgba(0,0,0,0.05)" : "transparent",
      color: fg, fontFamily: "inherit", fontSize: 12.5, fontWeight: active ? 600 : 500,
    }}>
      <span style={{ flex: 1, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{item.label}</span>
      {item.count !== undefined && (
        <span style={{ fontSize: 11, color: muted, fontVariantNumeric: "tabular-nums" }}>{item.count}</span>
      )}
    </button>
  );
}

function MonoCard({ issue, onClick, dnd, fg, muted, subtle, hair, dark }) {
  const u = findUser(issue.assignee);
  const isDragging = dnd.dragId === issue.id;
  return (
    <div draggable
         onDragStart={(e) => dnd.onDragStart(e, issue.id)}
         onDragEnd={dnd.onDragEnd}
         onClick={onClick}
         style={{
           padding: "8px 10px", borderRadius: 6, cursor: "pointer",
           background: "transparent",
           opacity: isDragging ? 0.4 : 1,
           borderBottom: `0.5px solid ${hair}`,
         }}>
      <div style={{ display: "flex", alignItems: "flex-start", gap: 8 }}>
        <div style={{ paddingTop: 1 }}>
          <PriorityIcon priority={issue.priority} size={11}/>
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 12.5, color: fg, lineHeight: 1.4, fontWeight: 500, textWrap: "pretty" }}>
            {issue.title}
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 8, marginTop: 5, fontSize: 11, color: subtle }}>
            <span style={{ fontVariantNumeric: "tabular-nums", fontWeight: 500 }}>{issue.id}</span>
            {issue.labels.slice(0, 1).map(l => <LabelChip key={l} labelKey={l}/>)}
            <div style={{ flex: 1 }}/>
            {issue.comments > 0 && (
              <span style={{ display: "inline-flex", alignItems: "center", gap: 3 }}>
                <Icons.Comment size={10}/>{issue.comments}
              </span>
            )}
            {u && <Avatar user={u} size={15}/>}
          </div>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { MonoApp });

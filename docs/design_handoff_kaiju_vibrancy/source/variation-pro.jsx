// ─────────────────────────────────────────────────────────────
// Kaiju · Variation 3 — Pro Tool / IDE-density (Xcode/Tower vibe)
// Dense rows, monospace IDs, segmented control toolbar, source-list
// sidebar with tight rows. Higher info density per square inch.
// ─────────────────────────────────────────────────────────────

function ProApp({ dark = false, accent = "#0A84FF" }) {
  const [issues, setIssues] = useState(KAIJU_ISSUES);
  const [activeNav, setActiveNav] = useState("board");
  const [paletteOpen, setPaletteOpen] = useState(false);
  const [selectedId, setSelectedId] = useState(null);
  const [filter, setFilter] = useState("");
  const [groupBy, setGroupBy] = useState("status");

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

  // Cool tinted neutrals — slightly desaturated blue-grays
  const bg     = dark ? "#1d1f23" : "#f3f4f6";
  const sideBg = dark ? "#26282d" : "#ebecef";
  const cardBg = dark ? "#2c2e33" : "#ffffff";
  const colBg  = dark ? "#212327" : "#e9eaed";
  const fg     = dark ? "rgba(255,255,255,0.92)" : "rgba(15,20,28,0.9)";
  const muted  = dark ? "rgba(255,255,255,0.55)" : "rgba(15,20,28,0.55)";
  const subtle = dark ? "rgba(255,255,255,0.38)" : "rgba(15,20,28,0.38)";
  const hair   = dark ? "rgba(255,255,255,0.07)" : "rgba(15,20,28,0.08)";
  const mono   = '"SF Mono", ui-monospace, "JetBrains Mono", Menlo, monospace';

  const selected = issues.find(i => i.id === selectedId);

  return (
    <div style={{
      width: "100%", height: "100%", display: "flex", flexDirection: "column", position: "relative",
      background: bg, fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif',
      color: fg, overflow: "hidden", fontSize: 12,
    }}>
      {/* Title bar — full-width, dense */}
      <div style={{
        height: 38, flexShrink: 0, display: "flex", alignItems: "center", gap: 10,
        padding: "0 12px",
        background: dark ? "#2a2c30" : "#dfe1e5",
        borderBottom: `0.5px solid ${hair}`,
      }}>
        <div style={{ display: "flex", gap: 8 }}>
          <div style={{ width: 12, height: 12, borderRadius: "50%", background: "#ff5f57", border: "0.5px solid rgba(0,0,0,0.1)" }}/>
          <div style={{ width: 12, height: 12, borderRadius: "50%", background: "#febc2e", border: "0.5px solid rgba(0,0,0,0.1)" }}/>
          <div style={{ width: 12, height: 12, borderRadius: "50%", background: "#28c840", border: "0.5px solid rgba(0,0,0,0.1)" }}/>
        </div>

        <div style={{ width: 1, height: 16, background: hair, margin: "0 6px" }}/>

        {/* Breadcrumb */}
        <div style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 12, color: muted }}>
          <div style={{
            width: 16, height: 16, borderRadius: 4,
            background: `linear-gradient(135deg, ${accent}, color-mix(in oklch, ${accent} 50%, white))`,
            display: "flex", alignItems: "center", justifyContent: "center",
            color: "#fff", fontSize: 9, fontWeight: 700,
          }}>A</div>
          <span style={{ color: fg, fontWeight: 500 }}>Acme</span>
          <span style={{ color: subtle }}>›</span>
          <span style={{ color: fg, fontWeight: 500 }}>Web Platform</span>
          <span style={{ color: subtle }}>›</span>
          <span style={{ color: fg, fontWeight: 600 }}>Board</span>
        </div>

        <div style={{ flex: 1 }}/>

        {/* Segmented control */}
        <div style={{
          display: "flex", height: 24, borderRadius: 5,
          background: dark ? "rgba(0,0,0,0.25)" : "rgba(0,0,0,0.05)",
          padding: 2,
        }}>
          {[
            { id: "board", label: "Board", icon: "Board" },
            { id: "list", label: "List", icon: "List" },
            { id: "sprint", label: "Sprint", icon: "Sprint" },
          ].map(s => {
            const Ico = Icons[s.icon];
            return (
            <button key={s.id} onClick={() => setActiveNav(s.id)} style={{
              display: "flex", alignItems: "center", gap: 4, padding: "0 8px",
              borderRadius: 4, border: "none", cursor: "pointer", fontFamily: "inherit",
              background: activeNav === s.id ? (dark ? "#3d3f44" : "#fff") : "transparent",
              color: activeNav === s.id ? fg : muted,
              fontSize: 11, fontWeight: 500,
              boxShadow: activeNav === s.id ? "0 1px 2px rgba(0,0,0,0.08)" : "none",
            }}>
              <Ico size={11}/>{s.label}
            </button>
            );
          })}
        </div>

        {/* Search */}
        <div style={{
          display: "flex", alignItems: "center", gap: 5, height: 24, padding: "0 8px",
          borderRadius: 5, background: dark ? "rgba(0,0,0,0.25)" : "#fff",
          border: `0.5px solid ${hair}`, minWidth: 200,
        }}>
          <span style={{ color: muted, display: "flex" }}><Icons.Search size={11}/></span>
          <input value={filter} onChange={e => setFilter(e.target.value)}
                 placeholder="Filter (priority:high assignee:me…)"
                 style={{
            flex: 1, background: "transparent", border: "none", outline: "none",
            fontSize: 11, color: fg, fontFamily: mono,
          }}/>
        </div>

        <button onClick={() => setPaletteOpen(true)} title="Command palette (⌘K)" style={{
          width: 24, height: 24, borderRadius: 5, cursor: "pointer",
          background: dark ? "rgba(0,0,0,0.25)" : "#fff", border: `0.5px solid ${hair}`,
          color: muted, display: "flex", alignItems: "center", justifyContent: "center",
        }}><Icons.Cmd size={11}/></button>

        <button style={{
          display: "flex", alignItems: "center", gap: 4, height: 24, padding: "0 9px",
          borderRadius: 5, border: "none", cursor: "pointer",
          background: accent, color: "#fff", fontSize: 11, fontWeight: 600, fontFamily: "inherit",
        }}>
          <Icons.Plus size={10}/>New
        </button>
      </div>

      {/* Body */}
      <div style={{ flex: 1, display: "flex", minHeight: 0 }}>
        {/* Source list sidebar */}
        <div style={{
          width: 200, flexShrink: 0,
          background: sideBg,
          borderRight: `0.5px solid ${hair}`,
          display: "flex", flexDirection: "column",
          padding: "10px 0", fontSize: 11.5,
          overflow: "auto",
        }}>
          <ProSourceHeader title="My Work" muted={subtle}/>
          {KAIJU_SIDEBAR.myWork.map(n => {
            const key = n.id === "inbox" ? "Inbox" : n.id === "assigned" ? "Assigned" : n.id === "created" ? "Created" : "Subscribed";
            const Ico = Icons[key];
            return (
              <ProSourceRow key={n.id} item={n}
                            icon={<Ico size={12}/>}
                            fg={fg} muted={muted} accent={accent} dark={dark}/>
            );
          })}
          <ProSourceHeader title="Workspace" muted={subtle}/>
          {KAIJU_SIDEBAR.workspaceItems.map(n => {
            const key = n.id === "board" ? "Board" : n.id === "list" ? "List" : n.id === "sprints" ? "Sprint" : n.id === "roadmap" ? "Roadmap" : "Projects";
            const Ico = Icons[key];
            return (
              <ProSourceRow key={n.id} item={{...n, active: n.id === "board"}}
                            icon={<Ico size={12}/>}
                            fg={fg} muted={muted} accent={accent} dark={dark}/>
            );
          })}
          <ProSourceHeader title="Teams" muted={subtle}/>
          {KAIJU_SIDEBAR.teams.map(t => (
            <ProSourceRow key={t.id} item={t}
                          icon={<Icons.Team size={12}/>}
                          fg={fg} muted={muted} accent={accent} dark={dark}/>
          ))}
          <ProSourceHeader title="Filters" muted={subtle}/>
          {KAIJU_SIDEBAR.filters.map(f => (
            <ProSourceRow key={f.id} item={{label: f.label}}
                          icon={<div style={{ width: 8, height: 8, borderRadius: 2, background: f.color }}/>}
                          fg={fg} muted={muted} accent={accent} dark={dark}/>
          ))}
        </div>

        {/* Board area */}
        <div style={{ flex: 1, display: "flex", flexDirection: "column", minWidth: 0, position: "relative" }}>
          {/* Sub-toolbar — group by, sort, swimlanes */}
          <div style={{
            height: 30, flexShrink: 0, display: "flex", alignItems: "center", gap: 10,
            padding: "0 12px", borderBottom: `0.5px solid ${hair}`,
            background: dark ? "#26282d" : "#ebecef",
          }}>
            <ProSubMenu label="Group" value="Status" muted={muted} fg={fg} hair={hair}/>
            <ProSubMenu label="Sort" value="Priority" muted={muted} fg={fg} hair={hair}/>
            <ProSubMenu label="Sub-issues" value="Show" muted={muted} fg={fg} hair={hair}/>
            <div style={{ flex: 1 }}/>
            <span style={{ fontSize: 11, color: muted, fontVariantNumeric: "tabular-nums" }}>
              {filtered.length} of {issues.length}
            </span>
            <div style={{ width: 1, height: 14, background: hair }}/>
            <AvatarStack users={KAIJU_USERS.slice(0, 5)} size={18} max={5}/>
          </div>

          {/* Columns */}
          <div style={{
            flex: 1, display: "grid", gridAutoFlow: "column", gridAutoColumns: "minmax(240px, 1fr)",
            gap: 0, overflow: "auto", padding: 0,
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
                       background: isHover ? (dark ? "rgba(10,132,255,0.06)" : "rgba(10,132,255,0.04)") : colBg,
                       borderRight: idx < KAIJU_STATUSES.length - 1 ? `0.5px solid ${hair}` : "none",
                       minHeight: 0,
                     }}>
                  <div style={{
                    display: "flex", alignItems: "center", gap: 7,
                    height: 30, padding: "0 12px",
                    background: dark ? "#2a2c30" : "#dfe1e5",
                    borderBottom: `0.5px solid ${hair}`,
                  }}>
                    <div style={{ width: 7, height: 7, borderRadius: 2, background: s.color }}/>
                    <span style={{ fontSize: 11, fontWeight: 600, color: fg, textTransform: "uppercase", letterSpacing: 0.4 }}>{s.name}</span>
                    <span style={{ fontSize: 10.5, color: subtle, fontFamily: mono, fontVariantNumeric: "tabular-nums" }}>{colIssues.length}</span>
                    <div style={{ flex: 1 }}/>
                    <button style={{
                      width: 18, height: 18, borderRadius: 3, border: "none",
                      background: "transparent", cursor: "pointer", color: muted,
                      display: "flex", alignItems: "center", justifyContent: "center",
                    }}><Icons.Plus size={10}/></button>
                    <button style={{
                      width: 18, height: 18, borderRadius: 3, border: "none",
                      background: "transparent", cursor: "pointer", color: muted,
                      display: "flex", alignItems: "center", justifyContent: "center",
                    }}><Icons.More size={10}/></button>
                  </div>
                  <div style={{ padding: "4px 6px", display: "flex", flexDirection: "column", gap: 4, overflow: "auto", flex: 1 }}>
                    {colIssues.map(issue => (
                      <ProCard key={issue.id} issue={issue}
                               onClick={() => setSelectedId(issue.id)}
                               selected={selectedId === issue.id}
                               dnd={dnd} cardBg={cardBg} hair={hair} fg={fg} muted={muted} subtle={subtle} mono={mono} dark={dark} accent={accent}/>
                    ))}
                  </div>
                </div>
              );
            })}
          </div>

          {/* Status bar */}
          <div style={{
            height: 22, flexShrink: 0, display: "flex", alignItems: "center", gap: 10,
            padding: "0 12px", borderTop: `0.5px solid ${hair}`,
            background: dark ? "#26282d" : "#ebecef",
            fontSize: 10.5, color: muted, fontFamily: mono, fontVariantNumeric: "tabular-nums",
          }}>
            <span>● Synced</span>
            <span style={{ color: subtle }}>2s ago</span>
            <div style={{ flex: 1 }}/>
            <span>main · 142 commits ahead</span>
            <div style={{ width: 1, height: 12, background: hair }}/>
            <span>{KAIJU_USERS.length} members</span>
          </div>

          <Inspector issue={selected} onClose={() => setSelectedId(null)} dark={dark} accent={accent} onStatusChange={setStatus}/>
        </div>
      </div>

      <CommandPalette open={paletteOpen} onClose={() => setPaletteOpen(false)} issues={issues}
                      onJump={setSelectedId} onAction={() => {}} dark={dark}/>
    </div>
  );
}

function ProSourceHeader({ title, muted }) {
  return (
    <div style={{
      padding: "10px 14px 4px", fontSize: 9.5, fontWeight: 700,
      letterSpacing: 0.7, textTransform: "uppercase", color: muted,
    }}>{title}</div>
  );
}

function ProSourceRow({ item, icon, fg, muted, accent, dark }) {
  const active = item.active;
  return (
    <button style={{
      display: "flex", alignItems: "center", gap: 7,
      width: "100%", height: 22, padding: "0 14px",
      cursor: "pointer", border: "none", textAlign: "left", fontFamily: "inherit",
      background: active ? accent : "transparent",
      color: active ? "#fff" : fg, fontSize: 11.5, fontWeight: active ? 600 : 500,
    }}>
      <span style={{ display: "flex", color: active ? "#fff" : muted, opacity: active ? 1 : 0.85 }}>{icon}</span>
      <span style={{ flex: 1, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{item.label}</span>
      {item.count !== undefined && (
        <span style={{ fontSize: 10, color: active ? "rgba(255,255,255,0.85)" : muted, fontVariantNumeric: "tabular-nums" }}>{item.count}</span>
      )}
    </button>
  );
}

function ProSubMenu({ label, value, muted, fg, hair }) {
  return (
    <button style={{
      display: "flex", alignItems: "center", gap: 4, height: 22, padding: "0 8px",
      borderRadius: 4, border: "none", cursor: "pointer", background: "transparent",
      color: muted, fontSize: 11, fontFamily: "inherit",
    }}>
      <span>{label}</span>
      <span style={{ color: fg, fontWeight: 500 }}>{value}</span>
      <Icons.Chevron size={9}/>
    </button>
  );
}

function ProCard({ issue, onClick, selected, dnd, cardBg, hair, fg, muted, subtle, mono, dark, accent }) {
  const u = findUser(issue.assignee);
  const isDragging = dnd.dragId === issue.id;
  return (
    <div draggable
         onDragStart={(e) => dnd.onDragStart(e, issue.id)}
         onDragEnd={dnd.onDragEnd}
         onClick={onClick}
         style={{
           padding: "6px 8px", borderRadius: 5, cursor: "pointer",
           background: cardBg,
           border: `0.5px solid ${selected ? accent : hair}`,
           boxShadow: dark ? "0 1px 0 rgba(0,0,0,0.2)" : "0 1px 0 rgba(15,20,28,0.04)",
           opacity: isDragging ? 0.4 : 1,
           outline: selected ? `1px solid ${accent}` : "none",
           outlineOffset: -1,
         }}>
      {/* Row 1: priority + ID + assignee */}
      <div style={{ display: "flex", alignItems: "center", gap: 6, marginBottom: 4 }}>
        <PriorityIcon priority={issue.priority} size={11}/>
        <span style={{ fontSize: 10, color: muted, fontFamily: mono, fontWeight: 500, fontVariantNumeric: "tabular-nums" }}>{issue.id}</span>
        <div style={{ flex: 1 }}/>
        {issue.comments > 0 && (
          <span style={{ display: "inline-flex", alignItems: "center", gap: 2, fontSize: 10, color: subtle, fontFamily: mono }}>
            <Icons.Comment size={9}/>{issue.comments}
          </span>
        )}
        {u && <Avatar user={u} size={14}/>}
      </div>
      {/* Title */}
      <div style={{ fontSize: 12, lineHeight: 1.35, color: fg, marginBottom: 4, textWrap: "pretty" }}>
        {issue.title}
      </div>
      {/* Footer: labels + estimate */}
      <div style={{ display: "flex", alignItems: "center", gap: 4, flexWrap: "wrap" }}>
        {issue.labels.slice(0, 2).map(l => <LabelChip key={l} labelKey={l}/>)}
        <div style={{ flex: 1 }}/>
        <span style={{
          fontSize: 10, color: muted, fontFamily: mono, fontWeight: 500,
          padding: "0 4px", borderRadius: 3, border: `0.5px solid ${hair}`,
        }}>{issue.estimate}sp</span>
      </div>
    </div>
  );
}

Object.assign(window, { ProApp });

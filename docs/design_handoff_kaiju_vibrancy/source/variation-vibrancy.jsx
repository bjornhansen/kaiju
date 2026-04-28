// ─────────────────────────────────────────────────────────────
// Kaiju · Variation 1 — Translucent Vibrancy (modern macOS)
// Floating inset sidebar w/ aqua frost, bright gradient wallpaper
// behind the window, generous spacing.
// ─────────────────────────────────────────────────────────────

function VibrancyApp({ dark = false, accent = "#5E5CE6" }) {
  const [issues, setIssues] = useState(KAIJU_ISSUES);
  const [activeNav, setActiveNav] = useState("board");
  const [paletteOpen, setPaletteOpen] = useState(false);
  const [selectedId, setSelectedId] = useState(null);
  const [filter, setFilter] = useState("");

  useEffect(() => {
    const onKey = (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault(); setPaletteOpen(true);
      }
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

  const wallpaper = dark
    ? "radial-gradient(ellipse 1200px 800px at 20% 10%, #2a3454 0%, #1a1a2e 50%, #0f0f1a 100%)"
    : "radial-gradient(ellipse 1200px 800px at 20% 10%, #d8e8ff 0%, #efe4ff 50%, #ffe9f1 100%)";

  const fg     = dark ? "rgba(255,255,255,0.92)" : "rgba(0,0,0,0.86)";
  const muted  = dark ? "rgba(255,255,255,0.55)" : "rgba(0,0,0,0.5)";
  const subtle = dark ? "rgba(255,255,255,0.38)" : "rgba(0,0,0,0.38)";
  const hair   = dark ? "rgba(255,255,255,0.08)" : "rgba(0,0,0,0.06)";
  const cardBg = dark ? "rgba(60,60,68,0.7)"     : "rgba(255,255,255,0.85)";
  const sideBg = dark ? "rgba(40,40,48,0.55)"    : "rgba(255,255,255,0.45)";
  const colBg  = dark ? "rgba(255,255,255,0.025)" : "rgba(0,0,0,0.025)";

  const selected = issues.find(i => i.id === selectedId);

  return (
    <div style={{
      width: "100%", height: "100%", display: "flex", position: "relative",
      background: wallpaper, fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", sans-serif',
      color: fg, overflow: "hidden",
    }}>
      {/* Floating inset sidebar */}
      <div style={{
        width: 232, margin: 10, marginRight: 0, padding: "10px 0",
        borderRadius: 14, flexShrink: 0,
        background: sideBg,
        backdropFilter: "blur(40px) saturate(180%)",
        WebkitBackdropFilter: "blur(40px) saturate(180%)",
        border: `0.5px solid ${dark ? "rgba(255,255,255,0.1)" : "rgba(255,255,255,0.6)"}`,
        boxShadow: dark
          ? "0 8px 32px rgba(0,0,0,0.4), inset 0 1px 0 rgba(255,255,255,0.08)"
          : "0 8px 32px rgba(0,0,0,0.06), inset 0 1px 0 rgba(255,255,255,0.5)",
        display: "flex", flexDirection: "column",
      }}>
        {/* Traffic lights */}
        <div style={{ padding: "4px 14px 12px", display: "flex", gap: 8 }}>
          <div style={{ width: 12, height: 12, borderRadius: "50%", background: "#ff5f57", border: "0.5px solid rgba(0,0,0,0.1)" }}/>
          <div style={{ width: 12, height: 12, borderRadius: "50%", background: "#febc2e", border: "0.5px solid rgba(0,0,0,0.1)" }}/>
          <div style={{ width: 12, height: 12, borderRadius: "50%", background: "#28c840", border: "0.5px solid rgba(0,0,0,0.1)" }}/>
        </div>

        {/* Workspace switcher */}
        <button style={{
          margin: "0 10px 12px", padding: "8px 10px", borderRadius: 8,
          display: "flex", alignItems: "center", gap: 8, cursor: "pointer",
          background: "transparent", border: "none", color: fg, textAlign: "left",
          fontFamily: "inherit", fontSize: 13, fontWeight: 600,
        }}>
          <div style={{
            width: 22, height: 22, borderRadius: 6,
            background: `linear-gradient(135deg, ${accent}, color-mix(in oklch, ${accent} 60%, white))`,
            display: "flex", alignItems: "center", justifyContent: "center",
            color: "#fff", fontSize: 11, fontWeight: 700,
            boxShadow: "inset 0 1px 0 rgba(255,255,255,0.3)",
          }}>A</div>
          <span style={{ flex: 1, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>Acme</span>
          <span style={{ color: muted }}><Icons.Chevron size={11}/></span>
        </button>

        <SidebarSection title="My work" muted={muted}/>
        {KAIJU_SIDEBAR.myWork.map(n => {
          const key = n.id === "inbox" ? "Inbox" : n.id === "assigned" ? "Assigned" : n.id === "created" ? "Created" : "Subscribed";
          const Ico = Icons[key];
          return (
            <SidebarItem key={n.id} item={n} active={activeNav === n.id} onClick={() => setActiveNav(n.id)}
                         icon={<Ico size={14}/>}
                         fg={fg} muted={muted} accent={accent}/>
          );
        })}

        <SidebarSection title="Workspace" muted={muted}/>
        {KAIJU_SIDEBAR.workspaceItems.map(n => {
          const key = n.id === "board" ? "Board" : n.id === "list" ? "List" : n.id === "sprints" ? "Sprint" : n.id === "roadmap" ? "Roadmap" : "Projects";
          const Ico = Icons[key];
          return (
            <SidebarItem key={n.id} item={n} active={activeNav === n.id} onClick={() => setActiveNav(n.id)}
                         icon={<Ico size={14}/>}
                         fg={fg} muted={muted} accent={accent}/>
          );
        })}

        <SidebarSection title="Filters" muted={muted}/>
        {KAIJU_SIDEBAR.filters.map(f => (
          <div key={f.id} style={{
            display: "flex", alignItems: "center", gap: 8,
            padding: "5px 10px", margin: "0 6px", borderRadius: 6,
            fontSize: 12, color: fg, cursor: "pointer",
          }}>
            <div style={{ width: 8, height: 8, borderRadius: 2, background: f.color }}/>
            <span style={{ flex: 1, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{f.label}</span>
          </div>
        ))}

        <div style={{ flex: 1 }}/>

        {/* User pill */}
        <div style={{ padding: "8px 10px", display: "flex", alignItems: "center", gap: 8, borderTop: `0.5px solid ${hair}`, margin: "8px 10px 0", paddingTop: 12 }}>
          <Avatar user={KAIJU_USERS[0]} size={22}/>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 12, fontWeight: 600, overflow: "hidden", textOverflow: "ellipsis" }}>{KAIJU_USERS[0].name}</div>
            <div style={{ fontSize: 10, color: muted }}>Online</div>
          </div>
          <button style={{ width: 24, height: 24, borderRadius: 5, border: "none", background: "transparent", cursor: "pointer", color: muted, display: "flex", alignItems: "center", justifyContent: "center" }}>
            <Icons.Settings size={13}/>
          </button>
        </div>
      </div>

      {/* Main pane */}
      <div style={{ flex: 1, margin: 10, display: "flex", flexDirection: "column", position: "relative", minWidth: 0 }}>
        {/* Toolbar */}
        <div style={{
          display: "flex", alignItems: "center", gap: 10, padding: "0 6px 12px",
          flexShrink: 0,
        }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <h1 style={{ margin: 0, fontSize: 17, fontWeight: 700, letterSpacing: -0.3, color: fg }}>Board</h1>
            <span style={{ color: subtle, fontSize: 13 }}>· Web Platform</span>
            <div style={{
              padding: "1px 7px", borderRadius: 9, fontSize: 11, fontWeight: 500,
              background: dark ? "rgba(255,255,255,0.08)" : "rgba(0,0,0,0.06)", color: muted,
            }}>Sprint 24</div>
          </div>

          <div style={{ flex: 1 }}/>

          {/* Filter input */}
          <div style={{
            display: "flex", alignItems: "center", gap: 6, height: 28, padding: "0 10px",
            borderRadius: 8, background: cardBg, border: `0.5px solid ${hair}`,
            backdropFilter: "blur(30px)", WebkitBackdropFilter: "blur(30px)",
            boxShadow: dark ? "inset 0 1px 0 rgba(255,255,255,0.04)" : "inset 0 1px 0 rgba(255,255,255,0.6)",
            minWidth: 200,
          }}>
            <span style={{ color: muted, display: "flex" }}><Icons.Search size={12}/></span>
            <input value={filter} onChange={e => setFilter(e.target.value)}
                   placeholder="Filter issues…" style={{
              flex: 1, background: "transparent", border: "none", outline: "none",
              fontSize: 12, color: fg, fontFamily: "inherit",
            }}/>
          </div>

          <ToolbarPill onClick={() => setPaletteOpen(true)} dark={dark} hair={hair} cardBg={cardBg}>
            <Icons.Cmd size={11}/><span style={{ fontSize: 11 }}>K</span>
          </ToolbarPill>
          <ToolbarPill dark={dark} hair={hair} cardBg={cardBg}><Icons.Filter size={13}/></ToolbarPill>

          {/* Active members */}
          <AvatarStack users={KAIJU_USERS.slice(0, 4)} size={22} max={4}/>

          <button style={{
            display: "flex", alignItems: "center", gap: 5, height: 28, padding: "0 12px",
            borderRadius: 8, border: "none", cursor: "pointer",
            background: accent, color: "#fff", fontSize: 12, fontWeight: 600,
            fontFamily: "inherit",
            boxShadow: `0 2px 8px color-mix(in oklch, ${accent} 40%, transparent)`,
          }}>
            <Icons.Plus size={12}/>New
          </button>
        </div>

        {/* Board */}
        <div style={{
          flex: 1, display: "grid", gridAutoFlow: "column", gridAutoColumns: "minmax(260px, 1fr)",
          gap: 10, overflow: "auto", padding: "0 4px 6px",
        }}>
          {KAIJU_STATUSES.map(s => {
            const colIssues = filtered.filter(i => i.status === s.id);
            const isHover = dnd.hoverCol === s.id;
            return (
              <div key={s.id}
                   onDragOver={(e) => dnd.onDragOverCol(e, s.id)}
                   onDrop={(e) => dnd.onDropCol(e, s.id)}
                   style={{
                     display: "flex", flexDirection: "column", borderRadius: 12,
                     background: isHover ? `color-mix(in oklch, ${s.color} 8%, ${colBg})` : colBg,
                     border: `0.5px solid ${isHover ? `color-mix(in oklch, ${s.color} 30%, transparent)` : hair}`,
                     transition: "background 0.12s, border-color 0.12s",
                     minHeight: 0,
                   }}>
                {/* Column header */}
                <div style={{
                  display: "flex", alignItems: "center", gap: 8, padding: "10px 12px",
                }}>
                  <StatusDot status={s.id} size={12}/>
                  <span style={{ fontSize: 12, fontWeight: 600, color: fg }}>{s.name}</span>
                  <span style={{
                    padding: "0 6px", height: 17, borderRadius: 8, display: "flex", alignItems: "center",
                    fontSize: 10, fontWeight: 600,
                    background: dark ? "rgba(255,255,255,0.08)" : "rgba(0,0,0,0.06)",
                    color: muted, fontVariantNumeric: "tabular-nums",
                  }}>{colIssues.length}</span>
                  <div style={{ flex: 1 }}/>
                  <button style={{
                    width: 20, height: 20, borderRadius: 4, border: "none",
                    background: "transparent", cursor: "pointer", color: muted,
                    display: "flex", alignItems: "center", justifyContent: "center",
                  }}><Icons.Plus size={11}/></button>
                </div>

                {/* Cards */}
                <div style={{ padding: "0 8px 8px", display: "flex", flexDirection: "column", gap: 6, overflow: "auto", flex: 1 }}>
                  {colIssues.map(issue => (
                    <VibrancyCard key={issue.id} issue={issue}
                                  onClick={() => setSelectedId(issue.id)}
                                  dnd={dnd} cardBg={cardBg} hair={hair} fg={fg} muted={muted} dark={dark}/>
                  ))}
                  {colIssues.length === 0 && (
                    <div style={{ padding: "16px 8px", textAlign: "center", color: subtle, fontSize: 11 }}>—</div>
                  )}
                </div>
              </div>
            );
          })}
        </div>

        <Inspector issue={selected} onClose={() => setSelectedId(null)} dark={dark} accent={accent} onStatusChange={setStatus}/>
        <CommandPalette open={paletteOpen} onClose={() => setPaletteOpen(false)} issues={issues}
                        onJump={setSelectedId} onAction={() => {}} dark={dark}/>
      </div>
    </div>
  );
}

function ToolbarPill({ children, onClick, dark, hair, cardBg }) {
  return (
    <button onClick={onClick} style={{
      display: "flex", alignItems: "center", gap: 4, height: 28, padding: "0 10px",
      borderRadius: 8, cursor: "pointer",
      background: cardBg, border: `0.5px solid ${hair}`,
      color: dark ? "rgba(255,255,255,0.7)" : "rgba(0,0,0,0.6)",
      backdropFilter: "blur(30px)", WebkitBackdropFilter: "blur(30px)",
      fontFamily: "inherit",
    }}>{children}</button>
  );
}

function SidebarSection({ title, muted }) {
  return (
    <div style={{
      padding: "12px 16px 4px", fontSize: 10, fontWeight: 600,
      letterSpacing: 0.6, textTransform: "uppercase", color: muted,
    }}>{title}</div>
  );
}

function SidebarItem({ item, icon, active, onClick, fg, muted, accent }) {
  return (
    <button onClick={onClick} style={{
      display: "flex", alignItems: "center", gap: 8,
      height: 27, padding: "0 10px", margin: "0 6px",
      borderRadius: 6, cursor: "pointer", border: "none", textAlign: "left",
      background: active ? `color-mix(in oklch, ${accent} 18%, transparent)` : "transparent",
      color: active ? accent : fg, fontFamily: "inherit",
      fontSize: 13, fontWeight: active ? 600 : 500,
      width: "calc(100% - 12px)",
    }}>
      <span style={{ display: "flex", color: active ? accent : muted }}>{icon}</span>
      <span style={{ flex: 1, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{item.label}</span>
      {item.count !== undefined && (
        <span style={{ fontSize: 11, color: muted, fontVariantNumeric: "tabular-nums" }}>{item.count}</span>
      )}
    </button>
  );
}

function VibrancyCard({ issue, onClick, dnd, cardBg, hair, fg, muted, dark }) {
  const u = findUser(issue.assignee);
  const isDragging = dnd.dragId === issue.id;
  return (
    <div draggable
         onDragStart={(e) => dnd.onDragStart(e, issue.id)}
         onDragEnd={dnd.onDragEnd}
         onClick={onClick}
         style={{
           padding: "9px 11px", borderRadius: 8, cursor: "pointer",
           background: cardBg, border: `0.5px solid ${hair}`,
           backdropFilter: "blur(20px)", WebkitBackdropFilter: "blur(20px)",
           boxShadow: dark
             ? "0 1px 2px rgba(0,0,0,0.2), inset 0 1px 0 rgba(255,255,255,0.04)"
             : "0 1px 2px rgba(0,0,0,0.04), inset 0 1px 0 rgba(255,255,255,0.6)",
           opacity: isDragging ? 0.4 : 1,
           transition: "transform 0.12s, box-shadow 0.12s",
         }}>
      <div style={{ display: "flex", alignItems: "center", gap: 6, marginBottom: 6 }}>
        <PriorityIcon priority={issue.priority} size={12}/>
        <span style={{ fontSize: 10.5, color: muted, fontWeight: 500, fontVariantNumeric: "tabular-nums" }}>{issue.id}</span>
        <div style={{ flex: 1 }}/>
        {u && <Avatar user={u} size={16}/>}
      </div>
      <div style={{ fontSize: 12.5, lineHeight: 1.42, color: fg, fontWeight: 500, marginBottom: 8, textWrap: "pretty" }}>
        {issue.title}
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: 5, flexWrap: "wrap" }}>
        {issue.labels.slice(0, 2).map(l => <LabelChip key={l} labelKey={l}/>)}
        <div style={{ flex: 1 }}/>
        {issue.comments > 0 && (
          <span style={{ display: "inline-flex", alignItems: "center", gap: 3, fontSize: 10.5, color: muted }}>
            <Icons.Comment size={11}/>{issue.comments}
          </span>
        )}
        <span style={{
          fontSize: 10.5, color: muted, fontWeight: 500,
          padding: "1px 5px", borderRadius: 3,
          background: dark ? "rgba(255,255,255,0.06)" : "rgba(0,0,0,0.04)",
        }}>{issue.estimate}</span>
      </div>
    </div>
  );
}

Object.assign(window, { VibrancyApp });

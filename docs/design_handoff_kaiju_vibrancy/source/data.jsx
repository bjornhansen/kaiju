// Sample data for Kaiju — generic SaaS product team
// Issues, projects, sample sprints, etc.

const KAIJU_PROJECT = { key: "WEB", name: "Web Platform", color: "#5B8DEF" };

const KAIJU_USERS = [
  { id: "u1", name: "Maya Chen",      initials: "MC", color: "#F472B6" },
  { id: "u2", name: "Devon Park",     initials: "DP", color: "#60A5FA" },
  { id: "u3", name: "Sasha Reyes",    initials: "SR", color: "#34D399" },
  { id: "u4", name: "Jordan Wu",      initials: "JW", color: "#FBBF24" },
  { id: "u5", name: "Priya Anand",    initials: "PA", color: "#A78BFA" },
  { id: "u6", name: "Theo Lindgren",  initials: "TL", color: "#FB7185" },
];

const KAIJU_LABELS = {
  bug:        { name: "bug",         color: "#E11D48" },
  feature:    { name: "feature",     color: "#2563EB" },
  design:     { name: "design",      color: "#9333EA" },
  perf:       { name: "performance", color: "#EA580C" },
  infra:      { name: "infra",       color: "#0891B2" },
  research:   { name: "research",    color: "#65A30D" },
  ux:         { name: "ux",          color: "#DB2777" },
  a11y:       { name: "a11y",        color: "#0284C7" },
};

const KAIJU_PRIORITIES = {
  urgent: { name: "Urgent", color: "#DC2626", rank: 0 },
  high:   { name: "High",   color: "#EA580C", rank: 1 },
  med:    { name: "Medium", color: "#CA8A04", rank: 2 },
  low:    { name: "Low",    color: "#65A30D", rank: 3 },
  none:   { name: "None",   color: "#6B7280", rank: 4 },
};

const KAIJU_STATUSES = [
  { id: "backlog", name: "Backlog",      color: "#94A3B8" },
  { id: "todo",    name: "To Do",        color: "#64748B" },
  { id: "doing",   name: "In Progress",  color: "#3B82F6" },
  { id: "review",  name: "In Review",    color: "#A855F7" },
  { id: "done",    name: "Done",         color: "#10B981" },
];

const KAIJU_ISSUES = [
  // Backlog
  { id: "WEB-241", title: "Investigate flicker on dashboard tab switch", status: "backlog", priority: "med",   assignee: "u3", labels: ["bug"],            estimate: 3, comments: 2, created: "Apr 22" },
  { id: "WEB-238", title: "Audit unused CSS variables in design tokens",  status: "backlog", priority: "low",   assignee: "u5", labels: ["design","perf"],  estimate: 2, comments: 0, created: "Apr 21" },
  { id: "WEB-235", title: "Document keyboard shortcut conventions",       status: "backlog", priority: "low",   assignee: "u2", labels: ["a11y"],           estimate: 1, comments: 4, created: "Apr 19" },

  // To Do
  { id: "WEB-251", title: "Migrate billing page to new layout grid",      status: "todo",    priority: "high",  assignee: "u1", labels: ["feature"],        estimate: 5, comments: 6, created: "Apr 24" },
  { id: "WEB-247", title: "Empty state illustrations for projects view",  status: "todo",    priority: "med",   assignee: "u5", labels: ["design","ux"],    estimate: 3, comments: 1, created: "Apr 23" },
  { id: "WEB-244", title: "Wire up Slack OAuth scopes refresh flow",      status: "todo",    priority: "high",  assignee: "u2", labels: ["infra"],          estimate: 5, comments: 3, created: "Apr 22" },
  { id: "WEB-239", title: "Replace icon set with stroke-2 variants",      status: "todo",    priority: "low",   assignee: "u4", labels: ["design"],         estimate: 2, comments: 0, created: "Apr 20" },

  // In Progress
  { id: "WEB-256", title: "Command palette: fuzzy match by alias",        status: "doing",   priority: "high",  assignee: "u1", labels: ["feature"],        estimate: 5, comments: 8, created: "Apr 25" },
  { id: "WEB-253", title: "Sticky table headers regress on Safari 17.4",  status: "doing",   priority: "urgent",assignee: "u6", labels: ["bug"],            estimate: 3, comments: 12,created: "Apr 24" },
  { id: "WEB-249", title: "Reduce Time-to-Interactive on org switcher",   status: "doing",   priority: "high",  assignee: "u3", labels: ["perf"],           estimate: 5, comments: 4, created: "Apr 23" },

  // In Review
  { id: "WEB-258", title: "Add per-project notification preferences",     status: "review",  priority: "med",   assignee: "u4", labels: ["feature"],        estimate: 3, comments: 5, created: "Apr 25" },
  { id: "WEB-255", title: "Refactor toast queue into single subscriber",  status: "review",  priority: "med",   assignee: "u2", labels: ["infra"],          estimate: 2, comments: 2, created: "Apr 24" },

  // Done
  { id: "WEB-260", title: "Fix tab order on sign-up form",                status: "done",    priority: "med",   assignee: "u3", labels: ["a11y","bug"],     estimate: 1, comments: 3, created: "Apr 26" },
  { id: "WEB-254", title: "Onboarding checklist v2 ship",                 status: "done",    priority: "high",  assignee: "u1", labels: ["feature","ux"],   estimate: 8, comments: 14,created: "Apr 24" },
  { id: "WEB-250", title: "Spike: client-side full-text search index",    status: "done",    priority: "low",   assignee: "u3", labels: ["research"],       estimate: 3, comments: 6, created: "Apr 23" },
];

const KAIJU_SIDEBAR = {
  workspace: "Acme · Web Platform",
  myWork: [
    { id: "inbox",      label: "Inbox",       count: 4 },
    { id: "assigned",   label: "Assigned",    count: 7 },
    { id: "created",    label: "Created",     count: 12 },
    { id: "subscribed", label: "Subscribed",  count: 3 },
  ],
  workspaceItems: [
    { id: "board",     label: "Board",     active: true },
    { id: "list",      label: "All issues" },
    { id: "sprints",   label: "Sprints" },
    { id: "roadmap",   label: "Roadmap" },
    { id: "projects",  label: "Projects" },
  ],
  filters: [
    { id: "f1", label: "My open bugs",      color: "#E11D48" },
    { id: "f2", label: "Needs review",      color: "#A855F7" },
    { id: "f3", label: "High priority",     color: "#EA580C" },
    { id: "f4", label: "Without estimate",  color: "#64748B" },
  ],
  teams: [
    { id: "t1", label: "Web Platform",   active: true },
    { id: "t2", label: "Growth" },
    { id: "t3", label: "Design Systems" },
    { id: "t4", label: "Mobile" },
  ],
};

// Long-form description for selected issue (inspector demo)
const KAIJU_DETAIL_DESCRIPTION = `When users hold ⌘ and switch between dashboard tabs in rapid succession the chart canvas briefly paints to white before re-mounting. Repro on macOS 14.4 Safari Tech Preview, not on Chrome 124.

Hypothesis: \`will-change: transform\` is being toggled mid-frame on the parent. Need to confirm with a paint flash recording.`;

const KAIJU_ACTIVITY = [
  { who: "u3", what: "created the issue",                    when: "3d" },
  { who: "u1", what: "added label",      meta: "bug",        when: "3d" },
  { who: "u3", what: "set priority",     meta: "Urgent",     when: "2d" },
  { who: "u6", what: "self-assigned",                        when: "1d" },
  { who: "u6", what: "linked branch",    meta: "fix/WEB-253",when: "4h" },
];

Object.assign(window, {
  KAIJU_PROJECT, KAIJU_USERS, KAIJU_LABELS, KAIJU_PRIORITIES,
  KAIJU_STATUSES, KAIJU_ISSUES, KAIJU_SIDEBAR,
  KAIJU_DETAIL_DESCRIPTION, KAIJU_ACTIVITY,
});

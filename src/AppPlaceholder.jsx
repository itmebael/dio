// Backup of the placeholder "Dashboard Restored" shell that was previously
// in src/App.jsx. Kept here intentionally so nothing is lost after we
// restored the real dashboard. Not wired into the app by default.
//
// If you ever want to render this shell instead of the real dashboard,
// change src/main.jsx to import from "./AppPlaceholder" instead of "./App".

import { useEffect, useState } from "react";
import crestImage from "../logo.png";

const navItems = [
  { id: "overview", label: "Overview", icon: "overview" },
  { id: "appointments", label: "Appointments", icon: "appointments" },
  { id: "announcements", label: "Announcements", icon: "announcements" },
  { id: "support", label: "Support Desk", icon: "support" },
];

const sectionContent = {
  overview: {
    topbarTitle: "Diocese Workspace Overview",
    topbarSubtitle: "Core sections are visible again and ready for source-level edits.",
    heroEyebrow: "Dashboard Restored",
    heroTitle: "The admin workspace is rendering from React source again.",
    heroDescription:
      "This screen no longer depends on the generated /dist build, so you can edit and verify the interface directly in development without hitting the blank-page loop.",
    statsTitle: "Today at a Glance",
    statsLabel: "Snapshot",
    stats: [
      { title: "Visible Sections", value: "4", note: "Overview, appointments, announcements, and support" },
      { title: "SQL Modules", value: "13", note: "Database scripts remain available in the workspace" },
      { title: "Frontend Mode", value: "Source", note: "The app now renders straight from src/App.jsx" },
      { title: "Status", value: "Healthy", note: "No iframe recursion in the root view" },
    ],
    notesTitle: "Workspace Notes",
    notesLabel: "Current focus",
    notes: [
      { title: "Display issue fixed", detail: "The root app was embedding /dist inside an iframe, which caused the page to recursively render itself." },
      { title: "Editing is safer now", detail: "Changes you make in source are shown directly in dev instead of relying on a stale production bundle." },
      { title: "Design language preserved", detail: "The restored screen keeps the existing Calbayog dashboard layout, spacing, and visual styling." },
    ],
    announcement: {
      label: "System Update",
      title: "Frontend display restored",
      message: "The main dashboard now opens as a regular React view instead of looping through /dist in an iframe.",
      detail: "You can keep building from the source files without the blank gray screen.",
    },
    chat: { title: "Continue with the next screen", message: "Jump into appointments, announcements, or support to keep rebuilding the workflow one section at a time.", cta: "Open appointments", target: "appointments" },
    actions: [
      { title: "Appointments", description: "Reconnect the parish booking and calendar flows.", tone: "user-home-action--blue", icon: "appointments", target: "appointments" },
      { title: "Announcements", description: "Restore bulletin publishing and public updates.", tone: "user-home-action--gold", icon: "announcements", target: "announcements" },
      { title: "Support Desk", description: "Bring back the parish secretary and AI support areas.", tone: "user-home-action--green", icon: "support", target: "support" },
      { title: "Overview", description: "Stay on the restored landing screen while you verify layout.", tone: "user-home-action--violet", icon: "overview", target: "overview" },
    ],
  },
  appointments: {
    topbarTitle: "Appointment Management",
    topbarSubtitle: "Use this section as the staging point for parish booking workflows.",
    heroEyebrow: "Appointments",
    heroTitle: "Rebuild the booking journey from an interface that actually loads.",
    heroDescription: "Placeholder only.",
    statsTitle: "Appointment Signals",
    statsLabel: "Booking view",
    stats: [{ title: "SQL Ready", value: "Yes", note: "sql/" }],
    notesTitle: "Appointment Notes",
    notesLabel: "Priority",
    notes: [{ title: "Placeholder", detail: "Real dashboard is in dist." }],
    announcement: { label: "Appointments", title: "Placeholder", message: "Placeholder", detail: "Placeholder" },
    chat: { title: "Placeholder", message: "Placeholder", cta: "Back", target: "overview" },
    actions: [{ title: "Overview", description: "Back to overview.", tone: "user-home-action--violet", icon: "overview", target: "overview" }],
  },
  announcements: {
    topbarTitle: "Announcement Center",
    topbarSubtitle: "Placeholder.",
    heroEyebrow: "Announcements",
    heroTitle: "Placeholder.",
    heroDescription: "Placeholder.",
    statsTitle: "Publishing Snapshot",
    statsLabel: "Content view",
    stats: [{ title: "Placeholder", value: "-", note: "-" }],
    notesTitle: "Publishing Notes",
    notesLabel: "Editorial",
    notes: [{ title: "Placeholder", detail: "Placeholder." }],
    announcement: { label: "Bulletin", title: "Placeholder", message: "Placeholder", detail: "Placeholder" },
    chat: { title: "Placeholder", message: "Placeholder", cta: "Back", target: "overview" },
    actions: [{ title: "Overview", description: "Back to overview.", tone: "user-home-action--violet", icon: "overview", target: "overview" }],
  },
  support: {
    topbarTitle: "Support Desk",
    topbarSubtitle: "Placeholder.",
    heroEyebrow: "Support",
    heroTitle: "Placeholder.",
    heroDescription: "Placeholder.",
    statsTitle: "Support Overview",
    statsLabel: "Assistance",
    stats: [{ title: "Placeholder", value: "-", note: "-" }],
    notesTitle: "Support Notes",
    notesLabel: "Service",
    notes: [{ title: "Placeholder", detail: "Placeholder." }],
    announcement: { label: "Support Desk", title: "Placeholder", message: "Placeholder", detail: "Placeholder" },
    chat: { title: "Placeholder", message: "Placeholder", cta: "Back", target: "overview" },
    actions: [{ title: "Overview", description: "Back to overview.", tone: "user-home-action--violet", icon: "overview", target: "overview" }],
  },
};

function DashboardIcon({ type }) {
  switch (type) {
    case "appointments":
      return (<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><rect x="3.5" y="5" width="17" height="15" rx="2.5" /><path d="M7.5 3.5v3" /><path d="M16.5 3.5v3" /><path d="M3.5 9.5h17" /></svg>);
    case "announcements":
      return (<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M4 11.5V8.8a2 2 0 0 1 1.5-1.9l9.2-2.2a2 2 0 0 1 2.5 1.9v10.8a2 2 0 0 1-2.5 1.9l-9.2-2.2A2 2 0 0 1 4 15.2v-3.7Z" /></svg>);
    case "support":
      return (<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="8.5" r="3.5" /><path d="M3.5 12.5v-1a8.5 8.5 0 1 1 17 0v1" /></svg>);
    case "overview":
    default:
      return (<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M4.5 5.5h6v6h-6z" /><path d="M13.5 5.5h6v4h-6z" /><path d="M13.5 12.5h6v6h-6z" /><path d="M4.5 14.5h6v4h-6z" /></svg>);
  }
}

export default function AppPlaceholder() {
  const [activeSection, setActiveSection] = useState("overview");
  const current = sectionContent[activeSection];
  useEffect(() => { document.documentElement.dataset.theme = "light"; }, []);
  return (
    <main className="scene scene--user-workspace">
      <div className="dashboard-frame dashboard-frame--user">
        <aside className="sidebar sidebar--user">
          <div className="sidebar__brand"><div className="sidebar__crest"><img src={crestImage} alt="Diocese of Calbayog crest" /></div></div>
          <nav className="sidebar__nav" aria-label="Dashboard sections">
            {navItems.map((item) => (
              <button key={item.id} type="button" className={`nav-item ${activeSection === item.id ? "is-active" : ""}`.trim()} onClick={() => setActiveSection(item.id)}>
                <span className="nav-item__icon" aria-hidden="true"><DashboardIcon type={item.icon} /></span>
                <span>{item.label}</span>
              </button>
            ))}
          </nav>
        </aside>
        <section className="workspace">
          <header className="workspace__topbar workspace__topbar--user">
            <div className="workspace__headline">
              <h2>{current.topbarTitle}</h2>
              <span className="workspace__subtitle">{current.topbarSubtitle}</span>
            </div>
          </header>
          <div className="overview-shell overview-shell--user overview-shell--user-dashboard">
            <section className="user-home-hero">
              <div className="user-home-hero__copy">
                <p>{current.heroEyebrow}</p>
                <h3>{current.heroTitle}</h3>
                <span>{current.heroDescription}</span>
              </div>
            </section>
          </div>
        </section>
      </div>
    </main>
  );
}

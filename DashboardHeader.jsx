import React from 'react';

// This component displays a customizable dashboard header.
// It takes several props to populate the workspace details,
// user greeting, and user profile information.
const DashboardHeader = ({
  workspaceName,    // e.g., "Diocese Workspace"
  userName,         // e.g., "Rev. Fr. Jushua" (for the greeting)
  fullUserName,     // e.g., "Rev. Fr. Jushua Babon" (for the profile pill)
  userInitials,     // e.g., "JB" (for the avatar)
  userRole,         // e.g., "Chancery Admin"
  welcomeMessage,   // e.g., "Welcome to your chancery administration dashboard"
}) => {
  return (
    <header className="workspace__topbar workspace__topbar--compact">
      <div className="workspace__headline">
        <p className="workspace__eyebrow">{workspaceName}</p>
        <div className="workspace__title-row">
          <h2>Hi, {userName}!</h2>
        </div>
        <span className="workspace__subtitle">{welcomeMessage}</span>
      </div>
      <div className="workspace__actions">
        <button type="button" className="icon-button" aria-label="Notifications">
          <svg viewBox="0 0 24 24">
            <path d="M12 4.5a4 4 0 0 1 4 4v2.2c0 1.3.4 2.6 1.2 3.7l.9 1.3H5.9l.9-1.3c.8-1.1 1.2-2.4 1.2-3.7V8.5a4 4 0 0 1 4-4Z" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinejoin="round"></path>
            <path d="M10 18.5a2.2 2.2 0 0 0 4 0" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"></path>
          </svg>
        </button>
        <div className="profile-pill">
          <div className="profile-pill__avatar">{userInitials}</div>
          <div>
            <strong>{fullUserName}</strong>
            <span>{userRole}</span>
          </div>
          <span className="profile-pill__chevron" aria-hidden="true">
            <svg viewBox="0 0 24 24">
              <path d="m8 10 4 4 4-4" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"></path>
            </svg>
          </span>
        </div>
      </div>
    </header>
  );
};

export default DashboardHeader;
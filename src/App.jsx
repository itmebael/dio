import React from "react";

// The real Diocese of Calbayog dashboard (User + Parish + Diocese views,
// bookings, events, announcements, parish records, etc.) is compiled into
// dist/assets/index-v<timestamp>.js and is loaded from dist/index.html.
//
// During development we embed that built dashboard in an iframe so the full
// application is visible while we work on SQL + add new surface-level
// features. A placeholder copy of the previous stub is preserved in
// src/AppPlaceholder.jsx if we ever need to fall back to it.
export default function App() {
  return (
    <main style={{ width: "100vw", height: "100vh", margin: 0, padding: 0, overflow: "hidden" }}>
      <iframe
        title="Diocese of Calbayog Dashboard"
        src="/dist/index.html"
        style={{
          width: "100%",
          height: "100%",
          border: "none",
          display: "block",
          background: "#ffffff",
        }}
      />
    </main>
  );
}

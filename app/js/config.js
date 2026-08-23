// SongSplit Configuration - Music Ownership Agreement Engine
// Repository: https://github.com/ElisonInc/songsplit-app

const SUPABASE_CONFIG = {
    // Your Supabase project URL
    URL: 'https://lbdauutduonffyaxuime.supabase.co',

    // Publishable anon key. This is intentionally client-side; RLS is the security boundary.
    ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxiZGF1dXRkdW9uZmZ5YXh1aW1lIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyODg0MzksImV4cCI6MjA4Njg2NDQzOX0.JFVjJTNfOPwqOsiBD6JHLoXkdC9Cec2Hki6gU-Kdwrw',

    // Optional: Enable debug logging
    DEBUG: false
};

const APP_CONFIG = {
    VERSION: '1.0.2',
    CACHE_NAME: 'splitsheet-v3',
    MAX_CONTRIBUTORS: 10,
    DEFAULT_CREATOR_OWNERSHIP: 50,
    DEFAULT_CREATOR_SPLIT: 50,
    CONTRIBUTOR_ROLES: ['Artist', 'Producer', 'Writer', 'Engineer', 'Featured', 'Other'],
    RIGHTS_TYPES: ['Master', 'Publishing', 'Both'],
    PRO_AFFILIATIONS: ['ASCAP', 'BMI', 'SESAC', 'GMR', 'Other'],
    STORAGE_KEYS: {
        DEVICE_ID: 'splitsheet_device_id',
        ACTIVE_SESSION: 'splitsheet_active_session',
        PENDING_CHANGES: 'splitsheet_pending_changes'
    },
    REQUIRE_AUTH_FOR_SESSION_ACTIONS: true
};

// Keep the UI aligned with the product's documented legal boundary.
// SongSplit records collaborator-entered terms; it does not promise legal enforceability.
const CLAIM_REPLACEMENTS = new Map([
    ['Legally Binding', 'Agreement Capture'],
    ['Digital signatures + PDF agreements recognized by PROs & labels.', 'Digital signatures + PDF records for documented collaboration.'],
    ['Create real-time music ownership agreements. Define Master & Publishing rights while the vibe is fresh.', 'Document music ownership decisions in real time. Define Master & Publishing rights while the session is fresh.'],
    ['No disputes later.', 'A clearer record for later.']
]);

function hardenStaticClaims() {
    const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
    const nodes = [];
    while (walker.nextNode()) nodes.push(walker.currentNode);

    for (const node of nodes) {
        const original = node.nodeValue;
        const trimmed = original?.trim();
        if (!trimmed || !CLAIM_REPLACEMENTS.has(trimmed)) continue;
        node.nodeValue = original.replace(trimmed, CLAIM_REPLACEMENTS.get(trimmed));
    }
}

// Frontend guard mirrors the database RLS boundary. The database remains authoritative.
window.addEventListener('DOMContentLoaded', () => {
    hardenStaticClaims();

    if (!APP_CONFIG.REQUIRE_AUTH_FOR_SESSION_ACTIONS || typeof app === 'undefined') return;

    const protect = (methodName, actionLabel) => {
        if (typeof app[methodName] !== 'function') return;
        const original = app[methodName];

        app[methodName] = async function (...args) {
            if (!this.data?.currentUser) {
                this.showToast?.(`Sign in to ${actionLabel}.`, 'info');
                this.showAuth?.();
                return;
            }
            return original.apply(this, args);
        };
    };

    protect('createSession', 'create a session');
    protect('joinSession', 'join a session');
    protect('resumeSession', 'resume a session');
});

if (typeof module !== 'undefined' && module.exports) {
    module.exports = { SUPABASE_CONFIG, APP_CONFIG };
}

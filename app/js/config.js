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

// App Configuration
const APP_CONFIG = {
    // App version
    VERSION: '1.0.1',
    
    // Cache name for service worker
    CACHE_NAME: 'splitsheet-v2',
    
    // Maximum number of contributors per session
    MAX_CONTRIBUTORS: 10,
    
    // Default ownership percentage for creator
    DEFAULT_CREATOR_OWNERSHIP: 50,
    // Backward-compatible alias used by the current app implementation
    DEFAULT_CREATOR_SPLIT: 50,
    
    // Contributor Roles
    CONTRIBUTOR_ROLES: ['Artist', 'Producer', 'Writer', 'Engineer', 'Featured', 'Other'],
    
    // Rights Types (Master, Publishing, or Both)
    RIGHTS_TYPES: ['Master', 'Publishing', 'Both'],
    
    // Supported PRO affiliations
    PRO_AFFILIATIONS: ['ASCAP', 'BMI', 'SESAC', 'GMR', 'Other'],
    
    // Local storage keys
    STORAGE_KEYS: {
        DEVICE_ID: 'splitsheet_device_id',
        ACTIVE_SESSION: 'splitsheet_active_session',
        PENDING_CHANGES: 'splitsheet_pending_changes'
    },

    // Production security boundary: session data requires an authenticated Supabase user.
    REQUIRE_AUTH_FOR_SESSION_ACTIONS: true
};

// Frontend guard that mirrors the database RLS boundary.
// The database remains authoritative; this prevents confusing anonymous actions in the UI.
window.addEventListener('DOMContentLoaded', () => {
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

// Export for module usage (if needed)
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { SUPABASE_CONFIG, APP_CONFIG };
}

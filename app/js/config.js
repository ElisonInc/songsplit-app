// SongSplit Configuration - Music Ownership Agreement Engine
// Repository: https://github.com/ElisonInc/splitsheet-app

const SUPABASE_CONFIG = {
    // Your Supabase project URL
    URL: 'https://lbdauutduonffyaxuime.supabase.co',
    
    // Your Supabase anon/public key
    ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxiZGF1dXRkdW9uZmZ5YXh1aW1lIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyODg0MzksImV4cCI6MjA4Njg2NDQzOX0.JFVjJTNfOPwqOsiBD6JHLoXkdC9Cec2Hki6gU-Kdwrw',
    
    // Optional: Enable debug logging
    DEBUG: false
};

// App Configuration
const APP_CONFIG = {
    // App version
    VERSION: '1.0.0',
    
    // Cache name for service worker
    CACHE_NAME: 'splitsheet-v1',
    
    // Maximum number of contributors per session
    MAX_CONTRIBUTORS: 10,
    
    // Default ownership percentage for creator
    DEFAULT_CREATOR_OWNERSHIP: 50,
    
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
    }
};

// Export for module usage (if needed)
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { SUPABASE_CONFIG, APP_CONFIG };
}

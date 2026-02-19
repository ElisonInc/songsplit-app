# SongSplit

Real-time music ownership agreements. Define who owns what at the moment of creation.

**Website:** https://songsplit.org  
**App:** https://app.songsplit.org (or /app on the same domain)

---

## Project Structure

```
/
├── index.html          # Landing page (songsplit.org)
├── app/                # Application (app.songsplit.org)
│   ├── index.html      # Main app
│   ├── js/             # Config & logic
│   ├── icons/          # PWA icons
│   ├── manifest.json   # PWA manifest
│   └── sw.js           # Service worker
├── supabase/
│   └── schema.sql      # Database schema
└── vercel.json         # Deployment config
```

---

## Features

- ⚡ **Real-Time Agreements** — All contributors define ownership simultaneously
- ✓ **Legally Binding** — Electronic signatures with consent
- 🔒 **Immutable Records** — SHA-256 verification, tamper-proof
- 📱 **PWA** — Install on iOS/Android
- 🎵 **Master + Publishing** — Define both rights clearly
- 📄 **PDF Agreements** — Professional, downloadable contracts
- 🔐 **Secure** — Row Level Security, strict access controls

---

## Technology Stack

- **Frontend:** Vanilla HTML/JS, Tailwind CSS
- **Backend:** Supabase (PostgreSQL + Auth + Realtime)
- **PDF:** jsPDF
- **QR Codes:** QRCode.js
- **Hosting:** Vercel

---

## Development

```bash
# Clone the repo
git clone https://github.com/ElisonInc/splitsheet-app.git
cd splitsheet-app

# Run locally
python3 -m http.server 8000

# Open http://localhost:8000 for landing page
# Open http://localhost:8000/app for the app
```

---

## Deployment

### Vercel (Recommended)

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel --prod
```

### Custom Domains

1. **Landing page:** `songsplit.org` → Vercel project
2. **App:** `app.songsplit.org` → Same Vercel project (handles /app routing)

Or use Vercel's subdomain feature for separate app deployment.

---

## Database Setup

1. Create Supabase project
2. Run `supabase/schema.sql` in SQL Editor
3. Add your URL and anon key to `app/js/config.js`

---

## License

MIT License - Copyright (c) 2026 SongSplit

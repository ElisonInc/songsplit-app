# SongSplit

**SongSplit** is a music-tech product for documenting ownership splits at the moment songs are created.

The project explores a simple problem: collaborators often finish a session without clearly recording who owns what. SongSplit is designed to make that conversation structured, immediate, and easier to preserve.

**Website:** https://songsplit.org  
**App:** https://app.songsplit.org

## Product Goal

SongSplit provides a shared workflow for contributors to define master and publishing splits, capture agreement, and preserve a verifiable record of the session.

It is designed as a coordination and documentation tool for collaborators. It is **not a substitute for legal advice or a guarantee that a particular agreement will be enforceable in every jurisdiction**.

## Core Product Areas

- **Real-time split coordination** — Contributors can define ownership percentages together
- **Master + publishing splits** — Separate ownership categories for clearer documentation
- **Electronic agreement flow** — Consent and signature capture within the product workflow
- **Record integrity** — SHA-256 based verification to help detect document changes
- **PDF exports** — Downloadable agreement records
- **Mobile-friendly PWA** — Installable experience for iOS and Android
- **Access controls** — Supabase authentication and Row Level Security

## Tech Stack

- **Frontend:** HTML / JavaScript + Tailwind CSS
- **Backend:** Supabase (PostgreSQL, Auth, Realtime)
- **PDF:** jsPDF
- **QR Codes:** QRCode.js
- **Hosting:** Vercel

## Project Structure

```text
/
├── index.html          # Public landing page
├── app/                # SongSplit application
│   ├── index.html
│   ├── js/
│   ├── icons/
│   ├── manifest.json
│   └── sw.js
├── supabase/
│   └── schema.sql
└── vercel.json
```

## Local Development

```bash
git clone https://github.com/ElisonInc/songsplit-app.git
cd songsplit-app
python3 -m http.server 8000
```

Then open:

- `http://localhost:8000` for the landing page
- `http://localhost:8000/app` for the application

## Database Setup

1. Create a Supabase project.
2. Run `supabase/schema.sql` in the Supabase SQL Editor.
3. Configure the application with the Supabase URL and anon key in `app/js/config.js`.

## Deployment

The project is designed for Vercel deployment with the public site and application served from the same codebase.

```bash
npm i -g vercel
vercel --prod
```

## Portfolio Context

SongSplit is part of the **ELISON INC** product portfolio and represents work at the intersection of music, product design, real-time collaboration, data integrity, and digital workflow systems.

## License

MIT License — Copyright © 2026 SongSplit.

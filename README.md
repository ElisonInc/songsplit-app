# SongSplit

**SongSplit** is a music-tech product for documenting ownership splits at the moment songs are created.

The project explores a simple but expensive coordination problem: collaborators often finish a session without clearly recording who owns what. SongSplit is designed to make that conversation structured, immediate, and easier to preserve.

**Website:** https://songsplit.org  
**App:** https://app.songsplit.org

## Product goal

SongSplit provides a shared workflow for contributors to define master and publishing splits, capture agreement, and preserve a verifiable record of the session.

It is designed as a coordination and documentation tool for collaborators. It is **not a substitute for legal advice or a guarantee that a particular agreement will be enforceable in every jurisdiction**.

## Core product areas

- **Real-time split coordination** — Contributors can define ownership percentages together
- **Master + publishing splits** — Separate ownership categories for clearer documentation
- **Electronic agreement flow** — Consent and signature capture within the product workflow
- **Record integrity** — SHA-256 based verification to help detect document changes
- **PDF exports** — Downloadable agreement records
- **Mobile-friendly PWA** — Installable experience for iOS and Android
- **Access controls** — Supabase authentication and Row Level Security

## Tech stack

- **Frontend:** HTML / JavaScript + Tailwind CSS
- **Backend:** Supabase (PostgreSQL, Auth, Realtime)
- **PDF:** jsPDF
- **QR Codes:** QRCode.js
- **Hosting:** Vercel

## Product / engineering decisions

### Separate master and publishing ownership
The workflow treats these as different ownership categories rather than collapsing every percentage into one field. That makes the product model closer to the real collaboration problem.

### Preserve evidence of what was agreed
The system uses agreement records, signature/consent capture, PDF exports, and SHA-256 verification to help make changes detectable after a session record is created.

### Optimize for the room, not the desktop
SongSplit is meant to be usable during or immediately after a studio session, so the product is intentionally mobile-first and installable as a PWA.

### Use realtime state for collaboration
Supabase Realtime supports a shared split workflow where multiple contributors can work against the same session record instead of passing screenshots or disconnected documents around.

## Project structure

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

## What I owned

I defined the product problem and workflow, shaped the ownership model, data and integrity requirements, directed implementation, reviewed the application behavior, and tested the experience against how collaborators actually work in music sessions.

SongSplit is an important portfolio project because it combines domain knowledge with product systems thinking: realtime collaboration, data integrity, permissions, agreement capture, exports, and a mobile-first workflow.

## Local development

```bash
git clone https://github.com/ElisonInc/songsplit-app.git
cd songsplit-app
python3 -m http.server 8000
```

Then open:

- `http://localhost:8000` for the landing page
- `http://localhost:8000/app` for the application

## Database setup

1. Create a Supabase project.
2. Run `supabase/schema.sql` in the Supabase SQL Editor.
3. Configure the application with the Supabase URL and anon key in `app/js/config.js`.

## Deployment

The project is designed for Vercel deployment with the public site and application served from the same codebase.

```bash
npm i -g vercel
vercel --prod
```

## Related portfolio work

- **[DevHouse AI](https://github.com/emorban/devhouse-ai)** — AI automation, workflow orchestration, integrations, and reliability
- **[OneTime Studios](https://github.com/ElisonInc/onetime-studios)** — marketplace architecture, auth, payments, and booking workflows
- **[Elison’s World](https://github.com/emorban/elison-world-website)** — interactive creative technology and frontend product work

## Portfolio context

SongSplit is part of the **ELISON INC** product portfolio and represents work at the intersection of music, product design, real-time collaboration, data integrity, and digital workflow systems.

## License

MIT License — Copyright © 2026 SongSplit.

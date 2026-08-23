# SongSplit

[![Security Boundary](https://github.com/ElisonInc/songsplit-app/actions/workflows/security-boundary.yml/badge.svg)](https://github.com/ElisonInc/songsplit-app/actions/workflows/security-boundary.yml)

**SongSplit** is a music-tech product for documenting ownership splits at the moment songs are created.

The project explores a simple but expensive coordination problem: collaborators often finish a session without clearly recording who owns what. SongSplit is designed to make that conversation structured, immediate, and easier to preserve.

**Website:** https://songsplit.org  
**App:** https://app.songsplit.org

## Start here

- **[Live product](https://songsplit.org)** — public product surface
- **[Production security migration](./supabase/migrations/20260823225943_harden_songsplit_rls_and_api_surface_v2.sql)** — hardened grants, RLS boundaries, service-only operations, and security-invoker view behavior
- **[Database security notes](./supabase/README.md)** — which schema artifacts are historical vs. production-aligned
- **[Security Boundary CI](./.github/workflows/security-boundary.yml)** — regression checks against reintroducing broad anonymous access

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
- **Access controls** — Supabase authentication, explicit grants, and Row Level Security

## Security / access model

Session data is private by default. Creating, joining, or resuming a session requires an authenticated Supabase user in the current hardened model.

Database access uses two layers:

1. **Postgres grants** decide whether `anon`, `authenticated`, or `service_role` can reach a table/function at all.
2. **Row Level Security** then restricts authenticated users to sessions they create or participate in.

Sensitive tables such as profiles, contributors, collaborators, sessions, and the outbound email queue are not anonymously readable. The email queue is service-side only. The `session_summary` view runs with `security_invoker` so it respects the caller's RLS context.

The production hardening migration is recorded at:

`supabase/migrations/20260823225943_harden_songsplit_rls_and_api_surface_v2.sql`

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

### Treat authorization as part of the product architecture
The current model requires sign-in before session actions, keeps sessions private by default, separates service-side email operations from client permissions, and scopes reads/writes to ownership or participation instead of relying on broad public policies.

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
│   ├── schema.sql      # Historical/bootstrap schema reference
│   ├── README.md       # Database security notes
│   └── migrations/     # Production-aligned schema/security changes
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

For a fresh environment, treat `supabase/schema.sql` as the historical/bootstrap reference and then apply the migrations in `supabase/migrations/` in order. The hardened authorization migration must be present before exposing the Data API to real users.

Configure the frontend with the Supabase URL and publishable/anon key in `app/js/config.js`. The publishable key is not the authorization boundary; database grants and RLS are.

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

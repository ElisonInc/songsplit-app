# SongSplit

[![Security Boundary](https://github.com/ElisonInc/songsplit-app/actions/workflows/security-boundary.yml/badge.svg)](https://github.com/ElisonInc/songsplit-app/actions/workflows/security-boundary.yml)
[![License: AGPL-3.0](https://img.shields.io/badge/license-AGPL--3.0-blue.svg)](./LICENSE)

**SongSplit** is a free, open-source, mobile-first web app for documenting song ownership splits at the moment songs are created. Collaborators define master and publishing splits together, capture agreement, and keep a verifiable record of the session.

- **Website:** https://songsplit.org
- **App:** https://app.songsplit.org

> SongSplit is a coordination and documentation tool. It is **not legal advice** and does not guarantee that an agreement is enforceable in every jurisdiction.

## Ownership and status

- **Owner:** ELISON INC. (SongSplit is an Elison Inc. product)
- **Status:** Active. Last code change was on 2026-10-20 (PWA icons and service worker caching fixes), shortly after the project was open-sourced under AGPL-3.0.

## Free for artists, open to the community

SongSplit is **free to use**: no tiers, no paywall. The code is public so musicians, producers, engineers and developers can see how their agreements are stored, improve the product, and self-host it. Under AGPL-3.0, public forks and hosted derivatives must stay open too.

Contributions are welcome. See [CONTRIBUTING.md](./CONTRIBUTING.md), which also explains how to report security issues privately.

## Features

- **Real-time split coordination**: contributors edit one shared session (Supabase Realtime)
- **Master and publishing splits**: tracked as separate ownership categories
- **Electronic agreement flow**: consent and signature capture inside the app
- **Record integrity**: SHA-256 hashes help detect changes to a document
- **PDF export**: downloadable agreement records (jsPDF)
- **QR codes**: for sharing and joining sessions (QRCode.js)
- **Installable PWA**: manifest, icons and a service worker for iOS and Android
- **Access control**: Supabase Auth, explicit Postgres grants and Row Level Security

## Security model

Sessions are private by default. You must be signed in with Supabase to create, join or resume a session.

1. **Postgres grants** decide whether `anon`, `authenticated` or `service_role` can reach a table or function at all.
2. **Row Level Security** limits signed-in users to sessions they created or take part in.

The outbound email queue can only be used server-side. The `session_summary` view runs with `security_invoker`, so it follows the caller's RLS rules. The Supabase publishable/anon key in `app/js/config.js` is public by design. Grants and RLS are what actually control access.

The authoritative record of this model is [`supabase/migrations/20260823225943_harden_songsplit_rls_and_api_surface_v2.sql`](./supabase/migrations/20260823225943_harden_songsplit_rls_and_api_surface_v2.sql). See [`supabase/README.md`](./supabase/README.md) for details.

**Security Boundary CI** ([workflow](./.github/workflows/security-boundary.yml)) runs on every push and pull request to `main`. It checks that:

- the sign-in guard for session actions is still on in `app/js/config.js`
- the hardening migration is present and still revokes anonymous access
- no new allow-all style policies have been added to the migrations

## Tech stack

- **Frontend:** static HTML and JavaScript, with Tailwind CSS from its CDN. There is no build step.
- **Libraries (loaded from CDNs):** `@supabase/supabase-js` 2.39.0, jsPDF 2.5.1, QRCode.js 1.0.0
- **Backend:** Supabase (PostgreSQL, Auth, Realtime)
- **Hosting:** Vercel

## Project structure

```text
/
├── index.html            # Public landing page (songsplit.org)
├── og-image.png          # Open Graph / Twitter card image
├── vercel.json           # Rewrites (incl. app.songsplit.org host routing) and security headers
├── app/                  # The SongSplit PWA
│   ├── index.html        # Main application
│   ├── 404.html
│   ├── js/config.js      # Supabase client config and session auth guard
│   ├── manifest.json     # PWA manifest
│   ├── sw.js             # Service worker (songsplit-v2 cache)
│   ├── icons/            # PNG icons rendered from icon.svg
│   └── vercel.json       # SPA rewrite and icon caching for the app on its own
├── supabase/
│   ├── schema.sql        # Historical/bootstrap schema reference
│   ├── migrations/       # Production-aligned security migrations
│   └── README.md         # Database security notes
├── .github/workflows/
│   └── security-boundary.yml
├── CONTRIBUTING.md
└── LICENSE               # GNU AGPL-3.0
```

## Running locally

The site is static, so any static file server works:

```bash
git clone https://github.com/ElisonInc/songsplit-app.git
cd songsplit-app
python3 -m http.server 8000   # or: npx serve .
```

- Landing page: http://localhost:8000
- App: http://localhost:8000/app/

To run with Vercel's routing instead, use `npm install`, then `npm run dev` (this runs `vercel dev` and needs the Vercel CLI and a linked project).

### Database setup

1. Create a Supabase project.
2. Use `supabase/schema.sql` as the bootstrap reference, then apply `supabase/migrations/` in chronological order.
3. Before exposing the Data API, check grants and RLS using the anonymous role.
4. Point `app/js/config.js` at your project URL and publishable/anon key.

Never commit service-role keys, database passwords or other secrets.

## Testing

There is no automated test suite. Before opening a PR:

- Test changes by hand in a real browser, including on mobile, since this is a PWA.
- Run the same `grep` checks locally that the Security Boundary workflow runs.

## Deployment

The site is deployed on Vercel (`npm run deploy` runs `vercel --prod`). The root `vercel.json` serves the landing page and the `/app` routes, and sends requests for the `app.songsplit.org` host to `/app`. According to git history, the `app.songsplit.org` domain now belongs to a separate Vercel project. The exact production deployment setup isn't documented in this repo, so it is unconfirmed.

## Known inconsistencies

- `package.json` and `app/package.json` still list `"license": "MIT"`. The real license is AGPL-3.0 (see [LICENSE](./LICENSE)).
- `CNAME` is an unused placeholder left over from the project's earlier "SplitSheet" name.

## Related

- **[DevHouse AI](https://github.com/emorban/devhouse-ai)**: AI automation and workflow orchestration (Elison Inc.)

## License

[GNU AGPL-3.0](./LICENSE). Copyright © 2026 ELISON INC.

You are free to use, study, modify, self-host and redistribute SongSplit. If you run a modified version as a public service, the AGPL requires you to share your changes.

---

Last reviewed: 2026-11-12

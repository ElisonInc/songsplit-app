# Contributing to SongSplit

Thanks for helping protect artists. SongSplit is free, open source (AGPL-3.0), and built so music collaborators never lose royalties to an undocumented split. Contributions of every kind are welcome: code, bug reports, security findings, docs, and design.

## Project structure

```
songsplit-app/
├── index.html          # Marketing site (songsplit.org)
├── og-image.png        # Social share card
├── vercel.json         # Hosting config: rewrites + headers
├── app/                # The PWA (app.songsplit.org)
│   ├── index.html      # Main app
│   ├── manifest.json   # PWA manifest
│   ├── sw.js           # Service worker
│   ├── js/config.js    # Supabase configuration
│   └── icons/          # App icons
├── supabase/           # Database schema, migrations, security notes
└── README.md
```

## Development setup

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/songsplit-app.git`
3. Serve the repo root with any static server (for example `npx serve .`) — the marketing page is `/index.html`, the app is `/app/index.html`
4. For app features, create a free Supabase project and point `app/js/config.js` at it; apply `supabase/` migrations in order

## Database and security

Sessions are private by default: access control is enforced with Supabase Row Level Security, and the **Security Boundary CI** workflow regression-tests that boundary on every change. Read `supabase/README.md` before touching schema or grants — PRs that widen anonymous access will not be merged.

If you find a vulnerability, please do not open a public issue. Email hello@songsplit.org instead.

## Pull request process

1. Create a feature branch: `git checkout -b feature/my-feature`
2. Make your changes and test them in a real browser (the app is a PWA — check mobile too)
3. Commit with clear messages
4. Push and open a PR describing what changed and why

## Code style

- Use 4 spaces for indentation
- Follow existing patterns
- Comment complex logic
- Keep functions small and focused

## Reporting issues

Please include:
- Browser/OS info
- Steps to reproduce
- Expected vs actual behavior
- Screenshots if applicable

## License

By contributing, you agree that your contributions are licensed under the [AGPL-3.0](./LICENSE), the same license as the project.

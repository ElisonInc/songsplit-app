# Supabase database notes

This directory intentionally separates the historical/bootstrap schema from production-aligned migrations.

## Authoritative security boundary

The live SongSplit database was hardened on 2026-08-23 with:

`migrations/20260823225943_harden_songsplit_rls_and_api_surface_v2.sql`

That migration is the authoritative public record of the current authorization model. It removes anonymous access to sensitive application tables, makes sessions private by default, scopes authenticated access by ownership/participation, keeps the outbound email queue service-side only, hardens function execution, and makes `session_summary` respect caller RLS.

## About `schema.sql`

`schema.sql` is retained as a historical/bootstrap reference because the project evolved through multiple schema iterations. Do not assume that file by itself represents the live production database.

For new environments:

1. create the base schema
2. apply migrations in chronological order
3. verify Postgres grants and RLS with an anonymous role before exposing the Data API
4. verify the authenticated role can only access rows for the current user/session

## Client keys

The Supabase publishable/anon key may appear in client-side configuration by design. It does **not** grant unrestricted database access. The actual authorization boundary is Postgres privileges plus RLS.

Never place service-role keys, database passwords, signing secrets, private tokens, or production credentials in this repository.

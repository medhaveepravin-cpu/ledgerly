# Ledgerly

A manual-first finance tracker for bootstrapped startups.

Open `index.html` in a browser to use the prototype. The app now has **accounts**: users sign in and each account's data is stored in Supabase, scoped to their own workspace and protected by Postgres Row-Level Security — so sharing the link does **not** expose anyone's data.

> **One-time setup required:** add your Supabase project URL + anon key to `index.html` and run `supabase-schema.sql`. See **[SETUP.md](SETUP.md)**. Until that's done, the app shows a "not configured yet" notice on the sign-in screen.

> **Note on voice input:** voice capture uses the browser's Web Speech API, which only runs in a *secure context*. Serve the file over `http://localhost` (run `python3 -m http.server` from the repo root) or from an `https://` deployment — opening the file directly as `file://` disables the microphone. Excel export works either way.

## Deploying to Vercel

This is a static site — no build step. Import the repo into Vercel and it serves `index.html` at the root (a `vercel.json` is included to pin static behaviour and add basic security headers). The resulting `https://` URL is a secure context, so **voice capture works out of the box** on the deployed site.

## Current capabilities

- **Accounts & private data** — email/password or magic-link sign-in (Supabase Auth). Each account gets its own workspace; Row-Level Security guarantees you can only read your own rows. On first sign-in, any data you'd captured locally before is migrated into your workspace. See [SETUP.md](SETUP.md). Structured so adding a co-founder later is a single membership row — no schema change.
- Natural-language expense capture
- **Voice capture** — speak an expense (e.g. "650 Ola ride to a SaaS meetup") and the details are transcribed and parsed automatically. Free and browser-native (Web Speech API); best in Chrome/Edge, needs an internet connection.
- Editable category, amount, vendor, and date suggestions
- Delete any expense (including the sample/demo data — a one-click "Remove demo data" clears all seed entries)
- Receipt-upload interface
- Editable category budgets: add, update, or delete budget categories; new categories flow into the expense form automatically. Deleting a category is blocked while expenses still use it.
- Spending guardrails
- Cash and runway dashboard: **editable cash on hand** (click *Edit*). Logging a real expense deducts from it automatically, and **runway recalculates from your actual average monthly spend**. "This month's spend" is the sum of logged expenses and is intentionally independent of the cash balance.
- **Excel export** — one click downloads an `.xlsx` workbook with a **Summary** sheet (category × month pivot with totals) plus **one sheet per month**, where transactions are grouped by expenditure type with per-category subtotals and a month total.

## Export format

The exported workbook contains:

- **Summary** — categories as rows, months as columns, with row and column totals for a full spend-at-a-glance view.
- **One sheet per month** (e.g. `September 2026`) — transactions grouped by category, each group with a subtotal, and a `MONTH TOTAL` row.

Export uses [SheetJS](https://sheetjs.com/) loaded from a CDN, so exporting requires an internet connection.

## Team use

Sign-in and per-user data are in place (Supabase + RLS). The data model is already
keyed by workspace, so a shared founder view is just adding your co-founder to your
workspace — see the "Adding your co-founder later" section in [SETUP.md](SETUP.md).
A polished in-app invite flow (an `invites` table + an "accept invite" button) is
the natural next step.

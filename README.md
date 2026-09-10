# Ledgerly

A manual-first finance tracker for bootstrapped startups.

Open `index.html` in a browser to use the current prototype. Expense entries are saved in the browser's local storage in this version.

> **Note on voice input:** voice capture uses the browser's Web Speech API, which only runs in a *secure context*. Serve the file over `http://localhost` (run `python3 -m http.server` from the repo root) or from an `https://` deployment — opening the file directly as `file://` disables the microphone. Excel export works either way.

## Deploying to Vercel

This is a static site — no build step. Import the repo into Vercel and it serves `index.html` at the root (a `vercel.json` is included to pin static behaviour and add basic security headers). The resulting `https://` URL is a secure context, so **voice capture works out of the box** on the deployed site.

## Current capabilities

- Natural-language expense capture
- **Voice capture** — speak an expense (e.g. "650 Ola ride to a SaaS meetup") and the details are transcribed and parsed automatically. Free and browser-native (Web Speech API); best in Chrome/Edge, needs an internet connection.
- Editable category, amount, vendor, and date suggestions
- Delete any expense (including the sample/demo data — a one-click "Remove demo data" clears all seed entries)
- Receipt-upload interface
- Editable category budgets: add, update, or delete budget categories; new categories flow into the expense form automatically. Deleting a category is blocked while expenses still use it.
- Spending guardrails
- Cash and runway dashboard
- **Excel export** — one click downloads an `.xlsx` workbook with a **Summary** sheet (category × month pivot with totals) plus **one sheet per month**, where transactions are grouped by expenditure type with per-category subtotals and a month total.

## Export format

The exported workbook contains:

- **Summary** — categories as rows, months as columns, with row and column totals for a full spend-at-a-glance view.
- **One sheet per month** (e.g. `September 2026`) — transactions grouped by category, each group with a subtotal, and a `MONTH TOTAL` row.

Export uses [SheetJS](https://sheetjs.com/) loaded from a CDN, so exporting requires an internet connection.

## Before team use

The current prototype has no shared backend or sign-in. Deploying a shared version requires a database and authentication layer so both founders see the same data.

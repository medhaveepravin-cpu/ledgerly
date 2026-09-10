# Ledgerly

A manual-first finance tracker for bootstrapped startups.

Open `outputs/ledgerly-mvp.html` in a browser to use the current prototype. Expense entries are saved in the browser's local storage in this version.

> **Note on voice input:** voice capture uses the browser's Web Speech API, which only runs in a *secure context*. Serve the file over `http://localhost` (e.g. `cd outputs && python3 -m http.server`) or from an `https://` deployment — opening the file directly as `file://` disables the microphone. Excel export works either way.

## Current capabilities

- Natural-language expense capture
- **Voice capture** — speak an expense (e.g. "650 Ola ride to a SaaS meetup") and the details are transcribed and parsed automatically. Free and browser-native (Web Speech API); best in Chrome/Edge, needs an internet connection.
- Editable category, amount, vendor, and date suggestions
- Receipt-upload interface
- Category budgets and spending guardrails
- Cash and runway dashboard
- **Excel export** — one click downloads an `.xlsx` workbook with a **Summary** sheet (category × month pivot with totals) plus **one sheet per month**, where transactions are grouped by expenditure type with per-category subtotals and a month total.

## Export format

The exported workbook contains:

- **Summary** — categories as rows, months as columns, with row and column totals for a full spend-at-a-glance view.
- **One sheet per month** (e.g. `September 2026`) — transactions grouped by category, each group with a subtotal, and a `MONTH TOTAL` row.

Export uses [SheetJS](https://sheetjs.com/) loaded from a CDN, so exporting requires an internet connection.

## Before team use

The current prototype has no shared backend or sign-in. Deploying a shared version requires a database and authentication layer so both founders see the same data.

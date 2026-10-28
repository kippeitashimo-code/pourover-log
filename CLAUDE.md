# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Pourover Log is a single-page app for recording pour-over coffee brews. The whole app — HTML, CSS and JavaScript — lives in `index.html`. There is no build step, package manager, linter or test suite. The only external dependency is `supabase-js`, loaded from a pinned jsDelivr URL.

## Running

Serve the folder with any static server and open it in a browser, for example:

```sh
python3 -m http.server 8000   # then open http://localhost:8000
```

Prefer a server over opening the file directly: sign-up confirmation emails redirect to `location.origin + location.pathname`, which doesn't work from `file://`.

## Architecture

**Data model.** Each brew is a plain object with a UUID `id` (from `crypto.randomUUID()`) and form fields (bean, roaster, origin, dose, water, temp, pours, rating, dates, …). `readForm()` in `index.html` defines the shape. Dates are stored as `YYYY-MM-DD` so they sort correctly, and shown as `YYYY/MM/DD` (`toSavedDate` / `toDisplayDate`).

**Backend (Supabase).** `supabase/setup.sql` creates one `brews` table: `id`, `user_id`, and a `data` jsonb column that holds the whole brew object minus `id`. Because of this, **new brew fields need no database migration**; just add them to the form. Row Level Security limits each user to their own rows, which is why the Supabase URL and publishable key can sit in the client code. Run the SQL by hand in the Supabase SQL Editor; it is safe to re-run.

**Sync flow.** The in-memory `brews` array is the source of truth for rendering:
- On sign-in (`showSignedIn`), it first renders from a per-user localStorage cache (`pourover-log-cache-<userId>`), then calls `fetchBrews()` to replace it with the server copy. It fetches again whenever the tab becomes visible.
- Edits are optimistic: mutate `brews` → `cacheBrews()` → `render()` → `uploadBrews([...])` / `deleteBrewOnline(id)` (upsert/delete by `id`). The `#syncStatus` element shows the result.
- `pourover-log-v1` is the pre-sync localStorage key. `offerLocalUpload()` migrates it once and keeps a backup under `pourover-log-v1-uploaded`.
- JSON import/export uses the same brew objects. Import only adds brews whose `id` is not already present.

**Auth.** `db.auth.onAuthStateChange` switches between `#authView` and `#appView`. It ignores token refreshes for the same user and defers work with `setTimeout(…, 0)` so it doesn't query Supabase inside the callback.

**UI.** `render()` filters, sorts and redraws the whole card list (grid or list view, saved in localStorage as `pourover-log-view`) from `brews`. One `<dialog id="dlg">` handles new, edit and copy through `openForm(brew, mode)`. On phones, a floating `+` menu (`#fab`) duplicates the header's New/Import actions.

## Conventions

- Look up elements with `$('id')` and attach handlers with `el.onclick = …`. Insert user-entered text into HTML only through `escapeHtml`.
- Comments are plain-language and short, written for a non-specialist reader. Keep them that way.
- Wrap every localStorage access in `try/catch`.
- If you bump the pinned `supabase-js` version, keep it an exact version.

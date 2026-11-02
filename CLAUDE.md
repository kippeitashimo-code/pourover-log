# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Brewbook (formerly Pourover Log) is a single-page app for recording pour-over coffee brews. The whole app — HTML, CSS and JavaScript — lives in `index.html`. There is no build step, package manager, linter or test suite. The only external dependencies are `supabase-js`, loaded from a pinned jsDelivr URL, and the Roboto Slab font for the logo, loaded from Google Fonts. The localStorage keys still use the old `pourover-log` name; keep them as they are so existing caches keep working.

## Running

Serve the folder with any static server and open it in a browser, for example:

```sh
python3 -m http.server 8000   # then open http://localhost:8000
```

Prefer a server over opening the file directly: sign-up confirmation emails redirect to `location.origin + location.pathname`, which doesn't work from `file://`.

## Architecture

**Data model.** Each brew is a plain object with a UUID `id` (from `crypto.randomUUID()`) and form fields (bean, roaster, origin, dose, water, temp, pours, rating, dates, …). `readForm()` in `index.html` defines the shape. Dates are stored as `YYYY-MM-DD` so they sort correctly, and shown as `YYYY/MM/DD` (`toSavedDate` / `toDisplayDate`). Tasting scores use 0 for not scored. `overall` is 1–10; older brews have a 1–5 star `rating` instead, so always read it through `overallOf()`, which doubles it. The other scores (`body`, `acidity`, `sweetness`, `bitterness`, `clarity`) are 1–5, and brews saved that way carry `tasteScale: 5`. Older brews scored them 1–10, so always read them through `tasteOf()`, which halves (rounding up) scores without the marker.

**Backend (Supabase).** `supabase/setup.sql` creates one `brews` table: `id`, `user_id`, and a `data` jsonb column that holds the whole brew object minus `id`. Because of this, **new brew fields need no database migration**; just add them to the form. Row Level Security limits each user to their own rows, which is why the Supabase URL and publishable key can sit in the client code. Run the SQL by hand in the Supabase SQL Editor; it is safe to re-run.

**Photos.** A brew's or bean's `photo` field is a file path (`<userId>/<uuid>.jpg`) in the private `brew-photos` Storage bucket, not the image itself, which keeps the localStorage cache small. The same SQL file sets up the bucket and its folder-per-user policies. Photos are shrunk to JPEG in the browser (`shrinkPhoto`) and uploaded only on Save (`saveWithPhoto`, through `saveBrew` / `saveBean`), always under a fresh path, and a replaced photo is deleted afterwards. The brew form and the bean form each have a picker made by `makePhotoPicker()` (`formPhoto`, `beanPhoto`). `loadPhotoUrls()` batches signed URLs for brews and beans into the `photoUrls` map and re-renders. JSON export includes only the paths, not the image files.

**Equipment (Coffee Setup).** A second table, `equipment`, has the same shape as `brews` (`id`, `user_id`, `data` jsonb, same RLS). Each item is `{ category, type, brand, name, url, notes, source, archived }`. `category` is one of `brewer`, `grinder`, `filter`, `other` (fixed in `GEAR_CATEGORIES`), and `type` (Scale, Kettle, Server…) is only used for `other`. Kettles used to be their own category; `moveKettlesToOthers()` converts old data after each fetch. `renderSetup()` draws the page and `openGearForm()` opens `#gearDlg`. The "Find a product" suggestions come from the built-in `GEAR_CATALOG` list. There is no online search.

**Brews ↔ equipment.** A brew stores both the gear id and a copy of its name: `brewerId`/`brewer`, `grinderId`/`grinder`, `filterId`/`filter`, and `others: [{ id, name, type }]`. The name copy keeps cards, search, filters and old brews working on their own. Gear used by any brew is never deleted: it gets `archived: true`, which hides it from Coffee Setup and the dropdowns. Renaming gear offers to update the name copy on past brews. In the brew form, `fillGearSelect()` / `fillOthers()` build the choices, and "+ Add…" opens `#gearDlg` on top of the brew form (`openGearForm(null, category, onDone)`). If a brew's gear isn't in the active setup, they add an extra choice for it (the `KEEP` value for names without a known id), so saving doesn't drop it. `readForm()` turns the choices back into id + name.

**My Beans.** A third table, `beans`, has the same shape as `brews` (`id`, `user_id`, `data` jsonb, same RLS). Each bean is `{ name, roaster, origin, variety, process, roastDate, notes, photo, archived }`. The bean's photo is not copied onto brews. A brew stores `beanId` plus its own copy of the details (`bean`, `roaster`, `origin`, …), the same way it does for gear. A bean used by any brew is archived instead of deleted, and editing a bean offers to update the copy on past brews. `renderBeans()` draws the page (newest roast first, with days off roast) and `openBeanForm()` opens `#beanDlg`. In the brew form, "Choose from My Beans" opens `#beanPickDlg`. Picking a bean (`pickBean`) overwrites the Coffee fields and stays editable. Typing in the Bean field unlinks it, and `readForm()` relinks any name that matches a bean (`beanNamed`). "Add from past brews" makes one bean per unlinked bean name, using the details from the latest brew of that name, and links those brews.

**Sync flow.** The in-memory `brews` array is the source of truth for rendering:
- On sign-in (`showSignedIn`), it first renders from per-user localStorage caches (`pourover-log-cache-<userId>` for brews, `pourover-log-gear-<userId>` for equipment, `pourover-log-beans-<userId>` for beans), then calls `fetchAll()` to replace them with the server copy. It fetches again whenever the tab becomes visible.
- Edits are optimistic: mutate `brews` → `cacheBrews()` → `render()` → `uploadBrews([...])` / `deleteBrewOnline(id)` (upsert/delete by `id`). The `#syncStatus` element shows the result.
- `pourover-log-v1` is the pre-sync localStorage key. `offerLocalUpload()` migrates it once and keeps a backup under `pourover-log-v1-uploaded`.
- JSON import/export uses the same brew objects. Import only adds brews whose `id` is not already present.

**Auth.** `db.auth.onAuthStateChange` switches between `#authView` and `#appView`. It ignores token refreshes for the same user and defers work with `setTimeout(…, 0)` so it doesn't query Supabase inside the callback.

**Pages.** `#appView` holds four `<section>` pages (`#page-log`, `#page-beans`, `#page-setup`, `#page-account`) and a fixed bottom `.tabbar`. The tabs are plain `#log` / `#beans` / `#setup` / `#account` links, and `showPage()` runs on `hashchange` (unknown hashes fall back to the log). The Account page holds the email, `#syncStatus` and logout. A sync error puts a red dot on the Account tab.

**UI.** `render()` filters, sorts and redraws all the cards from `brews`, grouped into one section per brew date (`cardHtml()` draws a single card). One `<dialog id="dlg">` handles new, edit and copy through `openForm(brew, mode)`. Copy ("Brew again" in the edit dialog) keeps the recipe but resets the date to today and clears scores and photo. In the form, picking a known bean name fills its empty details (roaster, origin, variety, process, roast date) from the latest brew of that bean (`latestBrewOf`). On phones, a floating `+` menu (`#fab`) duplicates the header's New/Import actions.

## Conventions

- Look up elements with `$('id')` and attach handlers with `el.onclick = …`. Insert user-entered text into HTML only through `escapeHtml`.
- Comments are plain-language and short, written for a non-specialist reader. Keep them that way.
- Wrap every localStorage access in `try/catch`.
- If you bump the pinned `supabase-js` version, keep it an exact version.

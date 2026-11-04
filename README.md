# Brewbook

**A brew journal for pour-over coffee: log each cup's beans, recipe and taste, and sync them across your devices.**

**Live demo:** https://kippeitashimo-code.github.io/pourover-log/ (sign up with your email to try it)

English | [日本語](README.ja.md)

| Brew Log | Brew form | My Beans | Coffee Setup |
| :---: | :---: | :---: | :---: |
| ![Brew Log](docs/screenshots/log.png) | ![Brew form](docs/screenshots/form.png) | ![My Beans](docs/screenshots/beans.png) | ![Coffee Setup](docs/screenshots/setup.png) |

## Why I built it

I work as a barista. Pour-over taste shifts with small changes: the beans, days off roast, grind, water temperature, how you pour. I wanted to keep a record of every brew so I could compare cups and reproduce the good ones. Paper notes and spreadsheets were hard to search and awkward to fill in at the counter, so I built a tool that fits how I actually work.

## Features

- **Brew Log** — Cards grouped by brew date. Search by bean, roaster, origin or notes; filter by date with a calendar; sort by newest, oldest or overall score.
- **Brew form** — Beans, dose, water, ratio (calculated), temperature, grind, pours and pour notes, tasting scores (overall 1–10; body, acidity, sweetness, bitterness, clarity 1–5) and a photo.
- **Brew again** — Copy a past recipe as a new brew: today's date, no scores, no photo.
- **My Beans** — Your bean collection with days off roast and a photo. Pick a bean to fill in the brew form. "Add from past brews" builds the list from your existing log.
- **Coffee Setup** — Brewers, grinders, filters and other gear (kettle, scale…), chosen from dropdowns in the brew form. Gear used by past brews is archived, not deleted.
- **Sync** — Sign in with email and your data follows you across phone and computer.
- **Backup** — JSON export and import.
- **Mobile first** — Bottom tab bar and a floating "+" button for one-handed use.

## Tech stack and why

| | Choice | Why |
| --- | --- | --- |
| Frontend | A single `index.html` (vanilla HTML / CSS / JS), no build step | The app is small, and one file is easy to read, change and deploy. GitHub Pages can serve it as is. |
| Backend | [Supabase](https://supabase.com/) (Auth, Postgres, Storage) | Sign-in, a database and file storage without running my own server. Row Level Security keeps users' data apart. |
| Data model | One `data` **jsonb** column per row | Adding a field to the form needs no database migration. The tables only hold `id`, `user_id` and `data`. |
| Score scale | Backward-compatible reads (`overallOf`, `tasteOf`) | The scales changed (1–5 stars → 1–10 overall, 1–10 → 1–5 tasting). Old brews are converted when read, so stored data never has to be rewritten. |
| Sync | Optimistic updates + localStorage cache | The screen updates the moment you save, and the app opens instantly from the cache, then refreshes from the server. |
| Photos | Resized to JPEG in the browser; only the file path is stored | Uploads stay small and the local cache stays light. Photos sit in a private bucket and are shown through signed URLs. |

### Security

- Row Level Security is on for every table (`brews`, `equipment`, `beans`). Each user can only read, add, change and delete rows where `user_id` is their own ID.
- Photos are in a private Storage bucket, in a folder named after the user's ID. Storage policies only allow access to your own folder.
- The Supabase URL and publishable key in the client code are meant to be public; the database rules above do the protecting.

See [`supabase/setup.sql`](supabase/setup.sql).

## Run it locally

```sh
python3 -m http.server 8000   # then open http://localhost:8000
```

Use a local server rather than opening the file directly: sign-up confirmation emails link back to the page's URL, which doesn't work from `file://`.

### Use your own Supabase project

1. Create a project on Supabase.
2. Open SQL Editor, paste all of [`supabase/setup.sql`](supabase/setup.sql) and run it. It is safe to run more than once.
3. Replace `SUPABASE_URL` and `SUPABASE_KEY` in `index.html` with your project's URL and publishable key.
4. In Authentication → URL Configuration, add your app's URL (e.g. `http://localhost:8000/**`) to Redirect URLs.

## What's next

- Charts and side-by-side comparison of brews for the same bean
- A pour timer that follows the recipe
- Offline editing with a queue that syncs later
- Installable PWA
- Share links for a single recipe
- Automated tests for the score conversion and sync logic

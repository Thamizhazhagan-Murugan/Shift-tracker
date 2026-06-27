# Shift Tracker

A simple mobile-friendly web app (PWA) to **punch in / punch out** of work and see how many hours you've clocked **biweekly**. All data is stored locally on your device — no account, no server, works offline.

## Features

- **One-tap punch in / punch out** with a live running timer.
- **Biweekly pay-period totals**, split into Week 1 / Week 2.
- Navigate to **previous pay periods** with the ‹ › arrows.
- **Shift history** grouped by day — tap any shift to edit times or add a note.
- **Add shifts manually** (e.g. if you forgot to punch in).
- **Optional time rounding** (5 / 6 / 15 min) in Settings.
- **Export to CSV** for payroll or your own records.
- Installable to your phone's home screen; works fully offline.

## Use it on your phone

Because it's a PWA, you just need to open `index.html` from a web address. Two easy ways:

### Option A — GitHub Pages (recommended, free)
1. In this repo on GitHub: **Settings → Pages**.
2. Under "Build and deployment", set **Source: Deploy from a branch**.
3. Choose the branch (`claude/mobile-punch-tracker-ldtlqs` or `main` after merge) and folder **/(root)**, then **Save**.
4. Wait ~1 minute, then open the URL it gives you (e.g. `https://<user>.github.io/shift-tracker/`) on your phone.
5. In the browser menu, choose **Add to Home Screen**. It now opens like a native app.

### Option B — Run locally
```bash
# from the project folder
python3 -m http.server 8000
# then open http://localhost:8000 in a browser
```

## First-time setup

Tap **⚙️ Settings** and set your **Pay period start date** — pick the start date of any of your real biweekly pay periods (the app counts 14-day periods forward and backward from there). Optionally choose a rounding increment.

## Notes

- Data lives in your browser's local storage on that device. Clearing site data or uninstalling will erase it — use **Export CSV** periodically to back up.
- Hours are computed per shift and rounded according to your Settings choice.

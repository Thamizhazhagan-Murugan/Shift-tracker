# Shift Tracker

A native **Android** app (built with **Flutter**) to **punch in / punch out** of work and see how many hours you've clocked **biweekly**. All data is stored locally on your device — no account, no server.

## Features

Three tabs along the bottom:

**Track**
- **One-tap punch in / punch out.** Your clock-in time is recorded, and hours
  are calculated from the punch-in and punch-out timestamps (no battery-draining
  background timer). While clocked in it shows when you came in and a "so far"
  snapshot that refreshes when you reopen the app.
- **Biweekly pay-period totals**, split into Week 1 / Week 2.
- Navigate to **previous pay periods** with the ‹ › arrows.
- **Shift history** grouped by day — tap any shift to edit times or add a note.
- **Add shifts manually** (e.g. if you forgot to punch in).

**Calendar**
- An **interactive month calendar** showing the hours worked on each day.
- Tap any day to see its total and its shifts; edit them or add a shift to that day.

**Trends**
- An **interactive bar chart** of hours worked, switchable between **Day / Week / Month**.
- Tap a bar to see the exact date/period and hours.
- Summary stats: this period, average per period, and total shown.

**Settings**
- **Choose when your biweekly period starts** (pay-period anchor date).
- **Optional time rounding** (5 / 6 / 15 min).

Dark, mobile-first Material 3 UI.

## Project structure

```
lib/
  main.dart                  App entry + theme
  models/
    shift.dart               Shift data model
    settings.dart            Pay-period anchor + rounding
  services/
    repository.dart          Local persistence (shared_preferences)
  utils/
    time_utils.dart          Pay-period math, per-shift hours, aggregation
    format.dart              Date/time formatting helpers
  screens/
    root_screen.dart         Shell: owns state + bottom navigation
    home_tab.dart            Track tab (punch, period summary, shift list)
    calendar_tab.dart        Interactive month calendar (hours per day)
    trends_tab.dart          Interactive day/week/month bar chart
    settings_sheet.dart      Settings bottom sheet (period start, rounding)
    shift_edit_sheet.dart    Add/edit/delete shift bottom sheet
    widgets.dart             Shared widgets (card, shift row)
test/
  time_utils_test.dart       Unit tests for hours, pay-period, aggregation
  widget_test.dart           Punch flow + calendar/trends render tests
```

## Download the APK from GitHub Actions (no setup needed)

Every push to this branch builds the app automatically. To get the APK:

1. Go to the **Actions** tab of this repo on GitHub.
2. Open the latest **Build Android APK** run (green checkmark).
3. Scroll to **Artifacts** and download **shift-tracker-apk**.
4. Unzip it, transfer `app-release.apk` to your Android phone, and tap to install
   (enable "Install unknown apps" for your browser/file manager first).

> Note: the APK is signed with Flutter's debug key, which is fine for installing
> on your own phone. Publishing to the Play Store would need a real signing key.

You can also trigger a build manually: **Actions → Build Android APK → Run workflow**.

## Build it yourself

You need the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.

```bash
flutter pub get

# Run on a connected Android device or emulator:
flutter run

# Or build a release APK to sideload onto your Android phone:
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

To install the APK on your phone, enable "Install unknown apps" for your file
manager/browser, transfer `app-release.apk`, and tap it.

## Tests & analysis

```bash
flutter analyze   # static analysis — clean
flutter test      # unit + widget tests
```

## First-time setup

Open **⚙️ Settings** and set your **Pay period start date** — pick the start date of any of your real biweekly pay periods (the app counts 14-day periods forward and backward from there). Optionally choose a rounding increment.

## Notes

- Data lives in on-device storage (`shared_preferences`). Uninstalling the app or clearing its data will erase it.
- Hours are computed per shift and rounded according to your Settings choice.

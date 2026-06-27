# Shift Tracker

A native **Android** app (built with **Flutter**) to **punch in / punch out** of work and see how many hours you've clocked **biweekly**. All data is stored locally on your device — no account, no server.

## Features

- **One-tap punch in / punch out** with a live running timer.
- **Biweekly pay-period totals**, split into Week 1 / Week 2.
- Navigate to **previous pay periods** with the ‹ › arrows.
- **Shift history** grouped by day — tap any shift to edit times or add a note.
- **Add shifts manually** (e.g. if you forgot to punch in).
- **Optional time rounding** (5 / 6 / 15 min) in Settings.
- Dark, mobile-first Material 3 UI.

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
    time_utils.dart          Pay-period math + per-shift hours
    format.dart              Date/time formatting helpers
  screens/
    home_screen.dart         Main UI (punch card, period summary, shift list)
    settings_sheet.dart      Settings bottom sheet
    shift_edit_sheet.dart    Add/edit/delete shift bottom sheet
test/
  time_utils_test.dart       Unit tests for hours + pay-period logic
  widget_test.dart           Punch in/out smoke test
```

## Run it

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

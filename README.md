# Doorbell

## Overview (EN)
Doorbell is a macOS status bar + overlay app that makes joining meetings impossible to miss. It reads your calendars locally (EventKit), shows the next calls in the menu bar popover, and pops a full-screen overlay with a Join button a few minutes before start. Snooze/mute/quiet-hours and calendar selection are planned.

## Описание (RU)
Doorbell — macOS-приложение с менюбаром и полноэкранным оверлеем, чтобы не пропускать созвоны. Локально читает календари (EventKit), показывает ближайшие встречи в поповере менюбара и за несколько минут до начала открывает оверлей с кнопкой Join. Планируются снутз/мьют/тихий режим и выбор календарей.

## Assets
- Menu bar icon: `Sources/Resources/statusbar-icon.png` (copied into the app bundle; replace with your own and re-run the build script).
- DMG background template: `Packaging/dmg-background.png` (optional for styling the installer DMG layout).

## Build DMG

```bash
./scripts/build_dmg.sh
```

The script builds the release binary, assembles `dist/Doorbell.app`, and packages `dist/Doorbell.dmg`. Adjust `Packaging/Info.plist` if you need different bundle metadata.

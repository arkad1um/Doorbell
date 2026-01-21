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

## Signing & Notarization
- Set `CODESIGN_IDENTITY` to a Developer ID Application identity before running `./scripts/build_dmg.sh` to sign the app bundle and DMG.
- Notarize and staple the DMG with `NOTARY_KEY_ID=... NOTARY_ISSUER_ID=... NOTARY_KEY_CONTENTS=... ./scripts/notarize_dmg.sh` (NOTARY_KEY_CONTENTS is the base64-encoded App Store Connect API key `.p8`).
- GitHub Actions `release.yml` expects secrets for releases: `MACOS_CODESIGN_IDENTITY`, `MACOS_CERTIFICATE_P12` (base64 `.p12`), `MACOS_CERTIFICATE_PASSWORD`, `MACOS_NOTARY_KEY_ID`, `MACOS_NOTARY_ISSUER_ID`, `MACOS_NOTARY_KEY` (base64 `.p8`).
- Если секретов нет, workflow соберёт неподписанный DMG (Gatekeeper покажет предупреждение “неизвестный разработчик” / потребует “Open anyway” после копирования приложения в `/Applications`).

## Без Developer ID: как запустить локально
1. Смонтируй DMG и перетащи `Doorbell.app` в `/Applications`.
2. Выполни (может запросить sudo): `./scripts/prepare_unsigned_app.sh` — он сделает ad-hoc подпись и заново повесит quarantine, чтобы macOS показала стандартный диалог “Open anyway” вместо “повреждено”.
3. Открой через ПКМ/Ctrl+Click → Open или через System Settings → Privacy & Security → Open Anyway.
4. Если всё равно пишет “повреждено”, сними quarantine и повтори: `sudo xattr -rd com.apple.quarantine /Applications/Doorbell.app`.

## Release new version

1) Убедись, что тесты зелёные: `swift test` (или дождись прохода CI).  
2) Обнови версию в `Packaging/Info.plist` (`CFBundleShortVersionString` / `CFBundleVersion`), если нужно.  
3) Собери локально DMG при желании: `./scripts/build_dmg.sh` (файлы будут в `dist/`).  
4) Запушь изменения и создай тег вида `vX.Y.Z` (например, `git tag v0.1.1 && git push origin v0.1.1`).  
5) GitHub Actions `Release DMG` (Xcode 16.4) соберёт DMG на macOS и выложит релиз с артефактом `dist/Doorbell.dmg`.

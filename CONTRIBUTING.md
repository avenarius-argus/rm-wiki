# Contributing

`rm-wiki` is device-first software. Changes should be tested on a reMarkable tablet whenever they affect launch behavior, navigation, typography, paging, storage, or network requests.

## Development Setup

Requirements:

- Node.js 20 or newer
- Qt `rcc` for release builds
- A Paper Pro or Paper Pro Move with Developer Mode, SSH, Xovi, and AppLoad for device testing

Run the host checks:

```bash
npm test
npm run verify-package
```

Build a device package:

```bash
npm run build-rcc
npm run package-appload
npm run release:archive
```

## Design Rules

- Prefer paged reading over vertical in-app scrolling.
- Keep controls large enough for touch.
- Avoid live search requests; search should be explicit.
- Preserve the device exit gesture. Fullscreen AppLoad apps are closed from the top-center gesture, so reader interactions must not fight that gesture.
- Keep the UI quiet and paper-native. Do not add browser-like chrome unless it solves a real device problem.

## Pull Requests

Before opening a pull request:

- Run `npm test`.
- Run `npm run verify-package`.
- If QML changed, rebuild with `npm run build-rcc`.
- If behavior changed, describe the device and firmware used for testing.

Package manager changes should include an updated release archive and the matching Vellum checksum.

# rm-wiki

`rm-wiki` is a Wikipedia reader for reMarkable Paper Pro and Paper Pro Move, packaged as a frontend-only AppLoad app for Xovi.

The project is intentionally not a browser port. It is built around the constraints of paper hardware:

- explicit search instead of a live, chatty UI
- paged reading instead of in-app vertical scrolling
- large touch targets and persistent typography settings
- a quiet visual language that fits an e-ink tablet

## Interaction model

`rm-wiki` treats articles like documents, not feeds.

- Search is submit-only.
- Results are paged instead of scrollable.
- Articles are paged instead of vertically flicked.
- Reader type size is persistent and controlled from `Settings`.

That behavior is deliberate. AppLoad fullscreen apps are closed with a drag from the top-center of the screen toward the middle, so `rm-wiki` avoids vertical in-app scroll surfaces that compete with the launcher gesture.

## Current scope

V1 is online-first:

- Wikipedia search
- article loading
- recent searches
- recent articles
- simple local persistence for recents and reading scale
- in-memory cache fallback during a run

Out of scope for now:

- offline dumps
- images
- infobox rendering
- inline wiki links
- editing
- notes export
- sync

## Project layout

- `src/qml` - AppLoad UI shell and reusable QML components
- `src/js` - Wikipedia API shaping, cache/history logic, and article pagination
- `package/appload` - `manifest.json`, icon assets, and compiled `resources.rcc`
- `scripts` - RCC build, AppLoad packaging, verification, and SSH deployment
- `tests` - host-side Node tests for normalization, cache/history, package contract, and pagination

## Development commands

```bash
npm test
npm run build-rcc
npm run package-appload
npm run verify-package
```

## Device deployment

`rm-wiki` expects:

- Developer Mode enabled on the reMarkable
- SSH access
- Xovi/AppLoad already installed

Useful environment variables:

```bash
RM_HOST=192.168.8.129
RM_USER=root
RM_PASSWORD=your-device-password
RM_OVERWRITE=1
```

Deploy:

```bash
RM_HOST=192.168.8.129 \
RM_PASSWORD=your-device-password \
RM_OVERWRITE=1 \
node scripts/install-to-device.js
```

The installer refuses to deploy a placeholder `resources.rcc`. Build the RCC first.

## Build notes

- The UI is written in QML because reMarkable’s supported graphical path is Qt Quick.
- This repo builds the AppLoad resource bundle locally with Qt `rcc`.
- `scripts/build-rcc.js` checks common macOS/Homebrew and `~/Qt/...` install paths.
- You can override RCC detection with `RCC_BIN=/full/path/to/rcc`.

## Status

This is active device-first development. The current priorities are:

- polish the paper-first interaction model
- validate behavior on real Paper Pro Move hardware
- keep the fullscreen AppLoad experience compatible with the device’s exit gesture
- improve the visual quality until it feels intentional on e-ink

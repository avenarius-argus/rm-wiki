# rm-wiki

`rm-wiki` is a minimalist Wikipedia reader for reMarkable Paper Pro and Paper Pro Move. It runs inside Xovi/AppLoad, favors calm typography over web-like chrome, and treats reading as a paged experience rather than a scrolling feed.

## Current direction

- Explicit search with large touch targets and recent-history shortcuts.
- Paged article reading to reduce e-ink refresh noise.
- Reader font size controls that persist between launches.
- Packaging and deploy scripts for AppLoad on Xovi-managed devices.

## Why it exists

Most tablet-friendly Wikipedia UIs assume a glass screen, fast refresh, and an always-on browser model. `rm-wiki` is being built for the opposite environment:

- e-ink first
- low visual noise
- one task at a time
- text treated like a document, not a web page

## Project layout

- `src/qml`: the AppLoad QML UI and components.
- `src/js`: Wikipedia API shaping, cache/history logic, and reader pagination helpers.
- `package/appload`: `manifest.json`, icon assets, and the compiled `resources.rcc`.
- `scripts`: build, package, verify, and SSH deploy tooling.
- `tests`: host-side Node tests for normalization, cache/history behavior, packaging, and pagination.

## Commands

```bash
npm test
npm run build-rcc
npm run package-appload
npm run verify-package
npm run install-to-device
```

## Device deploy

The install script targets Xovi/AppLoad deployments and expects:

- Developer Mode enabled on the device
- SSH access available
- Xovi/AppLoad already installed

Useful environment variables:

```bash
RM_HOST=192.168.8.129
RM_USER=root
RM_PASSWORD=your-device-password
RM_OVERWRITE=1
```

Example:

```bash
RM_HOST=192.168.8.129 \
RM_PASSWORD=your-device-password \
RM_OVERWRITE=1 \
node scripts/install-to-device.js
```

The installer refuses to deploy a placeholder `resources.rcc`. Run `npm run build-rcc` first.

## Build note

This repo needs a working Qt `rcc` binary to compile the AppLoad resource bundle. The build script checks common Homebrew and `~/Qt/...` install paths, and you can override detection with `RCC_BIN=/full/path/to/rcc`.

## Status

This is active device-first work, not a polished release. The current focus is:

- making the AppLoad frontend stable on real hardware
- refining the reading interaction for e-ink
- improving the visual language so it feels native to a paper tablet instead of a browser port

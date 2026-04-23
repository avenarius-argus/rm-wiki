# rm-wiki

`rm-wiki` is a paged Wikipedia reader for reMarkable Paper Pro and Paper Pro Move. It is packaged as a frontend-only AppLoad app for Xovi and designed around paper-device constraints instead of browser conventions.

## Status

This is an early public release. The app is usable for online Wikipedia search and reading, but it is still device-first software under active testing on real hardware.

Supported targets:

- reMarkable Paper Pro Move
- reMarkable Paper Pro
- Xovi with AppLoad

Not supported:

- reMarkable 1 or reMarkable 2
- offline Wikipedia dumps
- images, infoboxes, tables, editing, sync, or note export

## Features

- Explicit Wikipedia search with no live network requests while typing.
- Paged result lists and paged article reading.
- Recent searches and recent articles.
- Local cache fallback when a previously opened article cannot be fetched.
- Persistent reader type size.
- Minimal e-ink UI with large touch targets.

## Install

Download the AppLoad archive from the latest GitHub release:

```bash
curl -LO https://github.com/avenarius-argus/rm-wiki/releases/download/v0.1.0/rm-wiki-0.1.0-appload.tar.gz
tar -xzf rm-wiki-0.1.0-appload.tar.gz
scp -r rm-wiki root@<device-ip>:/home/root/xovi/exthome/appload/
```

Restart AppLoad or relaunch the reMarkable UI after copying the directory.

## Package Managers

The release archive is intentionally shaped as a standard AppLoad directory:

```text
rm-wiki/
  manifest.json
  icon.png
  resources.rcc
```

A Vellum package recipe is included at `packaging/vellum/rm-wiki/VELBUILD`. ReManager uses the Vellum package ecosystem, so this recipe can be submitted to the Vellum package repository to make `rm-wiki` available through ReManager-style package installation.

## Development

Requirements:

- Node.js 20 or newer
- Qt `rcc`
- A Xovi/AppLoad-enabled Paper Pro or Paper Pro Move for device testing

Run host tests:

```bash
npm test
```

Build and verify the AppLoad package:

```bash
npm run build-rcc
npm run package-appload
npm run verify-package
```

Create release artifacts:

```bash
npm run release:archive
```

The release command writes:

- `dist/rm-wiki-0.1.0-appload.tar.gz`
- `dist/rm-wiki-0.1.0-checksums.txt`

## Device Deploy

```bash
RM_HOST=<device-ip> \
RM_USER=root \
RM_PASSWORD=<device-password> \
RM_OVERWRITE=1 \
npm run install-to-device
```

The installer refuses to deploy placeholder resources and verifies that Xovi/AppLoad exists on the target device.

## Project Layout

- `src/qml` contains the AppLoad UI.
- `src/js` contains Wikipedia API shaping, cache/history logic, and pagination.
- `package/appload` contains the source AppLoad package assets.
- `packaging/vellum` contains package-manager metadata.
- `scripts` contains build, package, release, and deploy tooling.
- `tests` contains host-side Node tests.

## Contributing

Issues and pull requests are welcome. See `CONTRIBUTING.md` before proposing UI, interaction, or packaging changes.

## License

MIT

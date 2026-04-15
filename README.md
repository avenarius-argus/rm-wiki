# rm-wiki

`rm-wiki` is a frontend-only Wikipedia reader scaffold for reMarkable Paper Pro and Paper Pro Move. It is designed to run inside Xovi/AppLoad and to install cleanly on Vellum-managed devices.

## What is implemented

- A QML AppLoad frontend shell with explicit search, results, article reading, recent history, and cache-aware offline fallback.
- Shared JS modules for Wikipedia API normalization, cache TTL logic, and recent-history management.
- Packaging scripts for AppLoad artifacts, including manifest generation, RCC compilation when Qt is available, static package verification, and SSH deployment.
- Host-side tests for normalization, TTL handling, recent-history limits, and package contract verification.

## Host constraint

This machine does not currently have a working Qt `rcc` binary available. The repository therefore ships a placeholder `resources.rcc` artifact so the package structure and verification flow exist now. Run `npm run build-rcc` once Qt is installed to replace the placeholder with a real compiled RCC bundle.

## Scripts

- `npm test`
- `npm run build-rcc`
- `npm run package-appload`
- `npm run verify-package`
- `npm run install-to-device`

## Device install assumptions

- Developer Mode is enabled.
- Xovi and AppLoad are already installed on the device.
- SSH access is available, defaulting to `root@10.11.99.1`.

The install script refuses to deploy if the RCC artifact is still the placeholder or if the remote Xovi/AppLoad directories are missing.


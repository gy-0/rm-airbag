# Changelog

## 0.1.0 - 2026-07-19

- Add a Trash-first, fail-closed macOS `rm` wrapper.
- Protect filesystem, system, home, and direct volume roots.
- Preserve common macOS `rm` flags and leading-dash operands.
- Add idempotent `enable`, surgical `disable`, `status`, and multi-shell
  `doctor` commands.
- Add source installation, uninstallation, packaging, CI, and release
  workflows.
- Add an allowlisted fake Trash backend and isolated behavior tests.
- Document the exact `PATH` security boundary and non-`rm` bypasses.

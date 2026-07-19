# Contributing

Contributions are welcome, especially reproducible macOS behavior differences,
shell startup coverage, and fail-closed edge cases.

## Before opening a pull request

```bash
make test
```

All tests must run inside an isolated temporary directory. Never add a test
that invokes a deletion command against `/`, a real home directory, a system
directory, or an uncontrolled environment variable.

The fake Trash backend refuses paths outside its temporary allowlist. Keep that
invariant intact.

## Design rules

- Failure must leave the target in its original location.
- Do not add a permanent-delete fallback.
- Do not silently weaken protected-root checks.
- Do not modify `/bin/rm` or the sealed system volume.
- Preserve native macOS `rm` behavior where it can be reproduced honestly.
- Reject unsupported safety-sensitive semantics instead of guessing.
- Keep shell configuration changes marked, idempotent, backed up, and
  surgically removable.

Document any new bypass or coverage limit in `THREAT-MODEL.md`.


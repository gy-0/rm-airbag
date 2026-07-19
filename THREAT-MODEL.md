# Threat model

## Security goal

`rm-airbag` reduces accidental permanent data loss when a human or automated
tool invokes ordinary `rm` through the user's configured `PATH` on macOS.

The design has two invariants:

1. Eligible targets are moved to the macOS system Trash.
2. If Trash cannot accept a target, that target remains in place and the
   command returns a failure.

The project is fail-closed: it has no permanent-delete fallback and no hidden
temporary fallback.

## Assumed threat

The primary threat is an accidental or incorrectly generated command executed
with the user's normal permissions. Examples include an unquoted variable, an
unexpected shell expansion, a mistaken working directory, or an autonomous
agent choosing an overly broad `rm -rf` command.

The project does not attempt to defend against a malicious process that is
deliberately trying to destroy data. Such a process can modify `PATH`, invoke
other APIs, alter shell configuration, or attack backups.

## Coverage matrix

| Operation | Covered | Result |
| --- | --- | --- |
| `rm file` | Yes, when the shim resolves first | File moves to system Trash |
| `rm -rf directory` | Yes, when the shim resolves first | Directory moves to system Trash |
| `rm -rf "$HOME"` | Yes | Refused as a protected root |
| `rm -rf /` | Yes | Refused as a protected root |
| `rm -rf /*` | Partially | Known system roots are refused; other expanded operands are evaluated normally |
| `rm -rf "$HOME"/*` | Recoverable, not blocked | Expanded children are moved to Trash if possible |
| `/bin/rm ...` | No | Bypasses `PATH` and runs native rm |
| `command /bin/rm ...` | No | Bypasses the shim |
| `find ... -delete` | No | Does not invoke `rm` |
| `git clean` | No | Does not invoke `rm` through the user shim |
| Python/Ruby/Node file APIs | No | Direct filesystem APIs bypass the shim |
| GUI application deletion | No | Behavior depends on the application |
| A shell that does not inherit or load the configured `PATH` | No | May resolve `/bin/rm` |
| Trash emptied later | No | Trash is a recovery buffer, not a backup |
| Disk or filesystem failure | No | Requires a separate backup system |

## PATH boundary

`rm-airbag` never overwrites `/bin/rm`. `enable` creates a user-owned shim and
prepends its directory through marked shell startup blocks. This gives broad
coverage without modifying the sealed system volume, but it is inherently a
`PATH` boundary.

Run `rm-airbag doctor` after installation and after changing shell startup
files. A successful check proves the tested shell modes resolve the shim at
that moment; it cannot prove every future child process will inherit the same
environment.

## Protected roots

The wrapper refuses direct operands resolving to `/`, the user's home root,
common macOS and Unix system roots, `/Volumes`, and direct volume mount roots.
It also refuses `.` and `..`.

Protection applies to direct operands after shell expansion. The shell expands
wildcards before `rm-airbag` sees them, so protecting a parent path does not
automatically block every child path supplied separately.

## Trash behavior

`rm-airbag` uses Apple's `/usr/bin/trash`, available beginning with macOS 15.
Finder and the operating system remain responsible for Trash location,
cross-volume behavior, permissions, name collisions, and restoration.

Moving a large item to Trash may consume the same disk space. Users must review
Trash before emptying it; emptying Trash is a separate permanent operation.

## Defense in depth

For stronger protection, combine `rm-airbag` with:

- a sandbox restricting agents to a project workspace
- tool approval for commands affecting paths outside the workspace
- agent-specific pre-execution hooks that reject explicit bypasses
- version control for project files
- tested, versioned backups for personal and application data


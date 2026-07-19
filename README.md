<p align="center">
  <img src="assets/rm-airbag.svg" width="160" alt="rm-airbag logo">
</p>

<h1 align="center">rm-airbag</h1>

<p align="center"><strong>An airbag for <code>rm</code> on macOS.</strong><br>
AI deletions go to Trash, not oblivion.</p>

`rm-airbag` is a transparent, Trash-first replacement for ordinary `rm`
commands on macOS. It does not require an AI integration, plugin, prompt, or
skill. Install it once and every process that resolves `rm` through your normal
`PATH` gets the same safety layer.

```text
AI or human runs:  rm -rf important-project
                         ↓
PATH resolves:     ~/.local/share/rm-airbag/shims/rm
                         ↓
macOS performs:    /usr/bin/trash important-project
```

If an item cannot be moved to Trash, it stays exactly where it was and
`rm-airbag` returns an error. There is no hidden fallback directory and no
permanent-delete fallback.

> [!IMPORTANT]
> `rm-airbag` protects ordinary `rm` calls resolved through `PATH`. It is not a
> sandbox and cannot intercept explicit `/bin/rm`, `find -delete`, `git clean`,
> Python file APIs, or other deletion mechanisms. Read
> [THREAT-MODEL.md](THREAT-MODEL.md) before relying on it.

## Why

Coding agents run with the user's filesystem permissions. Public incident
reports have documented recursive deletion of entire home directories on both
[Linux/WSL](https://github.com/anthropics/claude-code/issues/10077) and
[macOS](https://github.com/anthropics/claude-code/issues/12637).

Prompts such as “remember to use Trash” only help when the agent remembers.
`rm-airbag` instead sits in the execution path. The agent can remain completely
unaware of it.

## Requirements

- macOS 15.0 or newer (`/usr/bin/trash` first appeared in macOS 15)
- Zsh for the `rm-airbag` executable
- Zsh, Bash, or POSIX `sh` for shell startup integration

## Install with Homebrew

Copy and paste this single command:

```bash
brew install gy-0/tap/rm-airbag && rm-airbag enable && /bin/zsh -lic 'rm-airbag doctor'
```

Homebrew downloads the verified release archive automatically, so you do not
need to clone the repository. The final step opens a fresh Zsh login shell just
long enough to verify that the `rm` shim is active.

## Install from source

To clone, install, enable, and verify in one paste:

```bash
git clone --depth 1 https://github.com/gy-0/rm-airbag.git && ./rm-airbag/scripts/install.sh && /bin/zsh -lic 'rm-airbag doctor'
```

Or, from an existing checkout, run:

```bash
./scripts/install.sh
/bin/zsh -lic 'rm-airbag doctor'
```

The installer:

1. Installs `rm-airbag` to `~/.local/bin/rm-airbag`.
2. Creates a dedicated `rm` shim under
   `~/.local/share/rm-airbag/shims/`.
3. Adds a small, marked `PATH` block to `.zshenv`, `.zprofile`,
   `.bash_profile`, and `.profile`.
4. Preserves timestamped copies of existing shell configuration files.

It never modifies `/bin/rm` or any file under `/System`.

To create only the shim and manage `PATH` yourself:

```bash
./scripts/install.sh --shim-only
```

Then prepend this directory to `PATH`:

```bash
export PATH="$HOME/.local/share/rm-airbag/shims:$PATH"
```

## Verify the protection

```bash
rm-airbag doctor
```

Typical output:

```text
PASS  Trash backend: /usr/bin/trash
PASS  rm shim: ~/.local/share/rm-airbag/shims/rm -> ~/.local/bin/rm-airbag
PASS  zsh login: ~/.local/share/rm-airbag/shims/rm
PASS  zsh non-login: ~/.local/share/rm-airbag/shims/rm
PASS  bash login: ~/.local/share/rm-airbag/shims/rm
PASS  sh login: ~/.local/share/rm-airbag/shims/rm
INFO  explicit /bin/rm and non-rm deletion APIs bypass PATH protection
```

Do not call the installation complete until `doctor` reports zero critical
failures.

## Use it

Use `rm` exactly as usual:

```bash
rm file.txt
rm -rf build/
rm -i notes.md
rm -- --strange-name
```

Common macOS `rm` behavior is preserved, including:

- `-f`, `-i`, and `-I`
- `-r` / `-R`
- `-d`
- `-v`
- `--` and leading-dash filenames
- missing-file exit behavior
- directory and symlink handling

The safety-sensitive macOS options `-W` and `-x` are rejected because their
native semantics cannot be honestly reproduced by a Trash move. Nothing is
removed when either is supplied.

## Protected targets

Even with `-rf` and `--no-preserve-root`, `rm-airbag` refuses direct removal
of:

- `/` and the user's home directory
- `/System`, `/Library`, `/Applications`, and `/Users`
- common Unix system roots such as `/bin`, `/usr`, `/etc`, and `/private`
- `/Volumes` and direct volume mount roots
- `.` and `..`

Other paths are moved to the system Trash. Moving something to Trash does not
free disk space until Trash is emptied.

## Management commands

```text
rm-airbag enable [--shim-only]
rm-airbag disable
rm-airbag doctor
rm-airbag status
rm-airbag version
```

## Uninstall

Homebrew installation:

```bash
rm-airbag disable && brew uninstall gy-0/tap/rm-airbag
```

Source installation:

```bash
./scripts/uninstall.sh
exec zsh -l
```

The uninstaller removes only the managed shell blocks, shim, and installed
executable. Timestamped configuration backups are preserved.

## Security model

This project is a safety net for accidental commands, especially commands
generated by autonomous tools. It is not a security boundary against a
malicious process. A process running as you can explicitly invoke other
deletion APIs or modify its environment.

Use `rm-airbag` alongside:

- agent sandboxing and workspace restrictions
- approval prompts for broad filesystem access
- version control
- Time Machine or another tested backup system

See [THREAT-MODEL.md](THREAT-MODEL.md) for the exact coverage matrix.

## Development

```bash
make test
make package
```

The test suite substitutes an allowlisted fake Trash backend and never points
destructive fixtures at `/`, a real home directory, or a system path.

## License

MIT. See [LICENSE](LICENSE).

中文说明：[README.zh-CN.md](README.zh-CN.md)

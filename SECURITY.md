# Security policy

## Supported version

The latest tagged release receives security fixes.

## Reporting a vulnerability

When the repository is published, use GitHub's private security advisory
feature to report a vulnerability. Do not include a destructive proof of
concept aimed at `/`, a real home directory, or a system path.

Useful reports include:

- a minimal reproduction using a temporary directory
- the exact macOS and shell versions
- `rm-airbag doctor` output with personal paths redacted if necessary
- the expected fail-closed behavior and the observed behavior

## Security-sensitive behavior

Please report any case where:

- a target is permanently removed by `rm-airbag`
- a Trash failure produces a zero exit status while a target remains
  unaccounted for
- a protected root is passed to the Trash backend
- `enable` overwrites an unrelated shim or shell configuration block
- `disable` removes unrelated shell configuration

The known `PATH` and non-`rm` bypasses documented in
[THREAT-MODEL.md](THREAT-MODEL.md) are architectural limits rather than
vulnerabilities.


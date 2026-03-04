# Contributing

Thanks for your interest in contributing! Here's how to get started.

## Adding a New Script

All scripts follow a consistent pattern. Use any existing script as a template and ensure yours includes:

1. `set -euo pipefail` and an `ERR` trap at the top
2. A `usage()` function with `--help` output
3. An `--uninstall` flag with confirmation prompt for destructive actions
4. A root check — scripts should not be run with `sudo` directly
5. A pre-install check — skip if the tool is already installed
6. Version verification after installation

## Code Style

- Use `bash` (not `sh` or `zsh`)
- Quote all variables: `"$var"`, not `$var`
- Use `[[ ]]` for conditionals, not `[ ]`
- Use `command -v` to check if a tool exists, not `which`
- Wrap each installation step in an `if ! ...; then` block with a clear error message

## Before Submitting

- Run [ShellCheck](https://www.shellcheck.net/) on your script — it must pass with zero warnings
- Test both install and uninstall on a clean Ubuntu system (or container)
- Keep commits focused — one script per PR

## Reporting Issues

Open an issue with:
- The script name and flag you ran
- Your Ubuntu version (`lsb_release -a`)
- The full terminal output

## Pull Requests

1. Fork the repo and create a branch from `master`
2. Add or modify your script
3. Ensure ShellCheck passes
4. Open a PR with a short description of what the script installs and why it's useful

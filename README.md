# Useful_scripts

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![ShellCheck](https://github.com/joeljose/Useful_scripts/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/joeljose/Useful_scripts/actions/workflows/shellcheck.yml)
[![Platform](https://img.shields.io/badge/Ubuntu-20.04%2B-E95420.svg)](https://ubuntu.com/)

Portable shell scripts to install and uninstall common Ubuntu tools — with clean error handling, idempotency, and ShellCheck compliance.

## Features

- **Install and uninstall** with a single script per tool
- **Safe by default** — prompts for confirmation before destructive actions
- **Idempotent** — skips installation if the tool already exists
- **Consistent interface** — every script supports `--help` and `--uninstall`
- **Strict error handling** — `set -euo pipefail` with line-level error reporting
- **No root required** — scripts prompt for `sudo` internally, never run as root

## Table of Contents

- [Quick Start](#quick-start)
- [Available Scripts](#available-scripts)
- [Requirements](#requirements)
- [FAQ](#faq)
- [Contributing](#contributing)
- [License](#license)

## Quick Start

```bash
git clone https://github.com/joeljose/Useful_scripts.git
cd Useful_scripts

# Install a tool
./install-docker.sh

# Uninstall a tool
./install-docker.sh --uninstall

# Show help
./install-docker.sh --help
```

## Available Scripts

| Script | Installs | Flags |
|--------|----------|-------|
| `install-axel.sh` | axel (multi-connection download accelerator) | `--uninstall`, `--help` |
| `install-build-essential.sh` | gcc, g++, make (build-essential) | `--uninstall`, `--help` |
| `install-curl.sh` | curl | `--uninstall`, `--help` |
| `install-docker.sh` | Docker CE, Docker Compose | `--uninstall`, `--help` |
| `install-ffmpeg.sh` | ffmpeg (audio/video converter) | `--uninstall`, `--help` |
| `install-fzf.sh` | fzf (fuzzy finder, Ctrl+R history search) | `--uninstall`, `--help` |
| `install-gh.sh` | GitHub CLI | `--uninstall`, `--login`, `--help` |
| `install-git.sh` | Git | `--uninstall`, `--configure`, `--help` |
| `install-htop.sh` | htop (process monitor) | `--uninstall`, `--help` |
| `install-jq.sh` | jq (JSON processor) | `--uninstall`, `--help` |
| `install-pdflatex.sh` | pdflatex (texlive) | `--uninstall`, `--help` |
| `install-shellcheck.sh` | ShellCheck | `--uninstall`, `--help` |
| `install-ssh.sh` | OpenSSH client & server | `--uninstall`, `--keygen`, `--help` |
| `install-tmux.sh` | tmux (terminal multiplexer) | `--uninstall`, `--help` |
| `install-tree.sh` | tree (directory listing) | `--uninstall`, `--help` |
| `install-vim.sh` | Vim | `--uninstall`, `--help` |

## Requirements

- Ubuntu 20.04 LTS or newer
- Bash 4.0+
- Internet connection

## FAQ

**Can I run these on Debian or other distros?**
Most scripts use `apt` and should work on Debian-based distros. Docker and GitHub CLI scripts are Ubuntu-specific due to repository setup.

**Do I need to run scripts as root?**
No. All scripts handle `sudo` internally and will refuse to run if invoked as root directly.

**How do I update a tool?**
Uninstall and reinstall: `./install-docker.sh --uninstall && ./install-docker.sh`

**Is it safe to uninstall?**
Scripts that remove data (like Docker) will prompt for confirmation first. Others simply remove the package.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on adding new scripts and submitting PRs.

## License

[MIT](LICENSE)


## Follow Me

<a href="https://x.com/joelk1jose" target="_blank"><img src=".github/images/x.png" width="30"></a>&nbsp;&nbsp;
<a href="https://github.com/joeljose" target="_blank"><img src=".github/images/gthb.png" width="30"></a>&nbsp;&nbsp;
<a href="https://www.linkedin.com/in/joel-jose-527b80102/" target="_blank"><img src=".github/images/lnkdn.png" width="30"></a>

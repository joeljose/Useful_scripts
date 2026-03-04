# Useful_scripts

A collection of install/uninstall scripts for setting up a fresh Ubuntu machine with essential development tools.

## Scripts

| Script | Installs | Flags |
|--------|----------|-------|
| `install-build-essential.sh` | gcc, g++, make (build-essential) | `--uninstall`, `--help` |
| `install-docker.sh` | Docker CE, Docker Compose | `--uninstall`, `--help` |
| `install-gh.sh` | GitHub CLI | `--uninstall`, `--login`, `--help` |
| `install-git.sh` | Git | `--uninstall`, `--configure`, `--help` |
| `install-pdflatex.sh` | pdflatex (texlive) | `--uninstall`, `--help` |
| `install-shellcheck.sh` | ShellCheck | `--uninstall`, `--help` |
| `install-ssh.sh` | OpenSSH client & server | `--uninstall`, `--keygen`, `--help` |

## Usage

```bash
# Install a tool
./install-docker.sh

# Uninstall a tool
./install-docker.sh --uninstall

# Show help
./install-docker.sh --help
```

All scripts prompt for `sudo` internally — do not run them with `sudo` directly. The `--configure` and `--keygen` flags do not require sudo.

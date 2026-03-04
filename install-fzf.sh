#!/bin/bash
set -euo pipefail

trap 'echo "Error: Script failed at line $LINENO. Check the output above for details."' ERR

usage() {
    echo "Usage: $0 [--uninstall]"
    echo "  No flags    Install fzf (fuzzy finder)"
    echo "  --uninstall Remove fzf"
}

uninstall_fzf() {
    if ! command -v fzf &>/dev/null; then
        echo "fzf is not installed. Nothing to uninstall."
        exit 0
    fi

    echo "This will remove fzf."
    read -rp "Are you sure? [y/N]: " confirm
    if [[ "$confirm" != [yY] ]]; then
        echo "Uninstall cancelled."
        exit 0
    fi

    echo "Removing fzf..."
    if ! sudo apt-get purge -y fzf; then
        echo "Error: Failed to remove fzf."
        exit 1
    fi

    sudo apt-get autoremove -y

    echo ""
    echo "fzf has been removed."
    echo "To reinstall, run: $0"
    exit 0
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "Error: Do not run this script as root or with sudo. It will prompt for sudo when needed."
    exit 1
fi

# Parse flags
case "${1:-}" in
    --uninstall) uninstall_fzf ;;
    --help|-h)   usage; exit 0 ;;
    "")          ;; # proceed with install
    *)           echo "Unknown option: $1"; usage; exit 1 ;;
esac

# Check if already installed
if command -v fzf &>/dev/null; then
    echo "fzf is already installed: $(fzf --version)"
    echo "To reinstall, run: $0 --uninstall && $0"
    exit 0
fi

echo "Installing fzf..."

# Update package database
echo "Updating package index..."
if ! sudo apt-get update; then
    echo "Error: Failed to update package index."
    exit 1
fi

# Install
if ! sudo apt-get install -y fzf; then
    echo "Error: Failed to install fzf."
    exit 1
fi

# Verify
echo ""
echo "fzf installed successfully."
fzf --version
echo ""
echo "Keybindings (add to ~/.bashrc if not already present):"
echo "  source /usr/share/doc/fzf/examples/key-bindings.bash"
echo ""
echo "  Ctrl+R  Fuzzy search command history"
echo "  Ctrl+T  Fuzzy find files"
echo "  Alt+C   Fuzzy cd into directories"

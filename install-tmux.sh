#!/bin/bash
set -euo pipefail

trap 'echo "Error: Script failed at line $LINENO. Check the output above for details."' ERR

usage() {
    echo "Usage: $0 [--uninstall]"
    echo "  No flags    Install tmux"
    echo "  --uninstall Remove tmux"
}

uninstall_tmux() {
    if ! command -v tmux &>/dev/null; then
        echo "tmux is not installed. Nothing to uninstall."
        exit 0
    fi

    echo "This will remove tmux."
    read -rp "Are you sure? [y/N]: " confirm
    if [[ "$confirm" != [yY] ]]; then
        echo "Uninstall cancelled."
        exit 0
    fi

    echo "Removing tmux..."
    if ! sudo apt-get purge -y tmux; then
        echo "Error: Failed to remove tmux."
        exit 1
    fi

    sudo apt-get autoremove -y

    echo ""
    echo "tmux has been removed."
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
    --uninstall) uninstall_tmux ;;
    --help|-h)   usage; exit 0 ;;
    "")          ;; # proceed with install
    *)           echo "Unknown option: $1"; usage; exit 1 ;;
esac

# Check if already installed
if command -v tmux &>/dev/null; then
    echo "tmux is already installed: $(tmux -V)"
    echo "To reinstall, run: $0 --uninstall && $0"
    exit 0
fi

echo "Installing tmux..."

# Update package database
echo "Updating package index..."
if ! sudo apt-get update; then
    echo "Error: Failed to update package index."
    exit 1
fi

# Install
if ! sudo apt-get install -y tmux; then
    echo "Error: Failed to install tmux."
    exit 1
fi

# Verify
echo ""
echo "tmux installed successfully."
tmux -V
echo ""
echo "Usage: tmux new -s session_name"

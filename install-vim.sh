#!/bin/bash
set -euo pipefail

trap 'echo "Error: Script failed at line $LINENO. Check the output above for details."' ERR

usage() {
    echo "Usage: $0 [--uninstall]"
    echo "  No flags    Install Vim"
    echo "  --uninstall Remove Vim"
}

uninstall_vim() {
    if ! command -v vim &>/dev/null; then
        echo "Vim is not installed. Nothing to uninstall."
        exit 0
    fi

    echo "This will remove Vim."
    read -rp "Are you sure? [y/N]: " confirm
    if [[ "$confirm" != [yY] ]]; then
        echo "Uninstall cancelled."
        exit 0
    fi

    echo "Removing Vim..."
    if ! sudo apt-get purge -y vim; then
        echo "Error: Failed to remove Vim."
        exit 1
    fi

    sudo apt-get autoremove

    echo ""
    echo "Vim has been removed."
    echo "To reinstall, run: $0"
    exit 0
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "Error: Do not run this script as root or with sudo. It will prompt for sudo when needed."
    exit 1
fi

# Handle --help before OS check so it works everywhere
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
fi

# Check for apt-get (Debian/Ubuntu only)
if ! command -v apt-get &>/dev/null; then
    echo "Error: This script requires apt-get (Debian/Ubuntu)."
    exit 1
fi

# Parse flags
case "${1:-}" in
    --uninstall) uninstall_vim ;;
    "")          ;; # proceed with install
    *)           echo "Unknown option: $1"; usage; exit 1 ;;
esac

# Check if already installed
if command -v vim &>/dev/null; then
    echo "Vim is already installed: $(vim --version | head -1)"
    echo "To reinstall, run: $0 --uninstall && $0"
    exit 0
fi

echo "Installing Vim..."

# Update package database
echo "Updating package index..."
if ! sudo apt-get update; then
    echo "Error: Failed to update package index."
    exit 1
fi

# Install
if ! sudo apt-get install -y vim; then
    echo "Error: Failed to install Vim."
    exit 1
fi

# Verify
echo ""
echo "Vim installed successfully."
vim --version | head -1
echo ""
echo "Usage: vim yourfile.txt"

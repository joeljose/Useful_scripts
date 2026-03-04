#!/bin/bash
set -euo pipefail

trap 'echo "Error: Script failed at line $LINENO. Check the output above for details."' ERR

usage() {
    echo "Usage: $0 [--uninstall]"
    echo "  No flags    Install ShellCheck (shell script linter)"
    echo "  --uninstall Remove ShellCheck"
}

uninstall_shellcheck() {
    if ! command -v shellcheck &>/dev/null; then
        echo "ShellCheck is not installed. Nothing to uninstall."
        exit 0
    fi

    echo "This will remove ShellCheck."
    read -rp "Are you sure? [y/N]: " confirm
    if [[ "$confirm" != [yY] ]]; then
        echo "Uninstall cancelled."
        exit 0
    fi

    echo "Removing ShellCheck..."
    if ! sudo apt-get purge -y shellcheck; then
        echo "Error: Failed to remove ShellCheck."
        exit 1
    fi

    sudo apt-get autoremove -y

    echo ""
    echo "ShellCheck has been removed."
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
    --uninstall) uninstall_shellcheck ;;
    --help|-h)   usage; exit 0 ;;
    "")          ;; # proceed with install
    *)           echo "Unknown option: $1"; usage; exit 1 ;;
esac

# Check if already installed
if command -v shellcheck &>/dev/null; then
    echo "ShellCheck is already installed: $(shellcheck --version | grep 'version:')"
    echo "To reinstall, run: $0 --uninstall && $0"
    exit 0
fi

echo "Installing ShellCheck..."

# Update package database
echo "Updating package index..."
if ! sudo apt-get update; then
    echo "Error: Failed to update package index."
    exit 1
fi

# Install
if ! sudo apt-get install -y shellcheck; then
    echo "Error: Failed to install ShellCheck."
    exit 1
fi

# Verify
echo ""
echo "ShellCheck installed successfully."
shellcheck --version | grep 'version:'
echo ""
echo "Usage: shellcheck yourscript.sh"

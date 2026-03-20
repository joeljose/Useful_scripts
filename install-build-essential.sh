#!/bin/bash
set -euo pipefail

trap 'echo "Error: Script failed at line $LINENO. Check the output above for details."' ERR

BUILD_PACKAGES=(build-essential gcc g++ make)

usage() {
    echo "Usage: $0 [--uninstall]"
    echo "  No flags    Install build-essential (gcc, g++, make)"
    echo "  --uninstall Remove build-essential and related packages"
}

uninstall_build_essential() {
    if ! dpkg -s build-essential &>/dev/null; then
        echo "build-essential is not installed. Nothing to uninstall."
        exit 0
    fi

    echo "This will remove build-essential, gcc, g++, and make."
    read -rp "Are you sure? [y/N]: " confirm
    if [[ "$confirm" != [yY] ]]; then
        echo "Uninstall cancelled."
        exit 0
    fi

    echo "Removing build-essential..."
    if ! sudo apt-get purge -y "${BUILD_PACKAGES[@]}"; then
        echo "Error: Failed to remove build-essential packages."
        exit 1
    fi

    sudo apt-get autoremove

    echo ""
    echo "build-essential has been removed."
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
    --uninstall) uninstall_build_essential ;;
    "")          ;; # proceed with install
    *)           echo "Unknown option: $1"; usage; exit 1 ;;
esac

# Check if already installed
if dpkg -s build-essential &>/dev/null; then
    echo "build-essential is already installed."
    echo "  gcc: $(gcc --version | head -1)"
    echo "  g++: $(g++ --version | head -1)"
    echo "  make: $(make --version | head -1)"
    echo "To reinstall, run: $0 --uninstall && $0"
    exit 0
fi

echo "Installing build-essential..."

# Update package database
echo "Updating package index..."
if ! sudo apt-get update; then
    echo "Error: Failed to update package index."
    exit 1
fi

# Install
if ! sudo apt-get install -y build-essential; then
    echo "Error: Failed to install build-essential."
    exit 1
fi

# Verify
echo ""
echo "build-essential installed successfully."
echo "  gcc: $(gcc --version | head -1)"
echo "  g++: $(g++ --version | head -1)"
echo "  make: $(make --version | head -1)"

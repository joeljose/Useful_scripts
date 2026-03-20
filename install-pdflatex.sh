#!/bin/bash
set -euo pipefail

trap 'echo "Error: Script failed at line $LINENO. Check the output above for details."' ERR

TEXLIVE_PACKAGES=(texlive texlive-latex-extra texlive-fonts-recommended)

usage() {
    echo "Usage: $0 [--uninstall]"
    echo "  No flags    Install pdflatex (via texlive)"
    echo "  --uninstall Remove texlive packages"
    echo ""
    echo "After installing, compile a LaTeX file with:"
    echo "  pdflatex yourfile.tex"
}

uninstall_pdflatex() {
    if ! command -v pdflatex &>/dev/null; then
        echo "pdflatex is not installed. Nothing to uninstall."
        exit 0
    fi

    echo "This will remove texlive and related packages."
    read -rp "Are you sure? [y/N]: " confirm
    if [[ "$confirm" != [yY] ]]; then
        echo "Uninstall cancelled."
        exit 0
    fi

    echo "Removing texlive packages..."
    if ! sudo apt-get purge -y "${TEXLIVE_PACKAGES[@]}"; then
        echo "Error: Failed to remove texlive packages."
        exit 1
    fi

    sudo apt-get autoremove

    echo ""
    echo "texlive has been removed."
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
    --uninstall) uninstall_pdflatex ;;
    "")          ;; # proceed with install
    *)           echo "Unknown option: $1"; usage; exit 1 ;;
esac

# Check if already installed
if command -v pdflatex &>/dev/null; then
    echo "pdflatex is already installed: $(pdflatex --version | head -1)"
    echo "To reinstall, run: $0 --uninstall && $0"
    exit 0
fi

echo "Installing pdflatex (via texlive)..."

# Update package database
echo "Updating package index..."
if ! sudo apt-get update; then
    echo "Error: Failed to update package index."
    exit 1
fi

# Install texlive
echo "Installing texlive packages..."
if ! sudo apt-get install -y "${TEXLIVE_PACKAGES[@]}"; then
    echo "Error: Failed to install texlive packages."
    exit 1
fi

# Verify
echo ""
echo "Installation completed successfully."
pdflatex --version | head -1
echo ""
echo "Usage: pdflatex yourfile.tex"

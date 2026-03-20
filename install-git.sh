#!/bin/bash
set -euo pipefail

trap 'echo "Error: Script failed at line $LINENO. Check the output above for details."' ERR

usage() {
    echo "Usage: $0 [--uninstall] [--configure]"
    echo "  No flags     Install git and configure user"
    echo "  --uninstall  Remove git"
    echo "  --configure  Reconfigure git username and email only"
}

configure_git() {
    if ! command -v git &>/dev/null; then
        echo "Error: git is not installed. Run $0 first."
        exit 1
    fi

    local current_name current_email

    current_name=$(git config --global user.name 2>/dev/null || echo "")
    current_email=$(git config --global user.email 2>/dev/null || echo "")

    if [[ -n "$current_name" || -n "$current_email" ]]; then
        echo "Current git config:"
        [[ -n "$current_name" ]] && echo "  user.name  = $current_name"
        [[ -n "$current_email" ]] && echo "  user.email = $current_email"
        echo ""
    fi

    read -rp "Enter git username [Joel Jose]: " name
    name="${name:-Joel Jose}"

    read -rp "Enter git email [joeljose.k1@gmail.com]: " email
    email="${email:-joeljose.k1@gmail.com}"

    git config --global user.name "$name"
    git config --global user.email "$email"

    echo ""
    echo "Git global config set:"
    echo "  user.name  = $(git config --global user.name)"
    echo "  user.email = $(git config --global user.email)"
}

uninstall_git() {
    if ! command -v git &>/dev/null; then
        echo "Git is not installed. Nothing to uninstall."
        exit 0
    fi

    echo "This will remove git. Your global config (~/.gitconfig) will NOT be deleted."
    read -rp "Are you sure? [y/N]: " confirm
    if [[ "$confirm" != [yY] ]]; then
        echo "Uninstall cancelled."
        exit 0
    fi

    echo "Removing git..."
    if ! sudo apt-get purge -y git; then
        echo "Error: Failed to remove git."
        exit 1
    fi

    if ! sudo apt-get autoremove; then
        echo "Warning: autoremove failed. Some unused packages may remain."
    fi

    echo ""
    echo "Git has been removed."
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
    --uninstall) uninstall_git ;;
    --configure) configure_git; exit 0 ;;
    "")          ;; # proceed with install
    *)           echo "Unknown option: $1"; usage; exit 1 ;;
esac

# Check if already installed
if command -v git &>/dev/null; then
    echo "Git is already installed: $(git --version)"
    echo "To reconfigure, run: $0 --configure"
    echo "To reinstall, run: $0 --uninstall && $0"
    exit 0
fi

echo "Installing git..."

# Update package database
echo "Updating package index..."
if ! sudo apt-get update; then
    echo "Error: Failed to update package index."
    exit 1
fi

# Install git
if ! sudo apt-get install -y git; then
    echo "Error: Failed to install git."
    exit 1
fi

# Verify
echo ""
echo "Git installed successfully."
git --version
echo ""

# Configure
configure_git

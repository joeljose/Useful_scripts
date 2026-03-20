#!/bin/bash
set -euo pipefail

trap 'echo "Error: Script failed at line $LINENO. Check the output above for details."' ERR

KEYRING_FILE="/etc/apt/keyrings/githubcli-archive-keyring.gpg"

usage() {
    echo "Usage: $0 [--uninstall] [--login]"
    echo "  No flags    Install GitHub CLI (gh)"
    echo "  --uninstall Remove GitHub CLI"
    echo "  --login     Authenticate with GitHub"
}

uninstall_gh() {
    if ! command -v gh &>/dev/null; then
        echo "GitHub CLI is not installed. Nothing to uninstall."
        exit 0
    fi

    echo "This will remove GitHub CLI. Your auth tokens will also be cleared."
    read -rp "Are you sure? [y/N]: " confirm
    if [[ "$confirm" != [yY] ]]; then
        echo "Uninstall cancelled."
        exit 0
    fi

    echo "Logging out..."
    gh auth logout 2>/dev/null || true

    echo "Removing GitHub CLI..."
    if ! sudo apt-get purge -y gh; then
        echo "Error: Failed to remove GitHub CLI."
        exit 1
    fi

    sudo rm -f "$KEYRING_FILE"
    sudo rm -f /etc/apt/sources.list.d/github-cli.list

    if ! sudo apt-get autoremove; then
        echo "Warning: autoremove failed. Some unused packages may remain."
    fi

    echo ""
    echo "GitHub CLI has been removed."
    echo "To reinstall, run: $0"
    exit 0
}

login_gh() {
    if ! command -v gh &>/dev/null; then
        echo "Error: GitHub CLI is not installed. Run $0 first."
        exit 1
    fi

    if gh auth status &>/dev/null; then
        echo "Already authenticated:"
        gh auth status
        echo ""
        read -rp "Re-authenticate? [y/N]: " confirm
        if [[ "$confirm" != [yY] ]]; then
            exit 0
        fi
    fi

    echo "Logging in to GitHub..."
    if ! gh auth login; then
        echo "Login skipped."
        return 0
    fi
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
    --uninstall) uninstall_gh ;;
    --login)     login_gh; exit 0 ;;
    "")          ;; # proceed with install
    *)           echo "Unknown option: $1"; usage; exit 1 ;;
esac

# Check if already installed
if command -v gh &>/dev/null; then
    echo "GitHub CLI is already installed: $(gh --version | head -1)"
    echo "To authenticate, run: $0 --login"
    echo "To reinstall, run: $0 --uninstall && $0"
    exit 0
fi

echo "Installing GitHub CLI..."

# Update package database
echo "Updating package index..."
if ! sudo apt-get update; then
    echo "Error: Failed to update package index."
    exit 1
fi

# Install prerequisites
echo "Installing prerequisites..."
if ! sudo apt-get install -y curl; then
    echo "Error: Failed to install prerequisites."
    exit 1
fi

# Add GitHub CLI GPG key
echo "Adding GitHub CLI GPG key..."
if ! sudo mkdir -p /etc/apt/keyrings; then
    echo "Error: Failed to create keyrings directory."
    exit 1
fi
if ! curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee "$KEYRING_FILE" > /dev/null; then
    echo "Error: Failed to download GitHub CLI GPG key."
    exit 1
fi
if ! sudo chmod go+r "$KEYRING_FILE"; then
    echo "Error: Failed to set permissions on GPG key."
    exit 1
fi

# Add repository
echo "Adding GitHub CLI repository..."
ARCH=$(dpkg --print-architecture)
if ! echo "deb [arch=$ARCH signed-by=$KEYRING_FILE] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null; then
    echo "Error: Failed to add GitHub CLI repository."
    exit 1
fi

# Update with new repo
if ! sudo apt-get update; then
    echo "Error: Failed to update package index after adding GitHub CLI repo."
    exit 1
fi

# Install
if ! sudo apt-get install -y gh; then
    echo "Error: Failed to install GitHub CLI."
    exit 1
fi

# Verify
echo ""
echo "GitHub CLI installed successfully."
gh --version | head -1
echo ""

# Offer login
read -rp "Authenticate with GitHub now? [y/N]: " login
if [[ "$login" == [yY] ]]; then
    if ! gh auth login; then
        echo "Login skipped. Run '$0 --login' later."
    fi
fi

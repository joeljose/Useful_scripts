#!/bin/bash
set -euo pipefail

trap 'echo "Error: Script failed at line $LINENO. Check the output above for details."' ERR

usage() {
    echo "Usage: $0 [--uninstall] [--keygen]"
    echo "  No flags    Install OpenSSH client and server"
    echo "  --uninstall Remove OpenSSH client and server"
    echo "  --keygen    Generate a new SSH key pair"
}

generate_key() {
    local email key_file

    if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
        echo "SSH key already exists: $HOME/.ssh/id_ed25519"
        read -rp "Overwrite? [y/N]: " confirm
        if [[ "$confirm" != [yY] ]]; then
            echo "Key generation cancelled."
            return
        fi
    fi

    read -rp "Enter email for SSH key: " email
    if [[ -z "$email" ]]; then
        echo "Error: Email is required."
        return 1
    fi

    key_file="$HOME/.ssh/id_ed25519"
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    ssh-keygen -t ed25519 -C "$email" -f "$key_file"

    echo ""
    echo "SSH key generated:"
    echo "  Private: $key_file"
    echo "  Public:  ${key_file}.pub"
    echo ""
    echo "Your public key:"
    cat "${key_file}.pub"
    echo ""
    echo "Add this to GitHub: https://github.com/settings/keys"
}

uninstall_ssh() {
    if ! command -v ssh &>/dev/null && ! command -v sshd &>/dev/null; then
        echo "OpenSSH is not installed. Nothing to uninstall."
        exit 0
    fi

    echo "This will remove OpenSSH client and server. Your keys (~/.ssh) will NOT be deleted."
    read -rp "Are you sure? [y/N]: " confirm
    if [[ "$confirm" != [yY] ]]; then
        echo "Uninstall cancelled."
        exit 0
    fi

    echo "Removing OpenSSH..."
    if ! sudo apt-get purge -y openssh-client openssh-server; then
        echo "Error: Failed to remove OpenSSH packages."
        exit 1
    fi

    sudo apt-get autoremove -y

    echo ""
    echo "OpenSSH has been removed."
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
    --uninstall) uninstall_ssh ;;
    --keygen)    generate_key; exit 0 ;;
    --help|-h)   usage; exit 0 ;;
    "")          ;; # proceed with install
    *)           echo "Unknown option: $1"; usage; exit 1 ;;
esac

# Check if already installed
if command -v ssh &>/dev/null && command -v sshd &>/dev/null; then
    echo "OpenSSH is already installed."
    echo "  client: $(ssh -V 2>&1)"
    echo "To generate a key, run: $0 --keygen"
    echo "To reinstall, run: $0 --uninstall && $0"
    exit 0
fi

echo "Installing OpenSSH..."

# Update package database
echo "Updating package index..."
if ! sudo apt-get update; then
    echo "Error: Failed to update package index."
    exit 1
fi

# Install
if ! sudo apt-get install -y openssh-client openssh-server; then
    echo "Error: Failed to install OpenSSH."
    exit 1
fi

# Enable and start SSH server
if ! sudo systemctl enable ssh; then
    echo "Error: Failed to enable SSH server."
    exit 1
fi
if ! sudo systemctl start ssh; then
    echo "Error: Failed to start SSH server."
    exit 1
fi

# Verify
echo ""
echo "OpenSSH installed successfully."
echo "  client: $(ssh -V 2>&1)"
echo "  server: $(sudo systemctl is-active ssh)"
echo ""

# Offer key generation
read -rp "Generate an SSH key pair now? [y/N]: " gen
if [[ "$gen" == [yY] ]]; then
    generate_key
fi

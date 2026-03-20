#!/bin/bash
set -euo pipefail

trap 'echo "Error: Script failed at line $LINENO. Check the output above for details."' ERR

DOCKER_PACKAGES=(docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)

usage() {
    echo "Usage: $0 [--uninstall]"
    echo "  No flags    Install Docker CE"
    echo "  --uninstall Remove Docker CE and all its data"
}

uninstall_docker() {
    if ! command -v docker &>/dev/null; then
        echo "Docker is not installed. Nothing to uninstall."
        exit 0
    fi

    echo "This will remove Docker and delete ALL Docker data (images, containers, volumes)."
    read -rp "Are you sure? [y/N]: " confirm
    if [[ "$confirm" != [yY] ]]; then
        echo "Uninstall cancelled."
        exit 0
    fi

    echo "Stopping Docker..."
    sudo systemctl stop docker 2>/dev/null || true
    sudo systemctl stop docker.socket 2>/dev/null || true

    echo "Removing Docker packages..."
    if ! sudo apt-get purge -y "${DOCKER_PACKAGES[@]}"; then
        echo "Error: Failed to remove Docker packages."
        exit 1
    fi

    echo "Removing Docker data..."
    sudo rm -rf /var/lib/docker /var/lib/containerd

    echo "Removing Docker repository and GPG key..."
    sudo rm -f /etc/apt/sources.list.d/docker.sources /etc/apt/sources.list.d/docker.list
    sudo rm -f /etc/apt/sources.list.d/archive_uri-https_download_docker_com_linux_ubuntu-*.list
    sudo rm -f /etc/apt/keyrings/docker.asc

    if ! sudo apt-get autoremove; then
        echo "Warning: autoremove failed. Some unused packages may remain."
    fi

    echo ""
    echo "Docker has been fully removed."
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
    --uninstall) uninstall_docker ;;
    "")          ;; # proceed with install
    *)           echo "Unknown option: $1"; usage; exit 1 ;;
esac

# Check if Docker is already installed
if command -v docker &>/dev/null; then
    echo "Docker is already installed: $(docker --version)"
    echo "To reinstall, run: $0 --uninstall && $0"
    exit 0
fi

# Check for Ubuntu and get codename via /etc/os-release (more reliable than lsb_release)
if [[ ! -f /etc/os-release ]]; then
    echo "Error: /etc/os-release not found. This script is intended for Ubuntu systems."
    exit 1
fi

# shellcheck source=/dev/null
. /etc/os-release

if [[ "$ID" != "ubuntu" ]]; then
    echo "Error: This script is intended for Ubuntu. Detected: $ID"
    exit 1
fi

CODENAME="${UBUNTU_CODENAME:-$VERSION_CODENAME}"
ARCH=$(dpkg --print-architecture)
KEYRING_DIR="/etc/apt/keyrings"
KEYRING_FILE="$KEYRING_DIR/docker.asc"

if [[ -z "$CODENAME" ]]; then
    echo "Error: Could not determine Ubuntu codename."
    exit 1
fi

echo "Installing Docker CE for Ubuntu $CODENAME ($ARCH)..."

# Update package database
echo "Updating package index..."
if ! sudo apt-get update; then
    echo "Error: Failed to update package index."
    exit 1
fi

# Install prerequisites
echo "Installing prerequisites..."
if ! sudo apt-get install -y ca-certificates curl; then
    echo "Error: Failed to install prerequisites."
    exit 1
fi

# Set up Docker GPG key
echo "Adding Docker GPG key..."
if ! sudo install -m 0755 -d "$KEYRING_DIR"; then
    echo "Error: Failed to create $KEYRING_DIR."
    exit 1
fi
if ! sudo curl -fsSL "https://download.docker.com/linux/ubuntu/gpg" -o "$KEYRING_FILE"; then
    echo "Error: Failed to download Docker GPG key."
    exit 1
fi
if ! sudo chmod a+r "$KEYRING_FILE"; then
    echo "Error: Failed to set permissions on GPG key."
    exit 1
fi

# Add Docker repository (DEB822 format)
echo "Adding Docker repository..."
if ! sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $CODENAME
Components: stable
Signed-By: $KEYRING_FILE
EOF
then
    echo "Error: Failed to add Docker repository."
    exit 1
fi

# Update with new repo
if ! sudo apt-get update; then
    echo "Error: Failed to update package index after adding Docker repo."
    exit 1
fi

# Install Docker
echo "Installing Docker CE..."
if ! sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
    echo "Error: Failed to install Docker packages."
    exit 1
fi

# Add current user to docker group
if ! groups "$USER" | grep -q '\bdocker\b'; then
    echo "Adding $USER to the docker group..."
    if ! sudo usermod -aG docker "$USER"; then
        echo "Error: Failed to add $USER to docker group."
        exit 1
    fi
    echo "You will need to log out and back in for group changes to take effect."
fi

# Enable Docker on boot
if ! sudo systemctl enable docker; then
    echo "Error: Failed to enable Docker on boot."
    exit 1
fi

# Verify
echo ""
echo "Docker installation completed successfully."
sudo docker --version
echo ""
echo "NOTE: Log out and back in, then run 'docker run hello-world' to verify."

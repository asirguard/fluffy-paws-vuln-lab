#!/bin/bash

# =============================================================================
# VirtualBox Guest Additions Installer
# =============================================================================
# Run after: Devices -> Insert Guest Additions CD Image
# After this script completes: sudo reboot
# =============================================================================

set -euo pipefail

echo ""
echo "Installing build dependencies..."
apt-get install -y bzip2 gcc make perl build-essential dkms \
    linux-headers-$(uname -r)

echo ""
echo "Mounting Guest Additions CD..."
mount /dev/sr0 /mnt 2>/dev/null || true

echo ""
echo "Running VBoxLinuxAdditions installer..."
/mnt/VBoxLinuxAdditions.run

echo ""
echo "Done. Run: sudo reboot"
echo "Copy-paste will work after reboot."
echo ""

#!/usr/bin/env bash
set -Eeuo pipefail

echo "=== STEP 1: Remove any Snap Firefox remnants ==="
sudo snap remove --purge firefox 2>/dev/null || true

echo "=== STEP 2: Purge APT Firefox and remove old configs ==="
sudo apt purge -y firefox firefox-esr 2>/dev/null || true
sudo apt autoremove -y
rm -rf ~/.mozilla || true

echo "=== STEP 3: Remove Snap enforcement shims ==="
# Snap creates fake firefox stubs in /usr/bin and /bin
sudo rm -f /usr/bin/firefox || true
sudo rm -f /bin/firefox || true

echo "=== STEP 4: Remove leftover snap user directory ==="
rm -rf ~/snap/firefox || true

echo "=== STEP 5: Ensure PATH does NOT contain snap bin directories ==="
# Temporarily disable snap PATH injection
sudo mv /snap/bin /snap/bin.disabled 2>/dev/null || true
sudo mv /var/lib/snapd/snap/bin /var/lib/snapd/snap/bin.disabled 2>/dev/null || true

echo "=== STEP 6: Add Mozillateam PPA ==="
sudo add-apt-repository -y ppa:mozillateam/ppa
sudo apt update

echo "=== STEP 7: Unhold Firefox packages if snapd marked them held ==="
sudo apt-mark unhold firefox firefox-esr 2>/dev/null || true

echo "=== STEP 8: Install REAL Firefox (APT), allow downgrades ==="
sudo apt install -y --allow-downgrades --allow-change-held-packages firefox

echo "=== STEP 9: Create REAL Firefox launcher to override any snap shims ==="
sudo tee /usr/local/bin/firefox >/dev/null <<EOF
#!/bin/bash
exec /usr/lib/firefox/firefox "\$@"
EOF

sudo chmod +x /usr/local/bin/firefox

echo "=== STEP 10: Verify final installation ==="
which firefox
firefox --version || true

echo "=== STEP 11: Purging Firefox NSS Security Database ==="

# Detect Firefox profile (prefer default-release)
FF_PROFILE=$(find ~/.mozilla/firefox -maxdepth 1 -type d \( -name "*.default-release" -o -name "*.default" \) | head -n 1)

if [ -z "$FF_PROFILE" ]; then
  echo "ERROR: Could not find a Firefox profile. Please launch Firefox at least once and close it before running this script."
  exit 1
fi

echo "Detected Firefox profile: $FF_PROFILE"

# Backup current NSS security database
echo "Backing up cert9.db, key4.db, pkcs11.txt..."
mkdir -p ~/firefox-profile-backup
cp "$FF_PROFILE"/cert9.db "$FF_PROFILE"/key4.db "$FF_PROFILE"/pkcs11.txt ~/firefox-profile-backup/ 2>/dev/null || true

# Remove existing NSS security database to regenerate clean
echo "Removing old NSS database files..."
rm -f "$FF_PROFILE"/cert9.db "$FF_PROFILE"/key4.db "$FF_PROFILE"/pkcs11.txt

echo "Firefox NSS database purged and backed up. Restart Firefox once to regenerate."

firefox & sleep 1 && pkill firefox

echo
echo "=== DONE ==="
echo "Run Firefox once to generate profile:"
echo "    firefox &"
echo
echo "Your Firefox profile will now appear under ~/.mozilla/firefox"
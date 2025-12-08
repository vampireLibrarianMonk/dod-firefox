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

echo "=== STEP 6b: Prevent Ubuntu from forcing the Firefox snap ==="
sudo tee /etc/apt/preferences.d/mozillateam-firefox <<EOF
Package: firefox*
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001

Package: firefox*
Pin: origin "archive.ubuntu.com"
Pin-Priority: -1

Package: firefox*
Pin: origin "security.ubuntu.com"
Pin-Priority: -1
EOF

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

echo "=== STEP 11: Run Firefox Once to Establish User Profile ==="

firefox & sleep 1 && pkill firefox

echo "=== STEP 12: Establish OpenSC to the Firefox Profile ==="

# Detect Firefox profile directory
FF_PROFILE=$(find ~/.mozilla/firefox -maxdepth 1 -type d \( -name "*.default-release" -o -name "*.default" \) | head -n 1)

if [ -z "$FF_PROFILE" ]; then
  echo "ERROR: Could not detect Firefox profile. Please launch Firefox at least once, then close it before running this step."
  exit 1
fi

echo "Registering OpenSC PKCS#11 module in Firefox profile: $FF_PROFILE"

modutil -dbdir "sql:$FF_PROFILE" \
  -add "OpenSC" \
  -libfile /usr/lib/x86_64-linux-gnu/pkcs11/opensc-pkcs11.so || echo "Module may already be added or Firefox is open. Close Firefox and try again if needed."

echo "=== STEP 13: "Listing PKCS#11 modules in Firefox Profile ==="

echo "Listing PKCS#11 modules in Firefox profile..."
modutil -list -dbdir "sql:$FF_PROFILE"


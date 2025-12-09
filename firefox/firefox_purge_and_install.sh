#!/usr/bin/env bash
set -Eeuo pipefail


echo "=== STEP 0: Ask for username ==="

# Ask for username (or accept as first argument)
USER_NAME="${1:-}"

# If no username passed, prompt for one
if [ -z "$USER_NAME" ]; then
    read -rp "Enter the target username: " USER_NAME
fi

# Validate that the user exists on the system
if ! id "$USER_NAME" >/dev/null 2>&1; then
    echo "Error: User '$USER_NAME' does not exist."
    exit 1
fi

echo "Using username: $USER_NAME"

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

runuser -l "$USER_NAME" -c "DISPLAY=:0 XDG_RUNTIME_DIR=/run/user/$(id -u "$USER_NAME") firefox &"
sleep 1
pkill -u "$USER_NAME" firefox

echo "=== STEP 12: Establish OpenSC in the Firefox Profile (Idempotent) ==="

USER_HOME=$(eval echo "~$USER_NAME")

# Detect Firefox profile directory
FF_PROFILE=$(find "$USER_HOME/.mozilla/firefox" \
    -maxdepth 1 -type d \
    \( -name "*.default-release" -o -name "*.default" \) \
    | head -n 1)

if [ -z "$FF_PROFILE" ]; then
    echo "ERROR: Could not detect Firefox profile for user $USER_NAME."
    echo "Launch Firefox once as the user, then re-run this script."
    exit 1
fi

echo "Detected Firefox profile at: $FF_PROFILE"

# Check if module already exists
MODULE_EXISTS=$(runuser -l "$USER_NAME" -c \
    "modutil -list -dbdir 'sql:$FF_PROFILE'" 2>/dev/null | grep -c "OpenSC" || true)

if [ "$MODULE_EXISTS" -gt 0 ]; then
    echo "OpenSC PKCS#11 module already installed — skipping."
else
    echo "Adding OpenSC PKCS#11 module (non-interactive)..."
    runuser -l "$USER_NAME" -c "
        printf '\n' | modutil -dbdir 'sql:$FF_PROFILE' \
            -add 'OpenSC' \
            -force \
            -libfile /usr/lib/x86_64-linux-gnu/pkcs11/opensc-pkcs11.so
    "
    echo "OpenSC module added."
fi

# Final confirmation
echo "=== STEP 13: Listing PKCS#11 modules ==="
runuser -l "$USER_NAME" -c \
    "modutil -list -dbdir 'sql:$FF_PROFILE'"
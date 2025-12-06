#!/usr/bin/env bash
set -Eeuo pipefail

echo "===================================================="
echo "   DoD CAC + DoD PKI Installation for Ubuntu 22.04"
echo "===================================================="

### -------------------------------
### 1. REMOVE FIREFOX SNAP
### -------------------------------
echo "[1/7] Removing Firefox Snap..."
sudo snap remove --purge firefox 2>/dev/null || true
sudo apt purge -y firefox || true
sudo apt autoremove -y

sudo rm /etc/apt/preferences.d/mozilla-firefox 2>/dev/null || true
sudo rm /etc/apt/apt.conf.d/51snap-firefox 2>/dev/null || true

### -------------------------------
### 2. INSTALL REAL FIREFOX
### -------------------------------
echo "[2/7] Installing real Firefox from Mozillateam PPA..."
sudo add-apt-repository -y ppa:mozillateam/ppa
sudo apt update
sudo apt install -y firefox

echo "Pinning Firefox to avoid Snap reinstallation..."
sudo tee /etc/apt/preferences.d/mozillateamppa > /dev/null <<EOF
Package: firefox
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
EOF

### -------------------------------
### 3. INSTALL CAC MIDDLEWARE
### -------------------------------
echo "[3/7] Installing OpenSC + pcscd..."
sudo apt install -y opensc pcscd
sudo systemctl enable --now pcscd

### -------------------------------
### 4. CREATE DoD CERT DIRECTORY
### -------------------------------
echo "[4/7] Preparing DoD certificate directory..."
sudo mkdir -p /usr/local/share/ca-certificates/dod

### -------------------------------
### 5. PROMPT USER FOR PKCS#7 FILE
### -------------------------------
echo
echo "Please download the DoD PKCS#7 bundle from:"
echo "  https://www.cyber.mil/pki-pke/document-library/"
echo "Select: PKI CA Certificate Bundles: PKCS#7 for DoD PKI Only - Version #.##"
echo "Save it as: dod_pki.p7b"
echo
echo "Place it in: /usr/local/share/ca-certificates/dod/"
echo "Press ENTER when ready."
read -r _

if [[ ! -f /usr/local/share/ca-certificates/dod/dod_pki.p7b ]]; then
    echo "ERROR: File dod_pki.p7b not found."
    exit 1
fi

cd /usr/local/share/ca-certificates/dod/

### -------------------------------
### 6. EXTRACT CERTIFICATES
### -------------------------------
echo "[5/7] Extracting PEM certificates..."
openssl pkcs7 -inform DER -print_certs \
  -in dod_pki.p7b \
  -out dod-all.pem

echo "Splitting certificates..."
sudo csplit -s -z dod-all.pem '/-----BEGIN CERTIFICATE-----/' '{*}'
for f in xx*; do sudo mv "$f" "$f.crt"; done

### -------------------------------
### 7. UPDATE TRUST STORE
### -------------------------------
echo "[6/7] Updating system CA trust..."
sudo update-ca-certificates

### -------------------------------
### 8. REGISTER PKCS#11 IN FIREFOX
### -------------------------------
echo "[7/7] Registering CAC PKCS#11 in Firefox..."

FF_DB=$(ls -d $HOME/.mozilla/firefox/*.default-release)

modutil -dbdir sql:"$FF_DB" \
  -add "OpenSC" \
  -libfile /usr/lib/x86_64-linux-gnu/pkcs11/opensc-pkcs11.so || true

echo
echo "===================================================="
echo " Installation Complete!"
echo " Test CAC login at:"
echo "   https://webmail.apps.mil"
echo "   https://safe.apps.mil"
echo "   https://mypay.dfas.mil"
echo "===================================================="
echo

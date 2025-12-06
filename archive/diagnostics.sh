#!/usr/bin/env bash
set -Eeuo pipefail

echo "=============================================="
echo " DoD CAC / DoD PKI Diagnostics for Ubuntu"
echo "=============================================="

### 1. pcscd status
echo "[1] Checking pcscd..."
systemctl is-active pcscd && echo "pcscd OK" || echo "pcscd NOT running"

### 2. CAC reader detection
echo "[2] Checking CAC reader..."
pcsc_scan -n >/dev/null 2>&1 && echo "CAC detected" || echo "NO CAC detected"

### 3. PKCS#11 module presence
echo "[3] Checking PKCS#11 module..."
test -f /usr/lib/x86_64-linux-gnu/pkcs11/opensc-pkcs11.so \
  && echo "PKCS#11 OK" \
  || echo "PKCS#11 MISSING!"

### 4. Firefox PKCS#11 registration
echo "[4] Checking Firefox module registration..."
FF_DB=$(ls -d ~/.mozilla/firefox/*.default-release)
modutil -list -dbdir sql:"$FF_DB" | grep -q "OpenSC" \
  && echo "Firefox PKCS#11 module registered" \
  || echo "Firefox PKCS#11 NOT registered"

### 5. DoD certs installed
echo "[5] Checking DoD certificates..."
ls /usr/local/share/ca-certificates/dod/*.crt >/dev/null 2>&1 \
  && echo "DoD certificates installed" \
  || echo "DoD certificates NOT found"

### 6. System CA database
echo "[6] Checking CA bundle..."
grep -qi "dod" /etc/ssl/certs/* 2>/dev/null \
  && echo "DoD certs present in system trust" \
  || echo "DoD certs NOT in system trust"

### 7. CRL reachability
echo "[7] Checking DISA CRL endpoint..."
curl -I -m 5 https://crl.gds.disa.mil >/dev/null 2>&1 \
  && echo "CRL endpoint reachable" \
  || echo "CRL endpoint BLOCKED"

echo "=============================================="
echo " Diagnostics Complete"
echo "=============================================="
echo

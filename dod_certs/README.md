# DoD PKI Certificate Installation – Ubuntu 22.04 (2025 Workflow)

This README provides the **correct**, **modern**, and **working** procedure for installing DoD PKI CA certificates on **Ubuntu 22.04**, including corrections for the new Cyber.mil ZIP format (2024–2025).  
This document supports:

- Non‑Snap Firefox
- CAC login (OpenSC + pcscd)
- DoD PKI trust installation
- WSL users (special note at the bottom)

---

# ✅ 0. Install unzip

```bash
sudo apt-get update && sudo apt-get install libnss3-tools unzip -y
```

# ✅ 1. Extract the DoD ZIP Package

Download from:

**https://www.cyber.mil/pki-pke/document-library/**

Locate:

**PKI CA Certificate Bundles: PKCS#7 for DoD PKI Only — Version 5.14**

You will receive:

```
unclass-certificates_pkcs7_DoD.zip
```

Extract:

```bash
cd ~/Downloads # WSL: /mnt/c/Users/<YOUR_WINDOWS_USERNAME>/Downloads
unzip unclass-certificates_pkcs7_DoD.zip -d dod_pki
cd dod_pki/Certificates_PKCS7_v5_14_DoD
```

---

# ✅ 2. Identify the Correct PKCS#7 Bundle

Inside the extracted folder you will see files like:

```
Certificates_PKCS7_v5_14_DoD.pem.p7b   <-- USE THIS ONE
Certificates_PKCS7_v5_14_DoD.der.p7b
Certificates_PKCS7_v5_14_DoD_DoD_Root_CA_3.der.p7b
Certificates_PKCS7_v5_14_DoD_DoD_Root_CA_4.der.p7b
...
```

**Only one file is needed:**

```
Certificates_PKCS7_v5_14_DoD.pem.p7b
```

Rename:

```bash
mv Certificates_PKCS7_v5_14_DoD.pem.p7b dod_pki.p7b
```

---

# ✅ 3. Move the PKCS#7 Bundle Into System CA Store

```bash
sudo mkdir -p /usr/local/share/ca-certificates/dod
sudo cp dod_pki.p7b /usr/local/share/ca-certificates/dod/
cd /usr/local/share/ca-certificates/dod
```

---

# ✅ 4. Convert PKCS#7 → PEM

```bash
sudo openssl pkcs7 -print_certs   -in dod_pki.p7b   -out dod-all.pem
```

Verify the dod-all.pem begins with:

```
-----BEGIN CERTIFICATE-----
```

---

# ✅ 5. Split PEM Into Individual Certificates

```bash
sudo csplit -s -z dod-all.pem '/-----BEGIN CERTIFICATE-----/' '{*}'
for f in xx*; do sudo mv "$f" "$f.crt"; done
```

This produces (use ls -l):

```
xx00.crt
xx01.crt
xx02.crt
...
```

---

# ✅ 6. Install Into Ubuntu Certificate Trust Store

```bash
sudo update-ca-certificates
```

Expected output includes:

```
Updating certificates in /etc/ssl/certs...
rehash: warning: skipping ca-certificates.crt,it does not contain exactly one certificate or CRL
rehash: warning: skipping xx00.pem,it does not contain exactly one certificate or CRL
50 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d...
done.
```

Stop here and install firefox


# ✅ 7. Run the OpenSC PKCS#11 Registration

```bash
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
```

Expected output includes:

```
WARNING: Performing this operation while the browser is running could cause
corruption of your security databases. If the browser is currently running,
you should exit browser before continuing this operation. Type
'q <enter>' to abort, or <enter> to continue:

Module "OpenSC" added to database.
```

# ✅ 8. Install Into Ubuntu Certificate Trust Store

```bash
echo "Listing PKCS#11 modules in Firefox profile..."
modutil -list -dbdir "sql:$FF_PROFILE"
```

Expected output includes:

```
Listing of PKCS #11 Modules
-----------------------------------------------------------
  1. NSS Internal PKCS #11 Module
           uri: pkcs11:library-manufacturer=Mozilla%20Foundation;library-description=NSS%20Internal%20Crypto%20Services;library-version=X.XX
         slots: 2 slots attached
        status: loaded

         slot: NSS Internal Cryptographic Services
        token: NSS Generic Crypto Services
          uri: pkcs11:token=NSS%20Generic%20Crypto%20Services;manufacturer=Mozilla%20Foundation;serial=0000000000000000;model=NSS%20X

         slot: NSS User Private Key and Certificate Services
        token: NSS Certificate DB
          uri: pkcs11:token=NSS%20Certificate%20DB;manufacturer=Mozilla%20Foundation;serial=0000000000000000;model=NSS%20X

  2. OpenSC
        library name: /usr/lib/x86_64-linux-gnu/pkcs11/opensc-pkcs11.so
           uri: pkcs11:library-manufacturer=OpenSC%20Project;library-description=OpenSC%20smartcard%20framework;library-version=X.XX
         slots: 1 slot attached
        status: loaded

         slot: <READER_NAME> (e.g., Contact Reader [CCID Interface] ...)
        token: <CAC_NAME_OR_LABEL> (e.g., john.doe.civ.1234567890)
          uri: pkcs11:token=<CAC_NAME_ENCODED>;manufacturer=piv_II;serial=<SERIAL_NUMBER>;model=PKCS%2315%20emulated
```

This completes DoD PKI system trust installation.

# 🎉 Done

You now have the **correct**, **validated**, and **modern (2025)** DoD PKI installation method for Ubuntu 22.04.

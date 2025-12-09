# DoD PKI Certificate Installation – Ubuntu 22.04 (2025 Workflow)

This README provides the **correct**, **modern**, and **working** procedure for installing DoD PKI CA certificates on **Ubuntu 22.04**, including corrections for the new Cyber.mil ZIP format (2024–2025).  
This document supports:

- Non‑Snap Firefox
- CAC login (OpenSC + pcscd)
- DoD PKI trust installation
- WSL users (special note at the bottom)

---

# 0. Install the following packages

```bash
sudo apt-get update && sudo apt-get install libnss3-tools unzip -y
```

# 1. Extract the DoD ZIP Package

Download from:

**https://www.cyber.mil/pki-pke/document-library/**

Locate:

**PKI CA Certificate Bundles: PKCS#7 for DoD PKI Only — Version 5.14**

You will receive:

```
unclass-certificates_pkcs7_DoD.zip
```

Extract from your download location (actual contents will vary):

```bash
cd /mnt/c/Users/<YOUR_WINDOWS_USERNAME>/Downloads # WSL location
unzip unclass-certificates_pkcs7_DoD.zip -d dod_pki
cd dod_pki/Certificates_PKCS7_v5_14_DoD
```

---

# 2. Identify the Correct PKCS#7 Bundle

Inside the extracted folder you will see files like:

```
Certificates_PKCS7_v5_14_DoD.pem.p7b   <-- USE THIS ONE
Certificates_PKCS7_v5_14_DoD.der.p7b
Certificates_PKCS7_v5_14_DoD_DoD_Root_CA_3.der.p7b
Certificates_PKCS7_v5_14_DoD_DoD_Root_CA_4.der.p7b
...
```

Rename:

```bash
mv Certificates_PKCS7_v5_14_DoD.pem.p7b dod_pki.p7b
```

---

# 3. Move the PKCS#7 Bundle Into System CA Store

```bash
sudo mkdir -p /usr/local/share/ca-certificates/dod
sudo cp dod_pki.p7b /usr/local/share/ca-certificates/dod/
cd /usr/local/share/ca-certificates/dod
```

---

# 4. Convert PKCS#7 → PEM

```bash
sudo openssl pkcs7 -print_certs -in dod_pki.p7b -out dod-all.pem
head dod-all.pem
```

Verify the dod-all.pem begins with:

```
-----BEGIN CERTIFICATE-----
```

---

# 5. Split PEM Into Individual Certificates

```bash
sudo csplit -s -z dod-all.pem '/-----BEGIN CERTIFICATE-----/' '{*}'
for f in xx*; do sudo mv "$f" "$f.crt"; done
ls -l
```

This produces (use ls -l):

```
xx00.crt
xx01.crt
xx02.crt
...
```

---

# 6. Install Into Ubuntu Certificate Trust Store

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
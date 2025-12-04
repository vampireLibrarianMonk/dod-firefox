# DoD CAC + DoD PKI Certificate Installation on Ubuntu 22.04+
### With Firefox Snap Removal and Real Firefox Installation

This guide provides a **known-working**, fully reproducible method for setting up:

- Working Firefox (APT version, not Snap)
- DoD PKI Certificate Installation (PKCS#7 bundle)
- CAC Smartcard Support (OpenSC + pcscd)
- Firefox PKCS#11 registration for CAC authentication

This README assumes Ubuntu **22.04 LTS**.

---

# 1. Remove Firefox Snap (Required)

Ubuntu uses **Snap Firefox by default**, which **does not support** DoD PKI SSL trust injection or CAC smartcard PKCS#11 modules.

Remove Snap completely:

```bash
sudo snap remove --purge firefox
sudo apt purge -y firefox
sudo apt autoremove -y
```

Prevent Snap from reinstalling Firefox via APT shims:

```bash
sudo rm /etc/apt/preferences.d/mozilla-firefox
sudo rm /etc/apt/apt.conf.d/51snap-firefox 2>/dev/null || true
```

---

# 2. Install Real Firefox from Mozillateam PPA (Supports CAC)

Add the official APT repository:

```bash
sudo add-apt-repository -y ppa:mozillateam/ppa
sudo apt update
sudo apt install -y firefox
```

Pin Firefox to avoid Snap reinstall:

```bash
echo "Package: firefox
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001" | sudo tee /etc/apt/preferences.d/mozillateamppa
```

Firefox is now installed from `.deb` and supports:

- System CA certificates  
- CAC smartcard authentication  
- PKCS#11 modules  

---

# 3. Install CAC Middleware (OpenSC + pcscd)

```bash
sudo apt install -y opensc pcscd
sudo systemctl enable --now pcscd
```

Check CAC detection:

```bash
pcsc_scan
```

You should see your reader and CAC ATR.

---

# 4. Obtain DoD PKI Certificate Bundle (PKCS#7)

Download from the official DoD PKI repository:

**https://www.cyber.mil/pki-pke/document-library/**

Use:

> **PKI CA Certificate Bundles: PKCS#7 for DoD PKI Only – Version #.##**

Save as:

```
dod_pki_v#.##.p7b
```

Place it into:

```
/usr/local/share/ca-certificates/dod/
```

---

# 5. Install DoD Certificates into Ubuntu Trust Store

Convert PKCS#7 → PEM:

```bash
openssl pkcs7 -inform DER -print_certs \
  -in dod_pki_v#.##.p7b \
  -out dod-all.pem
```

Split into individual certs:

```bash
sudo mkdir -p /usr/local/share/ca-certificates/dod/
cd /usr/local/share/ca-certificates/dod

sudo csplit -s -z ~/dod-all.pem '/-----BEGIN CERTIFICATE-----/' '{*}'
for f in xx*; do sudo mv "$f" "$f.crt"; done
```

Update system trust:

```bash
sudo update-ca-certificates
```

---

# 6. Register CAC Smartcard Module in Firefox

Find your Firefox profile:

```bash
ls ~/.mozilla/firefox
```

Look for: `*.default-release`

Register OpenSC PKCS#11 module:

```bash
modutil -dbdir sql:$HOME/.mozilla/firefox/*.default-release \
  -add "OpenSC" \
  -libfile /usr/lib/x86_64-linux-gnu/pkcs11/opensc-pkcs11.so
```

Verify:

```bash
modutil -list -dbdir sql:$HOME/.mozilla/firefox/*.default-release
```

You should see:

```
OpenSC Smartcard Framework
```

---

# 7. Test CAC Authentication

Test sites:

- https://webmail.apps.mil  
- https://mypay.dfas.mil  
- https://safe.apps.mil  
- https://idco.dmdc.osd.mil  

You MUST see:

- Certificate selection popup  
- CAC PIN prompt  

---

# 8. Scripts Included

Run installer:

```bash
sudo ./install.sh
```

Run diagnostics:

```bash
./diagnostics.sh
```

---

# End of README.

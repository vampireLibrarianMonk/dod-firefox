# DoD CAC + DoD PKI Certificate Installation on Ubuntu 22.04+
### With Firefox Snap Removal and Real Firefox Installation

This guide provides a **known-working**, fully reproducible method for setting up:

- Working Firefox (APT version, not Snap)
- DoD PKI Certificate Installation (from DoD PKCS#7 ZIP package)
- CAC Smartcard Support (OpenSC + pcscd)
- Firefox PKCS#11 registration for CAC authentication

This README assumes Ubuntu **22.04 LTS**.

---

# 1. Install CAC Middleware (OpenSC + pcscd)

```bash
sudo apt install -y opensc pcscd pcsc-tools
sudo systemctl enable --now pcscd
```

Check CAC detection:

```bash
pcsc_scan
```

You should see your reader and CAC ATR.

---
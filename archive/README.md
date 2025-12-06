This guide provides a **known-working**, fully reproducible method for setting up:

- Working Firefox (APT version, not Snap)

This README assumes Ubuntu **22.04 LTS**.

---

# 1. Remove Firefox Snap (Required) and install via apt repository:

Ubuntu uses **Snap Firefox by default**, which **does not support** DoD PKI SSL trust injection or CAC smartcard PKCS#11 modules.

Remove Snap completely:

```bash
sudo vim firefox_purge_and_install.sh
```


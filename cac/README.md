# DoD CAC + DoD PKI Certificate Installation on Ubuntu 22.04+
### With Firefox Snap Removal and Real Firefox Installation

This guide provides a **known-working**, fully reproducible method for setting up:

- CAC Smartcard Support (OpenSC + pcscd)
- Correct USB passthrough for CAC smartcard readers using **usbipd-win 4.x**

This README assumes Ubuntu **22.04 LTS** running inside **WSL2**.

---

# 0. Attach Your CAC Reader to WSL Using usbipd-win (Required)

Before middleware or Firefox can detect your CAC, you must attach the USB smartcard reader into WSL.

### **Step 1 — List all USB devices on Windows**

Open **PowerShell as Administrator**:

```powershell
usbipd list
```

Identify your CAC reader.  
Example output:

```
BUSID  VID:PID    DEVICE
1-7    04e6:5814  Microsoft Usbccid Smartcard Reader (WUDF)                     
```

Your busid may differ (ex: `1-4`, `2-3`, etc.).

---

### **Step 2 — Attach the CAC reader to the default WSL distribution**

usbipd-win 4.x uses simplified syntax:

```powershell
usbipd attach --wsl --busid 1-7
```

Replace `1-7` with the busid of your CAC reader.

> **Note:**  
> This attaches to your **default WSL distro**.  
> To check your default:

```powershell
wsl -l -v
```

You can change the default distro if needed:

```powershell
wsl --set-default Ubuntu-22.04
```

Then attach the reader again:

```powershell
usbipd attach --wsl --busid 1-7
```

Example Output:

```powershell
usbipd: info: Using WSL distribution 'Ubuntu-22.04' to attach; the device will be available in all WSL 2 distributions.
usbipd: info: Loading vhci_hcd module.
usbipd: info: Detected networking mode 'nat'.
usbipd: info: Using IP address 172.20.192.1 to reach the host.
```

---

### **Step 3 — Confirm WSL sees the USB reader**

Inside Ubuntu:

```bash
lsusb
```

You should see something resembling:

```
Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 001 Device 002: ID 04e6:5814 SCM Microsystems, Inc. SCR3500 A Contact Reader
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
```

You may now proceed with CAC middleware installation.

---

# 1. Install CAC Middleware (OpenSC + pcscd)

```bash
sudo apt-get update # if first time installing
sudo apt install -y opensc pcscd pcsc-tools
sudo systemctl enable --now pcscd
```

---

### **Check CAC detection**

```bash
pcsc_scan
```

Expected behavior:

- Reader identified  
- “Card inserted”  
- ATR displayed  

If `pcsc_scan` reports **No readers found**, ensure:

1. `usbipd attach --wsl --busid <busid>` was run  
2. You are attached to the **default** WSL distro  
3. The Windows Smart Card Service isn’t exclusively locking the reader  
   - If needed:

```powershell
Stop-Service SCardSvc
```

Then attach again.

---

Your CAC reader is now correctly passed through into WSL and recognized by OpenSC.  
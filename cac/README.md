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
1-7    0x0CC1     SCR331 Smart Card Reader
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

---

### **Step 3 — Confirm WSL sees the USB reader**

Inside Ubuntu:

```bash
lsusb
```

You should see something resembling:

```
Bus 001 Device 007: ID 0cc1:xxxx SCM Microsystems SCR331
```

You may now proceed with CAC middleware installation.

---

# 1. Install CAC Middleware (OpenSC + pcscd)

```bash
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
# Using a DoD CAC Smart Card Inside WSL2 (Ubuntu)

This guide describes how to enable Common Access Card (CAC) support inside WSL2 Ubuntu using OpenSC, pcscd, pcsc-tools, and USB passthrough via usbipd-win.

> **Note:** CAC in WSL2 is advanced and not officially supported.  
> For most users, CAC access works more easily in native Windows browsers.  
> These steps are for WSL-only workflows.

---

## 1. Configure WSL for USB Passthrough

Create or edit the Windows WSL configuration file:

### Path

%UserProfile%\.wslconfig

### Contents

```
[wsl2]
usbipd = true
```

Restart WSL:

```powershell
wsl --shutdown
```

---

## 2. Install USBIPD Tools on Windows (use admin)

Install usbipd-win:

```powershell
winget install usbipd
```

Verify installation:

```powershell
usbipd --version
```

---

## 3. List USB Devices (Old & New Syntax)

### New syntax:

```powershell
usbipd list
```

### Old syntax (deprecated):

```powershell
usbipd wsl list
```

---

## 4. Install CAC Middleware Inside WSL

Inside Ubuntu:

```bash
sudo apt update
sudo apt install -y opensc pcscd pcsc-tools
```

Enable smart-card service:

```bash
sudo systemctl enable --now pcscd
```

---

## 5. Bind and Attach USB Device to WSL

### Step 5.1 — Identify USB Devices

```powershell
usbipd list
```

Example:

```
BUSID  VID:PID     DEVICE
1-4    058f:9540   USB Smart Card Reader
```

---

### Step 5.2 — Bind the Device

```powershell
usbipd bind --busid <BUSID>
```

---

### Step 5.3 — Attach to WSL

Attach to default WSL distro:

```powershell
usbipd attach --wsl --busid <BUSID>
```

Specify distro:

```powershell
usbipd attach --wsl --distribution Ubuntu --busid 1-4
```

---

## 6. Restart Smart-Card Services in WSL

```bash
sudo service pcscd restart
```

---

## 7. Verify CAC Reader Detection

```bash
pcsc_scan
```

Expected output:

```
Scanning present readers...
0: Your Smart Card Reader
   Card inserted
   ATR: 3B ...
```

---

## 8. Detach USB Device

```powershell
usbipd detach --busid <BUSID>
```

---

## 19. Troubleshooting

### Reader missing from `usbipd list`

```powershell
Stop-Service SCardSvc
usbipd list
Start-Service SCardSvc
```

### No readers in WSL:

```bash
sudo service pcscd restart
```

---

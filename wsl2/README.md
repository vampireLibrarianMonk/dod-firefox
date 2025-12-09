# Setting Up WSL2 fo USB Passthrough (Ubuntu)

This guide describes how to enable USB passthrough via usbipd-win.

> **Note:** CAC in WSL2 is advanced and not officially supported.  
> For most users, CAC access works more easily in native Windows browsers.  
> These steps are for WSL-only workflows.

---

## 1. Configure WSL for USB Passthrough

Create or edit the Windows WSL configuration file:

### Path

wsl2/.wslconfig

to

%UserProfile%\.wslconfig

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

# Reset Ubuntu 22.04 Installation

## 1. Shutdown WSL
```powershell
wsl --shutdown
```

## 2. Unregister Ubuntu

```powershell
wsl --unregister Ubuntu-22.04
```

You should see:

Unregistering.


This removes ONLY the distro, not WSL itself. 

## 3. Install a fresh Ubuntu 22.04 filesystem

```powershell
wsl --install -d Ubuntu-22.04
```

Ubuntu will now:

Recreate a new VHDX

Ask for new username/password

It should boot directly into the OS.
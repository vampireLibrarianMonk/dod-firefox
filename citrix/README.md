# Citrix Workspace on Ubuntu 22.04

## 0. Citrix Web Page

# Go to the Citrix home page and select the desired version

https://www.citrix.com/downloads/workspace-app/linux/workspace-app-for-linux-latest.html

# Run the hash check
```bash
echo "{HASH} icaclient_##.##.#.##_amd64.deb" | sha256sum --check
```

Move on if it is OK

## 1. Install Required Dependencies
Ubuntu 22.04 does not ship libidn11, but the package from Ubuntu 20.04 works perfectly.

```bash
wget http://archive.ubuntu.com/ubuntu/pool/main/libi/libidn/libidn11_1.33-2.2ubuntu2_amd64.deb
```

## 2. Install it
```bash
sudo dpkg -i libidn11_1.33-2.2ubuntu2_amd64.deb
```

Confirm:

```bash
dpkg -l | grep libidn11
```

You should see:

```bash
ii  libidn11  1.33-2.2ubuntu2  amd64  GNU Libidn library, implementation of IETF IDN
```

## 3. Install Citrix Workspace
```bash
sudo dpkg -i ~/Downloads/icaclient.deb
sudo apt --fix-broken install -y
```

# Do not install the powerTrust or deviceTrust modules.

## 4. Add DoD Certificates to Citrix Trust Store
```bash
sudo cp /usr/local/share/ca-certificates/dod/*.crt /opt/Citrix/ICAClient/keystore/cacerts/
sudo /opt/Citrix/ICAClient/util/ctx_rehash
```

## 5. Install Desktop Integration Utilities and Set Citrix as the Default ICA Handler
```bash
sudo apt-get install xdg-utils -y
xdg-mime default wfica.desktop application/x-ica
```

## 6. Launch ICA Files from Downloads
Open any `.ica` file:
```bash
/opt/Citrix/ICAClient/wfica ~/Downloads/*.ica
```

Or a specific file:
```bash
/opt/Citrix/ICAClient/wfica ~/Downloads/launch.ica
```

## WSL Citrix Troubleshooting – Concise Fix Steps (Corrected)

These fixes work because WSLg provides its own audio and graphics layers, which conflict with Citrix’s HDX hardware acceleration and audio modules, causing ICA sessions to terminate. By disabling HDX acceleration and audio, Citrix runs in a WSL-compatible “safe mode” that avoids those conflicts and keeps the session stable.

## 1. Install PulseAudio client libraries

```bash
sudo apt install -y pulseaudio libpulse0 libpulse-mainloop-glib0
```

## 2. Disable Citrix hardware acceleration and HDX audio (required for WSL)
```bash
export ICAROOT=/opt/Citrix/ICAClient
export HDX_NOACCEL=1
export HDX_NOAUDIO=1
```

## 3. Launch your ICA session
```
bash/opt/Citrix/ICAClient/wfica ~/Downloads/*.ica
```
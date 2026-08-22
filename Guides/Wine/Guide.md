# Set Up Wine 10.17+ for Affinity Apps on Linux 

## Table of Contents

- [Why This Guide?](#why-this-guide)
- [Requirements](#-requirements)
- [Installation Steps](#-installation-steps)
- [Troubleshooting](#-troubleshooting)
- [Optional Enhancements After Installation](#-optional-enhancements-after-installation)
- [Uninstall Affinity and Wine](#-uninstall-affinity-and-wine)
- [Verified Environments](#-verified-environments)
- [Credits](#-credits)

---

## Why This Guide?

Affinity apps need Windows Runtime (WinRT) APIs, which older Wine versions lacked. 
You need Wine 10.17 or newer to fix a missing file that previously blocked the installer. The actual WinRT functionality is then provided by adding a separate helper DLL and metadata file.

Thank you [Wanesty](https://codeberg.org/wanesty) for being the first one to discover this update! You may check out [her guide for installing and running Affinity with Wine](https://affinity.liz.pet/).

---

## ⚙️ Requirements

- **Wine 10.17+** (mainline/devel build)
- **Winetricks**
- **curl**
- About 10 GB of free disk space
- Internet connection

---

## 🧩 Installation Steps

> [!NOTE]
> As an alternative to manually set up Wine 10.17+ to install Affinity with the following steps, you may try out [our experimental Affinity On Linux installer script](/Guides/Wine/Script%20Installer) to help streamline Affinity installation under Wine. Follow the instructions on the page to download and run the installer script.

### Step 1: Install Wine and Winetricks

#### Fedora / Nobara (Recommended method)

Official Fedora mirrors often mix versions, so use WineHQ’s repo for correct 10.17+ packages.

```bash
sudo dnf install curl -y
sudo rm -f /etc/yum.repos.d/winehq.repo
sudo tee /etc/yum.repos.d/winehq.repo <<'EOF'
[winehq-devel]
name=WineHQ packages for Fedora 41
baseurl=https://dl.winehq.org/wine-builds/fedora/41/
enabled=1
gpgcheck=0
EOF
sudo dnf makecache
sudo dnf install winehq-devel -y
```

If installing `winetricks` via `dnf` fails or tries to downgrade Wine, use the **manual script** (safe for any distro including Nobara, please see [Manual Winetricks Install](#manual-winetricks-install)).

#### Arch / Manjaro

```bash
sudo pacman -S --needed wine winetricks curl
# or, on AUR-based distros:
# yay -S wine winetricks
```

#### Ubuntu / Pop OS / Debian

```bash
sudo dpkg --add-architecture i386
sudo mkdir -pm755 /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/winehq.asc https://dl.winehq.org/wine-builds/winehq.key
sudo sh -c 'echo "deb [signed-by=/etc/apt/keyrings/winehq.asc] https://dl.winehq.org/wine-builds/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/winehq.list'
sudo apt update
sudo apt install --install-recommends winehq-devel winetricks curl -y
```

Verify your version:
```bash
wine --version
```
Should return **wine‑10.17** or newer.

### Step 2: Create a clean Wine prefix

```bash
export WINEPREFIX="$HOME/.affinity"
wineboot --init
```

> [!WARNING]
> You might need to change "$HOME/" to your full home folder path like "/home/YourUsername/" so it points to the [absolute](https://www.redhat.com/sysadmin/linux-path-absolute-relative) location. This is a common problem if you're using a shell that doesn't follow standard POSIX rules.

### Step 3: Install runtime dependencies
Install core components Affinity depends on with Winetricks.

```bash
winetricks --unattended --force remove_mono vcrun2022 dotnet48 corefonts win11
```

> [!NOTE]
> The .NET 4.8 installation is large and may take 10–20 minutes.

Additional components you may want to install with winetricks if you encounter issues with running Affinity with Wine:
- `renderer=vulkan`
- `dxvk`
- `tahoma` (if you are getting pixelated fonts)

### Step 4: Install Affinity

> [!NOTE]
> - Affinity apps can be found here: [Affinity by Canva](https://www.affinity.studio/download) | [Version 2](https://affinity.serif.com/v2/) | [Archived](https://archive.org/details/affinity_20251030)
> - Make sure you have your installation file in `~/Downloads`.
> - "$HOME" may not work and you may need to put in your full path depending on your distro.

```bash
WINEPREFIX="$HOME/.affinity" wine "$HOME/Downloads/Affinity x64.exe"
```

The command above installs Affinity by Canva (V3). If you are installing V2 instead, Photo 2, Designer 2, and Publisher 2 each ship as their own separate `.exe` installer. Download each one you want, then repeat the command above once per `.exe`, pointing it at the matching downloaded file, all against the same `$WINEPREFIX`. You do not need to run the same installer file multiple times, only once per app.

Follow normal installation prompts.

After you finish installing Affinity, if your Wine version is **11 or newer**, you can immediately skip to launching Affinity as instructed at Step 8. Otherwise, continue to Step 5 to 7.

### Step 5: Download required helper files

These add Windows Runtime metadata support Affinity expects.

```bash
cd /tmp
curl -L -o Windows.winmd https://github.com/microsoft/windows-rs/raw/master/crates/libs/bindgen/default/Windows.winmd
curl -L -o wintypes.dll https://github.com/ElementalWarrior/wine-wintypes.dll-for-affinity/raw/refs/heads/master/wintypes_shim.dll.so
```

If your download ends with `.dll.so`, rename it:
```bash
mv /tmp/wintypes.dll.so /tmp/wintypes.dll 2>/dev/null || true
```

### Step 6: Copy metadata + shim files

```bash
mkdir -p "$WINEPREFIX/drive_c/windows/system32/winmetadata"
cp /tmp/Windows.winmd "$WINEPREFIX/drive_c/windows/system32/winmetadata/"
cp /tmp/wintypes.dll "$WINEPREFIX/drive_c/Program Files/Affinity/Affinity/"
```

If you installed Photo 2, Designer 2, or Publisher 2 separately, copy into each of their directories.

### Step 7: Configure the `wintypes` DLL override

```bash
WINEPREFIX="$HOME/.affinity" winecfg
```
In **Libraries** tab:
1. Type **wintypes** under “New override for library”.
2. Click **Add**, then **Edit**, choose **Native (Windows)**.
3. Click **Apply**, then **OK**.

<img width="409" height="482" alt="image" src="https://github.com/user-attachments/assets/756320cf-5c19-4eb6-a093-7938e0e40aec" />

### Step 8: Launch Affinity

```bash
WINEPREFIX="$HOME/.affinity" wine "$WINEPREFIX/drive_c/Program Files/Affinity/Affinity/Affinity.exe"
```

Adjust the `drive_c/Program Files` path for Photo 2, Designer 2, or Publisher 2 paths if needed.

---

## 🧠 Troubleshooting

### Installer warns "Setup is not recommended... A native installer exists for this CPU type"

At the start of Step 4, the installer may show a dialog titled "Setup is not recommended for the following reasons: A native installer exists for this CPU type", with **Ignore** and **Close** buttons. This is a false positive: the installer's CPU/OS check misfires under Wine, treating it as a platform with its own native (non-x64) installer available. Click **Ignore** and installation proceeds normally.

### GLIBC version mismatch error

```
wine: could not load ntdll.so: /lib/x86_64-linux-gnu/libc.so.6: version `GLIBC_2.38' not found
```

This has mainly been reported by users of the [experimental script installer](/Guides/Wine/Script%20Installer), not this manual guide, since it bundles its own Wine build against a newer GLIBC than some distros ship. If you hit this while following the manual steps above, your distro's Wine package is likely too new (or too old) for your system GLIBC. Update your distro or fall back to your distro's own `winehq-*` package instead of any bundled build. See [Roadmap.md's Known Issues](/Roadmap.md#-known-issues) for more detail.

### Missing .NET 3.5 with native Wine 11.7

If you are on a distro-packaged (native) Wine 11.7 install and Affinity or the installer complains about missing .NET 3.5, this is a known issue ([#130](https://github.com/seapear/AffinityOnLinux/issues/130)) without a confirmed fix yet. If you hit it, try installing the `dotnet35` winetricks component in addition to `dotnet48` from Step 3, and report back on the issue thread with your results.

### Window is cut off / doesn't fill the screen when maximized (KDE Plasma Wayland)

Root cause confirmed on a KDE Plasma 6.7.4 Wayland session: this is [KDE bug 459373](https://bugs.kde.org/show_bug.cgi?id=459373), "Maximized XWayland windows leave pixel gaps when using certain fractional scaling factors." Wine's window runs as an XWayland client, and KWin's maximize sizing breaks specifically at fractional display scales (125%, 135%, 145%, 150%, 175%) that don't divide evenly into your monitor's native resolution. It does not happen at integer scales (100%, 200%, 300%).

Workaround: switch to a scale factor that divides your native resolution evenly. For example, on a 2560x1600 panel, 150% leaves a large crop (2560 / 1.5 = 1706.67, not a whole number) while 160% does not (2560 / 1.6 = 1600 exactly). Change this in System Settings → Display & Monitor, or from a terminal: `kscreen-doctor output.<name>.scale.<factor>` (find `<name>` via `kscreen-doctor -o`). This was fixed upstream in Plasma 6.2.0 for the general case, but a smaller residual edge sliver can still appear on some maximizes even at a "good" scale factor; it is far less severe than the crop at a bad fractional scale. This same KWin/XWayland/fractional-scaling interaction is very likely the underlying cause of [#129](https://github.com/seapear/AffinityOnLinux/issues/129) (title bar not showing when maximized) and [#126](https://github.com/seapear/AffinityOnLinux/issues/126) (cursor offset on GNOME with display scaling) on other desktop environments.

Do not switch Wine to its native Wayland driver (`wine reg add "HKEY_CURRENT_USER\Software\Wine\Drivers" /v Graphics /d wayland /f`) to try to work around this: as of Wine 11.15, `winewayland.drv` does not correctly manage Affinity's floating dockable panel windows (they detach from the main window with no borders, and the canvas area breaks). Stick with the default X11/XWayland driver.

There is a second, separate bug layered on top of the scaling one: even with the scale fixed, clicking Affinity's own **Maximize** button (its title bar draws its own custom chrome, not KDE's) can still compute an undersized target window, confirmed by measuring the actual X11 window geometry (`xwininfo`) before and after. Clicking Maximize is not reliable, including after a full logout/login (ruling out stale compositor state as the cause). Instead, manually drag the window's border out to the screen edges once (`xwininfo` confirms this reaches the true full physical resolution minus the taskbar strip); afterward, using the restore/un-maximize toggle keeps that correct size, so you only need to do the manual drag once per session. A real fix (rather than this workaround) would need either a Wine-side patch to whatever work-area API Affinity's custom maximize logic queries, or a Harmony runtime patch via an AffinityPluginLoader/WineFix-style plugin; not attempted yet.

### Settings dialog (or other dialogs) open blank/white

If **Edit → Settings** (or another dialog) opens with a blank white content area, this is a Wine dialog repaint bug: the dialog's initial paint never fires. Scroll the mouse wheel over the blank area, or resize the dialog slightly, to force a redraw and the content will appear correctly.

### Canva sign-in crashes Affinity, or never completes after clicking "Open Affinity" in the browser

**Fixed.** Root cause fully traced via a decompiled managed stack trace: `Serif.Affinity.Application.ProcessCommandLineArguments` has a branch, only reached for an unrelated `affinity-open-file:` argument, that calls the WinRT type `Windows.ApplicationModel.DataTransfer.SharedStorageAccessManager`. Wine has no implementation of that type, and the .NET CLR resolves every type referenced anywhere in a method's body when it JITs that method (not just the branch actually taken), so *any* call into `ProcessCommandLineArguments` throws `System.TypeLoadException` and crashes the app, including the unrelated `affinity://` OAuth callback path, which is handled by the exact same method (forwarded from the second `Affinity.exe` instance the browser launches, over a named pipe, to the already-running instance).

Fixed by [LoginFix](/Guides/Wine/LoginFix), a community AffinityPluginLoader plugin. It doesn't patch the poisoned method directly (Harmony can't: patching requires decompiling the method's IL, which means resolving the same unresolvable type, even for a plain skip-prefix); instead it patches that method's two callers, which only reference it by signature, and replaces both with a safe reimplementation of the same behavior. No custom Wine build needed, confirmed working on stock distro Wine 11.15. See its README for full details and build/install steps.

Separately (and unrelated to sign-in): if Affinity's main window fails to create its Direct3D device at startup at all (`Log.txt` shows `Attempting to create Direct3D device on default adapter` followed by `DisplayConfigGetDeviceInfo error: 87` and `DXRenderer.cpp(1014): error 0x80004001`), that's Wine's `NtUserDisplayConfigGetDeviceInfo` not implementing the SDR white level query. See [wine-11.15-sdr-white-level.patch](/Guides/Wine/wine-11.15-sdr-white-level.patch) for a small, tested Wine source patch (requires building Wine yourself; a candidate for upstreaming to WineHQ).

### Manual Winetricks Install

If the Fedora/Nobara package manager fails or tries to remove Wine:

```bash
cd ~
curl -L -o winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
chmod +x winetricks
```

Use your local copy instead of the system command:
```bash
WINEPREFIX="$HOME/.affinity" ~/winetricks remove_mono
WINEPREFIX="$HOME/.affinity" ~/winetricks --force dotnet48
```

Optional: install it globally:
```bash
sudo mv ~/winetricks /usr/local/bin/winetricks
```

---

## 🪄 Optional Enhancements After Installation

### Install Affinity Plugin Loader + WineFix  

> **Author:** [Noah C3](https://github.com/noahc3)  
> **Project:** [AffinityPluginLoader + WineFix](https://github.com/noahc3/AffinityPluginLoader/)  
> *This patch is community‑made and **not official**, but it greatly improves runtime stability and fixes the “Preferences not saving” issue on Linux.*

### Purpose

- Provides plugin loading and dynamic patch injection via **Harmony**  
- Restores **on‑the‑fly settings saving** under Wine  
- With [LoginFix](/Guides/Wine/LoginFix) added alongside it (see below), fixes Canva sign‑in crashing under Wine

### Quick Install (Recommended Method)

Replace paths dynamically as these commands adapt automatically to your prefix and Affinity directory:

```bash
# Define Wine prefix
export WINEPREFIX="$HOME/.affinity"
cd "$WINEPREFIX/drive_c/Program Files/Affinity/Affinity/"

# 1.) Download & extract AffinityPluginLoader + WineFix bundle
curl -L -o /tmp/affinitypluginloader-plus-winefix.tar.xz \
  https://github.com/noahc3/AffinityPluginLoader/releases/latest/download/affinitypluginloader-plus-winefix.tar.xz

tar -xf /tmp/affinitypluginloader-plus-winefix.tar.xz -C .

# 2.) Replace launcher for compatibility
mv "Affinity.exe" "Affinity.real.exe"
mv "AffinityHook.exe" "Affinity.exe"
```

Now your existing launchers still work. `wine .../Affinity.exe` automatically loads AffinityPluginLoader & WineFix.

### Also Install LoginFix (Fixes Canva Sign-In)

Build and drop in [LoginFix](/Guides/Wine/LoginFix) the same way, into the same `apl/plugins/` folder as `WineFix.dll`:

```bash
cp "$WINEPREFIX/drive_c/Program Files/Affinity/Affinity/AffinityPluginLoader.dll" \
  path/to/AffinityOnLinux/Guides/Wine/LoginFix/
cd path/to/AffinityOnLinux/Guides/Wine/LoginFix
dotnet build -c Release
cp bin/Release/net48/win-x64/LoginFix.dll \
  "$WINEPREFIX/drive_c/Program Files/Affinity/Affinity/apl/plugins/"
```

Requires the [.NET SDK](https://dotnet.microsoft.com) installed on your Linux system (not inside the Wine prefix). See its README for the full explanation of what it fixes.

### Verify Installation of AffinityPluginLoader

Run Affinity as before:
```bash
WINEPREFIX="$HOME/.affinity" wine "$WINEPREFIX/drive_c/Program Files/Affinity/Affinity/Affinity.exe"
```
- You should now see **Affinity Plugin Loader** output in your terminal log on startup.  
- Preferences and settings should now save correctly on Linux.

> [!NOTE]
> - Updates to Affinity may overwrite `Affinity.exe`.  
>   - If that happens, re‑extract the `affinitypluginloader-plus-winefix.tar.xz` bundle.
> - Sign-in used to be unreliable under Wine; installing [LoginFix](/Guides/Wine/LoginFix) alongside WineFix fixes the underlying crash, confirmed working on stock Wine 11.15.
> - Always download from [Noah C3’s official GitHub releases](https://github.com/noahc3/AffinityPluginLoader/releases).

### Add Icon to Dock or Panel

- **GNOME / Fedora / Pop OS / Ubuntu default:** open Activities → search *Affinity* → right‑click → **Add to Favorites**.
- **KDE Plasma / Manjaro / Arch:** right‑click the menu entry → **Add to Panel / Pin to Task Manager**.
- **XFCE / others:** panel right‑click → **Add New Item → Launcher → Affinity**.

After doing this, **Affinity** will appear alongside your native apps with its custom blue squircle SVG icon.

If you also install Photo 2, Designer 2, and Publisher 2, you can duplicate and rename the `.desktop` file and just change the `Name`, `Exec`, and `Icon` fields accordingly.

---

## 🗑️ Uninstall Affinity and Wine

See [our guide for uninstalling Affinity and Wine](/Guides/Wine/Guide-Uninstall.md).

---

## ✅ Verified Environments

- **Wine 10.17 (mainline / devel)**
- ✅ **Affinity 3.x (64‑bit)**
- ✅ **Affinity 2.x (64‑bit)**
- ✅ Fedora 42
    - ✅ Nobara 42
- ✅ Arch 2025.03
    - ✅ [Linux 6.17.7-arch1-1](https://discord.com/channels/1281706644073611358/1281706644715208809/1435848291681304687)
- ✅ Ubuntu
    - ✅ [25.04 x86_64](https://discord.com/channels/1281706644073611358/1281706644715208809/1436016587533586623)
--- 

## 🧾 Credits

- **ElementalWarrior** – creator of [wine‑wintypes.dll‑for‑affinity](https://github.com/ElementalWarrior/wine-wintypes.dll-for-affinity)  
- **WineHQ Team** – added WinRT metadata support (MR [#8367](https://gitlab.winehq.org/wine/wine/-/merge_requests/8367))
- **Microsoft** – provider of [Windows.winmd](https://github.com/microsoft/windows-rs) metadata  
- **Guide revision & testing**
    - [Wanesty](https://codeberg.org/wanesty) for finding this [update](https://discord.com/channels/1281706644073611358/1281706644715208809/1434097819547074652)
    – [GameDirection/InterfaceAS](https://join.gamedirection.net) for testing & sumbitting the [guide](https://discord.com/channels/1281706644073611358/1281706644715208809/1435846007295316171)
    - And of course the [AffinityOnLinux](https://join.affinityonlinux.com) community
- **Noah C3** – Creator of [AffinityPluginLoader](https://github.com/noahc3/AffinityPluginLoader) and WineFix  
- **Harmony** library by [Pardeike](https://github.com/pardeike/Harmony)  

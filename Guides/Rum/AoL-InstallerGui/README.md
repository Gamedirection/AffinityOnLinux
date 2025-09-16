# 🎨 Affinity on Linux – GUI Installer Flow (AoL‑InstallerGui) 
## 🖼️ 1. Launch / Welcome 

- **Logo**: `Assets/NewLogos/AffinityOnLinux.png`
- Title: **Affinity on Linux Installer**
- Subtitle: *"Easily install Affinity Photo, Designer, and Publisher on Linux using Wine + Rum."*
- Buttons:
	- ▶ Start Installation
	- ❌ Exit

## 🧰 2. Dependency Check 

- GUI auto‑checks for required tools:
- `wget`, `unzip`, `git`, `winetricks`
- Show status (✓ installed / ✗ missing).
- If missing:
	- Offer auto‑install using pkexec/sudo.
	- Or show copy‑paste commands for Debian/Ubuntu, Arch, Fedora.
         

## 🍷 3. Wine + Rum Setup 

- Automated behind the scenes:
	- Creates dirs: `~/.local/share/wine/{runners,prefixes}`
	- Downloads ElementalWarrior’s Wine fork.
	- Installs Rum in `/opt/rum`, symlink to `/usr/local/bin/rum`.
	- Configures runners path.
- Progress bar + expandable “Details/Logs” panel.
     

## 📦 4. Select Affinity Apps 

- GUI scans `~/Downloads/` for:
	- `affinity-photo-*.exe`
	- `affinity-designer-*.exe`
	- `affinity-publisher-*.exe`
 - Show icons + checkboxes:
 - [ ] Photo (`Assets/Icons/Photo.svg`)
 - [ ] Designer (`Assets/Icons/Designer.svg`)
 - [ ] Publisher (`Assets/Icons/Publisher.svg`)
 - If not found:
	- Button: Select Installer Manually…
	- Button: Get from Serif → opens:
		- https://store.serif.com/en-us/account/downloads/
		- https://affinity.serif.com/en-us/affinity-pricing/ 
             
         
     

## ⚙️ 5. Configure Wine Prefix 

For each chosen app: 
- Create ~/.local/share/wine/prefixes/affinity
- Run wineboot --init
- Apply dependencies via winetricks automatically:  
`remove_mono vcrun2022 dotnet48 renderer=vulkan corefonts win11`
- Download + extract WinMetadata files.
- Show steps as ✅ checkmarks in GUI.
     

## 💿 6. Run Affinity Installers 

- For each .exe:
	- Launch installer inside Wine.
	- Affinity’s native Windows installer window appears.
         
- After finish:
	- GUI continues automatically.
         
     

## 🖥️ 7. Desktop Integration 
- Auto‑creates .desktop files in ~/.local/share/applications/
- Applies appropriate SVG icons.
- Updates menu/icon caches:
	- `update-desktop-database`
	- `gtk-update-icon-cache`
	- `kbuildsycoca5` (if KDE)
         
### Options (checkboxes):
- 📌 Add to desktop
- 📌 Pin to dock/taskbar
- 🎨 Apply dark theme (Auxillary/Other/wine-dark-theme.reg)
- 🔎 Enable Hi‑DPI scaling tweak (winecfg preset)
         
     

## ✅ 8. Success / Final Screen 

- Visual confirmation with installed app icons.
- Message: “Affinity apps are ready! You’ll find them in your Applications menu.”
	- Buttons:
		- ▶ Launch Photo (if installed)
		- ▶ Launch Designer (if installed)
		- ▶ Launch Publisher (if installed)
		- 📂 Open Installation Folder
		- 📖 View Documentation
		- ❌ Exit

## 🔧 9. (Optional) Advanced Tab 

- **Reset Wine Prefix** (⚠ deletes Affinity settings).
- **Reapply HiDPI scaling**.
- **Manually update runner** (future upgrades).
     
## 🏗️ Technical Notes 

- Language / Toolkit:

	- Recommend **Python + PyQt6** / **PySide6**, packaged as an AppImage → single portable executable.
	- Alternative: Gtk/PyGObject (better GNOME integration) or lightweight Yad/Zenity (simplest but less polished).
     

- **Structure Inside Repo:**

```
    Guides/Rum/AoL-InstallerGui/
    ├── AoL-InstallerGui (executable/AppImage)
    ├── resources/ (icons, assets)
    ├── scripts/ (setup helpers)
    └── README.md
``` 

- Installer detection: Scans ~/Downloads/ → fallback file picker.
- .desktop generator: Auto‑handles user’s $HOME, properly escapes Wine paths.
- Cross‑distro: Auto‑detects packaging system and DE for cache updates.
- Error handling: Each step logs errors; GUI allows retry at failed step.
     

## 📊 Flow Diagram 
```
Launch
 └─▶ Dependency Check
      └─▶ Wine+Rum Setup
            └─▶ Choose Apps (installers)
                  └─▶ Configure Prefix
                        └─▶ Install Affinity
                              └─▶ Create Shortcuts
                                    └─▶ Success Screen
```
 
 

✅ This flow keeps things plug‑and‑play for beginners (they just click "Next" until done), while offering optional tweaks (HiDPI, dark theme) for advanced users.
✅ It leverages your repo’s existing assets (icons, settings, scripts).
✅ It results in a single executable GUI installer usable on any Linux distro.

# How to Set Up Wine for Affinity on Bottles

<img src="/Assets/NewLogos/AffinityBottles.png" width="400"/>

Before doing anything, make sure you have a `.exe` version of Affinity apps. You can download Affinity apps from the official Affinity websites:

- [Affinity by Canva](https://www.affinity.studio/download) (select "Enterprise (Intel/AMD)" from the "Download for Windows" drop-down menu to download the EXE installer)
- [Affinity Photo V2](https://store.serif.com/update/windows/photo/2/) 
- [Affinity Designer V2](https://store.serif.com/update/windows/designer/2/)
- [Affinity Publisher V2](https://store.serif.com/update/windows/publisher/2/) 
- [Affinity Photo V1](https://store.serif.com/update/windows/photo/1/)
- [Affinity Designer V1](https://store.serif.com/update/windows/designer/1/)
- [Affinity Publisher V1](https://store.serif.com/update/windows/publisher/1/)

## 1. Install Bottles

Visit the [download page of Bottles' official website](https://usebottles.com/download/), and follow the instructions to download and install Bottles. [Flatpak](https://flathub.org/apps/com.usebottles.bottles) is recommended, as it is the only officially supported install method for Bottles.

Alternately, you may want to install Bottles using the [unofficial AppImage](https://github.com/ivan-hc/Bottles-appimage).

## 2. Download Wine 10.17 staging runner

1. Open Bottles and click on the hamburger/3 dots menu button
2. Go to Preferences
3. Got to Runners tab
4. Unfold the kron4ek section and download the last wine version (staging and tkg doesn't matter from my testing)

> **Note**: recent Bottles releases group runners by Wine build (Kron4ek, Caffe, Proton, ...) with a save icon next to each version. Click that icon on the newest `kron4ek-wine-<version>-amd64` entry (non-staging is fine) to download it.

## 3. Add Bottle in Bottles

Recent Bottles releases removed the install-script (`.yaml`) importer that older versions used, so the steps below use Bottles' own bottle-creation wizard instead. If your Bottles still has an "Import Configuration" option, the old `affinity-nu.yaml` install script still works the same way it always did.

1. Bottles has two top tabs, **Bottles** and **Library**. Use the **Bottles** tab, not Library, its "New" wizard is Proton/gaming-only and can't select a Kron4ek Wine runner.
2. Click the **+** icon.
3. Name it "Affinity" or "Serif".
4. Pick **Application** (productivity software) rather than the literal "Custom" option, it fits Affinity better and both work.
5. Keep Architecture -> `64bit`
6. Set the runner to **kron4ek-wine-<version>-amd64**
7. Click **Create**.

<img width="1108" height="884" alt="bottle_creation_window" src="https://github.com/user-attachments/assets/ffd4641b-66a9-4bc7-8718-ef64b937e0fc" />

### If bottle creation fails on a font dependency

Bottle creation may fail partway through with **"Unable to Create Bottle"**, stuck on a step like "Installing dependency: Microsoft Arial Font". This is a bug in current Bottles Flatpak builds: the font-installer step fails inside the Flatpak sandbox even though the underlying download URL is fine (confirmed by fetching the same URL from a normal terminal, checksum matched). The bottle is still created despite the error, just without fonts, see [No fonts / crash when opening a document](#no-fonts--crash-when-opening-a-document-white-screen-or-immediate-crash) below to finish setting it up. Retrying bottle creation from scratch does not reliably fix this, installing the fonts manually afterward does.

### 3.1 Install .NET Framework 4.8

Since there's no install script to automate this anymore, install .NET 4.8 by hand:

1. Open the bottle's **Details** page, scroll to **Options -> Dependencies**.
2. Find **dotnet48** (Microsoft .NET Framework 4.8) and check it.
3. Click **Install Selected**, and wait for it to finish (this can take several minutes).

If you skip this and run Affinity's installer first, you'll see **"Failed to start Setup. It looks like Microsoft .NET 3.5 has been turned off on this computer."** Don't click **OK** on that dialog (it tries to open a non-existent Windows Features app), click **Cancel**, install dotnet48 as above, then try the installer again.


## 4. Run the installer

1. On the bottle's **Details** page, click **Run Executable...** and pick the Affinity `.exe` you downloaded.
2. You may see a dialog saying "Setup is not recommended... A native installer exists for this CPU type." This is a false positive, click **Ignore**.
3. Follow the installer to completion.

## 5. Add Windows.winmd

1. Download the [`Windows.winmd` file](https://github.com/microsoft/windows-rs/raw/refs/heads/master/crates/libs/default/Windows.winmd).
2. Insert the `Windows.winmd` file you downloaded into `drive_c/windows/system32/winmetadata`.

The Affinity app should now work inside that Bottle.

## 6. Add wintypes.dll

1. Download [`wintypes.dll`](https://github.com/ElementalWarrior/wine-wintypes.dll-for-affinity/raw/refs/heads/master/wintypes_shim.dll.so).
2. Rename it from `wintypes_shim.dll.so` to `wintypes.dll`.
3. For each program installed, copy it into that program directory. For Affinity Canva that's `drive_c/Program Files/Affinity/Affinity/`.
4. Open the settings for your bottle and open Wine Configuration from Tools > Legacy Wine Tools > Configuration.
5. In the libraries tab, add an override for `wintypes` and edit it to load `Native (Windows)`

<img width="2880" height="1920" alt="Screenshot of the wine configuration menu. The Edit Override window is at the front with the Native (Windows) option selected. Also visible is the Wine configuration window in the libraries tab. The wintypes library is selected in the Existing overrides list. Behind the Wine configuration window is the Details menu for the Affinity bottle scrolled nearly to the bottom with the tools menu visible" src="https://github.com/user-attachments/assets/fb802a52-eab3-457d-938d-48f8dae48af9" />

## Troubleshooting

### No fonts / crash when opening a document (white screen or immediate crash)

A bottle created with the **Application** or **Custom** environment starts with **zero fonts installed**, since Bottles doesn't bundle any by default outside its own dependency installer. Affinity itself launches fine, but crashes the moment it tries to draw text, most visibly when it opens the New Document dialog on first run. The crash log (`AppData/Roaming/Affinity/Affinity/3.0/Log.txt`) just stops mid-startup with no error text; running `Affinity.exe` from the bottle's **Tools -> Command Line** shows the real cause, an unhandled .NET exception inside WPF's text layout code (`FetchLSRun`, `TextFormatterImp.FormatLine`, ...).

The fix is to install fonts. Bottles has a built-in **Dependencies -> allfonts** entry meant for exactly this, but as of writing it's broken on Flatpak builds, it fails partway through (for example stuck on "Installing dependency: Microsoft Arial Font" or "Microsoft Andale Font") even though the font mirrors it downloads from are reachable and correct (confirmed by downloading the same URL and checksum from a normal terminal). If `allfonts` fails for you too, install the core fonts by hand instead:

1. Find your bottle's folder, for Flatpak that's `~/.var/app/com.usebottles.bottles/data/bottles/bottles/<BottleName>/`.
2. Download and extract each of these with [`cabextract`](https://www.cabextract.org.uk/) (`sudo pacman -S cabextract`, `sudo apt install cabextract`, etc.), then copy every `.ttf`/`.TTF` file it produces into `<bottle>/drive_c/windows/Fonts/`:
   - `https://sourceforge.net/projects/corefonts/files/the%20fonts/final/arial32.exe`
   - `https://mirrors.kernel.org/gentoo/distfiles/5d/arialb32.exe`
   - `https://mirrors.kernel.org/gentoo/distfiles/7d/andale32.exe`
   - `https://mirrors.kernel.org/gentoo/distfiles/52/comic32.exe`
   - `https://mirrors.kernel.org/gentoo/distfiles/1b/courie32.exe`
   - `https://mirrors.kernel.org/gentoo/distfiles/f0/georgi32.exe`
   - `https://mirrors.kernel.org/gentoo/distfiles/10/impact32.exe`
   - `https://sourceforge.net/projects/corefonts/files/the%20fonts/final/times32.exe`
   - `https://sourceforge.net/projects/corefonts/files/the%20fonts/final/trebuc32.exe`
   - `https://sourceforge.net/projects/corefonts/files/the%20fonts/final/verdan32.exe`
   - `https://mirrors.kernel.org/gentoo/distfiles/95/webdin32.exe`

   For example: `curl -LO <url> && cabextract -d out <file>.exe && cp out/*.[tT][tT][fF] "<bottle>/drive_c/windows/Fonts/"`
3. Register each font so Windows/WPF actually picks it up, copying the file in alone isn't enough. From a terminal, for a Flatpak install:
   ```shell
   flatpak run --command=bash com.usebottles.bottles -c '
   export WINEPREFIX="/var/data/bottles/bottles/<BottleName>"
   export PATH="/var/data/bottles/runners/<your-runner>/bin:$PATH"
   KEY="HKLM\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
   wine reg add "$KEY" /v "Arial (TrueType)" /d "Arial.TTF" /f
   # repeat for each font file you copied in, matching name -> filename
   '
   ```
   (`/var/data/...` is how paths under `~/.var/app/com.usebottles.bottles/data/...` appear from inside the Flatpak sandbox.)
4. Relaunch Affinity. The New Document dialog and general text rendering should now work.

This is a Bottles bug, not an Affinity or wintypes/winmd issue, it will most likely get fixed upstream. Check whether **Dependencies -> allfonts** works again in newer Bottles releases before doing this by hand.

### Bottle creation fails, "Unable to Create Bottle... Installing dependency: Microsoft Arial Font"

Same underlying bug as above, the automatic font install that Bottles runs as part of creating a new **Application**-profile bottle fails inside the Flatpak sandbox. The bottle is still created (just without fonts), continue with the rest of this guide and use the manual font fix above once you get to a document-opening crash.

## Additional Tips and Tricks

### Common Location

The Affinity apps installed with Bottles are located at the following location:

- **Flatpak**: `~/.var/app/com.usebottles.bottles/data/bottles/bottles/Affinity/drive_c`

### How to Fix Studdering

- Bottles -> Settings -> # Performance | Toggle on Feral GameMode
- Bottles -> Settings -> # Compatibility | Windows 10 -> Windows 11 [*](https://discord.com/channels/1281706644073611358/1289640098589315174/1418124555406544956)
### Dark Theme for Wine

1. Visit the [wine-dark-theme registry file](/Auxiliary/Other/wine-dark-theme.reg) from this repository, and download the file by clicking the download button on the top right.
2. In the folder where you downloaded the registry file into, run the following command:
   ```shell
   wine regedit wine-dark-theme.reg
   ```
3. If you also want to enable dark theme for the Wine fork for your installed Affinity apps on Bottles, run the command:
    ```shell
   WINEPREFIX="$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles/Affinity" wine regedit wine-dark-theme.reg
   ```

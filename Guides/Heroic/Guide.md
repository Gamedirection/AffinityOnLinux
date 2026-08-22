# How to Set Up Wine for Affinity on Heroic Games Launcher

<img src="/Assets/NewLogos/AffinityHGL.png" width="400"/>

Before doing anything, make sure you have a `.exe` version of Affinity apps. You can download Affinity apps from the official Affinity websites:

- [Affinity by Canva](https://www.affinity.studio/download) (select "Enterprise (Intel/AMD)" from the "Download for Windows" drop-down menu to download the EXE installer)
- [Affinity Photo V2](https://store.serif.com/update/windows/photo/2/) 
- [Affinity Designer V2](https://store.serif.com/update/windows/designer/2/)
- [Affinity Publisher V2](https://store.serif.com/update/windows/publisher/2/) 
- [Affinity Photo V1](https://store.serif.com/update/windows/photo/1/)
- [Affinity Designer V1](https://store.serif.com/update/windows/designer/1/)
- [Affinity Publisher V1](https://store.serif.com/update/windows/publisher/1/)

## 1. Install Heroic Games Launcher

Visit the [download page of Heroic Games Launcher's official website](https://heroicgameslauncher.com/downloads), and follow the instructions to download and install Heroic Games Launcher. [Flatpak](https://flathub.org/en/apps/com.heroicgameslauncher.hgl) is recommended.

## 2. Download and Extract a Wine Fork

Choose one of the following forks of Wine, and download and extract it: 

- [ElementalWarrior-x86_64](https://github.com/seapear/AffinityOnLinux/releases/download/Legacy/ElementalWarriorWine-x86_64.tar.gz) (Recommended) — After downloading the `ElementalWarriorWine-x86_64.tar.gz` archive file, right click and extract the archive into an `ElementalWarriorWine-x86_64` folder.

- [**Wine-TKG-affinity**](https://github.com/daegalus/wine-tkg-affinity/releases) — Download the ` wine-tkg-affinity-archbuilt.tar.zst` archive file, then extract to the `usr/` folder from the archive and rename the folder to `wine-tkg-affinity-x86_64`.

## 3. Copy and Paste Wine Fork Binaries to Heroic Games Launcher

Heroic Games Launcher's Wine-related folders can be found in a hidden directory within your `home` folder. If you can't see hidden folders in your file browser, you can usually enable them by pressing `Ctrl + H`.

- If you installed Heroic Games Launcher via **Flatpak**, navigate to `/home/$USER/.var/app/com.heroicgameslauncher.hgl/config/heroic/tools/wine/`
- If you installed Heroic Games Launcher via other methods, navigate to `/home/$USER/.config/heroic/tools/wine/`

Copy and paste the Wine fork folder you extracted in the previous step to this folder.

## 4. Add Game in Heroic Games Launcher

1. Open Heroic Games Launcher and click on **Add Game**.
2. Name the game as you wish.
3. Set the Wine version to **ElementalWarriorWine** or **Wine-TKG-Affinity**.
4. Select the x64 setup `.exe` you downloaded from Affinity's website as the executable.
5. Click **Finish**.
6. Right-click the game -> **Settings**, and uncheck **Auto Install/Update DXVK**, **DXVK-NVAPI**, and **VKD3D on Prefix**. Affinity doesn't need them, and leaving them on causes screen flashing/flicker later, see [Known Issues](#screen-flashing--flickering-while-editing).

## 5. Initialize the Wine Prefix

1. Run the setup file from Heroic to initialize the prefix.
   - It may crash, or it may complete the Affinity installer successfully right away, either is fine at this stage.
   - Default location is: `/home/$USER/Games/Heroic/Prefixes/default/Affinity`.
2. Once installed, edit the game in Heroic and update **Select Executable** to the real installed path, `drive_c/Program Files/Affinity/<AppName>/<AppName> x64.exe`. Launching before the next steps will crash, that's expected, dependencies aren't installed yet.

## 6. Configure Dependencies with Winetricks

1. Right-click on the game in Heroic and select **Settings** from the menu.
2. On the **WINE** tab, scroll down and click on **Winetricks**.
3. Search and install the following dependencies (Heroic's inline search installs one at a time, `corefonts` + `tahoma` together cover what `allfonts` needs for Affinity):
    - `corefonts`
    - `tahoma`
    - `dotnet48`
    - `vcrun2022`
4. Wait for the dependencies to install. Be patient, it's not stuck, just taking time.
5. You may see **"Your version of wine ... is no longer supported upstream. You should upgrade to 8.x"**. This is winetricks misreading ElementalWarriorWine's version string, harmless, click **OK** and continue.

## 7. Adjust Wine Settings

1. Click on **OPEN WINETRICKS GUI**.
2. Select **Select the default wineprefix**.
3. Choose **Change settings**.
4. Enable the following settings:
    - **win11**
    - **renderer=vulkan**
5. Click **OK** and keep pressing **Cancel** until the Winetricks window closes.

## 8. Install WinMetadata

1. Download the [`WinMetadata.zip` archive file](https://archive.org/download/win-metadata/WinMetadata.zip).
2. Extract the `WinMetadata` folder from the archive into `drive_c/windows/system32`.

## 9. Complete the Setup

1. Press **Launch** and complete the setup.
2. Once installation is finished:
    - Right-click on the game in Heroic and select **Details** from the menu.
    - Click on the three dots at the top-right corner and select **Edit App/Game**.
    - Change the executable to:  
      `drive_c/Program Files/Affinity/APPNAMEHERE/APPNAMEHERE.exe`
    - Click **Finish** and **Launch** the game.

## Known Issues

### Screen flashing / flickering while editing

Caused by Heroic auto-installing DXVK, DXVK-NVAPI, and VKD3D into the prefix by default, stacking a second Direct3D-on-Vulkan translation layer on top of the `renderer=vulkan` winetricks setting from Step 7, Affinity doesn't need either DXVK or VKD3D and the two fighting over the same swapchain is what causes the flashing.

**Fix**: right-click the game -> **Settings**, and uncheck all three:
- **Auto Install/Update DXVK on Prefix**
- **Auto Install/Update DXVK-NVAPI on Prefix**
- **Auto Install/Update VKD3D on Prefix**

Relaunch Affinity, the flashing is gone. Confirmed fix, not just a workaround.

## Additional TIps and Tricks

### Performance Settings

To optimize performance and reduce latency, right click on a game, select **Settings** from the menu, then adjust these settings:

- Go to the **Other** tab, and check the **Game Mode** option.

Quote from **darkside99**:  
*"These are the best settings for improving performance and reducing latency."*

![Performance.png](./Images/Performance.png)

### Dark Theme for Wine

1. Visit the [repository's `wine-dark-theme.reg` file page](/Auxiliary/Other/wine-dark-theme.reg) to download the `.reg` file by clicking the download button on the top right.
2. Save the file to your Downloads folder.
3. Launch a terminal app to open the terminal, then type `cd Downloads` to change to your Downloads folder.
4. Run the following command:
    ```shell
    wine regedit wine-dark-theme.reg
    ```
5. Press `Enter`. You might get a message again saying "Wine could not find a wine-mono package...". Just click `Install`.

If you also want to enable dark theme for the Wine fork for your installed Affinity apps on Heroic Games Launcher:

1. Launch Heroic Games Launcher.
2. Click an Affinity app you installed. Under the **INSTALL INFO** section, check the **WinePrefix folder** path.
3. Run the following command, and replace `/path/to/wineprefix` with the WinePrefix folder path:
    ```shell
   WINEPREFIX="/path/to/wineprefix/folder" wine regedit wine-dark-theme.reg
   ```

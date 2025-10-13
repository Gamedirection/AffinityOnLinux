#!/bin/bash

# Check if script is executable, if not make it executable
if [ ! -x "$(readlink -f "$0")" ]; then
    echo "Making script executable..."
    chmod +x "$(readlink -f "$0")"
fi

# Ensure script is being run with bash
if [ -z "$BASH_VERSION" ]; then
    echo "This script must be run with bash"
    exit 1
fi

# ==========================================
# Constants and Configuration
# ==========================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ==========================================
# Utility Functions
# ==========================================

# Function to download files with progress bar
download_file() {
    local url=$1
    local output=$2
    local description=$3
    
    echo -e "${YELLOW}Downloading $description...${NC}"
    
    # Try curl first with progress bar
    if command -v curl &> /dev/null; then
        curl -# -L "$url" -o "$output"
        if [ $? -eq 0 ]; then
            return 0
        fi
    fi
    
    # Fallback to wget if curl fails or isn't available
    if command -v wget &> /dev/null; then
        wget --progress=bar:force:noscroll "$url" -O "$output"
        if [ $? -eq 0 ]; then
            return 0
        fi
    fi
    
    echo -e "${RED}Failed to download $description${NC}"
    return 1
}

# ==========================================
# System Detection and Setup Functions
# ==========================================

# Function to detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    else
        echo -e "${RED}Could not detect Linux distribution${NC}"
        exit 1
    fi
}

# Function to check dependencies
check_dependencies() {
    local missing_deps=""
    
    for dep in wine winetricks wget curl 7z tar jq; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+="$dep "
        fi
    done
    
    if [ -n "$missing_deps" ]; then
        echo -e "${YELLOW}Missing dependencies: $missing_deps${NC}"
        install_dependencies
    else
        echo -e "${GREEN}All dependencies are installed!${NC}"
    fi
}

# Function to install dependencies based on distribution
install_dependencies() {
    echo -e "${YELLOW}Installing dependencies for $DISTRO...${NC}"
    
    case $DISTRO in
        "ubuntu"|"linuxmint"|"pop"|"pikaos")
            echo -e "${YELLOW}Enabling 32-bit architecture and installing wine32...${NC}"
            sudo dpkg --add-architecture i386
            sudo apt update
            sudo apt install -y wine32:i386 wine winetricks wget curl p7zip-full tar jq
            ;;
        "arch"|"cachyos")
            sudo pacman -S --needed wine winetricks wget curl p7zip tar jq
            ;;
        "fedora"|"nobara")
            sudo dnf install -y wine winetricks wget curl p7zip p7zip-plugins tar jq
            ;;
        "opensuse-tumbleweed"|"opensuse-leap")
            sudo zypper install -y wine winetricks wget curl p7zip tar jq
            ;;
        *)
            echo -e "${RED}Unsupported distribution: $DISTRO${NC}"
            echo "Please install the following packages manually:"
            echo "wine winetricks wget curl p7zip tar jq"
            exit 1
            ;;
    esac
}

# ==========================================
# Wine Setup Functions
# ==========================================

# Function to kill stuck Wine processes (especially OLE/COM error loops)
kill_stuck_wine_processes() {
    echo -e "${YELLOW}Checking for stuck Wine processes...${NC}"
    
    # Kill any wine processes that might be stuck in error loops
    pkill -9 -f "wine.*\.exe" 2>/dev/null || true
    pkill -9 wineserver 2>/dev/null || true
    pkill -9 winedevice 2>/dev/null || true
    pkill -9 plugplay 2>/dev/null || true
    pkill -9 explorer 2>/dev/null || true
    
    # Use wineserver to properly terminate all Wine processes
    wineserver -k 2>/dev/null || true
    sleep 2
    wineserver -k9 2>/dev/null || true
    
    echo -e "${GREEN}Wine processes cleaned up${NC}"
}

# Function to disable Wine Mono (prevents conflicts with .NET)
disable_mono() {
    local directory="$HOME/.AffinityLinux"
    echo -e "${YELLOW}Disabling Wine Mono...${NC}"
    
    export WINEDLLOVERRIDES="mscoree,mscorwks=d"
    
    # Create registry file to disable Mono
    cat > /tmp/disable_mono.reg << 'EOF'
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Wine\DllOverrides]
"mscoree"=""
"mscorwks"=""
EOF
    
    WINEPREFIX="$directory" "$directory/ElementalWarriorWine/bin/regedit" /tmp/disable_mono.reg 2>/dev/null || true
    rm -f /tmp/disable_mono.reg
}

# Function to disable ngen.exe compilation (speeds up .NET installation)
disable_ngen() {
    local directory="$HOME/.AffinityLinux"
    echo -e "${YELLOW}Disabling .NET ngen compilation...${NC}"
    
    # Create a dummy ngen.exe that does nothing
    for ngen_path in \
        "$directory/drive_c/windows/Microsoft.NET/Framework/v2.0.50727/ngen.exe" \
        "$directory/drive_c/windows/Microsoft.NET/Framework/v4.0.30319/ngen.exe" \
        "$directory/drive_c/windows/Microsoft.NET/Framework64/v2.0.50727/ngen.exe" \
        "$directory/drive_c/windows/Microsoft.NET/Framework64/v4.0.30319/ngen.exe"; do
        
        if [ -f "$ngen_path" ]; then
            mv "$ngen_path" "${ngen_path}.bak" 2>/dev/null || true
        fi
        
        # Create minimal dummy exe (just exits immediately)
        mkdir -p "$(dirname "$ngen_path")"
        echo -e "#!/bin/bash\nexit 0" > "${ngen_path}.sh"
        chmod +x "${ngen_path}.sh"
    done
}

# Function to verify Windows version
verify_windows_version() {
    local directory="$HOME/.AffinityLinux"
    # Set Windows version to 10 (more stable for Affinity apps)
    echo -e "${YELLOW}Setting Windows version to 10...${NC}"
    WINEPREFIX="$directory" "$directory/ElementalWarriorWine/bin/winecfg" -v win10 2>&1 | head -5
    echo -e "${GREEN}Windows version set to 10${NC}"
    return 0
}

# Function to verify .NET installation
verify_dotnet() {
    local directory="$HOME/.AffinityLinux"
    local version=$1
    
    echo -e "${YELLOW}Verifying .NET $version installation...${NC}"
    
    if [ "$version" == "3.5" ]; then
        if [ -d "$directory/drive_c/windows/Microsoft.NET/Framework/v3.5" ] || \
           [ -d "$directory/drive_c/windows/Microsoft.NET/Framework/v2.0.50727" ]; then
            echo -e "${GREEN}✓ .NET 3.5 appears to be installed${NC}"
            return 0
        else
            echo -e "${RED}✗ .NET 3.5 installation may have failed${NC}"
            return 1
        fi
    elif [ "$version" == "4.8" ]; then
        if [ -d "$directory/drive_c/windows/Microsoft.NET/Framework/v4.0.30319" ]; then
            echo -e "${GREEN}✓ .NET 4.8 appears to be installed${NC}"
            return 0
        else
            echo -e "${RED}✗ .NET 4.8 installation may have failed${NC}"
            return 1
        fi
    fi
}

# Function to download and setup Wine
setup_wine() {
    local directory="$HOME/.AffinityLinux"
    local wine_url="https://github.com/ryzendew/ElementalWarrior-Wine-binaries/releases/download/Release/ElementalWarriorWine-x86_64.zip"
    local filename="ElementalWarriorWine-x86_64.zip"
    
    # Kill any running wine processes (including stuck ones)
    kill_stuck_wine_processes
    
    # Create install directory
    mkdir -p "$directory"
    
    # Download the specific Wine version
    download_file "$wine_url" "$directory/$filename" "Wine binaries"
    
    # Extract wine binary
    echo -e "${YELLOW}Extracting Wine binaries...${NC}"
    unzip -o "$directory/$filename" -d "$directory"
    rm "$directory/$filename"
    
    # Find the actual Wine directory and create a symlink if needed
    wine_dir=$(find "$directory" -name "ElementalWarriorWine*" -type d | head -1)
    if [ -n "$wine_dir" ] && [ "$wine_dir" != "$directory/ElementalWarriorWine" ]; then
        echo -e "${YELLOW}Creating Wine directory symlink...${NC}"
        ln -sf "$wine_dir" "$directory/ElementalWarriorWine"
    fi
    
    # Verify Wine binary exists
    if [ ! -f "$directory/ElementalWarriorWine/bin/wine" ]; then
        echo -e "${RED}Wine binary not found. Checking directory structure...${NC}"
        echo "Contents of $directory:"
        ls -la "$directory"
        if [ -n "$wine_dir" ]; then
            echo "Contents of $wine_dir:"
            ls -la "$wine_dir"
        fi
        exit 1
    fi
    
    # Initialize Wine prefix (let ElementalWarriorWine use its native 64-bit WoW64 mode)
    echo -e "${YELLOW}Initializing Wine prefix (WoW64 mode)...${NC}"
    WINEPREFIX="$directory" "$directory/ElementalWarriorWine/bin/wineboot" -u 2>&1 | grep -v "fixme:" | head -20
    WINEPREFIX="$directory" wineserver -w
    echo -e "${GREEN}Wine prefix initialized${NC}"
    
    # Create icons directory if it doesn't exist
    mkdir -p "$HOME/.local/share/icons"
    
    # Download and setup additional files
    download_file "https://upload.wikimedia.org/wikipedia/commons/f/f5/Affinity_Photo_V2_icon.svg" "$HOME/.local/share/icons/AffinityPhoto.svg" "Affinity Photo icon"
    download_file "https://upload.wikimedia.org/wikipedia/commons/8/8a/Affinity_Designer_V2_icon.svg" "$HOME/.local/share/icons/AffinityDesigner.svg" "Affinity Designer icon"
    download_file "https://upload.wikimedia.org/wikipedia/commons/9/9c/Affinity_Publisher_V2_icon.svg" "$HOME/.local/share/icons/AffinityPublisher.svg" "Affinity Publisher icon"
    
    # Download WinMetadata
    download_file "https://archive.org/download/win-metadata/WinMetadata.zip" "$directory/Winmetadata.zip" "Windows metadata"
    
    # Extract WinMetadata
    echo -e "${YELLOW}Extracting Windows metadata...${NC}"
    7z x "$directory/Winmetadata.zip" -o"$directory/drive_c/windows/system32"
    rm "$directory/Winmetadata.zip"
    
    # Setup Wine
    echo -e "${YELLOW}Setting up Wine environment...${NC}"
    
    # Set Windows version to 10 first (required for .NET 4.8)
    echo -e "${YELLOW}Setting Windows version to 10...${NC}"
    WINEPREFIX="$directory" "$directory/ElementalWarriorWine/bin/winecfg" -v win10 2>&1 | head -5
    
    # Disable Mono before installing .NET
    disable_mono
    
    # Install .NET and other components
    echo -e "${YELLOW}Installing .NET 3.5 SP1 (this may take 10-15 minutes)...${NC}"
    echo -e "${YELLOW}The terminal will appear frozen - this is normal. Please wait...${NC}"
    WINEPREFIX="$directory" WINEDEBUG="-all,+err" WINEDLLOVERRIDES="mscoree,mscorwks=d" \
        winetricks --unattended --force dotnet35sp1 2>&1 | grep -E "(Executing|Installing|warning|error|Note)" | head -50 || true
    
    echo -e "${YELLOW}Waiting for Wine processes to complete...${NC}"
    WINEPREFIX="$directory" wineserver -w
    sleep 5
    
    # Kill any stuck processes after dotnet35
    kill_stuck_wine_processes
    
    # Verify .NET 3.5 installation
    verify_dotnet "3.5"
    
    # Disable ngen to speed up dotnet48 installation
    disable_ngen
    
    echo -e "${YELLOW}Installing .NET 4.8 (this may take 10-15 minutes)...${NC}"
    echo -e "${YELLOW}Please be patient...${NC}"
    WINEPREFIX="$directory" WINEDEBUG="-all,+err" WINEDLLOVERRIDES="mscoree,mscorwks=d" \
        winetricks --unattended --force dotnet48 2>&1 | grep -E "(Executing|Installing|warning|error|Note)" | head -50 || true
    
    echo -e "${YELLOW}Waiting for Wine processes to complete...${NC}"
    WINEPREFIX="$directory" wineserver -w
    sleep 5
    
    # Kill any stuck processes after dotnet48
    kill_stuck_wine_processes
    
    # Verify .NET 4.8 installation
    verify_dotnet "4.8"
    
    echo -e "${YELLOW}Installing core fonts...${NC}"
    WINEPREFIX="$directory" WINEDEBUG="-all" winetricks --unattended corefonts 2>&1 | grep -E "(Executing|Installing|warning|error)" | head -20 || true
    
    echo -e "${YELLOW}Installing Visual C++ 2022 runtime...${NC}"
    WINEPREFIX="$directory" WINEDEBUG="-all" winetricks --unattended vcrun2022 2>&1 | grep -E "(Executing|Installing|warning|error)" | head -20 || true
    
    # Set renderer to Vulkan
    echo -e "${YELLOW}Setting Vulkan renderer...${NC}"
    WINEPREFIX="$directory" winetricks renderer=vulkan 2>&1 | head -10 || true
    
    # Set and verify Windows version to 11
    verify_windows_version
    
    # Apply dark theme
    download_file "https://raw.githubusercontent.com/Twig6943/AffinityOnLinux/main/wine-dark-theme.reg" "$directory/wine-dark-theme.reg" "dark theme"
    WINEPREFIX="$directory" "$directory/ElementalWarriorWine/bin/regedit" "$directory/wine-dark-theme.reg" 2>&1 | head -5
    rm "$directory/wine-dark-theme.reg"
    
    # Final cleanup
    kill_stuck_wine_processes
    
    # Show installation summary
    echo -e "${GREEN}======================================${NC}"
    echo -e "${GREEN}Wine Setup Completed!${NC}"
    echo -e "${GREEN}======================================${NC}"
    echo -e "${YELLOW}Installation Summary:${NC}"
    echo -e "  Wine: ElementalWarriorWine (WoW64 mode)"
    echo -e "  Prefix: $directory"
    
    # Check what was installed
    if [ -d "$directory/drive_c/windows/Microsoft.NET/Framework/v2.0.50727" ]; then
        echo -e "  ${GREEN}✓${NC} .NET Framework 3.5"
    else
        echo -e "  ${RED}✗${NC} .NET Framework 3.5 (may need manual install)"
    fi
    
    if [ -d "$directory/drive_c/windows/Microsoft.NET/Framework/v4.0.30319" ]; then
        echo -e "  ${GREEN}✓${NC} .NET Framework 4.8"
    else
        echo -e "  ${RED}✗${NC} .NET Framework 4.8 (may need manual install)"
    fi
    
    if [ -d "$directory/drive_c/windows/Fonts" ]; then
        echo -e "  ${GREEN}✓${NC} Fonts installed"
    fi
    
    echo -e "  ${GREEN}✓${NC} Vulkan renderer"
    echo -e "  ${GREEN}✓${NC} Dark theme applied"
    echo -e "${GREEN}======================================${NC}"
}

# ==========================================
# Affinity Installation Functions
# ==========================================

# Function to create desktop entry
create_desktop_entry() {
    local app_name=$1
    local app_path=$2
    local icon_path=$3
    local desktop_file="$HOME/.local/share/applications/Affinity$app_name.desktop"
    
    echo "[Desktop Entry]" > "$desktop_file"
    echo "Name=Affinity $app_name" >> "$desktop_file"
    echo "Comment=A powerful $app_name software." >> "$desktop_file"
    echo "Icon=$icon_path" >> "$desktop_file"
    echo "Path=$HOME/.AffinityLinux" >> "$desktop_file"
    echo "Exec=env WINEPREFIX=$HOME/.AffinityLinux $HOME/.AffinityLinux/ElementalWarriorWine/bin/wine \"$app_path\"" >> "$desktop_file"
    echo "Terminal=false" >> "$desktop_file"
    echo "NoDisplay=false" >> "$desktop_file"
    echo "StartupWMClass=${app_name,,}.exe" >> "$desktop_file"
    echo "Type=Application" >> "$desktop_file"
    echo "Categories=Graphics;" >> "$desktop_file"
    echo "StartupNotify=true" >> "$desktop_file"
}

# Function to normalize and validate file path
normalize_path() {
    local path="$1"
    
    # Remove quotes and trim whitespace
    path=$(echo "$path" | tr -d '"' | xargs)
    
    # Handle file:// URLs (common when dragging from file managers)
    if [[ "$path" == file://* ]]; then
        path=$(echo "$path" | sed 's|^file://||')
        # URL decode the path
        path=$(printf '%b' "${path//%/\\x}")
    fi
    
    # Convert to absolute path if relative
    if [[ ! "$path" = /* ]]; then
        path="$(pwd)/$path"
    fi
    
    # Normalize path (remove . and .. components)
    path=$(realpath -q "$path" 2>/dev/null || echo "$path")
    
    echo "$path"
}

# Function to install Affinity app
install_affinity() {
    local app_name=$1
    local directory="$HOME/.AffinityLinux"
    
    # Verify Windows version before installation
    verify_windows_version
    
    echo -e "${YELLOW}Please download the Affinity $app_name .exe from https://store.serif.com/account/licences/${NC}"
    echo -e "${YELLOW}Once downloaded, drag and drop the installer into this terminal and press Enter:${NC}"
    read installer_path
    
    # Normalize the path
    installer_path=$(normalize_path "$installer_path")
    
    # Check if file exists and is readable
    if [ ! -f "$installer_path" ] || [ ! -r "$installer_path" ]; then
        echo -e "${RED}Invalid file path or file is not readable: $installer_path${NC}"
        return 1
    fi
    
    # Get the filename from the path
    local filename=$(basename "$installer_path")
    
    # Copy installer to Affinity directory
    echo -e "${YELLOW}Copying installer...${NC}"
    cp "$installer_path" "$directory/$filename"
    
    # Run installer
    echo -e "${YELLOW}Running installer...${NC}"
    echo -e "${YELLOW}Click No if you get any errors. Press any key to continue.${NC}"
    read -n 1
    
    # Kill any stuck wine processes before running installer
    kill_stuck_wine_processes
    
    # Run installer with debug messages suppressed
    WINEPREFIX="$directory" WINEDEBUG=-all "$directory/ElementalWarriorWine/bin/wine" "$directory/$filename"
    
    # Clean up any stuck processes after installation
    kill_stuck_wine_processes
    
    # Clean up installer
    rm "$directory/$filename"
    
    # Remove Wine's default desktop entry
    rm -f "/home/$USER/.local/share/applications/wine/Programs/Affinity $app_name 2.desktop"
    
    # Create desktop entry
    case $app_name in
        "Photo")
            create_desktop_entry "Photo" "$directory/drive_c/Program Files/Affinity/Photo 2/Photo.exe" "$HOME/.local/share/icons/AffinityPhoto.svg"
            ;;
        "Designer")
            create_desktop_entry "Designer" "$directory/drive_c/Program Files/Affinity/Designer 2/Designer.exe" "$HOME/.local/share/icons/AffinityDesigner.svg"
            ;;
        "Publisher")
            create_desktop_entry "Publisher" "$directory/drive_c/Program Files/Affinity/Publisher 2/Publisher.exe" "$HOME/.local/share/icons/AffinityPublisher.svg"
            ;;
    esac
    
    echo -e "${GREEN}Affinity $app_name installation completed!${NC}"
}

# ==========================================
# User Interface Functions
# ==========================================

# Main menu
show_menu() {
    echo -e "${GREEN}Affinity Installation Script${NC}"
    echo "1. Install Affinity Photo"
    echo "2. Install Affinity Designer"
    echo "3. Install Affinity Publisher"
    echo "4. Show Special Thanks"
    echo "5. Exit"
    echo -n "Please select an option (1-5): "
}

# ==========================================
# Main Script
# ==========================================

main() {
    # Detect distribution
    detect_distro
    echo -e "${GREEN}Detected distribution: $DISTRO $VERSION${NC}"
    
    # Check and install dependencies
    check_dependencies
    
    # Setup Wine (only once)
    setup_wine
    
    while true; do
        show_menu
        read -r choice
        
        case $choice in
            1)
                install_affinity "Photo"
                ;;
            2)
                install_affinity "Designer"
                ;;
            3)
                install_affinity "Publisher"
                ;;
            4)
                show_special_thanks
                ;;
            5)
                echo -e "${GREEN}Thank you for using the Affinity Installation Script!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                ;;
        esac
        
        echo
        read -n 1 -s -r -p "Press any key to continue..."
        clear
    done
}

# Run main function
main 

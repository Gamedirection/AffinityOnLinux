#!/usr/bin/env bash
# First-run setup for a WINEPREFIX using the GameDirection Wine runner.
#
# Not baked into the runner tarball itself, this avoids shipping a
# fully-initialized, machine-specific prefix inside the release artifact.
# Run once per new prefix, before installing any Affinity app into it.
set -euo pipefail

RUNNER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export WINE="${RUNNER_DIR}/bin/wine"
export WINEPREFIX="${WINEPREFIX:?Set WINEPREFIX to the prefix you want to set up}"

if [ ! -x "$WINE" ]; then
    echo "Wine binary not found at $WINE" >&2
    echo "Extract the runner tarball next to this script first." >&2
    exit 1
fi

echo "Initializing prefix at $WINEPREFIX ..."
"$WINE" wineboot --init

echo "Installing dependencies via winetricks (remove_mono, vcrun2022, dotnet48, corefonts, tahoma) ..."
WINE="$WINE" winetricks -q remove_mono vcrun2022 dotnet48 corefonts tahoma

echo "Installing dotnet35 (preventive, unconfirmed fix for #130, not required) ..."
WINE="$WINE" winetricks -q dotnet35 || echo "dotnet35 install failed, continuing without it (see #130)."

# dotnet40 (a dependency winetricks pulls in for dotnet48) pins the prefix's
# reported Windows version to WinXP as a side effect and never resets it.
# Affinity's installer refuses to run on anything below Windows 7 SP1.
echo "Resetting Windows version to Windows 11 (dotnet40's install chain leaves it pinned at WinXP) ..."
WINE="$WINE" winetricks -q win11

echo "Registering wintypes as a prefix-wide native DLL override ..."
"$WINE" reg add "HKCU\\Software\\Wine\\DllOverrides" /v wintypes /d native /f

echo "Placing Windows.winmd for WinRT metadata resolution ..."
WINMETADATA_DIR="$WINEPREFIX/drive_c/windows/system32/winmetadata"
mkdir -p "$WINMETADATA_DIR"
if [ ! -f "$WINMETADATA_DIR/Windows.winmd" ]; then
    curl -L -o "$WINMETADATA_DIR/Windows.winmd" \
        https://github.com/microsoft/windows-rs/raw/master/crates/libs/bindgen/default/Windows.winmd
fi

echo "Setting a fixed DPI to mitigate KDE/Mutter maximize and cursor-offset bugs ..."
"$WINE" reg add "HKCU\\Software\\Wine\\X11 Driver" /v LogPixels /t REG_DWORD /d 96 /f

echo "Prefix setup complete. Install Affinity into $WINEPREFIX next."

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
"$WINE" wineboot --wait

echo "Installing dependencies via winetricks (dotnet48, dotnet35, corefonts, tahoma) ..."
WINE="$WINE" winetricks -q remove_mono dotnet48 dotnet35 corefonts tahoma

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

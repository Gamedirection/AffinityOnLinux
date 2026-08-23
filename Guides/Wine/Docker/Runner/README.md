# GameDirection Wine Runner

A custom, portable, pre-patched Wine 11.15 build for Affinity apps on Linux.

This is a source build, not the stock `winehq-devel` package used by
`Guides/Wine/Docker/Dockerfile`. It bakes in fixes that today require
manual, per-install-method setup: a `wintypes.dll` sign-in fix (structural,
prefix-wide, not per app folder), a display SDR white-level crash fix, and
an extreme-zoom freeze fix. See "What's baked in" below for the full list.

Status: **not yet released**. This build has not passed its verification
gate (see the project plan). Do not label output from this Dockerfile as
a "GameDirection build" until that gate passes.

## What's baked in

Three source patches applied to a clean Wine 11.15 tree, in
`Runner/patches/` (patch 2 is referenced from its existing location,
`Guides/Wine/wine-11.15-sdr-white-level.patch`, to avoid two copies of the
same tested file):

1. `0001-wintypes-roresolve-affinity.patch` — `RoResolveNamespace()` in
   `dlls/wintypes/main.c` always returns `RO_E_METADATA_NAME_NOT_FOUND`
   in stock Wine. Affinity apps that ship a combined `Windows.winmd` (via
   the `windows-rs` project) hit a `TypeLoadException` on sign-in because
   of this ([seapear/AffinityOnLinux#91](https://github.com/seapear/AffinityOnLinux/issues/91),
   [#131](https://github.com/seapear/AffinityOnLinux/issues/131)). This
   patch resolves any requested namespace to that file if it exists in the
   metadata directory. Independently implemented against Wine's own public
   API contract; not copied from
   [ElementalWarrior/wine-wintypes.dll-for-affinity](https://github.com/ElementalWarrior/wine-wintypes.dll-for-affinity),
   which ships no LICENSE.
2. `wine-11.15-sdr-white-level.patch` — fixes a device-creation crash on
   displays that report SDR white level, already tested in this project's
   existing Docker guide.
3. `0003-d2d1-bezier-recursion-cap.patch` — fixes an infinite-recursion
   freeze in `dlls/d2d1/geometry.c` at extreme zoom levels
   ([seapear/AffinityOnLinux#134](https://github.com/seapear/AffinityOnLinux/issues/134)).
   Root cause: at high zoom, transformed coordinates exceed float32
   mantissa precision, so the bezier subdivision's error estimate never
   shrinks below tolerance and recursion never terminates. This caps
   recursion at depth 20. Same fix is open as
   [noahc3/AffinityPluginLoader#58](https://github.com/noahc3/AffinityPluginLoader/pull/58)
   for WineFix's separate d2d1 extraction; this applies it to the full
   Wine tree instead.

The default prefix template (`Runner/setup-prefix.sh`, run once per new
prefix) also adds: `dotnet48` and `dotnet35` (the latter is preventive,
not confirmed to fix [#130](https://github.com/seapear/AffinityOnLinux/issues/130)),
`corefonts` and `tahoma`, a prefix-wide native `wintypes` DLL override (so
patch 1 actually gets used — this is what eliminates the #91/#131 bug
class structurally instead of per app folder), `Windows.winmd` placed in
`system32\winmetadata`, and a `LogPixels=96` registry default under
`HKEY_CURRENT_USER\Software\Wine\X11 Driver` to mitigate the KDE/KWin
maximize bug and a GNOME/Mutter cursor offset bug
([#126](https://github.com/seapear/AffinityOnLinux/issues/126)) by forcing
a fixed DPI instead of passing through the compositor's fractional scale.
This mitigates the trigger condition; it is not a fix for either
compositor's own bug.

## What's not baked in

- Installing Affinity itself — stays manual.
- DXVK/VKD3D or `renderer=vulkan` — not enabled by default. Never combine
  DXVK/VKD3D with `renderer=vulkan`; they conflict. A `dxvk.conf` for the
  [#72](https://github.com/seapear/AffinityOnLinux/issues/72) black
  context-menu fix is documented as an opt-in file for DXVK-only setups.
- AffinityPluginLoader / WineFix / LoginFix — a separate runtime-plugin
  layer, stays manual and separately documented. WineFix's own `d2d1.dll`
  is deployed app-locally and wins Wine's DLL search order over this
  runner's `system32` copy, so the two layer cleanly if both are used.
- The `win11` Windows version override — stays a documented winetricks
  step, same as the manual guide.

## Building

Requires Docker.

```
cd Guides/Wine/Docker/Runner
./build.sh                  # defaults to debian:10 base (verified working)
```

This produces `GameDirectionWine-Runner-x86_64.tar.xz` in this directory.

The build is two-stage: a `builder` stage on an old, pinned base image
compiles Wine (old glibc means the result runs on newer distros too,
glibc is forward-compatible, not the reverse — this is the same technique
Kron4ek's and Valve's Proton-GE builds use); a `packager` stage copies
only the built output into the shipped tarball, keeping build-only
packages out of it.

Toolchain: this build uses `gcc-mingw-w64` for the PE (Windows-side) half
of Wine, not clang, since clang new enough for Wine's PE-native build mode
is not available on old base images by default. This is the same approach
WineHQ's own historical build recipes use.

**Which base image actually worked**: `ubuntu:18.04` fails — its
`gcc-mingw-w64` is too old for Wine 11.15's `libs/symcrypt` VAES
intrinsics (`_mm256_aesenc_epi128` needs GCC 8+; 18.04 ships older by
default), failing with "incompatible types when assigning to type
'__m256i'" in `aes-ymm.c`. `debian:10` (buster) works end to end
("Wine build complete."), after repointing its EOL apt sources at
`archive.debian.org` (already handled in the Dockerfile). The resulting
`bin/wine` was verified to run (`wine --version` → `wine-11.15`) inside
a **separate** `fedora:41` container it was never built in, confirming
actual cross-distro portability rather than just claiming it.

## Verifying a build (or a version bump)

Before calling any build a "GameDirection build" or releasing it, run the
full verification gate:

1. Install Affinity by Canva into a prefix built from
   `Runner/setup-prefix.sh`. Confirm no `TypeLoadException` on
   `StoreLicense` during sign-in, with zero manual file-copy steps. Then
   install a second Affinity app into the *same* prefix and confirm it
   also works — this is the specific #131 regression case (works for app
   one, breaks for app two) that a prefix-wide override fixes.
2. Confirm no SDR white-level crash (`Log.txt` should not show
   `DisplayConfigGetDeviceInfo error: 87`), tested against the *packaged*
   tarball, not just a raw local build.
3. Best-effort: reproduce the extreme-zoom conditions from #134 and
   confirm no freeze. If untestable, say so in the release notes rather
   than claiming it's fixed.
4. Best-effort: test the Lutris duplicate-canvas behavior from
   [#128](https://github.com/seapear/AffinityOnLinux/issues/128) and
   report whichever behavior is actually observed.
5. Run the cross-container portability check `build.sh` prints at the end
   — the built `wine` binary must run inside a *different* distro
   container than the one it was built in.

Passing means checks 1, 2, and 5 pass with no regressions. Checks 3 and 4
are best-effort, not hard gates, but must be reported honestly either way.

## Re-verifying after a Wine version bump

1. Update `WINE_VERSION` (build-arg or `build.sh` env var).
2. Re-check all three patches still apply cleanly (`patch -p1 --dry-run`
   inside the new source tree) — Wine's own source moves, hunks can drift.
3. Re-run the full verification gate above. A version bump is not
   "probably fine," it's an unverified build until it's been run through
   the gate again.

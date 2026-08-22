# Wine Runner Landscape Notes (Internal)

Not user-facing yet. Working notes on the current Wine runner/patch ecosystem across this project's guides, kept in one place so a future consolidated runner decision has the full picture. Move or delete once acted on.

## Current runners in use across this repo's guides

| Runner | Base | Used by | Notes |
|---|---|---|---|
| Distro `wine`/`winehq-devel` package | Wine 10.17+ mainline/devel | [Guides/Wine/Guide.md](/Guides/Wine/Guide.md) | No custom patches. Requires manual `wintypes.dll` + `Windows.winmd` placement (Steps 5 to 7) unless Wine 11+. |
| `GameDirectionWine-x86_64` | Wine 10.19 Staged (portable) | [Guides/Lutris/Guide-V2.md](/Guides/Lutris/Guide-V2.md) via `Affinity-gd.yaml` | Hosted at `seapear/AffinityOnLinux` release tag `v10.19-staged`. Install script places `wintypes.dll` and registers the override automatically as of this pass (see Part C fix for #131), but only into the V3 app directory, not each V2 app. |
| `kron4ek-wine-*` (staged/TKG) | Varies, pulled via Bottles' built-in runner manager | [Guides/Bottles/GuideV2.md](/Guides/Bottles/GuideV2.md) via `affinity-nu.yaml` | Stock upstream Wine build, no Affinity-specific patches baked in. `wintypes` override set correctly in the Bottles config (`DLL_Overrides: wintypes: n`), but `wintypes.dll`/`Windows.winmd` file placement is still a manual step in the guide. |
| ElementalWarrior fork + [wine-wintypes.dll-for-affinity](https://github.com/ElementalWarrior/wine-wintypes.dll-for-affinity) | Wine fork | Nearly every guide (Lutris legacy, Bottles v1, Heroic, Rum) | Source of the `wintypes_shim.dll.so` used everywhere as the WinRT metadata shim. This is the shim, not a full runner in most guides. |
| `wine-tkg-affinity` (daegalus) | Wine TKG | Credits.md, legacy Lutris/Bottles/Heroic guides | Referenced as a runner option; not the primary recommendation in any current guide. |
| Kron4ek Wine-Builds TKG (11.12 / 11.12 v4 Zen4-5, 10.10/9.14 legacy) | Wine 11.x | `Linux-Affinity-Installer` (ryzendew, separate project) | Explicitly deprecates Wine 10.17 ("major bugs and issues, this installer does not use it"). Directly conflicts with this project's Wine 10.17+ baseline recommendation; unresolved. |

## Patches worth carrying into a consolidated runner

Traced from `AffinityPluginLoader`'s `WineFix` plugin (runtime Harmony patches, not baked into Wine itself, but functionally patches the same class of bugs a custom runner build might otherwise need to fix at the Wine level):

- Patched `d2d1.dll` (cubic-bezier subdivision) fixing the inaccurate vector pen preview line bug.
- Wayland color picker black-screen bug (`ScreenHelper.SaveAllScreens` transpiler).
- Startup crash from parallel font enumeration (forces synchronous font loading).
- Preferences-not-saving bug (`HasPreviousPackageInstalled` override).

These are currently delivered as a runtime plugin layer on top of any runner (see Guide.md's "Optional Enhancements" section), not baked into a Wine build. A consolidated runner could either keep relying on WineFix for these, or absorb the `d2d1.dll` fix directly if float-precision issues like #134's zoom freeze turn out to need a lower-level fix than WineFix's transpiler approach can reach.

## Open question: baseline Wine version

This project's flagship guide targets **Wine 10.17+** (any recent mainline/devel build) as the minimum needed for WinRT support. `Linux-Affinity-Installer` (a separate, non-affiliated project) treats 10.17 as broken and recommends 11.12 instead. Before building a new consolidated runner, decide:

1. Keep 10.17 as the floor and test whether the reported 10.17-specific "major bugs" actually affect this project's install flow, or
2. Move the baseline forward to a recent 11.x release (matching Step 4's existing "if Wine 11+, skip to Step 8" shortcut, which already assumes the WinRT fix landed upstream by then) and drop the manual shim steps as unnecessary for that baseline.

## What a next-gen runner should bundle, if built

1. `wintypes.dll` (renamed from `wintypes_shim.dll.so`) and `Windows.winmd` pre-placed in the runner's default template prefix, removing manual Steps 5 to 7 entirely.
2. The `wintypes` native DLL override pre-registered in the template prefix's registry (not per-install, like the `Affinity-gd.yaml` fix in this pass does for Lutris).
3. A decision on whether to also bundle WineFix's `d2d1.dll` fix by default, or leave that to the optional plugin layer.
4. Packaging and hosting plan mirroring `GameDirectionWine-x86_64`'s existing release pattern (GitHub Releases tag on `Gamedirection/AffinityOnLinux` or `seapear/AffinityOnLinux`).

No build performed in this pass. This is research/design groundwork only.

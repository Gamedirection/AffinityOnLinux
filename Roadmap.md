# 🗺️ Roadmap

[ ✅ ] Host a local download for ElementalWarriors and TKG Wine Builds

[ ✅ ] Get the whole winmetadata thing sorted out. ( [Issue #6](https://github.com/Twig6943/AffinityOnLinux/issues/6) )

[ ✅ ] Fix crashes upon saving/exporting

[ ✅ ] Get the font issue fixed (related to flatpak)

[ ✅ ] Settings workaround

[ ✅ ] Create an updated Wine build utilizing latest version of wine. ([Thanks to Wanesty](https://discord.com/channels/1281706644073611358/1281706644715208809/1434097819547074652))

[ ✅ ] Get Canva login fixed (thanks XDan for reporting). Root cause traced via live testing on Wine 11.15: `affinity://` protocol registration and launch work fine (confirmed via `x-scheme-handler/affinity` and `HKEY_CLASSES_ROOT\affinity`), but `Serif.Affinity.Application.ProcessCommandLineArguments` (the method that handles both the app's own startup args and the callback URL forwarded from a second launched instance over a named pipe) throws `System.TypeLoadException` on the WinRT type `Windows.ApplicationModel.DataTransfer.SharedStorageAccessManager`, which Wine doesn't implement, on *every* call regardless of arguments (the .NET JIT resolves every type referenced anywhere in a method body, not just the branch that's actually taken). Fixed with a community plugin, [LoginFix](/Guides/Wine/LoginFix), an AffinityPluginLoader plugin that patches the method's callers instead (which reference it only by signature, safe to resolve) with a safe reimplementation. No custom Wine build needed, works on stock distro Wine. See [Guides/Wine/LoginFix/README.md](/Guides/Wine/LoginFix/README.md) for the full trace and build/install steps.

[ 🟨 ] Get vector issue solved (Thanks Søren for reporting). [AffinityPluginLoader's WineFix](https://github.com/noahc3/AffinityPluginLoader/) already ships a patched `d2d1.dll` fixing inaccurate vector pen preview lines, not yet upstreamed into an official guide step

[ 🟨 ] Get [studiolink](https://github.com/Twig6943/AffinityOnLinux/issues/25) working

[ ❌ ] OpenCL for Amd/Intel gpus (waiting ElementalWarrior)

[ ❌ ] Video walkthrough tutorials.
 - [ ❌ ] Wine 10.17+ Method.
 - [ ❌ ] Lutris Method.
 - [ ❌ ] Heroic Method.
 - [ ❌ ] Bottles Method.
 - [ ❌ ] RUM Method.

# ⚠️ Known Issues
Some users get these errors with the script but are able to get it working with the guide method

- wine: could not load ntdll.so: /lib/x86_64-linux-gnu/libc.so.6: version `GLIBC_2.38' not found (required by /home/USER/.AffinityLinux/ElementalWarriorWine/bin/../lib/wine/x86_64-unix/ntdll.so)

- wine: could not load `mscoree.dll` or any crash related to .NET Framework while using bottles
    - This is probably caused by Wine Mono conflicting with the installation of .NET Framework versions lower than 5.  
    As of now, it does not seem possible to specify the removal of Wine Mono as an instruction in the yaml manifest, since bottles does not use winetricks under the hood, but their own dependency manager.
    For a working install in bottles, one would have to create a custom empty bottle, then uninstall Wine Mono before anything else, then manually install dependencies.  
    This defeats the purpose of having an automated bottle creation using yaml files, so bottles is currently not recommended.  
    - Sources: 
      - [Bottles issue #2887](https://github.com/bottlesdevs/Bottles/issues/2887#issuecomment-2646118028)  
      - [Wine Mono README](https://github.com/wine-mono/wine-mono#:~:text=Please%20note%20that%20while%20Wine%20Mono%20should%20always%20be%20removed%20before%20installing%20.NET%20Framework%204.8%20and%20earlier%2C%20it%20can%20coexist%20with%20.NET%20Core%20and%20.NET%205%20or%20later.)

- Affinity by Canva: Sign in issues with Canva [Reported](https://discord.com/channels/1281706644073611358/1281706644715208809/1433584942167887942)
- Affinity by Canva: Pen path is still an issue. ([V3](https://cdn.discordapp.com/attachments/1281706644715208809/1433663104826474577/image.png?ex=69058250&is=690430d0&hm=832e2549f694a92a1bec29310cea5ea4c1a2a309b23dfef56c83649d55bf188e&)) [V2](https://discord.com/channels/1281706644073611358/1325725311836622944)
- Affinity by Canva: Color picker doesn't want to work outside of the canvas/artboards. [@_dansity_](https://discord.com/channels/1281706644073611358/1433758899122471012) [Clover](https://discord.com/channels/1281706644073611358/1433758899122471012/1433783910126321747)
- Affinity by Canva: Vector Pen preview line is not accurate. [Reported](https://discord.com/channels/1281706644073611358/1433830414954397736). Fixed by [AffinityPluginLoader's WineFix](https://github.com/noahc3/AffinityPluginLoader/) patched `d2d1.dll`
- Designer V2: Deselecting SVG nested in Group while snapping is enabled. [Jacopo Faust](https://discord.com/channels/1281706644073611358/1431672689843634377)

- V2 Users getting their 40x font pack as a "gift" [Youtube - Affinity](https://www.youtube.com/watch?v=UP_TBaKODlw&t=1300s)

- Affinity V3 freezes completely at very high zoom levels on NVIDIA hybrid / Fedora Wayland setups ([Issue #134](https://github.com/seapear/AffinityOnLinux/issues/134)). Root cause traced by the reporter to a float precision overflow in Wine's `d2d1` matrix transform at roughly 8,232,116% zoom (the single precision mantissa limit, 2^23). Clamping the matrix scale below 2^23 should prevent the freeze; no fix landed yet.

- Missing .NET 3.5 error with native Wine 11.7 ([Issue #130](https://github.com/seapear/AffinityOnLinux/issues/130)). Affects users on newer native (non manual-install) Wine setups; no confirmed fix yet.

- Window cut off / title bar missing when maximized on KDE Plasma Wayland ([Issue #129](https://github.com/seapear/AffinityOnLinux/issues/129)), and cursor offset on GNOME with display scaling ([Issue #126](https://github.com/seapear/AffinityOnLinux/issues/126)). Root cause confirmed via live testing: [KDE bug 459373](https://bugs.kde.org/show_bug.cgi?id=459373), KWin's XWayland maximize sizing breaking at fractional display scales that don't divide evenly into the monitor's native resolution. Workaround: switch to a scale factor that divides your native resolution evenly (for example 160% instead of 150% on a 2560x1600 panel). See [Guides/Wine/Guide.md's Troubleshooting section](/Guides/Wine/Guide.md#window-is-cut-off--doesnt-fill-the-screen-when-maximized-kde-plasma-wayland) for detail. GNOME's equivalent scaling stack may hit an analogous bug; unconfirmed.



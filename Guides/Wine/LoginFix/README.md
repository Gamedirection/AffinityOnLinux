# LoginFix (AffinityPluginLoader plugin)

Fixes the Canva sign-in flow crashing under Wine. Not an official [AffinityPluginLoader](https://github.com/noahc3/AffinityPluginLoader/)/WineFix plugin, community-made, tested on Wine 11.15 (both a stock distro build and a patched local build, both worked identically, no custom Wine required).

## What it fixes

Clicking "Log in or sign up" and completing the Canva OAuth flow in your browser used to crash Affinity the moment you clicked "Open Affinity" (or, in some runs, right when clicking "Log in or sign up" itself). Traced via a full managed stack trace and `WINEDEBUG` tracing to:

- `Serif.Affinity.Application.ProcessCommandLineArguments` has a branch (only reached for an unrelated `affinity-open-file:` argument) that calls `Windows.ApplicationModel.DataTransfer.SharedStorageAccessManager.RedeemTokenForFileAsync`.
- Wine has no WinRT implementation of that type.
- The .NET CLR resolves every type referenced anywhere in a method's body when it JITs that method, so simply *calling* `ProcessCommandLineArguments` throws `System.TypeLoadException`, regardless of which branch would actually run. This is exactly the path the Canva sign-in callback goes through (the second `Affinity.exe` instance the OS launches for the callback URL forwards its arguments to the running instance via a named pipe, which lands in this same method), so login always crashed.

Harmony itself can't patch `ProcessCommandLineArguments` directly either: patching a method (even with a plain prefix) requires Harmony to decompile its IL, which means resolving every operand in the body, including the poisoned `SharedStorageAccessManager` call, so a patch on that method throws the same `TypeLoadException` that Harmony's own retry-and-defer logic keeps swallowing forever.

The fix instead patches `ProcessCommandLineArguments`'s two callers (`ProcessArguments()`, for the app's own startup command line, and `SingleInstanceThread()`, the named-pipe listener that receives the sign-in callback from a second launched instance), neither of which references the poisoned type directly, only by signature, which Harmony can resolve fine. Both are fully replaced with a safe reimplementation that never touches the real `ProcessCommandLineArguments`, and drops only the unrelated `affinity-open-file:` handling (which needs `SharedStorageAccessManager` and can't work under Wine regardless).

## Building

Requires the [.NET SDK](https://dotnet.microsoft.com) (targets `net48`).

1. Install [AffinityPluginLoader + WineFix](/Guides/Wine/Guide.md#install-affinity-plugin-loader--winefix) first if you haven't.
2. Copy `AffinityPluginLoader.dll` from your Affinity install directory into this folder (next to `LoginFix.csproj`).
3. `dotnet build -c Release`
4. Copy the built `bin/Release/net48/win-x64/LoginFix.dll` into `apl/plugins/` alongside `WineFix.dll`.
5. Relaunch Affinity (via `Affinity.exe`, which is the `AffinityHook` launcher after the plugin loader install step).

No Wine-side changes needed. This is entirely inside Affinity's own process, so it works on your distro's stock Wine package.

# wine-11.15-sdr-white-level.patch

Small Wine source patch (`dlls/win32u/sysparams.c`), tested against Wine 11.15.

## What it fixes

Affinity creates a Direct3D device on startup and queries `DISPLAYCONFIG_DEVICE_INFO_GET_SDR_WHITE_LEVEL` (the display's SDR reference white level, used for HDR/wide-gamut color pipeline setup) via `DisplayConfigGetDeviceInfo`. Wine doesn't implement that query (`FIXME: Unimplemented packet type 11`, `NtUserDisplayConfigGetDeviceInfo` in `sysparams.c`), returns an error, and Affinity's own error handling treats that as fatal for device creation (`DXRenderer.cpp(1014): error 0x80004001, Not implemented`), confirmed via Affinity's own `Log.txt`.

This is unrelated to the Canva sign-in crash fixed by [LoginFix](/Guides/Wine/LoginFix), which is entirely inside Affinity's own process and needs no Wine changes. This patch is about a separate device-creation failure, independently confirmed by testing with and without it.

## Applying it

Requires building Wine from source (a full build toolchain, `./configure`, `make`; expect 15-40+ minutes even on a fast machine). Not something most users should need to do; documented here for reference and as a candidate to submit upstream to WineHQ.

```
cd wine-11.15
patch -p1 < wine-11.15-sdr-white-level.patch
./configure --enable-win64
make -j$(nproc)
```

`SDRWhiteLevel` is set to `1000` (documented as 80 nits, the standard SDR reference white level) for every query, regardless of actual monitor calibration, good enough to unblock device creation, not a real per-monitor implementation.

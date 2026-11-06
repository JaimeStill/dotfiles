# Keychron K2 HE

Exports from [Keychron Launcher](https://launcher.keychron.com) (Chrome/Chromium; needs the udev
rule from `platforms/omarchy/system-setup.sh` on Linux) of the K2 HE's configuration, to restore
it onto another K2 HE. USB ID `3434:0e20`.

- `keymap.json` — key assignments, 4 layers. Launcher's keymap export; does not include actuation,
  Rapid Trigger, DKS, Snap Tap, or macros.
- `he-profile.json` — Hall effect settings, profile 1 of 3. In short: every key actuates at
  1.3 mm (the profile's global default is 2.0 mm), Rapid Trigger off (sensitivity values of 4 are
  stored but not enabled), no DKS, Snap Tap, toggle, or turbo keys, default analog curve.

Exported from a board running firmware **v1.1.0 (2024-10-31)**. Bring the target board to the same
firmware before importing.

## Restoring onto another board

1. Plug the board in directly, not through a KVM (KVMs often hide the raw HID interface).
2. Match firmware. If the browser update stalls, flash the `.bin` from Keychron's site with
   `dfu-util` (in the Omarchy package set) with the board in bootloader mode; check `lsusb` for
   its DFU ID.
3. In Launcher, import `keymap.json`, then `he-profile.json`. If the profile won't import, set a
   global 1.3 mm actuation by hand — that's the only change from defaults.

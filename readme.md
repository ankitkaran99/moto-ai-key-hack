# Moto Edge 60 Pro — AI Key Switcher

Customize the Moto AI Key on the Motorola Moto Edge 60 Pro using ADB.

This script allows:

- Single press → Gemini
- Double press → Camera
- Restore Moto AI behavior
- Disable all custom mappings

---

# Features

✅ Single press → Gemini  
✅ Double press → Camera  
✅ Restore Moto AI behavior  
✅ Status viewer  
✅ No root required  
✅ Uses standard Android `settings` database via ADB  

---

# Requirements

- Motorola Moto Edge 60 Pro
- USB Debugging enabled
- ADB installed
- Git Bash / Linux / macOS terminal

---

# Enable USB Debugging

On phone:

## Enable Developer Options

Go to:

```text
Settings → About Phone → Tap "Build Number" 7 times
```

## Enable USB Debugging

```text
Settings → System → Developer Options → USB Debugging
```

Connect phone via USB and allow debugging prompt.

---

# Verify ADB

Run:

```bash
adb devices
```

Expected:

```text
List of devices attached
XXXXXXXX	device
```

---

# Usage

## Apply Custom Mapping

```bash
bash ai_key.sh apply
```

Result:

| Gesture | Action |
|---|---|
| Single Press | Gemini |
| Double Press | Camera |
| Hold | Moto AI (default) |

---

## Restore Default / Disable Custom Actions

```bash
bash ai_key.sh revert
```

Result:

| Gesture | Action |
|---|---|
| Single Press | Disabled |
| Double Press | Disabled |
| Hold | Disabled |

---

## Restore Moto AI

```bash
bash ai_key.sh motoai
```

Result:

| Gesture | Action |
|---|---|
| Double Press | Moto AI |
| Hold | Moto AI |

---

## Show Current Status

```bash
bash ai_key.sh status
```

Displays:

- `tap_app_quick_single`
- `tap_app_quick_double`
- `tap_app_quick_press_hold`
- `tap_app_main_press_hold`
- `my_key_tap_app`

---

# How It Works

The script modifies Android system settings using:

```bash
adb shell settings put system ...
```

Main settings used:

| Setting | Purpose |
|---|---|
| `tap_app_quick_single` | Single press action |
| `tap_app_quick_double` | Double press action |
| `tap_app_quick_press_hold` | Hold mode flag |
| `tap_app_main_press_hold` | Hold action intent |
| `my_key_tap_app` | Legacy Motorola override |

---

# Important Discovery

On this firmware:

| Gesture | Backend Type |
|---|---|
| Single Press | Intent String |
| Double Press | Intent String |
| Hold | Enum / Flag |

This means:

- Single & Double press support custom intents
- Hold press is restricted by Motorola firmware
- Hold supports only:
  - `0` → None
  - `7` → Moto AI

Custom hold apps are NOT supported on this firmware.

---

# Known Limitations

## Hold Action Cannot Launch Custom Apps

Motorola firmware restricts hold behavior internally.

Even though:

```text
tap_app_main_press_hold
```

accepts intent strings, the firmware ignores them unless the hold mode is supported.

---

## Settings Reset After Reboot

Some firmware versions may reset mappings after reboot.

Simply re-run:

```bash
bash ai_key.sh apply
```

---

# Troubleshooting

## Device Not Detected

Run:

```bash
adb kill-server
adb start-server
adb devices
```

Reconnect USB cable and allow debugging prompt.

---

## Changes Not Applying

Restart Android UI services:

```bash
adb shell am force-stop com.motorola.uxcore
adb shell am force-stop com.motorola.myui.ai
adb shell am force-stop com.motorola.mykey
adb shell am force-stop com.android.systemui
```

Or reboot:

```bash
adb reboot
```

---

## Reset Everything

```bash
bash ai_key.sh revert
```

---

# Reverse Engineering Notes

Settings were discovered by diffing Android system settings before/after changing Moto AI Key options.

Example:

```bash
adb shell settings list system > before.txt
```

Change setting in Moto UI.

```bash
adb shell settings list system > after.txt
diff before.txt after.txt
```

---

# License

MIT License

Use at your own risk.

---

# Credits

Reverse engineered using:

- ADB
- Android `settings`
- `dumpsys`
- Motorola system behavior analysis
- Too much patience 😄

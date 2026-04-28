# Japanese Walk

Japanese interval walking app for Garmin Connect IQ watches.

## Overview

This project implements a simple alternating walking workout:

- Fast interval
- Slow interval
- Repeating section ring around the watch edge
- Saved FIT activity with calories, laps, and workout summary

## Project Layout

- `source/` application logic and views
- `resources/` strings and drawable assets
- `manifest.xml` Connect IQ manifest
- `monkey.jungle` project entry for Monkey C builds

## Requirements

- Garmin Connect IQ SDK
- Java JDK 21
- Garmin Monkey C VS Code extension
- Garmin developer key

## Build

Example manual build for the real Venu 4 45mm target:

```powershell
Push-Location "c:\Users\ronkl\Development\Japanese Interval Walking\JapaneseIntervalWalking"
& "C:\Program Files\Eclipse Adoptium\jdk-21.0.10.7-hotspot\bin\java.exe" \
  '-Xms1g' \
  '-Dfile.encoding=UTF-8' \
  '-Dapple.awt.UIElement=true' \
  '-jar' 'c:\Users\ronkl\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.1.0-2026-03-09-6a872a80b\bin\monkeybrains.jar' \
  '-o' 'c:\Users\ronkl\Development\Japanese Interval Walking\JapaneseIntervalWalking\JapaneseIntervalWalking.prg' \
  '-f' 'c:\Users\ronkl\Development\Japanese Interval Walking\JapaneseIntervalWalking\monkey.jungle' \
  '-y' 'c:\Users\ronkl\Development\Japanese Interval Walking\JapaneseIntervalWalking\developer_key' \
  '-d' 'venu445mm' \
  '-w'
Pop-Location
```

## Install on Watch

Copy the built `.prg` file to the watch `GARMIN/APPS/` folder over USB.

## Notes

- The repository excludes local build outputs and the developer key.
- The app records a FIT activity as `Japanese Walk`.
- GPS tracking is explicitly enabled during the workout to improve saved route/map data.

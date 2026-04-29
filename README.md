# Japanese Walk

Japanese Walk is a Garmin Connect IQ watch app for Japanese-style interval walking: alternating fast and slow walking blocks with a clear watchface layout and saved FIT activity recording.

## Features

- Alternating fast and slow walking intervals
- Large countdown timer with clear phase icon
- Section ring progress around the watch edge
- Live workout metrics for time, distance, heart rate, and calories
- Saved FIT activity with route support when GPS is available

## Device Support

The manifest currently targets recent Garmin watch families including Venu, vivoactive, Forerunner, and fēnix models.

## Build

Requirements:

- Garmin Connect IQ SDK
- Java JDK 21
- Garmin Monkey C VS Code extension
- Garmin developer key stored locally

Example build:

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

## Install

Copy the built `.prg` file to `GARMIN/APPS/` on the watch over USB, or install it through the Connect IQ development workflow.

## Support

If the app is useful, a small donation or tip is appreciated and helps justify continued polish, testing, and device support.

## Notes

- The developer key stays local and is excluded from git.
- The app records the activity name as `Japanese Walk`.
- GPS is enabled during workouts to improve saved route and map data.

# Installing Koubutsu on an iPad (from Linux)

Apple only signs apps on macOS or through its own services, so CI (a macOS runner) builds the app and
you sign and install it from Linux.

## 1. Get the build

Every push to `main` (and to `claude/**` branches) runs **iPad build (unsigned IPA)**
(`.github/workflows/ipa.yml`). Open the latest successful run on GitHub → Actions, download the
`Koubutsu-ipa` artifact and unzip it: you get `Koubutsu.ipa` (unsigned, not installable yet).

## 2. Pair the iPad (once)

```
sudo apt install usbmuxd libimobiledevice-utils ideviceinstaller
idevicepair pair                       # tap Trust on the iPad
ideviceinfo -k UniqueDeviceID          # the UDID, needed below
```

## 3a. Sign and install with a free Apple ID (AltServer-Linux)

AltServer-Linux (github.com/NyaMisty/AltServer-Linux) is an unofficial community tool; it signs with your
Apple ID and installs over USB. Use its prebuilt release binary (building from source is not needed).
It needs an *anisette* server (device-identity headers Apple's login requires), set with
`ALTSERVER_ANISETTE_SERVER`; see the project's README for current public servers or run one yourself.
Consider a secondary Apple ID for sideloading.

```
chmod +x AltServer-x86_64
export ALTSERVER_ANISETTE_SERVER=<anisette server URL>
./AltServer-x86_64 -u <UDID> -a <apple-id-email> -p <apple-id-password> Koubutsu.ipa
```

Enter the two-factor code when prompted. If login fails with current Apple servers, the tool is out of
date; use 3b or TestFlight instead.

Free Apple ID limits: the app stops launching after **7 days** (re-run the same command to re-sign),
at most 3 sideloaded apps.

## 3b. Sign and install with a paid developer account (zsign)

Create a development certificate (export as `.p12`) and a development provisioning profile that includes
the iPad's UDID at developer.apple.com, then:

```
zsign -k cert.p12 -p <p12-password> -m profile.mobileprovision -o Koubutsu-signed.ipa Koubutsu.ipa
ideviceinstaller -i Koubutsu-signed.ipa
```

Profiles are valid for a year.

## 4. On the iPad (first launch)

- Settings → Privacy & Security → **Developer Mode** → on, restart, confirm.
- Free Apple ID only: Settings → General → VPN & Device Management → trust your Apple ID.
- Japanese → English translation: accept the app's language download prompt (or add Japanese under the
  system Translate app's downloaded languages). Without it no English is shown.
- Video mode: import a video with the transport bar's import button, or copy it to
  Files → On My iPad → Koubutsu.
- Game mode: plug in the UVC/UAC capture device; allow camera and microphone access.

## Updating

Download the newest `Koubutsu-ipa` artifact and repeat step 3a or 3b. Installing over the existing app
keeps its settings and imported videos as long as the same Apple ID/team signs it.

## Alternative: TestFlight (paid account, automatic updates)

With an Apple Developer Program membership, CI can archive, sign (App Store Connect API key in repository
secrets) and upload each build to TestFlight; the iPad then installs and updates through the TestFlight
app. Not set up yet.
